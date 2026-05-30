import AppKit
import Combine
import EventKit

final class CalendarStore: ObservableObject {
    @Published private(set) var events: [CalendarEvent] = []
    @Published private(set) var authorizationStatus: CalendarAuthorizationStatus = .unknown
    @Published private(set) var lastRefreshDate: Date?
    @Published private(set) var lastErrorMessage: String?

    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?
    private var changeObserver: NSObjectProtocol?
    private var debounceWorkItem: DispatchWorkItem?

    init() {
        UserDefaults.standard.register(defaults: [
            PreferenceKeys.lookaheadDays: 30,
            PreferenceKeys.includeAllDayEvents: true
        ])
        updateAuthorizationStatus()
        observeCalendarChanges()
        startFastRefreshTimer()
        requestCalendarAccessIfNeeded()
    }

    deinit {
        refreshTimer?.invalidate()
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    var nextEvent: CalendarEvent? {
        events.first
    }

    var statusBarEvent: CalendarEvent? {
        events.first { !$0.isAllDay }
    }

    var panelEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today) ?? now

        return events.filter { event in
            event.startDate < dayAfterTomorrow
        }
    }

    var panelCurrentEvents: [CalendarEvent] {
        let now = Date()

        return panelEvents.filter { event in
            !event.isAllDay && event.startDate <= now && event.endDate > now
        }
    }

    var panelUpcomingEvents: [CalendarEvent] {
        let now = Date()

        return panelEvents.filter { event in
            !event.isAllDay && event.startDate > now
        }
    }

    var panelAllDayEvents: [CalendarEvent] {
        panelEvents.filter(\.isAllDay)
    }

    var menuBarStatusText: String {
        switch authorizationStatus {
        case .fullAccess:
            guard let statusBarEvent else {
                return "No events"
            }
            return "\(trimmedForMenu(statusBarEvent.displayTitle)) · \(relativeStartText(for: statusBarEvent, compact: true))"
        case .needsPermission:
            return "Calendar access"
        case .denied:
            return "Calendar blocked"
        case .unknown:
            return "Loading calendar"
        }
    }

    func requestCalendarAccessIfNeeded() {
        updateAuthorizationStatus()

        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            refreshNow()
        case .notDetermined:
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.lastErrorMessage = error?.localizedDescription
                    self?.authorizationStatus = granted ? .fullAccess : .denied
                    if granted {
                        self?.refreshNow()
                    }
                }
            }
        case .denied, .restricted, .writeOnly:
            authorizationStatus = .denied
            events = []
        @unknown default:
            authorizationStatus = .denied
            events = []
        }
    }

    func refreshNow() {
        updateAuthorizationStatus()

        guard authorizationStatus == .fullAccess else {
            events = []
            return
        }

        let now = Date()
        let calendar = Calendar.current
        let storedLookaheadDays = UserDefaults.standard.object(forKey: PreferenceKeys.lookaheadDays) as? Int ?? 30
        let lookaheadDays = max(1, storedLookaheadDays)
        let includeAllDay = UserDefaults.standard.object(forKey: PreferenceKeys.includeAllDayEvents) as? Bool ?? true
        let endDate = calendar.date(byAdding: .day, value: lookaheadDays, to: now) ?? now.addingTimeInterval(7 * 24 * 60 * 60)
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: nil)

        let mappedEvents = eventStore.events(matching: predicate)
            .filter { event in
                event.endDate > now && (includeAllDay || !event.isAllDay)
            }
            .sorted { lhs, rhs in
                if lhs.startDate == rhs.startDate {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.startDate < rhs.startDate
            }
            .map(CalendarEvent.init(event:))

        events = mappedEvents
        lastRefreshDate = now
        lastErrorMessage = nil
    }

    func openCalendarApp() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
    }

    func openEventInCalendar(_ event: CalendarEvent) {
        openCalendarApp()
    }

    func joinVideoMeeting(_ event: CalendarEvent) {
        guard let conferenceURL = event.conferenceURL else {
            return
        }

        NSWorkspace.shared.open(conferenceURL)
    }

    func openCalendarPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    func relativeStartText(for event: CalendarEvent, compact: Bool) -> String {
        let now = Date()

        if event.startDate <= now && event.endDate > now {
            return "now"
        }

        let interval = max(0, Int(event.startDate.timeIntervalSince(now)))
        let days = interval / 86_400
        let hours = (interval % 86_400) / 3_600
        let minutes = max(1, (interval % 3_600) / 60)

        if compact {
            if days > 0 {
                return "in \(days) d \(hours) h"
            }
            if hours > 0 {
                return "in \(hours) h \(minutes) m"
            }
            return "in \(minutes) m"
        }

        if days > 0 {
            return "in \(days) d \(hours) h"
        }
        if hours > 0 {
            return "in \(hours) h \(minutes) min"
        }
        return "in \(minutes) min"
    }

    private func updateAuthorizationStatus() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            authorizationStatus = .fullAccess
        case .notDetermined:
            authorizationStatus = .needsPermission
        case .denied, .restricted, .writeOnly:
            authorizationStatus = .denied
        @unknown default:
            authorizationStatus = .denied
        }
    }

    private func observeCalendarChanges() {
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleDebouncedRefresh()
        }
    }

    private func scheduleDebouncedRefresh() {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.refreshNow()
        }

        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private func startFastRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refreshNow()
        }
        refreshTimer?.tolerance = 1
    }

    private func trimmedForMenu(_ title: String) -> String {
        let maxLength = 28
        guard title.count > maxLength else {
            return title
        }

        let prefix = title.prefix(maxLength - 1)
        return "\(prefix)..."
    }
}

enum CalendarAuthorizationStatus {
    case unknown
    case needsPermission
    case fullAccess
    case denied
}

enum PreferenceKeys {
    static let lookaheadDays = "lookaheadDays"
    static let includeAllDayEvents = "includeAllDayEvents"
}

private extension CalendarEvent {
    init(event: EKEvent) {
        let conference = ConferenceURLResolver.resolve(from: event)

        self.init(
            id: event.eventIdentifier ?? "\(event.startDate.timeIntervalSince1970)-\(event.title ?? "")",
            title: event.title ?? "",
            startDate: event.startDate,
            endDate: event.endDate,
            calendarTitle: event.calendar.title,
            color: CalendarEventColor(cgColor: event.calendar.cgColor),
            isAllDay: event.isAllDay,
            location: event.location,
            conferenceURL: conference?.url,
            conferenceService: conference?.service
        )
    }
}

private extension CalendarEventColor {
    init(cgColor: CGColor?) {
        guard let cgColor, let nsColor = NSColor(cgColor: cgColor)?.usingColorSpace(.sRGB) else {
            self = .fallback
            return
        }

        self.init(
            red: Double(nsColor.redComponent),
            green: Double(nsColor.greenComponent),
            blue: Double(nsColor.blueComponent),
            alpha: Double(nsColor.alphaComponent)
        )
    }
}
