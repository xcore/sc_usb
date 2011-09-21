// Simple keyboard handler

// Import header
#include "xgc_keyboard.h"
#include "xgc_kbd_decode.h"

// Global vars
#define BUFF_MAX 16
static int buffer[BUFF_MAX+1];
static unsigned buff_start=0;		// Read at start
static unsigned buff_end=0;		// Write at end
static int has_req=0;

// Define ports
on stdcore[0]: port ps2_clock = XS1_PORT_1A;
on stdcore[0]: port ps2_data = XS1_PORT_1L;

// Validate parity, adapted from Roger's code on X(MOS)Linkers
int validate_odd_parity(char press, int bit) {
	unsigned char intermediate = press;
	unsigned char bitc = (char)bit;
	
	intermediate = (intermediate >> 4) ^ intermediate;
	intermediate = (intermediate >> 2) ^ intermediate;
	intermediate = ((intermediate >> 1) ^ intermediate) & 0x01 ;
    
    if (intermediate!=bitc) return 1; else return 0;
}

// Look for falling edge, wait a short period read data, look for rising edge and return
int read_bit(port ps2_clock, port ps2_data, int timeout) {
	int not_done=1;
	unsigned temp;
	unsigned tme;
	timer t;
	
	t :> tme;
	
	while (not_done) {
		select {
			case ps2_clock when pinseq(0x0) :> void:
				not_done=0;
				break;
			case timeout => t when timerafter(tme+200000) :> void:
				return -1;
		}
	}
	
	ps2_data :> temp;
	
	select {
		case ps2_clock when pinseq(0x1) :> void:
			break;
		case t when timerafter(tme+200000) :> void:
			return -1;
	}

	return temp;
}

char ps2lookup[256] = {
    0,0,0,0,0,0,0,0,0,0,0,0,0,
    0x2b,0x35,0,0,0xe0,0x02,0,0x39,0x14,0x1e,0,0,0,0x1d,0x16,0x04,0x1a,0x1f,0,0,

    0x06,0x1b,0x7,8,0x21,0x20,0,0,0x2c,0x19,9,0x17,0x15,0x22,0,0,0x11,0x5,0xb,0xa,0x1c,0x23,0,0,0,0x10,0x0d,0x18,0x24,0x25,
 0,
 0,
 0x36,
0x0E,
0x0C,
0x12,
0x27,
0x26,
0x00,
0x00,
0x37,
0x38,
0x0F,
0x33,
0x13,
0x2D,
0x00,
0x00,
0x00,
0x34,
0x00,
0x2F,
0x2E,
0x00,
0x00,
0xE4,
0xE5,
0x28,
0x30,
0x00,
0x31,
0x00,
0x00,
0x00,
0x00,
0x00,
0x00,
0x00,
0x00,
0x2A,
0x00,
0x00,
0x59,
0x00,
0x5C,
0x5F,
0x00,
0x00,
0x00,
0x62,
0x63,
0x5A,
0x5D,
0x5E,
0x60,
0x53,
0x54,
0x00,
0x58,
0x5B,
0x85,
0x57,
0x61,
0x55,
0x00,
0x00,
0x00,
0x00,
0x00,
0x56,
};

// Main function
extern void keyboard_ps2_interface(chanend c) {
	// Bits for control
	unsigned int start;
	unsigned int parity;
	unsigned int stop;
	
	// Press will contain the scancode, char the decoded character
	unsigned int press;
	unsigned int press_char;
	
	// This process will maintain the state of shift and control
	unsigned int shifton=0;	// Shift on?
	unsigned int ctrlon=0; // Ctrl on?
	unsigned int released=0; // Was previous char a release char?
	unsigned int extended=0; // Was previous char the extended keyboard character E0?
	unsigned int capslock=0;

	// Loop
	while (1) {
		// Reset
		press=0;
		press_char=0;
		
		// Find start bit
		while ((start = read_bit( ps2_clock, ps2_data, 0))!=0);
		
		// Next 8 bits are the actual key
		for (int i=0; i<8; i++) {
			// Read bit into temp
			int tmp = read_bit( ps2_clock, ps2_data, 1);
			press_char >>= 1;
			if (tmp) press_char = press_char | 0x80;
		}

		// Next is parity and stop
		parity = read_bit( ps2_clock, ps2_data, 1);
		stop = read_bit( ps2_clock, ps2_data, 1);

		// Check start bit
		if (start) printstr("wrong start");
		
		// Verify parity bit
		if(!validate_odd_parity(press_char, parity)) printstr("wrong parity");
		
		// Check stop bit
		if (!stop) printstr("wrong stop");
//        printintln(press_char);


#if 0
		// Decode key
		if (shifton) {
			press_char = decode_shift_press(press_char);
		} else {
			press_char = decode_press(press_char);
		}
		
		// Is this char a release?
		if (press_char==PS2_RELEASE) {
			released=1;
			extended=0;
		} else {
			if (press_char==PS2_SHIFT) {
				// Is this char a shift?
				if (released==1) shifton=0; else shifton=1;
				// Not released!
				released=0;
			} else if (press_char==PS2_CTRL) {
				// Is this char a control?
				if (released==1) ctrlon=0; else ctrlon=1;
				// Not released!
				released=0;
			} else if (press_char==PS2_EXT) {
				// Log that the next one is an extended key
				// Released again to ignore 2 key presses
				extended = 1;
			} else if (press_char==PS2_CAPS){
				// Set
				capslock++;
				
				// Check
				if (capslock==4) capslock=0;
			}else {
				if ((released!=1) && (press_char!=PS2_NOTAKEY)) {
					
					// If extended, set the topmost bit
					if (extended) {
						press_char = press_char | 0x80000000;
					}
					
					// If control is on, set upper bits
					if (ctrlon) {
						press_char = press_char | 0x40000000;
					}

					// If caps
					if (capslock==2) {
						if ((press_char>=0x61) && (press_char<=0x7A)) {
							press_char -= 32;
						}
					}
					
					// Store in buffer
                    c <: (int) press_char;
				}
				// Not released!
				released=0;
			}
		}
#else
		if (press_char==PS2_RELEASE) {
			released=1;
			extended=0;
        } else if (press_char==PS2_SHIFT) {
            // Is this char a shift?
            if (released==1) shifton=0; else shifton=1;
            // Not released!
            released=0;
        } else if (press_char==PS2_CTRL) {
            // Is this char a control?
            if (released==1) ctrlon=0; else ctrlon=1;
            // Not released!
            released=0;
        } else if (press_char==PS2_EXT) {
            // Log that the next one is an extended key
            // Released again to ignore 2 key presses
            extended = 1;
        } else if (press_char==PS2_CAPS){
            // Set
            capslock++;
			
            // Check
            if (capslock==4) capslock=0;
        } else if (!released) {
//        printintln(press_char);
            c <: (shifton ? 0x02 : 0x00) | (ctrlon ? 0x01 : 0x00);
            if (press_char > sizeof( ps2lookup)) {
                c <: (int) press_char;                
            } else {
                c <: (int) ps2lookup[press_char];
            }
        } else {
            released = 0;
        }
#endif

	}
}

void tests(chanend c) {
  c <: 13;
}

void testr(chanend c) {
  int i;
  c :> i;
  printintln(i);
}

