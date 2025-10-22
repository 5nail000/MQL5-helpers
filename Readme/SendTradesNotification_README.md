# SendTradesNotification - Уведомления о сделках

## Описание / Description

**SendTradesNotification.mq5** - это советник для отправки уведомлений об открытии и закрытии торговых позиций. Поддерживает настраиваемые заголовки и позволяет выбирать типы уведомлений.

**SendTradesNotification.mq5** is an Expert Advisor for sending notifications about opening and closing trading positions. Supports customizable titles and allows selecting notification types.

## Функциональность / Features

- ✅ Уведомления об открытии позиций
- ✅ Уведомления о закрытии позиций
- ✅ Настраиваемый заголовок уведомлений
- ✅ Отображение детальной информации о сделках
- ✅ Поддержка всех типов торговых операций
- ✅ Интеграция с мобильными приложениями MetaTrader

- ✅ Position opening notifications
- ✅ Position closing notifications
- ✅ Customizable notification titles
- ✅ Detailed trade information display
- ✅ Support for all types of trading operations
- ✅ Integration with MetaTrader mobile apps

## Параметры / Parameters

| Параметр / Parameter | Тип / Type | Описание / Description |
|---------------------|------------|------------------------|
| `Title` | string | Заголовок уведомления / Notification title |
| `notifyOpen` | nStyles | Уведомлять об открытии позиций / Notify about position opening |
| `notifyClose` | nStyles | Уведомлять о закрытии позиций / Notify about position closing |

## Типы уведомлений / Notification Types

### Уведомления об открытии / Opening Notifications
Включают информацию о:
- Направлении сделки (покупка/продажа)
- Символе инструмента
- Размере лота
- Цене входа
- Комментарии
- Магическом номере

Include information about:
- Trade direction (buy/sell)
- Instrument symbol
- Lot size
- Entry price
- Comment
- Magic number

### Уведомления о закрытии / Closing Notifications
Включают информацию о:
- Символе инструмента
- Размере лота
- Прибыли/убытке
- Цене выхода
- Текущем балансе и эквити
- Комментарии
- Магическом номере

Include information about:
- Instrument symbol
- Lot size
- Profit/loss
- Exit price
- Current balance and equity
- Comment
- Magic number

## Установка / Installation

1. Скопируйте файл `SendTradesNotification.mq5` в папку `MQL5/Experts/`
2. Скомпилируйте в MetaEditor
3. Добавьте на график и настройте параметры

1. Copy `SendTradesNotification.mq5` to `MQL5/Experts/` folder
2. Compile in MetaEditor
3. Add to chart and configure parameters

## Использование / Usage

1. Установите желаемый заголовок уведомлений (`Title`)
2. Выберите типы уведомлений (`notifyOpen`, `notifyClose`)
3. Запустите советник на графике
4. Убедитесь, что уведомления включены в настройках терминала

1. Set desired notification title (`Title`)
2. Choose notification types (`notifyOpen`, `notifyClose`)
3. Run EA on chart
4. Ensure notifications are enabled in terminal settings

## Примеры / Examples

### Пример 1: Все уведомления
```
Title = "ECN TRADE !"
notifyOpen = 1
notifyClose = 1
```

### Пример 2: Только закрытие позиций
```
Title = "Trade Alert"
notifyOpen = 0
notifyClose = 1
```

### Пример 3: Без заголовка
```
Title = ""
notifyOpen = 1
notifyClose = 1
```

## Формат уведомлений / Notification Format

### Уведомление об открытии / Opening Notification
```
ECN TRADE !
Вошли в ПОКУПКУ: EURUSD
Размер лота: 0.10
Цена на входе: 1.0850
Коментарий: MyEA
Magic: 12345
```

### Уведомление о закрытии / Closing Notification
```
ECN TRADE !
Закрыли позицию: EURUSD
Размер лота: 0.10
Прибыль: 15.50
Цена на выходе: 1.0865
Текущий баланс/еквити: 1000.00(1015.50)
Коментарий: MyEA
Magic: 12345
```

## Алгоритм работы / Algorithm

1. **Отслеживание сделок**: Мониторит все торговые транзакции
2. **Фильтрация**: Определяет тип сделки (открытие/закрытие)
3. **Сбор данных**: Получает информацию о сделке из истории
4. **Формирование сообщения**: Создает текст уведомления
5. **Отправка**: Отправляет уведомление через терминал

1. **Trade tracking**: Monitors all trading transactions
2. **Filtering**: Determines trade type (opening/closing)
3. **Data collection**: Retrieves trade information from history
4. **Message formation**: Creates notification text
5. **Sending**: Sends notification through terminal

## Особенности / Features

- **Автоматическое определение**: Автоматически определяет тип сделки
- **Детальная информация**: Включает всю важную информацию о сделке
- **Гибкая настройка**: Позволяет выбирать типы уведомлений
- **Совместимость**: Работает со всеми типами торговых операций

- **Automatic detection**: Automatically determines trade type
- **Detailed information**: Includes all important trade information
- **Flexible configuration**: Allows choosing notification types
- **Compatibility**: Works with all types of trading operations

## Настройка уведомлений / Notification Setup

Для получения уведомлений необходимо:

To receive notifications, you need to:

1. **Включить уведомления в терминале**:
   - Tools → Options → Notifications
   - Включить "Enable notifications"

1. **Enable notifications in terminal**:
   - Tools → Options → Notifications
   - Enable "Enable notifications"

2. **Настроить мобильное приложение** (опционально):
   - Установить MetaTrader 5 на мобильное устройство
   - Войти в тот же аккаунт

2. **Configure mobile app** (optional):
   - Install MetaTrader 5 on mobile device
   - Login to same account

## Примечания / Notes

- Уведомления работают только при включенных настройках в терминале
- Поддерживается отправка на мобильные устройства
- Советник работает в фоновом режиме
- Не влияет на торговую логику других советников

- Notifications work only when enabled in terminal settings
- Mobile device sending is supported
- EA works in background mode
- Does not affect trading logic of other EAs

## Версия / Version

**v1.01** - Добавлены флаги для информирования открытия и закрытия

## Автор / Author

Snail000
