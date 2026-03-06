import Darwin
import Foundation
import os

final class PerformanceMonitor {
    struct Snapshot: Sendable {
        let timestamp: Date
        let cpuPercent: Double
        let memoryMB: Double
    }

    var onSnapshot: ((Snapshot) -> Void)?

    private let logger = Logger(subsystem: "com.myfocus.app", category: "performance")
    private let cpuLimitPercent: Double
    private let memoryLimitMB: Double
    private let sampleInterval: TimeInterval
    private var timer: Timer?
    private var lastTotalCPUSeconds: Double?
    private var lastSampleTime: Date?

    init(cpuLimitPercent: Double = 1.0, memoryLimitMB: Double = 100.0, sampleInterval: TimeInterval = 30) {
        self.cpuLimitPercent = cpuLimitPercent
        self.memoryLimitMB = memoryLimitMB
        self.sampleInterval = sampleInterval
    }

    deinit {
        timer?.invalidate()
    }

    func start() {
        guard timer == nil else {
            return
        }

        sample()
        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            self?.sample()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        guard let usage = readUsage() else {
            return
        }

        let now = Date()
        let totalCPUSeconds = usage.userTimeSeconds + usage.systemTimeSeconds

        let cpuPercent: Double
        if let lastCPU = lastTotalCPUSeconds, let lastTime = lastSampleTime {
            let wallDelta = max(0.001, now.timeIntervalSince(lastTime))
            let cpuDelta = max(0, totalCPUSeconds - lastCPU)
            cpuPercent = (cpuDelta / wallDelta) * 100
        } else {
            cpuPercent = 0
        }

        let memoryMB = usage.residentBytes / 1_048_576

        let snapshot = Snapshot(timestamp: now, cpuPercent: cpuPercent, memoryMB: memoryMB)
        onSnapshot?(snapshot)

        if cpuPercent > cpuLimitPercent || memoryMB > memoryLimitMB {
            logger.warning("Resource guardrail exceeded cpu=\(cpuPercent, format: .fixed(precision: 2)) memMB=\(memoryMB, format: .fixed(precision: 2))")
        }

        lastTotalCPUSeconds = totalCPUSeconds
        lastSampleTime = now
    }

    private func readUsage() -> Usage? {
        var threadInfo = task_thread_times_info_data_t()
        var threadInfoCount = mach_msg_type_number_t(MemoryLayout.size(ofValue: threadInfo) / MemoryLayout<natural_t>.size)
        let threadInfoResult: kern_return_t = withUnsafeMutablePointer(to: &threadInfo) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) { intPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_THREAD_TIMES_INFO),
                    intPointer,
                    &threadInfoCount
                )
            }
        }

        guard threadInfoResult == KERN_SUCCESS else {
            return nil
        }

        var basicInfo = mach_task_basic_info_data_t()
        var basicInfoCount = mach_msg_type_number_t(MemoryLayout.size(ofValue: basicInfo) / MemoryLayout<natural_t>.size)
        let basicInfoResult: kern_return_t = withUnsafeMutablePointer(to: &basicInfo) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(basicInfoCount)) { intPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    intPointer,
                    &basicInfoCount
                )
            }
        }

        guard basicInfoResult == KERN_SUCCESS else {
            return nil
        }

        let userSeconds = Double(threadInfo.user_time.seconds) + (Double(threadInfo.user_time.microseconds) / 1_000_000)
        let systemSeconds = Double(threadInfo.system_time.seconds) + (Double(threadInfo.system_time.microseconds) / 1_000_000)
        let residentBytes = Double(basicInfo.resident_size)

        return Usage(userTimeSeconds: userSeconds, systemTimeSeconds: systemSeconds, residentBytes: residentBytes)
    }

    private struct Usage {
        let userTimeSeconds: Double
        let systemTimeSeconds: Double
        let residentBytes: Double
    }
}
