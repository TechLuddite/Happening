"""Exercise the workflow's release/tag guard with mocked GitHub API responses."""

from contextlib import redirect_stdout
import io
import json
import os
from pathlib import Path
import tempfile
import textwrap
import unittest
from unittest.mock import patch
import urllib.error

WORKFLOW = Path(__file__).resolve().parent.parent / ".github/workflows/release.yml"
SOURCE = textwrap.dedent(
    WORKFLOW.read_text().split("python3 - <<'PY'\n", 1)[1].split("          PY\n", 1)[0]
)


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.output = Path(self.directory.name) / "outputs"
        self.responses = {}

    def run_guard(self):
        def response(request, timeout):
            self.assertEqual(timeout, 30)
            result = self.responses.get(request.full_url)
            if result is None:
                raise urllib.error.HTTPError(request.full_url, 404, "missing", {}, None)
            if isinstance(result, Exception):
                raise result
            return io.BytesIO(json.dumps(result).encode())

        environment = {"GITHUB_REPOSITORY": "TechLuddite/Happening", "VERSION": "0.1.0",
                       "GH_TOKEN": "test-token", "GH_API_URL": "https://api.github.com",
                       "GITHUB_SHA": "tested-commit", "GITHUB_OUTPUT": str(self.output)}
        with patch.dict(os.environ, environment), patch("urllib.request.urlopen", side_effect=response) as api:
            with redirect_stdout(io.StringIO()):
                exec(compile(SOURCE, str(WORKFLOW), "exec"), {})
            return api.call_count

    def api_path(self, suffix):
        return "https://api.github.com/repos/TechLuddite/Happening" + suffix

    def test_new_version_can_release(self):
        self.assertEqual(self.run_guard(), 2)
        self.assertEqual(self.output.read_text(), "released=false\n")

    def test_existing_release_skips_without_examining_or_changing_tag(self):
        self.responses[self.api_path("/releases/tags/v0.1.0")] = {"tag_name": "v0.1.0"}
        self.assertEqual(self.run_guard(), 1)
        self.assertEqual(self.output.read_text(), "released=true\n")

    def test_existing_tag_at_tested_commit_can_release(self):
        self.responses[self.api_path("/git/ref/tags/v0.1.0")] = {
            "object": {"type": "commit", "sha": "tested-commit"}}
        self.run_guard()
        self.assertEqual(self.output.read_text(), "released=false\n")

    def test_annotated_tag_is_resolved(self):
        self.responses[self.api_path("/git/ref/tags/v0.1.0")] = {
            "object": {"type": "tag", "sha": "annotation"}}
        self.responses[self.api_path("/git/tags/annotation")] = {
            "object": {"type": "commit", "sha": "tested-commit"}}
        self.assertEqual(self.run_guard(), 3)
        self.assertEqual(self.output.read_text(), "released=false\n")

    def test_tag_at_another_commit_refuses_release(self):
        self.responses[self.api_path("/git/ref/tags/v0.1.0")] = {
            "object": {"type": "commit", "sha": "other-commit"}}
        with self.assertRaisesRegex(RuntimeError, "refusing to retag"):
            self.run_guard()
        self.assertFalse(self.output.exists())

    def test_api_failure_does_not_mean_new_release(self):
        url = self.api_path("/releases/tags/v0.1.0")
        self.responses[url] = urllib.error.HTTPError(url, 503, "unavailable", {}, None)
        self.addCleanup(self.responses[url].close)
        with self.assertRaises(urllib.error.HTTPError):
            self.run_guard()
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
