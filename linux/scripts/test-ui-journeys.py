#!/usr/bin/env python3
"""Run in an isolated interactive GNOME test session with python3-pyatspi installed."""
import argparse
import json
import os
import re
import shutil
from pathlib import Path
import subprocess
import tempfile
import uuid
import pyatspi
from gi.repository import Atspi


from ui_automation import wait, descendants, visible_named, reveal_named, invoke, expand_and_collapse
from ui_protection_journey import protection_workflow


def workflow(scenario, app, root, process, title):
    def click(key):
        invoke(wait(lambda: reveal_named(app, title(key)), key, process))
    if scenario == "protection-roundtrip":
        return protection_workflow(app, root, process, title)
    if scenario == "history-clear":
        outputs = {path: path.read_bytes() for path in root.rglob("Contract-result.pdf")}
        assert outputs, "The fixture must own a saved output"
        click("saved_history")
        click("ui_clear_the_list"); click("ui_cancel")
        wait(lambda: visible_named(app, title("ui_cancel")) is None
             and visible_named(app, title("ui_clear_list")) is None, "cancelled dialog dismissed", process)
        wait(lambda: visible_named(app, "Contract-result.pdf"), "cancel retains history", process)
        click("ui_clear_the_list"); click("ui_clear_list")
        wait(lambda: visible_named(app, title("ui_no_activity_yet")), "empty history", process)
        click("saved_files")
        wait(lambda: visible_named(app, "Contract-result.pdf"), "saved output retained", process)
        assert all(path.read_bytes() == data for path, data in outputs.items()), "History clear changed output bytes"
        return "cancel and confirm history clear; retain saved library and output bytes"
    if scenario.startswith("sign-"):
        # The mock replaces BatchSigning; this button still runs the actual application workflow.
        sign = title("ui_sign_value_documents").replace("%1$s", "2").replace("%@", "2").replace("%s", "2")
        invoke(wait(lambda: visible_named(app, sign), "sign batch", process))
        expected = {"sign-success": 2, "sign-mixed": 1, "sign-fatal": 0}[scenario]
        if scenario == "sign-fatal":
            wait(lambda: visible_named(app, title("linux_pin_blocked")), "fatal card outcome", process)
        else:
            wait(lambda: len(list(root.rglob("*-DEMO-NOT-SIGNED.pdf"))) == expected, "mock outputs", process)
            wait(lambda: visible_named(app, "Declaration.txt") is None, "successful item dequeued", process)
        files = list(root.rglob("*-DEMO-NOT-SIGNED.pdf"))
        assert len(files) == expected
        assert all(b"DEMO ONLY - UNSIGNED DOCUMENT" in path.read_bytes() for path in files)
        assert (visible_named(app, "Contract.pdf") is not None) == (scenario != "sign-success")
        assert visible_named(app, title("ui_qscd_pin")) is None
        return "sign through mock service; assert queue, failure policy and output bytes"
    if scenario == "remove-input":
        click("file_options"); click("file_remove")
        wait(lambda: visible_named(app, "Contract.pdf") is None, "removed input", process)
        assert visible_named(app, "Declaration.txt") is not None
        assert not list(root.rglob("*-DEMO-NOT-SIGNED.pdf"))
        return "remove input through native file menu"
    if scenario == "change-format":
        click("file_options"); click("format_xml")
        selected_format = "✓  " + title("format_xml")
        # Wait for the new row/menu after the controller renders the changed format.
        def format_applied():
            filename = visible_named(app, "Contract.pdf")
            return filename is not None and any(node.name == title("format_xml")
                                                for node in descendants(filename.parent))
        wait(format_applied, "format applied", process)
        click("file_options")
        wait(lambda: visible_named(app, selected_format), "selected XML format", process)
        return "choose format and reopen menu to confirm selection"
    if scenario == "cancel-stamp":
        click("file_options"); click("stamp_add")
        wait(lambda: visible_named(app, title("stamp_title")), "stamp editor", process)
        click("ui_cancel")
        wait(lambda: visible_named(app, title("stamp_title")) is None, "stamp cancelled", process)
        assert visible_named(app, "Contract.pdf") is not None
        return "open native stamp editor and cancel without changing queue"
    raise AssertionError("Unknown workflow: " + scenario)


def run(binary, output, selected=None):
    if subprocess.run(["pgrep", "-x", "esemnbun-gnome"], stdout=subprocess.DEVNULL).returncode == 0:
        raise RuntimeError("Close eSemnBun before running the isolated native suite")
    localization = (Path(__file__).resolve().parents[1] / "Sources/MoldSignGnome/Infrastructure/Localization/L10n.swift").read_text()
    def title(key):
        match = re.search(r'"' + key + r'"\s*:\s*\{.*?"en"\s*:\s*("(?:[^"\\]|\\.)*")', localization, re.S)
        assert match, key
        return json.loads(match.group(1))
    scenarios = {
        "verify-valid": ("verify", "Valid signature"),
        "verify-invalid": ("verify", "Invalid signature"),
        "verify-unknown": ("verify", "Cannot be confirmed"),
        "verify-unsigned": ("verify", "No signature found"),
        "verify-checking": ("verify", title("ui_verifying")),
        "documents": ("sign", "Contract.pdf"),
        "signing": ("sign", "Contract.pdf"),
        "signing-error": ("sign", title("ui_the_card_does_not_respond")),
        "success": ("sign", "Contract-result.pdf"),
        "activity": ("activity", "Contract-result.pdf"),
        "settings": ("sign", title("ui_preferences")),
        "pin": ("sign", title("ui_qscd_pin")),
        "pin-error": ("sign", title("ui_qscd_pin")),
    }
    workflow_cases = ["sign-success", "sign-mixed", "sign-fatal", "remove-input", "change-format", "cancel-stamp"]
    scenarios.update({name: ("sign", "Contract.pdf") for name in workflow_cases})
    workflow_cases.append("history-clear")
    scenarios["history-clear"] = ("activity", "Contract-result.pdf")
    workflow_cases.append("protection-roundtrip")
    scenarios["protection-roundtrip"] = ("activity", title("protect_choose_file"))
    if selected:
        unknown = set(selected) - scenarios.keys()
        if unknown:
            raise ValueError("Unknown scenarios: " + ", ".join(sorted(unknown)))
        scenarios = {name: case for name, case in scenarios.items() if name in selected}
    assert b"MSIGN_DEMO_READY_FILE" in Path(binary).read_bytes(), "Debug demo binary required"
    results = []
    for scenario, (page, verdict) in scenarios.items():
        with tempfile.TemporaryDirectory(prefix="esemnbun-ui-") as folder:
            root = Path(folder)
            token = str(uuid.uuid4())
            fixture = "activity" if scenario in ("history-clear", "protection-roundtrip") else "documents" if scenario in workflow_cases else scenario
            env = dict(os.environ, XDG_CONFIG_HOME=str(root / "config"), XDG_DATA_HOME=str(root / "data"),
                       MSIGN_DEMO_CARDS="1", MSIGN_DEMO_SCENARIO=fixture, MSIGN_DEMO_PAGE=page,
                       MSIGN_DEMO_LANGUAGE="en", MSIGN_SCREENSHOT_CAPTURE="1", GTK_A11Y="atspi",
                       GDK_DEBUG="no-portals",
                       MSIGN_DEMO_WORK_DIR=folder, MSIGN_DEMO_RUN_ID=token,
                       MSIGN_DEMO_READY_FILE=str(root / "ready.json"))
            env.pop("MSIGN_UI_TEST_SCENARIO", None)
            env.pop("MSIGN_CAPTURE_DIALOG", None)
            if scenario == "protection-roundtrip":
                env["MSIGN_CAPTURE_DIALOG"] = "protect-encrypt"
            if scenario.startswith("sign-") and scenario in workflow_cases:
                env["MSIGN_UI_TEST_SCENARIO"] = scenario
            with (output / f"{scenario}.log").open("w") as log:
                process = subprocess.Popen([binary], env=env, stdout=log, stderr=log)
                app = None
                try:
                    wait(lambda: (root / "ready.json").exists(), "readiness marker", process)
                    ready = json.loads((root / "ready.json").read_text())
                    assert ready["run"] == token and ready["scenario"] == fixture and ready["page"] == page
                    app = wait(lambda: next((a for a in pyatspi.Registry.getDesktop(0)
                                              if a.get_process_id() == process.pid), None), "AT-SPI app", process)
                    # Query fresh state while bounded waits drain native accessibility events.
                    app.set_cache_mask(Atspi.Cache.NONE)
                    app.clear_cache()
                    wait(lambda: visible_named(app, verdict), verdict, process)
                    action_name = "assert presentation"
                    if scenario in workflow_cases:
                        action_name = workflow(scenario, app, root, process, title)
                    elif scenario.startswith("verify-") and scenario != "verify-checking":
                        if scenario != "verify-unsigned":
                            for key in ("verify_certificate_details", "ui_technical_details"):
                                expand_and_collapse(app, title(key), process)
                        clear = wait(lambda: visible_named(app, title("verify_clear_results")), "clear action", process)
                        action = clear.queryAction()
                        assert action.nActions > 0 and action.doAction(0), "Clear action failed"
                        wait(lambda: visible_named(app, verdict) is None
                             and visible_named(app, title("verify_clear_results")) is None
                             and visible_named(app, title("ui_choose_file")),
                             "cleared verdict and empty verification state", process)
                        action_name = "expand/collapse signed details, then clear verification"
                    elif scenario in ("pin", "pin-error"):
                        cancel = wait(lambda: visible_named(app, title("ui_cancel")), "cancel PIN", process)
                        assert cancel.queryAction().doAction(0)
                        wait(lambda: visible_named(app, verdict) is None, "PIN dismissed", process)
                        action_name = "cancel PIN without entering a credential"
                    results.append({"scenario": scenario, "status": "passed", "action": action_name})
                except Exception as error:
                    if os.environ.get("GDK_BACKEND") == "x11" and shutil.which("import"):
                        subprocess.run(["import", "-window", "root", str(output / f"{scenario}-failure.png")], timeout=10)
                    if app is not None:
                        try:
                            tree = [{"role": node.getRoleName(), "name": node.name,
                                     "showing": node.getState().contains(pyatspi.STATE_SHOWING)}
                                    for node in descendants(app)]
                            (output / f"{scenario}-accessibility.json").write_text(json.dumps(tree, indent=2))
                        except Exception as diagnostic_error:
                            log.write(f"Accessibility capture failed: {diagnostic_error}\n")
                    results.append({"scenario": scenario, "status": "failed", "error": str(error)})
                    raise
                finally:
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                    (output / "results.json").write_text(json.dumps(results, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("app", type=lambda p: str(Path(p).resolve(strict=True)))
    parser.add_argument("output", type=Path)
    parser.add_argument("--scenario", action="append", help="Run one named scenario; repeat to select several")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    run(args.app, args.output, args.scenario)
