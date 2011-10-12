// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

          .section .dp.bss,        "adw", @nobits
.globl packetBuffer, "a(8:a(381:ui))"
.globl packetBuffer_, "a(8:a(381:ui))"
.globl packetBuffer__, "a(8:a(381:ui))"
.type  packetBuffer, @object
.size packetBuffer, 12192
.cc_top packetBuffer.data, packetBuffer
          .align    4
packetBuffer:
packetBuffer_:
packetBuffer__:
.globl packetBuffer.globound
          .set      packetBuffer.globound,8
.globl packetBuffer_.globound
          .set      packetBuffer_.globound,8
.globl packetBuffer__.globound
          .set      packetBuffer__.globound,8
          .space    12192
.cc_bottom packetBuffer.data
          .align    4
          .section .cp.const4,     "acM", @progbits, 4
          .align    4
.LC2:
          .int      8
          .set      packetBuffer.locbound,.LC2
          .set      packetBuffer_.locbound,.LC2
          .set      packetBuffer__.locbound,.LC2
