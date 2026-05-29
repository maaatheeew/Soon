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
    let conferenceService: ConferenceService?

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

enum ConferenceService: Equatable {
    case telemost
    case zoom
    case googleMeet
    case microsoftTeams
    case faceTime
    case webex
    case generic

    var joinTitle: String {
        switch self {
        case .telemost:
            return "Join Telemost"
        case .zoom:
            return "Join Zoom"
        case .googleMeet:
            return "Join Google Meet"
        case .microsoftTeams:
            return "Join Microsoft Teams"
        case .faceTime:
            return "Join FaceTime"
        case .webex:
            return "Join Webex"
        case .generic:
            return "Join Video Meeting"
        }
    }
}
