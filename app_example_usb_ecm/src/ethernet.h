// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

extern int ipAddressOurs;
extern int ipAddressTheirs;
extern char macAddressOurs[6];
extern char macAddressTheirs[6];

extern void handlePacket(unsigned int packet, int len);

extern void onesChecksum(unsigned int startsum, unsigned short data[], int begin, int end, int to);

void lightLed(int val);
