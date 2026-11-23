"""Transactional acceptance tests for sword crafting and tool upgrades."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")


def action_block(action, next_action):
    start = WORLD.index(f'if action == "{action}" then')
    end = WORLD.index(f'if action == "{next_action}" then', start)
    return WORLD[start:end]


class AtomicToolEconomyTests(unittest.TestCase):
    def test_sword_crafting_requires_online_profile_and_workshop(self):
        block = action_block("CraftSword", "UpgradeTool")
        self.assertIn('not player:GetAttribute("Ready")', block)
        self.assertIn("if not session.online then", block)
        self.assertIn("if session.economyBusy then return end", block)
        self.assertIn('FindFirstChild("Workshop")', block)
        self.assertIn('FindFirstChild("PromptAnchor")', block)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 14', block)

    def test_sword_crafting_rolls_back_every_mutated_value(self):
        block = action_block("CraftSword", "UpgradeTool")
        save_failure = block.index("if not save(player) then")
        self.assertLess(save_failure, block.index('addDailyQuestProgress(player, "CraftSword", 1)'))
        for fragment in (
            "session.inventory.IronIngot = previousIngots",
            "session.inventory.Wood = previousWood",
            "session.tools.Sword = false",
            "session.equippedTool = previousEquipped",
            "syncInventory(player)",
            "syncTools(player)",
            "session.economyBusy = false",
        ):
            self.assertIn(fragment, block)

    def test_tool_upgrade_rolls_back_materials_and_level(self):
        block = action_block("UpgradeTool", "EquipTool")
        self.assertIn("if not session.online then", block)
        self.assertIn("if session.economyBusy then return end", block)
        self.assertIn("local previousLevel =", block)
        self.assertIn("if not save(player) then", block)
        for fragment in (
            "session.inventory.Wood = previousWood",
            "session.inventory.Stone = previousStone",
            "session.toolLevels[payload] = previousLevel",
            "addDailyQuestProgress(player, " + '"UpgradeTool", 1)',
        ):
            self.assertIn(fragment, block)
        self.assertLess(block.index("if not save(player) then"), block.index('addDailyQuestProgress(player, "UpgradeTool", 1)'))

    def test_equipment_change_is_saved_or_reverted(self):
        block = WORLD[WORLD.index('if action == "EquipTool" then'):WORLD.index('if action == "RequestResourceState" then')]
        self.assertIn("local previousEquipped = session.equippedTool", block)
        self.assertIn("if not save(player) then", block)
        self.assertIn("session.equippedTool = previousEquipped", block)
        self.assertIn("syncTools(player)", block)

    def test_actions_never_commit_resources_when_profile_is_offline(self):
        for action, next_action in (("CraftSword", "UpgradeTool"), ("UpgradeTool", "EquipTool")):
            block = action_block(action, next_action)
            self.assertIn("if not session.online then", block)
            self.assertIn("return tip(player", block)


if __name__ == "__main__":
    unittest.main()
