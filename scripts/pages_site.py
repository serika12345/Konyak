#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DOCS = ROOT / "docs"
OUTPUT = ROOT / "build" / "pages"
RUNTIME_SCHEMA = (
    ROOT / "packages" / "konyak_cli" / "profiles" / "profile.schema.json"
)
MKDOCS_CONFIG = ROOT / "mkdocs.yml"

EXPECTED_CONTENT = {
    "index.html": "Konyak - Wine and Proton bottle management",
    "docs/index.html": "Konyak documentation",
    "docs/profiles/index.html": "Author a compatibility profile",
    "docs/profiles/schema-v1/index.html": "Konyak compatibility profile",
    "docs/profiles/validation/index.html": "Compatibility profile validation",
    "docs/profiles/versioning/index.html": "Compatibility profile versioning",
}
REQUIRED_FILES = {
    ".nojekyll",
    "styles.css",
    "assets/konyak.png",
    "schemas/profile-v1.schema.json",
}
ALLOWED_TOP_LEVEL = {
    ".nojekyll",
    "assets",
    "docs",
    "index.html",
    "schemas",
    "styles.css",
}
INTERNAL_DOCUMENT_NAMES = {
    "personal-project-notes.md",
    "progress.md",
    "todo.md",
}


class PagesSiteError(RuntimeError):
    pass


class _HtmlReferences(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.references: list[str] = []

    def handle_starttag(
        self,
        tag: str,
        attrs: list[tuple[str, str | None]],
    ) -> None:
        del tag
        self.references.extend(
            value
            for name, value in attrs
            if name in {"href", "src"} and value is not None
        )


def stage_product_page(source_docs: Path, output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    for name in ("index.html", "styles.css", ".nojekyll"):
        source = source_docs / name
        if not source.is_file():
            raise PagesSiteError(f"missing product page source: {source}")
        shutil.copy2(source, output / name)

    source_assets = source_docs / "assets"
    if not source_assets.is_dir():
        raise PagesSiteError(f"missing product page assets: {source_assets}")
    destination_assets = output / "assets"
    if destination_assets.exists():
        shutil.rmtree(destination_assets)
    shutil.copytree(source_assets, destination_assets)


def build_site() -> None:
    if OUTPUT.exists():
        shutil.rmtree(OUTPUT)
    OUTPUT.mkdir(parents=True)
    subprocess.run(
        [
            "mkdocs",
            "build",
            "--strict",
            "--clean",
            "--config-file",
            str(MKDOCS_CONFIG),
        ],
        cwd=ROOT,
        check=True,
    )
    stage_product_page(SOURCE_DOCS, OUTPUT)
    schema_mirror = OUTPUT / "schemas" / "profile-v1.schema.json"
    schema_mirror.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(RUNTIME_SCHEMA, schema_mirror)


def verify_artifact(output: Path, runtime_schema: Path) -> None:
    if not output.is_dir():
        raise PagesSiteError(f"Pages artifact does not exist: {output}")

    unexpected = sorted(path.name for path in output.iterdir())
    unexpected = [name for name in unexpected if name not in ALLOWED_TOP_LEVEL]
    if unexpected:
        raise PagesSiteError(
            "unexpected top-level Pages artifact entries: " + ", ".join(unexpected)
        )

    for relative_path, expected_text in EXPECTED_CONTENT.items():
        path = output / relative_path
        if not path.is_file():
            raise PagesSiteError(f"missing required Pages file: {relative_path}")
        try:
            contents = path.read_text(encoding="utf-8")
        except UnicodeError as error:
            raise PagesSiteError(
                f"required Pages file is not UTF-8: {relative_path}"
            ) from error
        if expected_text not in contents:
            raise PagesSiteError(
                f"required Pages content {expected_text!r} is absent from "
                f"{relative_path}"
            )

    for relative_path in REQUIRED_FILES:
        if not (output / relative_path).is_file():
            raise PagesSiteError(f"missing required Pages file: {relative_path}")

    product_page = (output / "index.html").read_text(encoding="utf-8")
    if 'href="docs/"' not in product_page:
        raise PagesSiteError(
            "product landing page is missing documentation navigation"
        )

    _reject_internal_documents(output)
    _verify_schema_mirror(output, runtime_schema)
    _verify_html_references(output)


def _reject_internal_documents(output: Path) -> None:
    for path in output.rglob("*"):
        if path.is_symlink():
            raise PagesSiteError(
                f"Pages artifact must not contain symlinks: {path.relative_to(output)}"
            )
        lower_name = path.name.lower()
        is_audit_document = "audit" in lower_name and path.suffix.lower() in {
            ".html",
            ".md",
        }
        if lower_name in INTERNAL_DOCUMENT_NAMES or is_audit_document:
            raise PagesSiteError(
                "Pages artifact contains an internal document: "
                f"{path.relative_to(output)}"
            )


def _verify_schema_mirror(output: Path, runtime_schema: Path) -> None:
    mirror = output / "schemas" / "profile-v1.schema.json"
    if mirror.read_bytes() != runtime_schema.read_bytes():
        raise PagesSiteError(
            "published profile v1 Schema must be byte-identical to the runtime Schema"
        )


def _verify_html_references(output: Path) -> None:
    for page in output.rglob("*.html"):
        parser = _HtmlReferences()
        try:
            parser.feed(page.read_text(encoding="utf-8"))
        except (UnicodeError, ValueError) as error:
            raise PagesSiteError(
                f"could not inspect HTML references in {page.relative_to(output)}"
            ) from error
        for reference in parser.references:
            target = _local_reference_target(output, page, reference)
            if target is not None and not target.is_file():
                raise PagesSiteError(
                    f"broken local link in {page.relative_to(output)}: {reference}"
                )


def _local_reference_target(
    output: Path,
    page: Path,
    reference: str,
) -> Path | None:
    parsed = urlsplit(reference)
    if parsed.scheme or parsed.netloc or not parsed.path:
        return None
    decoded_path = unquote(parsed.path)
    if decoded_path.startswith("/Konyak/"):
        relative_path = Path(decoded_path.removeprefix("/Konyak/"))
    elif decoded_path in {"/Konyak", "/Konyak/"}:
        relative_path = Path()
    elif decoded_path.startswith("/"):
        relative_path = Path(decoded_path.removeprefix("/"))
    else:
        relative_path = page.relative_to(output).parent / decoded_path

    candidate = (output / relative_path).resolve()
    output_root = output.resolve()
    try:
        candidate.relative_to(output_root)
    except ValueError as error:
        raise PagesSiteError(
            f"local link escapes the Pages artifact: {reference}"
        ) from error
    if decoded_path.endswith("/") or candidate.is_dir():
        return candidate / "index.html"
    return candidate


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build or verify Konyak Pages.")
    parser.add_argument("action", choices=("build", "check"))
    return parser


def main(arguments: list[str] | None = None) -> int:
    options = _parser().parse_args(arguments)
    try:
        if options.action == "build":
            build_site()
        else:
            verify_artifact(OUTPUT, RUNTIME_SCHEMA)
        return 0
    except (OSError, PagesSiteError, subprocess.CalledProcessError) as error:
        print(f"Pages {options.action} failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
