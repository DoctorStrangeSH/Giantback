## Монеты за боевые победы

- [x] Добавить небольшие разовые Coins к восьми существующим наградам Grove и Rootvault.
- [x] Использовать сохранённый `completedCombatEncounters`: повторная победа не фармится повторно.
- [x] Ограничить начисление свободным местом кошелька и синхронизировать UI сразу после победы.
- [x] Сохранять предмет, Coins и флаг встречи одной операцией; при ошибке DataStore откатывать все изменения.
- [x] Добавить контрактные проверки сумм, идемпотентности, лимита кошелька и отката.
- [ ] Roblox Studio: проверить все восемь наград, повторную доставку, перезаход, почти полный кошелёк и отказ DataStore.

## Сезонное событие — Фестиваль урожая (23.11–08.12 UTC)

- [x] Добавить повторяющееся ежегодное окно события с расчётом по UTC, без зависимости от часового пояса игрока.
- [x] Сохранять очки фестиваля и полученные рубежи в профиле (schema v14); безопасно переносить старые профили.
- [x] Начислять очки только после серверно подтверждённых действий: сбор ресурсов, ферма, рынок, питомцы, тайники, ремесло и бой.
- [x] Добавить три рубежа прогресса: 20 очков — 30 Coins; 50 — 1 StarShard; 100 — 80 Coins + 2 StarShard.
- [x] Встроить прогресс, даты события, статусы рубежей и кнопку получения наград в существующий дневник.
- [x] Объединить монеты, осколки и статусы получения в одно сохранение с полным откатом при ошибке DataStore.
- [ ] Roblox Studio: проверить начисление очков по всем действиям, перезаход, границы окна UTC, частичное/полное получение, повторный запрос и отказ DataStore.
- [ ] Визуальный сезонный декор мира, уникальные питомцы/яйца и магазин фестивальных предметов — следующие подэтапы, NOT DONE.

## Недельные испытания — первая версия (23.11.2026)

- [x] Добавить ротацию из трёх недельных целей с обновлением по понедельникам UTC.
- [x] Сохранять выбранные цели, прогресс и факт получения награды в профиле (schema v13).
- [x] Подбирать доступные цели с учётом открытых питомцев, лисёнка и меча; базовые сбор, ферма и рынок доступны всем.
- [x] Начислять прогресс только через серверные события: сбор, ферма, торговля, питомцы, тайники и победы в бою.
- [x] Добавить отдельные карточки прогресса в дневник и кнопку недельного сундука.
- [x] За полное выполнение выдавать сумму наград выбранных целей и 1 звёздный осколок.
- [x] Сохранять монеты, осколок и факт получения одной операцией; откатывать все три значения при ошибке DataStore.
- [ ] Roblox Studio: проверить смену недели, повторный вход, разные открытия профиля, прогресс всех типов, повторный Claim и отказ DataStore.

## Баланс ежедневных заданий — сложность и честные награды (23.11.2026)

- [x] Разделить 12 заданий на лёгкие (10 Coins), средние (15 Coins) и сложные (20 Coins).
- [x] Выбирать подборку с приоритетом разнообразия сложности: по одному заданию из каждого доступного уровня.
- [x] Для новых игроков без сложных заданий добирать подборку средними целями, а не искусственно повышать сложность.
- [x] Не ставить в один день две цели одной категории, пока доступны другие категории: сбор, ферма, рынок, питомцы, исследование, ремесло и бой.
- [x] Рассчитывать награду за день по сумме трёх заданий; бонусы серии +20 / +60 Coins добавляются поверх.
- [x] Показывать сложность и индивидуальную награду на каждой карточке, а итог — на кнопке получения.
- [x] Сохранить серверный выбор, проверку выполнения, атомарное начисление и откат при ошибке DataStore.
- [ ] Roblox Studio: проверить новые и развитые профили, разные подборки, категории, фактическое время выполнения, награду и серии.

## Серия ежедневных заданий — мягкие бонусы (23.11.2026)

- [x] Сохранять текущую серию, лучший рекорд и дату последнего завершённого дня в профиле.
- [x] Засчитывать серию только после выполнения всех трёх ежедневных заданий и успешного получения награды.
- [x] Продолжать серию при выполнении заданий в соседние UTC-дни; после пропуска дня следующая завершённая дата начинает серию заново.
- [x] Выдавать дополнительный бонус +20 Coins за третий день подряд и +60 Coins за каждый седьмой день серии.
- [x] Объединить обычную награду и бонус серии в одно сохранение; при ошибке DataStore откатывать валюту, серию и дату вместе.
- [x] Показывать текущую серию, личный рекорд и ближайшую награду в дневнике.
- [ ] Roblox Studio: проверить переходы 2→3, 6→7, 7→8, пропуск дня, повторный запрос и отказ DataStore.

## Ежедневные задания 2.0 — ротация и доступность (23.11.2026)

- [x] Расширить пул до 12 заданий: сбор ресурсов, древесины и камня; посадка и сбор урожая; торговля; разведка тайников; кормление и игры с питомцем; создание меча; улучшение инструмента; победа в бою.
- [x] Каждый UTC-день выбирать три задания детерминированно для игрока: один и тот же набор сохраняется при перезаходе и на разных серверах.
- [x] Учитывать прогресс открытия: задания на питомцев, инструменты и бой не попадают в список, пока соответствующие возможности не открыты.
- [x] Сохранять версию схемы, выбранные ID заданий, прогресс и получение награды; поддержать мягкую миграцию прежнего дневного набора.
- [x] Начислять прогресс только после успешного серверного действия; клиент отображает только серверные атрибуты.
- [x] Оставить общую награду 40 Coins за все три задания, с защитой от повторного получения и откатом при ошибке DataStore.
- [x] Обновить карточки в существующем дневнике: название, описание, счётчик и состояние.
- [ ] Roblox Studio: проверить разные уровни прогресса аккаунта, стабильность набора, перезаход, переход UTC-дня, повторные запросы и ошибки сохранения.

## Ежедневные задания — первая версия (23.11.2026)

- [x] Добавить три серверных задания: собрать 3 ресурса, продать 3 единицы урожая, найти тайник с лисёнком.
- [x] Обновлять прогресс только после подтверждённых игровых действий; клиент не может самостоятельно начислить прогресс или награду.
- [x] Обновлять задания ежедневно по UTC и сохранять дату, прогресс и факт получения награды в профиле.
- [x] Добавить кнопку получения общей награды 40 Coins после выполнения всех трёх заданий.
- [x] Проверять доступность сохранения, кошелёк, повторное получение и конкурирующие операции экономики на сервере.
- [x] Встроить карточки заданий в существующую вкладку «Дневник», без дополнительной вкладки.
- [ ] Roblox Studio: проверить прогресс трёх заданий, обновление дня, перезаход, повторные запросы, переполненный кошелёк и отказ DataStore.

## Разовые награды за исследование (23.11.2026)

- [x] Добавить Coins за первые открытия лунного прохода, звёздной реликвии, Кристальной пещеры, древнего сердца, трёх рун, тайника, Эхо-камеры и призматического семени.
- [x] Использовать уже сохраняемые флаги прогресса игрока: повторный визит не выдаёт награду повторно.
- [x] Синхронизировать баланс через общий атрибут кошелька и ограничить начисление MAX_COINS.
- [x] Показывать сумму монет прямо в сообщении об открытии/находке.
- [x] Не менять предметные награды, требования к питомцам, последовательность головоломок или доступ к локациям.
- [ ] Roblox Studio: пройти цепочку с новым профилем, перезайти на каждом этапе, повторить взаимодействия, проверить баланс и сохранение.
- [ ] Проверить начисление при почти полном кошельке и при временной ошибке DataStore.

**Разовые бонусы:** следы Moon Gate — 3; открытие прохода — 5; звёздная реликвия — 6; вход в Кристальную пещеру — 8; древнее сердце — 8; три руны — 5; тайник — 10; Эхо-камера — 8; призматическое семя — 15 Coins.

## Улучшения фермы за Coins (23.11.2026)

- [x] Добавить серверные цены улучшения: уровень 1 → 2 за 60 монет; уровень 2 → 3 за 150 монет.
- [x] Уровень 2 открывает грядки №2 и №3; уровень 3 открывает грядку №4.
- [x] Проверять баланс, максимальный уровень, готовность профиля и доступность DataStore на сервере.
- [x] Сохранять новый уровень и списание монет одной операцией профиля; откатывать оба значения при ошибке сохранения.
- [x] Использовать общую блокировку экономики, чтобы покупка семян, улучшение фермы и продажа урожая не пересекались.
- [x] Добавить карточку улучшения с ценой, эффектом и текущим числом доступных грядок.
- [ ] Roblox Studio: проверить уровни 1→2→3, новые грядки, нехватку монет, повторные запросы, перезаход и отказ DataStore.

## Магазин семян за монеты (23.11.2026)

- [x] Добавить серверный каталог наборов семян с фиксированными ценами и количеством.
- [x] Разрешить покупку четырёх базовых культур только за заработанные Coins.
- [x] Проверять баланс, допустимый вид семян, лимит стопки и готовность профиля на сервере.
- [x] Сохранять покупку вместе с инвентарём и валютой; при ошибке сохранения возвращать монеты и семена.
- [x] Добавить компактные кнопки покупки в карточки культур на вкладке «Ферма».
- [x] Показывать текущий баланс и стоимость набора до покупки.
- [ ] Roblox Studio: проверить покупку каждого набора, нехватку монет, лимит семян, повторные запросы, перезаход и отказ при недоступном DataStore.
- [x] Следующий этап выполнен: улучшения фермы добавлены в раздел выше.
- [ ] Следующий фокус: Studio-приёмка экономики, баланс цен и темпа открытия грядок.

**Наборы:** морковь — 3 семени за 12 монет; клубника — 3 за 21; тыква — 2 за 20; капуста — 2 за 16.

## Фермерский рынок и первая игровая валюта (23.11.2026)

- [x] Добавить постоянную валюту Coins в профиль игрока и синхронизировать её с UI.
- [x] Создать на личном острове отдельную визуальную торговую стойку с вывеской «РЫНОК», прилавком, навесом и декоративным урожаем.
- [x] Добавить серверное действие «Продать весь урожай» с проверкой владельца острова.
- [x] Установить прозрачные цены: морковь — 4, клубника — 7, тыква — 12, капуста — 9 монет.
- [x] Продавать только собранные культуры, не семена и не материалы; при отсутствии урожая сообщать об этом.
- [x] Защитить от повторного одновременного запроса; ограничить баланс 2 000 000 000 монет.
- [x] Сохранять валюту в DataStore; если сохранение продажи не удалось, вернуть урожай и прежний баланс.
- [x] Показывать баланс в карточке «Мой остров».
- [x] Добавить контрактные тесты на цены, права доступа, сохранение и откат.
- [ ] Roblox Studio: проверить продажу каждого вида урожая, продажу нескольких культур, пустой рюкзак, повторный запрос, чужого игрока и перезаход.
- [x] Магазин семян и улучшения фермы за Coins реализованы в PR #26.
- [ ] Следующий этап: Studio-приёмка экономики и настройка баланса по реальному темпу игры.

## Личный остров — первый склад и хранилище ресурсов (23.11.2026)

- [x] Добавить склад как четвёртый размещаемый объект личного острова с отдельным ghost preview.
- [x] Построить визуальную модель склада: фундамент, деревянный корпус, дверь, балки и вывеска.
- [x] Стоимость: 10 дерева + 8 камня; демонтаж возвращает 5 дерева + 4 камня.
- [x] Добавить серверное хранилище на 120 единиц: дерево, камень, железная руда, слитки и четыре вида урожая.
- [x] Реализовать у склада отдельные ProximityPrompt-действия «Сложить материалы» и «Забрать материалы»; владелец проверяется сервером.
- [x] Сохранять содержимое склада в профиле и восстанавливать при повторном входе.
- [x] Запретить демонтаж склада, пока внутри остаются предметы, чтобы не потерять ресурсы.
- [x] Отображать вместимость и остатки основных материалов в карточке «Мой остров».
- [x] Добавить контрактные тесты для строительства, хранения, сохранения и защиты от потери содержимого.
- [ ] Roblox Studio: проверить размещение, prompt, частичное заполнение лимита, перенос, сохранение, отказ чужому игроку и демонтаж пустого/непустого склада.
- [ ] Следующий этап: торговая лавка — продажа урожая за монеты и сохранение валюты.

## Первый настоящий домик — каталог строительства (23.11.2026)

- [x] Добавить «Уютный домик» как третий объект строительства: фундамент, стены, дверь с ручкой, окна, двускатная крыша, дымоход и ступенька.
- [x] Добавить клиентский ghost preview домика с проверкой материалов до подтверждения.
- [x] Стоимость домика: 8 дерева + 6 камня; демонтаж возвращает 4 дерева + 3 камня.
- [x] Разрешить домик в серверной валидации, нормализации профиля, сохранении, восстановлении, переносе и демонтаже.
- [x] Добавить контрактные тесты на каталог, визуал, стоимость и восстановление.
- [x] GitHub Actions Validate Giantback place #2291 — SUCCESS; PR #23 объединён с main.
- [ ] Roblox Studio: проверить совпадение ghost preview и модели, ориентацию крыши, дверь/окна, коллизии, перенос, демонтаж и сохранение после повторного входа.
- [ ] Следующий этап: расширить каталог функциональными постройками — склад и торговая лавка с игровыми взаимодействиями.

## Редактирование построек — перемещение и демонтаж (23.11.2026)

- [x] Показывать список построенных дорожек и клумб с координатами и поворотом в карточке «Мой остров».
- [x] Добавить перенос существующей постройки через тот же предпросмотр и сетку, без повторного списания ресурсов.
- [x] При переносе исключать исходную клетку из проверки занятости; сохранять выбранный поворот.
- [x] Добавить демонтаж с возвратом 50% исходной стоимости: дорожка — 1 дерево; клумба — 2 дерева и 1 камень.
- [x] Повторно проверять сервером владельца, дистанцию, индекс объекта, клетку и ресурсы; сохранять изменения профиля.
- [x] Синхронизировать ID, координаты и поворот каждой постройки с HUD-атрибутами.
- [x] Добавить контрактные тесты управления, перемещения и возврата материалов.
- [x] GitHub Actions Validate Giantback place #2287 — SUCCESS; PR #22 объединён с main.
- [ ] Roblox Studio: проверить перемещение в исходную/соседнюю клетку, занятые клетки, поворот, демонтаж, возврат материалов, сохранение после повторного входа.
- [ ] Следующий этап: подтверждение демонтажа и расширение каталога реальными объектами островного города.

## Редактор размещения построек — предпросмотр и выбор клетки (23.11.2026)

- [x] Перевести каталог на режим предпросмотра: кнопка предмета больше не строит объект немедленно.
- [x] Добавить локальный полупрозрачный предпросмотр дорожки и клумбы.
- [x] Выбирать клетку наведением мыши или касанием поверхности лужайки; привязать координаты к сетке 4 studs.
- [x] Показывать валидное/занятое/недоступное место разными цветами и сообщениями.
- [x] Добавить поворот на 90°, подтверждение и отмену; клавиатура R/Esc и экранные кнопки.
- [x] Передавать выбранные координаты на сервер; сервер повторно проверяет формат, сетку, дистанцию, занятость, лимит и стоимость.
- [x] Синхронизировать занятые клетки в атрибуте игрока для мгновенной проверки предпросмотра.
- [x] Добавить контрактные тесты клиента и серверной проверки.
- [x] GitHub Actions Validate Giantback place #2282 — SUCCESS; PR #21 объединён с main.
- [ ] Roblox Studio: проверить наведение мыши, касания, поворот, красный/зелёный предпросмотр, отмену и подтверждение.
- [ ] Следующий этап: выбор уже размещённой постройки, перемещение, демонтаж с возвратом части стоимости.

## Строительство личного острова — первая игровая вертикаль (23.11.2026)

- [x] Проверить текущую архитектуру: отдельного свободного режима строительства ещё не было; поле `island.buildings` существовало в схеме сохранения, но не нормализовалось и не отображалось.
- [x] Добавить серверное размещение двух первых предметов: каменная дорожка и цветочная клумба.
- [x] Размещать предмет перед персонажем по сетке 4 studs; направление персонажа задаёт поворот с шагом 90°.
- [x] Проверять сервером владельца острова, расстояние до лужайки, допустимую зону, занятость клетки, лимит 12 предметов и стоимость ресурсов.
- [x] Сохранять ID, координаты и поворот в профиле; восстанавливать декор при входе.
- [x] Добавить каталог в карточку «Мой остров» с ценой и кнопками строительства; поддержать компактную ширину.
- [x] Синхронизировать число построенных предметов с HUD.
- [x] Добавить source-contract тесты на безопасность, сохранение, восстановление, поворот и UI.
- [x] GitHub Actions Validate Giantback place #2278 — SUCCESS; PR #20 объединён с main.
- [ ] GitHub Actions Validate Giantback place.
- [ ] Roblox Studio: проверить оба предмета, сетку и поворот, занятые клетки, недостаток ресурсов, лимит, выход/повторный вход и чужой остров.
- [ ] Следующий этап: режим предпросмотра-призрака, свободный выбор клетки касанием/мышью, перенос/поворот/отмена и демонтаж с возвратом части стоимости.

## Рюкзак и снаряжение — категории ресурсов и мобильные карточки (23.11.2026)

- [x] Переименовать раздел инструментов в понятный игроку «Мой рюкзак», сохранив стабильный ID вкладки и навигацию.
- [x] Разделить содержимое на категории: материалы, семена и урожай, редкие находки, инструменты и оружие.
- [x] Подключить сводки к существующим серверным атрибутам ресурсов; новые источники данных и правила инвентаря не вводились.
- [x] Перестроить карточки топора, кирки и меча для мобильных экранов: описание сверху, действия снизу.
- [x] Сохранить прежние серверные события экипировки, улучшения и создания меча.
- [x] Добавить source-contract тесты для категорий, атрибутов и мобильных действий.
- [x] GitHub Actions Validate Giantback place #2272 — SUCCESS; PR #19 объединён с main.
- [ ] Roblox Studio: проверить 320/375/414 px, длинные названия, заполненные/пустые категории и все действия с экипировкой.
- [ ] Проверить, что прокрутка раздела остаётся удобной при длинном списке ресурсов и снаряжения.

## Коллекция питомцев — мобильные карточки и действия (23.11.2026)

- [x] Перестроить карточки питомцев для узких экранов: портрет, имя, описание, настроение, дружба, уровень и талант идут в читаемом вертикальном порядке.
- [x] Перенести четыре действия в мобильную сетку 2×2; сохранить исходные серверные события и проверки владения/экипировки.
- [x] Добавить индивидуальную цветную подложку портрета для каждого питомца.
- [x] Перестраивать открытую коллекцию при смене ориентации/переходе через breakpoint 620 px.
- [x] Добавить source-contract тесты для мобильной компоновки, действий и смены ориентации.
- [x] GitHub Actions Validate Giantback place #2268 — SUCCESS; PR #18 объединён с main.
- [ ] Roblox Studio: проверить коллекцию на 320/375/414 px, длинные названия/мутации, все четыре действия и смену портретной/альбомной ориентации.
- [ ] Проверить на реальном телефоне, что карточки не перекрывают нижнюю навигацию и прокрутка остаётся удобной.

## Интерфейс — читаемые карточки и понятные инструкции (23.11.2026)

- [x] Измерять заголовки и описания карточек через TextService и автоматически увеличивать высоту при переносе строк.
- [x] Сохранять единый визуальный акцент карточек и адаптировать размеры шрифтов для компактных экранов.
- [x] Переписать инструкции фермы, инструментов, исследования и дневника простым языком с ясными действиями.
- [x] Добавить source-contract тесты для расчёта высоты и ключевых текстов.
- [x] GitHub Actions Validate Giantback place #2265 — SUCCESS; PR #17 объединён с main.
- [ ] Roblox Studio: проверить переносы длинных названий/описаний, высоту карточек, прокрутку и ширину 320/375/768/1920 px.
- [ ] Продолжить редактуру оставшихся текстов питомцев, предметов и заданий по реальным экранам.

## Интерфейс — фокус окон и читаемые значки (23.11.2026)

- [x] Добавить затемнение игрового мира при открытии основного окна; фокусировать окно выше HUD и навигации.
- [x] Закрывать окно одинаково: крестиком, нажатием по затемнённой области, Escape или B на геймпаде.
- [x] Сбрасывать активное состояние навигации при закрытии и проверять имя вкладки перед отрисовкой.
- [x] Сохранять слои окна после обновления ресурсов и повторной отрисовки карточек.
- [x] Подстроить заголовок и кнопку закрытия под компактные экраны; оставить уведомления поверх модального затемнения.
- [x] Заменить emoji-пиктограммы ресурсов и мини-игры питомцев на стабильные символы; синхронизировать последовательность на клиенте и сервере.
- [x] Добавить контрактные тесты для фокуса, способов закрытия, слоёв и значков.
- [x] GitHub Actions Validate Giantback place #2260 — SUCCESS; PR #16 объединён с main.
- [ ] Roblox Studio: открыть каждую вкладку, закрыть всеми способами, проверить мини-игру питомца и масштабирование на 320/375/768/1920 px.
- [ ] Следующий проход: единый стиль карточек, улучшение информационной иерархии и полная редактура текстов всех экранов.

## UI и комфорт исследования — адаптивность, мосты и безопасность (23.11.2026)

- [x] Перестроить HUD под ширину и высоту экрана: компактная шапка, цель, навигация и центральная панель; на узком экране навигация показывает короткие буквенные значки.
- [x] Заменить критичные emoji-иконки, зависящие от платформенного шрифта, на стабильные буквенные/символьные обозначения.
- [x] Расширить настил мостов с 5.2 до 8.2 studs и перенести перила/стойки к новым краям прохода.
- [x] Добавить серверное спасение живого персонажа при падении ниже игровой зоны с возвратом на личный остров/безопасный спавн; предметы и прогресс не теряются.
- [x] Ограничить дальность плавающих надписей и отключить AlwaysOnTop для тренировочной таблички, предупреждений и рун.
- [x] Улучшить несколько подсказок и описаний, обновить тесты адаптивной цели и добавить контракты UI/мира.
- [x] GitHub Actions Validate Giantback place #2256 — SUCCESS; 425+ контрактных тестов пройдены; PR #15 объединён с main.
- [ ] Roblox Studio: 320/375/768/1920 px, безопасные зоны, масштаб шрифтов, все иконки, перекрытие окон, ширина/коллизии мостов, падение с острова и возврат.
- [ ] Провести отдельный русский редакторский проход по всем экранам после визуального просмотра в Studio.

## Боевой отклик — числа урона и визуальное попадание (23.11.2026)

- [x] Передавать клиенту фактически нанесённый сервером урон для обычного комбо и заряженного удара (включая безопасный урон тренировочному манекену).
- [x] Передавать актуальные HP и MaxHealth цели вместе с подтверждением попадания.
- [x] Показывать над противником всплывающее число урона, разный акцент для заряженного удара/финишера и короткую вспышку попадания.
- [x] Эффекты полностью локальные и декоративные; клиент не определяет урон и не меняет HP.
- [x] Добавить source-contract тесты для фактического урона и визуального подтверждения.
- [x] CI Validate Giantback place #2244 — SUCCESS; PR #14 объединён с main.
- [ ] Roblox Studio: проверить читаемость цифр на манекене, Моховичке, нескольких целях и мобильном экране; убедиться, что вспышки не накапливаются.

## Мобильное боевое управление — контекстные кнопки (23.11.2026)

- [x] Разместить пять боевых touch-кнопок компактной сеткой 3+2 выше нижней навигации.
- [x] Показывать боевые кнопки только в игровой боевой зоне, проверяя те же tagged bounds, что и сервер; скрывать при исследовании/строительстве.
- [x] Не менять ввод с клавиатуры, мыши и геймпада или серверные правила урона.
- [x] Покрыть управление, размеры, видимость и проверку зоны source-contract тестами.
- [x] CI Validate Giantback place #2240 — SUCCESS; PR #13 объединён с main.
- [ ] Roblox Studio Edit/Play: подтвердить контекстное отображение кнопок и отсутствие ошибок.
- [ ] Проверить на мобильном эмуляторе 375 px: кнопки не перекрывают HUD, перемещение и меню строительства; при входе/выходе из GroveTraining видимость корректна.
- [ ] Протестировать быстрое переключение между мечом, топором и киркой во время боя на телефоне.

## Меч странника — боевая визуальная синхронизация (23.11.2026)

- [x] Отправлять CombatSwing только после одобрения сервером обычной или заряженной атаки, независимо от попадания.
- [x] Проигрывать отдельное локальное движение экипированного Меча странника во время комбо и заряженного удара.
- [x] Сбрасывать анимацию при новом ударе и перерождении, избегая накопления сдвига и дублирующихся твинов.
- [x] Оставить урон, кулдауны, проверку цели и награды на сервере без изменения механики.
- [x] Добавить контрактные тесты для серверной проверки момента анимации, экипировки и возврата положения меча.
- [x] CI Validate Giantback place #2236 — SUCCESS; PR #12 объединён с main.
- [ ] Проверить в Roblox Studio анимацию меча на R6/R15, комбо 1–3, заряд и переключение на топор/кирку.
- [ ] Проверить визуал на телефоне и при высоком пинге; финальные анимационные ассеты ещё не утверждены.

## Меч странника — крафт и сохранение (23.11.2026)

- [x] Добавить рецепт меча у личного верстака: 2 железных слитка + 6 дерева; сервер проверяет владение станцией, расстояние и материалы.
- [x] Добавить настоящий Tool с клинком, гардой и рукоятью в инвентарь игрока, возможность взять в руки через раздел инструментов.
- [x] Сохранять Sword и выбранный инструмент в существующем профиле schemaVersion >= 11, без замены старых сохранений.
- [x] Добавить карточку с рецептом, статусом и кнопками создания/экипировки в игровом HUD.
- [x] Добавить тесты контракта для рецепта, сохранения, экипировки и сборки.
- [x] CI Validate Giantback place #2232 — SUCCESS; PR #11 объединён с main.
- [ ] Roblox Studio Play: скрафтить, надеть, атаковать манекен/Моховичка, выйти и зайти снова.
- [ ] Проверить крафт и сохранение при двух игроках и на мобильном интерфейсе.
- [ ] Связать визуальную анимацию реального меча с комбо после Studio-проверки; текущее боевое управление SwordShield не заменяется.

## Mossling — живой противник лесной арены (23.11.2026)

- [x] Добавить Моховичка в существующую арену GroveTraining: отдельный силуэт, листва, показатели здоровья и предупреждение атаки.
- [x] Использовать Combat.server.luau: серверная регистрация, преследование, проверки попаданий и урона; без отдельной боевой системы.
- [x] При победе выдавать Stone ×2 каждому участвовавшему игроку только при первом прохождении, с текущей защитой сохранения от повторной награды.
- [x] Восстанавливать противника через 20 секунд; повторная победа не дублирует награду.
- [x] Добавить автоматические контракты для регистрации, боевых параметров, наград и повторного появления.
- [x] GitHub Actions Validate Giantback place #2227 — SUCCESS; PR #10 объединён с main. Studio runtime пока не проверялся.
- [ ] Пройти Roblox Studio Play / 2 players / mobile: атака, преследование, телеграф, награда, повторное появление.
- [ ] Заменить временную модель Моховичка на одобренный MeshPart без потери игрового поведения.
- [ ] Продолжить V2-миграцию рецепта меча с проверкой сохранения и владения.

## Тренировочная арена — первый интегрированный этап (23.11.2026)

- [x] Разместить манекен в игровой зоне GroveTraining, а не в отдельной демо-сцене.
- [x] Использовать серверную обработку обычной и заряженной атаки.
- [x] Запретить награды, преследование игрока и уничтожение манекена; здоровье восстанавливается после паузы.
- [x] Добавить контрактные тесты на расположение, попадания и восстановление.
- [x] CI Validate Giantback place #2224 — SUCCESS (контрактные тесты, сборка и проверка place).
- [ ] Проверить настоящую игру в Roblox Studio.
- [ ] Перенести рецепт и сохранение меча из V2 с учётом текущей версии профиля.
- [x] Добавить Mossling в текущую арену (PR #10, CI #2227); реальная Roblox Studio-приёмка по-прежнему [ ].

## Интеграция `main` и восстановление функций — 23.11.2026

- [x] Перенести игровой Reboot из `feat/combat-c0-contract` в `main` через PR #8, сохранив обе истории Git.
- [x] Проверить автоматическую сборку интеграционного коммита: Validate Giantback place #2210 и #2211 — SUCCESS.
- [x] Проверить положение семи веток относительно `main`; три ветки полностью входят в его историю, четыре пока имеют уникальные коммиты.
- [x] Проверить, что модули `HarvestMotion` и `ResourceNodeVisibility` действительно встроены в сборку.
- [x] Выявить отсутствующие в `main` возможности V2: меч, тренировочный манекен, Mossling; не считать их выполненными.
- [ ] Перенести меч и манекен из V2 без замены текущих скриптов целиком; покрыть серверные ограничения, сохранение и UI тестами.
- [ ] Перенести Mossling и третью ступень инструментов после сверки профиля schemaVersion >= 11 и стоимости рецептов.
- [ ] Проверить уникальные отличия четырёх расходящихся веток, закрыть только обоснованно ненужные ветки после сохранения истории.
- [ ] Пройти Roblox Studio Edit/Play, 2-player и Mobile Device Emulator по `docs/STUDIO_PLAYTEST.md`; CI это не заменяет.
- [ ] Утвердить реальные MeshPart, затем удалить заменённые блок-ауты, не ломая игру.
- [ ] Отметить 1.0 готовой только после полного Release Gate.

## Asset Pipeline 1.0 — Studio import and asset staging

- [x] Add client-only, state-aware first Grove world guidance: after repairing the home bridge, highlight the Fox nest; after equipping Fox, highlight the scouting trail until the first lunar seed/cache is active. Automatically remove previous markers on quest changes; retain server-owned ProximityPrompts and rewards. Studio visual acceptance remains pending.
- [x] Clarify post-bridge newcomer flow in the live objective HUD: find the Fox nest and use its friendship prompt, equip Fox from Pets if necessary, search the trail for the first lunar seed, follow an active golden-pawprint cache route, then proceed toward Moth. Add contract coverage for ordered hints; Studio UX acceptance still pending.
- [x] Improve first-minute onboarding: show first bridge objective with live wood/stone counts and actual home-pile interaction hint; first owner-only home pile pickups provide 5 wood and 3 stone before bridge repair so the player can complete their first bridge without waiting for the 60-second cooldown. Normal post-bridge pickups remain 3/2 with 60-second cooldown; Studio UX playtest remains pending.
- [x] Bundle a read-only Roblox Studio Edit/Play preflight and Russian 1.0 gameplay/multiplayer/mobile acceptance checklist with the downloadable Giantback.rbxlx artifact; no actual Studio playtest or imported MeshPart approval claimed.
- [x] Extract level-driven companion growth scaling and cosmetic mutation tints/highlights/legendary aura into CompanionAppearance ModuleScript; preserve live rig animation recapture and server-owned mutation rolls.
- [x] Extract Moth stardust attachment creation and bond/personality refresh into MothStardust ModuleScript; fix misplaced emitter lookup and missing lilacLight/moon palette keys.
- [x] Extract local-only sleeping Z glyph effects and cancellation/cleanup into CompanionSleepVisuals ModuleScript; leave the 45-second idle threshold in CompanionActivity.
- [x] Extract companion world petting prompts and friendship burst VFX to CompanionInteractions ModuleScript; fix missing CrystalWisp affection tint and retain server-validated rewards.
- [x] Extract companion follow-position calculations (local Moth personality orbit, Fox offset, per-player bobbing and frame-rate-independent smoothing) to CompanionFollow ModuleScript; preserve follower ownership and lifecycle in Album.client.luau.
- [x] Extract per-player companion curiosity timing, rest (12s) and sleep (45s) thresholds into client-only CompanionActivity ModuleScript; keep the follower loop, visual animation and server-owned progression unchanged.
- [x] Extract Fox, Moth and CrystalWisp procedural body/wing/tail/ear/face animation into CompanionAnimation ModuleScript; retain follower lifecycle, growth/mutation states and ability clocks in Album.client.luau.
- [x] Extract harvest hit progress, cracks, chips, reward pickups and final impact VFX into client-only HarvestFeedback ModuleScript; keep authoritative harvest events and node geometry orchestration in Album.client.luau.
- [x] Extract local harvest camera feedback and character/tool swing sequencing into ReplicatedStorage/HarvestMotion ModuleScript, preserving per-player timing guards and server-authoritative item awards.
- [x] Extract client-only resource visibility/cooldown scheduler to ReplicatedStorage/ResourceNodeVisibility ModuleScript; preserve generation guards and late-spawn node hiding.
- [x] Fix resource node lookup forward declaration in Album.client.luau so earlier reward and harvest callbacks use the local function.
- [x] Extract approved Fox/Moth template selection and fallback policy from Album.client.luau into a ReplicatedStorage ModuleScript, and embed it through build.py with regression coverage.
- [x] Require imported Fox/Moth Body and animated Tail/Wing MeshParts to be direct children compatible with current procedural animation; keep fallback when incomplete.
- [x] Deduplicate Moth stardust particle-rate calculation and refresh particles on personality changes as well as friendship-stage changes, with regression tests.
- [x] Retire disabled GiantbackJournal UI and its old quest polling; migrate companion collection (including CrystalWisp), levels/XP, growth, mutation names, talents, scout readiness and rare material counters into active GiantbackHUD.
- [x] Keep active Album client-only animation, harvesting effects, local prompts and follower logic intact, with automated regression contracts.
- [x] Fix missing ore, ingot and smelter-local values in active Tools UI rendering.
- [x] Organize the repository asset catalogue by editable sources, imported model exports, textures, icons, audio, animation sources and references.
- [x] Validate six original OBJ/MTL source pairs and source manifest in GitHub Actions.
- [x] Add a Roblox Studio Command Bar organizer for already imported models with dry-run mode, duplicate prevention and explicit destinations.
- [x] Cover organizer naming, safe defaults, destination checks and non-destructive behavior with source contract tests.
- [~] Add read-only Roblox Studio rig diagnostics for the six-source import pipeline: Fox/Moth structure, MeshIds, moving parts, collision, bone/joint conflicts and scale; real Studio model import and manual animation/art approval remain NOT DONE.
- [ ] Import source models into Roblox Studio, confirm materials, scale, collisions and joints.
- [ ] Publish approved MeshParts and record asset IDs and ownership in asset manifest.
- [~] Fox/Moth client followers can opt into approved MeshPart templates under ReplicatedStorage/AssetLibrary/Models/Companions; strict Studio-approval and rig-compatibility attributes preserve the existing Parts fallback. Real Studio import and acceptance remain NOT DONE.
- [ ] Verify Fox tail and Moth wings, mobile rendering and multi-player visibility in Studio.

## Ironworking 1.0 — Ore and smelting

- [x] Two personal iron-ore resource nodes in the Dusk biome with pickaxe validation, five-hit harvesting, per-player cooldowns and configured rewards.
- [x] Personal island furnace with a 60-second server-timed recipe (3 ore + 2 wood → 1 ingot).
- [x] Server checks furnace ownership and interaction distance; no client-side reward grants.
- [x] Persist pending smelting state so progress survives reconnects and offline time.
- [x] Show ore, ingot counts and smelting status in the Tools panel.
- [x] Validate 189 automated tests, Roblox place build, generated-place validation and artifact upload in the latest canonical GitHub Actions run.
- [ ] Studio playtest: verify ore placement, furnace access, timer, reconnect, collection and duplicate-claim prevention.
- [ ] Add multiple recipes, fuel choices and furnace upgrades after the first smelting loop is playtested.

## Harvesting 2.0 — Starter tools and multi-hit resource nodes

- [x] Add persistent Axe/Pickaxe ownership, selected tool and level-1/2 progression to player profiles (schema v9, monotonic version writes).
- [x] Restore tools on join and respawn; track actual tool equips so the server validates the tool currently held.
- [x] Add a dedicated Russian Tools tab with equip and upgrade actions.
- [x] Add an owner-only personal workbench with server-side distance checks for upgrades.
- [x] Add two forest wood nodes and two dusk stone nodes with distinct tree/rock visuals.
- [x] Require the correct equipped tool for each resource family.
- [x] Add server-authoritative multi-hit progress with a 0.4-second per-node hit throttle and faster harvesting at tool level 2.
- [x] Add client-local hit progress display; collected-node visibility remains per-player.
- [x] Add regression tests for tool persistence, equip validation, multi-hit state, workshop distance/material costs and local hit feedback.
- [x] Add two iron-ore veins to the Dusk island; each requires the pickaxe and five hits, yields two ore, and respawns after 10 minutes per player.
- [x] Add distinct iron-vein visuals and resource-specific interaction labels.
- [x] Fix resource reward handling so each node grants its configured amount (wood/stone now correctly grant ×2; iron grants ×2).
- [x] Add a personal owner-only furnace: 3 IronOre + 2 Wood starts a 60-second smelt; the iron ingot is granted only when collected after completion.
- [x] Persist in-progress smelting timestamps and pending output across rejoin; add HUD material counts and smelter status.
- [~] Implement harvesting tool swing/impact, hit-progress/crack, break/regrowth and reward feedback in consolidated PR #7; awaiting Studio acceptance and merge into the canonical branch.
- [ ] Studio playtest: verify Backpack switching, correct-tool checks, hit progress, respawn restoration, upgrade cost consumption and save/rejoin.
- [ ] Add mobile-friendly touch controls and tool selection UX after Studio testing.

## Repository consolidation — profile safety

- [x] Prevent schema-v6 saves from downgrading a newer profile schema marker.
- [x] Include IronOre and IronIngot in the current inventory load/sync/save registry so existing V2 values are not silently omitted.
- [x] Update contract tests for monotonic schema versions and preserved island-building payload.
- [x] Update generated-place validation marker for the forward-compatible schema assignment.
- [x] Confirm fresh Validate Giantback run #1223 after the validator update; tests, place build, generated-place validation and artifact upload all passed.
- [x] Port starter tool ownership/equipment and server-authoritative multi-hit wood/stone gathering.
- [x] Port smelter state/actions and iron ore processing; owner-only furnace, persistent timer and collect-after-completion flow are implemented.
- [~] Combat C1 + first expedition/boss slice are implemented in PR #7: server-owned three-strike sword combo (18/22/32 damage, 1.15s chain window, larger finisher with authoritative knockback; bosses resist 72% of the impulse), hold-and-release charged strike (0.45–1.6s, 30–52 server-calculated damage, 1.35s recovery), first server-owned companion combat skills (Fox: nearest same-region enemy for 24 damage; Moth: heal same-region allies within 14 studs for up to 18 HP; shared 14s cooldown), telegraphed enemy AI, block/dodge, PC/gamepad/touch inputs, per-contributor idempotent rewards, Grove training arena, Forest Trial rune puzzle, three-room Rootvault and three-phase Seal Keeper boss. Client presentation includes enemy/boss health UI, boss warnings/phase VFX, procedural placeholder poses, plus first confirmed Fox target-impact and Moth healed-ally VFX (local-only spark bursts and ground pulses; server supplies targetId/healedUserIds). Latest head passed 236 contract tests, Roblox place build and generated-place validation (71 named instances, 6 embedded scripts); artifact `Giantback-visual-build` uploaded by Actions run #1641. Studio acceptance remains outstanding. Roblox Studio acceptance remains NOT DONE: verify rig animation, pathfinding, hitbox alignment, VFX streaming/mobile readability, multiplayer isolation, reconnect persistence, dungeon traversal and boss phases.

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
- [x] Add four distinct procedural crop silhouettes (carrot root, strawberry berries, pumpkin fruit/vine, cabbage head/leaves).
- [x] Add five server-timestamp-driven visual growth stages with progressive scale and mature-fruit reveal.
- [x] Persist selected crop ID inside the saved island farm profile (not only in the live session).
- [x] Complete Python contract suite and Roblox place validation; latest Validate Giantback run #1192 passed.
- [ ] Replace Parts-based crop blockout with polished MeshPart assets and crop-specific animation/harvest feedback.
- [ ] Studio playtest save/rejoin, offline growth, two rapid harvest requests and all four crop types.

## Farm Plots — Readability visual pass

- [x] Добавить четыре деревянных бортика на каждую грядку; борта визуально отделяют почву от дорожек.
- [x] Добавить три неглубокие борозды на каждую грядку, выровненные с поверхностью земли.
- [x] Все декоративные детали создаются без коллизий, касаний и query; интерактивность остаётся на отдельном PromptAnchor.
- [x] Добавить source-contract test для бортиков, борозд и их высоты.
- [x] Generated place validation после обновления визуальных стадий прошла в CI.
- [ ] Roblox Studio playtest: проверить посадку/сбор, prompt, рост культуры, камеру и читаемость на мобильном экране.
- [ ] Заменить процедурный Parts-blockout четырёх культур на авторские MeshPart-модели; текущая геометрия — рабочий прототип, не финальный арт.

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
- [~] Коллекция и экипировка Fox/Moth, локальное следование, исследовательские и боевые способности реализованы; требуется Studio-проверка и расширение до шести видов.
- [~] Первые два питомца приручаются гарантированными встречами в мире, без платных случайных яиц; способы получения ещё четырёх видов остаются NOT DONE.
- [~] Добавить индивидуальную прокачку компаньонов 1–5: сохранение schema v11, серверный XP за подтверждённые действия, рост боевых способностей и индикатор уровня/опыта в альбоме. GitHub Actions #1682: 244 контрактных теста PASS, Roblox place build PASS, generated-place validation PASS (71 именованный объект, 6 скриптов), артефакт загружен. Studio-проверка, DataStore reconnect и баланс остаются NOT DONE.
- [~] Пассивные таланты Fox/Moth: Fox сокращает перезарядку поиска с 120 до 90 секунд на уровне 3 и до 60 секунд на уровне 5; Moth увеличивает радиус лечения с 14 до 16/18 studs на уровнях 3/5. Эффекты серверные, подсказки отображаются в альбоме. GitHub Actions #1701: 246 контрактных тестов PASS, Roblox place build PASS, generated-place validation PASS (71 именованный объект, 6 скриптов), артефакт загружен. Studio-проверка баланса остаётся NOT DONE.
- [~] Дружба и кормление питомцев: личная шкала 0–1000 и 5 рангов; угощение только экипированного питомца собранным урожаем (тыква +25, клубника +20, капуста +18, морковь +15), расход предмета, серверный cooldown 8 сек., сохранение в профиле. UI во вкладке «Питомцы». Actions #1720: 250 тестов PASS, Roblox place build PASS, generated-place validation PASS (71 именованный объект, 6 скриптов), артефакт загружен. Studio-приёмка и проверка DataStore NOT DONE.
- [~] Добавить совместные игры и добровольные взаимодействия: мини-игра «Повтори за питомцем» с серверным challenge token, случайной последовательностью из 3 символов (4 при дружбе 600+), проверкой каждого ввода на сервере, таймаутом 18 сек. и cooldown 25 сек. Победа даёт +15 дружбы и +8 XP; ошибка не отнимает прогресс. Pets UI и контрактные тесты добавлены. Actions #1739 (после финальной правки компоновки кнопок): 255 тестов PASS, Roblox place build PASS, generated-place validation PASS (71 именованный объект, 6 скриптов), артефакт загружен. Studio/mobile acceptance NOT DONE.
- [~] Глубокий отдых питомца: после 45 секунд неподвижности локальный компаньон показывает мягко всплывающие Z-глифы над головой; индикатор создаётся локально для каждого отображаемого компаньона, удаляется при движении/смене компаньона/выходе и не меняет игровые параметры. Добавлен source-contract тест жизненного цикла; CI и Studio/mobile acceptance ожидают проверки.
- [~] Первый слой характера и настроения: лисёнок — любопытный исследователь, моль — спокойная хранительница света; настроение меняется от экипировки, кормления и успешной игры (Любопытство/Спокойствие → Довольство/Радость). Серверные атрибуты и отображение в альбоме готовы; состояние не decay-ится и не влияет на способности/ресурсы, сбрасывается к базовому при новой сессии. Actions #1752: 259 тестов PASS, Roblox place build PASS, generated-place validation PASS (71 именованный объект, 6 скриптов), артефакт загружен. Поглаживание из альбома: серверная проверка владения/экипировки, cooldown 18 сек., +5 дружбы, настроение «Радость», сохранение; Fox усиливает взмахи хвоста и движение ушей, Moth — взмахи крыльев и свечение, локальные сердечки/искры. Контрактные тесты добавлены. Actions #1771: 263 теста PASS, Roblox place build PASS, generated-place validation PASS (71 именованный объект, 6 скриптов), артефакт загружен. Поглаживание из мира: локальный компаньон получает ProximityPrompt «Погладить» (E на клавиатуре, X на геймпаде, ClickablePrompt для touch); запрос проходит существующую серверную проверку владения/экипировки и cooldown, а подтверждение запускает species-specific реакцию и сердечки. Уникальные позы при поглаживании: Fox мягко приседает корпусом, подбирает лапы и активнее виляет хвостом; Moth кивает головой и ускоряет крылья. Это процедурные локальные реакции, не полноценный hand-contact rig. Анимация руки/касания и Studio/mobile acceptance NOT DONE. Пассивный отдых: после 12 сек. неподвижности владельца Fox переходит к мягкому дыханию/расслабленному хвосту, Moth замедляет взмахи крыльев и свечение; движение сразу возвращает обычный follow. Только визуальный эффект, без энергии/штрафов. Добавлены контрактные тесты; Studio/mobile acceptance NOT DONE.
- [~] Индивидуальные idle-повадки: лисёнок периодически нюхает воздух во время спокойного ожидания; локальная лунная моль плавно облетает игрока по небольшой орбите и оставляет короткий шлейф звёздной пыли. Эффекты локальные, не дают наград и не меняют прогрессию; добавлены source-contract тесты. Проверка производительности и Studio/mobile acceptance NOT DONE.
- [~] Индивидуальность питомцев: сервер назначает каждому питомцу стабильный видоспецифичный характер из четырёх вариантов (Любопытный, Озорной, Смелый, Застенчивый); характер влияет на повадки лисёнка, скорость/радиус орбиты моли и интенсивность звёздной пыли. Теперь характер хранится внутри записи соответствующего питомца в DataStore, восстанавливается при входе и валидируется по белому списку; старые профили без поля получают безопасное значение по умолчанию. Добавлены source-contract тесты сохранения/загрузки; Studio/mobile и многопользовательская проверка NOT DONE.
- [~] Рост близости влияет на поведение: сервер синхронизирует ступени связи 0–4 по порогам дружбы 0/100/300/600/900. По мере роста связи лисёнок чаще проявляет любопытство, моль летает ближе к хозяину и усиливает звёздную пыль; изменение эффекта моли обновляется без пересоздания модели. Характер питомца остаётся неизменным — меняется именно привычность к хозяину. Добавлены source-contract проверки порогов и клиентских реакций; баланс и Studio/mobile acceptance NOT DONE.
- [~] Реакция на близость при поглаживании: сервер передаёт текущую ступень дружбы вместе с подтверждением действия; локальная вспышка питомца становится богаче по мере роста отношений (5–13 символов, переход оттенка к золоту, особый мотив на максимальной ступени). Эффект только косметический, не выдаёт предметы/XP и не меняет баланс. Добавлен source-contract тест серверного payload и клиентского отображения; Studio/mobile acceptance NOT DONE.
- [~] Первый визуальный рост питомцев: уровень 1–2 — «Малыш» (масштаб 0.90), уровень 3–4 — «Подросток» (1.00), уровень 5 — «Взрослый» (1.10). Ступень определяется серверным уровнем питомца, масштабируется локальная модель у каждого клиента и обновляется при level-up без пересоздания компаньона; карточки альбома показывают ту же ступень. Это визуальный фундамент, не отдельная система возраста: нет таймеров взросления, потери прогресса или платного ускорения. Добавлены 3 source-contract теста. Roblox Studio/mobile acceptance, визуальная читаемость масштаба и multiplayer проверка NOT DONE.
- [~] Анимационные различия стадий роста: у лисёнка интенсивность движения хвоста и шагов зависит от стадии; у моли меняются темп/амплитуда взмахов крыльев и яркость лунного свечения. Эффекты только клиентские и визуальные, боевые характеристики/награды не меняются. Добавлен отдельный контрактный тест; Studio/mobile acceptance и проверка читаемости на реальных моделях NOT DONE.
- [~] Первая система мутаций питомцев: при первом получении питомец получает один постоянный видоспецифичный вариант. Лисёнок: Мшистый / Солнечный / Призматический / легендарный Древесный дух (Солнечная роща); моль: Лунная вуаль / Звёздная пыль / Аврора / легендарное Затмение (Сумеречная долина). Весовые шансы: 70% / 24% / 5,5% / 0,5%. Мутация сохраняется в записи питомца, валидируется при загрузке и синхронизируется всем клиентам; альбом показывает имя и редкость, локальная модель получает цветовой оттенок/контур, легендарные формы — отдельную частицу-ауру. Мутации косметические, без бонусов характеристик. При первом знакомстве сервер передаёт фактический биом встречи в таблицу розыгрыша; пул мутаций фильтруется по биому, а восстановление старых профилей безопасно использует родной биом питомца. Fox знакомится в Grove, Moth — в Dusk. Это пока привязка к месту первой встречи, не сезонным/погодным событиям; отдельные биомные активности, обмен и коллекционная галерея NOT DONE. Добавлены 6 source-contract тестов; Roblox Studio/mobile acceptance и проверка реальных ригов NOT DONE.
- [~] Дневник экспедиций добавлен в HUD как отдельная вкладка «ДНЕВНИК»: трек Солнечной рощи (знакомство с лисёнком, лунное семя, три найденных тайника) и трек Сумеречной долины (моль, лунный цветок, след корней, открытие рун, звёздный осколок). Прогресс строится только на существующих серверных атрибутах и сохранённых счётчиках, UI read-only и обновляется при изменениях атрибутов. Это первая навигационная/журнальная итерация; отдельные экспедиционные задания, награды и новые биомы NOT DONE. Добавлены source-contract тесты; Roblox Studio/mobile acceptance NOT DONE.
- [ ] Добавить косметические варианты и визуальные изменения питомцев.
- [ ] Проверить отсутствие визуальных дубликатов и багов после респавна.

## Этап 6. Экспедиции и бой
- [~] Добавлена первая исследовательская зона «Кристальная пещера»: вход в Сумеречной долине открывается после получения звёздного осколка; отдельная камера содержит кристальные образования, точку прибытия/возврата и сердце пещеры. Взаимодействия проверяются сервером, вход и возврат требуют реальной дистанции, сердце выдаёт один постоянный `CrystalShard`; `CrystalGrottoDiscovered`, `CrystalHeart` и инвентарь сохраняются. Дневник экспедиций показывает оба открытия. Это короткая исследовательская зона без врагов и босса; полноценный биом, случайные события и босс NOT DONE. Добавлены 5 source-contract тестов; Roblox Studio/mobile acceptance NOT DONE.
- [~] Кристальная пещера расширена двумя жилами люмен-кристалла. Они используют общий серверный цикл добычи ресурсов: кирка в руке, 6 ударов (с учётом улучшения инструмента), индивидуальный cooldown 15 минут и сохранение `CrystalShard` в инвентаре. Сервер проверяет, что игрок действительно находится в пещере и стоит рядом с жилой; визуальные жилы имеют отдельную кристальную модель. Это первый ресурсный слой зоны, не полноценная экономика кристаллов; баланс, UI-индикация прогресса ударов и Studio/mobile acceptance NOT DONE. Добавлены 3 source-contract теста.
- [~] В Кристальной пещере добавлена головоломка трёх рун (Луна → Рассвет → Прилив), подсказка на табличке и запечатанный тайник. Прогресс последовательности индивидуальный, сбрасывается после 25 секунд бездействия или неверного символа; завершение сохраняется в `CrystalRunes`. Тайник выдаёт один постоянный `CrystalSigil`, флаг `CrystalCache` и инвентарь сохраняются сервером. Дневник экспедиций показывает оба новых этапа. Roblox Studio/mobile acceptance, визуальная обратная связь активированных рун и баланс награды NOT DONE.
- [~] Добавлено случайное событие «Кристальный обвал» в Кристальной пещере: запускается только при присутствии игроков, выбирает точку внутри безопасных границ зала, показывает красную зону предупреждения за 3 секунды до падения, а затем наносит 18 урона игрокам в радиусе 8 studs. Падение и удар используют TweenService, временные объекты очищает Debris. Частота — случайные 95–145 секунд активного ожидания цикла; событие не запускается, если пещера пуста. Баланс урона/частоты, мобильная читаемость телеграфа и Studio acceptance NOT DONE. Добавлены 2 source-contract теста.
- [~] Добавлена скрытая Эхо-камера за золотой дверью в Кристальной пещере. Доступ требует завершённого тайника (`CrystalCache`) и сохранённой древней печати `CrystalSigil`; сервер проверяет нахождение игрока в пещере, выдаёт отдельную точку входа/возврата и отмечает открытие `CrystalEchoDiscovered`. Внутри размещено призматическое семя — уникальная награда `PrismSeed`, выдаваемая один раз и сохраняемая в инвентаре. Дневник экспедиций отслеживает открытие камеры и получение семени. Полноценная посадка/выращивание призматического растения, Studio/mobile acceptance и баланс NOT DONE. Добавлены 4 source-contract теста.
- [~] Добавлен третий питомец Crystal Wisp: процедурная модель, редкая встреча в Эхо-камере, приручение за призматическое семя, сохранение владения и прогресса, три карточки коллекции и дневниковая отметка. Мутации привязаны к биому CrystalGrotto.
- [~] Реализовано Prism Sense: серверная проверка питомца и нахождения в пещере, открытие двух скрытых призменных жил на 16–28 секунд в зависимости от уровня, 45-секундное восстановление, добыча дополнительных CrystalShard киркой, локальный эффект и XP питомцу. Требуется Studio/mobile acceptance и проверка многопользовательского поведения.
- [ ] Добавить лес и каменный биом как законченные зоны.
- [ ] Создать базовые инструменты, оружие и броню.
- [ ] Добавить врагов с читаемыми атаками.
- [ ] Реализовать кооператив 1–4 игрока.
- [~] Добавить первый лесной тайник после двух побед: портал в `ForestTrialChamber`, серверная проверка обеих побед, загадка трёх рун (Луна → Рассвет → Прилив) с индивидуальным прогрессом игрока и личная разовая награда StarShard ×1. Это только короткая наградная комната; Studio-приёмка NOT DONE.
- [~] Создать первый Rootvault-маршрут: три комнаты, коридор с уроняющими плитами, собственная боевая зона, Корневой охотник (75 HP), Страж хранилища (145 HP), Страж печатей (360 HP, 3 серверные фазы, HUD босса, локальный эффект пробуждения, призывает 2 осколка печати в финальной фазе), персональный рычаг, ключ, RootvaultEssence, RootvaultSigil и разовая награда IronOre ×3. Studio-проверка, баланс, уникальные атаки и анимации босса остаются NOT DONE.
- [ ] Завершить полноценное подземелье: добавить врагов, босса, ключ/дроп и финальную награду.
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
