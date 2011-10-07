#define NULL_PACKET 0xFFFFFFFF
#define NUM_PACKETS 8

// These are all the same...
extern unsigned int packetBuffer[NUM_PACKETS][1516/sizeof(int)+2];
extern unsigned int packetBuffer_[NUM_PACKETS][1516/sizeof(int)+2];
extern unsigned int packetBuffer__[NUM_PACKETS][1516/sizeof(int)+2];

extern void packetBufferInit(void);
extern int  packetBufferAlloc(void);
extern void packetBufferFree(int index);

extern void packetCopyInto(int packetNum, char from[], int len);
