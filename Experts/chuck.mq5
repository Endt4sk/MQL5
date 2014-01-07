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
#include <Expert\ExpertChuck.mqh>
#include <Expert\ExpertSignal.mqh>
#include <Expert\Signal\SignalChuck.mqh>
#include <Expert\Trailing\TrailingBottomTop.mqh>
#include <Expert\Money\MoneyNone.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string Inp_Expert_Title            ="ExpertChuck";
int          Expert_MagicNumber          =10981;
bool         Expert_EveryTick            =false;
//--- inputs for signal
input int      Inp_Signal_MBands_Period=13;
input int      Inp_Signal_MBands_Shift=0;
input double   Inp_Signal_MBands_Deviation=1.618;
input int      Inp_Signal_MBands_TakeProfit  =0;
input int      Inp_Signal_MBands_StopLoss    =20;

//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpertChuck ExtExpert;

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+

static int BARS;
//+------------------------------------------------------------------+
//| NewBar function                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   if(BARS!=Bars(_Symbol,_Period))
     {
      BARS=Bars(_Symbol,_Period);
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
   CSignalChuck *signal=new CSignalChuck;
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
   signal.PeriodMA(Inp_Signal_MBands_Period);
   signal.Shift(Inp_Signal_MBands_Shift);
   signal.Deviation(Inp_Signal_MBands_Deviation);
   signal.TakeLevel(Inp_Signal_MBands_TakeProfit);
   signal.StopLevel(Inp_Signal_MBands_StopLoss);
   signal.SetCShare(GetPointer(ExtExpert.CShare));
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
   trailing.SetCShare(GetPointer(ExtExpert.CShare));
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

   ExtExpert.CShare.zigzag_handle=IndicatorCreate(Symbol(),Period(),IND_CUSTOM,4,CustomZigZag_prop);
   if(ExtExpert.CShare.zigzag_handle==NULL)
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   ExtExpert.CShare.RPoint = 10 * Point();

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
   if(CopyBuffer(ExtExpert.CShare.zigzag_handle,1,1,1,ExtExpert.CShare.zigzag_high)<=0) return;
   if(CopyBuffer(ExtExpert.CShare.zigzag_handle,2,1,1,ExtExpert.CShare.zigzag_low)<=0) return;
   if(CopyBuffer(ExtExpert.CShare.zigzag_handle,0,1,1,ExtExpert.CShare.zigzag)<=0) return;
//--- set indexation of array MA[] as timeseries
   ArraySetAsSeries(ExtExpert.CShare.zigzag_high,true);
   ArraySetAsSeries(ExtExpert.CShare.zigzag_low,true);
   ArraySetAsSeries(ExtExpert.CShare.zigzag,true);
   int i,offset;
   printf("should be called by every hour");
   printf("zigzag_high = %f, zigzag_low = %f",ExtExpert.CShare.zigzag_high[0],ExtExpert.CShare.zigzag_low[0]);
   if(ExtExpert.CShare.zigzag[0] > 0.0) printf("zigzag = %f", ExtExpert.CShare.zigzag[0]);
   if(ExtExpert.CShare.zigzag_high[0] > 0.0)
     {
      if(ExtExpert.CShare.last_insert_index==-1 || !ExtExpert.CShare.IsLastHigh)
        {
         ExtExpert.CShare.last_insert_index=(ExtExpert.CShare.last_insert_index+1)%ValueSize;
        }
      ExtExpert.CShare.zigzag_value[ExtExpert.CShare.last_insert_index]=ExtExpert.CShare.zigzag_high[0];
      ExtExpert.CShare.IsLastHigh=true;
      for(i=1; i<=ValueSize; i++)
        {
         offset=(ExtExpert.CShare.last_insert_index+i)%ValueSize;
         if(ExtExpert.CShare.zigzag_value[offset]>0.0)
           {
            printf("value[%d] = %f",offset,ExtExpert.CShare.zigzag_value[offset]);
           }
        }
     }
   else if(ExtExpert.CShare.zigzag_low[0]>0.0)
     {
      if(ExtExpert.CShare.last_insert_index==-1 || ExtExpert.CShare.IsLastHigh)
        {
         ExtExpert.CShare.last_insert_index=(ExtExpert.CShare.last_insert_index+1)%ValueSize;
        }
      ExtExpert.CShare.zigzag_value[ExtExpert.CShare.last_insert_index]=ExtExpert.CShare.zigzag_low[0];
      ExtExpert.CShare.IsLastHigh=false;
      for(i=1; i<=ValueSize; i++)
        {
         offset=(ExtExpert.CShare.last_insert_index+i)%ValueSize;
         if(ExtExpert.CShare.zigzag_value[offset]>0.0)
           {
            printf("value[%d] = %f",offset,ExtExpert.CShare.zigzag_value[offset]);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   MqlDateTime tm;
   TimeCurrent(tm);
   
   if(tm.min==0)
     {
      //printf("close[0] = ", Close(0));
      UpdateValues();
     }
     //printf("Open[1] = %f", Close(1));
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| Function-event handler "trade"                                   |
//+------------------------------------------------------------------+
void OnTrade(void)
  {
    HistorySelect(0,TimeCurrent());
    uint     total=HistoryOrdersTotal();
    //if(
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
