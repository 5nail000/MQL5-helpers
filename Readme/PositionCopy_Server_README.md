# PositionCopy Server - Сервер записи позиций (MQL5)

## Описание / Description

**PositionCopy_Server.mq5** - это серверный советник для записи данных о позициях в CSV файл. Предназначен для работы в MetaTrader 5 и служит источником данных для клиентских советников системы копирования торговли.

**PositionCopy_Server.mq5** is a server Expert Advisor for recording position data to CSV file. Designed for MetaTrader 5 and serves as data source for client EAs in trade copying system.

## Функциональность / Features

- ✅ Запись данных о позициях в CSV файл
- ✅ Фильтрация по символам и магическим номерам
- ✅ Отслеживание изменений SL и TP позиций
- ✅ Настраиваемый интервал синхронизации
- ✅ Отображение информации о позициях на графике
- ✅ Оптимизированная работа с памятью

- ✅ Recording position data to CSV file
- ✅ Filtering by symbols and magic numbers
- ✅ Tracking SL and TP position changes
- ✅ Configurable synchronization interval
- ✅ Position information display on chart
- ✅ Optimized memory usage

## Параметры / Parameters

| Параметр / Parameter | Тип / Type | Описание / Description |
|---------------------|------------|------------------------|
| `syncTime` | uint | Время синхронизации в миллисекундах / Synchronization time in milliseconds |
| `shareName` | string | Имя для файлов и отображения / Name for files and display |
| `shareSymbol` | string | Фильтр символов (All или список через ;) / Symbol filter (All or list separated by ;) |
| `shareMagic` | string | Фильтр магических номеров (All или список через ;) / Magic number filter (All or list separated by ;) |

## Формат файла / File Format

### Файл позиций (PositionCopy.csv)
```
Ticket;Symbol;Orientation;Volume;Price;StopLoss;TakeProfit;Currency;Balance;Credit;MarginFree;Time;TimeGMT;Contract;Magic;Comment
```

Где:
- `Ticket` - номер тикета позиции
- `Symbol` - символ инструмента
- `Orientation` - направление (1 = покупка, -1 = продажа)
- `Volume` - объем позиции
- `Price` - цена открытия
- `StopLoss` - уровень стоп-лосс
- `TakeProfit` - уровень тейк-профит
- `Currency` - валюта счета
- `Balance` - баланс счета
- `Credit` - кредит
- `MarginFree` - свободная маржа
- `Time` - время открытия позиции
- `TimeGMT` - время открытия в GMT
- `Contract` - размер контракта
- `Magic` - магический номер
- `Comment` - комментарий

Where:
- `Ticket` - position ticket number
- `Symbol` - instrument symbol
- `Orientation` - direction (1 = buy, -1 = sell)
- `Volume` - position volume
- `Price` - open price
- `StopLoss` - stop loss level
- `TakeProfit` - take profit level
- `Currency` - account currency
- `Balance` - account balance
- `Credit` - credit
- `MarginFree` - free margin
- `Time` - position open time
- `TimeGMT` - open time in GMT
- `Contract` - contract size
- `Magic` - magic number
- `Comment` - comment

## Установка / Installation

1. Скопируйте файл `PositionCopy_Server.mq5` в папку `MQL5/Experts/`
2. Скомпилируйте в MetaEditor
3. Добавьте на график и настройте параметры

1. Copy `PositionCopy_Server.mq5` to `MQL5/Experts/` folder
2. Compile in MetaEditor
3. Add to chart and configure parameters

## Использование / Usage

1. Установите `shareName` для указания префикса файла
2. Настройте фильтры символов и магических номеров
3. Установите интервал синхронизации (`syncTime`)
4. Запустите советник на графике

1. Set `shareName` to specify file prefix
2. Configure symbol and magic number filters
3. Set synchronization interval (`syncTime`)
4. Run EA on chart

## Примеры / Examples

### Пример 1: Базовое использование
```
shareName = "PositionCopy"
shareSymbol = "All"
shareMagic = "All"
syncTime = 1
```

### Пример 2: С фильтрацией
```
shareName = "MyServer"
shareSymbol = "EURUSD;GBPUSD;USDJPY"
shareMagic = "12345;67890"
syncTime = 100
```

## Алгоритм работы / Algorithm

1. **Инициализация**: Создает файл и записывает начальные данные
2. **Мониторинг**: Отслеживает изменения в позициях
3. **Обнаружение изменений**: Сравнивает текущее состояние с предыдущим
4. **Запись данных**: Обновляет файл при обнаружении изменений
5. **Отображение**: Показывает информацию о позициях на графике

1. **Initialization**: Creates file and records initial data
2. **Monitoring**: Tracks changes in positions
3. **Change detection**: Compares current state with previous
4. **Data recording**: Updates file when changes are detected
5. **Display**: Shows position information on chart

## Особенности / Features

- **Эффективное отслеживание**: Использует структуры данных для отслеживания изменений
- **Безопасная запись**: Использует временные файлы для предотвращения потери данных
- **Подробная информация**: Включает все необходимые данные о позициях
- **Гибкая фильтрация**: Поддержка множественных символов и магических номеров

- **Efficient tracking**: Uses data structures to track changes
- **Safe writing**: Uses temporary files to prevent data loss
- **Detailed information**: Includes all necessary position data
- **Flexible filtering**: Support for multiple symbols and magic numbers

## Примечания / Notes

- Файл создается в папке `Common/Files/`
- Поддерживается работа с несколькими символами одновременно
- Автоматическое удаление комментариев при деинициализации
- Совместимость с клиентскими советниками для копирования торговли

- File is created in `Common/Files/` folder
- Supports multiple symbols simultaneously
- Automatic comment removal on deinitialization
- Compatibility with client EAs for trade copying

## Версия / Version

**v1.072** - Исправлено отслеживание изменений TP и SL

## Автор / Author

Snail000
