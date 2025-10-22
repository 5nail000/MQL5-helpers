//+------------------------------------------------------------------+
//|                                           SendTradesNotification |
//+------------------------------------------------------------------+
//|                                                                  |
//|                         Version 1.01                             |
//|            Expert Advisor For Sending Notifications              |
//|                                                                  |
//|  Последние изменения:                                            |
//|  v1.01                                                           |
//|  - Добавлены флаги для информирования открытия и закрытия        |
//|  - Исправлен баг, в trans.deal_type == DEAL_TYPE_BUY, было ORDER |
//+------------------------------------------------------------------+

#property copyright "Snail000"
#property link      "https://www.mql5.com"
#property version   "1.01"

enum nStyles { off = 0, on = 1 };

input string Title         = "ECN TRADE !";            // Notification Title
input nStyles notifyOpen   = 1;                        // Notify Opening
input nStyles notifyClose  = 1;                        // Notify Closing

nStyles notifyDeals  = 1;                        // Deals Notification Switcher
string notifyTitle = Title != "" ? Title + "\n" : "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, 
                        const MqlTradeRequest& request, 
                        const MqlTradeResult& result)
  {
   if(notifyDeals == 1 && trans.type==TRADE_TRANSACTION_DEAL_ADD)
     {
      
      //--- Получаем тикет сделки и выбираем сделку из списка по тикету
      ulong deal_ticket=trans.deal;
      string message;
      string direction;
      
      if(HistoryDealSelect(deal_ticket)){
         string deal_price = string(HistoryDealGetDouble(deal_ticket, DEAL_PRICE));
         ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
         if(entry==DEAL_ENTRY_IN && trans.volume > 0 && notifyOpen == 1){         
            direction = trans.deal_type == DEAL_TYPE_BUY ? "ПОКУПКУ" : "ПРОДАЖУ";
            message = notifyTitle+"Вошли в " + direction + ": " + trans.symbol + "\nРазмер лота: " + DoubleToString(trans.volume, 2) +
                      "\nЦена на входе: " + deal_price +
                      "\nКоментарий: " + HistoryDealGetString(deal_ticket, DEAL_COMMENT) +
                      "\nMagic: " + IntegerToString(HistoryDealGetInteger(deal_ticket, DEAL_MAGIC));
            SendNotification(message);
         }
         if(entry==DEAL_ENTRY_OUT && notifyClose == 1){
            double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT) + HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION) + HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
            message = notifyTitle+"Закрыли позицию: " + trans.symbol + "\nРазмер лота: " + DoubleToString(trans.volume, 2) +
                      "\nПрибыль: " + DoubleToString(profit, 2) + 
                      "\nЦена на выходе: " + deal_price +
                      "\nТекущий баланс/еквити: " + string(AccountInfoDouble(ACCOUNT_BALANCE)) + "(" + string(AccountInfoDouble(ACCOUNT_EQUITY)) + ")" +
                      "\nКоментарий: " + HistoryDealGetString(deal_ticket, DEAL_COMMENT) +
                      "\nMagic: " + IntegerToString(HistoryDealGetInteger(deal_ticket, DEAL_MAGIC));
            SendNotification(message);
         }
      }
     }
  }

//+------------------------------------------------------------------+
