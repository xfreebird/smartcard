"""Finder presentation shared by local and CI macOS installers."""
import os
import subprocess

from mac_alias import Bookmark


class NativeBookmark:
    def __init__(self, path):
        self.path = path

    def to_bytes(self):
        return subprocess.check_output([os.environ["ESEMNBUN_BOOKMARK_TOOL"], self.path])


# Finder on current macOS does not display the background with mac-alias's
# generated bookmark. Foundation produces the bookmark Finder expects.
Bookmark.for_file = staticmethod(NativeBookmark)

format = "UDZO"
filesystem = "HFS+"
files = [defines["app"]]
symlinks = {" ": "/Applications"}
icon = defines["icon"]
background = defines["background"]
window_rect = ((200, 200), (680, 425))
icon_size = 128
text_size = 12
icon_locations = {"eSemnBun.app": (208, 190), " ": (472, 190)}
# Finder hide-extension flags add com.apple.FinderInfo to the signed bundle.
# Keep the bundle untouched so strict code-signature verification succeeds.
hide_extensions = []
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_sidebar = False
show_icon_preview = True
include_icon_view_settings = True
include_list_view_settings = False
