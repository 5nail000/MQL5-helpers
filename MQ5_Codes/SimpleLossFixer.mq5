//+--------------------------------------------------------------------+
//|                                                 SimpleLossFixer.mq5|
//|                                  Version 1.7                       |
//|                                                                    |
//|        Simple Expert Advisor for monitoring drawdown by Magic      |
//|        Number. Uses enum for mode selection: All (with optional    |
//|        exclusions) or Selected (comma-separated list). Calculates  |
//|        TOTAL P&L for each Magic's positions separately. Closes     |
//|        positions when total P&L <= -StopValue for that Magic (if   |
//|        not in display-only mode). Displays table on chart.         |
//|        Logs actions. Checks trading permissions and forces         |
//|        display-only if permissions are missing.                    |
//|                                                                    |
//|        New in 1.7: Added LOCK mode to ActionProcess. When          |
//|        triggered, opens opposite positions to hedge (lock) the     |
//|        net exposure per symbol for the magic, using a unique       |
//|        lock magic (1064 * 100000 + original_magic). Maintains      |
//|        the lock by adjusting for any new positions opened by the   |
//|        original advisor.                                           |
//|                                                                    |
//|        Inputs:                                                     |
//|        - Mode: All or Selected                                     |
//|        - MagicNumbersList: For Selected mode (comma-separated)     |
//|        - ExcludeMagicNumbersList: For All mode (comma-separated)   |
//|        - StopValue: Critical drawdown limit in account currency    |
//|        - ActionProcess: Close positions, Display only, or Lock     |
//+--------------------------------------------------------------------+

#property strict
#property version     "1.7"

#include <Trade\Trade.mqh>

// Enum for monitoring mode
enum MonitoringMode
{
    MODE_ALL,       // All Magics (with optional exclusions)
    MODE_SELECTED   // Selected Magics (comma-separated list)
};

// Enum for action process flag
enum ActionProcessFlag
{
    CLOSE_POSITIONS,  // Close positions if limit exceeded
    DISPLAY_ONLY,     // Only display info, no closing
    LOCK              // Lock (hedge) positions and maintain
};

// Input parameters
input MonitoringMode Mode = MODE_SELECTED;                            // Monitoring Mode: All or Selected
input string MagicNumbersList = "12345";                              // For Selected: Comma-separated Magic Numbers (e.g., "12345,67890")
input string ExcludeMagicNumbersList = "";                            // For All: Comma-separated exclusions (e.g., "99999,00000")
input double StopValue = 550.0;                                       // Critical drawdown limit (negative P&L threshold)
input ActionProcessFlag ActionProcess = CLOSE_POSITIONS;              // Action Process: Close positions, Display only, or Lock

// Global variables
CTrade trade;
int magics[];      // Array of specific Magic Numbers (for Selected mode)
int excludes[];    // Array of excluded Magic Numbers (for All mode)
bool isAllMode = false;  // Flag for All mode
bool onlyDisplay = false;  // Flag for display-only mode (considering permissions)
bool isLockMode = false;   // Flag for Lock mode
long lockBase = 1064;      // Base for lock magic numbers
string TableIndent = "          ";  // Indent for table (adjustable spaces for margin from edge)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    onlyDisplay = (ActionProcess == DISPLAY_ONLY);
    isLockMode = (ActionProcess == LOCK);
    
    // Check trading permissions and force display-only if any is missing
    bool terminalTradeAllowed = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
    bool eaTradeAllowed = MQLInfoInteger(MQL_TRADE_ALLOWED);
    bool accountTradeAllowed = AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
    
    if(!terminalTradeAllowed || !eaTradeAllowed || !accountTradeAllowed)
    {
        onlyDisplay = true;
        string permIssue = "";
        if(!terminalTradeAllowed) permIssue += "Terminal trade not allowed; ";
        if(!eaTradeAllowed) permIssue += "EA trade not allowed; ";
        if(!accountTradeAllowed) permIssue += "Account trade not allowed; ";
        Print("Trading permissions missing (", permIssue, "). Forcing DISPLAY_ONLY mode.");
    }
    
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
        
        Print("SimpleLossFixer initialized in ALL mode (with ", ArraySize(excludes), " exclusions). Monitoring unique Magic Numbers in open positions. StopValue: ", StopValue, ". Action: ", EnumToString(ActionProcess), " (Effective: ", (onlyDisplay ? "Display Only" : "Active"), ")");
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
        
        Print("SimpleLossFixer initialized in SELECTED mode. Monitoring ", numMagics, " specific Magic Number(s). StopValue: ", StopValue, ". Action: ", EnumToString(ActionProcess), " (Effective: ", (onlyDisplay ? "Display Only" : "Active"), ")");
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
//| Get lock magic for a given original magic                        |
//+------------------------------------------------------------------+
long GetLockMagic(int originalMagic)
{
    return lockBase * 100000 + originalMagic;  // Assuming originalMagic < 100000; adjust multiplier if needed
}

//+------------------------------------------------------------------+
//| Check if lock exists for a magic (any position with lock magic)  |
//+------------------------------------------------------------------+
bool LockExists(int originalMagic)
{
    long lockMagic = GetLockMagic(originalMagic);
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) != "")
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            if(magic == lockMagic)
            {
                return true;
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Collect unique symbols for a given magic                         |
//+------------------------------------------------------------------+
void GetSymbolsForMagic(long targetMagic, string &symbols[], int &count)
{
    count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) != "")
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            if(magic == targetMagic)
            {
                string sym = PositionGetString(POSITION_SYMBOL);
                bool exists = false;
                for(int s = 0; s < count; s++)
                {
                    if(symbols[s] == sym)
                    {
                        exists = true;
                        break;
                    }
                }
                if(!exists)
                {
                    ArrayResize(symbols, count + 1);
                    symbols[count] = sym;
                    count++;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate net lots for a magic on a specific symbol              |
//+------------------------------------------------------------------+
double GetNetLots(long targetMagic, string symbol)
{
    double buyLots = 0.0;
    double sellLots = 0.0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            if(magic == targetMagic)
            {
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double volume = PositionGetDouble(POSITION_VOLUME);
                if(posType == POSITION_TYPE_BUY)
                {
                    buyLots += volume;
                }
                else if(posType == POSITION_TYPE_SELL)
                {
                    sellLots += volume;
                }
            }
        }
    }
    return buyLots - sellLots;
}

//+------------------------------------------------------------------+
//| Lock positions for a magic (open initial hedges)                 |
//+------------------------------------------------------------------+
void LockPositions(int originalMagic)
{
    long lockMagic = GetLockMagic(originalMagic);
    string symbols[];
    int symCount;
    GetSymbolsForMagic(originalMagic, symbols, symCount);
    
    for(int s = 0; s < symCount; s++)
    {
        string sym = symbols[s];
        double netOriginal = GetNetLots(originalMagic, sym);
        if(MathAbs(netOriginal) > 0.0)
        {
            ENUM_ORDER_TYPE orderType = (netOriginal > 0.0) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            double volume = MathAbs(netOriginal);
            trade.SetExpertMagicNumber(lockMagic);  // Set the magic number for the trade
            if(trade.PositionOpen(sym, orderType, volume, 0, 0, 0, "Lock for " + IntegerToString(originalMagic)))
            {
                Print("Lock position opened: ", sym, " ", EnumToString(orderType), " ", DoubleToString(volume, 2), " (Magic: ", lockMagic, ")");
            }
            else
            {
                Print("Error opening lock position on ", sym, ": ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check and adjust lock for a magic (maintain hedge)               |
//+------------------------------------------------------------------+
void CheckAndAdjustLock(int originalMagic)
{
    long lockMagic = GetLockMagic(originalMagic);
    
    // Collect all unique symbols involved (original or lock)
    string symbols[];
    int symCount = 0;
    
    // From original
    string origSymbols[];
    int origCount;
    GetSymbolsForMagic(originalMagic, origSymbols, origCount);
    for(int o = 0; o < origCount; o++)
    {
        bool exists = false;
        for(int s = 0; s < symCount; s++)
        {
            if(symbols[s] == origSymbols[o])
            {
                exists = true;
                break;
            }
        }
        if(!exists)
        {
            ArrayResize(symbols, symCount + 1);
            symbols[symCount] = origSymbols[o];
            symCount++;
        }
    }
    
    // From lock
    string lockSymbols[];
    int lockCount;
    GetSymbolsForMagic(lockMagic, lockSymbols, lockCount);
    for(int l = 0; l < lockCount; l++)
    {
        bool exists = false;
        for(int s = 0; s < symCount; s++)
        {
            if(symbols[s] == lockSymbols[l])
            {
                exists = true;
                break;
            }
        }
        if(!exists)
        {
            ArrayResize(symbols, symCount + 1);
            symbols[symCount] = lockSymbols[l];
            symCount++;
        }
    }
    
    // For each symbol, check and adjust
    for(int s = 0; s < symCount; s++)
    {
        string sym = symbols[s];
        double netOriginal = GetNetLots(originalMagic, sym);
        double netLock = GetNetLots(lockMagic, sym);
        double desiredNetLock = -netOriginal;
        double delta = desiredNetLock - netLock;
        
        if(MathAbs(delta) > 0.0)
        {
            ENUM_ORDER_TYPE orderType = (delta > 0.0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
            double volume = MathAbs(delta);
            trade.SetExpertMagicNumber(lockMagic);  // Set the magic number for the trade
            if(trade.PositionOpen(sym, orderType, volume, 0, 0, 0, "Adjust Lock for " + IntegerToString(originalMagic)))
            {
                Print("Lock adjusted: ", sym, " ", EnumToString(orderType), " ", DoubleToString(volume, 2), " (Magic: ", lockMagic, ")");
            }
            else
            {
                Print("Error adjusting lock on ", sym, ": ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
            }
        }
    }
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
    table += TableIndent + "Action: " + EnumToString(ActionProcess) + "\n";
    table += TableIndent + "StopValue: " + DoubleToString(StopValue, 2) + "\n";
    table += TableIndent + "\n";  // Empty line before header
    
    // Header with aligned widths
    table += TableIndent + StringFormat("%-11s | %-11s | %-20s | %-16s | %-25s\n", "Magic ID", "Positions", "P&L (Currency)", "Drawdown %", "Status");
    
    // Separator line matching total width (11+3+11+3+20+3+16+3+25 = 92 chars)
    string separator;
    StringInit(separator, 120, '-');
    table += TableIndent + separator + "\n";
    
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
        
        // Prepare strings and truncate if necessary to prevent overflow
        string pnlStr = DoubleToString(totalPnL, 2);
        if(StringLen(pnlStr) > 20) pnlStr = StringSubstr(pnlStr, 0, 20);
        
        // Drawdown %: Only if totalPnL < 0, else empty
        string drawdownPct = "0.0%";
        if(totalPnL < 0)
        {
            double pct = MathAbs(totalPnL) / StopValue * 100.0;
            drawdownPct = StringFormat("%.1f%%", pct);
        }
        if(StringLen(drawdownPct) > 16) drawdownPct = StringSubstr(drawdownPct, 0, 16);
        
        // Status: Exceeded if totalPnL <= -StopValue
        string status = (totalPnL <= -StopValue) ? "EXCEEDED!" : "OK";
        if(isLockMode && LockExists(currentMagic)) status += " - LOCKED";
        if(onlyDisplay) status += " (Display Only)";
        if(StringLen(status) > 25) status = StringSubstr(status, 0, 25);
        
        table += TableIndent + StringFormat("%-11d | %-14d | %-24s | %-22s | %-25s\n", 
                                            currentMagic, count, pnlStr, drawdownPct, status);
    }
    
    if(monitorCount == 0)
    {
        table += TableIndent + "No monitored positions found.\n";
    }
    
    table += TableIndent + "====================================================\n";
    
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
        
        // Handle based on mode
        if(totalPnL <= -StopValue && count > 0)
        {
            if(!onlyDisplay)
            {
                if(ActionProcess == CLOSE_POSITIONS)
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
                else if(isLockMode)
                {
                    // Lock mode: If not already locked, initiate lock
                    if(!LockExists(currentMagic))
                    {
                        LockPositions(currentMagic);
                        
                        // Log the event
                        string message = StringFormat("Drawdown limit exceeded for Magic %d: Total P&L %.2f <= -%.2f. Positions locked.", 
                                                      currentMagic, totalPnL, StopValue);
                        Print(message);
                        Alert(message);
                    }
                }
            }
        }
        
        // For Lock mode, if lock exists, always check and adjust (even if not exceeded)
        if(isLockMode && !onlyDisplay && LockExists(currentMagic))
        {
            CheckAndAdjustLock(currentMagic);
        }
    }
    
    // Update display table
    DisplayTable();
}