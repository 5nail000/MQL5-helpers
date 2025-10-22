# PositionCopy Server - Сервер записи позиций (MQL4)

## Описание / Description

**PositionCopy_and_Orders_Server.mq4** - это советник для записи данных о позициях и отложенных ордерах в файлы CSV. Предназначен для работы в MetaTrader 4 и служит сервером для системы копирования торговли.

**PositionCopy_and_Orders_Server.mq4** is an Expert Advisor for recording position and pending order data to CSV files. Designed for MetaTrader 4 and serves as a server for trade copying system.

## Функциональность / Features

- ✅ Запись данных о позициях в CSV файл
- ✅ Запись данных об отложенных ордерах (опционально)
- ✅ Фильтрация по символам и магическим номерам
- ✅ Подробное логирование изменений позиций/ордеров
- ✅ Минимизированное логирование для избежания спама
- ✅ Настраиваемый интервал синхронизации

- ✅ Recording position data to CSV file
- ✅ Recording pending order data (optional)
- ✅ Filtering by symbols and magic numbers
- ✅ Detailed logging of position/order changes
- ✅ Minimized logging to avoid spam
- ✅ Configurable synchronization interval

## Параметры / Parameters

| Параметр / Parameter | Тип / Type | Описание / Description |
|---------------------|------------|------------------------|
| `syncTimeMs` | int | Время синхронизации в миллисекундах / Synchronization time in milliseconds |
| `shareName` | string | Имя для файлов и отображения / Name for files and display |
| `shareSymbol` | string | Фильтр символов (All или список через ;) / Symbol filter (All or list separated by ;) |
| `shareMagic` | string | Фильтр магических номеров (All или список через ;) / Magic number filter (All or list separated by ;) |
| `pendingOrders` | bool | Включить сохранение отложенных ордеров / Enable saving pending orders |
| `verbose_logging` | bool | Подробное логирование для отладки / Detailed logging for debugging |

## Формат файлов / File Format

### Файл позиций (PositionCopy.csv)
```
Ticket;Symbol;Orientation;Volume;Price;StopLoss;TakeProfit;Currency;Balance;Credit;MarginFree;Time;TimeGMT;Contract;Magic;Comment
```

### Файл ордеров (PositionCopy_ord.csv)
```
Ticket;Symbol;OrderType;Volume;Price;StopLoss;TakeProfit;Currency;Balance;Credit;MarginFree;Time;TimeGMT;Contract;Magic;Comment
```

## Установка / Installation

1. Скопируйте файл `PositionCopy_and_Orders_Server.mq4` в папку `MQL4/Experts/`
2. Скомпилируйте в MetaEditor
3. Добавьте на график и настройте параметры

1. Copy `PositionCopy_and_Orders_Server.mq4` to `MQL4/Experts/` folder
2. Compile in MetaEditor
3. Add to chart and configure parameters

## Использование / Usage

1. Установите `shareName` для указания префикса файлов
2. Настройте фильтры символов и магических номеров
3. Включите `pendingOrders` для записи отложенных ордеров
4. Установите интервал синхронизации (`syncTimeMs`)
5. При необходимости включите подробное логирование

1. Set `shareName` to specify file prefix
2. Configure symbol and magic number filters
3. Enable `pendingOrders` to record pending orders
4. Set synchronization interval (`syncTimeMs`)
5. Enable detailed logging if needed

## Примеры / Examples

### Пример 1: Базовое использование
```
shareName = "PositionCopy"
shareSymbol = "All"
shareMagic = "All"
pendingOrders = false
syncTimeMs = 50
```

### Пример 2: С фильтрацией и ордерами
```
shareName = "MyServer"
shareSymbol = "EURUSD;GBPUSD"
shareMagic = "12345;67890"
pendingOrders = true
verbose_logging = true
```

## Алгоритм работы / Algorithm

1. **Инициализация**: Создает файлы и записывает начальные данные
2. **Мониторинг**: Отслеживает изменения в позициях и ордерах
3. **Обнаружение изменений**: Сравнивает текущее состояние с предыдущим
4. **Запись данных**: Обновляет файлы при обнаружении изменений
5. **Логирование**: Записывает информацию об изменениях

1. **Initialization**: Creates files and records initial data
2. **Monitoring**: Tracks changes in positions and orders
3. **Change detection**: Compares current state with previous
4. **Data recording**: Updates files when changes are detected
5. **Logging**: Records information about changes

## Особенности / Features

- **Оптимизированное логирование**: Записывает только при наличии изменений
- **Безопасная запись**: Использует временные файлы для предотвращения потери данных
- **Подробная информация**: Включает все необходимые данные о позициях и ордерах
- **Гибкая фильтрация**: Поддержка множественных символов и магических номеров

- **Optimized logging**: Records only when changes are present
- **Safe writing**: Uses temporary files to prevent data loss
- **Detailed information**: Includes all necessary position and order data
- **Flexible filtering**: Support for multiple symbols and magic numbers

## Примечания / Notes

- Файлы создаются в папке `Common/Files/`
- Поддерживается работа с несколькими символами одновременно
- Автоматическое удаление стоп-линий при деинициализации
- Совместимость с клиентскими советниками для копирования торговли

- Files are created in `Common/Files/` folder
- Supports multiple symbols simultaneously
- Automatic stop line removal on deinitialization
- Compatibility with client EAs for trade copying

## Версия / Version

**v1.076** - ИСПРАВЛЕНО: Ошибки компиляции "sign mismatch" при сравнении типов

**v1.075** - ИСПРАВЛЕНО: Отображение на графике теперь обновляется регулярно, добавлена информация о прибыли

**v1.074** - Добавлено подробное логирование и улучшения

## Автор / Author

Snail000 (исправлено Grok)
