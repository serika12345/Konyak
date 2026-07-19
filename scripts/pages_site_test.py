#!/usr/bin/env python3
import tempfile
import unittest
from pathlib import Path

import pages_site


class PagesSiteTest(unittest.TestCase):
    def test_stages_only_the_product_landing_page_and_assets(self):
        with tempfile.TemporaryDirectory(prefix="konyak-pages-stage-test-") as raw:
            root = Path(raw)
            source = root / "docs"
            output = root / "build" / "pages"
            _write(source / "index.html", "<h1>Konyak</h1>")
            _write(source / "styles.css", "body {}\n")
            _write(source / ".nojekyll", "")
            _write(source / "assets" / "konyak.png", "image")
            _write(source / "progress.md", "internal")
            _write(source / "public" / "index.md", "built by MkDocs")

            pages_site.stage_product_page(source, output)

            self.assertEqual(
                sorted(
                    path.relative_to(output).as_posix()
                    for path in output.rglob("*")
                    if path.is_file()
                ),
                [".nojekyll", "assets/konyak.png", "index.html", "styles.css"],
            )

    def test_accepts_a_curated_artifact_with_resolved_local_links(self):
        with tempfile.TemporaryDirectory(prefix="konyak-pages-check-test-") as raw:
            root = Path(raw)
            schema = root / "profile.schema.json"
            output = root / "pages"
            schema_bytes = b'{"schemaVersion":1}\n'
            schema.write_bytes(schema_bytes)
            _write_valid_artifact(output, schema_bytes)

            pages_site.verify_artifact(output, schema)

    def test_rejects_a_missing_public_route(self):
        with tempfile.TemporaryDirectory(prefix="konyak-pages-check-test-") as raw:
            root = Path(raw)
            schema = root / "profile.schema.json"
            output = root / "pages"
            schema_bytes = b'{"schemaVersion":1}\n'
            schema.write_bytes(schema_bytes)
            _write_valid_artifact(output, schema_bytes)
            (output / "docs" / "profiles" / "schema-v1" / "index.html").unlink()

            with self.assertRaisesRegex(
                pages_site.PagesSiteError,
                "docs/profiles/schema-v1/index.html",
            ):
                pages_site.verify_artifact(output, schema)

    def test_rejects_a_schema_mirror_that_differs_by_one_byte(self):
        with tempfile.TemporaryDirectory(prefix="konyak-pages-check-test-") as raw:
            root = Path(raw)
            schema = root / "profile.schema.json"
            output = root / "pages"
            schema_bytes = b'{"schemaVersion":1}\n'
            schema.write_bytes(schema_bytes)
            _write_valid_artifact(output, schema_bytes + b" ")

            with self.assertRaisesRegex(
                pages_site.PagesSiteError,
                "byte-identical",
            ):
                pages_site.verify_artifact(output, schema)

    def test_rejects_internal_and_audit_documents_anywhere(self):
        with tempfile.TemporaryDirectory(prefix="konyak-pages-check-test-") as raw:
            root = Path(raw)
            schema = root / "profile.schema.json"
            output = root / "pages"
            schema_bytes = b'{"schemaVersion":1}\n'
            schema.write_bytes(schema_bytes)
            _write_valid_artifact(output, schema_bytes)
            _write(output / "docs" / "internal" / "progress.md", "private")

            with self.assertRaisesRegex(
                pages_site.PagesSiteError,
                "internal document",
            ):
                pages_site.verify_artifact(output, schema)

    def test_rejects_a_broken_relative_link(self):
        with tempfile.TemporaryDirectory(prefix="konyak-pages-check-test-") as raw:
            root = Path(raw)
            schema = root / "profile.schema.json"
            output = root / "pages"
            schema_bytes = b'{"schemaVersion":1}\n'
            schema.write_bytes(schema_bytes)
            _write_valid_artifact(output, schema_bytes)
            _write(
                output / "docs" / "profiles" / "index.html",
                '<h1>Author a compatibility profile</h1><a href="missing/">bad</a>',
            )

            with self.assertRaisesRegex(
                pages_site.PagesSiteError,
                "broken local link",
            ):
                pages_site.verify_artifact(output, schema)

    def test_rejects_a_product_page_without_documentation_navigation(self):
        with tempfile.TemporaryDirectory(prefix="konyak-pages-check-test-") as raw:
            root = Path(raw)
            schema = root / "profile.schema.json"
            output = root / "pages"
            schema_bytes = b'{"schemaVersion":1}\n'
            schema.write_bytes(schema_bytes)
            _write_valid_artifact(output, schema_bytes)
            _write(
                output / "index.html",
                '<title>Konyak - Wine and Proton bottle management</title>'
                '<link href="styles.css"><img src="assets/konyak.png">',
            )

            with self.assertRaisesRegex(
                pages_site.PagesSiteError,
                "documentation navigation",
            ):
                pages_site.verify_artifact(output, schema)


def _write_valid_artifact(output: Path, schema_bytes: bytes) -> None:
    _write(
        output / "index.html",
        '<title>Konyak - Wine and Proton bottle management</title>'
        '<link href="styles.css"><img src="assets/konyak.png">'
        '<a href="docs/">Documentation</a>',
    )
    _write(output / "styles.css", "body {}\n")
    _write(output / ".nojekyll", "")
    _write(output / "assets" / "konyak.png", "image")
    _write(
        output / "docs" / "index.html",
        '<h1>Konyak documentation</h1><a href="profiles/">Profiles</a>',
    )
    _write(
        output / "docs" / "profiles" / "index.html",
        '<h1>Author a compatibility profile</h1>'
        '<a href="schema-v1/">Schema</a>'
        '<a href="validation/">Validation</a>'
        '<a href="versioning/">Versioning</a>',
    )
    _write(
        output / "docs" / "profiles" / "schema-v1" / "index.html",
        "<h1>Konyak compatibility profile</h1>",
    )
    _write(
        output / "docs" / "profiles" / "validation" / "index.html",
        "<h1>Compatibility profile validation</h1>",
    )
    _write(
        output / "docs" / "profiles" / "versioning" / "index.html",
        "<h1>Compatibility profile versioning</h1>",
    )
    schema_path = output / "schemas" / "profile-v1.schema.json"
    schema_path.parent.mkdir(parents=True, exist_ok=True)
    schema_path.write_bytes(schema_bytes)


def _write(path: Path, contents: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents, encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
