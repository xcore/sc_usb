#include <xclib.h>
#include "femtoIP.h"
#include "ethernet.h"

void patchIPHeader(unsigned int packet[], int packetLength, int to, int isTCP) {
    if (to == 0) {
        to = ipAddressTheirs;
    }
    if ((to & 0xff000000) == 0xe0000000) {
        packet[0] = 0x005e0001;
        packet[1] = 0x2200fb00;
    } else {
        for(int i = 0; i < 6; i++) {
            (packet, char[])[i] = macAddressTheirs[i];
        }
    }
    for(int i = 0; i < 6; i++) {
        (packet, char[])[ 6+i] = macAddressOurs[i];
    }
    packet[3] = 0x00450008;
    packet[4] = 0xff630000 | byterev(packetLength) >> 16;
    packet[5] = 0x11010000;
    (packet, unsigned char[])[23] = isTCP ? 0x06 : 0x11;
    (packet, unsigned short[])[12] = 0;
    (packet, unsigned short[])[13] = ((unsigned)byterev(ipAddressOurs));
    (packet, unsigned short[])[14] = ((unsigned)byterev(ipAddressOurs))>> 16;
    (packet, unsigned short[])[15] = ((unsigned)byterev(to));
    (packet, unsigned short[])[16] = ((unsigned)byterev(to))>> 16;
    onesChecksum(0, (packet, unsigned short[]), 7, 16, 12);
}
