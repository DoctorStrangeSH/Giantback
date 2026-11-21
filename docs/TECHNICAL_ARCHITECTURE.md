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
- Инвентарь, cooldowns и unique claims сохраняются через UpdateAsync; schemaVersion текущего прототипа — 5.
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
- Profile schemaVersion 5 migrates the old `city` payload into `island`, preserves farm/building data, removes the legacy field and accepts old profiles idempotently.
- Plot01 is open at farm level 1; Plot02/Plot03 open at level 2; Plot04 opens at level 3.
- The first crop is Carrot: 3 starter seeds, 180 seconds of growth, then one carrot harvest. plantedAt and readyAt persist so growth continues offline.
- Studio uses a separate DataStore, GiantbackAlbum_Studio_v1. Enable Studio Access to API Services to test saves; if DataStore is unavailable the session is marked offline and is not saved.
- This is a playable architecture prototype, not a finished build mode or guest-permissions system. The Roblox place should be configured for a maximum of eight players until additional slots are implemented.

## Reboot decision (2026-11-21)

The moving-island loop and overlapping PersonalCities approach are retired. The current implementation uses static turtle-shaped personal home islands, eight server-assigned slots and a shared bridge-connected adventure hub. See docs/REBOOT_ARCHITECTURE.md. CI validates the place source and profile migration; Studio multiplayer, persistence and mobile acceptance remain open.
