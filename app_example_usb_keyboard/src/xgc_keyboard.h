#ifndef KEYBOARD_H_
#define KEYBOARD_H_

// Provide a simple keyboard handler

// Include Xmos
#include <platform.h>
#include <print.h>
#include <xs1.h>

// Keyboard will provide a channel of characters
extern void keyboard(chanend chars, streaming chanend req);
extern unsigned char decode_press(unsigned char press);
extern unsigned char decode_shift_press(unsigned char press);
extern void graphics_add_text(char chs[]);
extern void keyboard_ps2_interface(chanend c);

// Some useful defs
#define KEY_ENTER (0x0000000D)
#define KEY_BACK (0x00000008)
#define KEY_DEL (0x8000002E)
#define KEY_ESC (0x0000001B)
#define KEY_UP (0x80000038)
#define KEY_DOWN (0x80000032)
#define KEY_LEFT (0x80000034)
#define KEY_RIGHT (0x80000036)
#define KEY_TAB (0x00000009)
#define KEY_SPACE (0x00000020)

#endif /*KEYBOARD_H_*/

