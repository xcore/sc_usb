// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "packetManager.h"
#include "ethernet.h"
#include <xclib.h>
#include "q.h"
#include "femtoIP.h"
#include "femtoUDP.h"
#include "femtoTCP.h"
#include "dhcp.h"
#include <print.h>
#include <stdio.h>
#include <assert.h>

extern struct queue toHost;

int ipAddressOurs   = 0xA9FE5555;
int ipAddressTheirs = 0xA9FEAAAA;
char macAddressOurs[6] = {0x00, 0x22, 0x97, 0x08, 0xA0, 0x02};
char macAddressTheirs[6] = {0x00, 0x22, 0x97, 0x08, 0xA0, 0x03};

unsigned char localName[] = "\004blah\005local";
unsigned char localName2[] = "\004host\005local";


int verbose = 0;

void onesChecksum(unsigned int sum, unsigned short data[], int begin, int end, int to) {
    for(int i = begin; i <= end; i++) {
        sum += byterev(data[i]) >> 16;
    }
    sum = (sum & 0xffff) + (sum >> 16);
    sum = (sum & 0xffff) + (sum >> 16);
    data[to] = byterev((~sum) & 0xffff) >> 16;
}

static int makeGratuitousArp(unsigned int packet[]) {
    packet[0] = 0xffffffff;
    packet[1] = 0xffffffff;
    packet[3] = 0x01000608;
    packet[4] = 0x04060008;
    packet[5] = 0x00000100;
    packet[7] = byterev(ipAddressOurs);
    packet[8] = 0;
    packet[9] = ((unsigned)byterev(ipAddressOurs)) << 16;
    packet[10] = ((unsigned)byterev(ipAddressOurs)) >> 16;
    for(int i = 0; i < 6; i++) {
        (packet, char[])[ 6+i] = macAddressOurs[i];
        (packet, char[])[22+i] = macAddressOurs[i];
    }
    return 42;
}

static int makeOrdinaryArp(unsigned int packet[]) {
    packet[0] = 0xffffffff;
    packet[1] = 0xffffffff;
    packet[3] = 0x01000608;
    packet[4] = 0x04060008;
    packet[5] = 0x00000200;
    packet[7] = byterev(ipAddressOurs);
    packet[8] = 0;
    packet[9] = ((unsigned)byterev(ipAddressTheirs)) << 16;
    packet[10] = ((unsigned)byterev(ipAddressTheirs)) >> 16;
    for(int i = 0; i < 6; i++) {
        (packet, char[])[ 6+i] = macAddressOurs[i];
        (packet, char[])[22+i] = macAddressOurs[i];
    }
    return 42;
}

static int makeMDNSResponse(unsigned int packet[]) {
    int k;
    packet[10] = 0x00000000;
    packet[11] = 0x00000084;
    packet[12] = 0x00000100;
    packet[13] = 0x00000100;
    k = 54;
    for(int i = 0; i < sizeof(localName); i++) {
        (packet, char[])[k++] = localName[i];
    }
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 1;
    (packet, char[])[k++] = 0x80;
    (packet, char[])[k++] = 1;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 255; // TTL2
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 4;
    (packet, char[])[k++] = ipAddressOurs >> 24;
    (packet, char[])[k++] = ipAddressOurs >> 16;
    (packet, char[])[k++] = ipAddressOurs >> 8;
    (packet, char[])[k++] = ipAddressOurs >> 0;


    for(int i = 0; i < sizeof(localName); i++) {
        (packet, char[])[k++] = localName[i];
    }
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 47;
    (packet, char[])[k++] = 0x80;
    (packet, char[])[k++] = 1;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 255; // TTL2
    (packet, char[])[k++] = 0; // data length
    (packet, char[])[k++] = 4; // data length
    (packet, char[])[k++] = 0; // Domain name
    (packet, char[])[k++] = 0;
    (packet, char[])[k++] = 1;
    (packet, char[])[k++] = 0x40;


    (packet, char[])[k] = 0x00;

    patchUDPHeader(packet, k, 0xe00000fb, 0xe914, 0xe914);
    return k;
}

int dstports[10], dstcnts =0;

void lightLed(int val) {
    int portnr = 0x00200000;
    asm("out res[%0],%1" :: "r" (portnr), "r" ((val << 3) | 1));
}

void handlePacket(unsigned int packet, int len) {
    int type = (packetBuffer[packet], short[])[6];
    if (type == 0x0608) { // ARP
        if ((packetBuffer[packet], short[])[14] == (packetBuffer[packet], short[])[19] &&
            (packetBuffer[packet], short[])[15] == (packetBuffer[packet], short[])[20]) {
            int t;
            int x = byterev(packetBuffer[packet][7]);
            if (x != ipAddressTheirs) {     // They missed DHCP and fell back to link local
                ipAddressTheirs = x;
                if (x == ipAddressOurs) {   // Bum - they grabbed our address.
                    ipAddressOurs = x+1;
                }
                lightLed(2);
            }
            t = packetBufferAlloc();
            len = makeGratuitousArp(packetBuffer[t]);
            qPut(toHost, t, len);
            return;
        }
        if ((packetBuffer[packet], short[])[20] == -1) {
            int t;
            t = packetBufferAlloc();
            len = makeOrdinaryArp(packetBuffer[t]);
            qPut(toHost, t, len);
            return;
        }

    } else if (type == 0x0008) { // IP
        int protocol = (packetBuffer[packet], unsigned char[])[23];
        if (protocol == 0x11) { // UDP
            int destPort = (packetBuffer[packet], unsigned short[])[18];
            int srcPort = (packetBuffer[packet], unsigned short[])[17];
            if (destPort == 0x4300 && srcPort == 0x4400) {          // DHCP
                processDHCPPacket(packet, len);
            } else if (destPort == 0xe914 && srcPort == 0xe914) {   // MDNS
                int flags = (packetBuffer[packet], short[])[22];
                int queries = byterev((packetBuffer[packet], short[])[23]) >> 16;
                int index = 54;
                if (flags != 0) return;
                for(int i = 0; i < queries; i++) {
                    int qType, qFlag;
                    int j = 0, matcher;
                    for(j = 0; j < sizeof(localName); j++) {
                        matcher = (packetBuffer[packet], unsigned char[])[index+j];
                        if (matcher == 0 || matcher != localName[j]) {
                            break;
                        }
                    }
                    if (matcher) {
                        do {
                            j++;
                            matcher = (packetBuffer[packet], unsigned char[])[index+j];
                        } while(matcher != 0);
                        index += 4 + j;
                        continue;
                    }
                    index += j+1;
                    if ((packetBuffer[packet], unsigned char[])[index] == 0 &&
                        (packetBuffer[packet], unsigned char[])[index+1] == 1 &&
                        (packetBuffer[packet], unsigned char[])[index+2] == 0 &&
                        (packetBuffer[packet], unsigned char[])[index+3] == 1) {
                        int t = packetBufferAlloc();
                        int len = makeMDNSResponse(packetBuffer[t]);
                        qPut(toHost, t, len);
                    }
                    index += 4;
                }
            }
        } else if (protocol == 0x6) { // TCP
            processTCPPacket(packet, len);
        }
    }
}
