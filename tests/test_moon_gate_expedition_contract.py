from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")


class MoonGateExpeditionContractTests(unittest.TestCase):
    def test_dusk_builds_three_hidden_queryable_noncollidable_anchors(self):
        for anchor in ("MoonGateTracks", "MoonGateRune", "MoonRelic"):
            self.assertIn(f'("{anchor}",', BUILD)
        self.assertIn('prop(anchor, "float", "Transparency", "1")', BUILD)
        self.assertIn('prop(anchor, "bool", "CanCollide", "false")', BUILD)
        self.assertIn('prop(anchor, "bool", "CanTouch", "false")', BUILD)
        self.assertIn('prop(anchor, "bool", "CanQuery", "true")', BUILD)

    def test_gate_progress_is_persisted_in_the_existing_progress_pipeline(self):
        self.assertIn('"MoonGateTrace", "MoonGateOpen", "MoonRelic"', WORLD)
        self.assertIn("for _, key in progress do snapshot[key] = player:GetAttribute(key) == true end", WORLD)
        self.assertIn("old[key] = old[key] == true or snapshot[key]", WORLD)

    def test_star_shard_uses_the_existing_inventory_pipeline(self):
        self.assertIn('"StarShard"', WORLD)
        self.assertIn('session.inventory.StarShard = (session.inventory.StarShard or 0) + 1', WORLD)
        self.assertIn('player:SetAttribute("Resource_" .. key, amount)', WORLD)
        self.assertIn("syncInventory(player)", WORLD)

    def test_fox_must_be_owned_equipped_and_near_the_tracks(self):
        self.assertIn('if not player:GetAttribute("Fox") or player:GetAttribute("Companion") ~= "Fox" then', WORLD)
        self.assertIn('local anchor = dusk and dusk:FindFirstChild("MoonGateTracks")', WORLD)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 10', WORLD)
        self.assertIn('player:SetAttribute("MoonGateTrace", true)', WORLD)
        self.assertIn('if action == "SearchMoonGate" then', WORLD)

    def test_moth_requires_the_fox_trace_and_must_be_equipped_at_the_runes(self):
        self.assertIn('if not player:GetAttribute("MoonGateTrace") then', WORLD)
        self.assertIn('if not player:GetAttribute("Moth") or player:GetAttribute("Companion") ~= "Moth" then', WORLD)
        self.assertIn('local anchor = dusk and dusk:FindFirstChild("MoonGateRune")', WORLD)
        self.assertIn('player:SetAttribute("MoonGateOpen", true)', WORLD)
        self.assertIn('if action == "RevealMoonGate" then', WORLD)

    def test_relic_requires_the_personal_open_gate_and_cannot_be_claimed_twice(self):
        self.assertIn('if not player:GetAttribute("MoonGateOpen") then', WORLD)
        self.assertIn('if player:GetAttribute("MoonRelic") then', WORLD)
        self.assertIn('local anchor = dusk and dusk:FindFirstChild("MoonRelic")', WORLD)
        self.assertIn('(root.Position - anchor.Position).Magnitude > 10', WORLD)
        self.assertIn('player:SetAttribute("MoonRelic", true)', WORLD)
        self.assertIn('if action == "CollectMoonRelic" then', WORLD)

    def test_gate_visuals_include_roots_seal_runes_and_a_secret_clearing(self):
        for marker in (
            'moonGateVisuals = makeFolder(dusk, "MoonGateVisuals")',
            'tracks.Name = "MoonGateTracksVisual"',
            'gateShell.Name = "MoonGateShell"',
            'seal.Name = "MoonGateSeal"',
            'runes.Name = "MoonGateRunesVisual"',
            'clearing.Name = "MoonGateClearingVisual"',
            '"Old tree root"',
            '"Awakening rune"',
            '"MoonRelicGem"',
        ):
            self.assertIn(marker, VISUALS)

    def test_fox_tracks_are_drawn_with_oriented_pawprints_and_motes(self):
        self.assertIn('makePart(tracks, "Fox paw pad"', VISUALS)
        self.assertIn('makePart(tracks, "Fox paw toe"', VISUALS)
        self.assertIn('"Scent mote"', VISUALS)
        self.assertNotIn('orb(tracks, "Fox paw pad"', VISUALS)

    def test_client_reveals_the_gate_only_for_personal_progress(self):
        self.assertIn("local function updateMoonGatePuzzle()", ALBUM)
        self.assertIn("foxEquipped or traceFound", ALBUM)
        self.assertIn("gateOpen or (traceFound and mothEquipped)", ALBUM)
        self.assertIn("setLocalModelVisibility(sealVisual, not gateOpen)", ALBUM)
        self.assertIn("setLocalModelVisibility(clearingVisual, gateOpen)", ALBUM)

    def test_local_prompts_are_gated_by_the_correct_companion_and_progress(self):
        self.assertIn('"SearchMoonGate"', ALBUM)
        self.assertIn('"RevealMoonGate"', ALBUM)
        self.assertIn('"CollectMoonRelic"', ALBUM)
        self.assertIn("foxEquipped and not traceFound", ALBUM)
        self.assertIn("traceFound and mothEquipped and not gateOpen", ALBUM)
        self.assertIn("gateOpen and not relicCollected", ALBUM)

    def test_relic_visual_disappears_only_after_the_player_claims_it(self):
        self.assertIn('descendant.Name == "MoonRelicGem"', ALBUM)
        self.assertIn("descendant.LocalTransparencyModifier = relicCollected and 1 or 0", ALBUM)

    def test_star_shard_is_visible_in_the_collection_resource_panel(self):
        self.assertIn('"Звёздный осколок"', ALBUM)
        self.assertIn("Resource_StarShard", ALBUM)
        self.assertIn("starShardCount.Text", ALBUM)

    def test_expedition_route_requires_fox_then_moth_then_relic_before_the_home_flower(self):
        fox_trace = ALBUM.index('{flag = "MoonGateTrace",')
        moth_gate = ALBUM.index('{flag = "MoonGateOpen",')
        relic = ALBUM.index('{flag = "MoonRelic",')
        flower = ALBUM.index('{flag = "Flower",')
        self.assertLess(fox_trace, moth_gate)
        self.assertLess(moth_gate, relic)
        self.assertLess(relic, flower)
        self.assertIn('if not player:GetAttribute("MoonGateTrace") then', HUD)
        self.assertIn('if not player:GetAttribute("MoonGateOpen") then', HUD)
        self.assertIn('if not player:GetAttribute("MoonRelic") then', HUD)


if __name__ == "__main__":
    unittest.main()
