# PositionCopy Client - Клиент копирования позиций (MQL5)

## Описание / Description

**PositionCopy_Client.mq5** - это клиентский советник для копирования позиций с сервера через файловую систему. Поддерживает различные режимы расчета объема, конвертацию символов и синхронизацию SL/TP.

**PositionCopy_Client.mq5** is a client Expert Advisor for copying positions from server via file system. Supports various volume calculation modes, symbol conversion, and SL/TP synchronization.

## Функциональность / Features

- ✅ Копирование позиций с сервера через CSV файлы
- ✅ Различные режимы расчета объема (фиксированный, пропорциональный, по балансу)
- ✅ Конвертация символов (например, USTECHCash → NAS100)
- ✅ Синхронизация SL и TP позиций
- ✅ Фильтрация по символам и магическим номерам
- ✅ Отображение информации о позициях на графике
- ✅ Проверка разрешений на торговлю

- ✅ Copying positions from server via CSV files
- ✅ Various volume calculation modes (fixed, proportional, by balance)
- ✅ Symbol conversion (e.g., USTECHCash → NAS100)
- ✅ SL and TP position synchronization
- ✅ Filtering by symbols and magic numbers
- ✅ Position information display on chart
- ✅ Trading permission checks

## Параметры / Parameters

| Параметр / Parameter | Тип / Type | Описание / Description |
|---------------------|------------|------------------------|
| `magicNumber` | long | Магический номер копировщика / Magic number of copier |
| `shareName` | string | Имя сервера / Server name |
| `displayComment` | string | Комментарий для отображения / Display comment |
| `filterSymbol_input` | string | Фильтр символов сервера / Server symbol filter |
| `filterMagic` | string | Фильтр магических номеров сервера / Server magic number filter |
| `convertSymbols` | string | Конвертация символов / Symbol conversion |
| `copyType` | CopyType | Режим расчета лота / Lot calculation mode |
| `proportional` | double | Фиксированный лот / множитель пропорции / Fixed lot / proportion multiplier |
| `distance` | int | Разрешенное расстояние / Allowed distance |
| `TPSL_switcher` | Switcher | Копирование SL и TP / SL and TP copying |
| `addSLShift` | double | Добавочный сдвиг SL / Additional SL shift |
| `addTPShift` | double | Добавочный сдвиг TP / Additional TP shift |

## Режимы расчета объема / Volume Calculation Modes

### Fixed (Фиксированный)
Использует фиксированный размер лота, указанный в `proportional`.

Uses fixed lot size specified in `proportional`.

### Oneness (Пропорциональный)
Рассчитывает объем пропорционально исходному объему.

Calculates volume proportionally to source volume.

### OnenessBalance (По балансу)
Рассчитывает объем на основе баланса счета и множителя.

Calculates volume based on account balance and multiplier.

### BalanceProp (Пропорция баланса)
Рассчитывает объем пропорционально балансу сервера и клиента.

Calculates volume proportionally to server and client balance.

### MarginProp (Пропорция маржи)
Рассчитывает объем пропорционально марже сервера и клиента.

Calculates volume proportionally to server and client margin.

### MarginFreeProp (Пропорция свободной маржи)
Рассчитывает объем пропорционально свободной марже сервера и клиента.

Calculates volume proportionally to server and client free margin.

## Конвертация символов / Symbol Conversion

Параметр `convertSymbols` позволяет конвертировать символы сервера в символы клиента:

The `convertSymbols` parameter allows converting server symbols to client symbols:

```
convertSymbols = "OldSymbol=NewSymbol;USTECHCash=NAS100;BRENT=XBRUSD"
```

## Установка / Installation

1. Скопируйте файл `PositionCopy_Client.mq5` в папку `MQL5/Experts/`
2. Скомпилируйте в MetaEditor
3. Убедитесь, что серверный файл находится в папке `Common/Files/`
4. Добавьте на график и настройте параметры

1. Copy `PositionCopy_Client.mq5` to `MQL5/Experts/` folder
2. Compile in MetaEditor
3. Ensure server file is in `Common/Files/` folder
4. Add to chart and configure parameters

## Использование / Usage

1. Настройте `shareName` для указания имени серверного файла
2. Выберите режим расчета объема (`copyType`)
3. Установите параметры фильтрации
4. Настройте конвертацию символов при необходимости
5. Включите синхронизацию SL/TP если нужно

1. Configure `shareName` to specify server file name
2. Choose volume calculation mode (`copyType`)
3. Set filtering parameters
4. Configure symbol conversion if needed
5. Enable SL/TP synchronization if required

## Примеры / Examples

### Пример 1: Базовое копирование
```
magicNumber = 333
shareName = "PositionCopy"
copyType = fixed
proportional = 0.01
TPSL_switcher = ON
```

### Пример 2: Пропорциональное копирование с конвертацией
```
magicNumber = 555
shareName = "MyServer"
copyType = onenessBalance
proportional = 1000
convertSymbols = "USTECHCash=NAS100;BRENT=XBRUSD"
```

## Алгоритм работы / Algorithm

1. **Чтение сервера**: Загружает данные позиций из CSV файла сервера
2. **Фильтрация**: Применяет фильтры по символам и магическим номерам
3. **Конвертация**: Преобразует символы согласно настройкам
4. **Сравнение**: Сравнивает позиции сервера и клиента
5. **Копирование**: Открывает/закрывает позиции для синхронизации
6. **Обновление SL/TP**: Синхронизирует уровни стоп-лосс и тейк-профит

1. **Server reading**: Loads position data from server CSV file
2. **Filtering**: Applies filters by symbols and magic numbers
3. **Conversion**: Converts symbols according to settings
4. **Comparison**: Compares server and client positions
5. **Copying**: Opens/closes positions for synchronization
6. **SL/TP update**: Synchronizes stop loss and take profit levels

## Особенности / Features

- **Объектно-ориентированный дизайн**: Использует классы для различных типов позиций
- **Умная синхронизация**: Отслеживает изменения и обновляет только необходимые позиции
- **Проверка разрешений**: Автоматически проверяет разрешения на торговлю
- **Визуализация**: Отображает информацию о позициях сервера и клиента на графике

- **Object-oriented design**: Uses classes for different position types
- **Smart synchronization**: Tracks changes and updates only necessary positions
- **Permission checks**: Automatically checks trading permissions
- **Visualization**: Displays server and client position information on chart

## Примечания / Notes

- Советник работает с файлами в формате CSV с разделителем ";"
- Поддерживается автоматическое определение режима заполнения ордеров
- Механизм повторных попыток для обработки ошибок торговли
- Автоматическое освобождение памяти для предотвращения утечек

- EA works with CSV files using ";" separator
- Automatic order filling mode detection is supported
- Retry mechanism for handling trading errors
- Automatic memory cleanup to prevent leaks

## Версия / Version

**v2.20** - Исправлена ошибка фильтрации символов

## Автор / Author

Snail000
