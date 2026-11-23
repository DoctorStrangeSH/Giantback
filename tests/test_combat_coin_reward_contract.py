"""One-time combat rewards grant persistent, bounded Coins alongside items."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


class CombatCoinRewardContractTests(unittest.TestCase):
    def test_all_combat_encounters_have_small_one_time_coin_rewards(self):
        expected = {
            "GroveGrunt01": 2,
            "GroveScout02": 3,
            "GroveMossling01": 3,
            "GroveTrialChest01": 8,
            "RootvaultChest01": 10,
            "RootvaultSentinel01": 12,
            "RootvaultStalker01": 14,
            "RootvaultSealKeeper01": 25,
        }
        for encounter_id, coins in expected.items():
            start = WORLD.index(f'{encounter_id} = {{')
            end = WORLD.index("}", start)
            self.assertIn(f"coins = {coins}", WORLD[start:end])

    def test_reward_is_bounded_by_wallet_cap(self):
        self.assertIn(
            "local coinReward = math.clamp(math.floor(tonumber(reward.coins) or 0), 0, MAX_COINS - previousCoins)",
            WORLD,
        )
        self.assertIn("session.coins = previousCoins + coinReward", WORLD)

    def test_rewards_are_idempotent_and_saved_with_existing_encounter_flag(self):
        self.assertIn("if session.completedCombatEncounters[encounterId] then return true end", WORLD)
        self.assertIn("session.completedCombatEncounters[encounterId] = true", WORLD)
        self.assertIn("old.completedCombatEncounters = savedCombatEncounters", WORLD)
        self.assertIn("old.coins = coinSnapshot", WORLD)

    def test_failed_save_rolls_back_item_coins_and_encounter_flag(self):
        start = WORLD.index("combatRewardFunction.OnInvoke = function")
        end = WORLD.index("local function collectFoxCache", start)
        handler = WORLD[start:end]
        self.assertIn("if session.online and not save(player) then", handler)
        self.assertIn("session.completedCombatEncounters[encounterId] = nil", handler)
        self.assertIn("session.inventory[reward.itemId] = math.max(0,", handler)
        self.assertIn("session.coins = previousCoins", handler)
        self.assertIn("syncInventory(player)", handler)
        self.assertIn("syncFarm(player)", handler)

    def test_wallet_updates_and_player_message_include_coin_reward(self):
        start = WORLD.index("combatRewardFunction.OnInvoke = function")
        end = WORLD.index("local function collectFoxCache", start)
        handler = WORLD[start:end]
        self.assertIn("syncFarm(player)", handler)
        self.assertIn('tostring(coinReward) .. " мон."', handler)


if __name__ == "__main__":
    unittest.main()
