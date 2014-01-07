//+------------------------------------------------------------------+
//|                                                     SignalMA.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <Expert\ExpertChuck.mqh>

class CSignalChuck : public CExpertSignal
  {
protected:
   CShareInfo             *CShare;
   CiBands              m_bands;             // object-indicator
   //--- adjusted parameters
   int               m_ma_period;      // the "period of averaging" parameter of the indicator
   int               m_ma_shift;       // the "time shift" parameter of the indicator
   double    m_deviation;      // the "method of averaging" parameter of the indicator
   ENUM_APPLIED_PRICE m_ma_applied;    // the "object of averaging" parameter of the indicator


public:
                     CSignalChuck(void);
                    ~CSignalChuck(void);
   //--- methods of setting adjustable parameters
   void              PeriodMA(int value)                 { m_ma_period=value;          }
   void              Shift(int value)                    { m_ma_shift=value;           }
   void              Deviation(double value)        { m_deviation=value;          }
   void              Applied(ENUM_APPLIED_PRICE value)   { m_ma_applied=value;         }
   void SetCShare(CShareInfo *value){CShare = value;printf("cshare = %f", CShare.last_insert_index);}
   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);

protected:
   //--- method of initialization of the indicator
   bool              InitMBands(CIndicators *indicators);
   //--- methods of getting data
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalChuck::CSignalChuck(void) : m_ma_period(13),
                             m_ma_shift(0),
                             m_deviation(1.618),
                             m_ma_applied(PRICE_CLOSE)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalChuck::~CSignalChuck(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalChuck::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks
   if(m_ma_period<=0)
     {
      printf(__FUNCTION__+": period MA must be greater than 0");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalChuck::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize MA indicator
   if(!InitMBands(indicators))
      return(false);
//--- ok
   return(true);
  }

bool CSignalChuck::InitMBands(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add object to collection
   if(!indicators.Add(GetPointer(m_bands)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_bands.Create(m_symbol.Name(),m_period,m_ma_period,m_ma_shift,m_deviation,m_ma_applied))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalChuck::LongCondition(void)
  {
   int result=0;
   MqlDateTime tm;
   TimeCurrent(tm);
   m_base_price=0.0;
   if(tm.min != 0)
   {
      return(0);
   }
   printf("m_stop_level = %f", m_stop_level);
   
   if(!CShare.IsLastHigh)//bottom buy
   {
      printf("close[1] = %f, open[1] = %f, m_bands.lower = %f", Close(1), Open(1), m_bands.Lower(1));
      printf("index[0] = %f, index[2] = %f", CShare.zigzag_value[CShare.index(0)], CShare.zigzag_value[CShare.index(2)]);
      if(CShare.zigzag_value[CShare.index(0)] > CShare.zigzag_value[CShare.index(2)])
      {
         if(Close(1) > Open(1))
         {
            printf("point = %f", Point());
            printf("close[1] - lower(1) = %f", Close(1) - m_bands.Lower(1));
            if(Close(1) > m_bands.Lower(1) && Close(1) - m_bands.Lower(1) < 10 * CShare.RPoint)
            {
               printf("return 80");
               return (80);
            }
         }
      }
   }
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalChuck::ShortCondition(void)
  {
   int result=0;
  m_base_price=0.0;
   return(result);
  }
//+------------------------------------------------------------------+
