//+------------------------------------------------------------------+
//|                                                   TrailingMA.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertTrailing.mqh>
#define ValueSize 4
class CTrailingBottomTop : public CExpertTrailing
  {
protected:
   CiCustom             *m_zigzag;
   //--- input parameters
   int               m_ExtDepth;
   int               m_ExtDeviation;
   int               m_ExtBackstep;
   int               last_insert_index;
   bool              IsLastHigh;
   double            value[ValueSize]; 
   

public:
                     CTrailingBottomTop(void);
                    ~CTrailingBottomTop(void);
   //--- methods of initialization of protected data
   void              ExtDepth(int ExtDepth)                  { m_ExtDepth=ExtDepth;   }
   void              ExtDeviation(int ExtDeviation)                    { m_ExtDeviation=ExtDeviation;     }
   void              ExtBackstep(int ExtBackstep)       { m_ExtBackstep=ExtBackstep;   }
   virtual void      UpdateValues();
   virtual bool      InitIndicators(CIndicators *indicators);
   virtual bool      ValidationSettings(void);
   //---
   virtual bool      CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp);
   virtual bool      CheckTrailingStopShort(CPositionInfo *position,double &sl,double &tp);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CTrailingBottomTop::CTrailingBottomTop(void) : m_ExtDepth(12),
                                      m_ExtDeviation(5),
                                      m_ExtBackstep(3),
                                      last_insert_index(-1),
                                      IsLastHigh(false)
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
bool CTrailingBottomTop::InitIndicators(CIndicators *indicators)
  {
//--- check
   if(indicators==NULL)
      return(false);

   if(m_zigzag==NULL)
      if((m_zigzag=new CiCustom)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }

   if(!indicators.Add(m_zigzag))
     {
      printf(__FUNCTION__+": error adding object");
      delete m_zigzag;
      return(false);
     }
     
   MqlParam CustomZigZag_prop[];
   ArrayResize(CustomZigZag_prop,4);
   
   CustomZigZag_prop[0].type=TYPE_STRING;
   CustomZigZag_prop[0].string_value="Examples\\ZigZag";
   
   CustomZigZag_prop[1].type=TYPE_INT;
   CustomZigZag_prop[1].integer_value=m_ExtDepth;
   
   CustomZigZag_prop[2].type=TYPE_INT;
   CustomZigZag_prop[2].integer_value=m_ExtDeviation;
   
   CustomZigZag_prop[3].type=TYPE_INT;
   CustomZigZag_prop[3].integer_value=m_ExtBackstep;

   printf("ExtDepth = %d, ExtDeviation = %d, ExtBackstep = %d, ind_custom = %d", m_ExtDepth, m_ExtDeviation, m_ExtBackstep, IND_CUSTOM);
   if(!m_zigzag.Create(m_symbol.Name(),m_period,IND_CUSTOM,4,CustomZigZag_prop))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   m_zigzag.NumBuffers(3);
//--- ok
   return(true);
  }
  
void CTrailingBottomTop::UpdateValues()
{
   double high = NormalizeDouble(m_zigzag.GetData(1, 0),m_symbol.Digits());
   double low = NormalizeDouble(m_zigzag.GetData(2, 0),m_symbol.Digits());
   int i, offset;
   printf("should be called by every hour");
   if(high > 0.0)
   {    
      if(last_insert_index == -1 || !IsLastHigh)
      {
         last_insert_index = (last_insert_index + 1) % ValueSize;
      }
      value[last_insert_index] = high;
      IsLastHigh = true;
      for(i = 1; i <= ValueSize; i++)
      {
         offset = (last_insert_index + i) % ValueSize;
         if(value[offset] > 0.0)
         {
            printf("value[%d] = %f", offset, value[offset]);
         }
      }
   }
   else if(low > 0.0)
   {
      if(last_insert_index == -1 || IsLastHigh)
      {
         last_insert_index = (last_insert_index + 1) % ValueSize;
      }
      value[last_insert_index] = high;
      IsLastHigh = false;
      for(i = 1; i <= ValueSize; i++)
      {
         offset = (last_insert_index + i) % ValueSize;
         if(value[offset] > 0.0)
         {
            printf("value[%d] = %f", offset, value[offset]);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Checking trailing stop and/or profit for long position.          |
//+------------------------------------------------------------------+
bool CTrailingBottomTop::CheckTrailingStopLong(CPositionInfo *position,double &sl,double &tp)
  {
//--- check
   if(position==NULL)
      return(false);
//---

   UpdateValues();
   double level =NormalizeDouble(m_symbol.Bid()-m_symbol.StopsLevel()*m_symbol.Point(),m_symbol.Digits());
   double new_sl=NormalizeDouble(m_zigzag.GetData(0, 0),m_symbol.Digits());
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
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
   double new_sl=NormalizeDouble(m_zigzag.GetData(0, 0)+m_symbol.Spread()*m_symbol.Point(),m_symbol.Digits());
   double pos_sl=position.StopLoss();
   double base  =(pos_sl==0.0) ? position.PriceOpen() : pos_sl;
//---
   sl=EMPTY_VALUE;
   tp=EMPTY_VALUE;
   if(new_sl<base && new_sl>level)
      sl=new_sl;
//---
   return(sl!=EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
