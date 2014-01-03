//+------------------------------------------------------------------+
//|                                                   TrailingMA.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertTrailing.mqh>
#include <Expert\ExpertChuck.mqh>

class CTrailingBottomTop : public CExpertTrailing
  {
protected:
   CShareInfo             *CShare;

public:
                     CTrailingBottomTop(void);
                    ~CTrailingBottomTop(void);
   //--- methods of initialization of protected data
   void SetCShare(CShareInfo *value){CShare = value;printf("cshare = %f", CShare.last_insert_index);}
   virtual bool      ValidationSettings(void);
   //---
   virtual bool      CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp);
   virtual bool      CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CTrailingBottomTop::CTrailingBottomTop()
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CTrailingBottomTop::~CTrailingBottomTop(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CTrailingBottomTop::ValidationSettings(void)
  {
   if(!CExpertTrailing::ValidationSettings())
      return(false);
//--- initial data checks
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking for input parameters and setting protected data.        |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for long position.          |
//+------------------------------------------------------------------+
bool CTrailingBottomTop::CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp)
  {
//--- check
   if(position==NULL)
      return(false);
//---

   double level =NormalizeDouble(m_symbol.Bid()-m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   printf("level = %f", level);
   printf("ticket = %f", position.Identifier());
   printf("openprice = %f", position.PriceOpen());
   printf("stoploss = %f", position.StopLoss());
   printf("tp = %f", position.TakeProfit());
   double new_sl=0.0;
   printf("zigzag0 = %f", CShare.zigzag_value[CShare.index(0)]);
   if(CShare.IsLastHigh)
   {
      //if(CShare.zigzag_value[CShare.index(0)] < CShare.zigzag_value[CShare.index(2)])
      {
         new_sl = CShare.zigzag_value[CShare.index(1)];
      }
   }
   else
   {
      new_sl = (CShare.zigzag_value[CShare.index(1)] - CShare.zigzag_value[CShare.index(2)]) / 2.0 + CShare.zigzag_value[CShare.index(2)];
   }
   
   printf("new_sl = %f", new_sl);
   
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
   
   if(pos_sl < position.PriceOpen() && position.PriceCurrent()- position.PriceOpen() > position.PriceOpen() - pos_sl)
   {
      new_sl = MathMax(new_sl, position.PriceOpen());
   }
//---
   sl=EMPTY_VALUE;
   tp=EMPTY_VALUE;
   if(new_sl>base && new_sl<level)
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for short position.         |
//+------------------------------------------------------------------+
bool CTrailingBottomTop::CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp)
  {
//--- check
   if(position==NULL)
      return(false);
//---
   double level =NormalizeDouble(m_symbol.Ask()+m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   double new_sl=0.0;
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
   
   if(CShare.IsLastHigh)
   {
      //if(CShare.zigzag_value[CShare.index(0)] < CShare.zigzag_value[CShare.index(2)])
      new_sl = (CShare.zigzag_value[CShare.index(2)] - CShare.zigzag_value[CShare.index(1)]) / 2.0 + CShare.zigzag_value[CShare.index(1)];
   }
   else
   {
      new_sl = CShare.zigzag_value[CShare.index(1)];
   }
   if(pos_sl > position.PriceOpen() && position.PriceOpen() - position.PriceCurrent() > pos_sl - position.PriceOpen())
   {
      new_sl = position.PriceOpen();//
   }
//---
   sl=EMPTY_VALUE;
   tp=EMPTY_VALUE;
   if(new_sl<base && new_sl>level)
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
