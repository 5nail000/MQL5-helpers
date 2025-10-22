//+---------------------------------------------------------------------+
//|                                                  OrderCopyClient    |
//|                         Version 1.3 for MQL5 (Fixed Logging)        |
//|                                                                     |
//|  Expert Advisor to copy pending orders and sync positions from file |
//|                                                                     |
//|  Changes in v1.3:                                                   |
//|  - Reduced logging spam: logs only when positions/orders present    |
//|  - Added verbose_logging input for detailed logging control         |
//|  - Dynamic filling mode based on symbol settings                    |
//|  - Retry mechanism for close failures (e.g., error 4756)            |
//|  - Increased recent position skip to 60 sec                         |
//+---------------------------------------------------------------------+

#property copyright   "Snail000 (fixed by Grok)"
#property link        "https://www.mql5.com"
#property version     "1.3"
#property description "- Copies pending orders and syncs positions from files in Common\\Files"
#property description "- Synchronizes every 15 minutes with 1-minute offset"
#property description "- Supports symbol/magic filtering and volume modes"
#property description "- Tracks position SL/TP changes (optional)"
#property description "- Optional closing of positions by server signal"
#property description "- Reduced logging to avoid spam"
#property description "- Added verbose_logging for debug control"

#include <Trade\Trade.mqh>

//--- Enum for volume calculation modes
enum CopyType
{
   FixedLotSize = 1, // Fixed lot size
   Proportional = 2  // Proportional to source volume
};

//--- Input parameters
input string   shareName = "PositionCopy"; // File name prefix (e.g., PositionCopy_ord.csv, PositionCopy.csv)
input uint     syncTime = 100;             // Check interval (milliseconds)
input uint     syncIntervalMinutes = 15;   // Synchronization interval (minutes)
input string   filterSymbol = "";          // Symbol filter (empty or All = no filter)
input string   filterMagic = "";           // Magic filter (empty or All = no filter)
input CopyType copyType = FixedLotSize;    // Volume calculation mode
input double   fixVolume = 0.01;           // Fixed volume for FixedLotSize mode
input double   proportional = 1;           // Proportional multiplier for Proportional mode
input long     newMagicNumber = 333;       // Magic number for copied orders/positions
input string   newComment = "Comment";     // Comment for copied orders/positions
input int      timeToleranceSec = 15;      // Допуск времени открытия позиций в секундах
input bool     closeByServer = false;      // Close positions only by server signal
input bool     verbose_logging = false;    // Enable detailed logging for debugging

//--- Structure for order data
struct OrderData
{
   ulong  ticket;
   string symbol;
   ENUM_ORDER_TYPE type;
   double volume;
   double price;
   double stoploss;
   double takeprofit;
   long   magic;
   string comment;
};

//--- Structure for position data
struct PositionData
{
   ulong  ticket;
   string symbol;
   ENUM_POSITION_TYPE type;
   double volume;
   double price;
   double stoploss;
   double takeprofit;
   long   magic;
   string comment;
   datetime open_time;
};

//--- Global variables
datetime last_sync_time = 0;
string orders_file_name = shareName + "_ord.csv";
string positions_file_name = shareName + ".csv";

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("OnInit: Initializing OrderCopyClient v1.3...");
   if(!FileIsExist(orders_file_name, FILE_COMMON))
   {
      Print("OnInit: Orders file ", orders_file_name, " not found in Common\\Files");
   }
   if(!FileIsExist(positions_file_name, FILE_COMMON))
   {
      Print("OnInit: Positions file ", positions_file_name, " not found in Common\\Files");
   }
   EventSetMillisecondTimer(syncTime);
   SyncOrders();
   SyncPositions();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("OnDeinit: Cleaning up, reason: ", reason);
   EventKillTimer();
   Comment("");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   datetime current_time = TimeCurrent();
   MqlDateTime time_struct;
   TimeToStruct(current_time, time_struct);

   if(time_struct.min % syncIntervalMinutes == 0 && current_time - last_sync_time >= 60)
   {
      SyncOrders();
      last_sync_time = current_time;
      if(verbose_logging) Print("OnTimer: Orders synchronized at ", TimeToString(current_time));
   }

   SyncPositions();
}

//+------------------------------------------------------------------+
//| Synchronize positions                                            |
//+------------------------------------------------------------------+
void SyncPositions()
{
   PositionData file_positions[];
   if(!ReadPositionsFromFile(file_positions))
   {
      Print("SyncPositions: Failed to read positions from file ", positions_file_name);
      return;
   }

   PositionData current_positions[];
   GetCurrentPositions(current_positions);

   // Логировать только при наличии позиций или в verbose-режиме
   if(verbose_logging || ArraySize(file_positions) > 0 || ArraySize(current_positions) > 0)
   {
      // Print("SyncPositions: Starting position synchronization at ", TimeToString(TimeCurrent()));
      // Print("SyncPositions: Read ", ArraySize(file_positions), " positions from file");
      // Print("SyncPositions: Found ", ArraySize(current_positions), " current positions in terminal");
   }

   // Add or modify positions
   for(int i = 0; i < ArraySize(file_positions); i++)
   {
      bool found = false;
      for(int j = 0; j < ArraySize(current_positions); j++)
      {
         if(file_positions[i].symbol == current_positions[j].symbol &&
            file_positions[i].type == current_positions[j].type &&
            MathAbs(file_positions[i].open_time - current_positions[j].open_time) <= timeToleranceSec)
         {
            found = true;
            if(!closeByServer)
            {
               int digits = (int)SymbolInfoInteger(file_positions[i].symbol, SYMBOL_DIGITS);
               double file_sl = file_positions[i].stoploss == 0 ? 0 : NormalizeDouble(file_positions[i].stoploss, digits);
               double current_sl = current_positions[j].stoploss == 0 ? 0 : NormalizeDouble(current_positions[j].stoploss, digits);
               double file_tp = file_positions[i].takeprofit == 0 ? 0 : NormalizeDouble(file_positions[i].takeprofit, digits);
               double current_tp = current_positions[j].takeprofit == 0 ? 0 : NormalizeDouble(current_positions[j].takeprofit, digits);

               if(file_sl != current_sl || file_tp != current_tp)
               {
                  Print("SyncPositions: Detected changes for position ticket ", current_positions[j].ticket,
                        ", symbol ", file_positions[i].symbol, ", type ", EnumToString(file_positions[i].type),
                        ", SL: ", file_sl, " vs ", current_sl, ", TP: ", file_tp, " vs ", current_tp);
                  ModifyPosition(current_positions[j].ticket, file_positions[i]);
               }
               else if(verbose_logging)
               {
                  Print("SyncPositions: No changes for position ticket ", current_positions[j].ticket,
                        ", symbol ", file_positions[i].symbol, ", type ", EnumToString(file_positions[i].type));
               }
            }
            break;
         }
      }
      if(!found)
      {
         Print("SyncPositions: No matching position found for server position: symbol ", file_positions[i].symbol,
               ", type ", EnumToString(file_positions[i].type), ", open_time ", TimeToString(file_positions[i].open_time));
      }
   }

   // Close positions not in file (if closeByServer is true)
   if(closeByServer)
   {
      for(int i = 0; i < ArraySize(current_positions); i++)
      {
         bool found = false;
         for(int j = 0; j < ArraySize(file_positions); j++)
         {
            if(current_positions[i].symbol == file_positions[j].symbol &&
               current_positions[i].type == file_positions[j].type &&
               MathAbs(current_positions[i].open_time - file_positions[j].open_time) <= timeToleranceSec)
            {
               found = true;
               break;
            }
         }
         if(!found)
         {
            if(TimeCurrent() - current_positions[i].open_time < 60)
            {
               Print("SyncPositions: Skipping closure of recent position ticket ", current_positions[i].ticket,
                     ", symbol ", current_positions[i].symbol, ", type ", EnumToString(current_positions[i].type));
               continue;
            }
            Print("SyncPositions: Attempting to close position ticket ", current_positions[i].ticket,
                  ", symbol ", current_positions[i].symbol, ", type ", EnumToString(current_positions[i].type));
            ClosePosition(current_positions[i].ticket);
         }
      }
   }

   if(verbose_logging || ArraySize(file_positions) > 0 || ArraySize(current_positions) > 0)
   {
      // Print("SyncPositions: Position synchronization completed at ", TimeToString(TimeCurrent()));
   }
}

//+------------------------------------------------------------------+
//| Synchronization function for orders                              |
//+------------------------------------------------------------------+
void SyncOrders()
{
   OrderData file_orders[];
   if(!ReadOrdersFromFile(file_orders))
   {
      Print("SyncOrders: Failed to read orders from file ", orders_file_name);
      return;
   }

   OrderData current_orders[];
   GetCurrentOrders(current_orders);

   if(verbose_logging || ArraySize(file_orders) > 0 || ArraySize(current_orders) > 0)
   {
      Print("SyncOrders: Starting order synchronization at ", TimeToString(TimeCurrent()));
      Print("SyncOrders: Read ", ArraySize(file_orders), " orders from file");
      Print("SyncOrders: Found ", ArraySize(current_orders), " current orders in terminal");
   }

   for(int i = 0; i < ArraySize(file_orders); i++)
   {
      bool found = false;
      for(int j = 0; j < ArraySize(current_orders); j++)
      {
         if(file_orders[i].symbol == current_orders[j].symbol &&
            file_orders[i].type == current_orders[j].type)
         {
            found = true;
            int digits = (int)SymbolInfoInteger(file_orders[i].symbol, SYMBOL_DIGITS);
            double file_price = NormalizeDouble(file_orders[i].price, digits);
            double current_price = NormalizeDouble(current_orders[j].price, digits);
            double file_sl = file_orders[i].stoploss == 0 ? 0 : NormalizeDouble(file_orders[i].stoploss, digits);
            double current_sl = current_orders[j].stoploss == 0 ? 0 : NormalizeDouble(current_orders[j].stoploss, digits);
            double file_tp = file_orders[i].takeprofit == 0 ? 0 : NormalizeDouble(file_orders[i].takeprofit, digits);
            double current_tp = current_orders[j].takeprofit == 0 ? 0 : NormalizeDouble(current_orders[j].takeprofit, digits);
            double file_volume = NormalizeDouble(file_orders[i].volume, 2);
            double current_volume = NormalizeDouble(current_orders[j].volume, 2);

            if(file_price != current_price || file_sl != current_sl || file_tp != current_tp)
            {
               Print("SyncOrders: Detected changes for order ticket ", current_orders[j].ticket,
                     ", symbol ", file_orders[i].symbol, ", type ", EnumToString(file_orders[i].type),
                     ", price: ", file_price, " vs ", current_price,
                     ", SL: ", file_sl, " vs ", current_sl,
                     ", TP: ", file_tp, " vs ", current_tp);
               ModifyOrder(current_orders[j].ticket, file_orders[i]);
            }
            else if(verbose_logging)
            {
               Print("SyncOrders: No changes for order ticket ", current_orders[j].ticket,
                     ", symbol ", file_orders[i].symbol, ", type ", EnumToString(file_orders[i].type));
            }
            break;
         }
      }
      if(!found)
      {
         Print("SyncOrders: Placing new order for symbol ", file_orders[i].symbol,
               ", type ", EnumToString(file_orders[i].type));
         PlaceOrder(file_orders[i]);
      }
   }

   for(int i = 0; i < ArraySize(current_orders); i++)
   {
      bool found = false;
      for(int j = 0; j < ArraySize(file_orders); j++)
      {
         if(current_orders[i].symbol == file_orders[j].symbol &&
            current_orders[i].type == file_orders[j].type)
         {
            found = true;
            break;
         }
      }
      if(!found)
      {
         Print("SyncOrders: Deleting order ticket ", current_orders[i].ticket,
               " for symbol ", current_orders[i].symbol, ", type ", EnumToString(current_orders[i].type));
         DeleteOrder(current_orders[i].ticket);
      }
   }

   if(verbose_logging || ArraySize(file_orders) > 0 || ArraySize(current_orders) > 0)
   {
      Print("SyncOrders: Order synchronization completed at ", TimeToString(TimeCurrent()));
   }
}

//+------------------------------------------------------------------+
//| Read orders from file                                            |
//+------------------------------------------------------------------+
bool ReadOrdersFromFile(OrderData &orders[])
{
   ArrayResize(orders, 0);
   int handle = FileOpen(orders_file_name, FILE_CSV | FILE_READ | FILE_COMMON);
   if(handle == INVALID_HANDLE)
   {
      Print("ReadOrdersFromFile: Failed to open file ", orders_file_name, ", error: ", GetLastError());
      return false;
   }

   while(!FileIsEnding(handle))
   {
      string line = FileReadString(handle);
      if(line == "") continue;

      string fields[];
      if(StringSplit(line, ';', fields) < 15) continue;

      long ticket = StringToInteger(fields[0]);
      string symbol = fields[1];
      string order_type_str = fields[2];
      double volume = StringToDouble(fields[3]);
      double price = StringToDouble(fields[4]);
      double stoploss = StringToDouble(fields[5]);
      double takeprofit = StringToDouble(fields[6]);
      long magic = StringToInteger(fields[14]);

      if(!IsSymbolFiltered(symbol) || !IsMagicFiltered(magic)) continue;

      ENUM_ORDER_TYPE type;
      if(order_type_str == "OP_BUYLIMIT") type = ORDER_TYPE_BUY_LIMIT;
      else if(order_type_str == "OP_BUYSTOP") type = ORDER_TYPE_BUY_STOP;
      else if(order_type_str == "OP_SELLLIMIT") type = ORDER_TYPE_SELL_LIMIT;
      else if(order_type_str == "OP_SELLSTOP") type = ORDER_TYPE_SELL_STOP;
      else continue;

      int new_size = ArraySize(orders) + 1;
      ArrayResize(orders, new_size);
      orders[new_size - 1].ticket = ticket;
      orders[new_size - 1].symbol = symbol;
      orders[new_size - 1].type = type;
      orders[new_size - 1].volume = volume;
      orders[new_size - 1].price = price;
      orders[new_size - 1].stoploss = stoploss;
      orders[new_size - 1].takeprofit = takeprofit;
      orders[new_size - 1].magic = magic;
      orders[new_size - 1].comment = fields[15];
   }

   FileClose(handle);
   if(verbose_logging || ArraySize(orders) > 0)
   {
      // Print("ReadOrdersFromFile: Successfully read ", ArraySize(orders), " orders from file ", orders_file_name);
   }
   return true;
}

//+------------------------------------------------------------------+
//| Read positions from file                                         |
//+------------------------------------------------------------------+
bool ReadPositionsFromFile(PositionData &positions[])
{
   ArrayResize(positions, 0);
   // Print("positions_file_name: ", positions_file_name); // Проверка имени файла
   if(!FileIsExist(positions_file_name, FILE_COMMON))
   {
      Print("File ", positions_file_name, " does not exist or is inaccessible in the common folder!");
      return false;
   }

   int handle = FileOpen(positions_file_name, FILE_CSV | FILE_READ | FILE_COMMON);
   if(handle == INVALID_HANDLE)
   {
      Print("ReadPositionsFromFile: Failed to open file ", positions_file_name, ", error: ", GetLastError());
      return false;
   }

   while(!FileIsEnding(handle))
   {
      string line = FileReadString(handle);
      if(line == "")
      {
         // Print("Empty line detected, skipping...");
         continue;
      }

      string fields[];
      int split_result = StringSplit(line, ';', fields);
      if(split_result < 15)
      {
         Print("Invalid line format (", split_result, " fields): ", line);
         continue;
      }

      long ticket = StringToInteger(fields[0]);
      string symbol = fields[1];
      int orientation = (int)StringToInteger(fields[2]);
      double volume = StringToDouble(fields[3]);
      double price = StringToDouble(fields[4]);
      double stoploss = StringToDouble(fields[5]);
      double takeprofit = StringToDouble(fields[6]);
      long magic = StringToInteger(fields[14]);
      datetime open_time = StringToTime(fields[11]);

      if(!IsSymbolFiltered(symbol) || !IsMagicFiltered(magic))
      {
         // Print("Filtered out: Symbol=", symbol, ", Magic=", magic);
         continue;
      }

      ENUM_POSITION_TYPE type = (orientation == 1) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;

      int new_size = ArraySize(positions) + 1;
      ArrayResize(positions, new_size);
      positions[new_size - 1].ticket = ticket;
      positions[new_size - 1].symbol = symbol;
      positions[new_size - 1].type = type;
      positions[new_size - 1].volume = volume;
      positions[new_size - 1].price = price;
      positions[new_size - 1].stoploss = stoploss;
      positions[new_size - 1].takeprofit = takeprofit;
      positions[new_size - 1].magic = magic;
      positions[new_size - 1].comment = fields[15];
      positions[new_size - 1].open_time = open_time;
   }

   FileClose(handle);
   if(verbose_logging || ArraySize(positions) > 0)
   {
      // Print("ReadPositionsFromFile: Successfully read ", ArraySize(positions), " positions from file ", positions_file_name);
   }
   return true;
}

//+------------------------------------------------------------------+
//| Get current orders with newMagicNumber                            |
//+------------------------------------------------------------------+
void GetCurrentOrders(OrderData &orders[])
{
   ArrayResize(orders, 0);
   for(int i = 0; i < OrdersTotal(); i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket))
      {
         if(OrderGetInteger(ORDER_MAGIC) == newMagicNumber)
         {
            int new_size = ArraySize(orders) + 1;
            ArrayResize(orders, new_size);
            orders[new_size - 1].ticket = ticket;
            orders[new_size - 1].symbol = OrderGetString(ORDER_SYMBOL);
            orders[new_size - 1].type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            orders[new_size - 1].volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
            orders[new_size - 1].price = OrderGetDouble(ORDER_PRICE_OPEN);
            orders[new_size - 1].stoploss = OrderGetDouble(ORDER_SL);
            orders[new_size - 1].takeprofit = OrderGetDouble(ORDER_TP);
            orders[new_size - 1].magic = OrderGetInteger(ORDER_MAGIC);
            orders[new_size - 1].comment = OrderGetString(ORDER_COMMENT);
         }
      }
   }
   if(verbose_logging || ArraySize(orders) > 0)
   {
      // Print("GetCurrentOrders: Retrieved ", ArraySize(orders), " orders with magic ", newMagicNumber);
   }
}

//+------------------------------------------------------------------+
//| Get current positions with newMagicNumber                         |
//+------------------------------------------------------------------+
void GetCurrentPositions(PositionData &positions[])
{
   ArrayResize(positions, 0);
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) == newMagicNumber)
         {
            int new_size = ArraySize(positions) + 1;
            ArrayResize(positions, new_size);
            positions[new_size - 1].ticket = ticket;
            positions[new_size - 1].symbol = PositionGetString(POSITION_SYMBOL);
            positions[new_size - 1].type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            positions[new_size - 1].volume = PositionGetDouble(POSITION_VOLUME);
            positions[new_size - 1].price = PositionGetDouble(POSITION_PRICE_OPEN);
            positions[new_size - 1].stoploss = PositionGetDouble(POSITION_SL);
            positions[new_size - 1].takeprofit = PositionGetDouble(POSITION_TP);
            positions[new_size - 1].magic = PositionGetInteger(POSITION_MAGIC);
            positions[new_size - 1].comment = PositionGetString(POSITION_COMMENT);
            positions[new_size - 1].open_time = (datetime)PositionGetInteger(POSITION_TIME);
         }
      }
   }
   if(verbose_logging || ArraySize(positions) > 0)
   {
      // Print("GetCurrentPositions: Retrieved ", ArraySize(positions), " positions with magic ", newMagicNumber);
   }
}

//+------------------------------------------------------------------+
//| Get filling mode for symbol                                      |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingMode(string symbol)
{
   uint filling = (uint)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
   if(filling & SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;
   if(filling & SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
   return ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//| Place a new pending order                                        |
//+------------------------------------------------------------------+
void PlaceOrder(const OrderData &order)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_PENDING;
   request.symbol = order.symbol;
   request.type = order.type;
   request.volume = CalcVolume(order.volume);
   request.price = order.price;
   request.sl = order.stoploss;
   request.tp = order.takeprofit;
   request.magic = newMagicNumber;
   request.comment = newComment;
   request.type_filling = GetFillingMode(order.symbol);

   if(!OrderSend(request, result))
   {
      Print("PlaceOrder: Failed to place order for ", order.symbol, ", type ", EnumToString(order.type),
            ", error: ", GetLastError());
   }
   else
   {
      Print("PlaceOrder: Order placed, ticket: ", result.order, ", symbol: ", order.symbol,
            ", type: ", EnumToString(order.type));
   }
}

//+------------------------------------------------------------------+
//| Modify an existing pending order                                 |
//+------------------------------------------------------------------+
void ModifyOrder(ulong ticket, const OrderData &order)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_MODIFY;
   request.order = ticket;
   request.symbol = order.symbol;
   request.volume = CalcVolume(order.volume);
   request.price = order.price;
   request.sl = order.stoploss;
   request.tp = order.takeprofit;
   request.type_filling = GetFillingMode(order.symbol);

   if(!OrderSend(request, result))
   {
      Print("ModifyOrder: Failed to modify order ", ticket, ", symbol ", order.symbol,
            ", error: ", GetLastError());
   }
   else
   {
      Print("ModifyOrder: Order modified, ticket: ", ticket, ", symbol: ", order.symbol);
   }
}

//+------------------------------------------------------------------+
//| Delete a pending order                                           |
//+------------------------------------------------------------------+
void DeleteOrder(ulong ticket)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_REMOVE;
   request.order = ticket;

   if(!OrderSend(request, result))
   {
      Print("DeleteOrder: Failed to delete order ", ticket, ", error: ", GetLastError());
   }
   else
   {
      Print("DeleteOrder: Order deleted, ticket: ", ticket);
   }
}

//+------------------------------------------------------------------+
//| Modify an existing position                                      |
//+------------------------------------------------------------------+
void ModifyPosition(ulong ticket, const PositionData &position)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol = position.symbol;
   request.sl = position.stoploss;
   request.tp = position.takeprofit;
   request.type_filling = GetFillingMode(position.symbol);

   if(!OrderSend(request, result))
   {
      Print("ModifyPosition: Failed to modify position ", ticket, ", symbol ", position.symbol,
            ", SL: ", position.stoploss, ", TP: ", position.takeprofit, ", error: ", GetLastError());
   }
   else
   {
      Print("ModifyPosition: Position modified, ticket: ", ticket, ", symbol: ", position.symbol,
            ", SL: ", position.stoploss, ", TP: ", position.takeprofit);
   }
}

//+------------------------------------------------------------------+
//| Close an existing position with retries                          |
//+------------------------------------------------------------------+
void ClosePosition(ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
   {
      Print("ClosePosition: Failed to select position ", ticket, " (may already be closed)");
      return;
   }

   string symbol = PositionGetString(POSITION_SYMBOL);
   double volume = PositionGetDouble(POSITION_VOLUME);
   ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   int retries = 5;
   int delay_sec = 1;

   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = symbol;
   request.volume = volume;
   request.type = (pos_type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price = SymbolInfoDouble(symbol, (request.type == ORDER_TYPE_BUY) ? SYMBOL_ASK : SYMBOL_BID);
   request.type_filling = GetFillingMode(symbol);

   for(int attempt = 1; attempt <= retries; attempt++)
   {
      if(OrderSend(request, result))
      {
         Print("ClosePosition: Position closed successfully, ticket: ", ticket, ", symbol: ", symbol, " on attempt ", attempt);
         return;
      }
      else
      {
         int err = GetLastError();
         Print("ClosePosition: Failed to close position ", ticket, ", symbol ", symbol,
               ", error: ", err, " on attempt ", attempt);
         if(err != 4756 || attempt == retries)
         {
            return;
         }
         Sleep(delay_sec * 1000);
      }
   }
   Print("ClosePosition: Max retries reached for position ", ticket, ", symbol ", symbol);
}

//+------------------------------------------------------------------+
//| Calculate volume based on copyType                               |
//+------------------------------------------------------------------+
double CalcVolume(double source_volume)
{
   double vol = 0;

   switch(copyType)
   {
      case FixedLotSize:
         vol = fixVolume;
         break;
      case Proportional:
         vol = proportional * source_volume;
         if(vol < 0.01) vol = 0.01;
         break;
   }

   double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   vol = NormalizeDouble(vol / lot_step, 0) * lot_step;

   double min_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   if(vol < min_lot) vol = min_lot;
   if(vol > max_lot) vol = max_lot;

   return vol;
}

//+------------------------------------------------------------------+
//| Check if symbol is filtered                                      |
//+------------------------------------------------------------------+
bool IsSymbolFiltered(string symbol)
{
   if(filterSymbol == "" || StringCompare(filterSymbol, "All", false) == 0)
      return true;

   string symbols[];
   StringSplit(filterSymbol, ';', symbols);
   for(int i = 0; i < ArraySize(symbols); i++)
   {
      if(StringCompare(symbol, symbols[i], false) == 0)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if magic number is filtered                                |
//+------------------------------------------------------------------+
bool IsMagicFiltered(long magic)
{
   if(filterMagic == "" || StringCompare(filterMagic, "All", false) == 0)
      return true;

   string magics[];
   StringSplit(filterMagic, ';', magics);
   for(int i = 0; i < ArraySize(magics); i++)
   {
      if(StringToInteger(magics[i]) == magic)
         return true;
   }
   return false;
}