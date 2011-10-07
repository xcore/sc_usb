#include "packetManager.h"
#include <stdio.h>
#include <assert.h>


//unsigned int packetBuffer[NUM_PACKETS][1516/sizeof(int)+2];
static int freeList;

void packetBufferInit() {
    for(int i = 0; i < NUM_PACKETS; i++) {
        packetBuffer[i][0] = i+1;
    }
    packetBuffer[NUM_PACKETS-1][0] = NULL_PACKET;
    freeList = 0;
}

int packetBufferAlloc() {
    int i = freeList;
    assert(i != NULL_PACKET);
    freeList = packetBuffer[freeList][0];
    return i;
}

void packetBufferFree(int index) {
    packetBuffer[index][0] = freeList;
    freeList = index;
}
