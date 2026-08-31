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
    assert manifest["version"] == "0.1.0"
    assert skill_path.is_file()
    assert skill_path.read_bytes() == (ROOT / "SKILL.md").read_bytes()
    assert installed_wrapper.is_file()
    assert installed_wrapper.read_bytes() == (ROOT / "scripts" / "run_agy.sh").read_bytes()
    assert _git_mode("scripts/run_agy.sh") == "100755"
    assert _git_mode("skills/antigravity-delegate/scripts/run_agy.sh") == "100755"
