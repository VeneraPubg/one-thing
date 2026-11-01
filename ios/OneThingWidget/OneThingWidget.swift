import WidgetKit
import SwiftUI

/// iOS WidgetKit extension for One Thing.
/// Reads task data from the shared App Group UserDefaults
/// written by the Flutter side via the home_widget package.
///
/// Setup steps:
/// 1. In Xcode: File → New → Target → Widget Extension → name "OneThingWidget"
/// 2. Add the App Group "group.com.onething.app" to both the main app
///    and the widget extension targets.
/// 3. Replace the generated files with this one.
/// 4. In Info.plist of the main app add the URL scheme "onething"
///    (CFBundleURLTypes) for checkbox taps.

private let appGroupId = "group.com.onething.app"

struct TaskSlot: Codable, Identifiable {
    let id: String
    let title: String
    let isDone: Bool
}

struct WidgetEntryModel: TimelineEntry {
    let date: Date
    let dateLabel: String
    let tasks: [TaskSlot]
    let counterLabel: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntryModel {
        WidgetEntryModel(
            date: Date(),
            dateLabel: "СЕГОДНЯ",
            tasks: [
                TaskSlot(id: "1", title: "Задача", isDone: false),
                TaskSlot(id: "2", title: "Задача", isDone: false),
                TaskSlot(id: "3", title: "Задача", isDone: false),
            ],
            counterLabel: "0 из 3 сделано"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntryModel) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntryModel>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> WidgetEntryModel {
        let defaults = UserDefaults(suiteName: appGroupId)

        let dateLabel = defaults?.string(forKey: "widget.date") ?? "СЕГОДНЯ"
        let counterLabel = defaults?.string(forKey: "widget.counter") ?? "0 из 3 сделано"

        var tasks: [TaskSlot] = []
        if let raw = defaults?.string(forKey: "widget.tasks"), !raw.isEmpty {
            tasks = raw
                .components(separatedBy: ";;")
                .compactMap { entry -> TaskSlot? in
                    let parts = entry.components(separatedBy: "|")
                    guard parts.count >= 3 else { return nil }
                    let isDone = parts[1] == "1"
                    return TaskSlot(id: parts[0], title: parts[2], isDone: isDone)
                }
        }

        return WidgetEntryModel(
            date: Date(),
            dateLabel: dateLabel,
            tasks: tasks,
            counterLabel: counterLabel
        )
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: WidgetEntryModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.dateLabel.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.43, green: 0.43, blue: 0.45))
                .kerning(0.5)

            ForEach(Array(entry.tasks.enumerated()), id: \.element.id) { _, task in
                HStack(spacing: 8) {
                    ToggleTaskButton(task: task)
                    Text(task.title)
                        .font(.footnote)
                        .strikethrough(task.isDone)
                        .foregroundColor(
                            task.isDone
                                ? Color(red: 0.43, green: 0.43, blue: 0.45)
                                : Color(red: 0.11, green: 0.11, blue: 0.12)
                        )
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }

            if family != .systemSmall {
                Text(entry.counterLabel)
                    .font(.caption2)
                    .foregroundColor(Color(red: 0.26, green: 0.40, blue: 0.30))
            }
        }
        .padding(12)
        .widgetURL(URL(string: "onething://today"))
    }
}

struct ToggleTaskButton: View {
    let task: TaskSlot

    var body: some View {
        Link(destination: URL(string: "onething://toggleTask?taskId=\(task.id)")!) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        task.isDone ? Color.clear : Color(red: 0.78, green: 0.79, blue: 0.75),
                        lineWidth: 1.5
                    )
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                task.isDone
                                    ? Color(red: 0.26, green: 0.40, blue: 0.30)
                                    : Color.clear
                            )
                    )

                if task.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .accessibilityLabel(task.isDone ? "Отменить выполнение" : "Отметить выполненной")
    }
}

@main
struct OneThingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OneThingWidget", provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("One Thing")
        .description("3 задачи на день и итог вечера.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
