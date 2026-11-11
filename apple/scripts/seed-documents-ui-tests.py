#!/usr/bin/env python3
"""Seed only synthetic files and new isolated QA preference domains; refuse existing fixtures."""
import json
from pathlib import Path
import plistlib
import shutil
import sys
import time
import uuid


def seed(container: Path, fixtures: Path, sample: Path):
    documents = container / 'Documents'
    preferences = container / 'Library/Preferences'
    suites = [preferences / f'md.esemnbun.qa.documents.{name}.plist' for name in ('history', 'final', 'duo')]
    originals = list(fixtures.glob('*.txt'))
    assert len(originals) == 1 and (fixtures / 'detached-signature.xml').is_file()
    destinations = [(sample, documents / 'QA-synthetic-semnat.pdf'),
                    (fixtures / 'detached-signature.xml', documents / 'detached-signature.xml'),
                    (originals[0], documents / 'Originals' / originals[0].name)]
    assert all(not target.exists() for target in suites + [target for _, target in destinations]), \
        'Use a fresh dedicated simulator; refusing to replace an existing fixture/profile'
    for source, target in destinations:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    history = [dict(id=str(uuid.uuid4()), title=target.name, subtitle='Synthetic integration fixture',
                    ok=True, date=time.time() - 978307200, fileURL=target.as_uri(), signedOutput=True)
               for _, target in destinations[:2]]
    preferences.mkdir(parents=True, exist_ok=True)
    for target in suites:
        # Omit signedDocuments so the real store performs its legacy history migration.
        target.write_bytes(plistlib.dumps({'activity': json.dumps(history).encode(),
                                          'appLanguage': 'en', 'appTheme': 'light'}))


if __name__ == '__main__':
    seed(*map(Path, sys.argv[1:]))
