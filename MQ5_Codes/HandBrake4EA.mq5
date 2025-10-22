//+---------------------------------------------------------------------+
//|                                                    HandBrake4EA.mq5 |
//|                         Version 1.0                                 |
//|                                                                     |
//|        Advisor for monitoring and controlling trading activity      |
//|        of another Expert Advisor (EA) based on drawdown levels.     |
//|        Monitors positions with a specified MagicNumber, closes      |
//|        them when a critical drawdown is reached, and optionally     |
//|        blocks new trades by closing any newly opened positions.     |
//|        When enabled, draws a stop line on the chart to visualize    |
//|        the price level where the critical drawdown would occur.     |
//|                                                                     |
//|        Features:                                                    |
//|        - Monitors drawdown for positions with a given MagicNumber   |
//|        - Closes positions when drawdown exceeds StopValue           |
//|        - Blocks new positions after critical drawdown (optional)    |
//|        - Draws a stop line for a specific symbol (optional)         |
//|        - Removes stop line when no positions exist or after close   |
//|                                                                     |
//|        Input Parameters:                                            |
//|        - MagicNumber: Magic number of the target EA's positions     |
//|        - SymbolFilter: Symbol to monitor ("" for all symbols)       |
//|        - StopValue: Critical drawdown level in account currency     |
//|        - isDelete: Enable blocking of new positions after close     |
//|        - ShowLines: Show stop line for the specified symbol         |
//|                                                                     |
//+---------------------------------------------------------------------+

#property strict
#property version     "1.0"

#include <Trade\Trade.mqh>

// Input parameters
input int MagicNumber = 12345;         // Magic number of the target EA
input string SymbolFilter = "";        // Symbol filter ("" - all symbols)
input double StopValue = 550;          // Critical drawdown in account currency
input bool isDelete = true;            // Block trading after closing positions
input bool ShowLines = true;           // Show stop line (If symbol is selected)

// Trading object
CTrade trade;

// Flag for blocking mode
bool blockTrading = false;

// Name of the stop line
const string StopLineName = "CriticalStopLine";

// Initialization
int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    return(INIT_SUCCEEDED);
}

// Deinitialization (remove line when EA stops)
void OnDeinit(const int reason)
{
    ObjectDelete(0, StopLineName);
}

// Main logic on each tick
void OnTick()
{
    // If blocking mode is active, close all new positions
    if(blockTrading)
    {
        for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            if(symbol != "")
            {
                long magic = PositionGetInteger(POSITION_MAGIC);
                string posSymbol = PositionGetString(POSITION_SYMBOL);
                
                if(magic == MagicNumber && (SymbolFilter == "" || posSymbol == SymbolFilter))
                {
                    if(trade.PositionClose(posSymbol))
                    {
                        Print("New position with MagicNumber ", MagicNumber, " closed to stop trading.");
                    }
                    else
                    {
                        Print("Error closing position: ", GetLastError());
                    }
                }
            }
        }
        ObjectDelete(0, StopLineName); // Remove line in blocking mode
        return;
    }
    
    // Check drawdown and draw stop line if ShowLines is enabled
    double totalLoss = 0.0;              // Total drawdown
    string symbolsToClose[];             // Array of symbols to close
    int count = 0;
    double totalVolume = 0.0;            // Total volume of positions
    double weightedOpenPrice = 0.0;      // Weighted average open price
    bool hasPositions = false;           // Flag for existing positions
    
    // Iterate through all open positions
    for(int i = 0; i < PositionsTotal(); i++)
    {
        string symbol = PositionGetSymbol(i);
        if(symbol != "")
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            string posSymbol = PositionGetString(POSITION_SYMBOL);
            double profit = PositionGetDouble(POSITION_PROFIT);
            
            if(magic == MagicNumber && (SymbolFilter == "" || posSymbol == SymbolFilter))
            {
                hasPositions = true;
                if(profit < 0)
                {
                    totalLoss -= profit; // Accumulate loss (profit is negative)
                }
                ArrayResize(symbolsToClose, count + 1);
                symbolsToClose[count] = posSymbol;
                count++;
                
                // Calculate data for stop line (only if SymbolFilter is set)
                if(ShowLines && SymbolFilter != "" && posSymbol == SymbolFilter)
                {
                    double volume = PositionGetDouble(POSITION_VOLUME);
                    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                    
                    // Account for position direction
                    if(posType == POSITION_TYPE_BUY)
                    {
                        totalVolume += volume;
                    }
                    else if(posType == POSITION_TYPE_SELL)
                    {
                        totalVolume -= volume;
                    }
                    weightedOpenPrice += openPrice * volume;
                }
            }
        }
    }
    
    // Draw stop line
    if(ShowLines && SymbolFilter != "" && hasPositions)
    {
        double pointValue = SymbolInfoDouble(SymbolFilter, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(SymbolFilter, SYMBOL_TRADE_TICK_SIZE);
        
        if(totalVolume != 0) // Avoid division by zero
        {
            weightedOpenPrice /= MathAbs(totalVolume); // Average open price
            double stopPrice;
            
            if(totalVolume > 0) // Net Buy
            {
                stopPrice = weightedOpenPrice - (StopValue / (totalVolume * pointValue)) * tickSize;
            }
            else // Net Sell
            {
                stopPrice = weightedOpenPrice + (StopValue / (MathAbs(totalVolume) * pointValue)) * tickSize;
            }
            
            // Create or update the line
            if(ObjectFind(0, StopLineName) < 0)
            {
                ObjectCreate(0, StopLineName, OBJ_HLINE, 0, 0, stopPrice);
                ObjectSetInteger(0, StopLineName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, StopLineName, OBJPROP_STYLE, STYLE_DASH);
                ObjectSetString(0, StopLineName, OBJPROP_TEXT, "Critical Stop: " + DoubleToString(StopValue, 2));
            }
            else
            {
                ObjectSetDouble(0, StopLineName, OBJPROP_PRICE, stopPrice);
            }
        }
    }
    else
    {
        ObjectDelete(0, StopLineName); // Remove line if no positions exist
    }
    
    // If drawdown reaches critical level
    if(totalLoss >= StopValue)
    {
        // Close all positions
        for(int i = 0; i < count; i++)
        {
            trade.PositionClose(symbolsToClose[i]);
        }
        
        // Notify user
        string message = StringFormat("Critical drawdown (%.2f) reached! Positions with MagicNumber %d closed.", totalLoss, MagicNumber);
        Alert(message);
        Print(message);
        
        // Activate blocking mode if isDelete is true
        if(isDelete)
        {
            blockTrading = true;
            Print("Blocking mode activated. All new positions with MagicNumber ", MagicNumber, " will be closed.");
        }
        
        ObjectDelete(0, StopLineName); // Remove line after closing
    }
}