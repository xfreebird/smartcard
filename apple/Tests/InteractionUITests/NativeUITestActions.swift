import XCTest

extension XCUIElement {
    @MainActor
    func activateControl() {
        #if os(macOS)
        click()
        #else
        tap()
        #endif
    }
}
