# HandBrake4EA - Контроль просадки советника

## Описание / Description

**HandBrake4EA.mq5** - это советник для мониторинга и контроля торговой активности другого советника на основе уровня просадки. При достижении критической просадки автоматически закрывает все позиции и может блокировать новые сделки.

**HandBrake4EA.mq5** is an Expert Advisor for monitoring and controlling trading activity of another EA based on drawdown levels. When critical drawdown is reached, it automatically closes all positions and can block new trades.

## Функциональность / Features

- ✅ Мониторинг просадки для позиций с заданным магическим номером
- ✅ Автоматическое закрытие позиций при достижении критической просадки
- ✅ Блокировка новых позиций после критической просадки (опционально)
- ✅ Отображение стоп-линии на графике для визуализации критического уровня
- ✅ Настраиваемые параметры просадки и фильтрации

- ✅ Drawdown monitoring for positions with specified magic number
- ✅ Automatic position closure when critical drawdown is reached
- ✅ Blocking new positions after critical drawdown (optional)
- ✅ Stop line display on chart for critical level visualization
- ✅ Configurable drawdown and filtering parameters

## Параметры / Parameters

| Параметр / Parameter | Тип / Type | Описание / Description |
|---------------------|------------|------------------------|
| `MagicNumber` | int | Магический номер целевого советника / Magic number of target EA |
| `SymbolFilter` | string | Фильтр символов (пустая строка = все символы) / Symbol filter (empty = all symbols) |
| `StopValue` | double | Критический уровень просадки в валюте счета / Critical drawdown level in account currency |
| `isDelete` | bool | Блокировать торговлю после закрытия позиций / Block trading after closing positions |
| `ShowLines` | bool | Показывать стоп-линию на графике / Show stop line on chart |

## Установка / Installation

1. Скопируйте файл `HandBrake4EA.mq5` в папку `MQL5/Experts/`
2. Скомпилируйте в MetaEditor
3. Добавьте на график и настройте параметры

1. Copy `HandBrake4EA.mq5` to `MQL5/Experts/` folder
2. Compile in MetaEditor
3. Add to chart and configure parameters

## Использование / Usage

1. Установите `MagicNumber` целевого советника
2. Настройте `StopValue` - критический уровень просадки
3. При необходимости укажите `SymbolFilter` для конкретного символа
4. Включите `isDelete` для блокировки новых сделок после закрытия
5. Включите `ShowLines` для отображения стоп-линии

1. Set `MagicNumber` of target EA
2. Configure `StopValue` - critical drawdown level
3. Specify `SymbolFilter` for specific symbol if needed
4. Enable `isDelete` to block new trades after closure
5. Enable `ShowLines` to display stop line

## Примеры / Examples

### Пример 1: Базовое использование
```
MagicNumber = 12345
StopValue = 550.0
isDelete = true
ShowLines = true
```

### Пример 2: Только для EURUSD
```
MagicNumber = 67890
SymbolFilter = "EURUSD"
StopValue = 1000.0
isDelete = false
ShowLines = true
```

## Алгоритм работы / Algorithm

1. **Мониторинг**: Постоянно отслеживает просадку всех позиций с заданным магическим номером
2. **Расчет просадки**: Суммирует убытки по всем позициям
3. **Проверка лимита**: Сравнивает общую просадку с критическим уровнем
4. **Закрытие позиций**: При превышении лимита закрывает все позиции
5. **Блокировка**: При включенной опции блокирует новые сделки

1. **Monitoring**: Continuously tracks drawdown of all positions with specified magic number
2. **Drawdown calculation**: Sums losses from all positions
3. **Limit check**: Compares total drawdown with critical level
4. **Position closure**: Closes all positions when limit is exceeded
5. **Blocking**: Blocks new trades when option is enabled

## Стоп-линия / Stop Line

При включенной опции `ShowLines` советник отображает красную пунктирную линию на графике, показывающую уровень цены, при котором будет достигнута критическая просадка.

When `ShowLines` option is enabled, the EA displays a red dashed line on the chart showing the price level at which critical drawdown will be reached.

## Примечания / Notes

- Советник работает только с позициями, имеющими указанный магический номер
- Просадка рассчитывается как сумма всех убытков по позициям
- После активации блокировки все новые позиции с тем же магическим номером будут автоматически закрываться
- Стоп-линия автоматически удаляется при отсутствии позиций

- EA works only with positions having specified magic number
- Drawdown is calculated as sum of all losses from positions
- After blocking activation, all new positions with same magic number will be automatically closed
- Stop line is automatically removed when no positions exist

## Версия / Version

**v1.0** - Первоначальная версия

## Автор / Author

Snail000
