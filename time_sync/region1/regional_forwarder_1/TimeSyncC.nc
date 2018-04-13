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
  uint32_t t1=0,t2=0,t3=0,t4=0,nodeid=11,done=0,i=0,T1=0,T2=0,T3=0,T4=0,
           propogation_delay=0,phase_drift=0,propogation_delay_1=0,phase_drift_1=0,to_send=111;
    event void Boot.booted() {
    	printf("mote with node id 11 is awake \n");
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
		
	 //if(t1>0 && t2>0 && t3>0 && t4>0 && done==0){
	if (!busy && ((T2+T3+T4)==0) && (t1>0) && (t2>0) && (t3>0) && (t4>0) && (done==0)){//regional forwarder is getting synced
	//MotetoMoteMsg* newpkt = (MotetoMoteMsg*)(call Packet.getPayload(&pkt, sizeof(MotetoMoteMsg)));	
			printf("T1 %u \n",t1);
			printf("T2 %u \n",t2);
			printf("T3 %u \n",t3);
			printf("T4 %u \n",t4);
			printf("node id %u \n",nodeid);
			done=1;
			call Leds.set(4);//indication of process completion
		}
		else if(!busy && ((T2+T3+T4)==0) && (done==1) && (i<4))
		{//send to cluster heads
			MotetoMoteMsg* newpkt = (MotetoMoteMsg*)(call Packet.getPayload(&pkt, sizeof(MotetoMoteMsg)));
            newpkt-> t1 = call LocalTime.get()+propogation_delay+phase_drift;
			newpkt-> t2 = 0;
			newpkt-> t3 = 0;
			newpkt-> t4 = 0;
			newpkt->nodeid = nodeid;//change
			newpkt->propogation_delay=0;
			newpkt->phase_drift=0;
			newpkt->node2send=to_send;
			T1 = newpkt->t1;
			printf("t1 value sent to cluster head motes: %u \n",T1);
			//propogation_delay=((t4-t3)+(t2-t1))/2;
			//newpkt -> propogation_delay = propogation_delay;
			//newpkt -> phase_drift = phase_drift;
			printf("sending vals to cluster head \n");
			printf("T1 %u \n",T1);
			//printf("T2 %u \n",T2);
			//printf("T3 %u \n",T3);
			//printf("T4 %u \n",T4);
		
		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MotetoMoteMsg)) == SUCCESS) {
			printf("sent from b.s to node:%u \n",newpkt->node2send);
			busy = TRUE;
			}
		}
	//end of first condition
	//start of t4 condition n final transmission to next level
			else if(!busy && T1>0 && T2>0 && T3>0 && T4>0 && i<4 && done==1 && to_send<115){
			MotetoMoteMsg* newpkt = (MotetoMoteMsg*)(call Packet.getPayload(&pkt, sizeof(MotetoMoteMsg)));
			newpkt-> t1 = T1;
			newpkt-> t2 = T2;
			newpkt-> t3 = T3;
			newpkt-> t4 = call LocalTime.get()+propogation_delay+phase_drift;
			T4=newpkt-> t4;
			newpkt->nodeid = nodeid;
			newpkt->node2send=to_send;
			propogation_delay_1=((T4-T3)+(T2-T1))/2;
			if((T4+T1)>(T3+T2)){
				phase_drift_1=((T4-T3-T2+T1))/2;
			}
			else{
				phase_drift_1=(-1*(T4-T3-T2+T1))/2;
			}
			newpkt -> propogation_delay = propogation_delay_1;
			newpkt -> phase_drift = phase_drift_1;
			
			printf("T1 %u \n",T1);
			printf("T2 %u \n",T2);
			printf("T3 %u \n",T3);
			printf("T4 %u \n",T4);
		
		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MotetoMoteMsg)) == SUCCESS) {
			busy = TRUE;
			printf("final msg t4 sent to node:%u \n",newpkt->node2send);
			i++;
			printf("value of i is :%u \n",i);
			if(to_send<114)
			to_send++;
			printf("next target for regional forwarder is : %u \n",to_send);
			T1=0,T2=0,T3=0,T4=0,propogation_delay_1=0,phase_drift_1=0;
			printf("all vals of b.s refreshed \n");
			}
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
			t3 = newpkt1->t3;

		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MotetoMoteMsg)) == SUCCESS) {
			printf("t3 send from node id 11 \n"); 
			busy = TRUE;
			}
		}
    }
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(MotetoMoteMsg)) {
			MotetoMoteMsg* newpkt = (MotetoMoteMsg*)payload;
			//printf("receiving something \n");
			if(newpkt->t2 == 0 && newpkt->node2send==nodeid && done==0){
				printf("not synced yet getting t1 val from b.s \n");
				t1 = newpkt -> t1 ;
				t2 = call LocalTime.get();		
				call Timer1.startOneShot(10);
				
			}
			else if(newpkt->t4>0 && newpkt->node2send==nodeid && done==0){//if everything is proper``
				propogation_delay =newpkt ->propogation_delay;
				phase_drift=newpkt->phase_drift;
				printf("propogation_delay %u \n",propogation_delay);
				printf("phase_drift %u \n",phase_drift);
				t1 = newpkt -> t1;
				t2 = newpkt -> t2-propogation_delay-phase_drift;//added by me
				t3 = newpkt -> t3+propogation_delay-phase_drift;//added by me
				t4 = newpkt -> t4;
			}

			else if(done==1 && newpkt -> nodeid == to_send)//to act as b.s to the higher level motes mj!!!!
    	    {
    		printf("enter the dragon \n");
			printf("received from node:%u",newpkt -> nodeid);
			if(newpkt->t1>0 && newpkt->t2 > 0 && newpkt->t3 >0 && newpkt-> t4 ==0 ){
			printf("t4 not yet declared \n");
			T2 = newpkt -> t2;
			T3 = newpkt -> t3; 
			T4 = call LocalTime.get()+propogation_delay+phase_drift;
			printf("syncd inside receive of level1 sending t4 val is allotted  \n");
			printf("sync completed= %u \n",done);
			}
			//acknowledgement receive part
			//else if(newpkt->t1>0 && newpkt->t2 > 0 && newpkt->t3 >0 && newpkt-> t4 >0 && newpkt -> nodeid == 1)//change node id
			//{
				//printf("acknowledgement received from level 3 n is equal to: %u \n",newpkt->acknowledgement);
				//acknowledgement_temp=newpkt->acknowledgement;
				//call Timer3.startOneShot(10);
				
				//printf("acknowledgement received from level3 and sent to level 1 ack value: %u \n",newpkt->acknowledgement);
			
				//if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MotetoMoteMsg)) == SUCCESS) {
			//busy = TRUE;
				//sync_completed=0;
			//printf("sent acknowledgement from level 1 to base station n value is %u \n",newpkt->acknowledgement);
			//}
			//}
		// msg;
	    //}
 		}
		return msg;
	}
}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg ) {
			  busy = FALSE;
		}
		
	}
}