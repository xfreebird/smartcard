import XCTest

/// Native finger injection: no arrow, page-control or accessibility-increment actions select cards.
@MainActor
final class CardCarouselUITests: XCTestCase {
    private var app: XCUIApplication!
    private let holders = ["Popescu Ion", "Mîndru Ștefan", "Rusu Ana"]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        app.launchEnvironment["MSIGN_QA_NO_HARDWARE"] = "1"
        app.launchEnvironment["MSIGN_SCREENSHOT_CAPTURE"] = "1"
        app.launchEnvironment["MSIGN_DEMO_CARDS"] = "3"
        app.launchEnvironment["MSIGN_DEMO_SELECTED"] = "0"
        app.launchEnvironment["MSIGN_DEMO_PREFERENCES_SUITE"] = "md.esemnbun.qa.native-touch.\(UUID())"
        app.launchArguments = ["-appTheme", "light", "-appLanguage", "ro", "-AppleLanguages", "(ro)"]
    }

    override func tearDown() {
        app?.terminate()
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    func testNativeSwipeSelectsCenteredCards() throws {
        app.launch()
        selectReader()
        let first = card(0)
        XCTAssertTrue(first.waitForPresence(timeout: 20))
        let center = first.frame.midX
        attach("01-before-card-1")
        for index in 1...2 {
            let previous = card(index - 1)
            let from = previous.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            let to = previous.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
            from.press(forDuration: 0.05, thenDragTo: to)
            let selected = card(index)
            XCTAssertTrue(selected.waitForPresence(timeout: 5))
            XCTAssertTrue(selected.isHittable)
            let selection = NSPredicate(format: "selected == true")
            expectation(for: selection, evaluatedWith: selected)
            waitForExpectations(timeout: 8)
            XCTAssertTrue(selected.isSelected)
            XCTAssertEqual(selected.frame.midX, center, accuracy: 2)
            XCTAssertGreaterThanOrEqual(selected.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(selected.frame.maxX, app.frame.maxX)
            attach("0\(index + 1)-after-card-\(index + 1)")
            proof(index: index + 1, holder: holders[index], frame: selected.frame, initialCenter: center)
        }
    }

    func testInitialSecondCardIsCenteredWithoutGesture() {
        app.launchEnvironment["MSIGN_DEMO_SELECTED"] = "1"
        app.launch()
        selectReader()
        let second = card(1)
        XCTAssertTrue(second.waitForPresence(timeout: 20))
        XCTAssertTrue(second.isHittable)
        XCTAssertTrue(second.isSelected)
        attach("initial-selected-card-2")
    }

    private func selectReader() {
        app.selectSigningMethod("reader")
        // The empty Sign workspace now displays the live carousel inline, not behind a button.
        XCTAssertTrue(app.collectionViews["signing.reader.cards"].waitForPresence(timeout: 10))
    }

    private func card(_ index: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", holders[index] + ", card de identitate")
        ).firstMatch
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        // Foldable simulator screenshots may target its inactive outer display. A host-side
        // display capture can synchronize with this checkpoint while the selected page is stable.
        print("MSIGN_UI_CAPTURE " + name)
        Thread.sleep(forTimeInterval: 2)
    }

    private func proof(index: Int, holder: String, frame: CGRect, initialCenter: CGFloat) {
        let data: [String: Any] = ["interaction": "native-finger-press-drag", "selectedIndex": index,
            "holder": holder, "centerX": Double(frame.midX), "initialCenterX": Double(initialCenter),
            "width": Double(frame.width), "height": Double(frame.height),
            "pinEntered": false, "hardwareAccess": false]
        if let json = try? JSONSerialization.data(withJSONObject: data, options: [.sortedKeys]) {
            print("MSIGN_UI_SWIPE_PROOF " + String(decoding: json, as: UTF8.self))
        }
    }
}
