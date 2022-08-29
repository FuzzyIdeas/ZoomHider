//
//  ZoomHiderApp.swift
//  ZoomHider
//
//  Created by Alin Panaitiu on 21.12.2021.
//

import AXSwift
import Combine
import Defaults
import Lowtech
import LowtechIndie
import Magnet
import SwiftUI

extension Defaults.Keys {
    static let paused = Key<Bool>("paused", default: false)
    static let faster = Key<Bool>("faster", default: false)
    static let enablePauseKey = Key<Bool>("enablePauseKey", default: true)
}

// MARK: - AXWindow

struct AXWindow {
    // MARK: Lifecycle

    init?(from window: UIElement, runningApp: NSRunningApplication? = nil) {
        guard let attrs = try? window.getMultipleAttributes(
            .frame,
            .fullScreen,
            .title,
            .position,
            .main,
            .minimized,
            .size,
            .identifier,
            .subrole,
            .role,
            .focused
        )
        else {
            return nil
        }
        element = window

        let frame = attrs[.frame] as? NSRect ?? NSRect()

        self.frame = frame
        fullScreen = attrs[.fullScreen] as? Bool ?? false
        title = attrs[.title] as? String ?? ""
        position = attrs[.position] as? NSPoint ?? NSPoint()
        main = attrs[.main] as? Bool ?? false
        minimized = attrs[.minimized] as? Bool ?? false
        focused = attrs[.focused] as? Bool ?? false
        size = attrs[.size] as? NSSize ?? NSSize()
        identifier = attrs[.identifier] as? String ?? ""
        subrole = attrs[.subrole] as? String ?? ""
        role = attrs[.role] as? String ?? ""

        self.runningApp = runningApp
    }

    // MARK: Internal

    let element: UIElement
    let frame: NSRect
    let fullScreen: Bool
    let title: String
    let position: NSPoint
    let main: Bool
    let minimized: Bool
    let focused: Bool
    let size: NSSize
    let identifier: String
    let subrole: String
    let role: String
    let runningApp: NSRunningApplication?
}

func acquirePrivileges() {
    let options = [
        kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true as CFBoolean,
    ]
    guard !AXIsProcessTrustedWithOptions(options as CFDictionary) else { return }

    Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
        if AXIsProcessTrusted() {
            timer.invalidate()
            AppDelegate.instance.statusBar?.showPopover(AppDelegate.instance)
        }
    }
}

extension NSRunningApplication {
    func windows() -> [AXWindow]? {
        guard let app = Application(self) else { return nil }
        do {
            let wins = try app.windows()
            return wins?.compactMap { AXWindow(from: $0, runningApp: self) }
        } catch {
            return nil
        }
    }
}

let OFF_SCREEN_POSITION = CGPoint(x: -999_999, y: -999_999)
var oldZoomStatusbarPosition = OFF_SCREEN_POSITION
var oldZoomToolbarPosition = OFF_SCREEN_POSITION

func moveZoom(offScreen: Bool = true) {
    var newStatusbarPosition = offScreen ? OFF_SCREEN_POSITION : oldZoomStatusbarPosition
    var newToolbarPosition = offScreen ? OFF_SCREEN_POSITION : oldZoomToolbarPosition
    let controlCenters = NSRunningApplication.runningApplications(withBundleIdentifier: "us.zoom.xos")
    let windows = controlCenters.compactMap { $0.windows() }.joined()

    guard let statusbarPositionValue = AXValueCreate(.cgPoint, &newStatusbarPosition),
          let toolbarPositionValue = AXValueCreate(.cgPoint, &newToolbarPosition), !windows.isEmpty
    else {
        return
    }

    for window in windows {
        #if DEBUG
            print(window)
        #endif
        if window.title == "zoom share statusbar window" {
            if oldZoomStatusbarPosition == OFF_SCREEN_POSITION {
                oldZoomStatusbarPosition = window.frame.origin
            }
            AXUIElementSetAttributeValue(window.element.element, kAXPositionAttribute as CFString, statusbarPositionValue)
        } else if window.title == "zoom share toolbar window" {
            if oldZoomToolbarPosition == OFF_SCREEN_POSITION {
                oldZoomToolbarPosition = window.frame.origin
            }
            AXUIElementSetAttributeValue(window.element.element, kAXPositionAttribute as CFString, toolbarPositionValue)
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: LowtechIndieAppDelegate {
    static let shared = AppDelegate.instance as! AppDelegate

    var zoomHider: Timer?

    func initZoomHider(timeInterval: TimeInterval) {
        zoomHider?.invalidate()
        zoomHider = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            guard !Defaults[.paused] else { return }
            moveZoom(offScreen: true)
        }
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        showPopoverOnFirstLaunch = false
        KM.specialKey = Defaults[.enablePauseKey] ? "z" : ""
        showPopoverOnSpecialKey = false
        accentColor = Colors.blue.blended(withFraction: 0.3, of: .white)
        contentView = AnyView(erasing: ContentView(app: self))

        #if !DEBUG
            acquirePrivileges()
        #endif

        initZoomHider(timeInterval: Defaults[.faster] ? 0.3 : 1)

        Defaults.publisher(.paused)
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .sink { paused in moveZoom(offScreen: !paused.newValue) }
            .store(in: &observers)

        Defaults.publisher(.faster)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { faster in self.initZoomHider(timeInterval: faster.newValue ? 0.3 : 1) }
            .store(in: &observers)

        Defaults.publisher(.enablePauseKey)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { enableKey in KM.specialKey = enableKey.newValue ? "z" : "" }
            .store(in: &observers)

        super.applicationDidFinishLaunching(notification)

        KM.onSpecialHotkey = {
            Defaults[.paused].toggle()
        }

        updateController.startUpdater()
    }
}

// MARK: - ZoomHiderApp

@main
struct ZoomHiderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }.commands {
            CommandMenu("ZoomHider") {
                Button("Close window") {
                    appDelegate.hidePopover()
                }.keyboardShortcut("w")
                Button("Quit") {
                    NSApp.terminate(appDelegate)
                }.keyboardShortcut("q")
            }
            TextEditingCommands()
            TextFormattingCommands()
        }
    }
}
