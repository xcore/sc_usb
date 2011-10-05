#include "xud.h"
#include "xud_interrupt_driven.h"

extern void setINHandler(chanend s, XUD_ep y);
extern void setOUTHandler(chanend s, XUD_ep y);
extern void enableInterrupts(chanend serv);

void XUD_provide_OUT_buffer(XUD_ep e, unsigned bufferPtr)
{
    int chan_array_ptr;
    int xud_chan;
    int my_chan;
    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(e));
    asm ("ldw %0, %1[1]":"=r"(xud_chan):"r"(e));
    asm ("ldw %0, %1[2]":"=r"(my_chan):"r"(e));
    asm ("out res[%0], %1"::"r"(my_chan),"r"(1));  

    /* Store buffer pointer */
    asm ("stw %0, %1[5]"::"r"(bufferPtr),"r"(e));
    
    /* Mark EP as ready with ID */
    asm ("stw %0, %1[0]"::"r"(xud_chan),"r"(chan_array_ptr));
}

int XUD_compute_OUT_length(XUD_ep e, unsigned bufferPtr) {
    int newPtr;
    int tail;
    asm ("ldw %0, %1[5]":"=r"(newPtr):"r"(e));
    asm ("ldw %0, %1[3]":"=r"(tail):"r"(e));
    
    return newPtr - bufferPtr + tail - 16;
}

void XUD_provide_IN_buffer(XUD_ep e, int pid, unsigned addr, unsigned len) {
    XUD_SetReady_In(e, pid, addr, len);
}
