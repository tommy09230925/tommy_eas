///+------------------------------------------------------------------+
//|                                               fiind_peak_low.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh> //加載標準程序庫
#include <Trade\SymbolInfo.mqh> //加載訂單品種資訊
#include <Indicators\Trend.mqh> //加載指標程序庫
#include <Trade\PositionInfo.mqh> //加載訂單位置程序庫
CTrade trade;
CSymbolInfo symbolinfo;
CPositionInfo positioninfo;
input double ratio = 0.05;
MqlRates PriceInformation[];
bool HasBuy = false;
bool HasSell = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArraySetAsSeries(PriceInformation,true);
   ArrayResize(PriceInformation,100); //限定數組大小，防止越界
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
//刷新訂單
   symbolinfo.Refresh();

//刷新訂單
   symbolinfo.RefreshRates();


//抓取前8根K線的開盤、收盤、最高、最低價
//k0、k1、k2、k3、k4、k5
//舉例來說，k代表k線，數字代表第幾根k線(倒數)，O表示開盤價，L最低價，H最高價，C收盤價
//K4L，也就是倒數第4根k線最低價

   int Data = CopyRates(Symbol(),PERIOD_CURRENT,0,Bars(Symbol(),PERIOD_CURRENT),PriceInformation);


   double k1H = PriceInformation[1].high;
   double k2H = PriceInformation[2].high;
   double k3H = PriceInformation[3].high;
   double k4H = PriceInformation[4].high;
   double k5H = PriceInformation[5].high;

   double k1L = PriceInformation[1].low;
   double k2L = PriceInformation[2].low;
   double k3L = PriceInformation[3].low;
   double k4L = PriceInformation[4].low;
   double k5L = PriceInformation[5].low;

   double k0O = PriceInformation[0].open;

//買單判斷
   if(HasBuy == false)
     {
      // 加入盤整判斷
      double arr_high[] = {k1H, k2H, k3H, k4H, k5H};
      double arr_low[] = {k1L, k2L, k3L, k4L, k5L};
      bool Correction = true;

      for(int i=0; i < 4; i++)
        {
         // 相鄰 2日的高點差不操過 0.1%
         if(MathAbs((arr_high[i] - arr_high[i+1])/arr_high[i]) >= 0.001)
            Correction = false;
        }

      for(int i=0; i < 4; i++)
        {
         //  相鄰2日的低點差不操過 0.1%
         if(MathAbs((arr_low[i] - arr_low[i+1])/arr_low[i]) >= 0.001)
            Correction = false;
        }

      if(Correction == true)
         printf("盤整\n");
      else
         printf("不盤整\n");

      /*  當日的高低點差
      for (int i=0; i < 5; i++)
      {
         if(((arr_high[i] - arr_low[i])/arr_high[i]) >= 0.01)
            Correction = false;
       }
       */


      // 用迴圈找出預備交日(K2)的前5日的K線的最高價
      // 目前只用到 max1
      int n = 5;

      double Hmax1 = arr_high[0];
      double Hmax2 = arr_high[0];
      double Lmax1 = arr_low[0];
      double Lmax2 = arr_low[0];

      for(int i = 1; i < n; i++)
        {
         if(arr_high[i] >= Hmax1)
           {
            Hmax2 = Hmax1;
            Hmax1 = arr_high[i];
           }
         else
            if(arr_high[i] > Hmax2)
              {
               Hmax2 = arr_high[i];
              }
        }
      printf("高點最大值: %f\n", Hmax1);
      printf("高點二大值: %f\n", Hmax2);


      for(int i = 1; i < n; i++)
        {
         if(arr_low[i] >= Lmax1)
           {
            Lmax2 = Lmax1;
            Lmax1 = arr_low[i];
           }
         else
            if(arr_low[i] > Lmax2)
              {
               Lmax2 = arr_low[i];
              }
        }
      printf("低點最大值: %f\n", Lmax1);
      printf("低點二大值: %f\n", Lmax2);


      //如果發生盤整，K1突破盤整(頭頭高、低低高)，K0日就買入交易
     
         if(Hmax1 == k1H &&  Hmax2 == k5H)

           {

            //買入0.01手，K0O為買入價，設定停損點
            trade.Buy(0.01,_Symbol,k0O);
            HasBuy = true;
           }

        
     }
   else
     {
      //設定新的止損點

      double n = 20.0;
      double sum = 0;
      double average20day = 0;
      double NewStopLoss;

      for(int i=1; i<=n; i++)
        {
         sum += PriceInformation[i].low;
        }

      average20day = sum/n;
      printf("average=%3.2f",average20day);

      //移動止損，每一訂單的止損都是前兩根K線的最低點的最大值
      //當20日平均最低價的止損比較高時，20日平均最低價當作止損
      if(PriceInformation[1].low > PriceInformation[2].low)
         NewStopLoss =  PriceInformation[1].low;
      else
         NewStopLoss =  PriceInformation[2].low;
      if(NewStopLoss <  average20day)
         NewStopLoss = average20day;

      //Modify the stop loss
      //trade.PositionModify(PositionTicket,NewStopLoss,0);
      if(NewStopLoss > k0O)
        {
         //今日開盤價低於停損點，賣出
         for(int i=PositionsTotal()-1; i>0; i--) // look at all position
           {
            int ticket = PositionGetTicket(i);
            trade.PositionClose(i);
           }
         HasBuy = false;
        }
     }




  } // end of On_Tick()




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

