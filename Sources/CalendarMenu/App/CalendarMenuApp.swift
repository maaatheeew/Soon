import AppKit
import SwiftUI

@main
struct CalendarMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var calendarStore = CalendarStore()

    var body: some Scene {
        MenuBarExtra {
            NativeMenuContentView(store: calendarStore)
                .environmentObject(calendarStore)
        } label: {
            MenuBarLabel(event: calendarStore.nextEvent, statusText: calendarStore.menuBarStatusText)
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
