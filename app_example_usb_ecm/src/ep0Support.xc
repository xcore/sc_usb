// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/** 
 * @file       DescriptorRequests.xc
 * @brief      DescriptorRequests implementation
 * @author     Ross Owen, XMOS Limited
 * @version    1.0
 */

#include <safestring.h>
#include <print.h>
#include <xs1.h>

#include "xud.h"     /* XUD Functions and defines */
#include "usb.h"     /* Defines related to the USB 2.0 Spec */
//#include "ep0Descriptors.h"
//#include "ep0.h"
#include "ep0Support.h"
#include "xud_interrupt_driven.h"

extern int min(int a, int b);

#pragma unsafe arrays
static int ep0DescriptorRequests(uint8 bufferIn[8], uint8 buffer[], SetupPacket &sp)
{
    int datalength;
    int stringID = 0;

    /* Parse data buffer end populate SetupPacket struct */
    XUD_ParseSetupPacket(bufferIn, sp);

    if (sp.bmRequestType.Recipient != BM_REQTYPE_RECIP_DEV) return 1;
    if (sp.bmRequestType.Type != BM_REQTYPE_TYPE_STANDARD) return 1;
    if (sp.bRequest != GET_DESCRIPTOR) return 1;
              
    /* Inspect for which descriptor is required (high byte of wValue) */
    switch(sp.wValue & 0xff00)
    {
        /* Device descriptor */
    case WVALUE_GETDESC_DEV:              
        /* Do get request (send descriptor then 0 length status stage) */
        ep0IN(hiSpdDesc, sizeofHiSpdDesc, sp.wLength); 
        return 0;

        /* Configuration Descriptor */
    case WVALUE_GETDESC_CONFIG:
        /* Do get request (send descriptor then 0 length status stage) */
        ep0IN( hiSpdConfDesc, sizeofHiSpdConfDesc, sp.wLength); 
        return 0;

        /* Device qualifier descriptor */
    case WVALUE_GETDESC_DEVQUAL:
        /* Do get request (send descriptor then 0 length status stage) */
        ep0IN(fullSpdDesc, sizeofFullSpdDesc, sp.wLength); 
        return 0;

        /* Other Speed Configiration Descriptor */
    case WVALUE_GETDESC_OSPEED_CFG:
        ep0IN( fullSpdConfDesc, sizeofFullSpdConfDesc, sp.wLength);
        return 0;
             
        /* String Descriptor */ 
    case WVALUE_GETDESC_STRING:
        /* Set descriptor type */
        buffer[1] = STRING;

        /* Send the string that was requested (low byte of wValue) */
        /* First, generate valid descriptor from string */
        /* TODO Bounds check */
        stringID = sp.wValue & 0xff;

        /* Microsoft OS String special case, send product ID string */
        if ( sp.wValue == 0x03ee)
        {
            stringID = 2;
        }

        datalength = safestrlen(stringDescriptors[ stringID ] );
                
        /* String 0 (LangIDs) is a special case*/ 
        if( stringID == 0 )
        {
            buffer[0] = datalength + 2;
            if( sp.wLength < datalength + 2 )
                datalength = sp.wLength - 2; 
                        
            for(int i = 0; i < datalength; i += 1 )
            {
                buffer[i+2] = stringDescriptors[stringID][i];
            }
        }
        else
        { 
            /* Datalength *= 2 due to unicode */
            datalength <<= 1;
                      
            /* Set data length in descriptor (+2 due to 2 byte datalength)*/
            buffer[0] = datalength + 2;

            if(sp.wLength < datalength + 2)
                datalength = sp.wLength - 2; 
                        
            /* Add zero bytes for unicode.. */
            for(int i = 0; i < datalength; i+=2)
            {
                buffer[i+2] = stringDescriptors[stringID][i>>1];
                buffer[i+3] = 0;
            }
                                       
        }
                                    
        /* Send back string */

        ep0IN(buffer, datalength + 2, sp.wLength); 
        return 0;
    default:
        return 1;
    }
}




enum {WAITING = 0, WAITFORACK, MOREDATAFORIN, SENDBLANK};

static int state = WAITING;
static int moreDataLength, moreDataPtr;
static int finalState;
static unsigned char ep0Buffer[100];

static XUD_ep c_ep_in;

#define MAX 64

void ep0Init(XUD_ep c) {
    c_ep_in = c;
}

void ep0IN(uint8 data[], int length, int maxLength) {
    finalState = WAITFORACK;
    if (length > maxLength) {
        if (length % 64 == 0) {
            finalState = SENDBLANK;
        }
        length = maxLength;       // truncate descriptor to maximum requested length.
    }
    if (length <= MAX) {
        XUD_provide_IN_buffer(c_ep_in, PIDn_DATA1, (data, unsigned int[]), length);
        state = finalState;
    } else {
        XUD_provide_IN_buffer(c_ep_in, PIDn_DATA1, (data, unsigned int[]), MAX);
        moreDataLength = length - MAX;
        asm("sub %0,%1,%2" : "=r" (moreDataPtr) : "r" (data), "r" (MAX));
        state = MOREDATAFORIN;
    }
}

void ep0INack() {
    unsigned int mdata[1];
    XUD_provide_IN_buffer(c_ep_in, PIDn_DATA1, mdata, 0);
}

void ep0HandleOUTPacket(unsigned int buffer[], int len) {
    int retVal;
    SetupPacket sp;
    switch(state) {
    case WAITING:
        retVal = ep0DescriptorRequests((buffer, unsigned char[]), ep0Buffer, sp);
        if (retVal == 1) {
            ep0User(sp ,ep0Buffer);
        }
        break;
    case WAITFORACK:
        state = WAITING;
        break;
    }
}

void ep0HandleINPacket() {
    if (state == MOREDATAFORIN) {
        if (moreDataLength < MAX) {
            XUD_provide_IN_buffer__(c_ep_in, 0, moreDataPtr, moreDataLength);
            state = finalState;
        } else {
            XUD_provide_IN_buffer__(c_ep_in, 0, moreDataPtr, MAX);
            moreDataLength -= MAX;
            moreDataPtr -= MAX;
        }
    } else if (state == SENDBLANK) {
        unsigned int mdata[1];
        XUD_provide_IN_buffer(c_ep_in, 0, mdata, 0);
        state = WAITFORACK;
    } else {
        ; // done with packet should not happen
//        printstrln("HELP\n");
    }
}
