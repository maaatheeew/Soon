import EventKit
import Foundation

enum ConferenceURLResolver {
    static func resolve(from event: EKEvent) -> URL? {
        let candidates = ([event.url] + links(in: event.notes)).compactMap(\.self)

        return candidates.first(where: isLikelyConferenceURL) ?? candidates.first
    }

    private static func links(in text: String?) -> [URL] {
        guard let text, !text.isEmpty else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

        return detector?.matches(in: text, options: [], range: range).compactMap(\.url) ?? []
    }

    private static func isLikelyConferenceURL(_ url: URL) -> Bool {
        let host = (url.host ?? "").lowercased()
        let absoluteString = url.absoluteString.lowercased()

        return [
            "zoom.us",
            "meet.google.com",
            "teams.microsoft.com",
            "facetime.apple.com",
            "webex.com",
            "whereby.com",
            "notion.so",
            "around.co",
            "discord.gg"
        ].contains { host.contains($0) || absoluteString.contains($0) }
    }
}
