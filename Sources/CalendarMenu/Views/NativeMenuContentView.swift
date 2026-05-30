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
        if store.panelEvents.isEmpty {
            Text("No events today or tomorrow")

            if let nextEvent = store.nextEvent {
                Text("Next: \(nextEvent.displayTitle) \(store.relativeStartText(for: nextEvent, compact: true))")
                    .lineLimit(2)
            }
        }

        if !store.panelCurrentEvents.isEmpty {
            Text("Now")

            ForEach(store.panelCurrentEvents) { event in
                eventMenuItems(for: event, showsDetails: true)
            }
        }

        if !store.panelUpcomingEvents.isEmpty {
            Text("Upcoming")

            ForEach(store.panelUpcomingEvents) { event in
                eventMenuItems(for: event, showsDetails: false)
            }
        }

        if !store.panelAllDayEvents.isEmpty {
            Text("All day")

            ForEach(store.panelAllDayEvents) { event in
                allDayEventMenuItem(for: event)
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

    private func allDayEventMenuItem(for event: CalendarEvent) -> some View {
        Button(twoLineMenuTitle(displayTitle(for: event, includesLocation: false)), action: { store.openEventInCalendar(event) })
    }

    private func eventTitle(for event: CalendarEvent, includesLocation: Bool) -> String {
        let value = "\(timeText(for: event)) · \(displayTitle(for: event, includesLocation: includesLocation))"
        return twoLineMenuTitle(value)
    }

    private func timeText(for event: CalendarEvent) -> String {
        let calendar = Calendar.current
        let time = DateFormatters.time.string(from: event.startDate)

        if calendar.isDateInToday(event.startDate) {
            return time
        }
        if calendar.isDateInTomorrow(event.startDate) {
            return "Tomorrow \(time)"
        }

        return "\(DateFormatters.dayHeader.string(from: event.startDate)) \(time)"
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
