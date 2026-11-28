"""Companion idle behavior must be extracted without changing server authority."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = (ROOT / "Album.client.luau").read_text(encoding="utf-8")
ACTIVITY = (ROOT / "modules/CompanionActivity.luau").read_text(encoding="utf-8")
BUILD = (ROOT / "build.py").read_text(encoding="utf-8")


class CompanionActivityModuleTests(unittest.TestCase):
    def test_builder_installs_activity_module(self):
        self.assertIn('companion_activity = obj(storage, "ModuleScript", "CompanionActivity")', BUILD)
        self.assertIn('require(storage:WaitForChild("CompanionActivity"))', CLIENT)
        self.assertIn('local companionActivity = CompanionActivity.new()', CLIENT)

    def test_idle_and_sniff_behavior_retained(self):
        self.assertIn('local companionActivity = setmetatable({}, {__mode = "k"})', ACTIVITY)
        self.assertIn('idleSeconds >= 12', ACTIVITY)
        self.assertIn('idleSeconds >= 45', ACTIVITY)
        self.assertIn('isLocal and id == "Fox"', ACTIVITY)
        self.assertIn('local resting, sleeping, sniff, attention, curious, playful = companionActivity.update(owner, id, now, moving, owner == player)', CLIENT)
        self.assertIn('if sniff then foxSniffUntil = os.clock() + 2.2 end', CLIENT)
        self.assertIn('setSleepIndicator(model, sleeping)', CLIENT)

    def test_owner_cleanup_and_personality_windows(self):
        self.assertIn('companionActivity.forget(owner)', CLIENT)
        self.assertIn('companionActivity[owner] = nil', ACTIVITY)
        for personality in ('Любопытный', 'Озорной', 'Смелый', 'Застенчивый'):
            self.assertIn('["' + personality + '"]', ACTIVITY)


    def test_attention_requests_are_local_cooldown_limited_and_personality_scaled(self):
        self.assertIn('nextAttentionAt = now + math.random(16, 26)', ACTIVITY)
        self.assertIn('if isLocal and not moving and now >= (activity.nextAttentionAt', ACTIVITY)
        self.assertIn('local attentionWindows = {', ACTIVITY)
        self.assertIn('["Любопытный"] = {34, 48}', ACTIVITY)
        self.assertIn('["Озорной"] = {28, 40}', ACTIVITY)
        self.assertIn('["Застенчивый"] = {48, 66}', ACTIVITY)
        self.assertIn('activity.nextAttentionAt = now + math.random(math.floor(minDelay), math.floor(maxDelay))', ACTIVITY)
        self.assertIn('if attention and owner == player then showCompanionAttention(model, id) end', CLIENT)
        self.assertIn('return resting, sleeping, sniff, attention, curious, playful, worldInterest', ACTIVITY)


    def test_all_equipped_species_get_short_personality_paced_curiosity_moments(self):
        self.assertIn('nextExploreAt = now + math.random(11, 18)', ACTIVITY)
        self.assertIn('if isLocal and not moving and now >= (activity.nextExploreAt', ACTIVITY)
        self.assertIn('activity.curiosityUntil = now + 2.6', ACTIVITY)
        self.assertIn('curious = isLocal and not moving and now < (activity.curiosityUntil or 0)', ACTIVITY)
        self.assertIn('local exploreWindows = {', ACTIVITY)
        self.assertIn('["Любопытный"] = {12, 18}', ACTIVITY)
        self.assertIn('["Застенчивый"] = {23, 32}', ACTIVITY)
        self.assertIn('activity.nextExploreAt = now + math.random(18, 28)', ACTIVITY)
        self.assertIn('state.curious = curious', CLIENT)

    def test_playful_idle_moments_are_personality_and_bond_paced_for_fox_and_moth(self):
        self.assertIn('nextPlayfulAt = now + math.random(18, 32)', ACTIVITY)
        self.assertIn('if isLocal and not moving and (id == "Fox" or id == "Moth")', ACTIVITY)
        self.assertIn('local playfulWindows = {', ACTIVITY)
        self.assertIn('["Озорной"] = {14, 24}', ACTIVITY)
        self.assertIn('["Застенчивый"] = {38, 54}', ACTIVITY)
        self.assertIn('activity.playfulUntil = now + 2.4', ACTIVITY)
        self.assertIn('window[1] - bondStage * 1.5', ACTIVITY)
        self.assertIn('return resting, sleeping, sniff, attention, curious, playful', ACTIVITY)
        self.assertIn('state.playful = playful', CLIENT)

    def test_playful_idle_timer_restarts_after_movement(self):
        self.assertIn('activity.nextPlayfulAt = now + math.random(24, 40)', ACTIVITY)
        self.assertIn('activity.playfulUntil = 0', ACTIVITY)

    def test_equipped_fox_and_moth_notice_owner_island_decorations_nearby(self):
        self.assertIn('local wantedDecoration = id == "Fox" and "DecorativeTree" or "FlowerBed"', ACTIVITY)
        self.assertIn('decoration:GetAttribute("DecorationId") == wantedDecoration', ACTIVITY)
        self.assertIn('nearestDistance = 8', ACTIVITY)
        self.assertIn('activity.nextWorldCheckAt = now + 0.4', ACTIVITY)
        self.assertIn('worldInterest = id == "Fox" and "Tree" or "Flowers"', ACTIVITY)
        self.assertIn('state.worldInterest = worldInterest', CLIENT)

    def test_module_is_read_only_to_server_and_does_not_animate(self):
        for forbidden in ('FireServer(', 'InvokeServer(', 'DataStoreService', 'Instance.new(', 'RenderStepped:Connect', ':SetAttribute('):
            self.assertNotIn(forbidden, ACTIVITY)
        self.assertEqual(CLIENT.count('RunService.RenderStepped:Connect(follow)'), 1)


if __name__ == "__main__":
    unittest.main()
