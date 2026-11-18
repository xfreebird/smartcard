"""Native AT-SPI queries and input used by the isolated Linux journey suites."""
import os
import subprocess
import time
import pyatspi
from gi.repository import GLib


def wait(predicate, description, process, timeout=20):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        context = GLib.MainContext.default()
        while context.pending():
            context.iteration(False)
        if process.poll() is not None:
            raise AssertionError(f"App exited during {description}")
        value = predicate()
        if value:
            return value
        time.sleep(.1)
    raise AssertionError(f"Timed out: {description}")


def descendants(node):
    # GTK may remove a child between reading the child count and fetching that child.
    if node is None:
        return
    yield node
    try:
        for child in node:
            yield from descendants(child)
    except GLib.GError:
        # Native chooser teardown can invalidate a subtree during enumeration.
        return


def visible_named(app, name):
    for node in descendants(app):
        try:
            if node.name == name and node.getState().contains(pyatspi.STATE_SHOWING):
                return node
        except GLib.GError:
            continue
    return None


def reveal_named(app, name):
    visible = visible_named(app, name)
    if visible is not None:
        return visible
    for node in descendants(app):
        if node.name == name:
            try:
                node.queryComponent().scrollTo(pyatspi.SCROLL_ANYWHERE)
            except (NotImplementedError, GLib.GError):
                continue
    return visible_named(app, name)


def invoke(node):
    while node is not None and node.getRole() not in (pyatspi.ROLE_APPLICATION, pyatspi.ROLE_FRAME, pyatspi.ROLE_WINDOW):
        # GtkMenuButton exposes its click action on a same-labelled child toggle.
        candidates = descendants(node) if node.getRole() == pyatspi.ROLE_PUSH_BUTTON else [node]
        for candidate in candidates:
            if candidate != node and candidate.name != node.name:
                continue
            try:
                action = candidate.queryAction()
                for index in range(action.nActions):
                    name = action.getName(index).lower()
                    if name in ("click", "press", "activate", "toggle") or name.endswith(".activate"):
                        assert action.doAction(index), "Native action rejected"
                        return
            except NotImplementedError:
                pass
        if node.getState().contains(pyatspi.STATE_EXPANDABLE):
            # GTK 4 exposes expansion state but not an AT-SPI activation/focus action.
            # Use the native keyboard focus chain; GTK also scrolls the focused row into view.
            if os.environ.get("GDK_BACKEND") != "x11":
                raise RuntimeError("GTK disclosure automation requires GDK_BACKEND=x11 and xdotool")
            windows = subprocess.check_output(["xdotool", "search", "--all", "--onlyvisible", "--pid",
                                                str(node.get_process_id()), "--name", "eSemnBun"], text=True).split()
            assert windows, "No native application window"
            subprocess.run(["xdotool", "windowfocus", "--sync", windows[0]], check=True, timeout=5)
            for _ in range(80):
                if any(child.getState().contains(pyatspi.STATE_FOCUSED) for child in descendants(node)):
                    subprocess.run(["xdotool", "key", "--clearmodifiers", "space"], check=True, timeout=5)
                    return
                subprocess.run(["xdotool", "key", "--clearmodifiers", "Tab"], check=True, timeout=5)
                time.sleep(.05)
            raise AssertionError("Disclosure never received native keyboard focus")

        node = node.parent
    raise AssertionError("No native activation action on control")


def expand_and_collapse(app, name, process, expanded_name=None):
    def control(label, expanded):
        node = reveal_named(app, label)
        while node is not None and node != app:
            state = node.getState()
            if state.contains(pyatspi.STATE_EXPANDABLE):
                return node if state.contains(pyatspi.STATE_EXPANDED) == expanded else None
            node = node.parent
        return None

    row = wait(lambda: control(name, False), "collapsed " + name, process)
    invoke(row)
    expanded_label = expanded_name or name
    row = wait(lambda: control(expanded_label, True), "expanded " + expanded_label, process)
    invoke(row)
    wait(lambda: control(name, False), "collapsed " + name, process)
