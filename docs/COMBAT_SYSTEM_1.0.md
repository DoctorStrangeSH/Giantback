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

## 12. Первый лесной тайник после боя — staged

После серверно подтверждённых побед над Корневым стражем и Мшистым разведчиком игрок получает доступ к небольшой скрытой комнате `ForestTrialChamber`. Портал на тренировочной арене выполняет проверку готовности, состояния персонажа, дистанции до взаимодействия и двух отметок победы непосредственно на сервере.

Внутри находится сундук, который один раз за профиль выдаёт `StarShard ×1` через существующий механизм `GiantbackGrantCombatReward`. Повторная выдача блокируется сохранённой отметкой `GroveTrialChest01`, а конкурентные обращения к сундуку в рамках сессии дополнительно защищены `trialBusy`. Выход ведёт назад к арене. Оба портала и комната создаются `WorldVisuals.server.luau`.

**Статус:** серверный функционал и сборка добавлены в PR #7. Это короткая наградная комната, а **не** полноценное процедурное подземелье, головоломка или босс. Проверка геометрии, коллизий, выхода и сохранения в Roblox Studio остаётся NOT DONE.

## 13. Rune memory puzzle — staged

The forest trial chamber contains three interactable runes. The visible clue gives the sequence **Moon → Dawn → Tide**. The server tracks progress independently per player, rejects incorrect order, resets an abandoned sequence after 20 seconds, and only enables the chest after all three runes are activated in order. Puzzle progress is session-scoped; the final chest reward remains profile-persistent and idempotent.

Roblox Studio acceptance remains required for prompt reachability, label readability, room layout and multiplayer isolation.

## 14. Rootvault expedition — staged

A compact three-room dungeon is generated beyond the first forest trial chamber: an entry room, a connected pressure-plate passage, a mechanism room with a per-player lever and sealed door, and a reward vault. The entrance requires the player's saved first-trial chest completion. The server owns the in-dungeon state, lever progression, prompt distance checks, trap damage cooldown, and one-time reward claim. Pressure plates deal bounded damage with a per-player cooldown; the vault chest grants **IronOre ×3** once per profile via the existing idempotent reward function.

This is the first traversal slice, not yet the final dungeon: enemy encounters, a boss, a key-drop loop, room randomization and Studio playtesting remain NOT DONE.

## 15. Rootvault sentinel and key gate — staged

Rootvault now has its own tagged combat region (`RegionId = Rootvault`), so combat validation works while the player is inside the dungeon rather than requiring the Grove training ring. A dedicated 145-HP R6 sentinel guards the mechanism room. Its server-registered encounter is `RootvaultSentinel01`; each contributing player receives one persistent `RootvaultKey` on first clear through the existing reward/save path. The sealed-door prompt requires both that player's key and their own activated lever state. The key is retained after opening, while the final reward chest remains separately one-time.

Roblox Studio acceptance remains required for sentinel navigation, pathfinding through the room openings, key persistence after reconnect, multiplayer contribution rewards and door progression.

## 16. Rootvault prowler — staged

The entry chamber now contains a distinct fast enemy, `RootvaultStalker01` (display name Корневой охотник): 75 HP, WalkSpeed 15, 8 damage, 1.8-second attack cooldown and 0.55-second telegraph. It uses the existing server-owned pursuit, attack validation and contributor tracking. Each player who contributes to its first defeat receives one persistent `RootvaultEssence` through the same idempotent reward/save pipeline. The sentinel continues to guard the mechanism room and award the separate RootvaultKey.

Studio acceptance remains required for rig animation, navigation around the arrival point, combat balance and multiplayer reward persistence.

## 17. Rootvault Seal Keeper boss — staged

The reward chamber now contains `RootvaultSealKeeper01`, a 360-HP boss with a server-driven three-phase progression. Phase 1 uses 14 damage / 3.1s cooldown / 1.15s telegraph. At 60% health it advances once to phase 2 (9 speed, 18 damage, 2.5s cooldown, 0.9s telegraph); at 25% it advances once to phase 3 (12 speed, 22 damage, 1.9s cooldown, 0.65s telegraph). The server changes movement and attack values from Humanoid.HealthChanged; clients cannot select or trigger phases.

Each contributor receives a persistent `RootvaultSigil` on first defeat. The Rootvault chest now refuses claims until that player's own saved `RootvaultSealKeeper01` encounter is complete. This is a first boss slice using the existing telegraphed melee pattern; unique area attacks, animations, and visual phase effects remain NOT DONE pending later iterations and Studio review.

## 18. Rootvault Seal Keeper ground slam

In phases 2 and 3, every second boss attack becomes a server-authoritative area ground slam. The boss publishes `BossAttack=GroundSlam` and `CombatState=BossSlamTelegraph` during the warning window, then checks every ready player inside the Rootvault combat region. Players outside the configured radius are safe; a correctly timed dodge avoids the hit; facing the boss while blocking applies the existing block reduction. Phase 2 uses radius 15 and 16 damage; phase 3 uses radius 19 and 22 damage. The client cannot provide target, radius, damage, or timing values.

The server exposes the slam state through replicated attributes. The client now renders a local expanding neon floor warning ring, raycast-aligned to the arena floor. Impact animation, phase-specific boss animations, and Studio balance pass remain NOT DONE.

## 19. Seal Keeper phase-three summons

At the 25% health transition, the server awakens two prebuilt dormant Seal Fragments in the Rootvault reward chamber. They are registered into the existing server combat loop only once, have 52 HP, 13 movement speed, 6 damage and a 0.55-second attack warning. The minions use a known encounter ID but are deliberately excluded from the reward allowlist: defeating them cannot grant the boss sigil or any duplicate first-clear reward. The boss records the number activated in its replicated `SummonedMinions` attribute.

The dormant rigs are authored as part of the generated place; they do not pursue or attack before phase three. Studio testing is still required for their spawn clearance, rig movement, and multi-target combat balance.

## 20. Client-side boss phase transformation pulse

The client listens for the server-replicated `BossPhase` attribute. On phases 2 and 3 it plays a short local-only transformation cue: an occluded Highlight flash, an expanding neon floor pulse raycast-aligned to the arena floor, and a brief SealCore size/color pulse. Phase 2 uses violet; phase 3 uses ember red. The effect does not modify boss health, movement, attacks, or damage and cannot be invoked by client input. Full rig animation, persistent armor geometry changes, and audio remain NOT DONE.

## 21. Enemy health UI

The client now creates local-only BillboardGui health/name bars for regular enemies and summoned minions, with distance culling at 90 studs and health color bands. The Seal Keeper receives a dedicated top-center boss panel with localized phase label, numeric HP and phase-colored health bar. UI follows replicated server health attributes and Humanoid.HealthChanged; it does not accept client-supplied health. Bars are cleaned up when an enemy dies or leaves Workspace. Studio review is still needed for mobile readability, overlap in co-op, and camera positioning.

## 22. Seal Fragment awakening cue

When a Seal Fragment is activated and enters the tagged enemy collection, each client plays a local-only awakening cue: violet Highlight flash, a short spark particle burst, and an expanding floor ring aligned by raycast. The cue is guarded per client per minion and does not affect combat or enemy visibility/authority. The same collection-added callback binds its local health bar. Studio acceptance must confirm particle readability, floor alignment and performance with both minions and multiple players.

## 23. Client procedural enemy animation layer

Tagged custom enemy rigs now receive a lightweight local animation layer driven by replicated `CombatState` and Humanoid movement. It supplies idle breathing/head motion, alternating arm/leg locomotion, single-attack wind-up, two-arm ground-slam wind-up, recovery and phase-transition poses. Motor6D.Transform is applied client-side only; the server still owns movement, hit timing and damage. Joint transforms are reset when the rig leaves Workspace. This is a procedural placeholder animation layer, not authored animation assets or a substitute for final animation polish. Studio validation is required for joint orientation, replication timing, and visual quality on every enemy rig.
