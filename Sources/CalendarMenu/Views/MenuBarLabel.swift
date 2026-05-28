import SwiftUI

struct MenuBarLabel: View {
    let event: CalendarEvent?
    let statusText: String

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(event?.color.color ?? Color.secondary)
                .frame(width: 7, height: 24)

            Text(statusText)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .lineLimit(1)
                .truncationMode(.tail)
                .monospacedDigit()
        }
        .frame(maxWidth: 300)
        .padding(.horizontal, 2)
    }
}
