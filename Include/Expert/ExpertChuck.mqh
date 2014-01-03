//+------------------------------------------------------------------+
//|                                                  ExpertChuck.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <Expert\Expert.mqh>
#define ValueSize 4

class CShareInfo : public CObject
{
   public:
   int zigzag_handle, last_insert_index;
   bool IsLastHigh;
   double zigzag_high[], zigzag_low[], zigzag[], zigzag_value[ValueSize];
   
   public:
      int index(int i){return ((last_insert_index - i + ValueSize) % ValueSize);}
};

class CExpertChuck : public CExpert
{
   public:  CShareInfo CShare;
   public:
            bool  Init(string symbol,ENUM_TIMEFRAMES period,bool every_tick,ulong magic=0);
};

bool CExpertChuck::Init(string symbol,ENUM_TIMEFRAMES period,bool every_tick,ulong magic)
{
   CShare.last_insert_index = -1;
   return(CExpert::Init(symbol,period,every_tick,magic));
}