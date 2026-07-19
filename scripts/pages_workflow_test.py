#!/usr/bin/env python3
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "pages.yml"


class PagesWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_pull_requests_build_but_only_main_can_deploy(self):
        self.assertIn("  pull_request:\n", self.workflow)
        self.assertIn("  push:\n    branches:\n      - main\n", self.workflow)

        build = _job(self.workflow, "build")
        self.assertIn("permissions:\n      contents: read", build)
        self.assertNotIn("pages: write", build)
        self.assertNotIn("id-token: write", build)

        deploy = _job(self.workflow, "deploy")
        self.assertIn("needs: build", deploy)
        self.assertIn("github.ref == 'refs/heads/main'", deploy)
        self.assertIn("github.event_name != 'pull_request'", deploy)
        self.assertIn("pages: write", deploy)
        self.assertIn("id-token: write", deploy)

    def test_build_uses_the_local_nix_just_contract_and_curated_artifact(self):
        build = _job(self.workflow, "build")
        self.assertIn("actions/checkout@v7", build)
        self.assertIn("cachix/install-nix-action@v31", build)
        self.assertIn("just pages-check", build)
        self.assertIn("actions/upload-pages-artifact@v5", build)
        self.assertIn("path: build/pages", build)
        self.assertNotIn("path: docs", build)

    def test_deploys_the_exact_build_artifact_with_current_actions(self):
        build = _job(self.workflow, "build")
        deploy = _job(self.workflow, "deploy")
        self.assertIn("PAGES_ARTIFACT_NAME", build)
        self.assertIn("artifact_name: ${{ needs.build.outputs.artifact_name }}", deploy)
        self.assertIn("actions/deploy-pages@v5", deploy)

    def test_post_deploy_job_verifies_the_public_url_contract(self):
        verify = _job(self.workflow, "verify-deployment")
        self.assertIn("needs: deploy", verify)
        self.assertIn("actions/checkout@v7", verify)
        self.assertIn("cachix/install-nix-action@v31", verify)
        self.assertIn("just pages-url-check", verify)
        self.assertIn("needs.deploy.outputs.page_url", verify)


def _job(workflow: str, name: str) -> str:
    marker = f"  {name}:\n"
    try:
        start = workflow.index(marker) + len(marker)
    except ValueError as error:
        raise AssertionError(f"workflow job is missing: {name}") from error
    tail = workflow[start:]
    next_job = re.search(r"(?m)^  [a-zA-Z0-9_-]+:\n", tail)
    return tail[: next_job.start()] if next_job else tail


if __name__ == "__main__":
    unittest.main()
