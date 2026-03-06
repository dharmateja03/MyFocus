import Foundation

@objc public protocol FocusHelperXPCProtocol {
    func ping(_ reply: @escaping (String) -> Void)
    func startSession(requestData: Data, reply: @escaping (Bool, String?) -> Void)
    func stopSession(_ reply: @escaping (Bool) -> Void)
    func updateBlockedApps(bundleIDs: [String], reply: @escaping (Bool, String?) -> Void)
}

@objc public protocol FocusAppXPCProtocol {
    func sessionStateDidChange(stateData: Data)
    func helperHealthDidChange(isHealthy: Bool)
}
