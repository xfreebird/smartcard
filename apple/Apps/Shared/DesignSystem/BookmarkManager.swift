import SwiftUI

@MainActor @Observable
final class BrowserBookmarks {
    private let repository = BookmarkRepository(preferences: AppPreferencesStore.defaults)
    var items: [BrowserBookmark] {
        didSet { repository.save(items) }
    }
    init() {
        items = repository.load(defaults: PortalService.all.map {
            BrowserBookmark(id: $0.id, title: $0.title, url: $0.url, icon: "globe", assetName: $0.imageName)
        })
    }
    func save(_ item: BrowserBookmark) {
        if let index = items.firstIndex(where: { $0.id == item.id }) { items[index] = item }
        else { items.append(item) }
    }
    func remove(_ item: BrowserBookmark) { items.removeAll { $0.id == item.id } }
}

struct BookmarkIcon: View {
    let bookmark: BrowserBookmark
    var body: some View {
        if let asset = bookmark.assetName {
            #if os(macOS)
            Image(nsImage: menuImage(asset)).renderingMode(.original)
            #else
            Image(asset).resizable().renderingMode(.original).scaledToFit().frame(width: 20, height: 20)
            #endif
        } else {
            Image(systemName: bookmark.symbol)
        }
    }
    #if os(macOS)
    private func menuImage(_ asset: String) -> NSImage {
        let image = (NSImage(named: asset)?.copy() as? NSImage) ?? NSImage(size: NSSize(width: 18, height: 18))
        image.size = NSSize(width: 18, height: 18)
        return image
    }
    #endif
}

/// One editor for macOS, iPhone and iPad. Deletions are local and never affect browser history.
struct BookmarkManager: View {
    let bookmarks: BrowserBookmarks
    let currentURL: URL?
    let currentTitle: String?
    @Environment(\.dismiss) private var dismiss
    @State private var editing: BrowserBookmark?
    @State private var title = ""
    @State private var address = ""
    @State private var icon = "globe"
    @State private var selectedAsset: String?

    private var candidate: BrowserBookmark? {
        BrowserBookmark.make(id: editing?.id ?? UUID().uuidString, title: title, address: address, icon: icon)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.text(.browser_bookmark_manage)).font(.title2.bold())
                Spacer()
                Button(L10n.text(.ui_done)) { dismiss() }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    bookmarkRows
                    Divider()
                    editorFields
                }
            }
            HStack {
                Button(L10n.text(.browser_bookmark_add)) { reset() }
                Spacer()
                Button(L10n.text(.browser_bookmark_save)) {
                    guard var item = candidate else { return }
                    item.assetName = selectedAsset
                    bookmarks.save(item)
                    reset()
                }
                .buttonStyle(.borderedProminent)
                .disabled(candidate == nil)
                .accessibilityIdentifier("bookmark.save")
            }
        }
        .padding(24)
        #if os(macOS)
        .frame(minWidth: 480, idealWidth: 540, minHeight: 520, idealHeight: 600)
        #else
        .presentationDetents([.large])
        #endif
        .onAppear { reset() }
    }

    private var bookmarkRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            if bookmarks.items.isEmpty {
                Text(L10n.text(.browser_bookmark_empty)).foregroundStyle(.secondary)
            }
            ForEach(bookmarks.items) { item in
                HStack(spacing: 12) {
                    Button { edit(item) } label: {
                        HStack(spacing: 12) {
                            BookmarkIcon(bookmark: item).frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).fontWeight(.medium)
                                Text(item.url.absoluteString).font(.callout).foregroundStyle(.secondary)
                                    .lineLimit(2).truncationMode(.middle)
                            }
                            Spacer(minLength: 0)
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Button(role: .destructive) {
                        bookmarks.remove(item)
                        if editing?.id == item.id { reset() }
                    } label: { Image(systemName: "trash").frame(minWidth: 44, minHeight: 44) }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("\(L10n.text(.ui_delete)): \(item.title)")
                }.padding(.vertical, 4)
            }
        }.frame(maxWidth: .infinity)
    }

    private var editorFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text(editing == nil ? .browser_bookmark_add : .browser_bookmark_edit)).font(.headline)
            TextField(L10n.text(.browser_bookmark_title), text: $title).textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("bookmark.title")
            TextField(L10n.text(.ui_https_example_md), text: $address).textFieldStyle(.roundedBorder)
                .accessibilityLabel(L10n.text(.ui_open_an_address))
                .accessibilityIdentifier("bookmark.url")
                #if os(iOS)
                .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                #endif
            Text(L10n.text(.browser_bookmark_icon)).font(.callout)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { iconChoices }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) { iconChoices }
            }
            if candidate == nil && (!title.isEmpty || !address.isEmpty) {
                Text(L10n.text(.browser_bookmark_invalid)).font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private var iconChoices: some View {
        ForEach(BrowserBookmark.icons, id: \.self) { value in
            Button {
                icon = value
                selectedAsset = nil
            } label: {
                Image(systemName: BrowserBookmark.symbol(for: value))
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(icon == value && selectedAsset == nil ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(icon == value && selectedAsset == nil ? Color.accentColor : Color.clear, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .help(iconTitle(value))
            .accessibilityLabel(iconTitle(value))
            .accessibilityAddTraits(icon == value && selectedAsset == nil ? .isSelected : [])
        }
    }

    private func reset() {
        editing = nil
        title = currentTitle ?? currentURL?.host ?? ""
        address = currentURL?.absoluteString ?? ""
        icon = "globe"
        selectedAsset = nil
    }
    private func edit(_ item: BrowserBookmark) {
        editing = item
        title = item.title
        address = item.url.absoluteString
        icon = item.icon
        selectedAsset = item.assetName
    }
    private func iconTitle(_ icon: String) -> String {
        switch icon {
        case "bookmark": return L10n.text(.browser_bookmark_icon_bookmark)
        case "document": return L10n.text(.browser_bookmark_icon_document)
        case "person": return L10n.text(.browser_bookmark_icon_person)
        case "building": return L10n.text(.browser_bookmark_icon_building)
        case "star": return L10n.text(.browser_bookmark_icon_star)
        default: return L10n.text(.browser_bookmark_icon_globe)
        }
    }
}
