//+------------------------------------------------------------------+
//|                                             UltimateTraderV1.mq4 |
//|                                    Copyright © 2010, D P Bennett |
//|                                      http://www.dpbennett.com.jm |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, D P Bennett"
#property link      "http://www.dpbennett.com.jm"

// Constants
// pivot level constants
#define POS_LONG 1
#define POS_NONE 0
#define POS_SHORT -1 
#define UP_TREND 1
#define DOWN_TREND -1
#define NO_TREND 0 
#define BB_UL_TESTED 1
#define BB_UL_BROKEN 2
#define BB_LL_TESTED 3
#define BB_LL_BROKEN 4
#define BB_NEUTRAL 0
#define RES_TEST 1
#define SUP_TEST 2
#define PERIODS 160 // the number of periods to check for resistance and support
#define UPPER_SHADOW 1
#define LOWER_SHADOW 2
#define REAL_BODY 3
#define STOCH_OVERBOUGHT 1
#define STOCH_NEUTRAL 0
#define STOCH_OVERSOLD -1
#define OVERBOUGHT 1
#define OVERSOLD 2
#define NEUTRAL 0
#define UNKNOWN -1
// candle type
#define UNDEFINED 0
#define BEAR_CAND 1
#define BULL_CAND 2
#define DOJI_CAND 3
#define BULL_HAMMER_CAND 4
#define BEAR_HAMMER_CAND 5
#define BULL_INV_HAMMER_CAND 6
#define BEAR_INV_HAMMER_CAND 7
#define BULL_SPIN_CAND 8
#define BEAR_SPIN_CAND 9
#define BULL_SHOOT_CAND 10
#define BEAR_SHOOT_CAND 11
// candle pattern
#define BEAR_ENGULF 1
#define BULL_ENGULF 2
#define HARAMI 3
// External variables
extern int MagicNumber = 19700623;
extern double AccountBalanceLimit = 85.00;
extern double FixedLots  = 0.01;
extern bool UseMaximumRisk = true;
extern double MaximumPercentageRisk = 5.0;  
extern bool AutoTrade = true;
extern bool ShowLevels = false; // show resistance/support levels?
extern bool UseTestedLevels = false; // check res/sup levels before entering a trade
extern double PipToleranceForStopLoss = 10.0; // use value that is based on the spread
extern double ProfitFactor = 3.0;
extern bool TradeAutoManagement = true;
extern bool EmailAlert = true;
extern bool AlarmOn = true;
extern bool AlarmHourly = true;
extern int AlarmMinutes = 55;
extern int AlarmCount = 2;
extern string AlarmSound = "alert.wav";
////////////////////////////
int alarmCounter;
string lastOrderNumber = "";
string candleType[12] = { "UNDEFINED", "BEAR", "BULL", "DOJI", "BULL HAMMER", "BEAR HAMMER", "BULL INVERTED HAMMER", "BEAR INVERTED HAMMER",
                          "BULL SPINNING TOP", "BEAR SPINNING TOP", "BULL SHOOTING STAR", "BEAR SHOOTING STAR"};
string candlePattern[4] = { "UNDEFINED", "BEARISH ENGULFING", "BULLISH ENGULFING", "HARAMI" };
double level[PERIODS];
double testedLevel[PERIODS];
double stopLoss;
double takeProfit;
double lots;
int orderType;
double orderPrice;
int orderTicket = -1;
datetime orderDate = NULL;
bool messageSent = false;
int marketHighRegionBarIndex[PERIODS];
int marketLowRegionBarIndex[PERIODS];
int marketHighBarIndex[PERIODS];
int marketLowBarIndex[PERIODS];
int upTrendLineBarIndex[PERIODS];
int downTrendLineBarIndex[PERIODS];
////////////////////////////
string trendDirectionComment;
string trendAnalysisComment;
string riskAnalysisComment = "";
string techAnalysisComment = "";
string levelsTestedComment = "";
string stochasticComment = "";
string bollingerBandsComment = "";
//string patternLevelTestComment = "";
//string positionBiasComment;
////////////////////////////
double pips;
double risk;
double maximumRisk;
double pivotLevel[7];
////////////////////////////

int init() {
   // load and read file here
   return(0);                                      
}  

// check if a candlestick has tested a resistance or support level
bool hasCandleBrokenLevel(int barIndex, double level, int testType) {
  // test resistance level
  if ( testType == RES_TEST ) {
    if ( (getCandleType(barIndex) == BULL_CAND) || 
         (getCandleType(barIndex) == BULL_HAMMER_CAND) ||
         (getCandleType(barIndex) == BULL_INV_HAMMER_CAND) ||
         (getCandleType(barIndex) == BULL_SPIN_CAND) ||
         (getCandleType(barIndex) == BULL_SHOOT_CAND) ||
         (getCandleType(barIndex) == DOJI_CAND) ) {  
      if ( Close[barIndex] > level ) {
         return (true);
      } 
    }
    if ( (getCandleType(barIndex) == BEAR_CAND) || 
         (getCandleType(barIndex) == BEAR_HAMMER_CAND) ||
         (getCandleType(barIndex) == BEAR_INV_HAMMER_CAND) ||
         (getCandleType(barIndex) == BEAR_SPIN_CAND) ||
         (getCandleType(barIndex) == BEAR_SHOOT_CAND) ) {   
      if ( Open[barIndex] > level ) {
         return (true);
      } 
    }   
  }  
  // test support level
  if ( testType == SUP_TEST ) {
    if ( (getCandleType(barIndex) == BULL_CAND) || 
         (getCandleType(barIndex) == BULL_HAMMER_CAND) ||
         (getCandleType(barIndex) == BULL_INV_HAMMER_CAND) ||
         (getCandleType(barIndex) == BULL_SPIN_CAND) ||
         (getCandleType(barIndex) == BULL_SHOOT_CAND) ||
         (getCandleType(barIndex) == DOJI_CAND) ) {
      if ( Open[barIndex] < level ) {
         return (true);
      } 
    }
    if ( (getCandleType(barIndex) == BEAR_CAND) || 
         (getCandleType(barIndex) == BEAR_HAMMER_CAND) ||
         (getCandleType(barIndex) == BEAR_INV_HAMMER_CAND) ||
         (getCandleType(barIndex) == BEAR_SPIN_CAND) ||
         (getCandleType(barIndex) == BEAR_SHOOT_CAND) ) {   
      if ( Close[barIndex] < level ) {
         return (true);
      } 
    }         
  }

  return (false);
}

// check if a candlestick has tested a resistance or support level
bool hasCandleTestedLevel(int barIndex, double level, int testType) {
  if ( testType == RES_TEST ) {
    if ( (getCandleType(barIndex) == BULL_CAND) || 
         (getCandleType(barIndex) == BULL_HAMMER_CAND) ||
         (getCandleType(barIndex) == BULL_INV_HAMMER_CAND) ||
         (getCandleType(barIndex) == BULL_SPIN_CAND) ||
         (getCandleType(barIndex) == BULL_SHOOT_CAND) ||
         (getCandleType(barIndex) == DOJI_CAND) ) {
      if ( (High[barIndex] >= level) && (Close[barIndex] <= level) ) {
         return (true);
      }
    }  
    if ( (getCandleType(barIndex) == BEAR_CAND) || 
         (getCandleType(barIndex) == BEAR_HAMMER_CAND) ||
         (getCandleType(barIndex) == BEAR_INV_HAMMER_CAND) ||
         (getCandleType(barIndex) == BEAR_SPIN_CAND) ||
         (getCandleType(barIndex) == BEAR_SHOOT_CAND) ) {
      if ( (High[barIndex] >= level) && (Open[barIndex] <= level) ) {
         return (true);
      }
    }  
  }
  
  if ( testType == SUP_TEST ) {
    if ( (getCandleType(barIndex) == BEAR_CAND) || 
         (getCandleType(barIndex) == BEAR_HAMMER_CAND) ||
         (getCandleType(barIndex) == BEAR_INV_HAMMER_CAND) ||
         (getCandleType(barIndex) == BEAR_SPIN_CAND) ||
         (getCandleType(barIndex) == BEAR_SHOOT_CAND) ) {
      if ( (Low[barIndex] <= level) && (Close[barIndex] >= level) ) {
         return (true);
      }
    }
    if ( (getCandleType(barIndex) == BULL_CAND) || 
         (getCandleType(barIndex) == BULL_HAMMER_CAND) ||
         (getCandleType(barIndex) == BULL_INV_HAMMER_CAND) ||
         (getCandleType(barIndex) == BULL_SPIN_CAND) ||
         (getCandleType(barIndex) == BULL_SHOOT_CAND) ||
         (getCandleType(barIndex) == DOJI_CAND) ) {
      if ( (Low[barIndex] <= level) && (Open[barIndex] >= level) ) {
         return (true);
      }
    }
  }
    
  return (false);
}

// get the state of the bollinger bands given the range of bars
int getBollingerBandsState(int firstBarIndex, int lastBarIndex) {
   int state[1];
   int index = 0;
   int newSize = ArrayResize(state, (lastBarIndex - firstBarIndex + 1)); 
   
   bollingerBandsComment = "Bollinger Bands: ";
   
   for (int i = firstBarIndex; i < (lastBarIndex + 1); i++) {
      // test the upper band
      if ( hasCandleTestedLevel(i, iBands(NULL,0,20,2,0,PRICE_TYPICAL,MODE_UPPER,i), RES_TEST) ){
         state[index] = BB_UL_TESTED; 
         bollingerBandsComment = bollingerBandsComment + "Bar " + i + " UT; ";
         index++;
      }
      else if ( hasCandleBrokenLevel(i, iBands(NULL,0,20,2,0,PRICE_TYPICAL,MODE_UPPER,i), RES_TEST) ){
         state[index] = BB_UL_BROKEN; 
         bollingerBandsComment = bollingerBandsComment + "Bar " + i + " UB; ";
         index++;
      }
      // test the lower band
      else if ( hasCandleTestedLevel(i, iBands(NULL,0,20,2,0,PRICE_TYPICAL,MODE_LOWER,i), SUP_TEST) ){
         state[index] = BB_LL_TESTED; 
         bollingerBandsComment = bollingerBandsComment + "Bar " + i + " LT; ";
         index++;
      }
      else if ( hasCandleBrokenLevel(i, iBands(NULL,0,20,2,0,PRICE_TYPICAL,MODE_LOWER,i), SUP_TEST) ){
         state[index] = BB_LL_BROKEN; 
         bollingerBandsComment = bollingerBandsComment + "Bar " + i + " LB; ";
         index++;
      }
      else {
         state[index] = BB_NEUTRAL; 
         bollingerBandsComment = bollingerBandsComment + "Bar " + i + " N; ";
         index++;
      }
     
   }   
   
   // return the state of the first bar that is not neutral
   for (i = 0; i < newSize; i++) {
      if (state[i] != BB_NEUTRAL) {
         bollingerBandsComment = bollingerBandsComment + "TESTED/BROKEN";
         return (state[i]);
      }    
   }
   
   bollingerBandsComment = bollingerBandsComment + "NEUTRAL";
   return (BB_NEUTRAL); 
}

int getCandleType(int barIndex = 1) {
   int type = UNDEFINED;

   // doji cand.
   if (Close[barIndex] == Open[barIndex]) {
      type = DOJI_CAND;
   }
   // bull cand.
   if (Close[barIndex] > Open[barIndex]) {
      if ( (getBarDimension(barIndex, REAL_BODY) > getBarDimension(barIndex, UPPER_SHADOW)) && 
           (getBarDimension(barIndex, REAL_BODY) > getBarDimension(barIndex, LOWER_SHADOW)) ) {
         type = BULL_CAND;
      }   
   }    
   // bear cand.
   if (Close[barIndex] < Open[barIndex]) {
      if ( (getBarDimension(barIndex, REAL_BODY) > getBarDimension(barIndex, UPPER_SHADOW)) && 
           (getBarDimension(barIndex, REAL_BODY) > getBarDimension(barIndex, LOWER_SHADOW)) ) {
         type = BEAR_CAND;
      }   
   }   
   // bull spinning top cand.
   if (Close[barIndex] > Open[barIndex]) {
      if ( (getBarDimension(barIndex, REAL_BODY) <= getBarDimension(barIndex, UPPER_SHADOW)) || 
           (getBarDimension(barIndex, REAL_BODY) <= getBarDimension(barIndex, LOWER_SHADOW)) ) {
         type = BULL_SPIN_CAND;
      }   
   } 
   // bear spinning top cand.
   if (Close[barIndex] < Open[barIndex]) {
      if ( (getBarDimension(barIndex, REAL_BODY) <= getBarDimension(barIndex, UPPER_SHADOW)) || 
           (getBarDimension(barIndex, REAL_BODY) <= getBarDimension(barIndex, LOWER_SHADOW)) ) {
         type = BEAR_SPIN_CAND;
      }   
   }   
   // bull shooting star cand.
   if (Close[barIndex] > Open[barIndex]) {
      if ( (getBarDimension(barIndex, REAL_BODY) <= getBarDimension(barIndex, UPPER_SHADOW)) && 
           (getBarDimension(barIndex, REAL_BODY) > getBarDimension(barIndex, LOWER_SHADOW)) && 
           (getBarDimension(barIndex, UPPER_SHADOW) > getBarDimension(barIndex, LOWER_SHADOW)) ) {
         type = BULL_SHOOT_CAND;
      }   
   } 
   // bear shooting star cand.
   if (Close[barIndex] < Open[barIndex]) {
      if ( (getBarDimension(barIndex, REAL_BODY) <= getBarDimension(barIndex, UPPER_SHADOW)) && 
           (getBarDimension(barIndex, REAL_BODY) > getBarDimension(barIndex, LOWER_SHADOW)) && 
           (getBarDimension(barIndex, UPPER_SHADOW) > getBarDimension(barIndex, LOWER_SHADOW)) ) {
         type = BEAR_SHOOT_CAND;
      }   
   }   
   // bull hammer cand.
   if ( Close[barIndex] > Open[barIndex] ) {
      if ( (2*getBarDimension(barIndex, UPPER_SHADOW) < getBarDimension(barIndex, LOWER_SHADOW)) && 
           (2*getBarDimension(barIndex, REAL_BODY) < getBarDimension(barIndex, LOWER_SHADOW)) ) {
         type = BULL_HAMMER_CAND;
      }   
   }   
   // bear hammer cand.
   if ( Close[barIndex] < Open[barIndex] ) {
      if ( (2*getBarDimension(barIndex, UPPER_SHADOW) < getBarDimension(barIndex, LOWER_SHADOW)) && 
           (2*getBarDimension(barIndex, REAL_BODY) < getBarDimension(barIndex, LOWER_SHADOW)) ) {
         type = BEAR_HAMMER_CAND;
      }   
   }
   // bull inverted hammer cand.
   if ( Close[barIndex] > Open[barIndex] ) {
      if ( (2*getBarDimension(barIndex, LOWER_SHADOW) < getBarDimension(barIndex, UPPER_SHADOW)) && 
           (2*getBarDimension(barIndex, REAL_BODY) < getBarDimension(barIndex, UPPER_SHADOW)) ) {
         type = BULL_INV_HAMMER_CAND;
      }   
   }  
   // bear inverted hammer cand.
   if ( Close[barIndex] < Open[barIndex] ) {
      if ( (2*getBarDimension(barIndex, LOWER_SHADOW) < getBarDimension(barIndex, UPPER_SHADOW)) && 
           (2*getBarDimension(barIndex, REAL_BODY) < getBarDimension(barIndex, UPPER_SHADOW)) ) {
         type = BEAR_INV_HAMMER_CAND;
      }   
   }    
   
   return (type);   
}

int getCandlePattern(int barIndex = 1) {
   // check for bullish engulfing pattern
   if ( (getCandleType(barIndex) == BULL_CAND) && 
        ((getCandleType(barIndex + 1) == BEAR_CAND) || 
         (getCandleType(barIndex + 1) == DOJI_CAND) || 
         (getCandleType(barIndex + 1) == BEAR_HAMMER_CAND) ||
         (getCandleType(barIndex + 1) == BEAR_INV_HAMMER_CAND) ||
         (getCandleType(barIndex + 1) == BEAR_SPIN_CAND) ||
         (getCandleType(barIndex + 1) == BEAR_SHOOT_CAND)) ) {
      if (Close[barIndex] > Open[barIndex + 1]) {
         return (BULL_ENGULF);
      }   
   }
   
   // check for bearish engulfing pattern
   if ( (getCandleType(barIndex) == BEAR_CAND) && 
        ((getCandleType(barIndex + 1) == BULL_CAND) || 
         (getCandleType(barIndex + 1) == DOJI_CAND) || 
         (getCandleType(barIndex + 1) == BULL_HAMMER_CAND) ||
         (getCandleType(barIndex + 1) == BULL_INV_HAMMER_CAND) ||
         (getCandleType(barIndex + 1) == BULL_SPIN_CAND) ||
         (getCandleType(barIndex + 1) == BULL_SHOOT_CAND)) ) {
      if (Close[barIndex] < Open[barIndex + 1]) {
         return (BEAR_ENGULF);
      }   
   }
   
   // inner bar
   if ( (High[barIndex] < High[barIndex + 1]) && (Low[barIndex] > Low[barIndex + 1]) ) {
         return (HARAMI);
   }      
  
   return (UNDEFINED);
      
}

void soundAlarmIfDue() {
   
   if (AlarmOn) {
      if (AlarmHourly) {
      
         // reset counter if minute has passed
         if ( (TimeMinute(TimeLocal()) != AlarmMinutes) ) {
            alarmCounter = 0;
            return;
         }
   
         // alarm if minutes reached and counter less than AlarmCount
         if ( (TimeMinute(TimeLocal()) == AlarmMinutes) && (alarmCounter < AlarmCount)) {
               PlaySound(AlarmSound);
               Print(Symbol() + " Hourly alarm sounded!");
               alarmCounter++;       
         }   
         
       }  
    }  
}

// Determine the direction of the current trend using the immediate pass 3 iMAs
int getTrendDirection(int timeFrame, int periods) {
   
   double firstPreviousAverage = NormalizeDouble(iMA(NULL, timeFrame, periods, 0, MODE_SMA, PRICE_CLOSE, 1), Digits);
   double secondPreviousAverage = NormalizeDouble(iMA(NULL, timeFrame, periods, 0, MODE_SMA, PRICE_CLOSE, 2), Digits);
   double thirdPreviousAverage = NormalizeDouble(iMA(NULL, timeFrame, periods, 0, MODE_SMA, PRICE_CLOSE, 3), Digits);
        
   // is up trend?
   if ( (firstPreviousAverage > secondPreviousAverage) &&
        (secondPreviousAverage > thirdPreviousAverage)) {
        trendDirectionComment = "" + getTimeFrameDescription(timeFrame) + "; UP"; 
        return( UP_TREND );  
   }
   
   // is down trend?                            
   if ( (firstPreviousAverage < secondPreviousAverage) &&
        (secondPreviousAverage < thirdPreviousAverage)) {
        trendDirectionComment = "" + getTimeFrameDescription(timeFrame) + "; DOWN"; 
        return(DOWN_TREND);    
   }    
   
   // no trend  
   trendDirectionComment = "" + getTimeFrameDescription(timeFrame) + "; NONE"; 
   return(NO_TREND);     
}

// get the state of the stochastic for the given range of bars
int getStochasticState(int timeframe = 0, int firstBarIndex = 1, int lastBarIndex = 3) {
   int state[1];
   int index = 0;
   int newSize = ArrayResize(state, (lastBarIndex - firstBarIndex + 1)); 
   
   stochasticComment = "Stochastic: ";
   
   for (int i = firstBarIndex; i < (lastBarIndex + 1); i++) {
      if (  (iStochastic(NULL,timeframe,14,3,3,MODE_SMA,1,MODE_MAIN,i) <= 20.0) && (iStochastic(NULL,timeframe,14,3,3,MODE_SMA,1,MODE_SIGNAL,i) <= 20.0) ) {
         state[index] = STOCH_OVERSOLD; 
         stochasticComment = stochasticComment + "Bar " + i + " OS; ";
         index++;
      }
      else if (  (iStochastic(NULL,timeframe,14,3,3,MODE_SMA,1,MODE_MAIN,i) >= 80.0) && (iStochastic(NULL,timeframe,14,3,3,MODE_SMA,1,MODE_SIGNAL,i) >= 80.0) ) {
         state[index] = STOCH_OVERBOUGHT; 
         stochasticComment = stochasticComment + "Bar " + i + " OB; ";
         index++;
      }
      else {
         state[index] = STOCH_NEUTRAL; 
         stochasticComment = stochasticComment + "Bar " + i + " N; ";
         index++;
      }
      
   }   
   
   // return the state of the first bar that is not neutral
   for (i = 0; i < newSize; i++) {
      if (state[i] == STOCH_OVERBOUGHT) {
         stochasticComment = stochasticComment + "OVERBOUGHT";
         return (state[i]);
      }
      if (state[i] == STOCH_OVERSOLD) {
         stochasticComment = stochasticComment + "OVERSOLD";
         return (state[i]);
      }
   }
   
   stochasticComment = stochasticComment + "NEUTRAL";
   return (STOCH_NEUTRAL); 
}

void deleteMarketHighsOrLows (int type) {
   // delete existing regions
   for (int i = 1; i < PERIODS; i++) {
      //regionBarIndex[PERIODS] = -1;
      if (type == STOCH_OVERBOUGHT) {
         marketHighRegionBarIndex[i] = -1;
         marketHighBarIndex[i] = -1;
         ObjectDelete("stoch:" + i + "type:" + STOCH_OVERBOUGHT);
      }   
      if (type == STOCH_OVERSOLD)   {
         marketLowRegionBarIndex[i] = -1;
         marketLowBarIndex[i] = -1;
         ObjectDelete("stoch:" + i + "type:" + STOCH_OVERSOLD);
      }   
   }
}

// identify OS/OB regions
void getMarketHighsOrLows (int type) {
   int barIndex = 0;
   int arrowIndex = 0;
   bool found = false;
   
   deleteMarketHighsOrLows(type);
   
   for (int i = 1; i < PERIODS; i++) {
      if (getStochasticState(0, i, i) == type ){
          if ( !found ) {
               found = true; 
               if (type == STOCH_OVERBOUGHT) {
                  marketHighRegionBarIndex[barIndex] = i;                  
               }   
               if (type == STOCH_OVERSOLD)   {
                  marketLowRegionBarIndex[barIndex] = i;                  
               }                     
               barIndex++;               
          }  
      }
      else {
         if ( found ) {
            found = false;
            if (type == STOCH_OVERBOUGHT) {
                marketHighRegionBarIndex[barIndex] = i - 1;                  
            }   
            if (type == STOCH_OVERSOLD)   {
                marketLowRegionBarIndex[barIndex] = i - 1;                  
            }     
            // let arrow point to the lowest/highest point
            if (type == STOCH_OVERBOUGHT) {
               // show high point
               marketHighBarIndex[arrowIndex] = iHighest(Symbol(), Period(), MODE_HIGH, marketHighRegionBarIndex[barIndex] - marketHighRegionBarIndex[barIndex - 1] + 1, marketHighRegionBarIndex[barIndex - 1]);                  
               arrowIndex++;
            }
            if (type == STOCH_OVERSOLD) {
               marketLowBarIndex[arrowIndex] = iLowest(Symbol(), Period(), MODE_LOW, marketLowRegionBarIndex[barIndex] - marketLowRegionBarIndex[barIndex - 1] + 1, marketLowRegionBarIndex[barIndex - 1]);
               arrowIndex++;
            }
            barIndex++;
         }      
        
      }
   }   
}

void showMarketHighsOrLows(int type) {
   
   for (int i = 0; i < PERIODS; i++) {
      if (type == STOCH_OVERBOUGHT) {
         if (marketHighBarIndex[i] != -1) {
           ObjectCreate("stoch:" + marketHighBarIndex[i] + "type:" + type, OBJ_ARROW, 0, Time[marketHighBarIndex[i]], High[marketHighBarIndex[i]] + 15 * Point);
           ObjectSet("stoch:" + marketHighBarIndex[i] + "type:" + type, OBJPROP_COLOR, Yellow);
           ObjectSet("stoch:"  + marketHighBarIndex[i] + "type:" + type, OBJPROP_ARROWCODE, SYMBOL_ARROWUP);                           
         }  
      }   
      if (type == STOCH_OVERSOLD)   {
         if (marketLowBarIndex[i] != -1) {
           ObjectCreate("stoch:" + marketLowBarIndex[i] + "type:" + type, OBJ_ARROW, 0, Time[marketLowBarIndex[i]], Low[marketLowBarIndex[i]] - 5 * Point);
           ObjectSet("stoch:" + marketLowBarIndex[i] + "type:" + type, OBJPROP_COLOR, Red);
           ObjectSet("stoch:"  + marketLowBarIndex[i] + "type:" + type, OBJPROP_ARROWCODE, SYMBOL_ARROWDOWN);                              
         }  
      }     
   }   
}


void deleteTrendLine(int trendLineNumber, int type) {
   
   if (type == UP_TREND) {     
         ObjectDelete("trendline:" + trendLineNumber + "up"); 
   }      
     
   if (type == DOWN_TREND) {
         ObjectDelete("trendline:" + trendLineNumber + "down");           
   }      
}

void displayTrendLine(int trendLineNumber, int type) {
   int trendLineMaxIndex;
   
   trendLineMaxIndex = trendLineNumber * 2; 
   
   if (type == UP_TREND) {
      ObjectCreate("trendline:" + trendLineNumber + "up", OBJ_TREND, 0, 
                     Time[upTrendLineBarIndex[trendLineMaxIndex - 2]], Low[upTrendLineBarIndex[trendLineMaxIndex - 2]], 
                     Time[upTrendLineBarIndex[trendLineMaxIndex - 1]], Low[upTrendLineBarIndex[trendLineMaxIndex - 1]]);
      ObjectSet("trendline:" + trendLineNumber + "up", OBJPROP_COLOR, Red);
      ObjectSet("trendline:" + trendLineNumber + "up", OBJPROP_STYLE, STYLE_DOT);    
   }
   
   if (type == DOWN_TREND) {
      ObjectCreate("trendline:" + trendLineNumber + "down", OBJ_TREND, 0, 
                     Time[downTrendLineBarIndex[trendLineMaxIndex - 2]], High[downTrendLineBarIndex[trendLineMaxIndex - 2]], 
                     Time[downTrendLineBarIndex[trendLineMaxIndex - 1]], High[downTrendLineBarIndex[trendLineMaxIndex - 1]]);
      ObjectSet("trendline:" + trendLineNumber + "down", OBJPROP_COLOR, Yellow);
      ObjectSet("trendline:" + trendLineNumber + "down", OBJPROP_STYLE, STYLE_DOT);    
   }
   
   
}

bool getTrendLine(int trendLineNumber, int type) {
   int trendLineMaxIndex;
   bool found = false;
    
   deleteTrendLine(trendLineNumber, type);                
      
   // find up trend lines
   if (type == UP_TREND) {
     // deal with up trends
     for (int i = 0; i < PERIODS; i++) { 
         if ((marketLowBarIndex[i] != -1) && ((i + 1) == trendLineNumber) ) {       
            // find the next high point and draw trend line 1
            for (int j = (i + 1); j < PERIODS; j++) {
              if (marketLowBarIndex[j] != -1) {
                if (Low[marketLowBarIndex[j]] < Low[marketLowBarIndex[i]] ) {
                   // store trend line
                   found = true;
                   trendLineMaxIndex = trendLineNumber * 2; 
                   upTrendLineBarIndex[trendLineMaxIndex - 2] = marketLowBarIndex[j];
                   upTrendLineBarIndex[trendLineMaxIndex - 1] = marketLowBarIndex[i];
                   displayTrendLine(trendLineNumber, type);
                   break;     
                }  
                else {
                   continue;
                }                  
              }
              else {
                continue;
              }
             
            }          
            break;           
         }
     }
     
   }
   
   // find down trend lines
   if (type == DOWN_TREND) {      
     // deal with down trends 
     for (i = 0; i < PERIODS; i++) { 
         if ((marketHighBarIndex[i] != -1) && ((i + 1) == trendLineNumber) ) {       
            // find the next high point and draw trend line 1
            for (j = (i + 1); j < PERIODS; j++) {
              if (marketHighBarIndex[j] != -1) {
                if (High[marketHighBarIndex[j]] > High[marketHighBarIndex[i]] ) {
                   // store trend line
                   found = true; 
                   trendLineMaxIndex = trendLineNumber * 2; 
                   downTrendLineBarIndex[trendLineMaxIndex - 2] = marketHighBarIndex[j];
                   downTrendLineBarIndex[trendLineMaxIndex - 1] = marketHighBarIndex[i];
                   displayTrendLine(trendLineNumber, type);
                   break;     
                }  
                else {
                   continue;
                }                  
              }
              else {
                continue;
              }
             
            }          
            break;           
         }
     }  
     
   }   
   
   return (found);     
  
}

string getTimeFrameDescription (int timeFrame) {
   switch (timeFrame) {
      case PERIOD_M1:
         return ("1 Minute");
      case PERIOD_M5:
         return ("5 Minutes");
      case PERIOD_M15:
         return ("15 Minutes");
      case PERIOD_M30:
         return ("30 Minutes");
      case PERIOD_H1:
         return ("1 Hour");             
      case PERIOD_H4:
         return ("4 Hours");
      case PERIOD_D1:
         return ("Daily");
      case PERIOD_W1:
         return ("Weekly");
      case PERIOD_MN1:
         return ("Monthly");
      default:
         return ("Current");                  
   }
   
   return ("");
}

double getBarDimension(int bar, int section) {
   switch(section) {
      case UPPER_SHADOW:
         if (Close[bar] > Open[bar]) {
            return (High[bar] - Close[bar]);
         }  
         else if (Close[bar] < Open[bar]) {
            return (High[bar] - Open[bar]);
         } 
         else { // doji
            return (High[bar] - Close[bar]); 
         } 
         break;
      case LOWER_SHADOW:
         if (Close[bar] > Open[bar]) {
            return (Open[bar] - Low[bar]);
         }  
         else if (Close[bar] < Open[bar]) {
            return (Close[bar] - Low[bar]);
         } 
         else { // doji
            return (Open[bar] - Low[bar]);
         } 
         break;
      case REAL_BODY:
         return (MathAbs(Close[bar] - Open[bar])); 
         break;      
   }
   
   return (0.0);
} 


void displayComment(string customComment) {
   string comment;
   
   comment = "\nUltimateTrader v1.0.0, Copyright © 2010, D P Bennett\n";
   comment =  comment + "\nTECHNICAL ANALYSIS\n" + 
                     techAnalysisComment +                     
                     "\nRISK ANALYSIS\n" + 
                     riskAnalysisComment + 
                     "\nTRADE ANALYSIS\n" +                  
                     customComment + "\n";
   Comment(comment);          
}

// get the resistance and support levels
// withing the given pip range
void getLevels() {
   int bars;
   
   deleteLevelLines();
   
   // make sure the actual bars in the chart is sufficient for our needs 
   if (Bars < PERIODS) {
      bars = Bars;
   }
   else {
      bars = PERIODS;
   }

   for (int i = 0; i < bars; i++) {
      level[i] = 0.0;
     
      // get resistance levels that are close to the current bid price
      if ( (High[i+2] >= High[i+1]) && (High[i+2] >= High[i+3]) ) {
             level[i] = High[i+2];
      }
      // get support levels that are close to the current bid price
      if ( (Low[i+2] <= Low[i+1]) && (Low[i+2] <= Low[i+3]) ) {
             level[i] = Low[i+2];
      }    
      
   }   
}

// delete level lines
void deleteLevelLines() {
   for (int i = 0; i < PERIODS; i++) {
      if (level[i] != 0.0) {
         ObjectDelete("l" + i);
         level[i] = 0.0;
      }
   }
}

// delete level lines
void deleteTestedLevelLines() {
   for (int i = 0; i < PERIODS; i++) {
      if (testedLevel[i] != 0.0) {
         ObjectDelete("l" + i);
         testedLevel[i] = 0.0;
      }
   }
}

void showLevelLines() {
   for (int i = 0; i < PERIODS; i++) {
      if (level[i] != 0.0) {
         ObjectCreate("l" + i, OBJ_HLINE, 0, 0, level[i]); 
         ObjectSet("l" + i, OBJPROP_COLOR, Gold);
      }   
   }
}

void getAndShowLevelLines() {
   getLevels(); 
   if (ShowLevels) {
      showLevelLines();
   }
}

double getPatternLevel(int pattern, int barIndex) {

   // delete existing line if any and show the new line
   ObjectDelete("PatternLevel");
   
   if (pattern == BEAR_ENGULF) {     
      if ( Close[barIndex + 1] >= Open[barIndex] ) {        
         ObjectCreate("PatternLevel", OBJ_HLINE, 0, 0, Close[barIndex + 1]); 
         ObjectSet("PatternLevel", OBJPROP_COLOR, Blue);
         return (Close[barIndex + 1]);
      } 
      else {
         ObjectCreate("PatternLevel", OBJ_HLINE, 0, 0, Open[barIndex]); 
         ObjectSet("PatternLevel", OBJPROP_COLOR, Blue);
         return (Open[barIndex]);
      }
   }
   
   if (pattern == BULL_ENGULF) {
      if (Close[barIndex + 1] <= Open[barIndex]) {        
         ObjectCreate("PatternLevel", OBJ_HLINE, 0, 0, Close[barIndex + 1]); 
         ObjectSet("PatternLevel", OBJPROP_COLOR, Blue);
         return (Close[barIndex + 1]);
      } 
      else {
         ObjectCreate("PatternLevel", OBJ_HLINE, 0, 0, Open[barIndex]); 
         ObjectSet("PatternLevel", OBJPROP_COLOR, Blue);
         return (Open[barIndex]);
      }
   }
 
   return (0.0);
}

// this tests the number of consecutive times the pattern level was tested
int getPatternLevelTestResults(int barIndex, double level, int testType) {
   int timesTested = 0;   
    
   for (int i = barIndex; i < PERIODS; i++) {
      if (hasCandleTestedLevel(i, level, testType)) {
         timesTested++;            
      } 
      else if (hasCandleBrokenLevel(i, level, testType)) {
         techAnalysisComment = techAnalysisComment + "Pattern level test results: " + timesTested + "\n"; 
         return (timesTested);   
      }   
   }
   
   techAnalysisComment = techAnalysisComment + "Pattern level test results: " + timesTested + "\n"; 
   return (timesTested);      
}

// check if a res/sup level was tested and show it if so
int checkLevelsTested(int barIndex, int testType, bool delete) {
   int levelsTested = 0;
   
   if (delete) {
      deleteTestedLevelLines();
   }   
         
   levelsTestedComment = "";

   // check for tested levels
   for (int i = 0; i < PERIODS; i++) {
      if (level[i] != 0.0) {
         if (hasCandleTestedLevel(barIndex, level[i], testType)) {
            testedLevel[i] = level[i];            
         }   
      }
   }
   
   // display levels tested
   for (i = 0; i < PERIODS; i++) {
      if (testedLevel[i] != 0.0) {
         levelsTested++;
         ObjectCreate("l" + i, OBJ_HLINE, 0, 0, testedLevel[i]); 
         ObjectSet("l" + i, OBJPROP_COLOR, Red);
         levelsTestedComment = levelsTestedComment + DoubleToStr(testedLevel[i], Digits) + " ";
      }       
   }  
   
   // build comment
   if (levelsTested == 0) {
      levelsTestedComment = "Levels tested: NONE";          
   }
   else {
      levelsTestedComment = "Levels tested (" + levelsTested + "): " + levelsTestedComment;
   }   
   
   return (levelsTested);     
}

// determine the overall direction of the trend based on various 
// criteria
int doTrendAnalysis() {
   trendAnalysisComment = "";
   
   // check for down trend
   //if (getTrendDirection(0, LongTermTrendPeriods) == DOWN_TREND) {
      //if ( (getTrendDirection(0, MediumTermTrendPeriods) == DOWN_TREND) ){
         //if ( (getTrendDirection(0, ShortTermTrendPeriods) == DOWN_TREND) || (getTrendDirection(0, ShortTermTrendPeriods) == NO_TREND) ){
            if (getTrendLine(1, DOWN_TREND)) {
               return (DOWN_TREND);
            }  
         //}         
      //}   
   //}
   
   // check for up trend
   //if (getTrendDirection(0, LongTermTrendPeriods) == UP_TREND) {
      //if ( (getTrendDirection(0, MediumTermTrendPeriods) == UP_TREND) ){
         //if ( (getTrendDirection(0, ShortTermTrendPeriods) == UP_TREND) || (getTrendDirection(0, ShortTermTrendPeriods) == NO_TREND) ){
            if (getTrendLine(1, UP_TREND)) {
               return (UP_TREND);
            }
         //}         
      //}   
   //}   
   
   return (NO_TREND);
}

void doTechAnalysis() {
   
   techAnalysisComment = "";
   
      
   getMarketHighsOrLows(STOCH_OVERBOUGHT);
   showMarketHighsOrLows(STOCH_OVERBOUGHT);
   
   getMarketHighsOrLows(STOCH_OVERSOLD);
   showMarketHighsOrLows(STOCH_OVERSOLD);

   getAndShowLevelLines();
   
   
   // get up trend lines
   if (doTrendAnalysis() == UP_TREND) {
      techAnalysisComment = techAnalysisComment + "Trend direction: UP\n";   
   }   
   // get down trend lines
   if (doTrendAnalysis() == DOWN_TREND) {
      techAnalysisComment = techAnalysisComment + "Trend direction: DOWN\n";     
   } 
        
         
   // tested levels   
   if (checkLevelsTested(1, SUP_TEST, true) > 0) {
      checkLevelsTested(1, RES_TEST, false);
   }
   else {
      checkLevelsTested(1, RES_TEST, true);
   }   
   techAnalysisComment = techAnalysisComment + levelsTestedComment + "\n";
   
   // bollinger analysis
   getBollingerBandsState(1, 3);
   techAnalysisComment = techAnalysisComment + bollingerBandsComment + "\n";
   
   // candle pattern analysis
   if (getCandleType(1) != UNDEFINED) {
      techAnalysisComment = techAnalysisComment + "Previous candlestick type and pattern: " + getCandleTypeName(1);
   }
   if ( (getCandlePattern(1) != UNDEFINED) && (getCandleType(1) != UNDEFINED) ) {
      techAnalysisComment = techAnalysisComment + ", " + getCandlePatternName(1) + "\n";
   }   
      
}


string getCandleTypeName(int barIndex) {
   int type = getCandleType(barIndex);
   
   return (candleType[type]);   
}

string getCandlePatternName(int barIndex = 1) {
   int patttern = getCandlePattern(barIndex);

   return (candlePattern[patttern]);
      
}


string convertToPipsStr(double value) {
   double pips = value;

  // convert dollar value of pip to number of pip
   for (int i = 0; i < Digits; i++) {
            pips = pips*10;
   }
   
   return (DoubleToStr(pips, 0));
}


// analyze the market and return true if trade conditions found
bool doAnalysis() {  

   // do tech analysis for display purposes
   doTechAnalysis();
   doRiskAnalysis();     
   
   if (AccountBalance() <=  AccountBalanceLimit) {
      displayComment("Free balance limit ($" +  DoubleToStr(AccountBalanceLimit, 2) + ") reached!");    
      return (false);
   }
   else {
      if ( doTrendAnalysis() == DOWN_TREND ) {
         if (getStochasticState(0, 1, 2) == STOCH_OVERBOUGHT ) {
            if ( (getBollingerBandsState(1, 3) == BB_UL_TESTED) || (getBollingerBandsState(1, 3) == BB_UL_BROKEN) ) {
               if (getCandlePattern() == BEAR_ENGULF) {
                  if (UseTestedLevels) {
                     if ( (checkLevelsTested(1, SUP_TEST, true) == 0) ) {   
                        orderType = OP_SELL;
                        return (true);  
                     }                 
                  }   
                  else {
                     return (true);
                  }
               }        
            } 
         }              
         displayComment("Searching for trade condition...");
      }
   
      else if ( doTrendAnalysis() == UP_TREND) {
         if ( getStochasticState(0, 1, 2) == STOCH_OVERSOLD ) {
            if ( (getBollingerBandsState(1, 3) == BB_LL_TESTED) || (getBollingerBandsState(1, 3) == BB_LL_BROKEN) ) {
               if (getCandlePattern() == BULL_ENGULF) {
                  if (UseTestedLevels) {
                     if ( (checkLevelsTested(1, RES_TEST, true) == 0) ) {   
                        orderType = OP_BUY;
                        return (true);  
                     }                    
                  }   
                  else {
                     return (true);
                  }                  
               }            
            }
         }
         displayComment("Searching for trade condition...");    
      }
      else {
         displayComment("Searching for trade condition...");      
      }   
   }
         
   return (false);   
}

// prepare and check order for correctnes before passing on to placeOrder()
bool prepareOrder() {   
   double riskValue;   
   
   messageSent = false; 
   // create order based on the inner bar and check order validity
   // the order type was already set in doAnalysis()
   // place buy order if all is well
   if (orderType == OP_BUY) {
      orderPrice = NormalizeDouble(Ask, Digits);
      stopLoss = getStopLoss(orderPrice, orderType); 
      takeProfit = NormalizeDouble(orderPrice + ProfitFactor * (orderPrice - stopLoss) + Point * MarketInfo(Symbol(), MODE_SPREAD), Digits);
      riskValue = orderPrice - stopLoss;
      lots = getLotsToTrade(convertDollarsToPips(riskValue));
                  
      // check if prices are valid
      if ( ((Bid - stopLoss) >= MarketInfo(Symbol(),MODE_STOPLEVEL) * Point) && 
           ((takeProfit - Bid) >= MarketInfo(Symbol(),MODE_STOPLEVEL) * Point) ) {
         // determine risk         
         if ( !calculateRisk(riskValue) ) {
            displayComment("Risk too high, Risk: $" +  DoubleToStr(risk, 2)); 
            return (false);   
         }  
         else {
            displayComment("PLACE BUY ORDER - OP: " + DoubleToStr(orderPrice, Digits) + 
                                            " SL: " + DoubleToStr(stopLoss, Digits) + 
                                            " TP: " + DoubleToStr(takeProfit, Digits) );
            return (true);
         } 
         
      }
      else {
         displayComment("Take profit or stop loss is invalid: OP - " + DoubleToStr(orderPrice, Digits) + 
                                                            " SL: " + DoubleToStr(stopLoss, Digits) + 
                                                            " TP: " + DoubleToStr(takeProfit, Digits) );
         return (false);        
      }          
   }
   
   // prepare sell order if all is well
   if (orderType == OP_SELL) { 
      orderPrice = NormalizeDouble(Bid, Digits);
      stopLoss = getStopLoss(orderPrice, orderType);
      takeProfit = NormalizeDouble(orderPrice - ProfitFactor * (stopLoss - orderPrice) - Point * MarketInfo(Symbol(), MODE_SPREAD), Digits);
      riskValue = stopLoss - orderPrice;
      lots = getLotsToTrade(convertDollarsToPips(riskValue));
            
      // check if prices are valid
      if ( ((stopLoss - Ask) >= MarketInfo(Symbol(),MODE_STOPLEVEL) * Point) && 
           ((Ask - takeProfit) >= MarketInfo(Symbol(),MODE_STOPLEVEL) * Point) ) {
         // determine risk         
         if ( !calculateRisk(riskValue) ) {
            displayComment("Risk too high, Risk: $" +  DoubleToStr(risk, 2)); 
            return (false);   
         }  
         else {
             displayComment("PLACE SELL ORDER - OP: " + DoubleToStr(orderPrice, Digits) + 
                                              " SL: " + DoubleToStr(stopLoss, Digits) + 
                                              " TP: " + DoubleToStr(takeProfit, Digits) );
            return (true);
         } 
         
      }
      else {
         displayComment("Take profit or stop loss is invalid: OP - " + DoubleToStr(orderPrice, Digits) + 
                                                            " SL: " + DoubleToStr(stopLoss, Digits) + 
                                                            " TP: " + DoubleToStr(takeProfit, Digits) );
         return (false);        
      }      
   }  
     
      
   return (false);       
}

bool placeOrder() {
   bool success = true;

   if (orderType == OP_BUY) {
      orderTicket = OrderSend(Symbol(), OP_BUY, lots, orderPrice, 0, stopLoss, takeProfit, NULL, MagicNumber, 0, Green); 
      if (orderTicket == -1) {
        success = false; 
        displayComment("Trade Error!: " + GetLastError() + ", OP: " + orderPrice + " SL: " + stopLoss + " TP: " + takeProfit );
        if (messageSent == false) {
               Print(Symbol() + "Trade Error!: " + GetLastError()  + ", OP: " + orderPrice + " SL: " + stopLoss + " TP: " + takeProfit );
               messageSent = true;
        }
      }
      else {
        displayComment("Buy Order Successful!: Ticket #" + orderTicket + " OP: " + orderPrice + " SL: " + stopLoss + " TP: " + takeProfit + " Risk: " + risk);
        if (messageSent == false) {
               Alert("Buy Order Successful!: Ticket #" + orderTicket + " OP: " + orderPrice + " SL: " + stopLoss + " TP: " + takeProfit + " Risk: " + risk);
               if (EmailAlert) {
                  SendMail("Buy Order Successful!: Ticket #" + orderTicket, Symbol() + " BUY ORDER");
               }
               messageSent = true;
        }
        orderDate = Time[0];
      }
   }
   else {
      orderTicket = OrderSend(Symbol(), OP_SELL, lots, orderPrice, 0, stopLoss, takeProfit, NULL, MagicNumber, 0, Red); 
      if (orderTicket == -1) {
        success = false; 
        displayComment("Trade Error!: " + GetLastError()  + ", OP: " + orderPrice + " SL: " + stopLoss + " TP: " + takeProfit );
        if (messageSent == false) {
               Print(Symbol() + "Trade Error!: " + GetLastError()  + ", OP: " + orderPrice + " SL: " + stopLoss + " TP: " + takeProfit );
               messageSent = true;
        }
      }
      else {
        displayComment("Sell Order Successful!: Ticket #" + orderTicket + " OP: " + orderPrice + " SL: " + stopLoss + " TP: " + takeProfit + " Risk: " + risk);
        if (messageSent == false) {
               Alert("Sell Order Successful!: Ticket #" + orderTicket + " OP: " + orderPrice + " SL: " + stopLoss + " TP: " + takeProfit + " Risk: " + risk);
               if (EmailAlert) {
                  SendMail("Sell Order Successful!: Ticket #" + orderTicket, Symbol() + " SELL ORDER");
               }   
               messageSent = true;
        }
        orderDate = Time[0];
      }
   }
   
   return (success);
}

// This return true if an order was process
bool processOrder() {  
   
   doTechAnalysis();
   doRiskAnalysis();
 
   // Process existing orders if any
   if (OrdersTotal() != 0) { // tk go through orders and only process those with magic number
      for (int i = 0; i < OrdersTotal(); i++) {   
         if ( OrderSelect(i, SELECT_BY_POS) && (OrderMagicNumber() == MagicNumber) && (OrderSymbol() == Symbol()) ) {
            // automatically manage the trade by making it a risk free trade by moving the stop loss
            // beyond the order price by the spread plus 1 pip
            if (TradeAutoManagement) {
               if ( (OrderType() == OP_BUY) && 
                    (OrderOpenPrice() > OrderStopLoss()) && // try to move the stoploss as long as it is less than the order price 
                    (Time[0] > orderDate) && 
                    ((Low[1] - MarketInfo(Symbol(), MODE_SPREAD) * Point) > OrderOpenPrice()) && // modification criteria
                    (getStochasticState(0, 0, 0) == STOCH_OVERBOUGHT) ) { 
                        if (OrderModify(OrderTicket(), OrderLots(), Low[1] - MarketInfo(Symbol(), MODE_SPREAD) * Point, OrderTakeProfit(), 0, Blue)) {  
                            orderDate = Time[0];
                            orderTicket = -1; 
                            PlaySound("alert.wav");
                            Print(Symbol() + ": Buy order modified!");
                            if (EmailAlert) {
                              SendMail(Symbol() + ": Buy order modified!", Symbol() + ": Buy order modified!");
                            }
                            return (true);
                         }
                         else {
                            PlaySound("alert.wav");
                            Print(Symbol() + ": Buy order could not be modified!");
                            return (true);
                         }        
               }  
               // handle sell order
               if ( (orderType == OP_SELL) && 
                    (OrderOpenPrice() < OrderStopLoss()) &&
                    (Time[0] > orderDate) && 
                    ((High[1] + MarketInfo(Symbol(), MODE_SPREAD) * Point) < OrderOpenPrice())  && // modification criteria
                    (getStochasticState(0, 0, 0) == STOCH_OVERSOLD) ) {
                        if (OrderModify(OrderTicket(), OrderLots(), High[1] + MarketInfo(Symbol(), MODE_SPREAD) * Point, OrderTakeProfit(), 0, Blue)) {
                            orderDate = Time[0];
                            orderTicket = -1; 
                            PlaySound("alert.wav");
                            Print(Symbol() + ": Sell order modified!");
                            if (EmailAlert) {
                              SendMail(Symbol() + ": Sell order modified!", Symbol() + ": Sell order modified!");
                            }
                            return (true);
                         }
                         else {
                            PlaySound("alert.wav");
                            Print(Symbol() + ": Sell order could not be modified!");
                            return (true);
                         }        
               } 
            }
              
            displayComment("Trade in progress..."); // provide trade details
            return (true);
         }
      }  
      displayComment("Trade in progress...");    
      return (true);
   }   

     
   return (false);
}

// gets the stop loss for the order which
// can be used to determine risk
double getStopLoss(double orderPrice, int orderType) {
    double lowestLow, highestHigh; // of pass 3 bars
    
    if (orderType == OP_BUY) {
      //lowestLow = Low[iLowest(NULL,0,MODE_LOW,3,1)];
      // get the first low
      if (marketLowBarIndex[0] != -1) {
         lowestLow = Low[marketLowBarIndex[0]];
         return (lowestLow - PipToleranceForStopLoss * Point);
      }   
    } 
    
    if (orderType == OP_SELL) {
      //highestHigh = High[iHighest(NULL,0,MODE_HIGH,3,1)];
      // get the firsyt high
      if (marketHighBarIndex[0] != -1) {
         highestHigh = High[marketHighBarIndex[0]];
         return (highestHigh + PipToleranceForStopLoss * Point);
      }   
    } 
    
    return (0.0); 
}

void doRiskAnalysis() {   
   double pips, riskValue, stopLoss;
   string buyRiskComment, sellRiskComment, maxRiskComment;

   // get max risk
   maximumRisk = getMaximumRisk();
   maxRiskComment = "Maximum Risk: $" + DoubleToStr(maximumRisk, 2); 
   riskAnalysisComment =  maxRiskComment + "\n";  
   
  
   // calc buy risk
   //if (getCandleType() == BULL_CAND) {
   if (getTrendLine(1, UP_TREND)) {
      stopLoss = getStopLoss(Close[0], OP_BUY); 
      riskValue = Close[0] - stopLoss;
      if ( riskValue > 0) {
         calculateRisk(riskValue);
         pips = convertDollarsToPips(riskValue);
         buyRiskComment = "Buy Risk: $" + DoubleToStr(risk, 2) + ", SL: " + DoubleToStr(stopLoss, Digits) + ", Lots: " + DoubleToStr(getLotsToTrade(pips), 2) + ", Pips: " + DoubleToStr(pips, 0);
         riskAnalysisComment = riskAnalysisComment + buyRiskComment + "\n";
      }
   }

   // calc sell risk
   //if (getCandleType() == BEAR_CAND) {
   if (getTrendLine(1, DOWN_TREND)) {
      stopLoss = getStopLoss(Close[0], OP_SELL);
      riskValue = stopLoss - Close[0];
      if ( riskValue > 0) {
         calculateRisk(riskValue);
         pips = convertDollarsToPips(riskValue);
         sellRiskComment = "Sell Risk: $" + DoubleToStr(risk, 2) + ", SL: " + DoubleToStr(stopLoss, Digits) + ", Lots: " + DoubleToStr(getLotsToTrade(pips), 2) + ", Pips: " + DoubleToStr(pips, 0);  
         riskAnalysisComment = riskAnalysisComment + sellRiskComment + "\n";   
      } 
   }  

}

double getMaximumRisk() {
  return (AccountFreeMargin()*(MaximumPercentageRisk/100.0));
}

// calculate risk and return false if it exceeds maximum allowed
bool calculateRisk(double value) {
   
   // convert dollar value of pip to number of pip
   double pips = convertDollarsToPips(value);
  
   risk = pips * getLotsToTrade(pips) * MarketInfo(Symbol(), MODE_LOTSIZE) * getValueOfPip("USD");
   maximumRisk = getMaximumRisk(); 
   
   if (risk > maximumRisk) {
     return (false);
   }  
         
   return (true);     
}

double convertDollarsToPips(double value) {
   double pips = value;

   // convert dollar value of pip to number of pip
   for (int i = 0; i < Digits; i++) {
            pips = pips*10;
   }
   
   return (pips);
}

double getLotsToTrade(double pips) {
   double lots;
   double costOfPipsToTrade;
   double standardLotSize;
   
   if (UseMaximumRisk) {   
      costOfPipsToTrade = pips * getValueOfPip("USD");
      maximumRisk =  AccountFreeMargin()*(MaximumPercentageRisk/100.0);
      
      lots = maximumRisk/(costOfPipsToTrade * MarketInfo(Symbol(), MODE_LOTSIZE));
      if (lots < MarketInfo(Symbol(), MODE_MINLOT)) {
         lots = MarketInfo(Symbol(), MODE_MINLOT); // make sure at least the minimum lots is returned
      }   
      return (NormalizeDouble(lots, 2)); 
   }
   
   return (FixedLots);
}

// return the value of a pip in the specified currency
double getValueOfPip(string currency) {
   double costPerPip;


   if (StringSubstr(Symbol(), 0, 3) == currency) { // for pairs such as USDJPY
     costPerPip = Point/Bid; 
   }
   else if (StringSubstr(Symbol(), 3, 3) == currency) { // for pairs such as EURUSD
     costPerPip = Point;  
   }
   else { // for crosses. not yet implemented so just return 0.0
      costPerPip = 0.0;
   }   
   
   return (costPerPip);

}

string getRequiredOrderNumber() {      
   return ("" + TimeDay(TimeLocal()) + "" + TimeMinute(TimeLocal()) );   
}

int start() {

  soundAlarmIfDue();
      
  if (!processOrder()) {  
      if (AutoTrade) {       
         if ( doAnalysis() ) {
            if (prepareOrder()) {
               placeOrder();       
            }    
         
         }
      }
      else {
         if ( doAnalysis() ) {
            prepareOrder();
         
         }
      }  
  }   
      
  return(0);                                     
}

//--------------------------------------------------------------------
int deinit() {
   // save data and close openned files here
   Comment(" ");
   
   ObjectDelete("PatternLevel");
   deleteLevelLines();
   deleteTestedLevelLines();
   deleteMarketHighsOrLows(STOCH_OVERBOUGHT);
   deleteMarketHighsOrLows(STOCH_OVERSOLD);
   
   deleteTrendLine(1, UP_TREND);  
   deleteTrendLine(1, DOWN_TREND);         
   
   return(0);                                      
}


