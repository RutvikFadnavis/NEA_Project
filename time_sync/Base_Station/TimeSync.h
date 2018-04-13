#ifndef TIMESYNC_H
#define TIMESYNC_H
 
 enum {
   AM_MOTETOMOTE = 6,
   TIMER_PERIOD_MILLI = 100
 };
 
/* typedef nx_struct BlinkToRadioMsg {
nx_uint16_t nodeid1;
nx_uint16_t counter1;
nx_uint16_t time_stamp1;
nx_uint16_t nodeid2;
nx_uint16_t counter2;
nx_uint16_t time_stamp2;
nx_uint16_t nodeid3;
nx_uint16_t counter3;
nx_uint16_t time_stamp3;
nx_uint16_t nodeid0;
nx_uint16_t serial_id;
} BlinkToRadioMsg;

*/
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


/*typedef nx_struct serial_pkt{
nx_uint16_t nodeid;
nx_uint16_t ackn;
}serial_pkt;
*/

 #endif
