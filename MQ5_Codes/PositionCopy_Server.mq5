//+-------------------------------------------------------------------+
//|                                                     PositionCopy  |
//|                         Version 1.072                             |
//|                                                                   |
//|            Expert Advisor to copy and log position data           |
//|                                                                   |
//|  Последние изменения:                                             |
//|                                                                   |
//|    v1.72:                                                         |
//|  - откоректированно слежение за изменениями значений TP и SL      |
//|                                                                   |
//|    v1.6:                                                          |
//|  - Добавленно сохранение временной метки обновления позиции для   |
//|    того что-бы не пропустить изменения даже в случае очень быстых |
//|                                                                   |
//|    v1.5:                                                          |
//|  - Добавлена поддержка фильтрации позиций по символам и магическим|
//|    номерам через параметры shareSymbol и shareMagic               |
//|  - Обновлена функция GetAllPositions для использования фильтров   |
//|  - Обновлена функция GetPositionsForComparison для использования  |
//|    фильтров                                                       |
//+-------------------------------------------------------------------+

#property copyright   "Snail000"
#property link        "https://www.mql5.com"
#property version     "1.072"
#property description "- добавлена фильтрация по символам и мэджикам"

//--- input parameters
input uint    syncTime = 1;
input string  shareName = "PositionCopy";
input string  shareSymbol = "All";
input string  shareMagic = "All";
string fileName = shareName + ".csv";

//+------------------------------------------------------------------+
//| Структура для хранения информации о позициях                     |
//+------------------------------------------------------------------+
struct PositionData
{
    ulong ticket;
    double stoploss;
    double takeprofit;
};

//--- Храним предыдущее состояние позиций
static PositionData last_positions_data[];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("OnInit: Initializing expert advisor...");
    EventSetMillisecondTimer(syncTime); // Устанавливаем таймер
    display_positions();
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("OnDeinit: Cleaning up...");
    EventKillTimer();
    Comment(""); // Удаляем комментарий с графика
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // display_positions();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    if (HasPositionsChanged())
    {
        string data = GetAllPositions();
        WriteToFile(fileName, data);
        display_positions();
        Print("OnTimer: New Data has written to file.");
    }
}

//+------------------------------------------------------------------+
//| Function to check if positions have changed                      |
//+------------------------------------------------------------------+
bool HasPositionsChanged()
{
    bool is_changed = false;

    // Получаем текущее состояние позиций
    uint size = PositionsTotal();
    PositionData current_positions_data[];
    ArrayResize(current_positions_data, size);

    // Сохраняем текущие данные в структуру
    for (uint i = 0; i < size; i++)
    {
        ulong ticket = PositionGetTicket(i);
        PositionSelectByTicket(ticket);
        double stoploss = PositionGetDouble(POSITION_SL);
        double takeprofit = PositionGetDouble(POSITION_TP);

        current_positions_data[i].ticket = ticket;
        current_positions_data[i].stoploss = stoploss;
        current_positions_data[i].takeprofit = takeprofit;

        // Ищем в предыдущих данных позицию с таким же тикетом
        bool found = false;
        for (int j = 0; j < ArraySize(last_positions_data); j++)
        {
            if (last_positions_data[j].ticket == ticket)
            {
                found = true;
                // Проверяем, изменились ли SL или TP
                if (last_positions_data[j].stoploss != stoploss || last_positions_data[j].takeprofit != takeprofit)
                {
                    is_changed = true;  // Есть изменения
                }
                break;
            }
        }

        // Если позиция не найдена в предыдущих данных, значит, это новая позиция или изменилась
        if (!found)
        {
            is_changed = true;
        }
    }

    // Проверяем закрытые позиции и удаляем их из last_positions_data
    for (int j = ArraySize(last_positions_data) - 1; j >= 0; j--)
    {
        bool found = false;
        for (uint i = 0; i < size; i++)
        {
            if (last_positions_data[j].ticket == current_positions_data[i].ticket)
            {
                found = true;
                break;
            }
        }

        // Если позиция из предыдущих данных не найдена в текущих позициях, значит, она была закрыта
        if (!found)
        {
            is_changed = true;
            // Удаляем закрытую позицию из last_positions_data
            ArrayRemove(last_positions_data, j);
        }
    }

    // Обновляем массив предыдущих данных
    ArrayCopy(last_positions_data, current_positions_data);

    return is_changed;
}

//+------------------------------------------------------------------+
//| Function to remove element from array                            |
//+------------------------------------------------------------------+
void ArrayRemove(PositionData &array[], int index)
{
    for (int i = index; i < ArraySize(array) - 1; i++)
    {
        array[i] = array[i + 1];
    }
    ArrayResize(array, ArraySize(array) - 1);
}

//+------------------------------------------------------------------+
//| Function to get all positions                                    |
//+------------------------------------------------------------------+
string GetAllPositions()
{
    string positions;
    uint size = PositionsTotal();
    for (uint i = 0; i < size; i++)
    {
        ulong ticket = PositionGetTicket(i);
        PositionSelectByTicket(ticket);
        string symbol = PositionGetString(POSITION_SYMBOL);
        ulong magic = PositionGetInteger(POSITION_MAGIC);

        if (IsSymbolFiltered(symbol) && IsMagicFiltered(magic))
        {
            ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            int orientation = positionType == POSITION_TYPE_BUY ? 1 : -1;
            double volume = PositionGetDouble(POSITION_VOLUME);
            double price = PositionGetDouble(POSITION_PRICE_OPEN);
            double stoploss = PositionGetDouble(POSITION_SL);
            double takeprofit = PositionGetDouble(POSITION_TP);

            string acc_currency = AccountInfoString(ACCOUNT_CURRENCY);
            double acc_balance = AccountInfoDouble(ACCOUNT_BALANCE);
            double acc_credit = AccountInfoDouble(ACCOUNT_CREDIT);
            double acc_marginFree = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

            datetime time = (datetime)PositionGetInteger(POSITION_TIME);
            datetime time_gmt = (datetime)PositionGetInteger(POSITION_TIME) + TimeGMTOffset();

            double contract = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
            string comment = PositionGetString(POSITION_COMMENT);

            positions += IntegerToString(ticket) + ";" + symbol + ";" + IntegerToString(orientation) + ";" + DoubleToString(volume, 2) + ";" + DoubleToString(price, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + ";" + DoubleToString(stoploss, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + ";" + DoubleToString(takeprofit, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + ";" + acc_currency + ";" + DoubleToString(acc_balance, 2) + ";" + DoubleToString(acc_credit, 2) + ";" + DoubleToString(acc_marginFree, 2) + ";" + TimeToString(time) + ";" + TimeToString(time_gmt) + ";" + DoubleToString(contract) + ";" + IntegerToString(magic) + ";" + comment + "\n";
        }
    }
    return positions;
}

//+------------------------------------------------------------------+
//| Function to get position data for Comparison                     |
//+------------------------------------------------------------------+
string GetPositionsForComparison()
{
    string positions;
    uint size = PositionsTotal();
    for (uint i = 0; i < size; i++)
    {
        ulong ticket = PositionGetTicket(i);
        PositionSelectByTicket(ticket);
        string symbol = PositionGetString(POSITION_SYMBOL);
        ulong magic = PositionGetInteger(POSITION_MAGIC);

        if (IsSymbolFiltered(symbol) && IsMagicFiltered(magic))
        {
            double volume = PositionGetDouble(POSITION_VOLUME);
            double stoploss = PositionGetDouble(POSITION_SL);
            double takeprofit = PositionGetDouble(POSITION_TP);
            datetime update_time = (datetime)PositionGetInteger(POSITION_TIME_UPDATE); // Время последнего обновления позиции

            positions += IntegerToString(ticket) + ";" + DoubleToString(volume, 2) + ";" + DoubleToString(stoploss, 2) + ";" + DoubleToString(takeprofit, 2) + ";" + TimeToString(update_time) + "\n";
        }
    }
    return positions;
}

//+------------------------------------------------------------------+
//| Function to write data to a file                                 |
//+------------------------------------------------------------------+
void WriteToFile(string file_name, string data)
{
    string temp_file_name = file_name + ".tmp"; // Временное имя файла

    // Открытие временного файла для записи
    int file_handle = FileOpen(temp_file_name, FILE_WRITE | FILE_CSV | FILE_COMMON);
    if (file_handle != INVALID_HANDLE)
    {
        FileWrite(file_handle, data);
        FileClose(file_handle);

        // Переименование временного файла в основной с несколькими попытками
        int attempts = 10; // Количество попыток переименования файла
        int delay = 25;   // Задержка между попытками в миллисекундах

        for (int i = 0; i < attempts; i++)
        {
            if (FileMove(temp_file_name, FILE_COMMON, file_name, FILE_COMMON | FILE_REWRITE))
            {
                break; // Успешное переименование файла
            }
            if (i > -1) Print("Error: Unable to rename temporary file to: ", file_name, ", attempt: ", i);
            Sleep(delay); // Задержка перед следующей попыткой
        }
    }
    else
    {
        Print("Error: Unable to open file for writing: ", temp_file_name);
    }
}

//+------------------------------------------------------------------+
//| Function to display on chart all opened positions                |
//+------------------------------------------------------------------+
void display_positions()
{
    string comments = "\n\n\n        [ " + shareName + " ]:\n\n";
    uint size = PositionsTotal();
    for (uint i = 0; i < size; i++)
    {
        ulong ticket = PositionGetTicket(i);
        PositionSelectByTicket(ticket);
        string symbol = PositionGetString(POSITION_SYMBOL);
        ulong magic = PositionGetInteger(POSITION_MAGIC);

        if (IsSymbolFiltered(symbol) && IsMagicFiltered(magic))
        {
            double volume = PositionGetDouble(POSITION_VOLUME);
            double price = PositionGetDouble(POSITION_PRICE_OPEN);
            string comment = PositionGetString(POSITION_COMMENT);

            comments += "                " + IntegerToString(ticket) + " | " + symbol + " | " + DoubleToString(volume, 2) + " | " + DoubleToString(price, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + " | " + comment + "\n";
        }
    }
    Comment(comments);
}

//+------------------------------------------------------------------+
//| Helper function to check if symbol is filtered                   |
//+------------------------------------------------------------------+
bool IsSymbolFiltered(string symbol)
{
    if (shareSymbol == "All" || shareSymbol == "")
        return true;

    string symbols[];
    StringSplit(shareSymbol, ';', symbols);
    for (int i = 0; i < ArraySize(symbols); i++)
    {
        if (StringCompare(symbol, symbols[i]) == 0)
            return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Helper function to check if magic number is filtered             |
//+------------------------------------------------------------------+
bool IsMagicFiltered(ulong magic)
{
    if (shareMagic == "All" || shareMagic == "")
        return true;

    string magics[];
    StringSplit(shareMagic, ';', magics);
    for (int i = 0; i < ArraySize(magics); i++)
    {
        if (StringToInteger(magics[i]) == magic)
            return true;
    }
    return false;
}
