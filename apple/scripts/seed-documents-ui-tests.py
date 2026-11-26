#!/usr/bin/env python3
"""Seed only synthetic files and new isolated QA preference domains; refuse existing fixtures."""
import json
import os
from pathlib import Path
import plistlib
import shutil
import sys
import tempfile
import time
import uuid


def contained(value, roots, what):
    """Resolve `value` and require it inside one of `roots` (symbolic links cannot escape)."""
    candidate = os.path.realpath(value)
    for root in roots:
        if os.path.commonpath([root, candidate]) == root:
            return Path(candidate)
    raise SystemExit(f'{what} must be inside {", ".join(roots)}: {value}')


def allowed_roots(environment=os.environ):
    temporary = [Path(tempfile.gettempdir()), Path('/tmp')]
    if environment.get('RUNNER_TEMP'):
        temporary.append(Path(environment['RUNNER_TEMP']))
    repository = Path(__file__).resolve().parents[2]
    simulators = Path.home() / 'Library/Developer/CoreSimulator/Devices'
    resolve = lambda paths: sorted({str(path.resolve()) for path in paths})
    # Containers come from `simctl get_app_container`; fixtures and the sample from the repository or a run directory.
    return resolve([simulators, *temporary]), resolve([repository, *temporary])


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


def main(argv):
    if len(argv) != 3:
        raise SystemExit('Usage: seed-documents-ui-tests.py SIMULATOR_APP_CONTAINER FIXTURES_DIR SAMPLE_PDF')
    containers, sources = allowed_roots()
    seed(contained(argv[0], containers, 'The app container'),
         contained(argv[1], sources, 'The fixtures directory'),
         contained(argv[2], sources, 'The sample PDF'))


if __name__ == '__main__':
    main(sys.argv[1:])
