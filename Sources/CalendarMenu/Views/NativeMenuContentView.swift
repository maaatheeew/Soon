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
            eventMenuItems(for: leadEvent, showsDetails: true)
        } else {
            Text("No events today or tomorrow")

            if let nextEvent = store.nextEvent {
                Text("Next: \(nextEvent.displayTitle) \(store.relativeStartText(for: nextEvent, compact: true))")
                    .lineLimit(2)
            }
        }

        ForEach(store.panelGroupsExcludingLead) { group in
            Text(groupTitle(for: group.date))

            ForEach(group.events) { event in
                eventMenuItems(for: event, showsDetails: false)
            }
        }
    }

    @ViewBuilder
    private func eventMenuItems(for event: CalendarEvent, showsDetails: Bool) -> some View {
        Button(eventTitle(for: event, includesLocation: showsDetails), action: { store.openEventInCalendar(event) })

        if showsDetails, let conferenceService = event.conferenceService {
            Button(conferenceService.joinTitle, action: { store.joinVideoMeeting(event) })
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

    private func eventTitle(for event: CalendarEvent, includesLocation: Bool) -> String {
        let value = "\(timeText(for: event)) · \(displayTitle(for: event, includesLocation: includesLocation))"
        return twoLineMenuTitle(value)
    }

    private func timeText(for event: CalendarEvent) -> String {
        if event.isAllDay {
            return "All day"
        }
        return DateFormatters.time.string(from: event.startDate)
    }

    private func displayTitle(for event: CalendarEvent, includesLocation: Bool) -> String {
        guard includesLocation, let locationText = locationText(for: event) else {
            return event.displayTitle
        }

        return "\(event.displayTitle) (\(locationText))"
    }

    private func locationText(for event: CalendarEvent) -> String? {
        guard let location = event.location?.trimmingCharacters(in: .whitespacesAndNewlines),
              !location.isEmpty else {
            return nil
        }

        return location
    }

    private func twoLineMenuTitle(_ value: String) -> String {
        let firstLineLimit = 44
        let secondLineLimit = 56

        guard value.count > firstLineLimit else {
            return value
        }

        let firstBreak = value[..<value.index(value.startIndex, offsetBy: firstLineLimit)]
            .lastIndex(of: " ") ?? value.index(value.startIndex, offsetBy: firstLineLimit)
        let firstLine = value[..<firstBreak].trimmingCharacters(in: .whitespaces)
        var secondLine = value[firstBreak...].trimmingCharacters(in: .whitespaces)

        if secondLine.count > secondLineLimit {
            secondLine = "\(secondLine.prefix(secondLineLimit - 1))..."
        }

        return "\(firstLine)\n\(secondLine)"
    }
}
