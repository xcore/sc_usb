#include <xs1.h>
    
    .globl setINHandler
    .globl setINHandler.nstackwords
    .linkset setINHandler.nstackwords, 0

setINHandler:
    ldap  r11, IN_interrupt
    setc  res[r0], XS1_SETC_IE_MODE_INTERRUPT
    setv  res[r0], r11
    add   r11, r1, 0
    setev res[r0], r11
    eeu   res[r0]

    retsp 0

    .globl enableInterrupts
    .globl enableInterrupts.nstackwords
    .linkset enableInterrupts.nstackwords, 0

    .section .dp.data,       "adw", @progbits
    .word 0, 0, 0, 0, 0, 0
kstack:
    .word 0
    .text
    
enableInterrupts:
    ldaw  r11, dp[kstack]
    stw   sp, dp[kstack]
    set   sp, r11
    krestsp 0
    setsr 2
    retsp 0
    
IN_interrupt:
    kentsp 5
    stw   r11, sp[0]
    get   r11, ed
    stw   r0, sp[1]
    ldw   r0, r11[5]    // Pointer
    stw   r1, sp[2]
    ldw   r1, r11[3]    // Len
    ldw   r11, r11[2]
    stw   r2, sp[3]
    ldw   r2, r0[r1]
    bf    r1, done
loop:   
    add   r1, r1, 1      // len++
    out   res[r11], r2   // Output word of data
    ldw   r2, r0[r1]     // Get next data entry
    bf    r1, loop
done:
    outct res[r11], 0     // Signify end of stream.
    out   res[r11], r2    // Output word of data (not all bits are used)
    in    r2, res[r11]    // Discard word that caused interrupt
    in    r2, res[r11]    // Discard word that acknowledges successful transfer

    get   r11, ed

    ldw r0, r11[4]
    ldc r1, 0x88
    xor r0, r0, r1
    stw r0, r11[4]
 
    ldw r2, r11[2]
    out res[r2], r0 

    /* Output tail */
    outct res[r2], 0

    stw r11, r11[5]             // Any old pointer

    ldc r0, 0
    stw r0, r11[3]              // len

    ldw r0, r11[0]
    ldw r1, r11[1]

    stw r1, r0[0]
    
    ldw   r2, sp[3]
    ldw   r1, sp[2]
    ldw   r0, sp[1]
    ldw   r11, sp[0]
    krestsp 5
    kret
