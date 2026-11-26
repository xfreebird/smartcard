"""Convert LLVM LCOV to Sonar generic coverage with portable repository paths."""

from collections import defaultdict
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def export(source_stream, repository, source_root, output):
    files = defaultdict(dict)
    source = None
    for line in source_stream:
        if line.startswith("SF:"):
            candidate = (repository / line[3:].strip()).resolve()
            source = candidate.relative_to(repository) if candidate.is_relative_to(source_root) else None
        elif line.strip() == "end_of_record":
            source = None
        elif source is not None and line.startswith("DA:"):
            number, count, *_ = line[3:].strip().split(",")
            number, count = int(number), int(count)
            if number < 1 or count < 0:
                raise ValueError(f"Invalid coverage at {source}:{number}")
            files[source][number] = files[source].get(number, False) or count > 0

    covered = sum(sum(lines.values()) for lines in files.values())
    if not covered:
        raise ValueError(f"No covered production lines found under {source_root}")

    root = ET.Element("coverage", version="1")
    for source, lines in sorted(files.items()):
        file = ET.SubElement(root, "file", path=source.as_posix())
        max_line = len((repository / source).read_bytes().splitlines())
        for number, hit in sorted(lines.items()):
            if number > max_line:
                raise ValueError(f"Coverage references a nonexistent line: {source}:{number}")
            ET.SubElement(file, "lineToCover", lineNumber=str(number), covered=str(hit).lower())
    ET.indent(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)
    print(f"{output.name}: {covered}/{sum(map(len, files.values()))} lines hit in {len(files)} source files")


if __name__ == "__main__":
    repo_path, source_path, report_path = map(Path, sys.argv[1:])
    repo_path = repo_path.resolve()
    source_path = (repo_path / source_path).resolve()
    if not source_path.is_relative_to(repo_path) or not source_path.is_dir():
        raise SystemExit("Coverage source directory must be inside the repository")
    export(sys.stdin, repo_path, source_path, report_path)
