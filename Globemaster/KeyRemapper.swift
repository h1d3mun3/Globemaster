//
//  KeyRemapper.swift
//  Globemaster
//
//  Created by hidemune on 3/11/26.
//

import Cocoa
import CoreGraphics

final class KeyRemapper: Sendable {

    private let lock = NSLock()

    private struct State {
        var eventTap: CFMachPort?
        var runLoopSource: CFRunLoopSource?
        var retainedSelf: Unmanaged<KeyRemapper>?
        var leftCommandPressed = false
        var rightCommandPressed = false
        var otherKeyPressedDuringCommand = false
    }

    private let state = UnsafeMutablePointer<State>.allocate(capacity: 1)

    // keycodes
    private static let leftCommandKeyCode: Int64 = 55
    private static let rightCommandKeyCode: Int64 = 54
    private static let eisuuKeyCode: CGKeyCode = 102
    private static let kanaKeyCode: CGKeyCode = 104

    init() {
        state.initialize(to: State())
    }

    deinit {
        stop()
        state.deinitialize(count: 1)
        state.deallocate()
    }

    var isEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let tap = state.pointee.eventTap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }

    func start() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard state.pointee.eventTap == nil else { return true }

        let eventMask: CGEventMask =
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.keyDown.rawValue)

        let retained = Unmanaged.passRetained(self)
        let refcon = retained.toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventCallback,
            userInfo: refcon
        ) else {
            retained.release()
            return false
        }

        state.pointee.retainedSelf = retained

        state.pointee.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        state.pointee.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    func stop() {
        lock.lock()
        defer { lock.unlock() }

        if let tap = state.pointee.eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = state.pointee.runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let tap = state.pointee.eventTap {
            CFMachPortInvalidate(tap)
        }
        state.pointee.eventTap = nil
        state.pointee.runLoopSource = nil
        state.pointee.leftCommandPressed = false
        state.pointee.rightCommandPressed = false
        state.pointee.otherKeyPressedDuringCommand = false

        state.pointee.retainedSelf?.release()
        state.pointee.retainedSelf = nil
    }

    func toggle() {
        lock.lock()
        defer { lock.unlock() }
        guard let tap = state.pointee.eventTap else { return }
        let current = CGEvent.tapIsEnabled(tap: tap)
        CGEvent.tapEnable(tap: tap, enable: !current)
    }

    // MARK: - Event Handling

    fileprivate func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        lock.lock()
        defer { lock.unlock() }

        // Re-enable tap if it was disabled by the system (timeout)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = state.pointee.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown {
            if state.pointee.leftCommandPressed || state.pointee.rightCommandPressed {
                state.pointee.otherKeyPressedDuringCommand = true
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .flagsChanged else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        switch keyCode {
        case Self.leftCommandKeyCode:
            if flags.contains(.maskCommand) {
                state.pointee.leftCommandPressed = true
                state.pointee.otherKeyPressedDuringCommand = false
            } else if state.pointee.leftCommandPressed {
                state.pointee.leftCommandPressed = false
                if !state.pointee.otherKeyPressedDuringCommand {
                    postKeyEvent(keyCode: Self.eisuuKeyCode)
                }
            }

        case Self.rightCommandKeyCode:
            if flags.contains(.maskCommand) {
                state.pointee.rightCommandPressed = true
                state.pointee.otherKeyPressedDuringCommand = false
            } else if state.pointee.rightCommandPressed {
                state.pointee.rightCommandPressed = false
                if !state.pointee.otherKeyPressedDuringCommand {
                    postKeyEvent(keyCode: Self.kanaKeyCode)
                }
            }

        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    private func postKeyEvent(keyCode: CGKeyCode) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.post(tap: .cgSessionEventTap)
        keyUp?.post(tap: .cgSessionEventTap)
    }
}

// MARK: - C callback

private func eventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passUnretained(event)
    }
    let remapper = Unmanaged<KeyRemapper>.fromOpaque(refcon).takeUnretainedValue()
    return remapper.handleEvent(proxy: proxy, type: type, event: event)
}
