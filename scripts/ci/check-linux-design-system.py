#!/usr/bin/env python3
"""Compile the GTK design system with only GTK/Foundation/localization available."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def main():
    source = ROOT / 'linux/Sources'
    with tempfile.TemporaryDirectory(prefix='esemnbun-design-system-') as folder:
        package = Path(folder)
        sources = package / 'Sources'
        shutil.copytree(source / 'CAdwaita', sources / 'CAdwaita')
        design = sources / 'DesignSystem'
        shutil.copytree(source / 'MoldSignGnome/Presentation/DesignSystem', design)
        support = source / 'MoldSignGnome/Infrastructure'
        for path in [support / 'GTK/Gtk.swift', support / 'Localization/L10n.swift',
                     support / 'Localization/LocalizationFormat.swift']:
            shutil.copy2(path, design / path.name)
        (package / 'Package.swift').write_text('''// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "DesignSystemBoundary", targets: [
    .systemLibrary(name: "CAdwaita", pkgConfig: "libadwaita-1"),
    .target(name: "DesignSystem", dependencies: ["CAdwaita"]),
])
''')
        subprocess.run([os.environ.get('SWIFT', 'swift'), 'build', '--package-path', str(package)], check=True)


if __name__ == '__main__':
    main()
