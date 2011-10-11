#include <xclib.h>
#include "femtoIP.h"
#include "ethernet.h"

void patchIPHeader(unsigned int packet[], int packetLength, int to) {
    packet[0] = 0x005e0001;
    packet[1] = 0x2200fb00;
    for(int i = 0; i < 6; i++) {
        (packet, char[])[ 6+i] = macAddressOurs[i];
    }
    packet[3] = 0x00450008;
    packet[4] = 0xff630000 | (packetLength) << 8;
    packet[5] = 0x11010000;
    packet[6] = ((unsigned)byterev(ipAddressOurs)) << 16 | 0x0000;
    packet[7] = ((unsigned)byterev(ipAddressOurs)) >> 16 | 0x00e00000;
    (packet, unsigned short[])[16] = 0xfb00;
    onesChecksum(0, (packet, unsigned short[]), 7, 16, 12);
}
