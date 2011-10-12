// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "packetManager.h"
#include "stdlib.h"

void packetCopyInto(int packetNum, char *from, int len) {
    memcpy(packetBuffer[packetNum], from, len);
}
