# Adjuster for SL and TP

## Описание / Description

**Adjuster_for_SL_and_TP.mq5** - это советник для автоматического обновления уровней Stop Loss и Take Profit для открытых позиций с заданным магическим номером.

**Adjuster_for_SL_and_TP.mq5** is an Expert Advisor for automatically updating Stop Loss and Take Profit levels for open positions with a specified magic number.

## Функциональность / Features

- ✅ Автоматическое обновление SL и TP для позиций с заданным магическим номером
- ✅ Фильтрация по символам (опционально)
- ✅ Настраиваемый интервал проверки
- ✅ Расчет уровней на основе расстояния в пунктах
- ✅ Поддержка всех типов символов (валютные пары, индексы, криптовалюты)

- ✅ Automatic SL and TP update for positions with specified magic number
- ✅ Symbol filtering (optional)
- ✅ Configurable check interval
- ✅ Level calculation based on point distance
- ✅ Support for all symbol types (forex pairs, indices, cryptocurrencies)

## Параметры / Parameters

| Параметр / Parameter | Тип / Type | Описание / Description |
|---------------------|------------|------------------------|
| `StopLossDistance` | double | Расстояние до Stop Loss в пунктах / Distance to Stop Loss in points |
| `TakeProfitDistance` | double | Расстояние до Take Profit в пунктах / Distance to Take Profit in points |
| `MagicNumber` | int | Магический номер позиций / Magic number of positions |
| `SymbolFilter` | string | Фильтр символов (пустая строка = все символы) / Symbol filter (empty = all symbols) |
| `TimerInterval` | int | Интервал проверки в секундах / Check interval in seconds |

## Установка / Installation

1. Скопируйте файл `Adjuster_for_SL_and_TP.mq5` в папку `MQL5/Experts/`
2. Скомпилируйте в MetaEditor
3. Добавьте на график и настройте параметры

1. Copy `Adjuster_for_SL_and_TP.mq5` to `MQL5/Experts/` folder
2. Compile in MetaEditor
3. Add to chart and configure parameters

## Использование / Usage

1. Установите желаемые значения для `StopLossDistance` и `TakeProfitDistance`
2. Укажите `MagicNumber` позиций, которые нужно отслеживать
3. При необходимости настройте фильтр символов
4. Установите интервал проверки (по умолчанию 300 секунд)

1. Set desired values for `StopLossDistance` and `TakeProfitDistance`
2. Specify `MagicNumber` of positions to track
3. Configure symbol filter if needed
4. Set check interval (default 300 seconds)

## Примеры / Examples

### Пример 1: Обновление только SL
```
StopLossDistance = 1000  // 1000 пунктов
TakeProfitDistance = 0   // Не обновлять TP
MagicNumber = 12345
```

### Пример 2: Обновление SL и TP для EURUSD
```
StopLossDistance = 500
TakeProfitDistance = 1000
SymbolFilter = "EURUSD"
MagicNumber = 67890
```

## Примечания / Notes

- Советник работает только с открытыми позициями
- Если позиция уже имеет SL/TP, они будут обновлены
- Расчет уровней основан на цене открытия позиции
- Поддерживается работа с несколькими символами одновременно

- EA works only with open positions
- If position already has SL/TP, they will be updated
- Level calculation is based on position open price
- Supports multiple symbols simultaneously

## Версия / Version

**v1.00** - Первоначальная версия

## Автор / Author

Snail000
