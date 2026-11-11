#!/usr/bin/env python3
"""Check traceability only. This never runs or certifies application tests."""
import argparse
import json
from pathlib import Path
import re


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--require-full-automation', action='store_true',
                        help='Fail if any applicable platform lacks complete automatic journey coverage.')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    catalog = json.loads((root / 'tests/journeys/catalog.json').read_text())
    source = (root / catalog['source']).read_text()
    documented = set(re.findall(r'^\| ([GMADLC]\d{2}) \|', source, re.M))
    ids = [row['id'] for row in catalog['journeys']]
    assert len(ids) == len(set(ids)), 'Duplicate journey IDs'
    assert documented <= set(ids), f'Missing documented journeys: {documented - set(ids)}'
    assert set(ids) - documented == {'P01', 'P02', 'P03'}, 'Unexpected supplemental IDs'
    suites = catalog['suites']
    for name, suite in suites.items():
        assert (root / suite['path']).exists(), f'Missing suite {name}: {suite["path"]}'
    scenario_ids = set()
    for scenario in catalog.get('mock_scenarios', []):
        assert scenario['id'] not in scenario_ids, 'Duplicate mock scenario'
        scenario_ids.add(scenario['id'])
        assert scenario['assertions'], scenario['id']
        supported = set()
        for suite in scenario['suites']:
            assert suite in suites, (scenario['id'], suite)
            supported.update(suites[suite]['platforms'])
        assert set(scenario['platforms']) <= supported, scenario['id']
    incomplete = []
    for row in catalog['journeys']:
        assert row['acceptance'] and row['edge_cases'] and row['runtime_check'], row['id']
        assert row['coverage'] in {'partial', 'runtime-required', 'automated'}, row['id']
        platforms = set(row['platforms'])
        covered = set()
        for name in row['suites']:
            assert name in suites, (row['id'], name)
            applicable = platforms & set(suites[name]['platforms'])
            assert applicable, f'{name} does not apply to {row["id"]}'
            covered.update(applicable)
        if covered != platforms or row['coverage'] != 'automated':
            incomplete.append(row['id'])
    print(f'{len(documented)} documented journeys + 3 current protection journeys mapped; suite paths exist.')
    print(f'{len(scenario_ids)} mock scenario groups mapped across their native suites.')
    print(f'{len(incomplete)} journeys have partial automation or native runtime requirements. No tests executed.')
    if args.require_full_automation and incomplete:
        raise SystemExit('Full automation gate not met: ' + ', '.join(incomplete))


if __name__ == '__main__':
    main()
