//+------------------------------------------------------------------+
//|                                                   ExpertMACD.mq5 |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
#include <Expert\Signal\SignalMACD.mqh>
#include <Expert\Trailing\TrailingBottomTop.mqh>
#include <Expert\Money\MoneyNone.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string Inp_Expert_Title            ="ExpertMACD";
int          Expert_MagicNumber          =10981;
bool         Expert_EveryTick            =false;
//--- inputs for signal
input int    Inp_Signal_MACD_PeriodFast  =12;
input int    Inp_Signal_MACD_PeriodSlow  =24;
input int    Inp_Signal_MACD_PeriodSignal=9;
input int    Inp_Signal_MACD_TakeProfit  =50;
input int    Inp_Signal_MACD_StopLoss    =20;
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
int zigzag_handle, last_insert_index = -1;
bool IsLastHigh;
double zigzag_high[], zigzag_low[], zigzag_value[100];
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(-1);
     }
//--- Creation of signal object
   CSignalMACD *signal=new CSignalMACD;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(-2);
     }
//--- Add signal to expert (will be deleted automatically))
   if(!ExtExpert.InitSignal(signal))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing signal");
      ExtExpert.Deinit();
      return(-3);
     }
//--- Set signal parameters
   signal.PeriodFast(Inp_Signal_MACD_PeriodFast);
   signal.PeriodSlow(Inp_Signal_MACD_PeriodSlow);
   signal.PeriodSignal(Inp_Signal_MACD_PeriodSignal);
   signal.TakeLevel(Inp_Signal_MACD_TakeProfit);
   signal.StopLevel(Inp_Signal_MACD_StopLoss);
//--- Check signal parameters
   if(!signal.ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error signal parameters");
      ExtExpert.Deinit();
      return(-4);
     }
//--- Creation of trailing object
   CTrailingBottomTop *trailing=new CTrailingBottomTop;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(-5);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(-6);
     }
//--- Set trailing parameters
//--- Check trailing parameters
   if(!trailing.ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error trailing parameters");
      ExtExpert.Deinit();
      return(-7);
     }
//--- Creation of money object
   CMoneyNone *money=new CMoneyNone;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(-8);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(-9);
     }
//--- Set money parameters
//--- Check money parameters
   if(!money.ValidationSettings())
     {
      //--- failed
      printf(__FUNCTION__+": error money parameters");
      ExtExpert.Deinit();
      return(-10);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(-11);
     }
     
   MqlParam CustomZigZag_prop[];
   ArrayResize(CustomZigZag_prop,4);
   
   CustomZigZag_prop[0].type=TYPE_STRING;
   CustomZigZag_prop[0].string_value="Examples\\ZigZag";
   
   CustomZigZag_prop[1].type=TYPE_INT;
   CustomZigZag_prop[1].integer_value=12;
   
   CustomZigZag_prop[2].type=TYPE_INT;
   CustomZigZag_prop[2].integer_value=5;
   
   CustomZigZag_prop[3].type=TYPE_INT;
   CustomZigZag_prop[3].integer_value=3;

   
   zigzag_handle = IndicatorCreate(Symbol(),Period(),IND_CUSTOM,4,CustomZigZag_prop);
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
    
//--- succeed
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| Function-event handler "tick"                                    |
//+------------------------------------------------------------------+

void UpdateValues()
{
   if(CopyBuffer(zigzag_handle,1,0,1,zigzag_high)<=0) return;
   if(CopyBuffer(zigzag_handle,2,0,1,zigzag_low)<=0) return;
   //--- set indexation of array MA[] as timeseries
   ArraySetAsSeries(zigzag_high,true);
   ArraySetAsSeries(zigzag_low,true);
   int i, offset;
   printf("should be called by every hour");
   if(zigzag_high[0] > 0.0)
   {    
      if(last_insert_index == -1 || !IsLastHigh)
      {
         last_insert_index = (last_insert_index + 1) % ValueSize;
      }
      zigzag_value[last_insert_index] = zigzag_high[0];
      IsLastHigh = true;
      for(i = 1; i <= ValueSize; i++)
      {
         offset = (last_insert_index + i) % ValueSize;
         if(zigzag_value[offset] > 0.0)
         {
            printf("value[%d] = %f", offset, zigzag_value[offset]);
         }
      }
   }
   else if(zigzag_low[0] > 0.0)
   {
      if(last_insert_index == -1 || IsLastHigh)
      {
         last_insert_index = (last_insert_index + 1) % ValueSize;
      }
      zigzag_value[last_insert_index] = zigzag_low[0];
      IsLastHigh = false;
      for(i = 1; i <= ValueSize; i++)
      {
         offset = (last_insert_index + i) % ValueSize;
         if(zigzag_value[offset] > 0.0)
         {
            printf("value[%d] = %f", offset, zigzag_value[offset]);
         }
      }
   }
}

void OnTick(void)
  {
     UpdateValues();
  }
//+------------------------------------------------------------------+
//| Function-event handler "trade"                                   |
//+------------------------------------------------------------------+
void OnTrade(void)
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| Function-event handler "timer"                                   |
//+------------------------------------------------------------------+
void OnTimer(void)
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
