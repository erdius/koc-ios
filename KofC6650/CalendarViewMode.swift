import SwiftUI

/// Global agenda-vs-month display preference for the Sign Ups and Calendar
/// tabs. A singleton (matches FontScale/AppearanceMode's pattern) so
/// switching it on one tab's toggle is instantly reflected on the other.
final class CalendarViewMode: ObservableObject {
    static let shared = CalendarViewMode()

    enum Mode: String, CaseIterable, Identifiable {
        case agenda = "Agenda"
        case month = "Month"

        var id: String { rawValue }
    }

    @Published var mode: Mode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.key) }
    }

    private static let key = "kofc_calendar_view_mode"

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.key)
        mode = Mode.allCases.first { $0.rawValue == saved } ?? .agenda
    }
}

struct CalendarViewModeToggle: View {
    @ObservedObject private var viewMode = CalendarViewMode.shared

    var body: some View {
        Picker("View", selection: $viewMode.mode) {
            ForEach(CalendarViewMode.Mode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}
