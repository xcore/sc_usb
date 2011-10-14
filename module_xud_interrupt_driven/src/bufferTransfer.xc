// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "stdio.h"
#include "assert.h"
#include "xud.h"
#include "xud_interrupt_driven.h"

extern void setINHandler(chanend s, XUD_ep y);
extern void setOUTHandler(chanend s, XUD_ep y);
extern void enableInterrupts(chanend serv);

void XUD_provide_OUT_buffer__(XUD_ep e, unsigned addr) {
    int chan_array_ptr;
    int xud_chan;
    int my_chan;
    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(e));
    asm ("ldw %0, %1[1]":"=r"(xud_chan):"r"(e));
    asm ("ldw %0, %1[2]":"=r"(my_chan):"r"(e));
    asm ("out res[%0], %1"::"r"(my_chan),"r"(1));  

    /* Store buffer pointer */
    asm ("stw %0, %1[5]"::"r"(addr),"r"(e));
    
    /* Mark EP as ready with ID */
    asm ("stw %0, %1[0]"::"r"(xud_chan),"r"(chan_array_ptr));
}

void XUD_provide_OUT_buffer_i(XUD_ep e, unsigned buffer[], int index) {
    int addr;
    asm("add %0, %1, %2":"=r"(addr): "r" (buffer), "r" (index));
    XUD_provide_OUT_buffer__(e, addr);
}

void XUD_provide_OUT_buffer(XUD_ep e, unsigned buffer[]) {
    int addr;
    asm("add %0, %1, 0":"=r"(addr): "r" (buffer));
    XUD_provide_OUT_buffer__(e, addr);
}

int XUD_compute_OUT_length(XUD_ep e, unsigned buffer[]) {
    int newPtr;
    int tail;
    unsigned addr;
    asm("add %0, %1, 0":"=r"(addr): "r" (buffer));
    asm ("ldw %0, %1[5]":"=r"(newPtr):"r"(e));
    asm ("ldw %0, %1[3]":"=r"(tail):"r"(e));

    if (tail == 9) {
        return -1;
    }
    return newPtr - addr + tail - 16;
}

void XUD_provide_IN_buffer__(XUD_ep e, int pid, unsigned addr, unsigned len) {
    XUD_SetReady_In(e, pid, addr, len);
}

void XUD_provide_IN_buffer(XUD_ep e, int pid, unsigned buffer[], unsigned len) {
    unsigned addr;
    asm("add %0, %1, 0":"=r"(addr): "r" (buffer));
    XUD_SetReady_In(e, pid, addr, len);
}

void XUD_provide_IN_buffer_i(XUD_ep e, int pid, unsigned buffer[], int index, unsigned len) {
    unsigned addr;
    asm("add %0, %1, %2":"=r"(addr): "r" (buffer), "r" (index));
    XUD_SetReady_In(e, pid, addr, len);
}
