//+------------------------------------------------------------------+
//|                                                    zigzag_EA.mq5 |
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
CiMA ima;
CTrade trade;
CSymbolInfo symbolinfo;
CPositionInfo positioninfo;
double zigzagzhi[]; //存儲所有K線上zigzag的值
double zigzag[]; //存儲zigzag的高低點
int k[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   
   ArraySetAsSeries(zigzagzhi,true);//把帶陣列轉為時間序列，倒敘
   ArraySetAsSeries(zigzag,true);//把帶陣列轉為時間序列，倒敘
   ArraySetAsSeries(k,true);//把K線轉為時間序列，倒敘
   ArrayResize(k,500);//把K線轉為時間序列，倒敘
   ArrayResize(zigzagzhi,500); //限定數組大小，防止越界
   ArrayResize(zigzag,4); //限定數組大小，防止越界
   
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
   string signal = "";
   ima.Create(_Symbol,PERIOD_CURRENT,120,0,MODE_EMA,PRICE_CLOSE);
   ima.Refresh(); //刷新ima數據
   //打印當前ma
   //Print(ima.Main(0)); 
   ima.AddToChart(0,0);
   symbolinfo.Refresh(); //刷新訂單
   symbolinfo.RefreshRates(); //刷新訂單
   int zigzag_handle = iCustom(_Symbol,PERIOD_CURRENT,"Examples\\ZigZag");
   CopyBuffer(zigzag_handle,0,0,500,zigzagzhi);
   MqlRates PriceInformation[];
   //set it from current candle to old candle

   ArraySetAsSeries(PriceInformation,true);

//copy price data i narray

   int Data = CopyRates(Symbol(),PERIOD_CURRENT,0,Bars(Symbol(),PERIOD_CURRENT),PriceInformation);

   double closePrice = PriceInformation[1].close;
   double openPrice = PriceInformation[1].open;

//Chart output

   Comment("Close price for candle",closePrice);

//Create an array for Volume
   double VolArray[];

//sorting the array from the current data
   ArraySetAsSeries(VolArray,true);

//defining Volume
   int VolDef=iVolumes(_Symbol,_Period,VOLUME_TICK);

//filling the array
   CopyBuffer(VolDef,0,0,4,VolArray);
   int jishu = 0;
   for(int i=0; i<500; i++)
     {
      if(jishu>3)
        {
         break;
        }
      if(zigzagzhi[i]>0)
        {
         zigzag[jishu]= zigzagzhi[i];
         k[jishu] = i;
         jishu++;
        }
     }
     //int total = PositionsTotal();
     //int total = PositionsTotal();
//(symbolinfo.Ask()-zigzag[2])<=100*Point() &&
      //create an array for the price data
   double PriceArray[];
   //define the AverageTrueRange EA
   int AverageTrueRangeDefinition = iATR(_Symbol,_Period,14);
   
    //sort the prices from the current candle downwards
  ArraySetAsSeries(PriceArray,true);
  
  //define EA,Buffer 0,3 candle,save in array
  CopyBuffer(AverageTrueRangeDefinition,0,0,3,PriceArray);
  
  //calcute the current candle 
  double AverageTrueRangeValue = NormalizeDouble(PriceArray[0],5);
  
    static double oldValue;
  
  //Initial for the old value
  if (oldValue==0)
  {
    oldValue=AverageTrueRangeValue;
  }
   // buy signal
   
   //If it is going up
   if(AverageTrueRangeValue>oldValue)
     {
      signal="buy";
     }
     
     //sell signal
     if(AverageTrueRangeValue<oldValue)
     {
      signal="sell";
     }
   double whobig = MathMax(zigzag[3],zigzag[1]);
   double whosmall = MathMin(zigzag[3],zigzag[1]);
   double big_small = whobig-whosmall;
     if(zigzag[1]>zigzag[0] && zigzag[1]>zigzag[2] && zigzag[3]>zigzag[2] && openPrice>zigzag[2] && closePrice<zigzag[2] && big_small<=150*Point() && signal == "sell" && closePrice<ima.Main(k[1]))
       {
        double sl = zigzag[1]+150*Point();
        double tp = symbolinfo.Bid()-(zigzag[1]-zigzag[2])*2;
        
        if(sl!=LastStopLoss())
          {
            trade.SellLimit(0.5,symbolinfo.Bid()+100*Point(),NULL,sl,tp);
          }
        
       }

  }
//+------------------------------------------------------------------+
 //上一單的止損
 double LastStopLoss() 
 {
 double a=0;
 int total = PositionsTotal();
 if(positioninfo.SelectByIndex(total-1)==true)
   {
    a=positioninfo.StopLoss();
   }
 
 return (a);
 }


