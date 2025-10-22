# MQL5 Helpers - Коллекция полезных скриптов для MetaTrader 5/4

## Описание / Description

Коллекция полезных скриптов и советников для MetaTrader 5/4, включающая инструменты для управления позициями, копирования торговли, мониторинга просадок и анализа истории торговли.

A collection of useful scripts and Expert Advisors for MetaTrader 5/4, including tools for position management, trade copying, drawdown monitoring, and trading history analysis.

## Структура проекта / Project Structure

```
MQL5_helpers/
├── MQ5_Codes/           # MQL5 скрипты и советники
├── MQ4_Codes/           # MQL4 скрипты и советники  
├── Readme/              # Документация для каждого скрипта
└── README.md           # Основная документация
```

## Содержание / Contents

### 📊 Управление позициями / Position Management

- **[Adjuster_for_SL_and_TP.mq5](MQ5_Codes/Adjuster_for_SL_and_TP.mq5)** - Автоматическое обновление Stop Loss и Take Profit для позиций
- **[HandBrake4EA.mq5](MQ5_Codes/HandBrake4EA.mq5)** - Мониторинг и контроль торговой активности советника на основе уровня просадки
- **[SimpleLossFixer.mq5](MQ5_Codes/SimpleLossFixer.mq5)** - Мониторинг просадки по магическим номерам с возможностью закрытия позиций

### 🔄 Копирование торговли / Trade Copying

- **[PositionCopy_Server.mq5](MQ5_Codes/PositionCopy_Server.mq5)** - Сервер для записи позиций в файл (MQL5)
- **[PositionCopy_Client.mq5](MQ5_Codes/PositionCopy_Client.mq5)** - Клиент для копирования позиций с сервера (MQL5)
- **[PositionCopy_and_Orders_Server.mq4](MQ4_Codes/PositionCopy_and_Orders_Server.mq4)** - Сервер для записи позиций и ордеров в файл (MQL4)
- **[OrderCopyClient.mq5](MQ5_Codes/OrderCopyClient.mq5)** - Клиент для копирования отложенных ордеров и синхронизации позиций

### 📈 Анализ и уведомления / Analysis & Notifications

- **[SendTradesNotification.mq5](MQ5_Codes/SendTradesNotification.mq5)** - Отправка уведомлений об открытии и закрытии позиций
- **[CalculateHistoryProfit](MQ5_Codes/CalculateHistoryProfit/)** - Скрипт для расчета исторической прибыли с графическим интерфейсом

## Установка / Installation

1. Склонируйте репозиторий:
   ```bash
   git clone https://github.com/yourusername/MQL5_helpers.git
   ```

2. Скопируйте нужные файлы в соответствующие папки MetaTrader:
   - **MQL5 файлы**: `MQ5_Codes/*.mq5` → `MQL5/Experts/` или `MQL5/Scripts/`
   - **MQL4 файлы**: `MQ4_Codes/*.mq4` → `MQL4/Experts/`
   - **DLL файлы**: `MQ5_Codes/CalculateHistoryProfit/mql5/Libraries/*.dll` → `MQL5/Libraries/`

3. Скомпилируйте скрипты в MetaEditor

## Документация / Documentation

Подробная документация для каждого скрипта находится в папке [Readme/](Readme/):

- [Adjuster_for_SL_and_TP](Readme/Adjuster_for_SL_and_TP_README.md)
- [HandBrake4EA](Readme/HandBrake4EA_README.md)
- [OrderCopyClient](Readme/OrderCopyClient_README.md)
- [PositionCopy_and_Orders_Server](Readme/PositionCopy_and_Orders_Server_README.md)
- [PositionCopy_Client](Readme/PositionCopy_Client_README.md)
- [PositionCopy_Server](Readme/PositionCopy_Server_README.md)
- [SendTradesNotification](Readme/SendTradesNotification_README.md)
- [SimpleLossFixer](Readme/SimpleLossFixer_README.md)
- [CalculateHistoryProfit](Readme/CalculateHistoryProfit_README.md)

## Требования / Requirements

- MetaTrader 5 (для .mq5 файлов)
- MetaTrader 4 (для .mq4 файлов)
- Windows (для DLL библиотек)

## Лицензия / License

MIT License - см. файл [LICENSE](LICENSE) для подробностей.

## Автор / Author

Создано Snail000

## Поддержка / Support

Для вопросов и предложений создавайте Issues в репозитории.

---

## English Version

### Description

This repository contains a collection of useful MQL5/MQL4 scripts and Expert Advisors for MetaTrader 5/4 trading platforms. The tools include position management utilities, trade copying systems, drawdown monitoring, and trading history analysis tools.

### Project Structure

```
MQL5_helpers/
├── MQ5_Codes/           # MQL5 scripts and Expert Advisors
├── MQ4_Codes/           # MQL4 scripts and Expert Advisors  
├── Readme/              # Documentation for each script
└── README.md           # Main documentation
```

### Features

- **Position Management**: Automatic SL/TP adjustment, drawdown monitoring, loss control
- **Trade Copying**: Server-client architecture for copying trades between accounts
- **Notifications**: Real-time trade notifications
- **History Analysis**: Profit calculation with graphical interface

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/MQL5_helpers.git
   ```

2. Copy files to appropriate MetaTrader directories:
   - **MQL5 files**: `MQ5_Codes/*.mq5` → `MQL5/Experts/` or `MQL5/Scripts/`
   - **MQL4 files**: `MQ4_Codes/*.mq4` → `MQL4/Experts/`
   - **DLL files**: `MQ5_Codes/CalculateHistoryProfit/mql5/Libraries/*.dll` → `MQL5/Libraries/`

3. Compile scripts in MetaEditor

### Documentation

Detailed documentation for each script is available in the [Readme/](Readme/) folder.

### Requirements

- MetaTrader 5 (for .mq5 files)
- MetaTrader 4 (for .mq4 files)
- Windows (for DLL libraries)

### License

MIT License - see [LICENSE](LICENSE) file for details.

### Author

Created by Snail000

### Support

For questions and suggestions, please create Issues in the repository.
