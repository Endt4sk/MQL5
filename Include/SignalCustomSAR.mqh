//+------------------------------------------------------------------+
//|                                                    SignalSAR.mqh |
//|                      Copyright © 2011, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//|                                              Revision 2011.03.30 |
//+------------------------------------------------------------------+
#property tester_indicator "Examples\\ParabolicSAR.ex5"
#include <Expert\ExpertSignal.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of custom indicator 'ParabolicSAR'                 |
//| Type=SignalAdvanced                                              |
//| Name=Parabolic SAR                                               |
//| ShortName=SAR                                                    |
//| Class=CSignalCustomSAR                                           |
//| Page=signal_sar                                                  |
//| Parameter=Step,double,0.02,Speed increment                       |
//| Parameter=Maximum,double,0.2,Maximum rate                        |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalCustomSAR.                                                |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Parabolic SAR' indicator.                          |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CSignalCustomSAR : public CExpertSignal
  {
protected:
   CiCustom          m_sar;            // object-indicator
   //--- adjusted parameters
   double            m_step;           // the "speed increment" parameter of the indicator
   double            m_maximum;        // the "maximum rate" parameter of the indicator
   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0 "the parabolic is on the necessary side from the price"
   int               m_pattern_1;      // model 1 "the parabolic has 'switched'"

public:
                     CSignalCustomSAR();
   //--- methods of setting adjustable parameters
   void              Step(double value)          { m_step=value;                 }
   void              Maximum(double value)       { m_maximum=value;              }
   //--- methods of adjusting "weights" of market models
   void              Pattern_0(int value)        { m_pattern_0=value;            }
   void              Pattern_1(int value)        { m_pattern_1=value;            }
   //--- method of verification of settings
   virtual bool      ValidationSettings();
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition();
   virtual int       ShortCondition();

protected:
   //--- method of initialization of the indicator
   bool              InitSAR(CIndicators *indicators);
   //--- methods of getting data
   double            SAR(int ind)                { return(m_sar.GetData(0,ind)); }
   double            Close(int ind)              { return(m_close.GetData(ind)); }
   double            DiffClose(int ind)          { return(Close(ind)-SAR(ind));  }
  };
//+------------------------------------------------------------------+
//| Constructor CSignalCustomSAR.                                          |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSignalCustomSAR::CSignalCustomSAR()
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_CLOSE;
//--- setting default values for the indicator parameters
   m_step   =0.02;
   m_maximum=0.2;
//--- setting default "weights" of the market models
   m_pattern_0=40;           // model 0 "the parabolic is on the necessary side from the price"
   m_pattern_1=90;           // model 1 "the parabolic has 'switched'"
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//| INPUT:  no.                                                      |
//| OUTPUT: true-if settings are correct, false otherwise.           |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCustomSAR::ValidationSettings()
  {
//--- call of the method of the parent class
   if(!CExpertSignal::ValidationSettings()) return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCustomSAR::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL) return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators)) return(false);
//--- create and initialize SAR indicator
   if(!InitSAR(indicators)) return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create SAR indicators.                                           |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCustomSAR::InitSAR(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL) return(false);
//--- add object to collection
   if(!indicators.Add(GetPointer(m_sar)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- prepare indicator parameters
   MqlParam CustomSAR_prop[];
   ArrayResize(CustomSAR_prop,4);
//--- indicator file
   CustomSAR_prop[0].type=TYPE_STRING;
   CustomSAR_prop[0].string_value="Examples\\ParabolicSAR";
//--- SAR step
   CustomSAR_prop[1].type=TYPE_DOUBLE;
   CustomSAR_prop[1].double_value=m_step;
//--- SAR maximum
   CustomSAR_prop[2].type=TYPE_DOUBLE;
   CustomSAR_prop[2].double_value=m_maximum;
//--- applied price
   CustomSAR_prop[3].type=TYPE_INT;
   CustomSAR_prop[3].integer_value=PRICE_CLOSE;
//--- initialize object
   if(!m_sar.Create(m_symbol.Name(),m_period,IND_CUSTOM,4,CustomSAR_prop))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   m_sar.NumBuffers(1);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//| INPUT:  no.                                                      |
//| OUTPUT: number of "votes" that price will grow.                  |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CSignalCustomSAR::LongCondition()
  {
   int result=0;
   int idx   =StartIndex();
//--- if the indicator is above the price at the first analyzed bar, don't 'vote' buying
   if(DiffClose(idx++)<0.0) return(result);
//--- the indicator is below the price at the first analyzed bar (the indicator has no objections to buying)
   if(IS_PATTERN_USAGE(0))
      result=m_pattern_0;
//--- if the indicator is above the price at the second analyzed bar, then there is a condition for buying
   if(IS_PATTERN_USAGE(1) && DiffClose(idx)<0.0)
      return(m_pattern_1);
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//| INPUT:  no.                                                      |
//| OUTPUT: number of "votes" that price will fall.                  |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CSignalCustomSAR::ShortCondition()
  {
   int result=0;
   int idx   =StartIndex();
//--- if the indicator is below the price at the first analyzed bar, don't "vote" for selling
   if(DiffClose(idx++)>0.0) return(result);
//--- the indicator is above the price at the first analyzed bar (the indicator has no objections to selling)
   if(IS_PATTERN_USAGE(0))
      result=m_pattern_0;
//--- if the indicator is below the price at the second analyzed bar, then there is a condition for selling
   if(IS_PATTERN_USAGE(1) && DiffClose(idx)>0.0)
      return(m_pattern_1);
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
