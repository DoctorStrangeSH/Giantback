"""Moth stardust is attached, refreshed and deduplicated in one client module."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
STARDUST = (ROOT / "modules/MothStardust.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class MothStardustModuleTests(unittest.TestCase):
    def test_build_and_client_connect_module(self):
        self.assertIn('moth_stardust = obj(storage, "ModuleScript", "MothStardust")', BUILD)
        self.assertIn('require(storage:WaitForChild("MothStardust"))', CLIENT)
        self.assertIn('MothStardust.new(player, palette)', CLIENT)
        self.assertIn('attachMothStardust(model)', CLIENT)
        self.assertIn('updateMothStardust(model, owner)', CLIENT)

    def test_emitter_lookup_matches_actual_parent(self):
        self.assertIn('attachment.Name = "CompanionStardustAttachment"', STARDUST)
        self.assertIn('emitter.Parent = attachment', STARDUST)
        self.assertIn('glow:FindFirstChild("CompanionStardustAttachment")', STARDUST)
        self.assertIn('attachment:FindFirstChild("CompanionStardust")', STARDUST)
        self.assertNotIn('glow:FindFirstChild("CompanionStardust")', STARDUST)

    def test_all_lunar_palette_keys_exist(self):
        self.assertIn('lilacLight = Color3.fromRGB(', CLIENT)
        self.assertIn('moon = Color3.fromRGB(', CLIENT)
        self.assertIn('ColorSequence.new(palette.lilacLight, palette.moon)', STARDUST)

    def test_personality_and_bond_refresh_and_no_server_authority(self):
        self.assertIn('emitter:GetAttribute("AppliedBondStage") == bondStage', STARDUST)
        self.assertIn('emitter:GetAttribute("AppliedPersonality") == (personality or "")', STARDUST)
        self.assertIn('emitter.Rate = mothStardustRate(personality, bondStage)', STARDUST)
        for marker in ('FireServer(', 'InvokeServer(', 'DataStoreService'):
            self.assertNotIn(marker, STARDUST)


if __name__ == "__main__":
    unittest.main()
