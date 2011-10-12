// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <assert.h>
#include "q.h"

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

int qPut(struct queue &q, int packet, int len) {
    int tail = q.wr;
    if (qIsFull(q)) {
        assert(0);
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
