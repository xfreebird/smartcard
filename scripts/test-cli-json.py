#!/usr/bin/env python3
"""Process-level Swift CLI JSON regression checks. Never opens a card or requests a PIN.

Optional genuine synthetic detached fixtures can be exported by the Swift missing-reference test.
Usage: python3 scripts/test-cli-json.py /path/esemnbun --detached-fixtures /path/fixtures
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cli', type=Path)
    parser.add_argument('--detached-fixtures', type=Path)
    parser.add_argument('--results', type=Path)
    args = parser.parse_args()
    cli = args.cli.resolve()
    repo = Path(__file__).resolve().parents[1]
    checks = []
    with tempfile.TemporaryDirectory(prefix='esemnbun-cli-json-') as directory:
        root = Path(directory)

        def check(name, words, exit_code, status=None, error=None):
            process = subprocess.run([str(cli), *map(str, words)], capture_output=True, text=True, timeout=15)
            assert process.returncode == exit_code, (name, process.returncode, process.stderr)
            result = json.loads(process.stdout)
            assert result['schemaVersion'] == 1, name
            if status:
                assert result['ok'] and result['data']['status'] == status, (name, result)
            if error:
                assert not result['ok'] and result['error']['code'] == error, (name, result)
            assert str(root) not in process.stdout, name
            assert 'private-value' not in process.stdout + process.stderr, name
            checks.append({'case': name, 'exitCode': exit_code, 'result': result})
            return result

        capability = check('capabilities', ['capabilities', '--json'], 0)
        assert capability['data']['verification']['json'], 'This suite targets the Swift JSON verifier'
        unsigned = repo / 'swift/MoldSignKit/Tests/MoldSignKitTests/Fixtures/unsigned.pdf'
        check('unsigned', ['verify', '--json', unsigned], 2, 'no_recognized_signature')
        check('unreadable', ['verify', '--json', root / 'private-missing.pdf'], 1, error='INPUT_UNREADABLE')
        check('bad_arguments', ['verify', '--json'], 1, error='INVALID_ARGUMENT')
        check('unsupported_sign', ['sign', 'private-value', '--json'], 1, error='UNSUPPORTED')
        link = root / 'symlink.pdf'
        link.symlink_to(unsigned)
        check('symlink_input', ['verify', '--json', link], 1, error='INPUT_UNREADABLE')
        fifo = root / 'pipe.pdf'
        os.mkfifo(fifo)
        check('fifo_input', ['verify', '--json', fifo], 1, error='INPUT_UNREADABLE')
        if args.detached_fixtures:
            fixtures = args.detached_fixtures.resolve()
            signature = fixtures / 'detached-signature.xml'
            originals = list(fixtures.glob('*.txt'))
            assert len(originals) == 1 and signature.is_file(), 'Expected one XML signature and one synthetic TXT original'
            missing = root / 'missing'
            missing.mkdir()
            tampered = root / 'tampered'
            tampered.mkdir()
            (tampered / originals[0].name).write_bytes(b'tampered bytes')
            check('missing_original', ['verify', '--json', signature, missing], 2, 'incomplete')
            check('resolved_original', ['verify', '--json', signature, fixtures], 0, 'unconfirmed')
            # The vendor-oriented core does not normalize every XML spelling; never accept it as valid.
            import re
            single_quoted = root / 'single-quoted.xml'
            single_quoted.write_text(re.sub(r'URI="(file:/[^"]*)"', r"URI='\1'", signature.read_text()))
            check('unsupported_quoting_not_validated', ['verify', '--json', single_quoted, fixtures], 2, 'invalid')
            check('tampered_original', ['verify', '--json', signature, tampered], 2, 'invalid')
    if args.results:
        args.results.write_text(json.dumps(checks, indent=2) + '\n')
    print(f'CLI JSON process checks passed: {len(checks)}')


if __name__ == '__main__':
    main()
