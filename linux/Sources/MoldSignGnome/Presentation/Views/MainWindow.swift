import CAdwaita
import Foundation
import MoldSignKit

/// AdwApplicationWindow: header bar with view switcher, banner, toasts, four pages (LNX-09, UX-07).
///
/// ```
/// AdwToolbarView
///  ├─ top:    AdwHeaderBar [re-read cards | AdwViewSwitcher | primary menu]
///  ├─ top:    AdwBanner (browser bridge could not bind its ports)
///  ├─ content AdwToastOverlay → AdwViewStack: Semnează · Verifică · Activitate · Card
///  └─ bottom: AdwViewSwitcherBar (revealed on narrow windows by an AdwBreakpoint)
/// ```
///
/// Card status is not a banner: the card wallet on Semnează / Card shows it (docs/10 §0.2), and the status
/// light goes to the Background portal (§0.1).
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

    init(app: UnsafeMutablePointer<AdwApplication>, controller: AppController) {
        self.controller = controller
        let win = adw_application_window_new(app.cast())!
        window = win.cast()
        gtk_window_set_title(window, "eSemnBun")
        gtk_window_set_default_size(window, 900, 640)
        gtk_widget_set_size_request(win, 360, 420)

        var windowRef: UnsafeMutablePointer<GtkWindow>?
        let parent: () -> UnsafeMutablePointer<GtkWindow>? = { windowRef }

        // Pages
        signPage = SignPage(controller: controller, window: parent)
        verifyPage = VerifyPage(controller: controller, window: parent)
        activityPage = ActivityPage(controller: controller, window: parent)

        stack = OpaquePointer(adw_view_stack_new()!)
        adw_view_stack_set_hhomogeneous(stack, 0)
        let pages: [(Widget, String, String, String)] = [
            (signPage.root, "sign", L10n.text(.ui_sign), "document-edit-symbolic"),
            (verifyPage.root, "verify", L10n.text(.ui_verify), "security-high-symbolic"),
            (activityPage.root, "activity", L10n.text(.ui_activity), "folder-documents-symbolic"),
        ]
        for (widget, name, title, icon) in pages {
            adw_view_stack_add_titled_with_icon(stack, widget, name, title, icon)
        }

        let documentStack = stack
        activityPage.onVerify = { path in
            adw_view_stack_set_visible_child_name(documentStack, "verify")
            controller.verify(paths: [path])
        }

        // Header bar + switchers
        let switcher = adw_view_switcher_new()!
        adw_view_switcher_set_stack(switcher.opaque, stack)
        adw_view_switcher_set_policy(switcher.opaque, ADW_VIEW_SWITCHER_POLICY_WIDE)
        let header = adw_header_bar_new()!
        adw_header_bar_set_title_widget(header.opaque, switcher)

        let menu = g_menu_new()
        let section = g_menu_new()
        g_menu_append(section, L10n.text(.ui_preferences), "app.preferences")
        g_menu_append(section, L10n.text(.ui_about_esemnbun), "app.about")
        g_menu_append(section, L10n.text(.update_check), "app.check-updates")
        g_menu_append_section(menu, nil, section?.cast())
        let quitSection = g_menu_new()
        g_menu_append(quitSection, L10n.text(.ui_quit), "app.quit")
        g_menu_append_section(menu, nil, quitSection?.cast())
        let menuButton = gtk_menu_button_new()!
        gtk_menu_button_set_icon_name(menuButton.opaque, "open-menu-symbolic")
        gtk_menu_button_set_menu_model(menuButton.opaque, menu?.cast())
        gtk_menu_button_set_primary(menuButton.opaque, 1)   // F10
        gtk_widget_set_tooltip_text(menuButton, L10n.text(.ui_main_menu))
        setAccessibleLabel(menuButton, L10n.text(.ui_main_menu))
        adw_header_bar_pack_end(header.opaque, menuButton)
        // docs/10 §0.2: re-read is a card context-menu action plus a small toolbar button
        let reread = iconButton("view-refresh-symbolic", tooltip: L10n.text(.ui_read_the_cards_again)) { controller.retryCard() }
        adw_header_bar_pack_start(header.opaque, reread)
        g_object_unref(section?.raw)
        g_object_unref(quitSection?.raw)
        g_object_unref(menu?.raw)

        banner = OpaquePointer(adw_banner_new("")!)

        toasts = OpaquePointer(adw_toast_overlay_new()!)
        adw_toast_overlay_set_child(toasts, stack.widget)

        let switcherBar = adw_view_switcher_bar_new()!
        adw_view_switcher_bar_set_stack(switcherBar.opaque, stack)
        addClasses(switcherBar, ["compact-navigation"])

        let toolbar = adw_toolbar_view_new()!
        adw_toolbar_view_add_top_bar(toolbar.opaque, header)
        adw_toolbar_view_add_top_bar(toolbar.opaque, banner.widget)
        adw_toolbar_view_set_content(toolbar.opaque, toasts.widget)
        adw_toolbar_view_add_bottom_bar(toolbar.opaque, switcherBar)
        adw_application_window_set_content(win.cast(), toolbar)

        // Narrow windows: switcher moves from the header to the bottom bar (GNOME HIG adaptive pattern);
        // narrower still, the wallet draws compact cards (260 × 164 instead of 340 × 214).
        for (query, compactCards) in [("max-width: 550sp", false), ("max-width: 420sp", true)] {
            guard let condition = adw_breakpoint_condition_parse(query) else { continue }
            let breakpoint = adw_breakpoint_new(condition)!
            setBreakpointBool(breakpoint, switcherBar, "reveal", true)
            setBreakpointBool(breakpoint, switcher, "visible", false)
            if compactCards {
                let wallets = [signPage.wallet]
                let signing = signPage
                onSignal(breakpoint, "apply") { wallets.forEach { $0.setCompact(true) }; signing.setCompact(true) }
                onSignal(breakpoint, "unapply") { wallets.forEach { $0.setCompact(false) }; signing.setCompact(false) }
            }
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
        if page == "card" {
            presentCardSettings(parent: window.cast(), controller: controller)
        } else if page == "settings" {
            presentPreferences(parent: window.cast(), controller: controller)
        } else {
            adw_view_stack_set_visible_child_name(stack, page)
        }
    }

    func present() {
        gtk_window_present(window)
    }

    func toast(_ text: String) {
        let toast = adw_toast_new(escapeMarkup(text))
        adw_toast_set_timeout(toast, 5)
        adw_toast_overlay_add_toast(toasts, toast)
    }

    /// Outcome toast with one action ("Document semnat" · "Arată").
    func toast(_ text: String, button: String, action: @escaping () -> Void) {
        let toast = adw_toast_new(escapeMarkup(text))
        adw_toast_set_timeout(toast, 6)
        adw_toast_set_button_label(toast, button)
        onSignal(toast!, "button-clicked") { action() }
        adw_toast_overlay_add_toast(toasts, toast)
    }

    /// A browser bridge that could not bind its ports (the vendor suite holds them). Card problems are shown by
    /// the wallet instead (docs/10 §0.2).
    private func renderBanner() {
        var title: String?
        var buttonLabel: String?
        bannerAction = nil
        if controller.isDemo {
            if !DemoMode.screenshotCapture { title = L10n.text(.ui_demo_data_no_real_card_pin_or_signatures) }
        } else if controller.settings.bridgeEnabled, controller.bridgeState == .portBusy {
            title = localized(.linux_bridge_ports_banner, String(MoldSignServer.defaultHTTPPort), String(MoldSignServer.defaultHTTPSPort))
            buttonLabel = L10n.text(.linux_vendor_resolve)
            bannerAction = { [weak self] in self?.resolveBridgeConflict() }
        } else if controller.settings.bridgeEnabled, controller.bridgeState == .identityRequired {
            title = controller.bridgeState.description
            buttonLabel = L10n.text(.ui_import)
            bannerAction = { [weak self] in
                guard let self else { return }
                chooseBridgeIdentity(parent: self.window.cast(), controller: self.controller)
            }
        }
        adw_banner_set_title(banner, escapeMarkup(title ?? ""))
        adw_banner_set_button_label(banner, buttonLabel)
        adw_banner_set_revealed(banner, title == nil ? 0 : 1)
    }

    private func resolveBridgeConflict() {
        // /proc may be unavailable inside a sandbox; absence of a match must never kill an unknown process.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let listeners = VendorPortConflict.listeners()
            onMain {
                guard let self, self.controller.bridgeState == .portBusy else { return }
                guard !listeners.isEmpty else {
                    self.toast(L10n.text(.linux_vendor_unknown))
                    self.controller.restartBridge()
                    return
                }
                presentConfirmDialog(parent: self.window.cast(), heading: L10n.text(.linux_vendor_quit_title),
                                     body: L10n.text(.linux_vendor_quit_body), action: L10n.text(.linux_vendor_quit_action)) { approved in
                    guard approved else { return }
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        VendorPortConflict.requestQuit(listeners)
                        Thread.sleep(forTimeInterval: 1)
                        onMain { self?.controller.restartBridge() }
                    }
                }
            }
        }
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
