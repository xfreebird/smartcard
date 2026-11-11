import SwiftUI
import MoldSignKit

/// Horizontally paged identity cards. Selection follows the visible page; dots and VoiceOver
/// provide the same selection without gestures. All geometry is derived from the card width.
struct CardSelector: View {
    enum Size {
        case compact, large, phone
        var maxWidth: CGFloat? {
            switch self {
            case .compact: return 288
            case .large: return 400
            case .phone: return 400
            }
        }
    }

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var size: Size = .large
    @State private var width: CGFloat = 288
    @State private var visibleReader: String?
    @State private var userIsScrolling = false
    @State private var selectionPending = false
    @State private var selectionCommit: Task<Void, Never>?
    #if os(macOS)
    @State private var hoveringCard = false
    #endif
    private var cardWidth: CGFloat {
        #if os(macOS)
        // Reserve space for hover controls outside the card when several readers exist.
        let gutters: CGFloat = model.displayedCards.count > 1 ? 88 : 8
        return max(120, min(size.maxWidth ?? .infinity, width - gutters))
        #else
        return max(120, min(size.maxWidth ?? 400, width - 8))
        #endif
    }
    private var selectorMaxWidth: CGFloat? {
        #if os(macOS)
        return size == .compact ? size.maxWidth.map { $0 + (model.displayedCards.count > 1 ? 88 : 0) } : nil
        #else
        return size.maxWidth
        #endif
    }
    private var sideInset: CGFloat { max(4, (width - cardWidth) / 2) }
    private var cardHeight: CGFloat { cardWidth / IDCardFace.ratio }
    private var selectedIndex: Int { model.displayedCards.firstIndex { $0.reader == model.selectedCard?.reader } ?? 0 }

    var body: some View {
        VStack(spacing: 10) {
            if model.displayedCards.isEmpty {
                EmptyCardFace(status: model.status, size: size)
                    .frame(width: cardWidth, height: cardHeight)
            } else {
                #if os(iOS)
                TabView(selection: Binding(get: { model.selectedCard?.reader ?? "" }, set: { reader in
                    // TabView may write back the temporary fallback after a reader disappears.
                    if reader != model.selectedCard?.reader { model.selectCard(reader) }
                })) {
                    ForEach(model.displayedCards) { card in
                        cardFace(card)
                            .padding(.bottom, model.displayedCards.count > 1 ? 32 : 0)
                            .tag(card.reader)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: model.displayedCards.count > 1 ? .always : .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: cardHeight + (model.displayedCards.count > 1 ? 36 : 8))
                .allowsHitTesting(model.currentStep == nil)
                #else
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(model.displayedCards) { card in
                            cardFace(card)
                                .frame(width: width)
                                .id(card.reader)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.vertical, 4)
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .scrollIndicators(.hidden)
                .modifier(CardPaging(interactionChanged: interactionChanged))
                .scrollPosition(id: $visibleReader, anchor: .center)
                .scrollDisabled(model.currentStep != nil)
                .frame(height: cardHeight + 8)
                .overlay {
                    if model.displayedCards.count > 1 {
                        HStack {
                            carouselArrow(-1)
                            Spacer()
                            carouselArrow(1)
                        }
                        .padding(.horizontal, 4)
                        .opacity(hoveringCard ? 1 : 0)
                        .allowsHitTesting(hoveringCard)
                        .accessibilityHidden(!hoveringCard)
                    }
                }
                .onHover { hoveringCard = $0 }
                .onAppear { visibleReader = model.selectedCard?.reader }
                .task(id: width) {
                    // Content margins and card width are measured after the first layout. Restore the
                    // selected item with the native proxy once that geometry is available.
                    let target = model.selectedCard?.reader
                    await Task.yield()
                    guard !Task.isCancelled, let target else { return }
                    proxy.scrollTo(target, anchor: .center)
                }
                .onChange(of: visibleReader) { _, reader in
                    if selectionPending && !userIsScrolling { commitSelectionWhenSettled() }
                }
                .onChange(of: model.selectedCard?.reader) { _, reader in
                    // During a swipe the binding already contains this reader. Only explicit selection
                    // changes (keyboard, card replacement) need an imperative scroll.
                    guard !userIsScrolling, !selectionPending, visibleReader != reader, let reader else { return }
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                        visibleReader = reader
                        proxy.scrollTo(reader, anchor: .center)
                    }
                }
                }
                #endif
                #if os(macOS)
                if model.displayedCards.count > 1 {
                    HStack(spacing: 0) {
                        // A reader may disappear while SwiftUI is still updating its old
                        // children. Capture each card's value rather than a live array index.
                        ForEach(model.displayedCards) { card in
                            Button {
                                guard model.currentStep == nil,
                                      model.displayedCards.contains(where: { $0.reader == card.reader }) else { return }
                                model.selectCard(card.reader)
                            } label: {
                                Circle()
                                    .fill(card.reader == model.selectedCard?.reader ? Color.accentColor : Color.secondary.opacity(0.3))
                                    .frame(width: 7, height: 7)
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(model.currentStep != nil)
                            .accessibilityLabel(IDCardFace.accessibilityLabel(card))
                            .accessibilityAddTraits(card.reader == model.selectedCard?.reader ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 2)
                }
                #endif
            }
        }
        .frame(maxWidth: selectorMaxWidth ?? .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .frame(maxWidth: .infinity)
        .onDisappear { selectionCommit?.cancel(); userIsScrolling = false; selectionPending = false }
        .onKeyPress(.leftArrow) { move(-1); return .handled }
        .onKeyPress(.rightArrow) { move(1); return .handled }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(1)
            case .decrement: move(-1)
            @unknown default: break
            }
        }
        #if os(iOS)
        .sensoryFeedback(.selection, trigger: model.selectedCard?.reader)
        #endif
    }

    private func cardFace(_ card: CardSlot) -> some View {
        IDCardFace(card: card, busy: model.currentStep != nil && card.reader == model.selectedCard?.reader,
                   inUse: model.displayedCards.count > 1 && card.reader == model.selectedCard?.reader)
            .frame(width: cardWidth, height: cardHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(IDCardFace.accessibilityLabel(card))
            .accessibilityAddTraits(card.reader == model.selectedCard?.reader ? .isSelected : [])
            .contextMenu {
                Button { model.rereadCards() } label: { Label(L10n.text(.ui_read_the_card_again), systemImage: "arrow.clockwise") }
            }
    }

    #if os(macOS)
    private func carouselArrow(_ direction: Int) -> some View {
        let title = L10n.text(direction < 0 ? .ui_previous_card : .ui_next_card)
        return Button { move(direction) } label: {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.12)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(model.currentStep != nil || (direction < 0 ? selectedIndex == 0 : selectedIndex >= model.displayedCards.count - 1))
        .accessibilityLabel(title)
        .help(title)
    }
    #endif

    private func interactionChanged(_ active: Bool) {
        if active {
            selectionCommit?.cancel()
            userIsScrolling = true
            selectionPending = true
        } else if selectionPending {
            userIsScrolling = false
            commitSelectionWhenSettled()
        }
    }

    private func commitSelectionWhenSettled() {
        selectionCommit?.cancel()
        selectionCommit = Task { @MainActor in
            if #available(iOS 18.0, macOS 15.0, *) {
                await Task.yield()
            } else {
                // Older iOS has no native scroll-phase callback; debounce its final binding changes.
                try? await Task.sleep(for: .milliseconds(180))
            }
            guard !Task.isCancelled, !userIsScrolling else { return }
            if let reader = visibleReader, model.currentStep == nil,
               model.displayedCards.contains(where: { $0.reader == reader }) { model.selectCard(reader) }
            selectionPending = false
        }
    }

    private func move(_ delta: Int) {
        guard !model.displayedCards.isEmpty, model.currentStep == nil else { return }
        let next = min(max(selectedIndex + delta, 0), model.displayedCards.count - 1)
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
            model.selectCard(model.displayedCards[next].reader)
        }
    }
}
