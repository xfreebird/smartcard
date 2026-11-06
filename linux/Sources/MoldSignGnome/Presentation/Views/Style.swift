/// App CSS on top of libadwaita. Colors come from libadwaita's named colors (accent, success,
/// warning, error) and its palette, so light/dark and the user's GNOME accent color apply automatically; the
/// design tokens in docs/10 §2 map onto them (brand → accent, success/warning/danger → the same names).
/// The card art itself (text included) is drawn with cairo + Pango (CardArt.swift); its button, outline and
/// disclosure are styled here.
enum Style {
    static let css = """
    /* DropZone (docs/10 §3): an always-active solid border; drag-over makes the action stronger. */
    .dropzone {
        border: 1px dashed alpha(@accent_color, 0.58);
        border-radius: 14px;
        padding: 24px;
        background-color: alpha(@accent_bg_color, 0.06);
    }
    .dropzone.compact { padding: 12px 16px; background-color: alpha(@accent_bg_color, 0.10); }
    .drop-page:drop(active) .dropzone {
        border-style: dashed;
        border-color: @accent_bg_color;
        background-color: alpha(@accent_bg_color, 0.12);
    }
    .drop-page:drop(active) { box-shadow: none; }

    /* FormatChip: small capsule */
    .file-row { border: 1px solid alpha(currentColor, 0.18); border-radius: 10px; margin: 3px; }
    .file-tag { border-radius: 6px; padding: 2px 5px; font-size: 0.8em; }
    .file-tag image { -gtk-icon-size: 12px; }
    .format-tag { background: alpha(@accent_bg_color, 0.14); color: @accent_color; }
    .stamp-tag { background: alpha(@success_color, 0.12); color: @success_color; }
    .stamp-off-tag { background: alpha(currentColor, 0.08); }
    .chip {
        border-radius: 999px;
        padding: 2px 10px;
        min-height: 0;
        font-size: 0.85em;
        font-weight: bold;
        background-color: alpha(@accent_bg_color, 0.14);
        color: @accent_color;
    }
    dropdown.chip > button { min-height: 0; padding: 2px 6px; background: none; color: inherit; }

    /* StepProgress */
    .steps { padding: 6px 0; }
    .step label { font-size: 0.9em; }
    .step.active label { font-weight: bold; }
    .step.pending { opacity: 0.55; }

    /* Status light (docs/10 §0.1): green ready, amber reader/reading, blue busy, red error, none idle */
    .status-dot { min-width: 10px; min-height: 10px; border-radius: 999px; }
    .status-dot.ready { background-color: @success_bg_color; }
    .status-dot.reader { background-color: @warning_bg_color; }
    .status-dot.busy { background-color: @blue_3; }
    .status-dot.error { background-color: @error_bg_color; }

    /* Card wallet (docs/10 §0.2b). The button is the card: no button chrome, the ID-card art is the drawing
       area (fixed colors, hairline drawn there); the shadow lets it read on dark windows too. */
    .wallet-card {
        padding: 0;
        min-height: 0;
        min-width: 0;
        border-radius: 15px;   /* 0.045 W */
        background: none;
        /* must fit the 8 px under the card: the revealer around each card clips */
        box-shadow: 0 1px 2px alpha(black, 0.2), 0 3px 6px alpha(black, 0.14);
        transition: box-shadow 200ms ease-out;
    }
    .wallet-card.compact { border-radius: 12px; }
    .wallet-card:hover, .wallet-card:active, .wallet-card:checked { background: none; }
    .wallet-card:hover { box-shadow: 0 1px 2px alpha(black, 0.22), 0 3px 7px alpha(black, 0.2); }
    .wallet-card:focus-visible { outline: 2px solid alpha(@accent_color, 0.6); outline-offset: 2px; }

    /* Expanded list: the selected card keeps an accent outline; its status strip (drawn) reads
       "✓ Folosit pentru semnare" (docs/10 §0.2b, UX-10) */
    .wallet-card.chosen { outline: 2px solid @accent_color; outline-offset: 2px; }

    /* Disclosure inside the card: round, 85 % white + hairline, fixed dark chevron like the face */
    button.card-disclosure {
        min-width: 0;
        min-height: 0;
        padding: 0;
        color: #1e2230;
        background-color: alpha(white, 0.85);
        box-shadow: 0 0 0 1px alpha(black, 0.14), 0 1px 3px alpha(black, 0.12);
        -gtk-icon-size: 14px;
    }
    button.card-disclosure:hover { background-color: alpha(white, 0.95); }
    button.card-disclosure:active { background-color: white; }

    button.wallet-dot { min-width: 20px; min-height: 20px; padding: 0; }

    .wallet-placeholder .placeholder-title { font-weight: bold; font-size: 1.1em; }
    .wallet-placeholder .placeholder-caption { opacity: 0.7; font-size: 0.9em; }
    .wallet-placeholder.error-card .placeholder-title { color: @error_color; }
    .wallet-placeholder .small-pill { padding: 2px 14px; min-height: 26px; font-size: 0.9em; }
    .wallet-placeholder.compact .placeholder-caption { font-size: 0.85em; }

    /* PIN field: large, spaced digits */
    .pin-entry text { font-size: 1.9em; letter-spacing: 0.3em; }
    .pin-entry { min-height: 64px; padding: 6px 18px; }

    .monospace-subtitle .subtitle { font-family: monospace; }
    """
}
