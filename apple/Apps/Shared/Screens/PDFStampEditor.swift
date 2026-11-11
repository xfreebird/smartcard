import SwiftUI
import PDFKit
import MoldSignKit

/// Reads a private in-memory copy; never writes or flattens the source PDF.
struct PDFStampEditor: View {
    let url: URL
    let initial: PDFStampPlacement?
    let holder: String
    let save: (PDFStampPlacement?) -> Void
    var onCancel: (() -> Void)? = nil
    var requester: String? = nil
    var onBatch: ((PDFStampPlacement?) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var placement = PDFStampPlacement()
    @State private var document: PDFDocument?
    @State private var error: String?
    @State private var enabled = true
    @State private var answered = false
    @State private var applyToQueue = false
    @State private var resizeStart: PDFStampPlacement?
    @State private var moveStart: PDFStampPlacement?
    @State private var visiblePage: Int? = 0

    var body: some View {
        Group {
        #if os(macOS)
            desktopEditor
        #else
        NavigationStack {
            VStack(spacing: 0) {
                if let requester { Text(requester).font(.callout).foregroundStyle(.secondary).padding(.horizontal) }
                if let document, document.pageCount > 0 {
                    GeometryReader { geometry in
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0) {
                                ForEach(0..<document.pageCount, id: \.self) { index in
                                    if let page = document.page(at: index) {
                                        preview(page, pageIndex: index)
                                            .padding(12)
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .id(index)
                                    }
                                }
                            }.scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging)
                        .scrollPosition(id: $visiblePage)
                        .onChange(of: visiblePage) { _, page in
                            if let page { placement.page = page }
                        }
                    }.background(.gray.opacity(0.06))
                    VStack(spacing: 4) {
                        HStack(spacing: 24) {
                            Button { withAnimation { visiblePage = max(0, placement.page - 1) } } label: {
                                Image(systemName: "chevron.left").font(.title3.weight(.semibold)).frame(width: 48, height: 48)
                                    .background(placement.page == 0 ? Color.secondary.opacity(0.12) : Color.accentColor.opacity(0.12), in: Circle())
                            }.disabled(placement.page == 0).accessibilityLabel(L10n.text(.stamp_previous_page))
                            Text("\(L10n.text(.stamp_page_label)) \(placement.page + 1) / \(document.pageCount)").monospacedDigit()
                            Button { withAnimation { visiblePage = min(document.pageCount - 1, placement.page + 1) } } label: {
                                Image(systemName: "chevron.right").font(.title3.weight(.semibold)).frame(width: 48, height: 48)
                                    .background(placement.page + 1 >= document.pageCount ? Color.secondary.opacity(0.12) : Color.accentColor.opacity(0.12), in: Circle())
                            }.disabled(placement.page + 1 >= document.pageCount).accessibilityLabel(L10n.text(.stamp_next_page))
                        }.buttonStyle(.plain).frame(maxWidth: .infinity).padding(.top, 12)
                        Picker(L10n.text(.stamp_visible), selection: Binding(
                            get: { !enabled ? 0 : (placement.allPages ? 2 : 1) },
                            set: { mode in enabled = mode != 0; if mode != 0 { placement.allPages = mode == 2 } }
                        )) {
                            Text(L10n.text(.stamp_off)).tag(0)
                            Text(L10n.text(.stamp_single)).tag(1)
                            Text(L10n.text(.stamp_every)).tag(2)
                        }.pickerStyle(.segmented).padding(.vertical, 8)
                        if onBatch != nil {
                            Divider()
                            Toggle(L10n.text(.stamp_queue), isOn: $applyToQueue).font(.subheadline).frame(minHeight: 44)
                        }
                    }.padding(.horizontal, 20).padding(.bottom, 8).background(.regularMaterial)
                } else if let error { Text(error).foregroundStyle(.red).padding() }
                else { ProgressView() }
            }
            .navigationTitle(L10n.text(.stamp_title))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.text(.ui_cancel)) { answered = true; onCancel?(); dismiss() }.accessibilityIdentifier("stamp.cancel") }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text(.stamp_save)) {
                        answered = true
                        let value = enabled ? placement : nil
                        save(value)
                        if applyToQueue { onBatch?(value) }
                        dismiss()
                    }
                        .disabled(enabled && document == nil)
                }
            }
        }
        #endif
        }
        .onDisappear { if !answered { onCancel?() } }
        .task {
            placement = initial ?? PDFStampPlacement()
            let preference = AppPreferencesStore.defaults.string(forKey: "appLanguage") ?? "system"
            placement.language = PDFStampLanguage(localeIdentifier: preference == "system" ? (Locale.preferredLanguages.first ?? "ro") : preference)
            visiblePage = placement.page
            enabled = true
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                guard let pdf = PDFDocument(data: data), !pdf.isLocked, pdf.pageCount > 0 else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                placement = placement.bound(to: data)
                document = pdf
            } catch { self.error = error.localizedDescription }
        }
    }

    #if os(macOS)
    private var desktopEditor: some View {
        HStack(spacing: 0) {
            ScrollViewReader { scroll in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let document {
                            ForEach(0..<document.pageCount, id: \.self) { index in
                                if let page = document.page(at: index) {
                                    let box = page.bounds(for: .cropBox)
                                    let ratio = page.rotation % 180 == 0 ? box.width/box.height : box.height/box.width
                                    preview(page, pageIndex: index)
                                        .frame(width: 288, height: 288/ratio)
                                        .background(.white)
                                        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                                        .overlay(alignment: .bottom) {
                                            HStack(spacing: 6) {
                                                if placement.allPages || placement.page == index {
                                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                                                }
                                                Text("\(index + 1) / \(document.pageCount)").monospacedDigit()
                                            }.font(.callout).padding(.horizontal, 12).padding(.vertical, 6)
                                                .background(.regularMaterial, in: Capsule()).padding(.bottom, 8)
                                                .allowsHitTesting(false)
                                        }
                                        .id(index)
                                }
                            }
                        } else if let error { Text(error).foregroundStyle(.red).padding() }
                        else { ProgressView().padding(40) }
                    }.padding(16)
                }.onChange(of: document?.pageCount) { _, _ in
                    DispatchQueue.main.async { scroll.scrollTo(0, anchor: .top) }
                }
            }.frame(width: 320).background(.quaternary.opacity(0.4))
            Divider()
            VStack(spacing: 0) {
                Form {
                    Section {
                        LabeledContent(L10n.text(.stamp_title)) {
                            Toggle(L10n.text(.stamp_visible), isOn: $enabled).labelsHidden().toggleStyle(.switch)
                        }
                        LabeledContent(L10n.text(.ui_document)) {
                            Text(url.lastPathComponent).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                        }
                    }
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.text(.stamp_scope))
                            Picker(L10n.text(.stamp_scope), selection: $placement.allPages) {
                                Text(L10n.text(.stamp_selected_page)).tag(false)
                                Text(L10n.text(.stamp_all_pages)).tag(true)
                            }.labelsHidden().pickerStyle(.radioGroup).disabled(!enabled)
                        }.padding(.vertical, 4)
                        if onBatch != nil {
                            Toggle(L10n.text(.stamp_queue), isOn: $applyToQueue).toggleStyle(.switch)
                        }
                    } footer: {
                        Text(L10n.text(.stamp_move_hint))
                    }
                    if let requester {
                        Section { Text(requester).font(.callout).foregroundStyle(.secondary) }
                    }
                }.formStyle(.grouped)
                HStack(spacing: 12) {
                    Spacer()
                    Button { answered = true; onCancel?(); dismiss() } label: {
                        Text(L10n.text(.ui_cancel)).frame(minWidth: 64)
                    }.accessibilityIdentifier("stamp.cancel").keyboardShortcut(.cancelAction)
                    Button {
                        answered = true
                        let value = enabled ? placement : nil
                        save(value)
                        if applyToQueue { onBatch?(value) }
                        dismiss()
                    } label: { Text(L10n.text(.stamp_save)).frame(minWidth: 64) }
                        .keyboardShortcut(.defaultAction).disabled(enabled && document == nil)
                }.controlSize(.regular).padding(20)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.frame(width: 820, height: 620)
    }
    #endif

    private var pageRatio: Double {
        guard let page = document?.page(at: placement.page) else { return 0.707 }
        let box = page.bounds(for: .cropBox)
        return page.rotation % 180 == 0 ? box.width / box.height : box.height / box.width
    }

    private var stampArtwork: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 240
            let vertical = geometry.size.height / 96
            let lines = placement.language.lines(holder: holder, date: Date())
            ZStack(alignment: .topLeading) {
                Rectangle().stroke(.gray.opacity(0.65), lineWidth: 0.5 * scale)
                    .frame(width: 174 * scale, height: 21 * vertical)
                    .offset(x: 0.5 * scale, y: 65 * vertical)
                ForEach(0..<6, id: \.self) { index in
                    Text(verbatim: lines[index])
                        .font(.custom("TimesNewRomanPSMT", size: (index == 5 ? 7 : 13) * scale))
                        .foregroundStyle(.black).lineLimit(1).minimumScaleFactor(0.01)
                        .frame(width: (index == 4 ? 164 : 228) * scale, alignment: .leading)
                        .offset(x: (index == 4 ? 5 : 0) * scale, y: [2, 17, 32, 47, 68, 87][index] * vertical)
                }
            }
        }.accessibilityHidden(true)
    }

    private func preview(_ page: PDFPage, pageIndex: Int? = nil) -> some View {
        let box = page.bounds(for: .cropBox)
        let rotated = page.rotation % 180 != 0
        let ratio = rotated ? box.height / box.width : box.width / box.height
        return GeometryReader { proxy in
            let width = min(proxy.size.width, proxy.size.height * ratio)
            let height = width / ratio
            ZStack(alignment: .topLeading) {
                #if os(macOS)
                Image(nsImage: page.thumbnail(of: CGSize(width: 1400, height: 1800), for: .cropBox)).resizable()
                #else
                Image(uiImage: page.thumbnail(of: CGSize(width: 1400, height: 1800), for: .cropBox)).resizable()
                #endif
                if enabled && (pageIndex == nil || placement.allPages || pageIndex == placement.page) {
                    stampArtwork
                        .frame(width: width * placement.width, height: height * placement.height)
                        .overlay(Rectangle().stroke(Color.accentColor.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 2, coordinateSpace: .global)
                            .onChanged { event in
                                if let pageIndex { placement.page = pageIndex }
                                if moveStart == nil { moveStart = placement }
                                guard let start = moveStart else { return }
                                placement.x = min(max(0, start.x + event.translation.width / width), 1 - placement.width)
                                placement.y = min(max(0, start.y + event.translation.height / height), 1 - placement.height)
                            }.onEnded { _ in moveStart = nil })
                        .offset(x: width * placement.x, y: height * placement.y)
                    ForEach(0..<4, id: \.self) { corner in
                        let right = corner % 2 == 1, bottom = corner >= 2
                        Circle().fill(Color.accentColor)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(.white, lineWidth: 1.5))
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                            .offset(x: width * (placement.x + (right ? placement.width : 0)) - 22,
                                    y: height * (placement.y + (bottom ? placement.height : 0)) - 22)
                            .highPriorityGesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                                .onChanged { event in
                                    if let pageIndex { placement.page = pageIndex }
                                    if resizeStart == nil { resizeStart = placement }
                                    placement = resizeStart!.resized(corner: corner, dx: event.translation.width / width, dy: event.translation.height / height)
                                }.onEnded { _ in resizeStart = nil })
                            .accessibilityLabel(L10n.text(.stamp_size))
                            .accessibilityValue("\(Int(placement.width * 100))%")
                            .accessibilityAdjustableAction { direction in
                                let amount = direction == .increment ? 0.02 : -0.02
                                placement = placement.resized(corner: corner, dx: right ? amount : -amount, dy: 0)
                            }
                    }

                }
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                guard enabled, resizeStart == nil else { return }
                if let pageIndex { placement.page = pageIndex }
                placement.x = min(max(0, location.x / width - placement.width / 2), 1 - placement.width)
                placement.y = min(max(0, location.y / height - placement.height / 2), 1 - placement.height)
            }
            .accessibilityLabel(L10n.text(.stamp_move_hint))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
