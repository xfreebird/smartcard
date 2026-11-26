"""Real password transformation and native picker/save actions using disposable synthetic files."""
import os
import re
import stat
import subprocess
import time
import pyatspi
from gi.repository import GLib
from ui_automation import descendants, invoke, reveal_named, visible_named, wait


def protection_workflow(app, root, process, title):
    assert os.environ.get('GDK_BACKEND') == 'x11', 'Native file chooser requires the isolated X11 runner'
    source = root / 'protection-source.txt'
    source.write_bytes(b'Synthetic native protection round trip.\n')
    encrypted = root / 'protection-source.txt.symmetric.p7m'
    restored = root / 'decrypted-protection-source.txt'
    original = source.read_bytes()

    def click(key):
        invoke(wait(lambda: reveal_named(app, title(key)), key, process))

    def key(value):
        subprocess.run(['xdotool', 'key', '--clearmodifiers', value], check=True, timeout=5)

    def focus_dialog(name):
        windows = subprocess.check_output(['xdotool', 'search', '--all', '--onlyvisible', '--maxdepth', '1', '--pid', str(process.pid),
                                           '--name', '^' + re.escape(name) + '$'], text=True).split()
        assert len(windows) == 1, 'Expected one native chooser window: ' + repr(windows)
        subprocess.run(['xdotool', 'windowfocus', '--sync', windows[0]], check=True, timeout=5)

    def select_operation(operation):
        # The isolated preview opens the real dialog; mode changes use its native controls.
        invoke(wait(lambda: reveal_named(app, title(operation)), operation, process))
        wait(lambda: visible_named(app, title('protect_choose_file')), 'protection dialog', process)

    def chooser(title_key="protect_choose_file"):
        # GTK exposes native chooser windows directly below the application.
        # Searching the document tree first also walks the chooser's directory
        # listing, whose remote accessibility children can change during a poll.
        for node in app:
            try:
                if (node.getRole() == pyatspi.ROLE_DIALOG and node.name == title(title_key)
                        and node.getState().contains(pyatspi.STATE_SHOWING)):
                    return node
            except GLib.GError:
                # Closing a native chooser can invalidate a node after traversal found it.
                continue
        return None

    def choose(path):
        click('protect_choose_file')
        dialog = wait(chooser, 'native open dialog', process)
        focus_dialog(title('protect_choose_file'))
        key('ctrl+l')
        entry = wait(lambda: next((node for node in descendants(dialog) if node.getRole() == pyatspi.ROLE_TEXT
                                   and node.getState().contains(pyatspi.STATE_SHOWING)), None), 'location entry', process)
        # One native edit avoids GTK path completion inserting characters between synthetic key events.
        assert entry.queryEditableText().setTextContents(str(path)), 'Location rejected native edit'
        wait(lambda: entry.queryText().getText(0, entry.queryText().characterCount) == str(path),
             'exact source path in native chooser', process)
        open_button = wait(lambda: visible_named(dialog, 'Open'), 'native open action', process)
        wait(lambda: open_button.getState().contains(pyatspi.STATE_SENSITIVE), 'enabled open action', process)
        invoke(open_button)
        wait(lambda: visible_named(app, path.name) and chooser() is None,
             'selected source', process)

    def submit(operation):
        # The mode selector has the same title; the form's submit action follows it in the tree.
        def button():
            nodes = [node for node in descendants(app)
                     if node.name == title(operation) and node.getRole() == pyatspi.ROLE_PUSH_BUTTON
                     and node.getState().contains(pyatspi.STATE_SHOWING)]
            return nodes[-1] if nodes else None
        return wait(button, 'submit action', process)

    def activate_submit(operation):
        wait(lambda: submit(operation).getState().contains(pyatspi.STATE_SENSITIVE), 'enabled submit', process)
        invoke(submit(operation))

    def edit(field, value):
        label = title(field)

        def editable_field():
            for node in descendants(app):
                if node.name != label:
                    continue
                try:
                    editable = node.queryEditableText()
                except NotImplementedError:
                    continue
                if not node.getState().contains(pyatspi.STATE_SHOWING):
                    node.queryComponent().scrollTo(pyatspi.SCROLL_ANYWHERE)
                if node.getState().contains(pyatspi.STATE_SHOWING):
                    return editable
            return None

        control = wait(editable_field, field, process)
        assert control.setTextContents(value), 'Password field rejected native edit'

    def save(path):
        click('protect_save_file')
        wait(lambda: chooser('protect_save_file'), 'native save dialog before cancellation', process)
        focus_dialog(title('protect_save_file'))
        key('Escape')
        wait(lambda: chooser('protect_save_file') is None, 'cancelled save', process)
        assert not path.exists(), 'Cancelling save must not create an output'
        wait(lambda: visible_named(app, title('protect_ready')), 'pending output retained', process)
        click('protect_save_file')
        dialog = wait(lambda: chooser('protect_save_file'), 'native save dialog', process)
        # Save dialogs have a filename entry; an absolute name selects the exact destination.
        name = wait(lambda: next((node for node in descendants(dialog) if node.name == 'Name:'
                                  and node.getRole() == pyatspi.ROLE_TEXT
                                  and node.getState().contains(pyatspi.STATE_SHOWING)), None), 'save filename', process)
        assert name.queryEditableText().setTextContents(str(path)), 'Save filename rejected native edit'
        invoke(wait(lambda: visible_named(dialog, 'Save'), 'save action', process))
        wait(lambda: path.is_file() and visible_named(app, title('protect_saved')), 'saved output', process)
        assert stat.S_IMODE(path.stat().st_mode) == 0o600

    wait(lambda: visible_named(app, title('protect_choose_file')), 'fixture protection dialog', process)
    assert not submit('protect_encrypt').getState().contains(pyatspi.STATE_SENSITIVE)
    click('protect_choose_file')
    wait(chooser, 'native chooser before cancellation', process)
    focus_dialog(title('protect_choose_file'))
    key('Escape')
    wait(lambda: chooser() is None, 'cancelled picker', process)
    assert source.read_bytes() == original
    assert not submit('protect_encrypt').getState().contains(pyatspi.STATE_SENSITIVE)
    choose(source)
    edit('protect_password', 'synthetic-roundtrip')
    edit('protect_confirm_password', 'mismatch')
    assert not submit('protect_encrypt').getState().contains(pyatspi.STATE_SENSITIVE)
    edit('protect_confirm_password', 'synthetic-roundtrip')
    activate_submit('protect_encrypt')
    wait(lambda: visible_named(app, title('protect_ready')), 'encryption finished', process)
    save(encrypted)
    assert source.read_bytes() == original and encrypted.read_bytes() != original

    select_operation('protect_decrypt')
    choose(encrypted)
    assert not submit('protect_decrypt').getState().contains(pyatspi.STATE_SENSITIVE)
    edit('protect_password', 'synthetic-roundtrip')
    activate_submit('protect_decrypt')
    wait(lambda: visible_named(app, title('protect_ready')), 'decryption finished', process)
    save(restored)
    assert restored.read_bytes() == original == source.read_bytes()

    select_operation('protect_remove')
    choose(restored)
    assert not submit('protect_remove').getState().contains(pyatspi.STATE_SENSITIVE)
    assert restored.read_bytes() == original
    confirmation = wait(lambda: reveal_named(app, title('protect_remove_confirm')), 'removal confirmation', process)
    focus_dialog('eSemnBun')
    for _ in range(80):
        if any(node.getState().contains(pyatspi.STATE_FOCUSED) for node in descendants(confirmation)):
            key('space')
            break
        key('Tab')
        time.sleep(.05)
    else:
        raise AssertionError('Removal confirmation never received native focus')
    wait(lambda: confirmation.getState().contains(pyatspi.STATE_CHECKED), 'checked removal confirmation', process)
    activate_submit('protect_remove')
    wait(lambda: not restored.exists() and visible_named(app, title('protect_removed')), 'confirmed removal', process)
    assert source.read_bytes() == original and encrypted.is_file()
    click('saved_close')
    return 'native picker/save cancel, mismatch rejection, encrypt/save/decrypt byte round trip, confirmed removal and private permissions'
