#include <Timer.h>
#include "TimeSync.h"
#include "printf.h"
 
 module TimeSyncC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Random;
  uses interface SplitControl as AMControl;
  uses interface Receive;
  uses interface LocalTime<TMilli> as LocalTime;
}
 
  implementation {

  bool busy = FALSE;
  message_t pkt;
  uint32_t t1=0,t2=0,t3=0,t4=0,nodeid=1141,propogation_delay=0,phase_drift=0,done=0;
    event void Boot.booted() {
    	printf("mote with id 1111 is awake \n");
		call AMControl.start();
	}
   	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
	     	call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
	   	}
		else {
		call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
		call AMControl.stop();
	}

	event void Timer0.fired() {
		
	 if(t1>0 && t2>0 && t3>0 && t4>0 && done==0){
		
			printf("T1 %u \n",t1);
			printf("T2 %u \n",t2);
			printf("T3 %u \n",t3);
			printf("T4 %u \n",t4);
			printf("node id %u \n",nodeid);
			done++;
			call Leds.led2On();
		}

    }
    event void Timer1.fired(){
    	if(!busy && t3==0 && t4==0 && t1>0 && t2>0){
		MotetoMoteMsg* newpkt1 = (MotetoMoteMsg*)(call Packet.getPayload(&pkt, sizeof(MotetoMoteMsg)));
			newpkt1-> t1 = t1;
			newpkt1-> t2 = t2;
			newpkt1-> t3 = call LocalTime.get();
			//printf("T3 %u \n",t3);
			newpkt1-> t4 = 0;
			newpkt1-> propogation_delay=0;
            newpkt1-> phase_drift=0;
			newpkt1->nodeid = nodeid;
			newpkt1->node2send=114;
			printf("firing timer1\n");
			t3 = newpkt1->t3;

		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MotetoMoteMsg)) == SUCCESS) {
			//printf("t3 send from node id 5 \n");
			busy = TRUE;
			}
		}
    }
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(MotetoMoteMsg)) {
			MotetoMoteMsg* newpkt = (MotetoMoteMsg*)payload;
			if(newpkt->t2 == 0 && newpkt->node2send==nodeid){
				t1 = newpkt -> t1 ;
				t2 = call LocalTime.get();
				printf("received for the 1st time\n");		
				call Timer1.startOneShot(10);
				
			}
			else if(newpkt->t4>0 && newpkt->node2send==nodeid){//if everything is proper``
				printf("mote 1111 received for the 2nd time\n");
				propogation_delay =newpkt ->propogation_delay;
				phase_drift=newpkt->phase_drift;
				printf("propogation_delay 1 %u \n",propogation_delay);
				printf("phase_drift %u \n",phase_drift);
				t1 = newpkt -> t1;
				t2 = newpkt -> t2-propogation_delay+phase_drift;//added by me
				t3 = newpkt -> t3+propogation_delay+phase_drift;//added by me
				t4 = newpkt -> t4;

			}
		}
		return msg;
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg ) {
			  busy = FALSE;
		}
		
	}
}