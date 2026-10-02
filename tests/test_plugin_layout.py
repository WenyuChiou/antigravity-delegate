import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _git_mode(path: str) -> str:
    result = subprocess.run(
        ["git", "ls-files", "--stage", "--", path],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.split()[0]


def test_claude_plugin_manifest_and_skill_layout_are_installable():
    manifest = json.loads((ROOT / ".claude-plugin" / "plugin.json").read_text(encoding="utf-8"))
    skill_path = ROOT / "skills" / "antigravity-delegate" / "SKILL.md"
    installed_wrapper = ROOT / "skills" / "antigravity-delegate" / "scripts" / "run_agy.sh"

    assert manifest["name"] == "antigravity-delegate"
    assert manifest["version"] == "0.1.1"
    assert skill_path.is_file()
    assert skill_path.read_bytes() == (ROOT / "SKILL.md").read_bytes()
    assert installed_wrapper.is_file()
    assert installed_wrapper.read_bytes() == (ROOT / "scripts" / "run_agy.sh").read_bytes()
    assert _git_mode("scripts/run_agy.sh") == "100755"
    assert _git_mode("skills/antigravity-delegate/scripts/run_agy.sh") == "100755"


def test_native_antigravity_marker_schema_and_skill_discovery():
    """Offline contract from Google's Plugins schema, checked 2026-10-02.

    This checks the documented required marker and skills topology; it does
    not claim native host loading or execute/install the absent agy runtime.
    Schema: https://antigravity.google/docs/plugins/#full-json-schema
    """
    import re

    native = json.loads((ROOT / "plugin.json").read_text(encoding="utf-8"))
    claude = json.loads((ROOT / ".claude-plugin/plugin.json").read_text(encoding="utf-8"))
    assert set(native) <= {"name", "description"}  # additionalProperties: false
    assert isinstance(native.get("name"), str)  # required string
    assert re.fullmatch(r"[a-zA-Z0-9_-]+", native["name"])
    assert isinstance(native.get("description", ""), str)
    assert native["name"] == claude["name"]
    discovered = sorted((ROOT / "skills").glob("*/SKILL.md"))
    assert [path.parent.name for path in discovered] == [native["name"]]
    assert (discovered[0].parent / "scripts/run_agy.sh").is_file()
    assert not any((ROOT / name).exists() for name in ["mcp_config.json", "hooks.json"])
