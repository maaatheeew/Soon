import SwiftUI

struct CalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarTitle: String
    let color: CalendarEventColor
    let isAllDay: Bool
    let location: String?
    let conferenceURL: URL?

    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled event" : title
    }
}

struct CalendarEventColor: Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    static let fallback = CalendarEventColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1)

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct EventDayGroup: Identifiable {
    let date: Date
    let events: [CalendarEvent]

    var id: Date { date }
}
