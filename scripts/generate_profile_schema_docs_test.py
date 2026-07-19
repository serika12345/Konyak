#!/usr/bin/env python3
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import generate_profile_schema_docs as generator  # noqa: E402


SCHEMA_PATH = ROOT / "packages" / "konyak_cli" / "profiles" / "profile.schema.json"
OUTPUT_PATH = ROOT / "docs" / "public" / "profiles" / "schema-v1.md"


def documented_schema():
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "https://example.test/profile.schema.json",
        "title": "Test profile",
        "description": "A documented test profile.",
        "type": "object",
        "required": ["schemaVersion", "name", "actions", "labels"],
        "properties": {
            "schemaVersion": {
                "description": "Profile schema contract version.",
                "const": 1,
            },
            "name": {
                "description": "Human-readable profile name.",
                "type": "string",
                "minLength": 1,
            },
            "actions": {
                "description": "Ordered declarative actions.",
                "type": "array",
                "maxItems": 2,
                "items": {
                    "oneOf": [
                        {
                            "description": "A named test action.",
                            "type": "object",
                            "required": ["kind"],
                            "properties": {
                                "kind": {
                                    "description": "Action discriminator.",
                                    "const": "test",
                                }
                            },
                        }
                    ]
                },
            },
            "labels": {
                "description": "Non-empty test labels.",
                "type": "array",
                "items": {
                    "type": "string",
                    "minLength": 1,
                    "pattern": "^[a-z]+$",
                },
            },
        },
        "x-konyak-semanticRules": [
            {
                "id": "actions.unique",
                "path": "/actions",
                "description": "Actions must have unique names.",
            }
        ],
    }


class GenerateProfileSchemaDocsTest(unittest.TestCase):
    def test_renders_fields_variants_and_semantic_rules(self):
        document = generator.generate_document(documented_schema())

        self.assertIn("# Test profile", document)
        self.assertIn("`/name`", document)
        self.assertIn("Human-readable profile name.", document)
        self.assertIn("minimum length: `1`", document)
        self.assertIn("A named test action.", document)
        self.assertIn("item type: `string`", document)
        self.assertIn("item minimum length: `1`", document)
        self.assertIn("item pattern: `^[a-z]+$`", document)
        self.assertIn("`/schemaVersion` | yes | `integer`", document)
        self.assertIn("`actions.unique`", document)
        self.assertIn("Actions must have unique names.", document)
        self.assertTrue(document.endswith("\n"))

    def test_rejects_missing_public_field_descriptions(self):
        schema = documented_schema()
        del schema["properties"]["name"]["description"]

        with self.assertRaisesRegex(
            generator.DocumentationError,
            r"/name.*description",
        ):
            generator.generate_document(schema)

    def test_check_mode_rejects_stale_output(self):
        with tempfile.TemporaryDirectory(prefix="konyak-schema-doc-test-") as raw:
            root = Path(raw)
            schema_path = root / "profile.schema.json"
            output_path = root / "schema-v1.md"
            schema_path.write_text(
                json.dumps(documented_schema()),
                encoding="utf-8",
            )
            output_path.write_text("stale\n", encoding="utf-8")

            with redirect_stderr(io.StringIO()):
                result = generator.main(
                    [
                        "--schema",
                        str(schema_path),
                        "--output",
                        str(output_path),
                        "--check",
                    ]
                )

            self.assertEqual(result, 1)
            self.assertEqual(output_path.read_text(encoding="utf-8"), "stale\n")

    def test_runtime_schema_annotations_are_complete(self):
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

        generator.generate_document(schema)

    def test_committed_runtime_reference_is_current(self):
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

        self.assertEqual(
            OUTPUT_PATH.read_text(encoding="utf-8"),
            generator.generate_document(schema),
        )


if __name__ == "__main__":
    unittest.main()
