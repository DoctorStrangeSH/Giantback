## Farming 2.0 — Four-crop server foundation

- [x] Expand server-owned crop registry to Carrot, Strawberry, Pumpkin and Cabbage with growth duration, seed item, harvest item and reward.
- [x] Add strawberry regrowth cycle (8 minutes after each harvest); other crops clear the plot after harvest.
- [x] Add persistent inventory keys and starter seed stock for the three new crops; legacy profiles receive safe defaults when those keys are absent.
- [x] Add server-side SelectCrop action; selection is accepted only for known crops with available seed.
- [x] Add per-plot in-flight guard to prevent overlapping harvest/plant requests.
- [x] Add regression tests for registry, inventory, selection, timestamps and strawberry regrowth.
- [x] Add player-facing four-crop seed selector to the Farm tab, showing seed counts, growth times and selected culture.
- [x] Show the actual crop name and live remaining growth time on each plot card.
- [x] Persist the selected crop in the player's island profile and restore it after rejoin.
- [ ] Add distinct crop-specific growth meshes/stages (current visual crop remains a shared placeholder).
- [ ] Complete Python contract suite and Roblox place validation after the latest UI/persistence changes.
- [ ] Studio playtest save/rejoin, offline growth, two rapid harvest requests and all four crop types.

## Farm Plots — Readability visual pass

- [x] Добавить четыре деревянных бортика на каждую грядку; борта визуально отделяют почву от дорожек.
- [x] Добавить три неглубокие борозды на каждую грядку, выровненные с поверхностью земли.
- [x] Все декоративные детали создаются без коллизий, касаний и query; интерактивность остаётся на отдельном PromptAnchor.
- [x] Добавить source-contract test для бортиков, борозд и их высоты.
- [ ] Дождаться Validate Giantback после farm visual pass и проверить generated place.
- [ ] Roblox Studio playtest: проверить посадку/сбор, prompt, рост культуры, камеру и читаемость на мобильном экране.
- [ ] Следующий этап — отдельные визуальные стадии четырёх культур; текущая морковь остаётся временным прототипом.

## Home Island — Layered Canopy visual pass

- [x] Добавить три крупных дерева с разной высотой/палитрой, объёмной кроной и небольшими светящимися ягодами.
- [x] Добавить четыре низких декоративных кармана с парными кустами и цветами.
- [x] Добавить три небольшие грибные группы, одна из них с мягким свечением.
- [x] Разместить растительность по внешнему краю, отдельно от четырёх грядок, ресурсных куч и зоны питомцев.
- [x] Добавить source-contract test на точки деревьев, кустов, грибов и незанятые игровые зоны.
- [ ] Дождаться Validate Giantback #1156; подтвердить contract tests, place build, embedded-script validation и artifact upload.
- [ ] Проверить реальную композицию/коллизии/проходимость в Roblox Studio на PC и mobile; проверить бюджет деталей при восьми личных островах.
- [ ] Не помечать арт как финальный до Studio review; текущая растительность собрана из Roblox primitives.

## Home Island — Companion Sanctuary visual pass

- [x] Добавить отдельную зону `HandcraftedDetails/PetSanctuary` на домашнем острове.
- [x] Сделать мягкую зелёную площадку с каменным центром и тремя цветными лежанками для компаньонов.
- [x] Добавить лунный фонарь, каменные бортики, цветы и четыре плиты подходной дорожки.
- [x] Добавить source-contract test на расположение трёх лежанок и элементов зоны.
- [ ] Проверить расположение и проходимость в Roblox Studio на PC/mobile; убедиться, что зона не пересекается с хвостом/декором острова.
- [ ] Связать лежанки с будущей системой назначения/отдыха питомцев; сейчас это только визуальная декорация.

## Lunar Moth — fourth visual correction pass

- [x] Artifact #56 passed Blender technical gates and generated front/side/back/three-quarter views.
- [x] Review #56 manually: body still too tapered/narrow, legs too wire-like, crescents too small at gameplay framing.
- [x] Shorten and widen thorax profile into a compact plush body; enlarge head and eyes.
- [x] Shorten leg reach, thicken curves/feet and enlarge/reposition crescent motifs inward.
- [ ] Run new Blender artifact; verify four views and all mesh/UV/material gates.
- [ ] Accept silhouette at gameplay scale before Studio import.
- [ ] Roblox Studio import, scale/pivot check and runtime wing animation — not done.

## Lunar Moth — third visual correction pass

- [x] Artifact #51 generated four real Blender views and passed technical geometry/UV/material package validation.
- [x] Manually review front, side and three-quarter renders: final art rejected; body still reads as a narrow tube, wings as pointed/leaf-like panels, crescents are too small, and legs look mechanical.
- [x] Reshape the continuous body into a fuller rounded thorax and softly tapered abdomen.
- [x] Change the wing width envelope to a rounded central lobe with narrower root/tip; enlarge the closed UV crescent marks; soften and thicken legs/feet.
- [ ] Run fresh Blender review; pass zero-area/non-manifold/UV/material gates.
- [ ] Manually accept all four views at intended Roblox gameplay scale.
- [ ] Roblox Studio import, scale/pivot check and runtime wing animation — not done.

## Lunar Moth — second visual correction pass

- [x] Проверить artifact #31: Blender geometry/UV/material gates прошли, но ручная приёмка отклонила oval-like moon marks, отсутствие видимых ног и скрытые abdomen bands.
- [x] Заменить овальные отметки на отдельные замкнутые crescent mesh с UV, толщиной и bevel; включить каждый знак в соответствующую wing-группу mesh report.
- [x] Добавить шесть изогнутых ног с мягкими лапками; включить mesh feet в thorax report group.
- [x] Перенести три золотые abdomen bands на видимую переднюю поверхность.
- [ ] Получить новый Blender artifact и пройти zero-area/non-manifold/UV/material gates.
- [ ] Вручную принять четыре ракурса; проверить, что полумесяцы читаются как полумесяцы, ноги не выглядят случайными выступами, а тело сохраняет дружелюбный силуэт.
- [ ] Roblox Studio import, scale/pivot check и runtime wing animation — не выполнены.

## Home Island — Garden Approach visual pass

- [x] Добавить отдельную зону `HandcraftedDetails/GardenApproach` в шаблон личного острова.
- [x] Проложить пять крупных stepping stones от входа коттеджа к фермерской зоне, чтобы новичок визуально понимал направление.
- [x] Добавить деревянную садовую арку с лунным светильником и небольшими вьющимися листьями; арка стоит перед грядками и не закрывает интерактивные точки.
- [x] Добавить source-contract tests `tests/test_home_island_visual_approach.py` для пути, арки и non-colliding visual helpers.
- [x] Python/gameplay/place validation подтверждена: runs #1100 и #1113 SUCCESS (source-contract tests, сборка place, embedded-script validation и artifact upload).
- [ ] Проверить композицию и проход игрока в Roblox Studio на PC/mobile; убедиться, что декор не перекрывает фермерские interaction prompts.
- [ ] Следующий визуальный проход: мягкие края острова, разнообразие растительности и читаемая зона питомцев; не перегружать стартовую площадку.

- [~] Fox Hero: artifact #239 успешно прошёл Blender technical gate и ручную проверку. Orange coat, глаза, мордочка и большой хвост читаются хорошо; уменьшенные forelock/brows стали аккуратнее, но лоб всё ещё имеет отдельные raised tufts, лапы остаются capsule-like с заметными cuff seams, а боковой силуэт корпуса/ног сегментирован. Нужен более органичный переход torso↔legs и встроенные лапы; не закрывать art acceptance и не импортировать до нового рендера.
- [x] Усилить CI visual-review gate: workflow проверяет четыре ракурса/OBJ/BLEND, совпадение rig/mesh report (17 групп), непустую геометрию, zero-area/non-manifold faces/edges, UV и назначенные материалы. Source-contract + place validation #965 SUCCESS; Blender artifact после последнего цветового pass ещё ожидается.
- [x] Soft-fur shader contract: `soft_fur`/`smooth` metadata and Sheen 0.08 are covered by tests. Current Fox Hero micro-relief is Noise scale 10, Detail 1, Bump strength 0.002/distance 0.001 (reduced after #187 manual review); next render must confirm gameplay-distance readability.
- [x] Синхронизировать source-contract tests с текущей палитрой Fox Hero и soft-fur shader: удалены противоречивые проверки старых RGB-значений, добавлены проверки Sheen, Noise/Bump параметров и metadata surface profiles. `FOX_ART_BRIEF.md` обновлён теми же фактическими параметрами. GitHub Actions `Validate Giantback place` run #941 завершился SUCCESS (контрактные тесты, сборка place, embedded-script validation и artifact upload). Fox Hero Blender run #109 завершился SUCCESS и опубликовал review artifact (4 PNG, OBJ/MTL, BLEND, rig JSON, mesh report; artifact ID 14742851612). Артефакт проверен вручную: модель технически корректна, но художественно не принята; корректировки внесены отдельным следующим проходом.
- [x] Добавить regression tests для самого Fox visual workflow: запрет `cancel-in-progress: true`, контроль timeout 35 минут и Blender bpy 4.2.0, наличие четырёх ракурсов и quality-gate для геометрии/UV/material profiles. Тесты проверяют конфигурацию workflow как исходный контракт; Blender run #109 завершился SUCCESS; artifact доступен и был визуально просмотрен. Повторный render после corrective art pass ещё ожидается.
- [~] Исправить топологию FoxHead: CI Blender обнаружил две zero-area faces в полюсных крышках головы. Сетка перестроена на единственную вершину в каждом полюсе и треугольные веера к первому/последнему кольцу; совпадающие вершины исключены. Unit/source test защищает новый способ построения. Повторный Blender render + mesh report обязательны перед художественной приёмкой.

# Giantback — Roadmap Reboot 1.0

Источник требований: PROJECT_SPEC.md.  
**Статусы:** [x] подтверждено в репозитории/CI; [~] прототип есть, но не принят; [ ] не сделано. CI не заменяет Roblox Studio playtest.


> **Текущий фокус — художественная production-фаза (началась).** Не выдаём Parts-based blockout за финальный визуал. Следующий визуальный gate: импорт и проверка оригинальных Fox/Moth OBJ/MTL в Roblox Studio, затем домашний остров и дом, мост, ферма и единый HUD. Для каждого ассета обязательны силуэт, материалы, масштаб относительно аватара, pivots/точки анимации, читаемость на мобильной дистанции и проверка производительности. Asset ID и результаты проверки фиксируются в `assets/source_models/ASSET_MANIFEST.md`. Не переключаем игровые скрипты на новые MeshPart до прохождения Studio acceptance.  
> **Вне Studio сейчас нельзя честно закрыть импорт MeshPart и визуальную приёмку.** До этого момента исходники готовы, но статус остаётся [~], а не [x].

## Lunar Moth — source audit

- [x] Измерить исходный `moth_companion.obj`: 1,306 vertices, 1,980 faces (1,978 triangles + 2 quads), 15 named objects, 7 assigned MTL materials.
- [x] Геометрические sanity checks: 0 zero-area faces, 0 edges with more than two adjacent faces; 616 boundary edges требуют ручного осмотра открытых оболочек.
- [x] Добавить `tests/test_moth_source_blockout_audit.py`: регрессионно фиксирует measured OBJ inventory, topology sanity checks и отсутствие UV, чтобы исходный BLOCKOUT нельзя было случайно принять за production-ready. Gameplay/world contract tests в Validate run #1034 прошли; финальное завершение workflow ожидается.
- [x] Обнаружить и зафиксировать критический gap: UV coordinates = 0. Исходник остаётся BLOCKOUT, не финальный текстурируемый asset.
- [ ] В новой Hero-модели создать UV unwrap, толщину/чистые кромки крыльев и painted motifs; оригинальный OBJ не перезаписывать.

## Lunar Moth Hero — first generation pass

- [x] Добавить отдельный Blender 4.2 generator `tools/blender/build_moth_companion.py`; legacy `moth_companion.obj/.mtl` не перезаписываются.
- [x] Создать четыре отдельных thickened wing mesh: upper/lower × left/right, каждому назначена UV-развёртка и отдельное имя для будущей анимации.
- [x] Первый Blender запуск создал BLEND/OBJ и 4 PNG, но gate поймал zero-area faces на верхнем крыле. Исправлен профиль ширины с 10% minimum и добавлен regression test; последующий run #20 прошёл все geometry/UV/material gates.
- [x] Исправлен Moth wing width profile: введён ненулевой floor 10%, чтобы корневая/концевая полосы не схлопывались в zero-area quads; добавлен regression guard. Первый render package собран, но acceptance gate корректно остановил артефакт из-за геометрии; новый run #15 ожидает перепроверки.
- [x] Создать body/head/abdomen, antennae, moon-gold accents, moon-cyan core и согласованную lilac/rose/cyan palette.
- [x] После художественного review #20 расширить/укоротить крылья, заменить bead antennae на Bezier feelers, объединить thorax/abdomen в цельный силуэт и добавить gold/lilac crescent inlays на все четыре крыла; fresh render + art review ещё обязательны.
- [x] Зафиксировать 10 стабильных rig groups и пять планируемых состояний (idle_hover/follow/reveal_secret/ability_burst/rest); текущий JSON — контракт, не готовый Roblox rig.
- [x] Добавить отдельный CI workflow `.github/workflows/lunar-moth-visual-review.yml`: BLEND/OBJ/MTL, rig JSON, mesh report, четыре ракурса, UV/geometry/material gates и artifact upload.
- [x] Добавить source-contract tests `tests/test_lunar_moth_hero_workflow.py`.
- [x] Дождаться реального Blender run #20: исправленная модель создана, zero-area/non-manifold/UV/material gates пройдены, артефакт опубликован.
- [~] Вручную проверить четыре ракурса: геометрия чистая, но художественно отклонено — узкие острые крылья, сегментированное тело, bead-like antennae и недостаточно уникальный moon motif. Новый source pass расширяет крылья, объединяет тело и делает изогнутые усики; повторный render обязателен.
- [ ] Импортировать в Roblox Studio; проверить масштаб, pivots, крылья, mobile readability и runtime animation.

## Следующий production-фокус — Lunar Moth

- [x] Создать `assets/source_models/MOTH_ART_BRIEF.md`: зафиксированы роль питомца, лунная палитра, четыре независимых крыла, силуэт, wing art, rig-группы, idle/follow/reveal/burst анимации и визуальные/технические acceptance gates.
- [x] Связать Moth art brief с `ASSET_MANIFEST.md`; исходный `moth_companion.obj/.mtl` сохранён как BLOCKOUT/rollback baseline.
- [ ] Выполнить геометрический аудит текущего Moth OBJ: части, дубли вершин, нормали, группы, материалы и pivot.
- [ ] Создать отдельную sculpted hero-модель моли с четырьмя независимыми крыльями; не перезаписывать исходный OBJ.
- [ ] Создать wing artwork и лунное световое ядро; подготовить Blender review package.
- [ ] Провести ручную художественную приёмку и Roblox Studio import/animation/mobile review.

## Этап 0. Переосмысление продукта
- [x] Зафиксировать новое направление: Cozy Adventure Sandbox / City Builder / Creature Collection.
- [x] Принять решение: острова статичны; развитие идёт через расширение и мосты.
- [x] Обновить полный PROJECT_SPEC 1.0.
- [x] Создать Reboot Vision, UI/UX Spec и Target Architecture.
- [x] Переписать Art Direction и правила качества ассетов.
- [x] Пересмотреть экономику, монетизацию и стратегию роста.
- [ ] Удалить противоречивые legacy-обещания из всех оставшихся документов и скриптов.

- [~] Автоматизировать Blender visual acceptance Fox Hero: workflow `bpy==4.2.0` строит .blend/OBJ, mesh report и четыре ракурса, проверяет 17 rig-групп, геометрию, UV и материалы. Runs #109/#117/#145/#163/#173 создали review packages; #173 вручную просмотрен, технически чистый, но художественно отклонён из-за персикового оттенка головы и сегментированных переходов корпуса/лап. Новый pass со Standard color transform и более мягким освещением закоммичен; повторный render ожидается.
- [x] Стабилизировать headless Blender workflow: `bpy==4.2.0`, software OpenGL/surfaceless EGL, `cancel-in-progress: false`, timeout 35 минут. Workflow-contract подтверждён тестами; каждый новый art pass должен завершаться новым render artifact.
- [x] Оптимизировать preview render: четыре обзорных PNG — 768×768, 16 Eevee TAA samples; финальные художественные рендеры высокого разрешения остаются отдельным этапом.

- [x] Сделать прогресс приключения понятнее в HUD: карточка текущей цели показывает номер шага из 11 сюжетных вех, номер обновляется по серверным атрибутам; добавлены визуальная полоса заполнения, счётчик `выполнено / всего` и плавная анимация заполнения. Исправлена высота карточки в desktop layout (94 px), чтобы шкала не обрезалась; compact layout сохраняет адаптивную ширину. Добавлены source-contract тесты. Требуется Studio-проверка на мобильном и ПК.

## Этап 1. Новый визуальный фундамент и UI
- [~] Добавить восемь отдельных статичных домашних островов вокруг общего лесного хаба и восемь радиальных мостов как blockout. Нужна Studio-проверка коллизий и качества рельефа.
- [x] Убрать серверное перемещение Мохоспина; игроки ходят между постоянными островами.
- [~] Создать статичный turtle-shaped HomeIslandTemplate, отдельные серверные копии и базовый декор. Нужны импорт MeshPart и художественная полировка.
- [ ] Заменить временный дом на качественную модульную модель с тремя стадиями.
- [ ] Переделать ферму: широкие грядки, дорожки, бортики и читаемые стадии роста.
- [~] Создать оригинальные OBJ/MTL-исходники лисы, моли, дома, грядки, моста и острова. Требуется импорт/публикация в Studio и проверка на устройствах.
- [x] Зафиксировать художественное направление Fox Companion: палитра, силуэт, требования к мордочке/ушам/хвосту, сохранение rig-групп и production acceptance gates в `assets/source_models/FOX_ART_BRIEF.md`. Это art brief, не готовая модель/текстура; переработка геометрии и ручная приёмка ещё NOT DONE.
- [~] Blender 4.2 генератор Fox Hero создаёт отдельный sculpted-form mesh с 17 rig-группами, UV, OBJ/MTL/BLEND, четырьмя review views и JSON pivot sidecar. Artifact #145 технически чистый и визуально просмотрен, но не принят; текущий corrective source pass меняет насыщенность coat и интеграцию щёк. Не импортировать в runtime до художественной и Studio acceptance.
- [x] Усилить rig hand-off Fox Hero: добавить pure-Python `fox_rig_contract.py`, который сверяет все 17 групп, runtime names, конечные 3D pivot-координаты и attachment references; Blender-генератор теперь валидирует реальные object names перед записью JSON sidecar. CI проверяет контракт без запуска Blender. Реальные object origins, экспорт/импорт и Studio-анимация остаются на ручной приёмке.
- [x] Исправить ориентацию review-пола Fox Hero: Blender создаёт plane в XY, тогда как персонаж использует Y-up; плоскость теперь поворачивается в XZ и CI защищает это от регрессии. Это исправляет основу для корректных контактных теней, но не заменяет реальный Blender-рендер и визуальную проверку.
- [x] Добавить измеримый mesh QA report для 17 частей (vertices/faces, UV layers, материалы, bounds); сборка останавливается при пустой геометрии, отсутствии UV/материала. Реальный Blender run #109 подтвердил успешную генерацию отчёта.
- [x] Усилить mesh QA: Blender BMesh пересчитывает нормали и отклоняет zero-area faces/non-manifold edges. Реальные Blender runs #109/#117 прошли mesh gate; визуальная оценка пересечений и силуэта остаётся открытой.
- [~] Добавить выразительность Fox Hero без изменения runtime rig: парные изогнутые брови и небольшая улыбка создаются отдельной геометрией, затем объединяются в существующие FoxHead/FoxMuzzle. Тесты фиксируют детали и группировку; визуальная оценка выражения на рендере и мобильной дистанции ещё NOT DONE.
- [~] Начать органическую переработку Fox Hero: голова заменена на плотную деформированную quad-shell с формой щёк/челюсти, мордочка — на tapered multi-section loft вместо стандартных ellipsoid primitives. Добавлены CI-проверки наличия этих генераторов. Это первый procedural sculpting pass, не ручная скульптура; тело, лапы, щёки и другие формы всё ещё требуют художественной переработки и реального Blender-рендера.
- [~] Переработать силуэт туловища Fox Hero: FoxBody и FoxBelly заменены с одиночных ellipsoid primitives на органические Y-axis loft meshes с профилями грудной клетки, сужением плеч/бёдер и отдельной кремовой областью живота. CI проверяет наличие генератора. Оценка силуэта, пересечений и контактных зон по реальным Blender-рендерам ещё NOT DONE.
- [~] Переработать конечности Fox Hero: передние и задние лапы теперь строятся отдельными tapered loft-профилями с более узкими переходами в области щиколотки и объёмом верхней части; paw-end остаётся отдельной формой внутри прежней rig-группы. CI проверяет вызов новых генераторов. Пропорции и силуэт требуют реального Blender-рендера и ручной художественной оценки.
- [~] Переработать хвост Fox Hero: вместо круглого Catmull-Rom tube используется отдельный swept elliptical mesh с независимыми width/depth профилями по центру траектории; кремовый кончик остаётся отдельной FoxTailTip rig-группой. CI проверяет генератор и оба вызова. Стык, силуэт и деформации должны быть приняты по реальному Blender-рендеру.
- [~] Переработать уши Fox Hero: leaf mesh теперь использует 25 профильных колец и 32 сечения, плавное сужение к кончику, лёгкий outward sweep и выпуклый объём. Внутренние розовые вставки остаются отдельными объектами. CI проверяет новую геометрию; силуэт спереди/сбоку и пересечения требуют реального Blender-рендера.
- [~] Усилить выразительность глаз Fox Hero: добавлены изогнутые верхние веки и дополнительные маленькие catchlights; геометрия входит в прежние FoxEyes/FoxEyeSparkles, контракт из 17 групп не меняется. CI проверяет наличие деталей и их группировку. Реальную посадку век и читаемость взгляда необходимо принять по Blender-рендеру.
- [~] Fox Hero Blender visual gate: #109/#117/#145/#163/#173/#187 создали review packages. #187: цветовое направление предварительно принято, но художественный финал отклонён из-за капсульных лап, sock-like paw caps и зернистого fur shader. Следующий source pass интегрирует paws в оранжевый силуэт и снижает procedural grain; source-contract tests обновлены. Ожидается новый render и manual acceptance.
- [x] Soft-fur shader contract: `soft_fur`/`smooth` metadata and Sheen 0.08 are covered by tests. Current Fox Hero micro-relief is Noise scale 10, Detail 1, Bump strength 0.002/distance 0.001 (reduced after #187 manual review); next render must confirm gameplay-distance readability.
- [~] Добавить художественные пряди на лбу Fox Hero: одиночный ellipsoid ForeheadTuft заменён тремя layered curved-plume формами (центральная и две боковые), объединяемыми в FoxHead; runtime rig contract из 17 групп сохранён. CI защищает наличие трёх прядей. Их читаемость, пересечения с ушами и открытость глаз нужно проверить на реальных Blender-рендерах.
- [~] Детализировать лапы Fox Hero: добавлены по три небольших изогнутых разделителя пальцев на каждой лапе, без когтей, с отдельным приглушённым paw_detail материалом. Все детали входят в существующие группы четырёх конечностей; 17-групповой rig contract сохранён. CI проверяет геометрию и группировку; реальная видимость и контакт с землёй требуют Blender-приёмки.
- [~] Сгладить переход хвоста Fox Hero: кремовый FoxTailTip теперь начинается в точном конечном центре и сечении оранжевого FoxTail, после чего сужается через пять эллиптических профилей. Два rig-объекта сохранены. CI защищает параметры стыка; отсутствие шва и корректность бликов должны быть подтверждены Blender-рендером.
- [x] Зафиксировать текущую геометрию шести исходных OBJ-моделей и добавить CI-бюджеты вершин/граней; это предварительный контроль размера, не замена мобильному профилированию в Studio.
- [x] Очистить шесть OBJ от нулевых по площади граней; добавить CI-проверку, чтобы вырожденные треугольники не возвращались в исходные модели.
- [x] Зафиксировать имена и состав OBJ-групп лисы и моли автоматическим контрактом с rig import mapping; случайное переименование анимируемых частей теперь блокируется CI.
- [x] Зафиксировать исходные габариты шести OBJ, оси и импортные якоря; CI ловит случайное изменение масштаба, а README фиксирует source-space габариты и оси и необходимость Studio-проверки шейдинга.
- [x] Добавить crease-aware angle-weighted normals на каждый угол полигонов во все шесть OBJ; порог 50° сохраняет жёсткие рёбра, тесты проверяют единичные нормали и корректные ссылки. Требуется визуальная проверка художником.
- [~] OBJ Validator теперь дополнительно вычисляет площадь каждого UV-полигона и отклоняет схлопнутые UV faces; CI проверяет нулевые и корректные площади. Проверка пересечений островов и texel density остаётся визуальной задачей.
- [~] Добавлен Blender UV review renderer: импортирует только preview OBJ, назначает временный checker material, автоматически выставляет камеру/свет и сохраняет PNG + .blend review scene; CI проверяет Python-контракт и защиту выходных файлов. Это подготовка к визуальной диагностике, не художественная приёмка. Blender 4.2 runtime, реальный render, ручная проверка UV, текстуры и Studio-приёмка остаются NOT DONE.
- [~] Создать единый HUD и нижнюю навигацию: Остров / Ферма / Питомцы / Карта. Нужна Studio-проверка.
- [x] Отключить legacy HUD; новый GiantbackHUD встроен в place. Требуется визуальная проверка в Studio.
- [x] Исправить область видимости HUD-callbacks: `renderCity` и `renderPets` теперь захватывают локальные `getObjective`/`showToast`, а не обращаются к отсутствующим глобальным функциям; place build CI успешно.
- [x] Исправить мобильную верхнюю панель HUD: ширина бренда и ресурсов теперь рассчитывается из доступного пространства с фиксированным зазором, без наложения на узких экранах; place build CI успешно.
- [x] Добавить регрессионные тесты неперекрытия верхней панели и расчёта геометрии на поддерживаемых ширинах 375–699 px; workflow тестов прошёл успешно.
- [x] Добавить регрессионный тест порядка forward declarations для HUD-renderers; тестовый workflow успешно прошёл.
- [x] Исправить гонку таймеров уведомлений HUD: старое уведомление больше не скрывает новое; анимация предыдущего toast отменяется. Успешная CI-сборка HUD-коммита.
- [x] Добавить регрессионные тесты для toast-гонки и высоты панели на коротких экранах; оба CI workflow для тестового коммита прошли успешно.
- [x] Удалить overlap-based PersonalCities и клиентское скрытие соседей; сервер выдаёт отдельные острова.
- [x] Ввести восемь серверных слотов, личный HomeSpawn и освобождение слота при выходе.
- [x] Перенести сохранение city в island через schemaVersion 5 с совместимостью старых профилей.
- [x] GitHub Actions: 110 контрактных тестов, сборка place, проверка 69 именованных объектов и 4 встроенных скриптов; артефакт загружен.
- [~] Fox Scout: три персональных cache anchors, локальный Highlight/ProximityPrompt, золотая дорожка отпечатков лап с маршрутами вокруг деревьев и scent motes, серверная проверка и фиксированные награды; CI/Studio проверка ожидается.
- [~] Настроить максимальное число игроков в Roblox place на 8 и проверить все слоты в Studio.
- [ ] Проверить UI на 375 px, PC и gamepad.

## Этап 2. Первый законченный игровой цикл
- [~] Ввести первые персональные источники дерева и камня на домашнем острове; валюты ещё нет.
- [~] Добавить серверный сбор дерева ×3 и камня ×2 с персональными 60-секундными cooldown и сохранением.
- [~] Реализовать первый восстанавливаемый мост: призрачный blueprint → сбор 5 дерева и 3 камня → открытый проход. Нужен Studio playtest.
- [~] Открыть лес как первый постоянный биом: общий хаб и три точки тайников уже созданы; нужна полная геометрия/экспедиция и Studio-проверка.
- [~] Реализовать первую способность лисёнка: три серверных тайника, локальная золотая метка, дорожка отпечатков лап, MoonSeed, цикл ресурсов и короткая анимация нюха; нужна Studio-проверка.
- [~] Реализовать способность лунной моли: личное раскрытие скрытого MoonBloom, локальная подсветка/Prompt, серверная проверка, MoonPetal ×2 и сохранение открытия; нужна Studio-проверка.
- [~] Реализовать первую совместную экспедицию: Fox находит следы у древних корней, Moth зажигает руны, личный Moon Gate открывает секретную поляну со StarShard ×1; нужна Studio-проверка и reconnect-тест.
- [~] Связать первые материалы с ремонтом персонального моста.
- [~] Сохранять и восстанавливать bridge + Fox Scout: активный тайник, cooldown и счётчик в schemaVersion 6; нужна проверка DataStore/reconnect.

## Этап 3. Город и строительство
- [x] Выделить восемь непересекающихся персональных островных слотов в каждом сервере.
- [ ] Реализовать build mode с предпросмотром, сеткой и поворотом.
- [ ] Добавить размещение, перемещение и удаление своих объектов.
- [ ] Проверять границы, коллизии, стоимость и права на сервере.
- [ ] Сохранить здания и расширения.
- [ ] Добавить 15+ качественных зданий/декораций.
- [ ] Реализовать три уровня дома и визуальные улучшения.

## Этап 4. Ферма
- [~] Сохранение четырёх записей грядок и прототип моркови — legacy, не считается финальной фермой.
- [ ] Перепроектировать ферму на новой карте.
- [ ] Добавить четыре культуры и собственные стадии роста.
- [ ] Добавить полив, сбор и понятный таймер.
- [ ] Добавить три визуальных уровня фермы и теплицу.
- [ ] Связать урожай с рецептами, строительством и питомцами.

## Этап 5. Существа
- [~] Fox и Moth получили расширенные Parts-based rig blockout-модели: анатомические детали, слоистые крылья, морду, лапы и отдельные точки движения; финальный импорт OBJ/MTL в Roblox Studio ещё не выполнен.
- [~] Подготовлены два оригинальных OBJ/MTL source mesh и улучшенные rig blockout для Fox/Moth; импорт MeshPart и ещё четыре вида остаются NOT DONE.
- [~] Добавить idle/follow и базовые анимации Fox/Moth; Fox уже получает короткий sniff/tail-wag при поиске, Moth — усиленные взмахи крыльев, пульсацию света и локальный 12-искровый burst при MoonBloom/MoonGate; полноценные walk/run/ability-анимации и Studio-проверка ещё впереди.
- [ ] Добавить коллекцию, экипировку и способности.
- [ ] Сделать гарантированные способы приручения.
- [ ] Проверить отсутствие визуальных дубликатов и багов после респавна.

## Этап 6. Экспедиции и бой
- [ ] Добавить лес и каменный биом как законченные зоны.
- [ ] Создать базовые инструменты, оружие и броню.
- [ ] Добавить врагов с читаемыми атаками.
- [ ] Реализовать кооператив 1–4 игрока.
- [ ] Создать одно полноценное подземелье с головоломкой и боссом.
- [ ] Выдавать серверно-проверяемые награды.

## Этап 7. Социальность и монетизация
- [ ] Посещение городов друзей.
- [ ] Права гостей и безопасная совместная стройка.
- [ ] Совместное прохождение подземелья.
- [ ] Магазин фиксированной косметики.
- [ ] Supporter Pass и корректная обработка покупок.
- [ ] Проверить все Roblox policies; платные случайные предметы не добавлять.

## Этап 8. Release Gate
- [ ] Пять-десять новых тестеров проходят первый цикл без объяснений.
- [ ] Проверены миграция и сохранения.
- [ ] Проверены два и более игрока, гостевые права и кооператив.
- [ ] Проверены PC/mobile/gamepad.
- [ ] Проверена производительность на слабом мобильном устройстве.
- [ ] Нет критических ошибок, дубликатов наград и потери построек.
- [ ] Иконка, thumbnails, трейлер и описание соответствуют реальному gameplay.
- [ ] Только после этого — публичный 1.0.

## Правило завершения
Не расширять scope до закрытия текущего этапа. Не ставить [x] без теста. Каждый PR обновляет этот Roadmap.
