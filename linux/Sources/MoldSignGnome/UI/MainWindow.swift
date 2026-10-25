import CAdwaita
import Foundation
import MoldSignKit

/// AdwApplicationWindow: header bar with view switcher, status banner, toasts, four pages (LNX-09).
///
/// ```
/// AdwToolbarView
///  ├─ top:    AdwHeaderBar [AdwViewSwitcher | primary menu]
///  ├─ top:    AdwBanner (reader/card problems, bridge port busy)
///  ├─ content AdwToastOverlay → AdwViewStack: Semnează · Verifică · Activitate · Card
///  └─ bottom: AdwViewSwitcherBar (revealed on narrow windows by an AdwBreakpoint)
/// ```
final class MainWindow {
    let window: UnsafeMutablePointer<GtkWindow>
    private let controller: AppController
    private let stack: OpaquePointer
    private let banner: OpaquePointer
    private let toasts: OpaquePointer
    private var bannerAction: (() -> Void)?

    // Pages are owned here: they observe the controller weakly.
    let signPage: SignPage
    let verifyPage: VerifyPage
    let activityPage: ActivityPage
    let cardPage: CardPage

    init(app: UnsafeMutablePointer<AdwApplication>, controller: AppController) {
        self.controller = controller
        let win = adw_application_window_new(app.cast())!
        window = win.cast()
        gtk_window_set_title(window, "MoldSign")
        gtk_window_set_default_size(window, 900, 640)
        gtk_widget_set_size_request(win, 360, 420)

        var windowRef: UnsafeMutablePointer<GtkWindow>?
        let parent: () -> UnsafeMutablePointer<GtkWindow>? = { windowRef }

        // Pages
        signPage = SignPage(controller: controller, window: parent)
        verifyPage = VerifyPage(controller: controller, window: parent)
        activityPage = ActivityPage(controller: controller, window: parent)
        cardPage = CardPage(controller: controller)

        stack = OpaquePointer(adw_view_stack_new()!)
        let pages: [(Widget, String, String, String)] = [
            (signPage.root, "sign", "Semnează", "document-edit-symbolic"),
            (verifyPage.root, "verify", "Verifică", "security-high-symbolic"),
            (activityPage.root, "activity", "Activitate", "document-open-recent-symbolic"),
            (cardPage.root, "card", "Card", "auth-smartcard-symbolic"),
        ]
        for (widget, name, title, icon) in pages {
            adw_view_stack_add_titled_with_icon(stack, widget, name, title, icon)
        }

        // Header bar + switchers
        let switcher = adw_view_switcher_new()!
        adw_view_switcher_set_stack(switcher.opaque, stack)
        adw_view_switcher_set_policy(switcher.opaque, ADW_VIEW_SWITCHER_POLICY_WIDE)
        let header = adw_header_bar_new()!
        adw_header_bar_set_title_widget(header.opaque, switcher)

        let menu = g_menu_new()
        let section = g_menu_new()
        g_menu_append(section, "Preferințe", "app.preferences")
        g_menu_append(section, "Despre MoldSign", "app.about")
        g_menu_append_section(menu, nil, section?.cast())
        let quitSection = g_menu_new()
        g_menu_append(quitSection, "Ieșire", "app.quit")
        g_menu_append_section(menu, nil, quitSection?.cast())
        let menuButton = gtk_menu_button_new()!
        gtk_menu_button_set_icon_name(menuButton.opaque, "open-menu-symbolic")
        gtk_menu_button_set_menu_model(menuButton.opaque, menu?.cast())
        gtk_menu_button_set_primary(menuButton.opaque, 1)   // F10
        gtk_widget_set_tooltip_text(menuButton, "Meniu principal")
        setAccessibleLabel(menuButton, "Meniu principal")
        adw_header_bar_pack_end(header.opaque, menuButton)
        g_object_unref(section?.raw)
        g_object_unref(quitSection?.raw)
        g_object_unref(menu?.raw)

        banner = OpaquePointer(adw_banner_new("")!)

        toasts = OpaquePointer(adw_toast_overlay_new()!)
        adw_toast_overlay_set_child(toasts, stack.widget)

        let switcherBar = adw_view_switcher_bar_new()!
        adw_view_switcher_bar_set_stack(switcherBar.opaque, stack)

        let toolbar = adw_toolbar_view_new()!
        adw_toolbar_view_add_top_bar(toolbar.opaque, header)
        adw_toolbar_view_add_top_bar(toolbar.opaque, banner.widget)
        adw_toolbar_view_set_content(toolbar.opaque, toasts.widget)
        adw_toolbar_view_add_bottom_bar(toolbar.opaque, switcherBar)
        adw_application_window_set_content(win.cast(), toolbar)

        // Narrow windows: switcher moves from the header to the bottom bar (GNOME HIG adaptive pattern).
        if let condition = adw_breakpoint_condition_parse("max-width: 550sp") {
            let breakpoint = adw_breakpoint_new(condition)!
            setBreakpointBool(breakpoint, switcherBar, "reveal", true)
            setBreakpointBool(breakpoint, header, "show-title", false)
            adw_application_window_add_breakpoint(win.cast(), breakpoint)
        }

        windowRef = window
        onSignal(banner, "button-clicked") { [weak self] in self?.bannerAction?() }
        controller.observe { [weak self] in self?.renderBanner() }
    }

    var visiblePage: String {
        adw_view_stack_get_visible_child_name(stack).map { String(cString: $0) } ?? "sign"
    }

    func show(page: String) {
        adw_view_stack_set_visible_child_name(stack, page)
    }

    func present() {
        gtk_window_present(window)
    }

    func toast(_ text: String) {
        let toast = adw_toast_new(escapeMarkup(text))
        adw_toast_set_timeout(toast, 5)
        adw_toast_overlay_add_toast(toasts, toast)
    }

    /// Reader/card problems first (status first, docs/10 §1), then a bridge that could not bind.
    private func renderBanner() {
        let status = controller.status
        var title: String?
        var buttonLabel: String?
        bannerAction = nil
        switch status {
        case .noReader:
            title = "Conectează cititorul de carduri"
        case .empty:
            title = "Introdu cardul în cititor"
        case .error(let message, let recovery):
            title = recovery.isEmpty ? message : "\(message). \(recovery)"
            buttonLabel = "Reîncearcă"
            bannerAction = { [weak self] in self?.controller.retryCard() }
        case .reading, .ready, .busy:
            break
        }
        if title == nil, controller.settings.bridgeEnabled, controller.bridgeState == .portBusy {
            title = "Conexiunea browser nu a pornit: porturile \(MoldSignServer.defaultHTTPPort)/\(MoldSignServer.defaultHTTPSPort) sunt ocupate de altă aplicație"
            buttonLabel = "Reîncearcă"
            bannerAction = { [weak self] in self?.controller.restartBridge() }
        }
        adw_banner_set_title(banner, escapeMarkup(title ?? ""))
        adw_banner_set_button_label(banner, buttonLabel)
        adw_banner_set_revealed(banner, title == nil ? 0 : 1)
    }
}

/// `adw_breakpoint_add_setter` with a boolean GValue (the setters API is variadic in C).
private func setBreakpointBool(_ breakpoint: GPointer, _ object: GPointer, _ property: String, _ value: Bool) {
    var v = GValue()
    g_value_init(&v, g_type_from_name("gboolean"))
    g_value_set_boolean(&v, value ? 1 : 0)
    adw_breakpoint_add_setter(breakpoint.opaque, object.object, property, &v)
    g_value_unset(&v)
}
