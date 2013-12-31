//=====================================================================
//	Expert based on the ZigZagTrendDetector trend indicator.
//=====================================================================
#property copyright 	"Dima S."
#property link      	"dimascub@mail.com"
#property version   	"1.01"
#property description "Expert based on the ZigZagTrendDetector trend indicator."
//---------------------------------------------------------------------
//	Included libraries:
//---------------------------------------------------------------------
#include <Trade\Trade.mqh>
//---------------------------------------------------------------------
//	External parameters:
//---------------------------------------------------------------------
input double   Lots=0.1;
input int      ExtDepth=5;
input int      ExtDeviation= 5;
input int      ExtBackstep = 3;
//---------------------------------------------------------------------
int            indicator_handle=0;
//---------------------------------------------------------------------
//	Initialization event handler:
//---------------------------------------------------------------------
int OnInit()
  {
//	Create external indicator handle for future reference to it:
   ResetLastError();
   indicator_handle=iCustom(Symbol(),PERIOD_CURRENT,"Examples\\ZigZagTrendDetector",ExtDepth,ExtDeviation,ExtBackstep);

//	If initialization was unsuccessful, return nonzero code:
   if(indicator_handle==INVALID_HANDLE)
     {
      Print("ZigZagTrendDetector initialization error, Code = ",GetLastError());
      return(-1);
     }

   return(0);
  }
//---------------------------------------------------------------------
//	Deinitialization event handler:
//---------------------------------------------------------------------
void OnDeinit(const int _reason)
  {
//	Delete indicator handle:
   if(indicator_handle!=INVALID_HANDLE)
     {
      IndicatorRelease(indicator_handle);
     }
  }

//---------------------------------------------------------------------
//	Handler of event about new tick by the current symbol:
//---------------------------------------------------------------------
int    current_signal=0;
int    prev_signal=0;
bool   is_first_signal=true;
//---------------------------------------------------------------------
void OnTick()
  {
//	Wait for beginning of a new bar:
   if(CheckNewBar()!=1)
     {
      return;
     }

//	Get signal to open/close position:
   current_signal=GetSignal();
   if(is_first_signal==true)
     {
      prev_signal=current_signal;
      is_first_signal=false;
     }

//	Select position by current symbol:
   if(PositionSelect(Symbol())==true)
     {
      //	Check if we need to close a reverse position:
      if(CheckPositionClose(current_signal)==1)
        {
         return;
        }
     }

//	Check if there is the BUY signal:
   if(CheckBuySignal(current_signal,prev_signal)==1)
     {
      CTrade   trade;
      trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,Lots,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0);
     }

//	Check if there is the SELL signal:
   if(CheckSellSignal(current_signal,prev_signal)==1)
     {
      CTrade   trade;
      trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,Lots,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0);
     }

//	Save current signal:
   prev_signal=current_signal;
  }
//---------------------------------------------------------------------
//	Check if we need to close position:
//---------------------------------------------------------------------
//	returns:
//		0 - no open position
//		1 - position already opened in signal's direction
//---------------------------------------------------------------------
int CheckPositionClose(int _signal)
  {
   long      position_type=PositionGetInteger(POSITION_TYPE);

   if(_signal==1)
     {
      //	If there is the BUY position already opened, then return:
      if(position_type==(long)POSITION_TYPE_BUY)
        {
         return(1);
        }
     }

   if(_signal==-1)
     {
      //	If there is the SELL position already opened, then return:
      if(position_type==(long)POSITION_TYPE_SELL)
        {
         return(1);
        }
     }

//	Close position:
   CTrade   trade;
   trade.PositionClose(Symbol(),10);

   return(0);
  }
//---------------------------------------------------------------------
//	Check if there is the BUY signal:
//---------------------------------------------------------------------
//	returns:
//		0 - no signal
//		1 - there is the BUY signal
//---------------------------------------------------------------------
int CheckBuySignal(int _curr_signal,int _prev_signal)
  {
//	Check if signal has changed to BUY:
   if(( _curr_signal==1 && _prev_signal==0) || (_curr_signal==1 && _prev_signal==-1))
     {
      return(1);
     }

   return(0);
  }
//---------------------------------------------------------------------
//	Check if there is the SELL signal:
//---------------------------------------------------------------------
//	returns:
//		0 - no signal
//		1 - there is the SELL signal
//---------------------------------------------------------------------
int CheckSellSignal(int _curr_signal,int _prev_signal)
  {
//	Check if signal has changed to SELL:
   if(( _curr_signal==-1 && _prev_signal==0) || (_curr_signal==-1 && _prev_signal==1))
     {
      return(1);
     }

   return(0);
  }

//---------------------------------------------------------------------
//	Get signal to open/close position:
//---------------------------------------------------------------------
#define LEN	20
//---------------------------------------------------------------------
int GetSignal()
  {
   double      trend_direction[LEN];

//	Get signal from trend indicator:
   ResetLastError();
   if(CopyBuffer(indicator_handle,0,0,LEN,trend_direction)!=LEN)
     {
      Print("CopyBuffer copy error, Code = ",GetLastError());
      return(0);
     }

   return(( int)trend_direction[LEN-1]);
  }
//---------------------------------------------------------------------
//	Returns flag of a new bar:
//---------------------------------------------------------------------
//	- if it returns 1, there is a new bar
//---------------------------------------------------------------------
int CheckNewBar()
  {
   MqlRates      current_rates[1];

   ResetLastError();
   if(CopyRates(Symbol(),Period(),0,1,current_rates)!=1)
     {
      Print("CopyRates copy error, Code = ",GetLastError());
      return(0);
     }

   if(current_rates[0].tick_volume>1)
     {
      return(0);
     }

   return(1);
  }
//+------------------------------------------------------------------+
