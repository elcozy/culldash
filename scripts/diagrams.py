#!/usr/bin/env python3
"""Renders docs/diagrams/*.puml to SVG and copies each diagram's source into
docs/APPFLOW.md, so the pictures, the .puml files and the document never
disagree.

    scripts/diagrams.py

Needs Java. PlantUML is one jar, downloaded once into .cache/. No Graphviz:
diagrams that lay out as graphs use PlantUML's own layout
(`!pragma layout smetana`).

In docs/APPFLOW.md a diagram lives between two markers, and everything
between them is replaced on every run:

    <!-- diagram:architecture -->
    <!-- /diagram -->
"""
import pathlib
import re
import subprocess
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIAGRAMS = ROOT / "docs" / "diagrams"
DOC = ROOT / "docs" / "APPFLOW.md"
VERSION = "1.2025.4"
JAR = ROOT / ".cache" / f"plantuml-{VERSION}.jar"
JAR_URL = f"https://github.com/plantuml/plantuml/releases/download/v{VERSION}/plantuml-mit-{VERSION}.jar"


def ensure_jar() -> None:
    if JAR.exists():
        return
    JAR.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading PlantUML {VERSION}...")
    urllib.request.urlretrieve(JAR_URL, JAR)


def java() -> str:
    """A java that runs on this machine.

    `/usr/bin/java` follows whatever JDK is installed system-wide, which on an
    Apple Silicon Mac can be an Intel-only build; without Rosetta that fails
    with "Bad CPU type in executable". Homebrew's is checked first because it
    matches the machine.
    """
    candidates = [
        "/opt/homebrew/opt/openjdk/bin/java",
        "/usr/local/opt/openjdk/bin/java",
        "java",
    ]
    for candidate in candidates:
        try:
            subprocess.run([candidate, "-version"], capture_output=True, check=True)
            return candidate
        except (OSError, subprocess.CalledProcessError):
            continue
    sys.exit("No usable Java. Install one with: brew install openjdk")


def render(files: list[pathlib.Path]) -> None:
    subprocess.run([java(), "-Djava.awt.headless=true", "-jar", str(JAR), "-tsvg", "-failfast2", *map(str, files)], cwd=DIAGRAMS, check=True)
    for file in files:
        svg = file.with_suffix(".svg").read_text()
        if re.search(r"Syntax Error|Cannot find Graphviz", svg, re.I):
            sys.exit(f"{file.name} did not render: see its .svg")


def embed(files: list[pathlib.Path]) -> None:
    doc = DOC.read_text()
    for file in files:
        name = file.stem
        block = (
            f"<!-- diagram:{name} -->\n"
            f"![{name}](diagrams/{name}.svg)\n\n"
            f"<details><summary>PlantUML source</summary>\n\n```plantuml\n{file.read_text().strip()}\n```\n\n</details>\n"
            f"<!-- /diagram -->"
        )
        pattern = re.compile(rf"<!-- diagram:{re.escape(name)} -->.*?<!-- /diagram -->", re.S)
        if not pattern.search(doc):
            sys.exit(f"docs/APPFLOW.md has no <!-- diagram:{name} --> block")
        doc = pattern.sub(lambda _: block, doc)
    DOC.write_text(doc)


if __name__ == "__main__":
    ensure_jar()
    sources = sorted(DIAGRAMS.glob("*.puml"))
    render(sources)
    embed(sources)
    print(f"Rendered and embedded {len(sources)} diagrams")
