#if 0
// Simple keyboard handler

// Import header
#include "xgc_keyboard.h"
#include "xgc_kbd_decode.h"

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
	unsigned temp;
	ps2_clock when pinseq(0x0) :> void;
	ps2_data :> temp;
    ps2_clock when pinseq(0x1) :> void;
	return temp;
}

enum {
    START_BIT = 0,
    BIT0,
    BIT1,
    BIT2,
    BIT3,
    BIT4,
    BIT5,
    BIT6,
    BIT7,
    PARITY_BIT,
    STOP_BIT
} ;

void ps2handlerInit(struct ps2state &state) {
    state.overrunErrors = 0;
    state.parityErrors = 0;
    state.stopErrors = 0;
    state.valid = 0;
    state.bits = 0;
    state.mode = START_BIT;
    state.clockValue = 1;
}

select void ps2handler(port ps2_clock, port ps2_data, struct ps2state state) {
	ps2_clock when pinseq(state.clockValue) :> void;
    if (state.clockValue == 0) { // seen rising edge
        ps2_data :> bit;
        switch(state.mode) {
        case START_BIT: 
            if (bit == 0) state.mode = BIT0;
            break;
        case BIT0:
        case BIT1:
        case BIT2:
        case BIT3:
        case BIT4:
        case BIT5:
        case BIT6:
        case BIT7:
			state.bits >>= 1;
			if (tmp) state.bits |= 0x80;
            state.mode++;
            break;
        case PARITY_BIT:
            parity = state.bits | bit<<8;
            crc(parity, 0x1, 0);
            if (parity == 1) {
                state.mode = STOP_BIT;
            } else {
                state.parityErrors++;
                state.mode = START_BIT;
            }
            break;
        case STOP_BIT: 
            if (bit == 0) {
                if (state.valid) {
                    state.overrunErrors++;
                }
                state.value = state.bits;
                state.valid = 1;
                state.mode = BIT0;
            } else {
                state.stopErrors++;
                state.mode = START_BIT;
            }
            break;
        }
		
		// Find start bit
		while ((start = read_bit( ps2_clock, ps2_data, 0))!=0);
		
		// Next 8 bits are the actual key
		for (int i=0; i<8; i++) {
			// Read bit into temp
			int tmp = read_bit( ps2_clock, ps2_data, 1);
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

    }
    state.clockValue = ~state.clockValue;
}

static char ps2lookup[0x85] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x2b, 0x35, 0x00,
    0x00, 0xe0, 0x02, 0x00, 0x39, 0x14, 0x1e, 0x00,
    0x00, 0x00, 0x1d, 0x16, 0x04, 0x1a, 0x1f, 0x00,
    0x00, 0x06, 0x1b, 0x07, 0x08, 0x21, 0x20, 0x00,
    0x00, 0x2c, 0x19, 0x09, 0x17, 0x15, 0x22, 0x00,
    0x00, 0x11, 0x05, 0x0b, 0x0a, 0x1c, 0x23, 0x00,
    0x00, 0x00, 0x10, 0x0d, 0x18, 0x24, 0x25, 0x00,
    0x00, 0x36, 0x0E, 0x0C, 0x12, 0x27, 0x26, 0x00,
    0x00, 0x37, 0x38, 0x0F, 0x33, 0x13, 0x2D, 0x00,
    0x00, 0x00, 0x34, 0x00, 0x2F, 0x2E, 0x00, 0x00,
    0xE4, 0xE5, 0x28, 0x30, 0x00, 0x31, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2A, 0x00,
    0x00, 0x59, 0x00, 0x5C, 0x5F, 0x00, 0x00, 0x00,
    0x62, 0x63, 0x5A, 0x5D, 0x5E, 0x60, 0x53, 0x54,
    0x00, 0x58, 0x5B, 0x85, 0x57, 0x61, 0x55, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x56,
};

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


        if (press_char == PS2_RELEASE) {
            released = 1;
        } else {
            switch (press_char) {
            case PS2_SHIFT:
                c <: released + 2;
                c <: 2;
                break;
            case PS2_CTRL:
                c <: released + 2;
                c <: 2;
                break;
            case PS2_EXT:
                c <: released + 2;
                c <: 2;
                break;
            default:
                if (press_char >= sizeof(ps2lookup)) {
                    printintln(press_char);
                } else {
                    c <: released;
                    c <: (int) ps2lookup[press_char];
                }
                break;
            }
            released = 0;
        }

	}
}

#endif
