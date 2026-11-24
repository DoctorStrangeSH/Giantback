"""Read-only Roblox Studio preflight must inspect the actual personal-island runtime."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PREFLIGHT = (ROOT / "tools/roblox/studio_playtest_preflight.luau").read_text(encoding="utf-8")


class StudioPlaytestPreflightContractTests(unittest.TestCase):
    def test_template_checks_cover_spawn_pivot_and_buildable_meadow(self):
        self.assertIn('child(template, "HomeSpawn", "SpawnLocation")', PREFLIGHT)
        self.assertIn('child(template, "IslandPivot", "BasePart")', PREFLIGHT)
        self.assertIn('child(template, "Meadow", "BasePart")', PREFLIGHT)

    def test_template_geometry_is_not_accepted_as_an_empty_model(self):
        self.assertIn("local templatePartCount = 0", PREFLIGHT)
        self.assertIn("if descendant:IsA(\"BasePart\") then", PREFLIGHT)
        self.assertIn("record(templatePartCount >= 8, \"Home island geometry\"", PREFLIGHT)

    def test_runtime_checks_verify_owner_city_and_meadow(self):
        self.assertIn('home:GetAttribute("OwnerUserId") == player.UserId', PREFLIGHT)
        self.assertIn('child(home, "Meadow", "BasePart")', PREFLIGHT)
        self.assertIn('child(home, "PersonalCity", "Model")', PREFLIGHT)
        self.assertIn('child(home, "HomeSpawn", "SpawnLocation")', PREFLIGHT)

    def test_runtime_checks_verify_synced_building_and_farm_state(self):
        for attribute in (
            "City_Level",
            "Farm_Level",
            "City_DecorationCount",
            "City_BuildingCells",
            "Warehouse_Capacity",
        ):
            self.assertIn(f'player:GetAttribute("{attribute}")', PREFLIGHT)

    def test_preflight_remains_read_only(self):
        self.assertIn("read-only", PREFLIGHT)
        self.assertNotIn(":SetAttribute(", PREFLIGHT)
        self.assertNotIn(":Destroy(", PREFLIGHT)
        self.assertNotIn(":FireServer(", PREFLIGHT)


if __name__ == "__main__":
    unittest.main()
