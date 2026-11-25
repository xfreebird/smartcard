"""Shared helpers that run repository automation in-process against temporary checkouts.

Scripts are executed from their real paths, so coverage is attributed to the checked-in sources,
while every write is redirected to a temporary directory. Nothing here contacts a network or a
device; external commands and services are always replaced by the individual tests.
"""
from contextlib import ExitStack, contextmanager, redirect_stderr, redirect_stdout
from dataclasses import dataclass
import importlib.util
import io
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[2]


@dataclass
class Result:
    code: object
    stdout: str
    stderr: str
    namespace: dict


def load(relative, name=None):
    """Import a script (hyphenated names included) as a fresh module."""
    path = REPO / relative
    name = name or 'tooling_' + re.sub(r'\W', '_', relative.removesuffix('.py'))
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    with patch.object(sys, 'path', [str(path.parent), *sys.path]):
        sys.modules[name] = module
        spec.loader.exec_module(module)
    return module


@contextmanager
def checkout_at(relative, root):
    """Make `Path(__file__).resolve()` of one script point into `root`, a disposable checkout."""
    script = REPO / relative
    target = Path(root).resolve() / relative
    real = Path.resolve

    def resolve(self, strict=False):
        resolved = real(self, strict)
        return target if resolved == script else resolved

    with patch.object(Path, 'resolve', resolve):
        yield target


def run(relative, *argv, stdin='', root=None, env=None, cwd=None):
    """Run a script as `__main__` and capture its exit status and output."""
    path = REPO / relative
    out, err = io.StringIO(), io.StringIO()
    namespace = {}
    code = 0
    with ExitStack() as stack:
        stack.enter_context(patch.object(sys, 'argv', [str(path), *map(str, argv)]))
        stack.enter_context(patch.object(sys, 'stdin', io.StringIO(stdin)))
        stack.enter_context(patch.object(sys, 'path', [str(path.parent), *sys.path]))
        stack.enter_context(redirect_stdout(out))
        stack.enter_context(redirect_stderr(err))
        if root is not None:
            stack.enter_context(checkout_at(relative, root))
        if env is not None:
            stack.enter_context(patch.dict(os.environ, env))
        if cwd is not None:
            previous = os.getcwd()
            os.chdir(cwd)
            stack.callback(os.chdir, previous)
        try:
            namespace = runpy.run_path(str(path), run_name='__main__')
        except SystemExit as error:
            code = error.code
    return Result(0 if code is None else code, out.getvalue(), err.getvalue(), namespace)


def copy_into(root, *relatives):
    """Copy repository inputs into a temporary checkout, preserving relative paths."""
    for relative in relatives:
        source = REPO / relative
        target = Path(root) / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            shutil.copytree(source, target, dirs_exist_ok=True)
        else:
            shutil.copy2(source, target)


def png(path, size=(4, 4), color=(20, 80, 200, 255), mode='RGBA'):
    """Write a small real PNG and return its path."""
    from PIL import Image

    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new(mode, size, color if mode != 'RGB' else color[:3]).save(path, compress_level=1)
    return path


@contextmanager
def fast_pillow():
    """Render with Pillow's bundled font and cheap blur/compression.

    Store artwork is full resolution; the tests keep every size, mode and composite, but skip
    macOS-only font files, wide Gaussian shadows and maximum PNG compression.
    """
    from PIL import Image, ImageFilter, ImageFont

    real_save, real_filter, real_truetype = Image.Image.save, Image.Image.filter, ImageFont.truetype

    def truetype(font=None, size=10, *args, **kwargs):
        # Named system fonts differ per host; the bundled font keeps layout identical everywhere.
        if isinstance(font, (str, os.PathLike)):
            return ImageFont.load_default(size)
        return real_truetype(font, size, *args, **kwargs)

    def blur_free(image, kind):
        return image.copy() if isinstance(kind, ImageFilter.GaussianBlur) else real_filter(image, kind)

    def quick_save(image, fp, format=None, **params):
        params.pop('optimize', None)
        params.setdefault('compress_level', 1)
        return real_save(image, fp, format, **params)

    with patch.object(ImageFont, 'truetype', truetype), patch.object(Image.Image, 'filter', blur_free), \
            patch.object(Image.Image, 'save', quick_save):
        yield


def completed(args=(), returncode=0, stdout=b'', stderr=b''):
    return subprocess.CompletedProcess(list(args), returncode, stdout, stderr)


class TempCase(unittest.TestCase):
    """Test case with a resolved temporary directory removed after each test."""

    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.tmp = Path(folder.name).resolve()
