import Darwin
import Foundation
import os

@MainActor
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
        var usage = rusage_info_current()
        let result = withUnsafeMutablePointer(to: &usage) { pointer in
            proc_pid_rusage(getpid(), RUSAGE_INFO_CURRENT, pointer)
        }

        guard result == 0 else {
            return nil
        }

        let userSeconds = Double(usage.ri_user_time) / 1_000_000_000
        let systemSeconds = Double(usage.ri_system_time) / 1_000_000_000
        let residentBytes = Double(usage.ri_resident_size)

        return Usage(userTimeSeconds: userSeconds, systemTimeSeconds: systemSeconds, residentBytes: residentBytes)
    }

    private struct Usage {
        let userTimeSeconds: Double
        let systemTimeSeconds: Double
        let residentBytes: Double
    }
}
