// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <assert.h>
#include <stdio.h>
#include "q.h"
#include "packetManager.h"

void qInit(struct queue &q) {
    q.len = 0;
    q.rd = 0;
    q.wr = 0;
}

int qGet(struct queue &q) {
    int r = q.rd;
    if (qIsEmpty(q)) {
        assert(0);
    }
    q.len--;
    q.rd++;
    if (q.rd == QL) {
        q.rd = 0;
    }
    return r;
}

static void pq(struct queue &q) {
    printf("rd: %d, wr: %d len %d\n", q.rd, q.wr, q.len);
    for(int i = 0; i < QL; i++) {
        int p = q.data[i].packet;
        int l = q.data[i].len;
        printf("Buf %d (%4d bytes) words %08x %08x %08x ... %08x %08x\n", p, l, packetBuffer[p][0],  packetBuffer[p][1],  packetBuffer[p][2],  packetBuffer[p][(l>>2)-2],  packetBuffer[p][(l>>2)-1]);
    }
}

int qPut(struct queue &q, int packet, int len) {
    int tail = q.wr;
    if (qIsFull(q)) {
        printf("Inserting %d in full queue\n", packet);
        pq(q);
        assert(0);
    }
    for(int k = 0; k < q.len; k++) {
        if (q.data[(q.rd+k)%QL].packet == packet) {
            printf("Inserting duplicate %d\n", packet);
            pq(q);
            assert(0);
        }
    }
    q.data[tail].from = 0;
    q.data[tail].len = len;
    q.data[tail].packet = packet;
    q.len++;
    q.wr++;
    if (q.wr == QL) {
        q.wr = 0;
    }
    return tail;
}

int qPeek(struct queue &q) {
    return q.rd;
}

int qIsEmpty(struct queue &q) {
    return q.len == 0;
}

int qIsFull(struct queue &q) {
    return q.len == QL;
}
