"""Contract tests for first-time exploration milestone coin rewards."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
ROADMAP = (ROOT / "ROADMAP.md").read_text(encoding="utf-8")
STUDIO = (ROOT / "docs" / "STUDIO_PLAYTEST.md").read_text(encoding="utf-8")


class ExplorationDiscoveryRewardTests(unittest.TestCase):
    def test_milestone_reward_catalog_is_bounded_and_explicit(self):
        expected = {
            "MoonGateTrace": 3,
            "MoonGateOpen": 5,
            "MoonRelic": 6,
            "CrystalGrottoDiscovered": 8,
            "CrystalHeart": 8,
            "CrystalRunes": 5,
            "CrystalCache": 10,
            "CrystalEchoDiscovered": 8,
            "PrismSeedFound": 15,
        }
        start = WORLD.index("local explorationMilestoneCoins = {")
        end = WORLD.index("\n}", start)
        catalog = WORLD[start:end]
        for milestone, amount in expected.items():
            self.assertIn(f"{milestone} = {amount}", catalog)

    def test_reward_helper_updates_shared_wallet_and_respects_cap(self):
        start = WORLD.index("local function grantExplorationCoins")
        end = WORLD.index("\nend", start)
        helper = WORLD[start:end]
        self.assertIn("local session = sessions[player]", helper)
        self.assertIn('player:GetAttribute("Ready")', helper)
        self.assertIn("MAX_COINS - previousCoins", helper)
        self.assertIn("session.coins = previousCoins + credited", helper)
        self.assertIn("syncFarm(player)", helper)
        self.assertIn("return credited", helper)

    def test_every_discovery_is_wired_to_its_existing_progress_flag(self):
        milestones = [
            "MoonGateTrace", "MoonGateOpen", "MoonRelic",
            "CrystalGrottoDiscovered", "CrystalHeart", "CrystalRunes",
            "CrystalCache", "CrystalEchoDiscovered", "PrismSeedFound",
        ]
        for milestone in milestones:
            self.assertIn(f'player:SetAttribute("{milestone}", true)', WORLD)
            self.assertIn(f'grantExplorationCoins(player, "{milestone}")', WORLD)

    def test_each_reward_is_gated_by_the_preexisting_discovery_flag(self):
        milestones = [
            "MoonGateTrace", "MoonGateOpen", "MoonRelic",
            "CrystalGrottoDiscovered", "CrystalHeart", "CrystalRunes",
            "CrystalCache", "CrystalEchoDiscovered", "PrismSeedFound",
        ]
        for milestone in milestones:
            self.assertIn(
                f'local firstDiscovery = player:GetAttribute("{milestone}") ~= true',
                WORLD,
            )
            self.assertIn(
                f'local coinBonus = firstDiscovery and grantExplorationCoins(player, "{milestone}") or 0',
                WORLD,
            )

    def test_existing_repeat_guards_remain_in_place(self):
        guards = [
            'if player:GetAttribute("MoonGateTrace") then',
            'if player:GetAttribute("MoonGateOpen") then',
            'if player:GetAttribute("MoonRelic") then',
            'if player:GetAttribute("CrystalHeart") then',
            'if player:GetAttribute("CrystalCache") then',
            'if player:GetAttribute("PrismSeedFound") then',
        ]
        for guard in guards:
            self.assertIn(guard, WORLD)
        self.assertIn("if not player:GetAttribute(\"CrystalRunes\") then", WORLD)

    def test_rewards_do_not_replace_existing_item_rewards(self):
        for item in [
            "session.inventory.StarShard = (session.inventory.StarShard or 0) + 1",
            "session.inventory.CrystalShard = (session.inventory.CrystalShard or 0) + 1",
            "session.inventory.CrystalSigil = (session.inventory.CrystalSigil or 0) + 1",
            "session.inventory.PrismSeed = (session.inventory.PrismSeed or 0) + 1",
        ]:
            self.assertIn(item, WORLD)

    def test_manual_acceptance_is_documented(self):
        self.assertIn("## Разовые награды за исследование", ROADMAP)
        self.assertIn("## Разовые награды за исследование", STUDIO)
        self.assertIn("Повторные взаимодействия после респавна/перезахода", STUDIO)


if __name__ == "__main__":
    unittest.main()
