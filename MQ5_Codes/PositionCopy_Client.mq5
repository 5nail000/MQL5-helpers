//+------------------------------------------------------------------+
//|                                                     PositionCopy |
//|                         Version 2.20                             |
//|                                                                  |
//|            Expert Advisor to copy and log position data          |
//|                           (Client)                               |
//|                                                                  |
//|  Последние изменения:                                            |
//|  v.2.20                                                          |
//| Исправленна ошибка фильтрации, связанных с конвертацией символов |
//| + функция: Преобразование фильтра символов                       |
//| + функция: Парсинг параметра convertSymbols                      |
//|                                                                  |
//|  v.2.14                                                          |
//|  - Добавлен displayComment                                       |
//|  v.2.13                                                          |
//|  - пропускаем пустые строки файла от mql4                        |
//|  v.2.12                                                          |
//|  - Добавлено отключение слежения за TP и SL                      |
//|  v.2.11                                                          |
//|  - Добавлена SL и TP shifts                                      |
//|  v.2.10                                                          |
//|  - Добавлена отмена торгов при неактивном аккаунте/советнике     |
//|  v.2.09                                                          |
//|  - Добавлена конвертация симолов "USTECHCash=NAS100;BRENT=XBRUSD"|
//|  v.2.07                                                          |
//|  - Добавлена поддержка открытия позиций filling_modes:           |
//|                ORDER_FILLING_RETURN и ORDER_FILLING_FOK          |
//|  v.2.06                                                          |
//|  - Добавлено отселживание SL и TP                                |
//|  v.2.05                                                          |
//|  - Добавлена фильтрация по magic numbers                         |
//|  - Добавлено округление лотов до 0.01 если по пропорции он меньше|
//|  v.2.04                                                          |
//|  - Добавлен способ калькуляции размера лота "onenessBalance"     |
//|    лот определяется по пропорции баланса к множителю             |
//+------------------------------------------------------------------+

#property copyright "Snail000"
#property link      "https://www.mql5.com"
#property version   "2.20"

enum CopyType
  {
   fixed,
   oneness,
   onenessBalance,
   balanceProp,
   marginProp,
   marginFreeProp
  };
  
enum Switcher
  {
   ON,
   OFF
  };

//--- input parameters
input long  magicNumber = 333;                                            // Magic Number of Copier
input string shareName = "PositionCopy";                                  // Server Name
input string   displayComment = ": without a filters";                    // Display Comment

// Символы для фильтрации сделок, разделенные точкой с запятой
input string   filterSymbol_input = "";                                   // Server Filter of Symbols // EURUSD;USDJPY // empty=All
input string   filterMagic = "";                                          // Server Filter of Magics // 222;333 // empty=All
input string   convertSymbols = "OldSymbol=NewSymbol;.USTECHCash=NAS100"; // Symbol Convertation // OldSymbol=NewSymbol;...
input CopyType copyType = fixed;                                          // Lot Calculation Mode
input double proportional = 0.01;                                         // Fixed Lot / Proportion Multiplier
input int  distance = 1000000;                                            // Allowed Distance
input Switcher TPSL_switcher = OFF;                                       // SL and TP copying
input double addSLShift = 0.00;                                           // add SL shift
input double addTPShift = 0.00;                                           // add TP shift

uint  syncTime = 120;
string filterSymbol;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class AccountInfo
  {
public:
                     AccountInfo(string currency_, double balance_, double credit_, double marginFree_) :
                     currency(currency_),
                     balance(balance_),
                     credit(credit_),
                     margin(balance_ + credit_),
                     marginFree(marginFree_)
     {}

   const string      currency;
   const double      balance;
   const double      credit;
   const double      margin;
   const double      marginFree;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PositionInfo
  {
public:
   enum Direction
     {
      negative = -1,
      zero = 0,
      positive = 1
     };

   const string      symbol;
   const ulong       ticket;
   const datetime    time;
   const Direction   direction;
   const double      volume;
   const double      price;
   const double      stoploss;
   const double      takeprofit;
   const string      comment;
   const double      contract;

   virtual bool      Order(AccountInfo* clientAccountInfo, AccountInfo* serverAccountInfo) = 0;
   virtual bool      Update(PositionInfo* position) = 0;
   
   // Публичные методы для доступа к члену same
   bool IsSame() const { return same; }
   void SetSame(bool value) { same = value; }

protected:
   bool              same;

                     PositionInfo(string symbol_, ulong ticket_, datetime time_, Direction direction_, double volume_, double price_, double stoploss_, double takeprofit_, string comment_, double contract_) :
                     symbol(symbol_),
                     ticket(ticket_),
                     time(time_),
                     direction(direction_),
                     volume(volume_),
                     price(price_),
                     stoploss(stoploss_),
                     takeprofit(takeprofit_),
                     comment(comment_),
                     contract(contract_),
                     same(false)
     {}

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PositionServer : public PositionInfo
{
public:
    PositionServer(string symbol_, ulong ticket_, datetime time_, int direction_, double volume_, double price_, double stoploss_, double takeprofit_, double contract_, string comment_) :
        PositionInfo(symbol_, ticket_, time_, (Direction)direction_, volume_, price_, stoploss_, takeprofit_, comment_, contract_)
    {}

    virtual bool Order(AccountInfo* clientAccountInfo, AccountInfo* serverAccountInfo)
    {
        if (IsSame() || clientAccountInfo == NULL || serverAccountInfo == NULL)
            return false;

        // Проверка и парсинг convertSymbols
        string finalSymbol = Parse_ConvertSymbols(symbol);
        double tick = SymbolInfoDouble(finalSymbol, SYMBOL_TRADE_TICK_SIZE);
        MqlTradeRequest request;
        ZeroMemory(request);
        int diff = 0;
        if (direction == positive)
        {
            request.type = ORDER_TYPE_BUY;
            request.price = SymbolInfoDouble(finalSymbol, SYMBOL_ASK);
            diff = (int)((request.price - price) / tick);
        }
        else if (direction == negative)
        {
            request.type = ORDER_TYPE_SELL;
            request.price = SymbolInfoDouble(finalSymbol, SYMBOL_BID);
            diff = (int)((price - request.price) / tick);
        }
        else
            return false;
        if (diff > distance)
            return false;

        request.volume = CalcVolume(clientAccountInfo, serverAccountInfo);
        if (request.volume == 0)
            return false;

        request.action = TRADE_ACTION_DEAL;
        request.symbol = finalSymbol;
        request.magic = magicNumber;
        
        // Ignore TP and SL if TPSL_switcher is OFF
        if (TPSL_switcher == ON)
        {
            request.sl = stoploss;
            request.tp = takeprofit;
        }
        else
        {
            request.sl = 0;
            request.tp = 0;
        }
        
        request.comment = IntegerToString(ticket);
        request.magic = magicNumber;
        request.deviation = 100;
        request.type_filling = ORDER_FILLING_IOC;
        request.type_time = ORDER_TIME_GTC;
        MqlTradeResult result = { 0 };
                
        bool ret = OrderSend(request, result);

        // Логирование запроса
        // PrintFormat("OrderSend Request: Symbol=%s, Type=%d, Volume=%f, Price=%f, SL=%f, TP=%f, Comment=%s", request.symbol, request.type, request.volume, request.price, request.sl, request.tp, request.comment);        
        // Логирование результата
        // PrintFormat("OrderSend Result: Ret=%d, Order=%d, RequestID=%d, RetCode=%d, Comment=%s", ret, result.order, result.request_id, result.retcode, result.comment);
        
        if(result.retcode == 10030){
            request.type_filling = ORDER_FILLING_FOK;
            MqlTradeResult result = { 0 };
            ret = OrderSend(request, result);

            if(result.retcode == 10030){
               request.type_filling = ORDER_FILLING_RETURN;
               MqlTradeResult result = { 0 };
               ret = OrderSend(request, result);
            }
        }
        
        return ret;
    }

    virtual bool Update(PositionInfo* position)
    {
        SetSame(true);
        return true;
    }

private:

    double CalcVolume(AccountInfo* clientAccountInfo, AccountInfo* serverAccountInfo)
    {
        double vol = 0;
        
        switch (copyType)
        {
        case fixed:
            vol = proportional;
            break;
        case oneness:
            vol = proportional * volume;
            if(vol < 0.01) vol = 0.01;
            break;
        case onenessBalance:
            vol = (clientAccountInfo.balance/proportional) * volume;
            if(0.0066 < vol && vol < 0.01) vol = 0.01;
            // if(vol < 0.01) vol = 0.01;
            break;
        case balanceProp:
            vol = proportional * volume * clientAccountInfo.balance / serverAccountInfo.balance;
            break;
        case marginProp:
            vol = proportional * volume * clientAccountInfo.margin / serverAccountInfo.margin;
            break;
        case marginFreeProp:
            vol = proportional * volume * clientAccountInfo.marginFree / serverAccountInfo.marginFree;
            break;
        }
                
        // Проверка и парсинг convertSymbols
        string finalSymbol = Parse_ConvertSymbols(symbol);
        double minVolume = SymbolInfoDouble(finalSymbol, SYMBOL_VOLUME_MIN);
        int lot = (int)(vol / minVolume);
        
        return lot * minVolume;
    }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PositionClientPosition : public PositionInfo
{
public:
    PositionClientPosition(string symbol_, ulong ticket_, datetime time_, ENUM_POSITION_TYPE type, double volume_, double price_, double stoploss_, double takeprofit_, string comment_) :
        PositionInfo(symbol_, ticket_, time_, type == POSITION_TYPE_BUY ? positive : negative, volume_, price_, stoploss_, takeprofit_, comment_, SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE))
    {}

    virtual bool Order(AccountInfo* clientAccountInfo, AccountInfo* serverAccountInfo)
    {
        
        if (IsSame())
            return false;
        MqlTradeRequest request;
        ZeroMemory(request);
        if (direction == positive)
        {
            request.type = ORDER_TYPE_SELL;
            request.price = SymbolInfoDouble(symbol, SYMBOL_BID);
        }
        else if (direction == negative)
        {
            request.type = ORDER_TYPE_BUY;
            request.price = SymbolInfoDouble(symbol, SYMBOL_ASK);
        }
        else
            return false;
        request.action = TRADE_ACTION_DEAL;
        request.position = ticket;
        request.symbol = symbol;
        request.volume = volume;
        request.magic = magicNumber;
        request.deviation = 100;
        request.type_filling = ORDER_FILLING_IOC;
        request.type_time = ORDER_TIME_GTC;
        MqlTradeResult result = { 0 };
        
        // Ignore TP and SL if TPSL_switcher is OFF
        if (TPSL_switcher == ON)
        {
            request.sl = stoploss;
            request.tp = takeprofit;
        }
        else
        {
            request.sl = 0;
            request.tp = 0;
        }

        // Логирование запроса
        // PrintFormat("OrderSend Request: Symbol=%s, Type=%d, Volume=%f, Price=%f, SL=%f, TP=%f, Comment=%s", request.symbol, request.type, request.volume, request.price, request.sl, request.tp, request.comment);

        bool ret = OrderSend(request, result);
        
        // // Логирование результата
        PrintFormat("OrderSend Result: Ret=%d, Order=%d, RequestID=%d, RetCode=%d, Comment=%s", ret, result.order, result.request_id, result.retcode, result.comment);

        return ret;
    }

    virtual bool Update(PositionInfo* position)
    {   
        SetSame(true);
        
        if (TPSL_switcher == OFF) return false; // Do nothing if TPSL_switcher is OFF
        // Получаем количество знаков после запятой для символа
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
        // Округляем уровни SL и TP в соответствии с количеством знаков после запятой
        double normalizedStopLoss = (double)DoubleToString(position.stoploss, digits);
        double normalizedTakeProfit = (double)DoubleToString(position.takeprofit, digits);
        
        bool slChanged = (position.stoploss != normalizedStopLoss && position.stoploss > 0);
        bool tpChanged = (position.takeprofit != normalizedTakeProfit && position.takeprofit > 0);
        
        // Print("Symbol is: ", symbol);
        // Print("digits is: ", digits);
        // PrintFormat("SLTP Request: old_SL=%f, new_SL=%f", position.stoploss, normalizedStopLoss);
        // PrintFormat("SLTP Request: old_TP=%f, new_TP=%f", position.takeprofit, normalizedTakeProfit);

        // Если ничего не изменилось, выходим
        if (!slChanged && !tpChanged)
            return true;
            
        // Print("Here! is: ", ticket);

        // Создаем запрос на изменение уровней SL и TP
        MqlTradeRequest request;
        ZeroMemory(request);
        request.action = TRADE_ACTION_SLTP;
        request.position = ticket;

        // Устанавливаем новые уровни SL и TP только если они изменились
        request.sl = slChanged ? position.stoploss : normalizedStopLoss;
        request.tp = tpChanged ? position.takeprofit : normalizedTakeProfit;

        // Логирование запроса
        // PrintFormat("SLTP Request: Position=%d, SL=%f, TP=%f", request.position, request.sl, request.tp);

        // Отправляем запрос
        MqlTradeResult result;
        ZeroMemory(result);
        bool ret = OrderSend(request, result);

        //// Логирование результата
        // PrintFormat("SLTP Result: Ret=%d, Order=%d, RequestID=%d, RetCode=%d, Comment=%s", ret, result.order, result.request_id, result.retcode, result.comment);

        return ret;
    }

    bool UpdateSLTP(PositionInfo* server_position, PositionInfo* client_position)
    {
        if (TPSL_switcher == OFF) return false; // Do nothing if TPSL_switcher is OFF
        
        int digits = (int)SymbolInfoInteger(server_position.symbol, SYMBOL_DIGITS);
        // Print("Here! is: ", ticket);
    
        // Округляем уровни SL и TP в соответствии с количеством знаков после запятой
        double normalizedStopLoss_server = (double)DoubleToString(server_position.stoploss, digits);
        double normalizedTakeProfit_server = (double)DoubleToString(server_position.takeprofit, digits);
        double normalizedStopLoss_client = (double)DoubleToString(client_position.stoploss, digits);
        double normalizedTakeProfit_client = (double)DoubleToString(client_position.takeprofit, digits);
        
        if ((normalizedStopLoss_server + addSLShift) == normalizedStopLoss_client && (normalizedTakeProfit_server + addTPShift) == normalizedTakeProfit_client)
           {
            // Print("no changes");
            return false; // SL и TP не изменились
           }
//        PrintFormat("normalizedStopLoss_server=%d, normalizedStopLoss_client=%d, normalizedTakeProfit_server=%d, normalizedTakeProfit_client=%d",
//            normalizedStopLoss_server, normalizedStopLoss_client, normalizedTakeProfit_server, normalizedTakeProfit_client);           
            
        MqlTradeRequest request;
        ZeroMemory(request);
        request.action = TRADE_ACTION_SLTP;
        request.position = ticket;
        request.sl = normalizedStopLoss_server + addSLShift;
        request.tp = normalizedTakeProfit_server + addTPShift;

        MqlTradeResult result;
        ZeroMemory(result);
        bool ret = OrderSend(request, result);
               
        if (ret && result.retcode == TRADE_RETCODE_DONE)
        {
            // stoploss = newStopLoss;
            // takeprofit = newTakeProfit;
        }
        
        return ret;
    }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PositionClientOrder : public PositionInfo
{
public:
    PositionClientOrder(string symbol_, ulong ticket_, datetime time_, ENUM_ORDER_TYPE type, double volume_, double openPrice_, double stopLoss_, double takeProfit_, string comment_) :
        PositionInfo(symbol_, ticket_, time_, OrderTypeToDirection(type), volume_, openPrice_, stopLoss_, takeProfit_, comment_, SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE))
    {}

    virtual bool Order(AccountInfo* clientAccountInfo, AccountInfo* serverAccountInfo)
    {
        if (IsSame())
            return false;
        MqlTradeRequest request;
        ZeroMemory(request);
        request.action = TRADE_ACTION_REMOVE;
        request.magic = magicNumber;
        request.order = ticket;
        MqlTradeResult result = { 0 };
        bool ret = OrderSend(request, result);
//
//        // Логирование результата
//        PrintFormat("SLTP Result: Ret=%d, Order=%d, RequestID=%d, RetCode=%d, Comment=%s",
//            ret, result.order, result.request_id, result.retcode, result.comment);
        return ret;
    }

    virtual bool Update(PositionInfo* position)
    {
        SetSame(true);
        return true;
    }

private:
    Direction OrderTypeToDirection(ENUM_ORDER_TYPE type)
    {
        if (type == ORDER_TYPE_BUY || type == ORDER_TYPE_BUY_LIMIT)
            return positive;
        else if (type == ORDER_TYPE_SELL || type == ORDER_TYPE_SELL_LIMIT)
            return negative;
        else
            return zero;
    }
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   filterSymbol = ConvertFilterSymbol(filterSymbol_input, convertSymbols);
   EventSetMillisecondTimer(syncTime);
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
  }

//+------------------------------------------------------------------+
//| Чтение данных сервера из именованного канала                     |
//+------------------------------------------------------------------+
string ReadServerDataFromFile()
  {
   string fileName = shareName + ".csv";
   int file_handle = INVALID_HANDLE; // Инициализация переменной
   int attempts = 5; // Количество попыток чтения файла
   int delay = 50; // Задержка между попытками в миллисекундах
   for(int i = 0; i < attempts; i++)
     {
      file_handle = FileOpen(fileName, FILE_READ | FILE_CSV | FILE_COMMON);
      if(file_handle != INVALID_HANDLE)
        {
         break; // Успешное открытие файла
        }
      if(i > 0)
         Print("Error: Unable to open file for reading: ", fileName, ", attempt: ", i);
      Sleep(delay); // Задержка перед следующей попыткой
     }
   if(file_handle == INVALID_HANDLE)
     {
      Print("Error: Unable to open file for reading: ", fileName);
      return NULL;
     }
   string data = "";
   while(!FileIsEnding(file_handle))
     {
      data += FileReadString(file_handle) + "\n";
     }
   FileClose(file_handle);
   return data;
  }

//+------------------------------------------------------------------+
//| Получение информации о сервере                                   |
//+------------------------------------------------------------------+
bool GetServerInfo(string serverInfo, AccountInfo*& accountInfo, PositionInfo*& positionInfo[])
  {

   // Разделение данных по строкам
   string lines[];
   int lineCount = StringSplit(serverInfo, '\n', lines);

   // Обработка данных об аккаунте
   if(lineCount < 1)
      return false; // Проверка на минимальное количество строк

   // Обработка информации о позициях
   int positionCount = 0;
   ArrayResize(positionInfo, lineCount - 2);
   for(int i = 0; i < lineCount; i++)
     {
      string trimmedLine = StringSubstr(lines[i], 0, StringFind(lines[i], "\r\n")); // Удаление пробелов
      if(trimmedLine == "")
         continue; // Пропускаем пустые строки
      if(StringLen(trimmedLine) == 1)
         continue; // Пропускаем пустые строки

      string columns[];
      StringSplit(trimmedLine, ';', columns);
      
      // Парсинг данных каждой сделки
      ulong ticket = StringToInteger(columns[0]);
      string symbol = columns[1];
      datetime time = (datetime)StringToInteger(columns[11]);
      int direction = (int)StringToInteger(columns[2]);
      double volume = StringToDouble(columns[3]);
      double price = StringToDouble(columns[4]);
      double stoploss = StringToDouble(columns[5]);
      double takeprofit = StringToDouble(columns[6]);
      double contract = StringToDouble(columns[13]);
      ulong magic = StringToInteger(columns[14]);
      string comment = columns[15];
      // Фильтруем символы
      if(!IsSymbolAllowed(symbol))
        {
         ArrayFree(columns);
         continue;
        }
        
      if(!IsMagicAllowed(string(magic)))
        {
         ArrayFree(columns);
         continue;
        }

      // Создание объекта PositionServer и добавление в массив
      positionInfo[positionCount] = new PositionServer(
         symbol,
         ticket,
         time,
         direction,
         volume,
         price,
         stoploss,
         takeprofit,
         contract,
         comment
      );
      positionCount++;
      string currency = columns[7];
      double balance = StringToDouble(columns[8]);
      double credit = StringToDouble(columns[9]);
      double marginFree = StringToDouble(columns[10]);
      // Освобождение предыдущей памяти, если она была выделена
      if(accountInfo != NULL)
        {
         delete accountInfo;
         accountInfo = NULL;
        }
      accountInfo = new AccountInfo(currency, balance, credit, marginFree);
      ArrayFree(columns);
     }
   ArrayFree(lines);
   ArrayResize(positionInfo, positionCount);
   return true;
  }

//+------------------------------------------------------------------+
//| Проверка, разрешен ли символ                                     |
//+------------------------------------------------------------------+
bool IsSymbolAllowed(string symbol)
  {
   if(filterSymbol == "" || filterSymbol == "All")
     {
      return true;
     }
   string symbols[];
   int count = StringSplit(filterSymbol, ';', symbols);
   for(int i = 0; i < count; i++)
     {
      if(StringFind(symbol, symbols[i]) == 0)
        {
         ArrayFree(symbols);
         return true;
        }
     }
     
   ArrayFree(symbols);
   return false;
  }
  
//+------------------------------------------------------------------+
//| Проверка, разрешен ли Мэджик                                     |
//+------------------------------------------------------------------+
bool IsMagicAllowed(string filter)
  {
   if(filterMagic == "" || filterMagic == "All")
     {
      return true;
     }
   string magics[];
   int count = StringSplit(filterMagic, ';', magics);
   for(int i = 0; i < count; i++)
     {
      if(StringFind(filter, magics[i]) == 0)
        {
         ArrayFree(magics);
         return true;
        }
     }
   
   ArrayFree(magics);
   return false;
  }

//+------------------------------------------------------------------+
//| Получение информации о клиенте                                   |
//+------------------------------------------------------------------+
bool GetClientInfo(AccountInfo*& accountInfo, PositionInfo*& positionInfo[])
  {
// Получаем информацию об аккаунте
   string currency = AccountInfoString(ACCOUNT_CURRENCY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double credit = AccountInfoDouble(ACCOUNT_CREDIT);
   double marginFree = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   accountInfo = new AccountInfo(currency, balance, credit, marginFree);

   // Получаем количество позиций и ордеров с совпадающим magicNumber
   uint resultSize = 0;
   uint positionSize = PositionsTotal();
   for(uint i = 0; i < positionSize; i++)
     {
      PositionSelectByTicket(PositionGetTicket(i));
      if(PositionGetInteger(POSITION_MAGIC) == magicNumber && IsSymbolAllowed(PositionGetString(POSITION_SYMBOL)))
         resultSize++;
     }
   uint orderSize = OrdersTotal();
   for(uint i = 0; i < orderSize; i++)
     {
      if(!OrderSelect(OrderGetTicket(i)))
         continue;
      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(OrderGetInteger(ORDER_MAGIC) == magicNumber && (orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL) && IsSymbolAllowed(OrderGetString(ORDER_SYMBOL)))
         resultSize++;
     }
   ArrayResize(positionInfo, resultSize);
   
   // Получаем позиции
   uint index = 0;
   for(uint i = 0; i < positionSize; i++)
     {
      ulong ticket = PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      if(PositionGetInteger(POSITION_MAGIC) == magicNumber && IsSymbolAllowed(PositionGetString(POSITION_SYMBOL)))
        {
         string symbol = PositionGetString(POSITION_SYMBOL);
         datetime time = (datetime)PositionGetInteger(POSITION_TIME);
         ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double stopLoss = PositionGetDouble(POSITION_SL);
         double takeProfit = PositionGetDouble(POSITION_TP);
         string comment = PositionGetString(POSITION_COMMENT);
         positionInfo[index++] = new PositionClientPosition(symbol, ticket, time, positionType, volume, openPrice, stopLoss, takeProfit, comment);
        }
     }
     
   // Получаем ордера
   for(uint i = 0; i < orderSize; i++)
     {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket))
         continue;
      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(OrderGetInteger(ORDER_MAGIC) == magicNumber && (orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL) && IsSymbolAllowed(OrderGetString(ORDER_SYMBOL)))
        {
         string symbol = OrderGetString(ORDER_SYMBOL);
         datetime time = (datetime)OrderGetInteger(ORDER_TIME_SETUP_MSC);
         double volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
         double openPrice = OrderGetDouble(ORDER_PRICE_OPEN);
         double stopLoss = OrderGetDouble(ORDER_SL);
         double takeProfit = OrderGetDouble(ORDER_TP);
         string comment = OrderGetString(ORDER_COMMENT);
         positionInfo[index++] = new PositionClientOrder(symbol, ticket, time, orderType, volume, openPrice, stopLoss, takeProfit, comment);
        }
     }
   return true;
  }


//+-------------------------------------------------------------------+
//| Преобразование фильтра символов                                   |
//|                                                                   |
//| Функция принимает строку фильтра символов и строку конвертации    |
//| символов, и заменяет исходные символы на их конвертированные      |
//| аналоги (если такие указаны). Возвращает преобразованный фильтр.  |
//| Зачем это нужно:                                                  |
//| - Предотвращение ошибок фильтрации, связанных с конвертацией      |
//|   символов.                                                       |
//| - Защита от случайного открытия сделок по некорректным символам.  |
//+-------------------------------------------------------------------+
string ConvertFilterSymbol(string localFilterSymbol, string localConvertSymbols) {

    if (localFilterSymbol == "" || localFilterSymbol == "All") return localFilterSymbol;
    if (localConvertSymbols == "") return localFilterSymbol;

    // Начинаем с оригинального фильтра
    string finalFilter = localFilterSymbol;
    
    // Разделяем строку конвертаций на пары
    string mappings[];
    int count = StringSplit(localConvertSymbols, ';', mappings);

    // Проходим по каждому символу в фильтре
    string symbols[];
    int symbolCount = StringSplit(localFilterSymbol, ';', symbols);

    for (int i = 0; i < symbolCount; i++) {
        // Ищем конвертацию для каждого символа
        for (int j = 0; j < count; j++) {
            string pair[];
            StringSplit(mappings[j], '=', pair); // Разделяем каждую пару на исходный и целевой символы
            if (ArraySize(pair) == 2 && symbols[i] == pair[0]) { // Проверяем соответствие исходного символа
                // Если конвертированный символ не добавлен, добавляем его в finalFilter
                if (StringFind(finalFilter, pair[1]) == -1) {
                    finalFilter += ";" + pair[1]; // Добавляем конвертированный символ
                    ArrayFree(pair);
                }
                break;
            }
        }
    }

    // Добавляем в результат символы из строки конвертаций, которые отсутствуют в фильтре
    for (int j = 0; j < count; j++) {
        string pair[];
        StringSplit(mappings[j], '=', pair);
        if (ArraySize(pair) == 2) {
            // Если исходный символ или его конвертированный аналог отсутствуют, добавляем их
            if (StringFind(finalFilter, pair[0]) == -1 && StringFind(finalFilter, pair[1]) == -1) {
                finalFilter += ";" + pair[1]; // Добавляем символ в итоговый фильтр
                ArrayFree(pair);
            }
        }
    }
    
    ArrayFree(mappings);
    ArrayFree(symbols);
    return finalFilter;
}


// Проверка и парсинг convertSymbols
string Parse_ConvertSymbols(string symbol)
{
   string parsedSymbol = symbol;
   if (convertSymbols != "")
   {
     string mappings[];
     int count = StringSplit(convertSymbols, ';', mappings);
     for (int i = 0; i < count; i++)
     {
         string pair[];
         StringSplit(mappings[i], '=', pair);
         if (ArraySize(pair) == 2 && symbol == pair[0])
         {
             parsedSymbol = pair[1];
             ArrayFree(mappings);
             ArrayFree(pair);
             break;
         }
     }
   }
   
   return parsedSymbol;
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {

  // =============================
  // Проверки на отмену торговли
  if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
     string forbidden_reason = "";
     if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) forbidden_reason = forbidden_reason + "in the terminal settings";
     if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
       {
         if(forbidden_reason == "") forbidden_reason = forbidden_reason + "forbidden for the account";
         else forbidden_reason = forbidden_reason + " + forbidden for the account";
       }
     if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
       {
         if(forbidden_reason == "") forbidden_reason = forbidden_reason + "in the program settings";
         else forbidden_reason = forbidden_reason + " + in the program settings";
       }
     
      Comment("\n\n\n\n        [ " + shareName + displayComment + " ]\n\n                TRADING NOT ALLOWED " + forbidden_reason);
      return;
     }

   // =============================
   // Чтение данных сервера из файла
   string serverData = ReadServerDataFromFile();
   if(serverData == NULL)
     {
      Comment("\n\n\n\n        [ " + shareName + displayComment + " ]");
      return;
     }

   // =============================
   // Получение информации о сервере
   AccountInfo* serverAccountInfo = NULL;
   PositionInfo* serverPositionInfo[];
   if(!GetServerInfo(serverData, serverAccountInfo, serverPositionInfo))
      return;

   // =============================
   // Получение информации о клиенте
   AccountInfo* clientAccountInfo = NULL;
   PositionInfo* clientPositionInfo[];
   if(!GetClientInfo(clientAccountInfo, clientPositionInfo))
      return;

   // =============================
   // Сравнение и обновление позиций
   int serverSize = ArraySize(serverPositionInfo);
   int clientSize = ArraySize(clientPositionInfo);
   for(int i = 0; i < serverSize; i++)
     {
      for(int j = 0; j < clientSize; j++)
        {
         if(serverPositionInfo[i].ticket == StringToInteger(clientPositionInfo[j].comment))
           {
                // Обновление SL и TP на клиенте, если они изменились на сервере
                PositionClientPosition* clientPos = (PositionClientPosition*)clientPositionInfo[j];
                bool updated = clientPos.UpdateSLTP(serverPositionInfo[i], clientPositionInfo[j]);
                if (updated)
                {
                    Print("Client SLTP update result: ", updated, " for ticket: ", clientPositionInfo[j].ticket);
                }
            serverPositionInfo[i].Update(clientPositionInfo[j]);
            clientPositionInfo[j].Update(serverPositionInfo[i]);
           }
        }
     }

   // =============================
   // Открытие или закрытие позиций
   for(int i = 0; i < clientSize; i++)
     {
      if(!clientPositionInfo[i].IsSame())
        {
         bool result = clientPositionInfo[i].Order(clientAccountInfo, serverAccountInfo);
         Print("Client Order result: ", result, " for ticket: ", clientPositionInfo[i].ticket);
        }
     }
   for(int i = 0; i < serverSize; i++)
     {
      if(!serverPositionInfo[i].IsSame())
        {
         bool result = serverPositionInfo[i].Order(clientAccountInfo, serverAccountInfo);
         Print("Server Order result: ", result, " for ticket: ", serverPositionInfo[i].ticket);
        }
     }

   // =============================
   // Вывод информации о позициях в комментариях на графике
   string comments;
   comments = "\n\n\n        [ " + shareName + displayComment + " ]\n\n        SERVER:\n";
   for(int i = 0; i < serverSize; i++)
     {
      string direction = serverPositionInfo[i].direction == PositionInfo::positive ? "BUY" : "SELL";
      comments += "                " + direction + " | " + serverPositionInfo[i].symbol + " | " +
                  DoubleToString(serverPositionInfo[i].volume, 2) + " | " +
                  DoubleToString(serverPositionInfo[i].price, (int)SymbolInfoInteger(serverPositionInfo[i].symbol, SYMBOL_DIGITS)) +
                  " | " + IntegerToString(serverPositionInfo[i].ticket) +
                  " | " + serverPositionInfo[i].comment + "\n";
     }
   comments += "\n        CLIENT:\n";
   for(int i = 0; i < clientSize; i++)
     {
      string direction = clientPositionInfo[i].direction == PositionInfo::positive ? "BUY" : "SELL";
      comments += "                " + direction + " | " + clientPositionInfo[i].symbol + " | " +
                  DoubleToString(clientPositionInfo[i].volume, 2) + " | " +
                  DoubleToString(clientPositionInfo[i].price, (int)SymbolInfoInteger(clientPositionInfo[i].symbol, SYMBOL_DIGITS)) +
                  " | " + clientPositionInfo[i].comment + "\n";
     }
   Comment(comments);
   
   // =============================
   // Освобождение памяти для объектов AccountInfo и PositionInfo
   if(serverAccountInfo != NULL)
     {
      delete serverAccountInfo;
      serverAccountInfo = NULL;
     }
   for(int i = 0; i < ArraySize(serverPositionInfo); i++)
     {
      if(serverPositionInfo[i] != NULL)
        {
         delete serverPositionInfo[i];
         serverPositionInfo[i] = NULL;
        }
     }
   if(clientAccountInfo != NULL)
     {
      delete clientAccountInfo;
      clientAccountInfo = NULL;
     }
   for(int i = 0; i < ArraySize(clientPositionInfo); i++)
     {
      if(clientPositionInfo[i] != NULL)
        {
         delete clientPositionInfo[i];
         clientPositionInfo[i] = NULL;
        }
     }

   // =============================
   // Освобождение памяти для массивов
   ArrayFree(serverPositionInfo);
   ArrayFree(clientPositionInfo);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
