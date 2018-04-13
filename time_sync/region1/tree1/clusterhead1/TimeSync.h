#ifndef TIMESYNC_H
#define TIMESYNC_H
 
 enum {
   AM_MOTETOMOTE = 6,
   TIMER_PERIOD_MILLI = 100
 };
 
typedef nx_struct MotetoMoteMsg {
  nx_uint16_t nodeid;
  nx_uint16_t node2send;
  nx_uint32_t t1;
  nx_uint32_t t2;
  nx_uint32_t t3;
  nx_uint32_t t4;
  nx_uint32_t propogation_delay;
  nx_uint32_t phase_drift;
} MotetoMoteMsg;

 #endif