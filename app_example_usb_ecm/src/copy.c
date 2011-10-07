#include "packetManager.h"
#include "stdlib.h"

void packetCopyInto(int packetNum, char *from, int len) {
    memcpy(packetBuffer[packetNum], from, len);
}
