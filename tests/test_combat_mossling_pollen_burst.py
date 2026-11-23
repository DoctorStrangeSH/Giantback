"""Contracts for the Mossling's readable, dodgeable pollen burst."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
COMBAT = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "Combat.client.luau").read_text(encoding="utf-8")
WORLD = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")


class MosslingPollenBurstTests(unittest.TestCase):
    def test_live_mossling_has_server_tuned_pollen_attack(self):
        mossling = WORLD.split("local function spawnMossling()", 1)[1].split("end\n\nspawnMossling()", 1)[0]
        self.assertIn('mossling:SetAttribute("ArchetypeId", "Mossling")', mossling)
        self.assertIn('mossling:SetAttribute("PollenRadius", 9)', mossling)
        self.assertIn('mossling:SetAttribute("PollenDamage", 8)', mossling)
        self.assertIn('mossling:SetAttribute("TelegraphSeconds", 1.15)', mossling)
        self.assertIn('state == "Telegraph" or state == "PollenTelegraph"', WORLD)
        self.assertIn('telegraphing and "УКЛОНЯЙСЯ!" or "АТАКА!"', WORLD)

    def test_pollen_burst_is_an_alternating_mossling_only_attack(self):
        self.assertIn('local usePollenBurst = enemy:GetAttribute("ArchetypeId") == "Mossling"', COMBAT)
        self.assertIn("and entry.attackSequence % 2 == 0", COMBAT)
        self.assertIn('elseif usePollenBurst then', COMBAT)
        self.assertIn('enemy:SetAttribute("BossAttack", "PollenBurst")', COMBAT)
        self.assertIn('enemy:SetAttribute("CombatState", "PollenTelegraph")', COMBAT)

    def test_damage_is_server_bounded_and_applied_only_inside_region_radius(self):
        self.assertIn('math.clamp(tonumber(enemy:GetAttribute("PollenRadius")) or 9, 6, 14)', COMBAT)
        self.assertIn('math.clamp(math.floor(tonumber(enemy:GetAttribute("PollenDamage")) or 8), 1, 16)', COMBAT)
        self.assertIn('getPlayerRegion(player) == entry.regionId', COMBAT)
        self.assertIn('(currentRoot.Position - root.Position).Magnitude <= pollenRadius', COMBAT)
        self.assertIn('currentHumanoid:TakeDamage(damage)', COMBAT)

    def test_dodge_and_directional_block_are_respected(self):
        branch = COMBAT.split('elseif usePollenBurst then', 1)[1].split('\n                    else\n                        enemy:SetAttribute("CombatState", "Telegraph")', 1)[0]
        self.assertIn('local dodging = playerState and playerState.dodgingUntil > os.clock()', branch)
        self.assertIn('if not dodging then', branch)
        self.assertIn('playerState.blocking', branch)
        self.assertIn('BLOCK_DAMAGE_MULTIPLIER', branch)
        self.assertIn('currentRoot.CFrame.LookVector:Dot(towardMossling.Unit) >= 0.35', branch)

    def test_client_shows_a_local_green_radius_warning(self):
        self.assertIn('local function showMosslingPollenTelegraph(enemy)', CLIENT)
        self.assertIn('marker.Name = "LocalMosslingPollenTelegraph"', CLIENT)
        self.assertIn('Color3.fromRGB(155, 222, 112)', CLIENT)
        self.assertIn('showMosslingPollenTelegraph(enemy)', CLIENT)
        self.assertIn('attack == "PollenBurst" and isMossling', CLIENT)
        self.assertIn('state == "Telegraph" or state == "PollenTelegraph"', CLIENT)


if __name__ == "__main__":
    unittest.main()
