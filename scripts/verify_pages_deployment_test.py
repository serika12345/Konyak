#!/usr/bin/env python3
import unittest

import verify_pages_deployment as deployment


RUNTIME_SCHEMA = b'{"schemaVersion":1}\n'


class VerifyPagesDeploymentTest(unittest.TestCase):
    def test_verifies_every_public_url_and_raw_schema_bytes(self):
        responses = _valid_responses()
        requested = []

        def fetch(url):
            requested.append(url)
            return responses[url]

        deployment.verify_deployment(
            "https://example.test/Konyak/",
            RUNTIME_SCHEMA,
            fetch,
        )

        self.assertEqual(set(requested), set(responses))

    def test_rejects_a_route_without_its_expected_content(self):
        responses = _valid_responses()
        responses["https://example.test/Konyak/docs/profiles/"] = b"wrong page"

        with self.assertRaisesRegex(
            deployment.PagesDeploymentError,
            "Author a compatibility profile",
        ):
            deployment.verify_deployment(
                "https://example.test/Konyak/",
                RUNTIME_SCHEMA,
                responses.__getitem__,
            )

    def test_rejects_a_deployed_schema_that_is_not_byte_identical(self):
        responses = _valid_responses()
        responses[
            "https://example.test/Konyak/schemas/profile-v1.schema.json"
        ] += b" "

        with self.assertRaisesRegex(
            deployment.PagesDeploymentError,
            "byte-identical",
        ):
            deployment.verify_deployment(
                "https://example.test/Konyak/",
                RUNTIME_SCHEMA,
                responses.__getitem__,
            )


def _valid_responses():
    return {
        "https://example.test/Konyak/": b"<title>Konyak - Wine and Proton bottle management</title>",
        "https://example.test/Konyak/docs/": b"<h1>Konyak documentation</h1>",
        "https://example.test/Konyak/docs/profiles/": b"<h1>Author a compatibility profile</h1>",
        "https://example.test/Konyak/docs/profiles/schema-v1/": b"<h1>Konyak compatibility profile</h1>",
        "https://example.test/Konyak/schemas/profile-v1.schema.json": RUNTIME_SCHEMA,
    }


if __name__ == "__main__":
    unittest.main()
