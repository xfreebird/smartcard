/// App CSS on top of libadwaita. Colors come from libadwaita's named colors (accent, success,
/// warning, error), so light/dark and the user's GNOME accent color apply automatically; the
/// design tokens in docs/10 §2 map onto them (brand → accent, success/warning/danger → the same names).
enum Style {
    static let css = """
    /* DropZone (docs/10 §3): dashed 1.5px border, radius 14; brand-soft fill + solid border while dragging */
    .dropzone {
        border: 2px dashed alpha(currentColor, 0.25);
        border-radius: 14px;
        padding: 24px;
    }
    .dropzone.compact { padding: 12px 16px; }
    .drop-page:drop(active) .dropzone {
        border-style: solid;
        border-color: @accent_bg_color;
        background-color: alpha(@accent_bg_color, 0.12);
    }
    .drop-page:drop(active) { box-shadow: none; }

    /* FormatChip: small capsule */
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

    /* StatusCard dot */
    .status-dot { min-width: 10px; min-height: 10px; border-radius: 999px; background-color: alpha(currentColor, 0.3); }
    .status-dot.ready { background-color: @success_color; }
    .status-dot.busy { background-color: @accent_color; }
    .status-dot.problem { background-color: @warning_color; }

    /* PIN field: large, spaced digits */
    .pin-entry text { font-size: 1.6em; letter-spacing: 0.4em; }
    .pin-entry { min-height: 46px; }

    .monospace-subtitle .subtitle { font-family: monospace; }
    """
}
