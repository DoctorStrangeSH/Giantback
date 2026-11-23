"""Contract coverage for the craftable Wanderer's Sword in the live place."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
COMBAT = (ROOT / "Combat.server.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class WandererSwordContract(unittest.TestCase):
    def test_crafting_is_server_authoritative_and_owned_workshop_only(self):
        craft = WORLD.split('if action == "CraftSword" then', 1)[1].split('if action == "UpgradeTool" then', 1)[0]
        self.assertIn('local swordRecipe = {IronIngot = 2, Wood = 6}', WORLD)
        self.assertIn('session.tools.Sword == true', craft)
        self.assertIn('session.homeIsland', craft)
        self.assertIn('FindFirstChild("Workshop")', craft)
        self.assertIn('FindFirstChild("PromptAnchor")', craft)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 14', craft)
        self.assertIn('session.inventory.IronIngot or 0', craft)
        self.assertIn('session.inventory.Wood or 0', craft)
        self.assertIn('session.inventory.IronIngot -= swordRecipe.IronIngot', craft)
        self.assertIn('session.inventory.Wood -= swordRecipe.Wood', craft)
        self.assertIn('session.tools.Sword = true', craft)
        self.assertIn('syncTools(player)', craft)
        self.assertIn('if session.online then save(player) end', craft)

    def test_owned_sword_survives_profile_reload_without_schema_downgrade(self):
        self.assertIn('tools = {Axe = true, Pickaxe = true, Sword = false}', WORLD)
        self.assertIn('savedTools.Sword = savedTools.Sword == true or toolsSnapshot.Sword', WORLD)
        self.assertIn('Sword = savedTools.Sword == true', WORLD)
        self.assertIn('equipped = toolIds[session.equippedTool] and session.equippedTool or "Axe"', WORLD)
        self.assertIn('session.equippedTool = toolIds[savedEquippedTool]', WORLD)
        self.assertIn('math.max(tonumber(old.schemaVersion) or 0, 13)', WORLD)

    def test_live_gear_and_ui(self):
        self.assertIn('local toolIds = {Axe = true, Pickaxe = true, Sword = true}', WORLD)
        self.assertIn('toolId == "Sword" and "Меч странника"', WORLD)
        self.assertIn('createToolPart(tool, "SwordBlade"', WORLD)
        self.assertIn('player:SetAttribute("Tool_SwordOwned", tools.Sword == true)', WORLD)
        self.assertIn('event:FireServer("CraftSword")', HUD)
        self.assertIn('event:FireServer("EquipTool", "Sword")', HUD)
        self.assertIn('player:GetAttribute("Tool_SwordOwned") == true', HUD)
        self.assertIn('local function renderTools()', HUD)
        self.assertIn('ALLOWED_WEAPONS = { SwordShield = true }', COMBAT)
        self.assertIn('"World.server.luau", "WorldVisuals.server.luau", "Combat.server.luau"', BUILD)


if __name__ == "__main__":
    unittest.main()
