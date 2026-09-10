#!/usr/bin/env python3
"""Try Claudux's real section patcher without a model call or installation."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]


def run_demo(root):
    docs = root / "docs"
    docs.mkdir()
    page = docs / "guide.md"
    original = "# Pocket API\n\n## Quick start\n\nWords I wrote and want to keep.\n\n## API\n\nThe old API description.\n"
    page.write_text(original)
    manifest = {
        "version": 1,
        "deletion_policy": "manifest_pages_require_manifest_change",
        "generated_sections_default": "bounded_patch",
        "navigation": [{"id": "guide", "title": "Guide", "link": "/guide", "order": 1}],
        "pages": [{
            "id": "guide", "path": "docs/guide.md", "title": "Pocket API",
            "nav_group": "guide", "order": 1,
            "sections": [
                {"id": "quick-start", "heading": "Quick start", "level": 2, "pinned": True},
                {"id": "api", "heading": "API", "level": 2},
            ],
        }],
    }
    (root / "docs-structure.json").write_text(json.dumps(manifest))
    env = {key: value for key, value in os.environ.items() if not key.startswith("CLAUDUX_")}
    env["BASH_ENV"] = "/dev/null"

    def patch(section, body):
        proposal = root / "proposal.json"
        proposal.write_text(json.dumps({"patches": [{
            "page_id": "guide", "section_id": section, "body_markdown": body,
        }]}))
        result = subprocess.run([
            "bash", "--noprofile", "--norc", "-c",
            'source "$1"; apply_manifest_section_patches "$2"',
            "demo", str(REPO / "lib/docs-manifest.sh"), str(proposal),
        ], cwd=root, env=env, text=True, capture_output=True)
        return result

    print("Two sections: a pinned Quick start and an editable API.", flush=True)
    print("\n1. Try to overwrite the pinned section.", flush=True)
    refused = patch("quick-start", "Replace the author's words.")
    if refused.returncode == 0 or "pinned" not in (refused.stdout + refused.stderr).lower():
        raise RuntimeError("Expected a pinned-section rejection: " + refused.stdout + refused.stderr)
    if page.read_text() != original:
        raise RuntimeError("A rejected patch changed the file")
    print("   Rejected. The whole file is unchanged.", flush=True)

    print("\n2. Update the allowed API section.", flush=True)
    accepted = patch("api", "`greet(name)` returns a greeting for the supplied name.")
    if accepted.returncode:
        raise RuntimeError(accepted.stdout + accepted.stderr)
    updated = page.read_text()
    pinned_before = original.split("## API\n", 1)[0]
    pinned_after = updated.split("## API\n", 1)[0]
    if pinned_before != pinned_after or "`greet(name)`" not in updated:
        raise RuntimeError("The allowed update did not preserve the pinned text")
    print("   Applied. Quick start is byte-for-byte unchanged.", flush=True)
    print("\nDemo passed. Real patcher, supplied proposals, no model calls.", flush=True)


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="claudux-demo-") as temp:
        run_demo(Path(temp))
