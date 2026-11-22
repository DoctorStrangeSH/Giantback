# Giantback — Combat System 1.0

**Status:** C0 contract and C1 server combat loop plus generated training arena/enemy are implemented; Roblox Studio gameplay acceptance remains NOT DONE; C2–C4 planned.  
**Owner:** gameplay/server systems.  
**Scope:** first reliable combat loop for the 1.0 adventure release.

This document translates sections 8–9 of `PROJECT_SPEC.md` and the combat requirements in `docs/PROGRESSION_AND_COMBAT.md` into an implementable, testable sequence. It does not authorize expanding the 1.0 release scope.

## 1. Player-facing goal

Combat should be readable and forgiving: the player sees an enemy telegraph, understands the safe response, performs an attack/block/dodge, and receives clear feedback. A companion may help, but must never be required to win.

The first playable slice is deliberately small: one weapon (sword + shield), one compact encounter arena, two readable enemy archetypes, and guaranteed first-clear rewards. Add weapon classes only after this loop is stable.

## 2. Non-negotiable authority rules

- The server owns enemy health, player combat state, attack cooldowns, hit validation, damage, death, encounter completion and rewards.
- A client request may express intent only. It must never supply authoritative damage, cooldown, reward amount, enemy health, hit result or arbitrary target position.
- The server validates that the player is alive, loaded, allowed to fight in the current region, and not currently stunned/dead.
- The server enforces per-action cooldowns and a bounded request rate. Rejected requests do not mutate health or inventory.
- Melee hit detection is calculated by the server from the character's current root/forward direction and a bounded hit volume. Ranged attacks use server raycasts/projectiles with server-owned origin and limits.
- Targets must belong to a server-registered encounter and be alive. Never accept an arbitrary Instance supplied by the client without resolving it against the server registry.
- Reward grants are server-only and idempotent per player + encounter completion ID.
- Visual effects, animation cues, hit markers and camera feedback may be client-side, but are presentation only.

## 3. Remote contract

Create a dedicated `CombatAction` RemoteEvent in a server-owned initialization path. Keep it separate from the general album/economy action protocol.

Allowed initial intents:
- `Attack` — weapon ID is inferred from server-owned equipped state; no client damage values.
- `BlockStart` / `BlockEnd` — server records block state and validates allowed weapon.
- `Dodge` — server applies cooldown, short invulnerability window and bounded movement impulse.
- `RequestCombatState` — server returns a sanitized state snapshot for UI recovery.

Payloads are small, typed and allow-listed. Unknown actions, oversized payloads, NaN/infinite numbers, arbitrary Instances and unknown IDs are rejected. The server derives all timing and damage values from server configuration.

## 4. First weapon: sword + shield

- Light attack: short wind-up, active hit window, recovery and server cooldown.
- Block: reduces or negates eligible frontal damage while held; does not protect from clearly telegraphed unblockable attacks.
- Dodge: short, readable movement burst with a small server-controlled invulnerability window and cooldown.
- No client-side damage prediction that changes authoritative health.
- Input must work with keyboard/mouse, touch and gamepad. Mobile controls must have large, separated attack/block/dodge targets and must not cover navigation.

## 5. First enemy

Implement one readable melee enemy with a small state machine:
1. `Idle` — waits until a valid player enters aggro range.
2. `Approach` — moves toward the target using server-owned logic.
3. `Telegraph` — announces a bounded attack and its danger area before impact.
4. `Attack` — applies server-calculated damage only if the target remains in the danger area.
5. `Recover` — pauses briefly before returning to approach.
6. `Defeated` — stops attacking, disables hit handling and triggers exactly one reward resolution.

The first enemy needs one basic attack and one clearly signaled heavy attack. The telegraph must be understandable without relying on color alone (shape, motion, sound and short text/icon cue).

## 6. Health, death and recovery

- Health and damage are clamped to server-configured bounds.
- Invulnerability frames are server-timed and cannot be extended by repeated client calls.
- Player death/respawn must clear transient combat state (blocking, active attack, stun, temporary buffs) without deleting persistent inventory.
- Enemy death and encounter completion must be atomic from the reward system's perspective.
- Disconnect/rejoin cannot duplicate a completed encounter reward.

## 7. Future weapon classes (after the first slice)

| Class | First ability | Server validation |
|---|---|---|
| Bow | charged shot / weak-point hit | server raycast or server-owned projectile, bounded range and fire rate |
| Staff | elemental bolt | server-owned projectile, bounded speed/range and cooldown |
| Sword + shield | frontal block / counter window | server-held block state and server-calculated frontal angle |

Weapon stats, upgrade tiers and armor modifiers live in server configuration/profile state. Cosmetics never alter damage or defense.

## 8. Test and acceptance gates

Automated contract tests must cover:
- unknown action and unknown weapon rejection;
- client-supplied damage/reward/health values are ignored;
- attack spam and block/dodge spam are rate-limited;
- melee range and facing are validated server-side;
- a dead, unready or out-of-region player cannot damage an enemy;
- an enemy outside the encounter registry cannot be targeted;
- damage cannot exceed configured caps;
- block only affects eligible frontal attacks;
- dodge invulnerability starts/ends on server time;
- enemy defeat and reward resolution happen once;
- reconnect/retry cannot duplicate encounter rewards;
- respawn clears transient combat state.

Roblox Studio acceptance must additionally verify animation timing, hitbox alignment, telegraph readability, touch/gamepad controls, 1–4 player behavior and low-end mobile performance. A passing Python source-contract suite is not a substitute for Studio playtesting.

## 9. Delivery sequence

1. **C0 — Combat contract:** remote creation, server config, state cleanup, rate limiting and automated negative tests. No public enemies yet.
2. **C1 — First playable loop:** sword/shield, block, dodge, one enemy, one arena, one guaranteed reward.
3. **C2 — Weapon variety:** bow and staff, each with distinct server validation.
4. **C3 — Progression:** armor slots, stats, smithing upgrades and readable equipment UI.
5. **C4 — Expedition:** one 5–10 minute dungeon, puzzle, boss and co-op scaling for 1–4 players.

Do not start C1 until C0 tests pass. Do not mark any combat milestone DONE until Roblox Studio acceptance is recorded.


## 10. C0 implementation record

Implemented in `Combat.server.luau`:
- Dedicated server-owned `CombatAction` RemoteEvent, recreated safely if a conflicting instance type exists.
- Strict action allow-list and empty payload contract; the client cannot provide damage, target, reward or health values.
- Global per-player request rate limit (10 requests per one-second window).
- Ready/alive, server-owned region ID and server-owned equipped-weapon gates for gameplay intents.
- Sanitized C0 state snapshot; no mutable server state tables are sent to clients.
- Transient combat state cleanup on death, respawn and disconnect.
- C0 security contract remains the foundation for C1; the current server accepts the allow-listed combat actions and performs server-owned damage and reward resolution.

Automated contract coverage lives in `tests/test_combat_foundation_contract.py`. The place builder embeds the new server script and CI validates its presence. C0 is not a playable combat milestone; no enemy, hitbox, damage or reward implementation is claimed.


### C0 security hardening

The server callback now captures all RemoteEvent trailing arguments with varargs and rejects any nonzero argument count. This also rejects an explicitly supplied `nil` and arguments beyond the former third parameter; checking only a single optional payload parameter would silently ignore later arguments.


## 11. C1 server implementation record

Implemented in `Combat.server.luau`:
- Server-tagged combat volumes (`GiantbackCombatRegion`) with allow-listed `RegionId` values; the player must physically be inside the volume.
- Server-tagged enemy Models (`GiantbackEnemy`) must contain a Humanoid and HumanoidRootPart and declare an allow-listed `EncounterId` and `RegionId`. Each enemy may define bounded server-read attributes for aggro range, attack range, damage, cooldown, telegraph duration and path refresh; clients cannot change these values.
- Server-owned sword hitbox, range, facing check, damage and attack cooldown. Client requests contain only the action name.
- Enemy AI loop with idle/approach/telegraph/recover states, a telegraphed melee attack, and server-side range revalidation before damage.
- Server-held block state reduces only frontal enemy damage; server-timed dodge grants a short invulnerability window and bounded impulse.
- Enemy death resolves the reward through the profile-owned BindableFunction. The profile stores completed encounter IDs and inventory rewards idempotently (schema v10); failed profile saves roll back the in-session grant. Every player who lands at least one server-validated hit is recorded as a contributor and receives their own first-clear reward on defeat; disconnected players are skipped.
- `Combat.client.luau` binds mouse/keyboard, gamepad and ContextActionService touch buttons for attack, held block and dodge; it sends action names only.
- Leaving the tagged arena automatically clears held block; `BlockEnd` is always accepted for a ready player so a lost focus/input release cannot leave a stale guard state.
- `WorldVisuals.server.luau` now generates a connected training glade beyond the Grove, tags its combat volume, and creates two R6-style enemies: a 100-health `Корневой страж` guardian and a faster 65-health `Мшистый разведчик` with a shorter warning window, lighter damage and a distinct mint-green telegraph. The approach bridge, stone ring, lanterns and arena are generated in a fresh place build; no manual Studio tagging or placeholder rig import is required.
- A visible `БЕРЕГИСЬ!` warning, temporary highlight and raised club pose appear during the server's 0.85-second enemy telegraph; the swing pose plays during recovery. The NPC is oriented toward the arena entrance and keeps server network ownership.
- The client displays concise Russian feedback for successful hits and rejected actions (cooldowns, arena boundary, load state and request rate) without exposing server-owned values.
- Studio acceptance is still required: verify that the NPC walks and attacks reliably, the hitbox aligns, rewards persist after reconnect, and two or more players cannot duplicate the reward.
