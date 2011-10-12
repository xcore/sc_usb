#include <xclib.h>
#include <print.h>
#include "femtoTCP.h"
#include "femtoIP.h"
#include "string.h"
#include "http.h"
#include "ethernet.h"
#include "q.h"
#include "packetManager.h"

extern struct queue toHost;

int streamSequenceNumber;
int streamAckNumber;
int streamDestPortRev;
int streamSourcePortRev;

void tcpString(char s[]) {
    int t, totalShorts;
    int len = strlen(s);
    t = packetBufferAlloc();
    patchIPHeader(packetBuffer[t], 20 + 20 + len, 0, 1);
    (packetBuffer[t], unsigned short[])[17] = streamDestPortRev;
    (packetBuffer[t], unsigned short[])[18] = streamSourcePortRev;
    (packetBuffer[t], unsigned short[])[20] = byterev(streamSequenceNumber) >> 16;
    (packetBuffer[t], unsigned short[])[19] = byterev(streamSequenceNumber);
    (packetBuffer[t], unsigned short[])[22] = byterev(streamAckNumber) >> 16;
    (packetBuffer[t], unsigned short[])[21] = byterev(streamAckNumber);
    (packetBuffer[t], unsigned short[])[23] = 0x1850;
    (packetBuffer[t], unsigned short[])[24] = 1600;
    (packetBuffer[t], unsigned short[])[25] = 0;
    (packetBuffer[t], unsigned short[])[26] = 0;
    for(int i = 0; i < len; i++) {
        (packetBuffer[t], unsigned char[])[54+i] = s[i];
    }
    (packetBuffer[t], unsigned char[])[54+len] = 0;

    totalShorts = 27 + ((len+1)>>1);
    onesChecksum(0x0006 + 20 + len /* packetType + packetLength */,
                 (packetBuffer[t], unsigned short[]), 13, totalShorts - 1, 25);
    
    qPut(toHost, t, totalShorts<<1);
    streamSequenceNumber += len;
    return;
}

void processTCPPacket(unsigned int packet, int len) {
    int sourcePortRev = (packetBuffer[packet], unsigned short[])[17];
    int destPortRev = (packetBuffer[packet], unsigned short[])[18];
    int sequenceNumberRev = (packetBuffer[packet], unsigned short[])[20]<<16 |
                            (packetBuffer[packet], unsigned short[])[19];
    int ackNumberRev = (packetBuffer[packet], unsigned short[])[22]<<16 |
                       (packetBuffer[packet], unsigned short[])[21];
    int packetLength;
    int headerLength;

    streamSourcePortRev = sourcePortRev;
    streamDestPortRev = destPortRev;

    if (packetBuffer[packet][11] & 0x02000000) { // SYN
        int t;
        t = packetBufferAlloc();
        patchIPHeader(packetBuffer[t], 20 + 20, 0, 1);
        (packetBuffer[t], unsigned short[])[17] = destPortRev;
        (packetBuffer[t], unsigned short[])[18] = sourcePortRev;
        streamSequenceNumber = 0; // could be random
        (packetBuffer[t], unsigned short[])[20] = byterev(streamSequenceNumber) >> 16;
        (packetBuffer[t], unsigned short[])[19] = byterev(streamSequenceNumber);
        streamSequenceNumber++;
        streamAckNumber = byterev(sequenceNumberRev) + 1;
        (packetBuffer[t], unsigned short[])[22] = byterev(streamAckNumber) >> 16;
        (packetBuffer[t], unsigned short[])[21] = byterev(streamAckNumber);
        (packetBuffer[t], unsigned short[])[23] = 0x1250;
        (packetBuffer[t], unsigned short[])[24] = 1600;
        (packetBuffer[t], unsigned short[])[25] = 0;
        (packetBuffer[t], unsigned short[])[26] = 0;
        onesChecksum(0x0006 + 20 /* packetType + packetLength */,
                     (packetBuffer[t], unsigned short[]), 13, 26, 25);
        
        qPut(toHost, t, 54);
        return;
    }
    if (packetBuffer[packet][11] & 0x01000000) { // FIN
        return;
    }
    if (packetBuffer[packet][11] & 0x10000000) { // ACK
        ;
    }
    packetLength = byterev((packetBuffer[packet], unsigned short[])[8]) >> 16;
    headerLength = (packetBuffer[packet], unsigned char[])[46]>>2;

    packetLength -= headerLength + 20;

    streamAckNumber += packetLength;

    if (packetLength > 0) {
        if (destPortRev == 0x5000) { // HTTP
            httpProcess(packet, 34 + headerLength, packetLength);
        }
    }
    if (packetBuffer[packet][11] & 0x08000000) { // PSH
        ;
    }
}

#if 0
void patchTCPHeader(unsigned int packet[], int packetHighestByteIndex, int to) {
    int packetLength = packetHighestByteIndex - 34;


    (packet, unsigned short[])[17] = 0xe914;
    (packet, unsigned short[])[18] = 0xe914;
    (packet, unsigned short[])[19] = byterev(packetLength) >> 16;
    (packet, unsigned short[])[20] = 0; // checksum to be patched.

}
#endif
