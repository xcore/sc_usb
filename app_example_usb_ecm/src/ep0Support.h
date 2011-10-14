extern unsigned char hiSpdDesc[];
extern unsigned char hiSpdConfDesc[];
extern unsigned char fullSpdDesc[];
extern unsigned char fullSpdConfDesc[];
extern unsigned char stringDescriptors[][40];
extern unsigned int sizeofHiSpdDesc;
extern unsigned int sizeofHiSpdConfDesc;
extern unsigned int sizeofFullSpdDesc;
extern unsigned int sizeofFullSpdConfDesc;

void ep0IN(unsigned char data[], int length, int maxLength);
void ep0INack();
void ep0HandleOUTPacket(unsigned int buffer[], int len);
void ep0HandleINPacket();
void ep0Init(XUD_ep c);

extern void ep0User(SetupPacket &sp, unsigned char buffer[]);
