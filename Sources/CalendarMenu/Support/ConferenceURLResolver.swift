import EventKit
import Foundation

enum ConferenceURLResolver {
    static func resolve(from event: EKEvent) -> (url: URL, service: ConferenceService)? {
        let candidates = (links(in: event.notes) + links(in: event.location) + [event.url]).compactMap(\.self)

        if let preferred = candidates.compactMap(resolveService(for:)).first(where: { $0.service != .generic }) {
            return preferred
        }

        return candidates.compactMap(resolveService(for:)).first
    }

    private static func links(in text: String?) -> [URL] {
        guard let text, !text.isEmpty else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

        return detector?.matches(in: text, options: [], range: range).compactMap(\.url) ?? []
    }

    private static func resolveService(for url: URL) -> (url: URL, service: ConferenceService)? {
        let host = (url.host ?? "").lowercased()
        let absoluteString = url.absoluteString.lowercased()

        if host.contains("telemost.360.yandex.ru") {
            return (url, .telemost)
        }
        if host.contains("zoom.us") {
            return (url, .zoom)
        }
        if host.contains("meet.google.com") {
            return (url, .googleMeet)
        }
        if host.contains("teams.microsoft.com") {
            return (url, .microsoftTeams)
        }
        if host.contains("facetime.apple.com") {
            return (url, .faceTime)
        }
        if host.contains("webex.com") {
            return (url, .webex)
        }
        if absoluteString.contains("join") || absoluteString.contains("meeting") || absoluteString.contains("conference") {
            return (url, .generic)
        }

        return nil
    }
}
