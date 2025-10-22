//+-------------------------------------------------------------------+
//|                                           Adjuster_for_SL_and_TP  |
//|                         Version 1.00                              |
//|                                                                   |
//|        Advisor for updating StopLoss and TakeProfit               |
//|                                                                   |
//+-------------------------------------------------------------------+

#property strict
#property version     "1.00"

#include <Trade/Trade.mqh>
CTrade Trade;  // Create trade object

// Input parameters
input double StopLossDistance = 2500;   // Distance to StopLoss in points
input double TakeProfitDistance = 0;   // Distance to TakeProfit in points
input int MagicNumber = 12345;         // Order Magic number
input string SymbolFilter = "";        // Symbol filter ("" - all symbols)
input int TimerInterval = 300;         // Timer interval in seconds

//+------------------------------------------------------------------+
//| Function to update SL and TP                                     |
//+------------------------------------------------------------------+
void UpdateSLTP()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (!PositionSelectByTicket(ticket)) continue;

        // Check Magic number and Symbol
        if (PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
        string symbol = PositionGetString(POSITION_SYMBOL);
        if (SymbolFilter != "" && symbol != SymbolFilter) continue;

        // Get position parameters
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);

        // Determine point size based on the symbol
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

        // Calculate new SL and TP
        double newSL = (isBuy ? openPrice - StopLossDistance * point : openPrice + StopLossDistance * point);
        double newTP = (isBuy ? openPrice + TakeProfitDistance * point : openPrice - TakeProfitDistance * point);

        // Check if update is needed
        bool needUpdate = false;
        if (StopLossDistance > 0 && (sl == 0 || sl != newSL)) needUpdate = true;
        if (TakeProfitDistance > 0 && (tp == 0 || tp != newTP)) needUpdate = true;

        if (needUpdate)
        {
            if (!Trade.PositionModify(ticket, StopLossDistance > 0 ? newSL : sl, TakeProfitDistance > 0 ? newTP : tp))
            {
                PrintFormat("Error modifying SL/TP for position %d: %d", ticket, GetLastError());
            }
            else
            {
                PrintFormat("Updated SL/TP for position %d", ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Advisor initialization                                          |
//+------------------------------------------------------------------+
int OnInit()
{
    EventSetTimer(TimerInterval); // Set timer in seconds
    UpdateSLTP();
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Advisor deinitialization                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer(); // Remove timer
}

//+------------------------------------------------------------------+
//| Timer handler                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    UpdateSLTP();
}
