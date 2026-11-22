from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")


class CrystalGrottoContractTests(unittest.TestCase):
    def test_grotto_is_a_real_visual_destination_with_a_return_path(self):
        self.assertIn('crystalGrotto.Name = "CrystalGrotto"', VISUALS)
        self.assertIn('"CrystalGrottoArrival"', VISUALS)
        self.assertIn('"CrystalGrottoReturn"', VISUALS)
        self.assertIn('"CrystalGrottoEntrance"', VISUALS)
        self.assertIn('crystalGrotto.Parent = combatGlade', VISUALS)

    def test_access_requires_the_persisted_moon_relic(self):
        self.assertIn('"CrystalGrottoDiscovered"', WORLD.split("local inventoryKeys")[0])
        self.assertIn('if not player:GetAttribute("MoonRelic") then', WORLD)
        self.assertIn('player:SetAttribute("CrystalGrottoDiscovered", true)', WORLD)
        self.assertIn('character:PivotTo(crystalArrival.CFrame', WORLD)

    def test_crystal_heart_is_a_single_server_granted_persistent_reward(self):
        self.assertIn('"CrystalHeart"', WORLD.split("local inventoryKeys")[0])
        self.assertIn('"CrystalShard"', WORLD.split("local toolIds")[0])
        self.assertIn('if player:GetAttribute("CrystalHeart") then', WORLD)
        self.assertIn('session.inventory.CrystalShard = (session.inventory.CrystalShard or 0) + 1', WORLD)
        self.assertIn('syncInventory(player)', WORLD)
        self.assertIn('if session.online and not save(player) then', WORLD)

    def test_grotto_prompts_reuse_visual_prompt_anchors(self):
        self.assertIn('connectTrialPrompt(crystalEntrance, function(player)', WORLD)
        self.assertIn('connectTrialPrompt(crystalReturn, function(player)', WORLD)
        self.assertIn('connectTrialPrompt(crystalHeart, function(player)', WORLD)
        self.assertNotIn('prompt(crystalEntrance,', WORLD)
        self.assertNotIn('prompt(crystalReturn,', WORLD)
        self.assertNotIn('prompt(crystalHeart,', WORLD)

    def test_lumen_crystal_deposits_use_the_existing_pickaxe_harvesting_loop(self):
        self.assertIn('CrystalGrottoLumen01 = true', WORLD)
        self.assertIn('CrystalGrottoLumen02 = true', WORLD)
        self.assertIn('key = "CrystalGrottoLumen01", amount = 1, requiredTool = "Pickaxe", hitsRequired = 6', WORLD)
        self.assertIn('key = "CrystalGrottoLumen02", amount = 1, requiredTool = "Pickaxe", hitsRequired = 6', WORLD)
        self.assertIn('itemId = "CrystalShard"', WORLD)
        self.assertIn('respawnSeconds = 900', WORLD)

    def test_grotto_resource_nodes_spawn_inside_the_cave_model(self):
        self.assertIn('if def.area == "CrystalGrotto" then', WORLD)
        self.assertIn('island = glade and glade:FindFirstChild("CrystalGrotto")', WORLD)
        self.assertIn('origin = island and island:FindFirstChild("CrystalGrottoFloor")', WORLD)
        self.assertIn('local crystalGrotto = Instance.new("Model")', VISUALS)
        self.assertIn('def.visual == "crystal"', WORLD)

    def test_crystal_mining_requires_cave_membership_and_nearby_interaction(self):
        self.assertIn('player:GetAttribute("InCrystalGrotto") ~= true', WORLD)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 13', WORLD)
        self.assertIn('session.equippedTool ~= def.requiredTool', WORLD)


    def test_expedition_journal_tracks_both_grotto_milestones(self):
        self.assertIn('{key = "CrystalGrottoDiscovered"', HUD)
        self.assertIn('{key = "CrystalHeart"', HUD)


if __name__ == "__main__":
    unittest.main()
