import SwiftUI

/// Keep the native toolbar field, including its focused size, within the Documents detail column.
struct DocumentSearchWidth: NSViewRepresentable {
    final class SizingView: NSView {
        private var widthLimit: NSLayoutConstraint?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            NotificationCenter.default.removeObserver(self, name: NSWindow.didUpdateNotification, object: nil)
            widthLimit?.isActive = false
            widthLimit = nil
            if let window {
                // SwiftUI can install the search item after the detail view attaches.
                NotificationCenter.default.addObserver(self, selector: #selector(updateSearchWidth),
                                                       name: NSWindow.didUpdateNotification, object: window)
            }
        }

        override func layout() {
            super.layout()
            updateSearchWidth()
        }

        @objc private func updateSearchWidth() {
            guard bounds.width > 0, let window,
                  let item = window.toolbar?.items.compactMap({ $0 as? NSSearchToolbarItem }).first else { return }
            let width = min(240, floor(bounds.width / 3))
            if item.preferredWidthForSearchField != width { item.preferredWidthForSearchField = width }
            let field = item.searchField
            if widthLimit?.firstItem !== field {
                widthLimit?.isActive = false
                widthLimit = field.widthAnchor.constraint(lessThanOrEqualToConstant: width)
                widthLimit?.isActive = true
            } else if widthLimit?.constant != width {
                widthLimit?.constant = width
            }
        }
    }

    func makeNSView(context: Context) -> SizingView { SizingView() }
    func updateNSView(_ view: SizingView, context: Context) {}
}
