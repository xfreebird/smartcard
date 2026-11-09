import SwiftUI
import WidgetKit

private struct DocumentEntry: TimelineEntry {
    let date: Date
    var language = "system"
    var enabled = false
    var documents: [RecentDocument] = []
}
private struct RecentDocument: Identifiable {
    let id: UUID
    let name: String
    var url: URL { URL(string: "esemnbun://widget/document?id=\(id.uuidString)")! }
}
private struct DocumentProvider: TimelineProvider {
    func placeholder(in context: Context) -> DocumentEntry { DocumentEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (DocumentEntry) -> Void) { completion(read()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DocumentEntry>) -> Void) {
        completion(Timeline(entries: [read()], policy: .after(Date().addingTimeInterval(1800))))
    }
    private func read() -> DocumentEntry {
        let defaults = UserDefaults(suiteName: "group.md.esemnbun.shared")
        let enabled = defaults?.bool(forKey: "widgetDiscoveryEnabled") == true
        let rows = enabled ? (defaults?.array(forKey: "widgetRecentDocuments") as? [[String: String]] ?? []) : []
        let documents = rows.prefix(3).compactMap { row -> RecentDocument? in
            guard let raw = row["id"], let id = UUID(uuidString: raw), let name = row["name"] else { return nil }
            return RecentDocument(id: id, name: name)
        }
        return DocumentEntry(date: .now, language: defaults?.string(forKey: "widgetLanguage") ?? "system", enabled: enabled, documents: documents)
    }
}
private struct DocumentWidgetView: View {
    let entry: DocumentEntry
    @Environment(\.widgetFamily) private var family
    private let blue = Color(red: 0.16, green: 0.29, blue: 0.83)
    var body: some View {
        Group {
            if family == .systemSmall {
                verifyPanel
            } else {
                HStack(spacing: 14) {
                    verifyPanel.frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 8) {
                        Link(destination: URL(string: "esemnbun://widget/documents")!) {
                            HStack(spacing: 4) {
                                Text("shortcut_open_documents").lineLimit(2)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").font(.caption2.bold())
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(minHeight: 32)
                        }
                        if entry.documents.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: entry.enabled ? "doc.text" : "lock.shield")
                                    .font(.title3).foregroundStyle(blue)
                                Text(LocalizedStringKey(entry.enabled ? "widget_no_documents" : "widget_private"))
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(4)
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                        } else {
                            ForEach(entry.documents.prefix(2)) { document in
                                Link(destination: document.url) {
                                    HStack(spacing: 7) {
                                        Image(systemName: "doc.text").foregroundStyle(blue)
                                        Text(document.name).foregroundStyle(.primary)
                                            .lineLimit(2).truncationMode(.middle)
                                    }
                                    .font(.caption).privacySensitive()
                                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .environment(\.locale, entry.language == "system" ? .autoupdatingCurrent : Locale(identifier: entry.language))
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "esemnbun://widget/verify")!)
    }

    private var verifyPanel: some View {
        Link(destination: URL(string: "esemnbun://widget/verify")!) {
            VStack(alignment: .leading, spacing: 8) {
                Text("eSemnBun").font(.caption2.weight(.semibold)).opacity(0.85)
                Spacer(minLength: 0)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 30, weight: .medium))
                    .accessibilityHidden(true)
                HStack(alignment: .bottom, spacing: 4) {
                    Text("shortcut_verify_pdf").font(.headline).lineLimit(2)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").font(.caption.bold())
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(.white)
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [blue, Color(red: 0.10, green: 0.19, blue: 0.59)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

}
@main
struct DocumentsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "eSemnBunDocuments", provider: DocumentProvider()) { DocumentWidgetView(entry: $0) }
            .configurationDisplayName("widget_title")
            .description("widget_description")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
