#include <Timer.h>
#include "TimeSync.h"
#include "printf.h"
 
 module TimeSyncC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
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
  uint32_t t1=0,t2=0,t3=0,t4=0,phase_drift=0,propogation_delay=0,i=0,to_send=11,nodeid=1,iteration=0;
    event void Boot.booted() {
    	printf("base station awake \n");
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

	event void Timer0.fired() { //very first iteration/condition
		//call Leds.set(4);
		if(i==4)
		call Leds.set(4);//process complete
		if (!busy && (t2+t3+t4)==0 && i<4) {
			MotetoMoteMsg* newpkt = (MotetoMoteMsg*)(call Packet.getPayload(&pkt, sizeof(MotetoMoteMsg)));
			newpkt-> t1 = call LocalTime.get();
			newpkt-> t2 = 0;
			newpkt-> t3 = 0;
			newpkt-> t4 = 0;
			newpkt->nodeid =nodeid ;
			newpkt->node2send=to_send;
			newpkt->propogation_delay=0;
			newpkt->phase_drift=0;
			t1 = newpkt->t1;

		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MotetoMoteMsg)) == SUCCESS) {
			printf("t1 value is : %u",t1);
			printf("sent from b.s to node:%u \n",newpkt->node2send);
			busy = TRUE;
			
			}
		}
		else if(!busy && t1>0 && t2>0 && t3>0 && t4>0 && i<4){
			MotetoMoteMsg* newpkt = (MotetoMoteMsg*)(call Packet.getPayload(&pkt, sizeof(MotetoMoteMsg)));
			newpkt-> t1 = t1;
			newpkt-> t2 = t2;
			newpkt-> t3 = t3;
			newpkt-> t4 = t4;
			newpkt->nodeid = nodeid;
			newpkt->node2send=to_send;
			printf("sent value of t4 is :%u \n",newpkt-> t4);
			propogation_delay=((t4-t3)+(t2-t1))/2;
			if((t4+t1)>(t3+t2)){
				phase_drift=((t4-t3-t2+t1))/2;
			}
			else{
				phase_drift=(-1*(t4-t3-t2+t1))/2;
			}
			newpkt -> propogation_delay = propogation_delay;
			newpkt -> phase_drift = phase_drift;
			
			printf("T1 %u \n",t1);
			printf("T2 %u \n",t2);
			printf("T3 %u \n",t3);
			printf("T4 %u \n",t4);
		
		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MotetoMoteMsg)) == SUCCESS) {
			busy = TRUE;
			printf("final msg t4 sent to node:%u \n",newpkt->node2send);
			i++;
			//if(i==4)
            //call Leds.led2On();
			printf("value of i is :%u \n",i);
			if(to_send==11)
			to_send=to_send+1;
			//else if(to_send=14)
			//call Leds.set(2);//indication of process completion
			printf("next target to b.s is : %u \n",to_send);
			t1=0;t2=0;t3=0;t4=0;propogation_delay=0;phase_drift=0;
			printf("all vals of b.s refreshed \n");
			}
		}

	}


	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg ) {
			  busy = FALSE;
		}	
	}
    
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(MotetoMoteMsg)) {
			MotetoMoteMsg* newpkt = (MotetoMoteMsg*)payload;

			if(newpkt->t2 > 0 && newpkt->t3 >0 && newpkt-> t4 ==0 && newpkt -> nodeid ==to_send)
			{ //nodeid==1 before changed by me!!
			t2 = newpkt -> t2;
			t3 = newpkt -> t3; 
			t4 = call LocalTime.get();
			printf("the value of t4 is: %u",t4);
			call Leds.set(1);
			}
		}
		return msg;
	}

}