#include "packetManager.h"
#include "ethernet.h"
#include <xclib.h>
#include "q.h"
#include <print.h>
#include <stdio.h>
#include <assert.h>

extern struct queue toHost;

int ipAddressOurs;
int ipAddressTheirs;
char macAddressOurs[6];
char macAddressTheirs[6] = {0x00, 0x22, 0x97, 0x08, 0xA0, 0x03};

unsigned char localName[] = "\004blah\005local";
unsigned char localName2[] = "\004host\005local";

static    unsigned sum = 0;

int verbose = 0;

void preOnesChecksum(unsigned short data[], int from, int len) {
    for(int i = 0; i < len; i++) {
        sum += byterev(data[from + i]) >> 16;
    }
}

void onesChecksum(unsigned short data[], int from, int len, int to) {
    for(int i = 0; i < len; i++) {
        sum += byterev(data[from + i]) >> 16;
    }
    sum = (sum & 0xffff) + (sum >> 16);
    sum = (sum & 0xffff) + (sum >> 16);
    data[to] = byterev((~sum) & 0xffff) >> 16;
    sum = 0;
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
    static int first = 0;
    unsigned short fake[2];

    packet[0] = 0x005e0001;
    packet[1] = 0x2200fb00;
    for(int i = 0; i < 6; i++) {
        (packet, char[])[ 6+i] = macAddressOurs[i];
    }
    packet[3] = 0x00450008;
    packet[4] = 0xff630000 | (54 + sizeof(localName)) << 8;
    packet[5] = 0x11010000;
    packet[6] = ((unsigned)byterev(ipAddressOurs)) << 16 | 0x0000;
    packet[7] = ((unsigned)byterev(ipAddressOurs)) >> 16 | 0x00e00000;
    packet[8] = 0xe914fb00;
    packet[9] = 0x0000e914 | (34 + sizeof(localName)) << 24;
    packet[10] = 0x00000000;
    packet[11] = 0x00000084;
    packet[12] = 0x00000100;
    packet[13] = 0x00000000;
    for(int i = 0; i < sizeof(localName); i++) {
        (packet, char[])[ 54+i] = localName[i];
    }
    k = 54 + sizeof(localName);
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

    (packet, char[])[k] = 0x00;

    onesChecksum((packet, unsigned short[]), 7, 10, 12);
    preOnesChecksum((packet, unsigned short[]), 13, 4);
    fake[0] = 0x1100;
    fake[1] = (packet, unsigned short[])[19];
    preOnesChecksum(fake, 0, 2);
    onesChecksum((packet, unsigned short[]), 17, ((k+1)>>1)-17, 20);
    return k;
}
int dstports[10], dstcnts =0;

void handlePacket(unsigned int packet, int len) {
    int type = (packetBuffer[packet], short[])[6];
    if (type == 0x0608) { // ARP
        if ((packetBuffer[packet], short[])[14] == (packetBuffer[packet], short[])[19] &&
            (packetBuffer[packet], short[])[15] == (packetBuffer[packet], short[])[20]) {
            int t;
            ipAddressTheirs = byterev(packetBuffer[packet][7]);
            t = (ipAddressTheirs & 0xffff0000) |
                (((ipAddressTheirs & 0xffff)-0x100 + 1) % 0xfe00+ 0x100);
            asm("stw %0, dp[ipAddressOurs]" :: "r" (t));
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
            if (destPort == 0xe914 && srcPort == 0xe914) {   // MDNS
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
        }
    }
}
