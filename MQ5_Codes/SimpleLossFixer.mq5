//+--------------------------------------------------------------------+
//|                                                 SimpleLossFixer.mq5|
//|                                  Version 1.6                       |
//|                                                                    |
//|        Simple Expert Advisor for monitoring drawdown by Magic      |
//|        Number. Uses enum for mode selection: All (with optional    |
//|        exclusions) or Selected (comma-separated list). Calculates  |
//|        TOTAL P&L for each Magic's positions separately. Closes     |
//|        positions when total P&L <= -StopValue for that Magic (if   |
//|        not in monitoring-only mode). Displays table on chart.      |
//|        Logs actions.                                               |
//|                                                                    |
//|        Inputs:                                                     |
//|        - Mode: All or Selected                                     |
//|        - MagicNumbersList: For Selected mode (comma-separated)     |
//|        - ExcludeMagicNumbersList: For All mode (comma-separated)   |
//|        - StopValue: Critical drawdown limit in account currency    |
//|        - MonitoringOnly: Display only (no closing)                 |
//+--------------------------------------------------------------------+

#property strict
#property version     "1.6"

#include <Trade\Trade.mqh>

// Enum for monitoring mode
enum MonitoringMode
{
    MODE_ALL,       // All Magics (with optional exclusions)
    MODE_SELECTED   // Selected Magics (comma-separated list)
};

// Enum for monitoring-only flag
enum MonitoringOnlyFlag
{
    CLOSE_POSITIONS,  // Close positions if limit exceeded
    DISPLAY_ONLY      // Only display info, no closing
};

// Input parameters
input MonitoringMode Mode = MODE_SELECTED;                            // Monitoring Mode: All or Selected
input string MagicNumbersList = "12345";                              // For Selected: Comma-separated Magic Numbers (e.g., "12345,67890")
input string ExcludeMagicNumbersList = "";                            // For All: Comma-separated exclusions (e.g., "99999,00000")
input double StopValue = 550.0;                                       // Critical drawdown limit (negative P&L threshold)
input MonitoringOnlyFlag MonitoringOnly = CLOSE_POSITIONS;            // Monitoring Only: Display info without closing

// Global variables
CTrade trade;
int magics[];      // Array of specific Magic Numbers (for Selected mode)
int excludes[];    // Array of excluded Magic Numbers (for All mode)
bool isAllMode = false;  // Flag for All mode
bool onlyMonitor = false;  // Flag for display-only mode
string TableIndent = "          ";  // Indent for table (adjustable spaces for margin from edge)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    onlyMonitor = (MonitoringOnly == DISPLAY_ONLY);
    
    if(Mode == MODE_ALL)
    {
        isAllMode = true;
        
        // Parse exclusions if provided
        if(ExcludeMagicNumbersList != "")
        {
            string tempEx[];
            int numEx = StringSplit(ExcludeMagicNumbersList, ',', tempEx);
            ArrayResize(excludes, numEx);
            for(int i = 0; i < numEx; i++)
            {
                string trimmedEx = tempEx[i];
                StringTrimLeft(trimmedEx);
                StringTrimRight(trimmedEx);
                excludes[i] = (int)StringToInteger(trimmedEx);
                if(excludes[i] > 0)
                {
                    Print("Excluding Magic Number: ", excludes[i]);
                }
                else
                {
                    Print("Warning: Invalid exclude Magic Number at index ", i, ": ", tempEx[i]);
                }
            }
        }
        
        Print("SimpleLossFixer initialized in ALL mode (with ", ArraySize(excludes), " exclusions). Monitoring unique Magic Numbers in open positions. StopValue: ", StopValue, ". Only Monitor: ", onlyMonitor);
    }
    else  // MODE_SELECTED
    {
        // Parse the Magic Numbers list
        string temp[];
        int numMagics = StringSplit(MagicNumbersList, ',', temp);
        if(numMagics <= 0)
        {
            Print("Error: Invalid MagicNumbersList in Selected mode. No Magic Numbers parsed.");
            return(INIT_FAILED);
        }
        
        ArrayResize(magics, numMagics);
        for(int i = 0; i < numMagics; i++)
        {
            string trimmed = temp[i];
            StringTrimLeft(trimmed);
            StringTrimRight(trimmed);
            magics[i] = (int)StringToInteger(trimmed);
            if(magics[i] <= 0)
            {
                Print("Warning: Invalid Magic Number at index ", i, ": ", temp[i]);
            }
            else
            {
                Print("Monitoring Magic Number: ", magics[i]);
            }
        }
        
        Print("SimpleLossFixer initialized in SELECTED mode. Monitoring ", numMagics, " specific Magic Number(s). StopValue: ", StopValue, ". Only Monitor: ", onlyMonitor);
    }
    
    trade.SetExpertMagicNumber(0);  // No specific magic for this EA's trades
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Comment("");  // Clear comment on deinit
    
    // Clear all dynamic arrays to prevent buffer overflows on multiple runs
    ArrayFree(magics);
    ArrayFree(excludes);
    
    Print("SimpleLossFixer deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Function to display monitoring table on chart                    |
//+------------------------------------------------------------------+
void DisplayTable()
{
    // Collect unique Magic Numbers from open positions
    int uniqueMagics[];
    int uniqueCount = 0;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) != "")
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            if(magic > 0)  // Ignore 0 (system positions)
            {
                // Check if already in unique list
                bool exists = false;
                for(int u = 0; u < uniqueCount; u++)
                {
                    if(uniqueMagics[u] == (int)magic)
                    {
                        exists = true;
                        break;
                    }
                }
                if(!exists)
                {
                    ArrayResize(uniqueMagics, uniqueCount + 1);
                    uniqueMagics[uniqueCount] = (int)magic;
                    uniqueCount++;
                }
            }
        }
    }
    
    // Determine which Magics to monitor (same logic as OnTick)
    int monitorMagics[];
    int monitorCount = 0;
    if(isAllMode)
    {
        for(int u = 0; u < uniqueCount; u++)
        {
            int umagic = uniqueMagics[u];
            bool isExcluded = false;
            for(int e = 0; e < ArraySize(excludes); e++)
            {
                if(umagic == excludes[e])
                {
                    isExcluded = true;
                    break;
                }
            }
            if(!isExcluded)
            {
                ArrayResize(monitorMagics, monitorCount + 1);
                monitorMagics[monitorCount] = umagic;
                monitorCount++;
            }
        }
    }
    else
    {
        for(int m = 0; m < ArraySize(magics); m++)
        {
            bool hasPositions = false;
            for(int u = 0; u < uniqueCount; u++)
            {
                if(magics[m] == uniqueMagics[u])
                {
                    hasPositions = true;
                    break;
                }
            }
            if(hasPositions)
            {
                ArrayResize(monitorMagics, monitorCount + 1);
                monitorMagics[monitorCount] = magics[m];
                monitorCount++;
            }
        }
    }
    
    // Build table string with indent
    string table = "\n";
    table += TableIndent + "=== SimpleLossFixer Monitoring Table ===\n\n";
    table += TableIndent + "MagicMode: " + EnumToString(Mode) + "\n";
    table += TableIndent + "MonitorMode: " + EnumToString(MonitoringOnly) + "\n";
    table += TableIndent + "StopValue: " + DoubleToString(StopValue, 2) + "\n";
    table += TableIndent + "\n";  // Empty line before header
    table += TableIndent + StringFormat("%8s | %-9s | %-15s | %-10s | %-20s\n", "Magic ID", "Positions", "P&L (Currency)", "Drawdown %", "Status");
    table += TableIndent + "---------------------------------------------------------------------------------------\n";  // Adjusted separator length (11+1+11+1+20+1+8+1+20=74 chars)
    
    for(int mk = 0; mk < monitorCount; mk++)
    {
        int currentMagic = monitorMagics[mk];
        double totalPnL = 0.0;
        int count = 0;
        
        // Calculate P&L and count for this Magic
        for(int i = 0; i < PositionsTotal(); i++)
        {
            if(PositionGetSymbol(i) != "")
            {
                long magic = PositionGetInteger(POSITION_MAGIC);
                double profit = PositionGetDouble(POSITION_PROFIT);
                
                if(magic == currentMagic)
                {
                    totalPnL += profit;
                    count++;
                }
            }
        }
        
        // Drawdown %: Only if totalPnL < 0, else empty
        string drawdownPct = "0.0%";
        if(totalPnL < 0)
        {
            double pct = MathAbs(totalPnL) / StopValue * 100.0;
            drawdownPct = StringFormat("%.1f%%", pct);
        }
        
        // Status: Exceeded if totalPnL <= -StopValue
        string status = (totalPnL <= -StopValue) ? "EXCEEDED!" : "OK";
        if(onlyMonitor) status += " (Monitor Only)";
        
        table += TableIndent + StringFormat("%-11d | %-11d | %-20s | %-16s | %-20s\n", 
                                            currentMagic, count, DoubleToString(totalPnL, 2), drawdownPct, status);
    }
    
    if(monitorCount == 0)
    {
        table += TableIndent + "No monitored positions found.\n";
    }
    
    table += TableIndent + "=====================================\n";
    
    // Display on chart
    Comment(table);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Collect unique Magic Numbers from open positions (only if positions exist)
    int uniqueMagics[];
    int uniqueCount = 0;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) != "")
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            if(magic > 0)  // Ignore 0 (system positions)
            {
                // Check if already in unique list
                bool exists = false;
                for(int u = 0; u < uniqueCount; u++)
                {
                    if(uniqueMagics[u] == (int)magic)
                    {
                        exists = true;
                        break;
                    }
                }
                if(!exists)
                {
                    ArrayResize(uniqueMagics, uniqueCount + 1);
                    uniqueMagics[uniqueCount] = (int)magic;
                    uniqueCount++;
                }
            }
        }
    }
    
    // Determine which Magics to monitor
    int monitorMagics[];
    int monitorCount = 0;
    if(isAllMode)  // MODE_ALL
    {
        // Monitor all unique Magics, excluding specified ones
        for(int u = 0; u < uniqueCount; u++)
        {
            int umagic = uniqueMagics[u];
            bool isExcluded = false;
            
            // Check against exclusions
            for(int e = 0; e < ArraySize(excludes); e++)
            {
                if(umagic == excludes[e])
                {
                    isExcluded = true;
                    break;
                }
            }
            
            if(!isExcluded)
            {
                ArrayResize(monitorMagics, monitorCount + 1);
                monitorMagics[monitorCount] = umagic;
                monitorCount++;
            }
        }
    }
    else  // MODE_SELECTED
    {
        // Monitor only specified Magics that have positions
        for(int m = 0; m < ArraySize(magics); m++)
        {
            bool hasPositions = false;
            for(int u = 0; u < uniqueCount; u++)
            {
                if(magics[m] == uniqueMagics[u])
                {
                    hasPositions = true;
                    break;
                }
            }
            if(hasPositions)
            {
                ArrayResize(monitorMagics, monitorCount + 1);
                monitorMagics[monitorCount] = magics[m];
                monitorCount++;
            }
        }
    }
    
    // For each monitored Magic Number, calculate total P&L and check limit
    for(int mk = 0; mk < monitorCount; mk++)
    {
        int currentMagic = monitorMagics[mk];
        double totalPnL = 0.0;  // Total Profit/Loss: sum of all profits (positive and negative)
        string symbolsToClose[];
        int count = 0;
        
        // Iterate through all positions to calculate total P&L for this Magic
        for(int i = 0; i < PositionsTotal(); i++)
        {
            if(PositionGetSymbol(i) != "")
            {
                long magic = PositionGetInteger(POSITION_MAGIC);
                string posSymbol = PositionGetString(POSITION_SYMBOL);
                double profit = PositionGetDouble(POSITION_PROFIT);
                
                if(magic == currentMagic)
                {
                    totalPnL += profit;  // Sum ALL profits/losses
                    ArrayResize(symbolsToClose, count + 1);
                    symbolsToClose[count] = posSymbol;
                    count++;
                }
            }
        }
        
        // If total P&L is at or below the negative threshold, close all positions for this Magic (unless only monitor)
        if(!onlyMonitor && totalPnL <= -StopValue && count > 0)
        {
            // Close positions
            for(int j = 0; j < count; j++)
            {
                if(trade.PositionClose(symbolsToClose[j]))
                {
                    Print("Position closed: ", symbolsToClose[j], " (Magic: ", currentMagic, ")");
                }
                else
                {
                    Print("Error closing position ", symbolsToClose[j], ": ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
                }
            }
            
            // Log the event
            string message = StringFormat("Drawdown limit exceeded for Magic %d: Total P&L %.2f <= -%.2f. All %d positions closed.", 
                                          currentMagic, totalPnL, StopValue, count);
            Print(message);
            Alert(message);  // Optional alert for immediate notification
        }
    }
    
    // Update display table
    DisplayTable();
}