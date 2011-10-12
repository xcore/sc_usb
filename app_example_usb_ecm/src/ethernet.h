extern int ipAddressOurs;
extern int ipAddressTheirs;
extern char macAddressOurs[6];
extern char macAddressTheirs[6];

extern void handlePacket(unsigned int packet, int len);

extern void onesChecksum(unsigned int startsum, unsigned short data[], int begin, int end, int to);

void lightLed(int val);
