//#include "ethernet.h"
#include <print.h>
#include <string.h>
#include "femtoTCP.h"
#include "q.h"
#include "packetManager.h"

#define STRLEN 16

void httpProcess(int packet, int charOffset, int packetLength) {
    char string[STRLEN];
    for(int i = 0; i < packetLength && i < STRLEN; i++) {
        string[i] = (packetBuffer[packet], unsigned char[])[charOffset + i];
    }
    if (strncmp(string, "GET ", 4) == 0) {
        tcpString("HTTP/1.0 200 OK\r\nContent-Length: 7\r\n\r\nHello\r\n");
    } else {
        tcpString("HTTP/1.0 404 NOT FOUND\r\n\r\n");
    }
//    printstrln(string);
}

