#include <Timer.h>
#include "TimeSync.h"
#include <printf.h>
 
configuration TimeSyncAppC {
}
implementation {
   components MainC;
   components LedsC;
   components SerialPrintfC;
   components RandomC;
   components TimeSyncC as App;
   components new TimerMilliC() as Timer0;
   components new TimerMilliC() as Timer1;
   components new TimerMilliC() as Timer2;
   components ActiveMessageC;
   components new AMSenderC(AM_MOTETOMOTE);
   components new AMReceiverC(AM_MOTETOMOTE); 
   components LocalTimeMilliC;
   
   	
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.Random -> RandomC;
   App.Timer0 -> Timer0;
   App.Timer1 ->Timer1;
   App.Timer2 ->Timer2;
   App.Packet -> AMSenderC;
   App.AMPacket -> AMSenderC;
   App.AMSend -> AMSenderC;
   App.AMControl -> ActiveMessageC;
   App.Receive -> AMReceiverC;
   App.LocalTime -> LocalTimeMilliC;
 }
