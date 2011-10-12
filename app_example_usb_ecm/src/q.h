// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#define QL 4

struct queue {
    int rd, wr, len;
    struct {
        int packet, from, len;
    } data[QL];
};

extern void qInit(struct queue &q) ;
extern int qGet(struct queue &q) ;
extern int qPut(struct queue &q, int packet, int len) ;
extern int qPeek(struct queue &q) ;
extern int qIsEmpty(struct queue &q) ;
extern int qIsFull(struct queue &q) ;

extern struct queue toHost;
