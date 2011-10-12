// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "packetManager.h"
#include <stdio.h>
#include <assert.h>


//unsigned int packetBuffer[NUM_PACKETS][1516/sizeof(int)+2];
static int freeList;

void packetBufferInit() {
    for(int i = 0; i < NUM_PACKETS; i++) {
        packetBuffer[i][0] = i+1;
        packetBuffer[i][1] = ~(i*i);
    }
    packetBuffer[NUM_PACKETS-1][0] = NULL_PACKET;
    freeList = 0;
}

int packetBufferAlloc() {
    int i = freeList;
    assert(i != NULL_PACKET);
    assert(packetBuffer[i][1] == ~(i*i));
    freeList = packetBuffer[freeList][0];
    return i;
}

void packetBufferFree(int index) {
    packetBuffer[index][0] = freeList;
    packetBuffer[index][1] = ~(index*index);
    freeList = index;
}
