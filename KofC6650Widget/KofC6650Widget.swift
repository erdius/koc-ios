import WidgetKit
import SwiftUI

private let navy = Color(red: 0x1A / 255, green: 0x2F / 255, blue: 0x5E / 255)
private let gold = Color(red: 0xC9 / 255, green: 0xA8 / 255, blue: 0x4C / 255)

struct NextEventEntry: TimelineEntry {
    let date: Date
    let info: NextEventInfo?
}

struct NextEventProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextEventEntry {
        NextEventEntry(date: Date(), info: NextEventInfo(title: "Council Meeting", dateDisplay: "Thu, Aug 20", time: "7:00 PM", location: "Council Hall"))
    }

    func getSnapshot(in context: Context, completion: @escaping (NextEventEntry) -> Void) {
        completion(NextEventEntry(date: Date(), info: NextEventInfo.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextEventEntry>) -> Void) {
        let entry = NextEventEntry(date: Date(), info: NextEventInfo.load())
        // The app itself pushes a fresh reload whenever events change; this
        // periodic refresh is just a fallback in case that never fires
        // (e.g. the app hasn't been opened in a while).
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(6 * 3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct KofC6650WidgetEntryView: View {
    var entry: NextEventProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT EVENT")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(gold)
                .tracking(1)

            if let info = entry.info {
                Text(info.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Spacer(minLength: 2)

                Text(info.dateDisplay + (info.time.map { " · \($0)" } ?? ""))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))

                if let location = info.location, !location.isEmpty {
                    Text(location)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            } else {
                Spacer(minLength: 2)
                Text("No upcoming events")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetBackground(navy)
    }
}

private extension View {
    /// iOS 17 requires containerBackground(for: .widget) -- widgets built
    /// with a plain .background show a deprecation warning there and can
    /// render with unwanted default padding. iOS 16 doesn't have that API
    /// at all, so this falls back to a plain background on that OS.
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(color, for: .widget)
        } else {
            background(color)
        }
    }
}

struct KofC6650Widget: Widget {
    let kind: String = "KofC6650Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextEventProvider()) { entry in
            KofC6650WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Event")
        .description("Shows the next upcoming council event.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct KofC6650WidgetBundle: WidgetBundle {
    var body: some Widget {
        KofC6650Widget()
    }
}
