//
//  Debouncer.swift
//  BLEScanner
//
//  Utility to debounce rapid state changes (e.g., search input)
//

import Foundation

/// Debouncer to delay execution of a task until a certain time has passed without new calls
actor Debouncer {
    private var task: Task<Void, Never>?
    private let delay: Duration

    init(delay: Duration = .milliseconds(300)) {
        self.delay = delay
    }

    /// Submit a task to be executed after the debounce delay
    func submit(_ action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await action()
        }
    }

    /// Cancel any pending task
    func cancel() {
        task?.cancel()
        task = nil
    }
}
