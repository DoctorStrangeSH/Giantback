from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "World.server.luau").read_text(encoding="utf-8")
ALBUM = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
HUD = (ROOT / "HUD.client.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")
VISUALS = (ROOT / "WorldVisuals.server.luau").read_text(encoding="utf-8")


class FoxScoutContractTests(unittest.TestCase):
    def test_schema_v6_adds_the_persistent_fox_scout_profile(self):
        self.assertIn("old.schemaVersion = 6", WORLD)
        self.assertIn("local savedFoxScout = type(old.foxScout) == \\"table\\" and old.foxScout or {}", WORLD)
        self.assertIn("savedFoxScout.activeCacheId = foxScoutSnapshot.activeCacheId", WORLD)
        self.assertIn("savedFoxScout.readyAt", WORLD)
        self.assertIn("savedFoxScout.searchCount", WORLD)
        self.assertIn("data.foxScout", WORLD)

    def test_three_cache_ids_are_registered_and_exist_in_the_grove_build(self):
        for cache_id in ("FoxCache01", "FoxCache02", "FoxCache03"):
            self.assertIn(cache_id, WORLD)
            self.assertIn(f'"{cache_id}"', BUILD)
        self.assertIn("local foxCacheIds =", WORLD)
        self.assertIn("FOX_SCOUT_COOLDOWN_SECONDS = 120", WORLD)

    def test_cache_anchors_are_invisible_queryable_and_non_collidable(self):
        self.assertIn('prop(cache_anchor, "float", "Transparency", "1")', BUILD)
        self.assertIn('prop(cache_anchor, "bool", "CanCollide", "false")', BUILD)
        self.assertIn('prop(cache_anchor, "bool", "CanTouch", "false")', BUILD)
        self.assertIn('prop(cache_anchor, "bool", "CanQuery", "true")', BUILD)

    def test_forest_caches_have_camouflaged_visual_models(self):
        self.assertIn('makeFolder(grove, "FoxCacheVisuals")', VISUALS)
        self.assertIn('visual.Name = "FoxCacheVisual" .. string.format("%02d", index)', VISUALS)
        self.assertIn("Mossy cache mound", VISUALS)
        self.assertIn("Leaf cover", VISUALS)
        self.assertIn("Buried glimmer", VISUALS)

    def test_search_requires_equipped_fox_and_respects_active_cache_and_cooldown(self):
        self.assertIn("local function startFoxSearch(player)", WORLD)
        self.assertIn('player:GetAttribute("Companion") ~= "Fox"', WORLD)
        self.assertIn("if session.foxCacheActiveId then", WORLD)
        self.assertIn("if session.foxSearchReadyAt > now then", WORLD)
        self.assertIn("session.foxCacheActiveId = cacheId", WORLD)
        self.assertIn('prompt(workspace.Grove.Trail,"Следы в траве","Попросить лисёнка искать",startFoxSearch)', WORLD)

    def test_collection_is_server_validated_by_owner_state_and_distance(self):
        self.assertIn('if action == "CollectFoxCache" then', WORLD)
        self.assertIn("local function collectFoxCache(player, cacheId)", WORLD)
        self.assertIn("session.foxCacheActiveId ~= cacheId", WORLD)
        self.assertIn("(root.Position - anchor.Position).Magnitude > 10", WORLD)
        self.assertIn('if typeof(cacheId) ~= "string" or not foxCacheIdSet[cacheId] then return end', WORLD)

    def test_first_scout_find_grants_moon_seed_and_flower_uses_it(self):
        self.assertIn('"MoonSeed"', WORLD)
        self.assertIn('itemId = "MoonSeed"', WORLD)
        self.assertIn('player:SetAttribute("Seed", true)', WORLD)
        self.assertIn("visitorSession.inventory.MoonSeed -= 1", WORLD)
        self.assertIn('visitor:GetAttribute("Companion") ~= "Moth"', WORLD)

    def test_cache_rewards_cycle_through_useful_materials(self):
        self.assertIn('FoxCache01 = {itemId = "SunPetal", amount = 2}', WORLD)
        self.assertIn('FoxCache02 = {itemId = "Wood", amount = 2}', WORLD)
        self.assertIn('FoxCache03 = {itemId = "CarrotSeed", amount = 1}', WORLD)
        self.assertIn("session.foxSearchCount += 1", WORLD)
        self.assertIn("session.foxSearchReadyAt = os.time() + FOX_SCOUT_COOLDOWN_SECONDS", WORLD)

    def test_client_reveals_only_the_active_cache_with_local_prompt_and_highlight(self):
        self.assertIn('localPrompt.Name = "FoxCacheLocalPrompt"', ALBUM)
        self.assertIn('event:FireServer("CollectFoxCache", cacheIdForPrompt)', ALBUM)
        self.assertIn('highlight.Name = "FoxCacheHighlight"', ALBUM)
        self.assertIn('highlight.Enabled = activeCacheId == cacheId', ALBUM)
        self.assertIn('player:GetAttributeChangedSignal("FoxCacheSpot")', ALBUM)
        self.assertIn("Следуй за золотой меткой и забери находку.", ALBUM)

    def test_album_displays_moon_seed_and_fox_scout_readiness(self):
        self.assertIn('"MoonSeed"', ALBUM)
        self.assertIn('Resource_MoonSeed', ALBUM)
        self.assertIn('FoxSearchReadyAt', ALBUM)
        self.assertIn("Нюх следопыта готов", ALBUM)

    def test_hud_explains_the_fox_scout_ability_and_active_find(self):
        self.assertIn("Нюх следопыта открывает личные тайники", HUD)
        self.assertIn("Следуй за золотой меткой в Солнечной роще", HUD)
        self.assertIn("найдёт лунное семя", HUD)


if __name__ == "__main__":
    unittest.main()
