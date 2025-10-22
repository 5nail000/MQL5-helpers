# OrderCopyClient - Клиент копирования ордеров

## Описание / Description

**OrderCopyClient.mq5** - это советник для копирования отложенных ордеров и синхронизации позиций из файлов. Поддерживает различные режимы расчета объема и фильтрацию по символам и магическим номерам.

**OrderCopyClient.mq5** is an Expert Advisor for copying pending orders and synchronizing positions from files. Supports various volume calculation modes and filtering by symbols and magic numbers.

## Функциональность / Features

- ✅ Копирование отложенных ордеров из файлов
- ✅ Синхронизация позиций с сервером
- ✅ Различные режимы расчета объема (фиксированный/пропорциональный)
- ✅ Фильтрация по символам и магическим номерам
- ✅ Отслеживание изменений SL/TP позиций
- ✅ Опциональное закрытие позиций по сигналу сервера
- ✅ Минимизированное логирование для избежания спама

- ✅ Copying pending orders from files
- ✅ Position synchronization with server
- ✅ Various volume calculation modes (fixed/proportional)
- ✅ Filtering by symbols and magic numbers
- ✅ Tracking SL/TP position changes
- ✅ Optional position closure by server signal
- ✅ Minimized logging to avoid spam

## Параметры / Parameters

| Параметр / Parameter | Тип / Type | Описание / Description |
|---------------------|------------|------------------------|
| `shareName` | string | Префикс имени файла / File name prefix |
| `syncTime` | uint | Интервал проверки в миллисекундах / Check interval in milliseconds |
| `syncIntervalMinutes` | uint | Интервал синхронизации в минутах / Synchronization interval in minutes |
| `filterSymbol` | string | Фильтр символов / Symbol filter |
| `filterMagic` | string | Фильтр магических номеров / Magic number filter |
| `copyType` | CopyType | Режим расчета объема / Volume calculation mode |
| `fixVolume` | double | Фиксированный объем для режима FixedLotSize / Fixed volume for FixedLotSize mode |
| `proportional` | double | Множитель для пропорционального режима / Multiplier for proportional mode |
| `newMagicNumber` | long | Магический номер для скопированных ордеров/позиций / Magic number for copied orders/positions |
| `newComment` | string | Комментарий для скопированных ордеров/позиций / Comment for copied orders/positions |
| `timeToleranceSec` | int | Допуск времени открытия позиций в секундах / Position opening time tolerance in seconds |
| `closeByServer` | bool | Закрывать позиции только по сигналу сервера / Close positions only by server signal |
| `verbose_logging` | bool | Подробное логирование для отладки / Detailed logging for debugging |

## Режимы расчета объема / Volume Calculation Modes

### FixedLotSize (Фиксированный размер лота)
Использует фиксированный размер лота, указанный в параметре `fixVolume`.

Uses fixed lot size specified in `fixVolume` parameter.

### Proportional (Пропорциональный)
Рассчитывает объем пропорционально исходному объему с учетом множителя `proportional`.

Calculates volume proportionally to source volume using `proportional` multiplier.

## Установка / Installation

1. Скопируйте файл `OrderCopyClient.mq5` в папку `MQL5/Experts/`
2. Скомпилируйте в MetaEditor
3. Убедитесь, что файлы данных находятся в папке `Common/Files/`
4. Добавьте на график и настройте параметры

1. Copy `OrderCopyClient.mq5` to `MQL5/Experts/` folder
2. Compile in MetaEditor
3. Ensure data files are in `Common/Files/` folder
4. Add to chart and configure parameters

## Структура файлов / File Structure

Советник ожидает два файла в папке `Common/Files/`:

The EA expects two files in `Common/Files/` folder:

- `{shareName}_ord.csv` - файл с отложенными ордерами / file with pending orders
- `{shareName}.csv` - файл с позициями / file with positions

## Использование / Usage

1. Настройте `shareName` для указания префикса файлов
2. Выберите режим расчета объема (`copyType`)
3. Установите параметры фильтрации (`filterSymbol`, `filterMagic`)
4. Настройте интервалы синхронизации
5. При необходимости включите подробное логирование

1. Configure `shareName` to specify file prefix
2. Choose volume calculation mode (`copyType`)
3. Set filtering parameters (`filterSymbol`, `filterMagic`)
4. Configure synchronization intervals
5. Enable detailed logging if needed

## Примеры / Examples

### Пример 1: Базовое копирование
```
shareName = "PositionCopy"
copyType = FixedLotSize
fixVolume = 0.01
newMagicNumber = 333
```

### Пример 2: Пропорциональное копирование с фильтрацией
```
shareName = "MyServer"
copyType = Proportional
proportional = 0.5
filterSymbol = "EURUSD;GBPUSD"
filterMagic = "12345;67890"
```

## Алгоритм работы / Algorithm

1. **Чтение файлов**: Загружает данные ордеров и позиций из CSV файлов
2. **Фильтрация**: Применяет фильтры по символам и магическим номерам
3. **Синхронизация ордеров**: Сравнивает текущие ордера с файловыми данными
4. **Синхронизация позиций**: Отслеживает изменения в позициях
5. **Обновление**: Модифицирует или создает новые ордера/позиции

1. **File reading**: Loads order and position data from CSV files
2. **Filtering**: Applies filters by symbols and magic numbers
3. **Order synchronization**: Compares current orders with file data
4. **Position synchronization**: Tracks position changes
5. **Update**: Modifies or creates new orders/positions

## Примечания / Notes

- Советник работает с файлами в формате CSV с разделителем ";"
- Поддерживается динамический режим заполнения на основе настроек символа
- Механизм повторных попыток для обработки ошибок закрытия позиций
- Минимизированное логирование для избежания спама в журнале

- EA works with CSV files using ";" separator
- Dynamic filling mode based on symbol settings is supported
- Retry mechanism for handling position closure errors
- Minimized logging to avoid journal spam

## Версия / Version

**v1.3** - Исправлено логирование, добавлены улучшения

## Автор / Author

Snail000 (исправлено Grok)
