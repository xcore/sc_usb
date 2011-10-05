// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
    
    .globl setOUTHandler
    .globl setOUTHandler.nstackwords
    .linkset setOUTHandler.nstackwords, 0
    
    .globl setINHandler
    .globl setINHandler.nstackwords
    .linkset setINHandler.nstackwords, 0

setOUTHandler:
    ldap  r11, OUT_interrupt
    bu    setHandler
setINHandler:
    ldap  r11, IN_interrupt
setHandler: 
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
chanend:
    .word 0
    .text
    
enableInterrupts:
    setd  res[r0], r0            // TODO: KLUDGE
    stw   r0, dp[chanend]
    ldaw  r11, dp[kstack]
    stw   sp, dp[kstack]
    set   sp, r11
    krestsp 0
    setsr 2
    retsp 0
    
IN_interrupt:
    kentsp 5
    stw   r11, sp[0]
    stw   r0, sp[1]
    get   r11, ed
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
    bt    r1, loop
done:
    outct res[r11], 0     // Signify end of stream.
    out   res[r11], r2    // Output word of data (not all bits are used)
    in    r2, res[r11]    // Discard word that caused interrupt
    in    r2, res[r11]    // Discard word that acknowledges successful transfer

    get   r11, ed

    ldw r0, r11[0]
    ldc r1, 0

    stw r1, r0[0]

    ldw  r0, dp[chanend]
    outt res[r0], r11
    
    ldw   r2, sp[3]
    ldw   r1, sp[2]
    ldw   r0, sp[1]
    ldw   r11, sp[0]
    krestsp 5
    kret


    
OUT_interrupt:
    kentsp 5
    stw   r11, sp[0]
    stw   r0, sp[1]
    get   r11, ed
    ldw   r0, r11[5]    // Pointer
    stw   r1, sp[2]
    ldw   r11, r11[2]
    in    r1, res[r11]    // Discard word that caused interrupt
    testct r1, res[r11]
    bt    r1, doneOUT
loopOUT:
    in    r1, res[r11]
    stw   r1, r0[0]
    add   r0, r0, 4      // len++
    testct r1, res[r11]
    bf    r1, loopOUT
doneOUT:
    inct  r1, res[r11]     // Tail count
    get   r11, ed
    stw   r0, r11[5]
    stw   r1, r11[3]

    ldw r0, r11[0]
    ldc r1, 0

    stw r1, r0[0]      

    ldw  r0, dp[chanend]
    outt res[r0], r11
    
    ldw   r1, sp[2]
    ldw   r0, sp[1]
    ldw   r11, sp[0]
    krestsp 5
    kret



    