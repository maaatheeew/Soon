# Soon Requirements

Soon is a small native macOS menu bar app for Apple Calendar events.

## Product

- Native macOS app targeting the current macOS 26 machine and built with SwiftUI/AppKit.
- Menu-bar-only behavior: no Dock icon by default.
- Short app name: Soon.
- Visual reference: compact menu bar label with a colored event marker, event title, and countdown; click opens a translucent compact event panel.

## Calendar Source

- Use the system Apple Calendar through EventKit.
- Request Calendar permission with a clear privacy usage description.
- Open Apple Calendar from the menu panel via an `Apple Calendar` action.

## Menu Bar Label

- Show the nearest upcoming or currently running event.
- Format: event title plus relative countdown, for example `Design sync · in 1 h 35 m`.
- Use the event calendar color as the small vertical marker.
- Keep title text compact enough for the menu bar.

## Popover Panel

- Show today's and tomorrow's events only.
- Show the nearest visible event under an `Upcoming ...` heading.
- If there are no events today or tomorrow, show an empty panel state while the menu bar still points to the next later event.
- Include actions:
  - Apple Calendar
  - Calendar Access...
  - Quit Soon Completely

## Refresh Behavior

- Listen for system calendar changes via EventKit so events update as soon as Apple Calendar reports changes.
- Add a fast fallback refresh every 5 seconds while the app is running.
- Debounce system calendar change notifications briefly to avoid duplicate refresh bursts.

## Calendar Access

- Open Apple Calendar and Calendar privacy settings.
