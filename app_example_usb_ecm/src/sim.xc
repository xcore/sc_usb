#include <xs1.h>
#include <stdio.h>

static    int x[10];
static    int y[10];

static void sendUSBOUT(chanend cOut, int len) {
    inuint(cOut);
    outuint(cOut, 0);
    outuint(cOut, 0);
    for(int j = 0; j < len>>2; j++) {
        outuint(cOut, j * 0x01010101);
    }
    outct(cOut, 12+(len&3));
}

void XUD_Manager_SIM(chanend cOut, chanend cIn) {
    int addr;
    int c;
    timer t;
    unsigned s;

    asm("add %0, %1, 0":"=r"(c): "r" (cOut));
    asm("getd %0, res[%1]":"=r"(c): "r" (c));
    asm("add %0, %1, 0":"=r"(addr): "r" (x));
    asm("stw %0, %1[2]"::"r"(c), "r" (addr));
    asm("ldaw %0, %1[6]":"=r"(c): "r" (addr));
    asm("stw %0, %1[0]"::"r"(c), "r" (addr));

    asm("add %0, %1, 0":"=r"(c): "r" (cIn));
    asm("getd %0, res[%1]":"=r"(c): "r" (c));
    asm("add %0, %1, 0":"=r"(addr): "r" (y));
    asm("stw %0, %1[2]"::"r"(c), "r" (addr));
    asm("ldaw %0, %1[6]":"=r"(c): "r" (addr));
    asm("stw %0, %1[0]"::"r"(c), "r" (addr));
    
    asm("add %0, %1, 0":"=r"(addr): "r" (x));
    outuint(cOut, addr);         // Init EP
    asm("add %0, %1, 0":"=r"(addr): "r" (y));
    outuint(cIn, addr);         // Init EP
#if OUTIE
    for(int i = 256; i < 1514; i+=128) {
        int l = i;
        printf("Supplying packet length %d\n", i);
        while(l >= 512) {
            sendUSBOUT(cOut, 512);
            l-= 512;
        }
        sendUSBOUT(cOut, l);
    t :> s;
        t when timerafter(s+50000) :> s;
    }
#else
    while(1) {
        int len = 0;
        inuint(cIn);       // signal
        inct(cIn);
        outuint(cIn, 0);   // interrupt
        while(!testct(cIn)) {
            len += 4;
            inuint(cIn);
        }
        inct(cIn);
        inuint(cIn);
        outuint(cIn, 0);
        printf("Got packet %d\n", len);
    }
#endif
}
