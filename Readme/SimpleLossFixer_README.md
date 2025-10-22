# SimpleLossFixer - Мониторинг просадки по магическим номерам

## Описание / Description

**SimpleLossFixer.mq5** - это советник для мониторинга просадки по магическим номерам с возможностью автоматического закрытия позиций при достижении критического уровня. Поддерживает два режима мониторинга и отображает подробную таблицу на графике.

**SimpleLossFixer.mq5** is an Expert Advisor for monitoring drawdown by magic numbers with automatic position closure when critical level is reached. Supports two monitoring modes and displays detailed table on chart.

## Функциональность / Features

- ✅ Мониторинг просадки по магическим номерам
- ✅ Два режима мониторинга: "Все" и "Выбранные"
- ✅ Автоматическое закрытие позиций при превышении лимита
- ✅ Режим создания хеджирующих (лок) позиций для нейтрализации экспозиции
- ✅ Режим только мониторинга (без действий)
- ✅ Подробная таблица мониторинга на графике
- ✅ Настраиваемые параметры просадки
- ✅ Автоматическое поддержание лока при изменении позиций

- ✅ Drawdown monitoring by magic numbers
- ✅ Two monitoring modes: "All" and "Selected"
- ✅ Automatic position closure when limit exceeded
- ✅ Hedging (lock) mode to neutralize exposure
- ✅ Monitoring-only mode (without actions)
- ✅ Detailed monitoring table on chart
- ✅ Configurable drawdown parameters
- ✅ Automatic lock maintenance when positions change

## Параметры / Parameters

| Параметр / Parameter | Тип / Type | Описание / Description |
|---------------------|------------|------------------------|
| `Mode` | MonitoringMode | Режим мониторинга: All или Selected / Monitoring mode: All or Selected |
| `MagicNumbersList` | string | Для режима Selected: магические номера через запятую / For Selected mode: magic numbers separated by comma |
| `ExcludeMagicNumbersList` | string | Для режима All: исключения через запятую / For All mode: exclusions separated by comma |
| `StopValue` | double | Критический лимит просадки в валюте счета / Critical drawdown limit in account currency |
| `ActionProcess` | ActionProcessFlag | Режим работы: Закрытие позиций, только отображение или лок / Operation mode: Close positions, display only, or lock |

## Режимы мониторинга / Monitoring Modes

### MODE_ALL (Все)
Мониторит все уникальные магические номера в открытых позициях, исключая указанные в `ExcludeMagicNumbersList`.

Monitors all unique magic numbers in open positions, excluding those specified in `ExcludeMagicNumbersList`.

### MODE_SELECTED (Выбранные)
Мониторит только указанные магические номера из `MagicNumbersList`.

Monitors only specified magic numbers from `MagicNumbersList`.

## Режимы работы / Operation Modes

### CLOSE_POSITIONS (Закрывать позиции)
При превышении лимита просадки автоматически закрывает все позиции с соответствующим магическим номером.

When drawdown limit is exceeded, automatically closes all positions with corresponding magic number.

### DISPLAY_ONLY (Только отображение)
Только отображает информацию о просадке без закрытия позиций.

Only displays drawdown information without closing positions.

### LOCK (Лок)
При превышении лимита просадки открывает противоположные позиции для хеджирования (с уникальным магик-номером `1064 * 100000 + originalMagic`). Поддерживает лок, автоматически корректируя его при изменении позиций исходного магика.

When drawdown limit is exceeded, opens opposite positions for hedging (with unique magic number `1064 * 100000 + originalMagic`). Maintains the lock by automatically adjusting it when positions with the original magic change.

## Установка / Installation

1. Скопируйте файл `SimpleLossFixer.mq5` в папку `MQL5/Experts/`
2. Скомпилируйте в MetaEditor
3. Добавьте на график и настройте параметры

1. Copy `SimpleLossFixer.mq5` to `MQL5/Experts/` folder
2. Compile in MetaEditor
3. Add to chart and configure parameters

## Использование / Usage

1. Выберите режим мониторинга (`Mode`)
2. Настройте список магических номеров или исключений
3. Установите критический лимит просадки (`StopValue`)
4. Выберите режим работы (`ActionProcess`)
5. Запустите советник на графике

1. Choose monitoring mode (`Mode`)
2. Configure magic numbers list or exclusions
3. Set critical drawdown limit (`StopValue`)
4. Choose operation mode (`ActionProcess`)
5. Run EA on chart

## Примеры / Examples

### Пример 1: Мониторинг всех магических номеров
```
Mode = MODE_ALL
ExcludeMagicNumbersList = "99999,00000"
StopValue = 550.0
ActionProcess = CLOSE_POSITIONS
```

### Пример 2: Мониторинг выбранных магических номеров номеров с локировкой
```
Mode = MODE_SELECTED
MagicNumbersList = "12345,67890"
StopValue = 1000.0
ActionProcess = LOCK
```

### Пример 3: Только мониторинг без закрытия
```
Mode = MODE_ALL
StopValue = 500.0
MonitoringOnly = DISPLAY_ONLY
```

## Таблица мониторинга / Monitoring Table

Советник отображает подробную таблицу на графике с информацией:

The EA displays detailed table on chart with information:

- **Magic ID**: Магический номер
- **Positions**: Количество позиций
- **P&L (Currency)**: Прибыль/убыток в валюте счета
- **Drawdown %**: Процент просадки от лимита
- **Status**: Статус (OK или EXCEEDED!)

- **Magic ID**: Magic number
- **Positions**: Number of positions
- **P&L (Currency)**: Profit/loss in account currency
- **Drawdown %**: Drawdown percentage from limit
- **Status**: Status (OK or EXCEEDED!)

## Алгоритм работы / Algorithm

1. **Сбор данных**: Собирает уникальные магические номера из открытых позиций
2. **Фильтрация**: Применяет выбранный режим мониторинга
3. **Расчет просадки**: Вычисляет общую прибыль/убыток для каждого магического номера
4. **Проверка лимита**: Сравнивает просадку с критическим уровнем
5. **Действия**: Закрывает позиции или только отображает информацию
6. **Поддержание лока**: В режиме LOCK корректирует хеджирующие позиции при изменении исходных позиций
7. **Обновление таблицы**: Обновляет таблицу мониторинга на графике

1. **Data collection**: Collects unique magic numbers from open positions
2. **Filtering**: Applies selected monitoring mode
3. **Drawdown calculation**: Calculates total profit/loss for each magic number
4. **Limit check**: Compares drawdown with critical level
5. **Actions**: Closes positions or only displays information
6. **Lock maintenance**: In LOCK mode, adjusts hedging positions when original positions change
7. **Table update**: Updates monitoring table on chart

## Особенности / Features

- **Умная фильтрация**: Автоматически определяет магические номера для мониторинга
- **Подробная статистика**: Отображает детальную информацию о каждой группе позиций
- **Гибкая настройка**: Поддерживает различные режимы мониторинга и работы
- **Безопасность**: Проверяет валидность магических номеров
- **Хеджирование**: Поддерживает автоматическое создание и корректировку лока для нейтрализации экспозиции
- **Динамическое управление**: Автоматически реагирует на закрытие или открытие новых позиций исходным советником

- **Smart filtering**: Automatically determines magic numbers for monitoring
- **Detailed statistics**: Displays detailed information about each position group
- **Flexible configuration**: Supports various monitoring and operation modes
- **Safety**: Validates magic numbers
- **Hedging**: Supports automatic creation and adjustment of locks to neutralize exposure
- **Dynamic management**: Automatically reacts to closing or opening new positions by the original advisor


## Примечания / Notes

- Просадка рассчитывается как сумма всех прибылей/убытков по позициям
- При превышении лимита в режиме CLOSE_POSITIONS закрываются ВСЕ позиции с соответствующим магическим номером
- В режиме LOCK создаются хеджирующие позиции с уникальным магик-номером, которые корректируются при любых изменениях исходных позиций
- Таблица обновляется в реальном времени
- Советник работает только с открытыми позициями
- Лок-позиции остаются открытыми после деинициализации советника (до ручного закрытия или корректировки)

- Drawdown is calculated as sum of all profits/losses from positions
- In CLOSE_POSITIONS mode, ALL positions with corresponding magic number are closed when limit is exceeded
- In LOCK mode, hedging positions with unique magic number are created and adjusted for any changes in original positions
- Table updates in real time
- EA works only with open positions
- Lock positions remain open after EA deinitialization (until manually closed or adjusted)

## Версия / Version

**v1.7** - Добавлен режим LOCK для хеджирования позиций, автоматическая корректировка лока при изменении позиций, улучшена обработка ошибок.

**v1.7** - Added LOCK mode for hedging positions, automatic lock adjustment on position changes, improved error handling.

**v1.6** - Добавлены режимы мониторинга и улучшения

## Автор / Author

Snail000
