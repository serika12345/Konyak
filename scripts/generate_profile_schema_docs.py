#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Mapping, Sequence
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SCHEMA_PATH = (
    ROOT / "packages" / "konyak_cli" / "profiles" / "profile.schema.json"
)
DEFAULT_OUTPUT_PATH = ROOT / "docs" / "public" / "profiles" / "schema-v1.md"
SEMANTIC_RULES_KEY = "x-konyak-semanticRules"


class DocumentationError(RuntimeError):
    pass


def _object(value: object, path: str) -> Mapping[str, object]:
    if not isinstance(value, Mapping):
        raise DocumentationError(f"{path} must be an object")
    return value


def _non_empty_string(value: object, path: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise DocumentationError(f"{path} must contain a non-empty string")
    return value


def _sequence(value: object, path: str) -> Sequence[object]:
    if isinstance(value, (str, bytes)) or not isinstance(value, Sequence):
        raise DocumentationError(f"{path} must be an array")
    return value


def _pointer(parent: str, name: str) -> str:
    escaped = name.replace("~", "~0").replace("/", "~1")
    return f"/{escaped}" if parent == "/" else f"{parent}/{escaped}"


def _properties(node: Mapping[str, object], path: str) -> Mapping[str, object]:
    value = node.get("properties", {})
    return _object(value, f"{path}/properties")


def _validate_annotations(schema: Mapping[str, object]) -> None:
    _non_empty_string(schema.get("title"), "/title")
    _non_empty_string(schema.get("description"), "/description")
    _validate_node_annotations(schema, "/")
    _semantic_rules(schema)


def _validate_node_annotations(node: Mapping[str, object], path: str) -> None:
    for name, raw_child in _properties(node, path).items():
        child_path = _pointer(path, name)
        child = _object(raw_child, child_path)
        _non_empty_string(child.get("description"), f"{child_path}/description")
        _validate_node_annotations(child, child_path)
        _validate_array_items(child, child_path)

    alternatives = node.get("oneOf")
    if alternatives is None:
        return
    for index, raw_alternative in enumerate(
        _sequence(alternatives, f"{path}/oneOf")
    ):
        alternative_path = f"{path}/oneOf/{index}"
        alternative = _object(raw_alternative, alternative_path)
        _non_empty_string(
            alternative.get("description"),
            f"{alternative_path}/description",
        )


def _validate_array_items(node: Mapping[str, object], path: str) -> None:
    if node.get("type") != "array" or "items" not in node:
        return
    items = _object(node["items"], f"{path}/*")
    if "properties" in items:
        _validate_node_annotations(items, f"{path}/*")
    alternatives = items.get("oneOf")
    if alternatives is None:
        return
    for index, raw_alternative in enumerate(
        _sequence(alternatives, f"{path}/*/oneOf")
    ):
        alternative_path = f"{path}/*/oneOf/{index}"
        alternative = _object(raw_alternative, alternative_path)
        _non_empty_string(
            alternative.get("description"),
            f"{alternative_path}/description",
        )
        _validate_node_annotations(alternative, alternative_path)


def _semantic_rules(schema: Mapping[str, object]) -> list[Mapping[str, object]]:
    raw_rules = _sequence(
        schema.get(SEMANTIC_RULES_KEY, []),
        f"/{SEMANTIC_RULES_KEY}",
    )
    rules: list[Mapping[str, object]] = []
    ids: set[str] = set()
    for index, raw_rule in enumerate(raw_rules):
        rule_path = f"/{SEMANTIC_RULES_KEY}/{index}"
        rule = _object(raw_rule, rule_path)
        rule_id = _non_empty_string(rule.get("id"), f"{rule_path}/id")
        _non_empty_string(rule.get("path"), f"{rule_path}/path")
        _non_empty_string(rule.get("description"), f"{rule_path}/description")
        if rule_id in ids:
            raise DocumentationError(f"duplicate semantic rule ID: {rule_id}")
        ids.add(rule_id)
        rules.append(rule)
    return rules


def _json_literal(value: object) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def _type_label(node: Mapping[str, object]) -> str:
    declared = node.get("type")
    if isinstance(declared, str):
        if declared == "array":
            items = node.get("items")
            if isinstance(items, Mapping):
                item_type = items.get("type")
                if isinstance(item_type, str):
                    return f"array<{item_type}>"
                if "oneOf" in items:
                    return "array<variant>"
        return declared
    if "const" in node:
        value = node["const"]
        return {
            bool: "boolean",
            int: "integer",
            float: "number",
            str: "string",
            type(None): "null",
        }.get(type(value), "any")
    if "enum" in node:
        return "enum"
    if "oneOf" in node:
        return "variant"
    return "any"


def _constraint_parts(node: Mapping[str, object]) -> list[str]:
    parts: list[str] = []
    if "const" in node:
        parts.append(f"constant: `{_json_literal(node['const'])}`")
    if "enum" in node:
        values = _sequence(node["enum"], "/enum")
        parts.append(
            "allowed: " + ", ".join(f"`{_json_literal(value)}`" for value in values)
        )
    labels = {
        "minLength": "minimum length",
        "maxLength": "maximum length",
        "minimum": "minimum",
        "maximum": "maximum",
        "minItems": "minimum items",
        "maxItems": "maximum items",
    }
    for key, label in labels.items():
        if key in node:
            parts.append(f"{label}: `{node[key]}`")
    if node.get("uniqueItems") is True:
        parts.append("items must be unique")
    if "pattern" in node:
        parts.append(f"pattern: `{node['pattern']}`")
    items = node.get("items")
    if isinstance(items, Mapping):
        parts.append(f"item type: `{_type_label(items)}`")
        parts.extend(f"item {constraint}" for constraint in _constraint_parts(items))
    if node.get("additionalProperties") is False:
        parts.append("unknown fields rejected")
    return parts


def _cell(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def _required_names(node: Mapping[str, object], path: str) -> set[str]:
    raw_required = node.get("required", [])
    return {
        _non_empty_string(value, f"{path}/required")
        for value in _sequence(raw_required, f"{path}/required")
    }


def _field_table(node: Mapping[str, object], path: str) -> list[str]:
    lines = [
        "| Field | Required | Type | Constraints | Description |",
        "| --- | --- | --- | --- | --- |",
    ]
    required = _required_names(node, path)
    for name, raw_child in _properties(node, path).items():
        child = _object(raw_child, _pointer(path, name))
        constraints = "; ".join(_constraint_parts(child)) or "—"
        description = _non_empty_string(
            child.get("description"),
            f"{_pointer(path, name)}/description",
        )
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{_cell(_pointer(path, name))}`",
                    "yes" if name in required else "no",
                    f"`{_cell(_type_label(child))}`",
                    _cell(constraints),
                    _cell(description),
                ]
            )
            + " |"
        )
    return lines


def _variant_name(node: Mapping[str, object], index: int) -> str:
    properties = node.get("properties")
    if isinstance(properties, Mapping):
        kind = properties.get("kind")
        if isinstance(kind, Mapping) and "const" in kind:
            return f"kind = {_json_literal(kind['const'])}"
    return f"alternative {index + 1}"


def _collect_sections(
    node: Mapping[str, object],
    path: str,
    heading: str,
) -> list[tuple[str, str, Mapping[str, object]]]:
    sections: list[tuple[str, str, Mapping[str, object]]] = []
    if "properties" in node:
        sections.append((heading, path, node))
    for name, raw_child in _properties(node, path).items():
        child_path = _pointer(path, name)
        child = _object(raw_child, child_path)
        if "properties" in child:
            sections.extend(
                _collect_sections(child, child_path, f"Object `{child_path}`")
            )
        if child.get("type") != "array" or "items" not in child:
            continue
        items = _object(child["items"], f"{child_path}/*")
        item_path = f"{child_path}/*"
        if "properties" in items:
            sections.extend(
                _collect_sections(items, item_path, f"Array item `{item_path}`")
            )
        alternatives = items.get("oneOf")
        if alternatives is None:
            continue
        for index, raw_alternative in enumerate(
            _sequence(alternatives, f"{item_path}/oneOf")
        ):
            alternative = _object(raw_alternative, f"{item_path}/oneOf/{index}")
            variant = _variant_name(alternative, index)
            sections.extend(
                _collect_sections(
                    alternative,
                    item_path,
                    f"Variant `{item_path}` — {variant}",
                )
            )
    return sections


def _described_alternatives(node: Mapping[str, object]) -> list[str]:
    raw_alternatives = node.get("oneOf")
    if raw_alternatives is None:
        return []
    descriptions: list[str] = []
    for index, raw_alternative in enumerate(
        _sequence(raw_alternatives, "/oneOf")
    ):
        alternative = _object(raw_alternative, f"/oneOf/{index}")
        descriptions.append(
            _non_empty_string(
                alternative.get("description"),
                f"/oneOf/{index}/description",
            )
        )
    return descriptions


def generate_document(schema: Mapping[str, object]) -> str:
    _validate_annotations(schema)
    title = _non_empty_string(schema.get("title"), "/title")
    description = _non_empty_string(schema.get("description"), "/description")
    schema_id = _non_empty_string(schema.get("$id"), "/$id")
    dialect = _non_empty_string(schema.get("$schema"), "/$schema")
    schema_version = _object(
        _properties(schema, "/").get("schemaVersion"),
        "/schemaVersion",
    ).get("const")

    lines = [
        "<!-- Generated by scripts/generate_profile_schema_docs.py. -->",
        "<!-- Edit packages/konyak_cli/profiles/profile.schema.json instead. -->",
        "",
        f"# {title}",
        "",
        description,
        "",
        "> This reference is generated from the runtime JSON Schema. Do not edit it by hand.",
        "",
        f"- Schema version: `{_json_literal(schema_version)}`",
        f"- Canonical schema: <{schema_id}>",
        f"- JSON Schema dialect: <{dialect}>",
        "",
    ]

    for heading, path, node in _collect_sections(schema, "/", "Root object"):
        lines.extend([f"## {heading}", ""])
        node_description = node.get("description")
        if isinstance(node_description, str) and path != "/":
            lines.extend([node_description, ""])
        lines.extend(_field_table(node, path))
        lines.append("")
        alternatives = _described_alternatives(node)
        if alternatives:
            lines.extend(["Additional alternatives:", ""])
            lines.extend(f"- {description}" for description in alternatives)
            lines.append("")

    conditionals = schema.get("allOf")
    if conditionals is not None:
        lines.extend(["## Conditional constraints", ""])
        for raw_rule in _sequence(conditionals, "/allOf"):
            rule = _object(raw_rule, "/allOf")
            lines.append(
                "- "
                + _non_empty_string(
                    rule.get("description"),
                    "/allOf/description",
                )
            )
        lines.append("")

    rules = _semantic_rules(schema)
    lines.extend(
        [
            "## Additional semantic validation",
            "",
            "These rules are enforced after JSON Schema validation by Konyak's Dart domain model.",
            "",
            "| Rule ID | Instance path | Description |",
            "| --- | --- | --- |",
        ]
    )
    for rule in rules:
        lines.append(
            "| "
            + " | ".join(
                [
                    f"`{_cell(str(rule['id']))}`",
                    f"`{_cell(str(rule['path']))}`",
                    _cell(str(rule["description"])),
                ]
            )
            + " |"
        )
    lines.append("")
    return "\n".join(lines)


def _read_schema(path: Path) -> Mapping[str, object]:
    try:
        decoded = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise DocumentationError(
            f"Could not read profile schema {path}: {error}"
        ) from error
    return _object(decoded, "/")


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generate the Konyak compatibility-profile schema reference."
    )
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA_PATH)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT_PATH)
    parser.add_argument("--check", action="store_true")
    return parser


def main(arguments: Sequence[str] | None = None) -> int:
    options = _parser().parse_args(arguments)
    try:
        generated = generate_document(_read_schema(options.schema))
        if options.check:
            try:
                current = options.output.read_text(encoding="utf-8")
            except (OSError, UnicodeError):
                current = ""
            if current != generated:
                print(
                    "Profile schema documentation is stale. Run: "
                    "just generate-profile-schema-docs",
                    file=sys.stderr,
                )
                return 1
            return 0
        options.output.parent.mkdir(parents=True, exist_ok=True)
        options.output.write_text(generated, encoding="utf-8")
        return 0
    except DocumentationError as error:
        print(f"profile schema documentation error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
