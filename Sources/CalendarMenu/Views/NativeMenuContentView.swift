import SwiftUI

struct NativeMenuContentView: View {
    @ObservedObject var store: CalendarStore

    var body: some View {
        Group {
            content

            Divider()

            Button("Apple Calendar", action: store.openCalendarApp)
                .keyboardShortcut("1", modifiers: .command)

            Button("Calendar Access...", action: store.openCalendarPrivacySettings)
                .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Soon Completely", action: store.quit)
                .keyboardShortcut("q", modifiers: .command)
        }
        .onAppear {
            store.requestCalendarAccessIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.authorizationStatus {
        case .unknown:
            Text("Loading Calendar")
        case .needsPermission:
            Text("Calendar Access Needed")
            Button("Allow Calendar Access", action: store.requestCalendarAccessIfNeeded)
        case .denied:
            Text("Calendar Access Blocked")
            Button("Open Privacy Settings", action: store.openCalendarPrivacySettings)
        case .fullAccess:
            eventItems
        }
    }

    @ViewBuilder
    private var eventItems: some View {
        if let leadEvent = store.panelLeadEvent {
            Text("Upcoming \(store.relativeStartText(for: leadEvent, compact: false))")
            Button(action: store.openCalendarApp) {
                EventMenuLabel(event: leadEvent)
            }
        } else {
            Text("No events today or tomorrow")

            if let nextEvent = store.nextEvent {
                Text("Next: \(shortTitle(nextEvent.displayTitle)) \(store.relativeStartText(for: nextEvent, compact: true))")
            }
        }

        ForEach(store.panelGroupsExcludingLead) { group in
            Text(groupTitle(for: group.date))

            ForEach(group.events) { event in
                Button(action: store.openCalendarApp) {
                    EventMenuLabel(event: event)
                }
            }
        }
    }

    private func groupTitle(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        return DateFormatters.dayHeader.string(from: date)
    }

    private func shortTitle(_ title: String) -> String {
        let maxLength = 30
        guard title.count > maxLength else {
            return title
        }

        return "\(title.prefix(maxLength - 1))..."
    }
}

private struct EventMenuLabel: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(event.color.color)
                .frame(width: 4, height: 16)

            Text("\(timeText) · \(shortTitle(event.displayTitle))")
                .lineLimit(1)
        }
    }

    private var timeText: String {
        if event.isAllDay {
            return "All day"
        }
        return DateFormatters.time.string(from: event.startDate)
    }

    private func shortTitle(_ title: String) -> String {
        let maxLength = 30
        guard title.count > maxLength else {
            return title
        }

        return "\(title.prefix(maxLength - 1))..."
    }
}
