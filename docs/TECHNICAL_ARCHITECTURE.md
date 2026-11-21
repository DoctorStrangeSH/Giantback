# Giantback — техническая архитектура

## 1. Основное правило

Сервер владеет игровым состоянием. Клиент отвечает за представление и ввод. Никакая важная награда, покупка, постройка или изменение чужого города не подтверждается только клиентским кодом.

## 2. Планируемая структура модулей

### ServerScriptService
- Services/ProfileService — загрузка, сохранение, миграции профиля.
- Services/CityService — участки, здания, расширения и разрешения гостей.
- Services/BuildingService — проверка и размещение объектов.
- Services/FarmService — посадка, рост и урожай.
- Services/PetService — коллекция, экипировка и способности.
- Services/InventoryService — валюта, ресурсы, предметы и атомарный подбор.
- Services/EquipmentService — слоты экипировки и улучшения.
- Services/CombatService — серверная проверка атак, урона и cooldown.
- Services/BridgeService — состояние мостов и открытие постоянных островов.
- Services/WorldService — биомы, ресурсы и точки интереса.
- Services/DungeonService — группы, комнаты, босс и награды.
- Services/MonetizationService — Game Pass, Developer Product и receipts.

### ReplicatedStorage
- Shared/Config — каталог зданий, культур, питомцев, рецептов и регионов.
- Shared/Remotes — RemoteEvent/RemoteFunction.
- Assets — модели и эффекты, используемые несколькими системами.

### StarterPlayer
- Client/UI — интерфейс.
- Client/Controllers — ввод, камера, строительство, карта и питомцы.
- Client/Animations — локальные анимационные контроллеры.

Эта структура вводится постепенно. Не переписывать весь проект одним коммитом.

## 3. Профиль игрока

Схема хранения должна иметь schemaVersion. Предварительная структура:

- profile.schemaVersion
- profile.city.level
- profile.city.unlockedDistricts
- profile.city.buildings
- profile.farm.level
- profile.farm.plots
- profile.pets.owned
- profile.pets.active
- profile.inventory.currency
- profile.inventory.materials
- profile.inventory.seeds
- profile.inventory.resources
- profile.equipment.weapon
- profile.equipment.armor
- profile.progress.quests
- profile.settings

Сохранять только сериализуемые значения и проверенные ID. Не сохранять произвольные Instances или клиентские CFrame без серверной проверки.

## 4. Сохранения

- Проверять результат загрузки и отличать пустой профиль от ошибки DataStore.
- Не перезаписывать существующий прогресс дефолтными значениями при временной ошибке.
- Использовать UpdateAsync для безопасных обновлений.
- Ограничивать частоту сохранений и учитывать бюджет DataStore.
- Сохранять при важных контрольных точках, выходе и закрытии сервера.
- Добавлять миграции при изменении схемы.
- Тестировать повторный вход и прерывание сервера.

## 5. Строительство

Клиент может показать preview, но сервер:
1. Проверяет, что участок принадлежит игроку или гость имеет право.
2. Проверяет ID здания в каталоге.
3. Проверяет стоимость и наличие ресурсов.
4. Проверяет границы и пересечения.
5. Проверяет допустимый поворот и позицию.
6. Списывает ресурсы и сохраняет постройку атомарно.
7. Реплицирует результат.

Удаление/перемещение должно возвращать ресурсы только по серверному правилу.

## 6. Питомцы и анимации

- Каталог вида отделён от конкретного экземпляра питомца.
- Владение и активный спутник хранятся в профиле игрока.
- Дикий encounter — отдельная серверная сущность.
- После приручения encounter скрывается локально только для владельца; другие игроки продолжают его видеть.
- На одного игрока создаётся только один follower каждой активной позиции.
- Анимации используют AnimationController/Animation assets либо процедурные движения с базовыми позами.
- Анимация не должна создавать физические столкновения или влиять на серверный игровой результат.
- Проверять респавн, смену питомца, стриминг и повторный вход.

## 7. Социальные разрешения

- Владелец выбирает, кто может посещать город.
- Гость по умолчанию может только осматривать.
- Помощь на ферме и использование общих объектов выдаются отдельными разрешениями.
- Редактирование и удаление чужих построек запрещено по умолчанию.
- Все проверки выполняются сервером.

## 8. Производительность

- Избегать постоянного создания/удаления больших наборов Instances.
- Использовать StreamingEnabled для больших миров после проверки маршрутов.
- Ограничивать число активных световых источников и частиц.
- Отключать физические свойства у декоративных объектов.
- Профилировать сервер и клиент на целевых мобильных устройствах.
- Не запускать отдельный RenderStepped listener для каждого питомца, если можно обновлять их общим контроллером.

## 9. Сетевая безопасность

- Проверять типы, длины строк и диапазоны чисел.
- Проверять дистанцию до объекта.
- Проверять владение предметом/участком.
- Ограничивать частоту запросов.
- Не принимать цену, валюту, редкость и награды от клиента.
- Не выдавать dungeon reward без серверного состояния завершения.
- Логировать аномальные действия без сохранения лишних персональных данных.

## 10. Проверки перед релизом

- Сборка из исходников.
- Проверка синтаксиса Luau.
- Тест нового профиля.
- Тест повторного входа.
- Тест нескольких игроков.
- Тест потери соединения.
- Тест строительства и прав гостей.
- Тест питомцев и дубликатов.
- Тест фермы и офлайн-роста.
- Тест подземелья и повторной выдачи наград.
- Тест покупок и receipts.
- Мобильная проверка и профилирование.


## 11. Подбор ресурсов и защита от дубликатов

- У каждого собираемого узла есть постоянный nodeId и itemId.
- Модель узла общая для сервера, но факт получения и cooldown хранятся отдельно в профиле каждого игрока.
- Сервер проверяет Ready, дистанцию до prompt и персональное состояние узла перед начислением.
- Персональный cooldown устанавливается до первого yield в обработчике, поэтому повторные и параллельные срабатывания одного игрока не начисляют второй предмет.
- После сбора клиент локально скрывает модель и prompt только для собравшего игрока; другие игроки продолжают видеть узел и могут собрать собственный ресурс.
- Возобновляемые ресурсы сохраняют timestamp следующего сбора в профиле; солнечные и лунные лепестки используют 300 секунд.
- Уникальные сюжетные и коллекционные находки сохраняют постоянный флаг collectedNodes и больше не доступны тому же игроку.
- Клиент запрашивает персональное состояние после загрузки профиля; сервер отправляет cooldowns и collected, не принимая эти значения от клиента.
- Повторный вход восстанавливает локальную видимость из сохранённого профиля.
- Инвентарь, cooldowns и unique claims сохраняются через UpdateAsync; schemaVersion текущего прототипа — 6.
- Клиент отображает счётчик, полученный из серверного профиля; локальная модель UI не является источником инвентаря.
- Сохранение использует версию схемы и миграции, чтобы старые профили не теряли прогресс.

## 12. Боевая система

- Клиент передаёт только намерение атаковать, направление и выбранную способность.
- Сервер проверяет дистанцию, линию атаки, скорость запросов, cooldown и состояние цели.
- Урон, смерть врага, выдача опыта и лута рассчитываются сервером.
- Экипировка сверяется с серверным инвентарём.
- Награда босса имеет уникальный ID выдачи, чтобы повторный сигнал не создавал дубликат.
- Клиентские эффекты попаданий и анимации не могут сами выдавать награды или изменять здоровье.


## 13. Fixed home islands and farm prototype

- `HomeIslandTemplate` is stored in ServerStorage. WorldVisuals decorates the template before World.server clones it.
- Each server has eight fixed home-island slots arranged around the shared Grove hub. The slot radius is 240 studs; all islands face inward toward their permanent bridge.
- A joining player receives a clone named `HomeIsland_<UserId>` inside Workspace.PlayerIslands, with OwnerUserId, OwnerName and HomeIslandSlot attributes.
- Each island has its own HomeSpawn, cottage, planter, lantern pad and PersonalCity container. Four farm plots are created inside that player's island; they no longer overlap or depend on client-side hiding.
- Eight radial bridges connect the personal islands to the shared Grove. Each home bridge starts as a translucent, non-collidable blueprint; the player repairs their own bridge for 5 Wood and 3 Stone. A separate fixed bridge connects Grove to Dusk.
- Every personal island has owner-only WoodPile and StonePile interactions. A harvest grants 3 Wood or 2 Stone with a 60-second per-profile cooldown; the cooldown is persisted.
- The first starter bundle is 2 Wood and 1 Stone, so one harvest from each pile completes the first bridge recipe.
- A temporary PublicSpawn in Grove is used while the profile loads. The player is then moved to their own HomeSpawn, which is also used for respawns.
- Slot occupancy is server-local and released when the player leaves. The slot number is not persisted; the island's gameplay state is stored in the player's profile.
- Profile schemaVersion 5 migrates the old `city` payload into `island`; schemaVersion 6 adds persistent Fox Scout cache state and the MoonSeed inventory item without discarding earlier profile fields.
- Plot01 is open at farm level 1; Plot02/Plot03 open at level 2; Plot04 opens at level 3.
- The first crop is Carrot: 3 starter seeds, 180 seconds of growth, then one carrot harvest. plantedAt and readyAt persist so growth continues offline.
- Studio uses a separate DataStore, GiantbackAlbum_Studio_v1. Enable Studio Access to API Services to test saves; if DataStore is unavailable the session is marked offline and is not saved.
- This is a playable architecture prototype, not a finished build mode or guest-permissions system. The Roblox place should be configured for a maximum of eight players until additional slots are implemented.

## Reboot decision (2026-11-21)

The moving-island loop and overlapping PersonalCities approach are retired. The current implementation uses static turtle-shaped personal home islands, eight server-assigned slots and a shared bridge-connected adventure hub. See docs/REBOOT_ARCHITECTURE.md. CI validates the place source, profile migration and Fox Scout contracts; Studio multiplayer, persistence and mobile acceptance remain open.


## 14. Fox Scout and personal cache discovery

- The Fox is the first active exploration companion. The player must equip it and interact with the tracks on \`Grove.Trail\` to request a search.
- The server rotates through three fixed cache anchors in the Grove. Cache selection is based on the player's saved search count, not on client input.
- The client receives only the active cache ID as a player attribute. It highlights that cache locally, creates a local-only ProximityPrompt, plays a short Fox sniff/tail-wag animation and renders a client-only golden pawprint trail from Grove.Trail to the active cache. Cache 2 and 3 routes use Grove-center-relative waypoints to steer the trail around the central trees. The trail is shown only while the Fox is equipped and is destroyed when the cache is cleared or the companion is unequipped; other players cannot see or claim it.
- The client sends the cache ID as an interaction request. The server verifies the ID allowlist, the player's active cache, equipped Fox, character root and 10-stud interaction distance before granting anything.
- The first successful find grants one \`MoonSeed\` and sets the \`Seed\` story flag. The MoonSeed is consumed when the player wakes the home flower with the Moth.
- Later cache rewards follow a deterministic rotation: 2 SunPetals, 2 Wood, then 1 CarrotSeed. There are no paid random rewards.
- A successful collection starts a 120-second scout cooldown. The active cache ID, cooldown timestamp and completed search count are saved under \`profile.foxScout\`.
- An active cache survives reconnects; the player can re-equip the Fox and finish the find. The client never decides reward amounts or cooldown state.


## 15. Moth Lunar Glow and personal MoonBloom discovery

- \`MoonBloom\` is a persistent progress flag in the existing profile progress map; no inventory schema migration is required.
- The Dusk island contains one invisible, non-collidable, queryable \`MoonBloom\` interaction anchor and a decorative \`MoonBloomVisual\` model.
- The visual model is hidden per client until the player equips Moth or has already discovered the flower. Its PointLight is enabled locally only while revealed.
- The client creates a local-only Highlight and ProximityPrompt. Other players without Moth cannot see or interact with the discovery.
- The client sends only \`CollectMoonBloom\`; the server checks Ready/session state, equipped Moth, the personal \`MoonBloom\` flag, anchor existence and a 10-stud interaction distance.
- A successful first discovery sets \`MoonBloom=true\`, grants MoonPetal ×2, synchronizes inventory and saves progress. Repeat requests grant nothing.
- The discovery is placed after meeting the Moth and before waking the home Moonflower, making the companion ability part of the first expedition rather than a cosmetic toggle.


## 16. Personal Moon Gate expedition

- Dusk contains three invisible, queryable anchors: \`MoonGateTracks\`, \`MoonGateRune\` and \`MoonRelic\`. They are non-collidable and carry no server ProximityPrompts.
- The player first equips the Fox and uses the local tracks prompt. The server checks the owned/equipped Fox, Ready session, anchor and 10-stud distance before setting \`MoonGateTrace\`.
- The player then equips the Moth and uses the local rune prompt. The server requires the saved trace flag, owned/equipped Moth, the rune anchor and 10-stud distance before setting \`MoonGateOpen\`.
- The gate seal, runes, tracks and clearing are rendered per client through \`LocalTransparencyModifier\`. The client creates local-only ProximityPrompts, Highlights and an invisible local collision barrier while the passage is locked; the barrier is removed only for that player's saved MoonGateOpen state. One player's discovery does not reveal the passage to others.
- The hidden clearing contains one StarShard. The server requires \`MoonGateOpen\`, an unclaimed \`MoonRelic\` flag, the relic anchor and 10-stud distance before granting \`StarShard +1\`.
- \`MoonGateTrace\`, \`MoonGateOpen\`, \`MoonRelic\` are monotonic profile progress flags. StarShard uses the existing inventory snapshot/sync pipeline; this is backward-compatible and does not require a schema migration.
- The main first-expedition route places this joint puzzle after MoonBloom and before the home Moonflower.
