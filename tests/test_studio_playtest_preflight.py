"""Studio smoke preflight stays read-only and ships in the downloadable place artifact."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHECK = (ROOT / "tools/roblox/studio_playtest_preflight.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
WORKFLOW = (ROOT / ".github/workflows/validate-place.yml").read_text(encoding="utf-8")
GUIDE = (ROOT / "docs/STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class StudioPlaytestPreflightTests(unittest.TestCase):
    def test_expected_runtime_and_starter_content(self):
        for name in ("World", "WorldVisuals", "Combat", "Album", "GiantbackHUD",
                     "CombatControls", "CompanionFollow", "CompanionAppearance", "MothStardust"):
            self.assertIn('"' + name + '"', CHECK)
        for name in ("Grove", "Dusk", "HomeIslandTemplate", "BridgeToGrove", "BridgeToDusk"):
            self.assertIn('"' + name + '"', CHECK)
        self.assertIn('obj(doc, "ServerScriptService"', BUILD)
        self.assertIn('obj(server_storage, "Model", "HomeIslandTemplate")', BUILD)

    def test_dynamic_remote_is_only_checked_in_play_mode(self):
        self.assertIn('if isRunning then\n    record(child(ReplicatedStorage, "AlbumAction", "RemoteEvent")', CHECK)
        self.assertIn('later("AlbumAction runtime remote", "Created by World script after Play begins")', CHECK)
        self.assertIn('RunService:IsRunning()', CHECK)
        self.assertIn('player:GetAttribute("Ready")', CHECK)
        self.assertIn('HomeIsland_', CHECK)

    def test_read_only_and_never_auto_approves_imports(self):
        for forbidden in (':Destroy()', ':Clone()', 'Instance.new(', ':SetAttribute(',
                          ':FireServer(', ':InvokeServer(', ':MoveTo(', '.Parent =', 'DataStoreService'):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, CHECK)
        for marker in ('GiantbackImportStatus', 'GiantbackRuntimeReady',
                       'GiantbackProceduralAnimationCompatible', 'No changes made.',
                       'PENDING', 'REVIEW', 'FAIL', 'PASS'):
            self.assertIn(marker, CHECK)

    def test_build_artifact_includes_studio_acceptance_pack(self):
        self.assertIn('docs/STUDIO_PLAYTEST.md', WORKFLOW)
        self.assertIn('tools/roblox/studio_playtest_preflight.luau', WORKFLOW)
        self.assertIn('Giantback.rbxlx', WORKFLOW)
        for marker in ('Server & Clients', 'Device Emulator', 'NOT TESTED',
                       'ASSET_IMPORT.md', 'Output'):
            self.assertIn(marker, GUIDE)


if __name__ == "__main__":
    unittest.main()
