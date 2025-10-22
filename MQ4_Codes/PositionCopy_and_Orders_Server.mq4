//+------------------------------------------------------------------+
//|                                                     PositionCopy |
//|                         Version 1.076 for MQL4                   |
//|                                                                  |
//|            Expert Advisor to copy and log position data          |
//|                                                                  |
//|  Последние изменения:                                            |
//|                                                                  |
//|    v1.076:                                                       |
//|  - ИСПРАВЛЕНО: Ошибки компиляции "sign mismatch" при сравнении типов |
//|                                                                  |
//|    v1.075:                                                       |
//|  - ИСПРАВЛЕНО: Отображение на графике теперь обновляется регулярно |
//|  - Добавлена информация о текущей прибыли/убытке позиций        |
//|  - Добавлена сводная информация (количество позиций, общий P&L) |
//|  - Добавлено время последнего обновления на графике             |
//|                                                                  |
//|    v1.074:                                                       |
//|  - Добавлено подробное логирование изменений позиций/ордеров     |
//|  - Логирование времени записи файла и задержек                  |
//|  - Новый параметр syncTimeMs (миллисекунды) вместо syncTime      |
//|  - Параметр verbose_logging для отладки                         |
//|  - Минимизация спама в логах                                    |
//|                                                                  |
//|    v1.073:                                                       |
//|  - Добавлена поддержка отложенных ордеров с опцией pendingOrders |
//|  - Отложенные ордера сохраняются в отдельный файл _ord.csv       |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Snail000 (fixed by Grok)"
#property link        "https://www.mql5.com"
#property version     "1.076"
#property description "- ИСПРАВЛЕНО: Ошибки компиляции 'sign mismatch' при сравнении типов"
#property description "- ИСПРАВЛЕНО: Отображение на графике теперь обновляется регулярно"
#property description "- Добавлена информация о текущей прибыли/убытке позиций"
#property description "- Добавлена сводная информация (количество позиций, общий P&L)"

//--- input parameters
input int     syncTimeMs = 50;           // Время синхронизации (миллисекунды)
input string  shareName = "PositionCopy"; // Имя для файлов и отображения
input string  shareSymbol = "All";       // Фильтр символов (All или список через ;)
input string  shareMagic = "All";        // Фильтр магиков (All или список через ;)
input bool    pendingOrders = false;      // Включить сохранение отложенных ордеров
input bool    verbose_logging = false;    // Включить подробное логирование для отладки
string fileName = shareName + ".csv";     // Имя файла для позиций
string ordersSuffix = shareName + "_ord.csv"; // Имя файла для отложенных ордеров

//--- Глобальные массивы для хранения предыдущих данных
double last_positions_data[][3]; // [ticket, stoploss, takeprofit]
double last_orders_data[][4];    // [ticket, stoploss, takeprofit, price]

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int init()
{
    Print("init: Initializing PositionCopy v1.074...");
    EventSetMillisecondTimer(syncTimeMs);
    display_positions();
    string positions_data = GetAllPositions();
    WriteToFile(fileName, positions_data);
    Print("init: Initial positions data written to file ", fileName);
    if (pendingOrders)
    {
        string orders_data = GetAllPendingOrders();
        WriteToFile(ordersSuffix, orders_data);
        Print("init: Initial pending orders data written to file ", ordersSuffix);
    }
    return(0);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
int deinit()
{
    Print("deinit: Cleaning up...");
    EventKillTimer();
    Comment("");
    return(0);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    uint start_time = GetTickCount();
    bool positions_changed = HasPositionsChanged();
    uint elapsed_time = GetTickCount() - start_time;

    if (positions_changed)
    {
        string data = GetAllPositions();
        WriteToFile(fileName, data);
        Print("OnTimer: New position data written to file ", fileName, ", processing time: ", elapsed_time, " ms");
    }
    else if (verbose_logging)
    {
        Print("OnTimer: No position changes detected, processing time: ", elapsed_time, " ms");
    }

    if (pendingOrders)
    {
        start_time = GetTickCount();
        bool orders_changed = HasPendingOrdersChanged();
        elapsed_time = GetTickCount() - start_time;

        if (orders_changed)
        {
            string orders_data = GetAllPendingOrders();
            WriteToFile(ordersSuffix, orders_data);
            Print("OnTimer: New pending orders data written to file ", ordersSuffix, ", processing time: ", elapsed_time, " ms");
        }
        else if (verbose_logging)
        {
            Print("OnTimer: No pending order changes detected, processing time: ", elapsed_time, " ms");
        }
    }

    // Always update display on chart regardless of changes
    display_positions();

    // Warn if processing time is too high
    if (elapsed_time > (uint)syncTimeMs)
    {
        Print("OnTimer: Warning: Processing time (", elapsed_time, " ms) exceeds syncTimeMs (", syncTimeMs, " ms)");
    }
}

//+------------------------------------------------------------------+
//| Function to check if positions have changed                      |
//+------------------------------------------------------------------+
bool HasPositionsChanged()
{
    bool is_changed = false;
    int total = OrdersTotal();
    double current_positions_data[][3];
    ArrayResize(current_positions_data, total);

    int pos_count = 0;
    for (int i = 0; i < total; i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderType() <= OP_SELL && IsSymbolFiltered(OrderSymbol()) && IsMagicFiltered(OrderMagicNumber()))
            {
                current_positions_data[pos_count][0] = OrderTicket();
                current_positions_data[pos_count][1] = OrderStopLoss();
                current_positions_data[pos_count][2] = OrderTakeProfit();
                pos_count++;

                bool pos_found = false;
                for (int j = 0; j < ArrayRange(last_positions_data, 0); j++)
                {
                    if (last_positions_data[j][0] == OrderTicket())
                    {
                        pos_found = true;
                        if (last_positions_data[j][1] != OrderStopLoss() || last_positions_data[j][2] != OrderTakeProfit())
                        {
                            is_changed = true;
                            Print("HasPositionsChanged: Position modified, ticket: ", OrderTicket(),
                                  ", symbol: ", OrderSymbol(), ", SL: ", OrderStopLoss(), " (was ", last_positions_data[j][1], ")",
                                  ", TP: ", OrderTakeProfit(), " (was ", last_positions_data[j][2], ")");
                        }
                        break;
                    }
                }
                if (!pos_found)
                {
                    is_changed = true;
                    Print("HasPositionsChanged: New position opened, ticket: ", OrderTicket(),
                          ", symbol: ", OrderSymbol(), ", type: ", (OrderType() == OP_BUY ? "BUY" : "SELL"),
                          ", volume: ", OrderLots());
                }
            }
        }
    }
    ArrayResize(current_positions_data, pos_count);

    // Проверяем закрытые позиции
    for (int k = ArrayRange(last_positions_data, 0) - 1; k >= 0; k--)
    {
        bool found = false;
        for (int m = 0; m < pos_count; m++)
        {
            if (last_positions_data[k][0] == current_positions_data[m][0])
            {
                found = true;
                break;
            }
        }
        if (!found)
        {
            is_changed = true;
            Print("HasPositionsChanged: Position closed, ticket: ", last_positions_data[k][0]);
            ArrayRemovePositions(last_positions_data, k);
        }
    }

    ArrayCopy(last_positions_data, current_positions_data);

    return is_changed;
}

//+------------------------------------------------------------------+
//| Function to check if pending orders have changed                 |
//+------------------------------------------------------------------+
bool HasPendingOrdersChanged()
{
    bool is_changed = false;
    int total = OrdersTotal();
    double current_orders_data[][4];
    ArrayResize(current_orders_data, total);

    int order_count = 0;
    for (int i = 0; i < total; i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderType() > OP_SELL && IsSymbolFiltered(OrderSymbol()) && IsMagicFiltered(OrderMagicNumber()))
            {
                current_orders_data[order_count][0] = OrderTicket();
                current_orders_data[order_count][1] = OrderStopLoss();
                current_orders_data[order_count][2] = OrderTakeProfit();
                current_orders_data[order_count][3] = OrderOpenPrice();
                order_count++;

                bool ord_found = false;
                for (int j = 0; j < ArrayRange(last_orders_data, 0); j++)
                {
                    if (last_orders_data[j][0] == OrderTicket())
                    {
                        ord_found = true;
                        if (last_orders_data[j][1] != OrderStopLoss() || 
                            last_orders_data[j][2] != OrderTakeProfit() || 
                            last_orders_data[j][3] != OrderOpenPrice())
                        {
                            is_changed = true;
                            Print("HasPendingOrdersChanged: Order modified, ticket: ", OrderTicket(),
                                  ", symbol: ", OrderSymbol(), ", type: ", GetOrderTypeString(OrderType()),
                                  ", SL: ", OrderStopLoss(), " (was ", last_orders_data[j][1], ")",
                                  ", TP: ", OrderTakeProfit(), " (was ", last_orders_data[j][2], ")",
                                  ", price: ", OrderOpenPrice(), " (was ", last_orders_data[j][3], ")");
                        }
                        break;
                    }
                }
                if (!ord_found)
                {
                    is_changed = true;
                    Print("HasPendingOrdersChanged: New order placed, ticket: ", OrderTicket(),
                          ", symbol: ", OrderSymbol(), ", type: ", GetOrderTypeString(OrderType()),
                          ", volume: ", OrderLots());
                }
            }
        }
    }
    ArrayResize(current_orders_data, order_count);

    // Проверяем удаленные ордера
    for (int k = ArrayRange(last_orders_data, 0) - 1; k >= 0; k--)
    {
        bool found = false;
        for (int m = 0; m < order_count; m++)
        {
            if (last_orders_data[k][0] == current_orders_data[m][0])
            {
                found = true;
                break;
            }
        }
        if (!found)
        {
            is_changed = true;
            Print("HasPendingOrdersChanged: Order deleted, ticket: ", last_orders_data[k][0]);
            ArrayRemoveOrders(last_orders_data, k);
        }
    }

    ArrayCopy(last_orders_data, current_orders_data);

    return is_changed;
}

//+------------------------------------------------------------------+
//| Helper function to get order type string                         |
//+------------------------------------------------------------------+
string GetOrderTypeString(int order_type)
{
    switch (order_type)
    {
        case OP_BUYLIMIT:  return "OP_BUYLIMIT";
        case OP_BUYSTOP:   return "OP_BUYSTOP";
        case OP_SELLLIMIT: return "OP_SELLLIMIT";
        case OP_SELLSTOP:  return "OP_SELLSTOP";
        default:           return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Function to remove element from array                            |
//+------------------------------------------------------------------+
void ArrayRemovePositions(double &array[][3], int index)
{
    for (int i = index; i < ArrayRange(array, 0) - 1; i++)
    {
        array[i][0] = array[i + 1][0];
        array[i][1] = array[i + 1][1];
        array[i][2] = array[i + 1][2];
    }
    ArrayResize(array, ArrayRange(array, 0) - 1);
}

void ArrayRemoveOrders(double &array[][4], int index)
{
    for (int i = index; i < ArrayRange(array, 0) - 1; i++)
    {
        array[i][0] = array[i + 1][0];
        array[i][1] = array[i + 1][1];
        array[i][2] = array[i + 1][2];
        array[i][3] = array[i + 1][3];
    }
    ArrayResize(array, ArrayRange(array, 0) - 1);
}

//+------------------------------------------------------------------+
//| Function to get all positions                                    |
//+------------------------------------------------------------------+
string GetAllPositions()
{
    string positions = "";
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderType() <= OP_SELL && IsSymbolFiltered(OrderSymbol()) && IsMagicFiltered(OrderMagicNumber()))
            {
                string symbol = OrderSymbol();
                int orientation = (OrderType() == OP_BUY) ? 1 : -1;
                double volume = OrderLots();
                double price = OrderOpenPrice();
                double stoploss = OrderStopLoss();
                double takeprofit = OrderTakeProfit();
                string acc_currency = AccountCurrency();
                double acc_balance = AccountBalance();
                double acc_credit = AccountCredit();
                double acc_marginFree = AccountFreeMargin();
                datetime time = OrderOpenTime();
                datetime time_gmt = time + (CustomTimeGMTOffset() / 1000);
                double contract = MarketInfo(symbol, MODE_LOTSIZE);
                string comment = OrderComment();

                positions += IntegerToString(OrderTicket()) + ";" + symbol + ";" + IntegerToString(orientation) + ";" + 
                            DoubleToString(volume, 2) + ";" + DoubleToString(price, (int)MarketInfo(symbol, MODE_DIGITS)) + ";" + 
                            DoubleToString(stoploss, (int)MarketInfo(symbol, MODE_DIGITS)) + ";" + 
                            DoubleToString(takeprofit, (int)MarketInfo(symbol, MODE_DIGITS)) + ";" + 
                            acc_currency + ";" + DoubleToString(acc_balance, 2) + ";" + 
                            DoubleToString(acc_credit, 2) + ";" + DoubleToString(acc_marginFree, 2) + ";" + 
                            TimeToString(time) + ";" + TimeToString(time_gmt) + ";" + 
                            DoubleToString(contract) + ";" + IntegerToString(OrderMagicNumber()) + ";" + comment + "\n";
            }
        }
    }
    return positions;
}

//+------------------------------------------------------------------+
//| Function to get all pending orders                               |
//+------------------------------------------------------------------+
string GetAllPendingOrders()
{
    string orders = "";
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderType() > OP_SELL && IsSymbolFiltered(OrderSymbol()) && IsMagicFiltered(OrderMagicNumber()))
            {
                string symbol = OrderSymbol();
                string order_type = GetOrderTypeString(OrderType());
                double volume = OrderLots();
                double price = OrderOpenPrice();
                double stoploss = OrderStopLoss();
                double takeprofit = OrderTakeProfit();
                string acc_currency = AccountCurrency();
                double acc_balance = AccountBalance();
                double acc_credit = AccountCredit();
                double acc_marginFree = AccountFreeMargin();
                datetime time = OrderOpenTime();
                datetime time_gmt = time + (CustomTimeGMTOffset() / 1000);
                double contract = MarketInfo(symbol, MODE_LOTSIZE);
                string comment = OrderComment();

                orders += IntegerToString(OrderTicket()) + ";" + symbol + ";" + order_type + ";" + 
                         DoubleToString(volume, 2) + ";" + DoubleToString(price, (int)MarketInfo(symbol, MODE_DIGITS)) + ";" + 
                         DoubleToString(stoploss, (int)MarketInfo(symbol, MODE_DIGITS)) + ";" + 
                         DoubleToString(takeprofit, (int)MarketInfo(symbol, MODE_DIGITS)) + ";" + 
                         acc_currency + ";" + DoubleToString(acc_balance, 2) + ";" + 
                         DoubleToString(acc_credit, 2) + ";" + DoubleToString(acc_marginFree, 2) + ";" + 
                         TimeToString(time) + ";" + TimeToString(time_gmt) + ";" + 
                         DoubleToString(contract) + ";" + IntegerToString(OrderMagicNumber()) + ";" + comment + "\n";
            }
        }
    }
    return orders;
}

//+------------------------------------------------------------------+
//| Function to write data to a file in the common directory         |
//+------------------------------------------------------------------+
void WriteToFile(string file_name, string data)
{
    uint elapsed_time;
    uint start_time = GetTickCount();
    string temp_file_name = file_name + ".tmp";
    int file_handle = FileOpen(temp_file_name, FILE_CSV | FILE_WRITE | FILE_COMMON | FILE_UNICODE);
    if (file_handle != INVALID_HANDLE)
    {
        FileWrite(file_handle, data);
        FileClose(file_handle);

        int attempts = 10;
        int delay = 25;
        bool success = false;
        for (int i = 0; i < attempts; i++)
        {
            if (FileMove(temp_file_name, FILE_COMMON, file_name, FILE_COMMON | FILE_REWRITE))
            {
                success = true;
                break;
            }
            Print("WriteToFile: Error: Unable to rename temporary file to ", file_name, ", attempt: ", i + 1, ", error: ", GetLastError());
            Sleep(delay);
        }
        elapsed_time = GetTickCount() - start_time;
        if (success)
        {
            Print("WriteToFile: File ", file_name, " written successfully, time: ", elapsed_time, " ms");
        }
        else
        {
            Print("WriteToFile: Failed to write file ", file_name, " after ", attempts, " attempts, time: ", elapsed_time, " ms");
        }
        if (elapsed_time > (uint)syncTimeMs)
        {
            Print("WriteToFile: Warning: File write time (", elapsed_time, " ms) exceeds syncTimeMs (", syncTimeMs, " ms)");
        }
    }
    else
    {
        elapsed_time = GetTickCount() - start_time;
        Print("WriteToFile: Error: Unable to open file ", temp_file_name, ", error: ", GetLastError(), ", time: ", elapsed_time, " ms");
    }
}

//+------------------------------------------------------------------+
//| Function to display on chart all opened positions and orders     |
//+------------------------------------------------------------------+
void display_positions()
{
    string comments = "\n\n\n        [ " + shareName + " ]:\n";
    comments += "        Last Update: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\n\n";
    
    int position_count = 0;
    int order_count = 0;
    double total_profit = 0.0;
    
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            string symbol = OrderSymbol();
            int magic = OrderMagicNumber();
            if (IsSymbolFiltered(symbol) && IsMagicFiltered(magic))
            {
                double volume = OrderLots();
                double price = OrderOpenPrice();
                string comment = OrderComment();
                
                if (OrderType() <= OP_SELL)
                {
                    position_count++;
                    double profit = OrderProfit() + OrderSwap() + OrderCommission();
                    total_profit += profit;
                    
                    string profit_str = DoubleToString(profit, 2);
                    if (profit > 0) profit_str = "+" + profit_str;
                    
                    comments += "                [Position] " + IntegerToString(OrderTicket()) + " | " + symbol + " | " + 
                               DoubleToString(volume, 2) + " | " + DoubleToString(price, (int)MarketInfo(symbol, MODE_DIGITS)) + 
                               " | P&L: " + profit_str + " | " + comment + "\n";
                }
                else if (pendingOrders)
                {
                    order_count++;
                    string order_type = GetOrderTypeString(OrderType());
                    comments += "                [Order] " + IntegerToString(OrderTicket()) + " | " + symbol + " | " + 
                               order_type + " | " + DoubleToString(volume, 2) + " | " + 
                               DoubleToString(price, (int)MarketInfo(symbol, MODE_DIGITS)) + " | " + comment + "\n";
                }
            }
        }
    }
    
    // Add summary information
    comments += "\n        Summary:\n";
    comments += "        Positions: " + IntegerToString(position_count) + "\n";
    if (pendingOrders) comments += "        Orders: " + IntegerToString(order_count) + "\n";
    comments += "        Total P&L: " + DoubleToString(total_profit, 2) + "\n";
    
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
        if (StringCompare(symbol, symbols[i], false) == 0)
            return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Helper function to check if magic number is filtered             |
//+------------------------------------------------------------------+
bool IsMagicFiltered(int magic)
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

//+------------------------------------------------------------------+
//| Helper function to split string                                  |
//+------------------------------------------------------------------+
int StringSplit(string input_str, char separator, string &result[])
{
    ArrayResize(result, 0);
    string temp = input_str;
    int pos;
    while ((pos = StringFind(temp, CharToStr(separator))) != -1)
    {
        ArrayResize(result, ArraySize(result) + 1);
        result[ArraySize(result) - 1] = StringSubstr(temp, 0, pos);
        temp = StringSubstr(temp, pos + 1);
    }
    ArrayResize(result, ArraySize(result) + 1);
    result[ArraySize(result) - 1] = temp;
    return ArraySize(result);
}

//+------------------------------------------------------------------+
//| Helper function to simulate TimeGMTOffset                        |
//+------------------------------------------------------------------+
int CustomTimeGMTOffset()
{
    return (TimeLocal() - TimeGMT()) * 1000; // Возвращаем в миллисекундах
}