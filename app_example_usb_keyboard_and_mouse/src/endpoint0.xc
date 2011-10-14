// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*
 * @file endpoint0.xc
 * @brief Implements endpoint zero for an HID device.
 * @author Ross Owen, XMOS Semiconductor
 * @version 0.1
 */

#include <xs1.h>
#include <print.h>
#include "xud.h"
#include "usb.h"
#include "hid.h"
#include "DescriptorRequests.h"

// This devices Device Descriptor:
static unsigned char hiSpdDesc[] = { 
  0x12,                /* 0  bLength */
  0x01,                /* 1  bdescriptorType */ 
  0x00,                /* 2  bcdUSB */ 
  0x02,                /* 3  bcdUSB */ 
  0x00,                /* 4  bDeviceClass */ 
  0x00,                /* 5  bDeviceSubClass */ 
  0x00,                /* 6  bDeviceProtocol */ 
  0x40,                /* 7  bMaxPacketSize */ 
  0xb1,                /* 8  idVendor */ 
  0x20,                /* 9  idVendor */ 
  0x01,                /* 10 idProduct */ 
  0x01,                /* 11 idProduct */ 
  0x10,                /* 12 bcdDevice */
  0x00,                /* 13 bcdDevice */
  0x01,                /* 14 iManufacturer */
  0x02,                /* 15 iProduct */
  0x00,                /* 16 iSerialNumber */
  0x01                 /* 17 bNumConfigurations */
};

unsigned char fullSpdDesc[] =
{ 
    0x0a,              /* 0  bLength */
    DEVICE_QUALIFIER,  /* 1  bDescriptorType */ 
    0x00,              /* 2  bcdUSB */
    0x02,              /* 3  bcdUSB */ 
    0x00,              /* 4  bDeviceClass */ 
    0x00,              /* 5  bDeviceSubClass */ 
    0x00,              /* 6  bDeviceProtocol */ 
    0x40,              /* 7  bMaxPacketSize */ 
    0x01,              /* 8  bNumConfigurations */ 
    0x00               /* 9  bReserved  */ 
};


static unsigned char hiSpdConfDesc[] = {  
  0x09,                /* 0  bLength */ 
  0x02,                /* 1  bDescriptortype */ 
  0x22, 0x00,          /* 2  wTotalLength */ 
  0x01,                /* 4  bNumInterfaces */ 
  0x01,                /* 5  bConfigurationValue */
  0x04,                /* 6  iConfiguration */
  0x80,                /* 7  bmAttributes */ 
  0xC8,                /* 8  bMaxPower */
  
  0x09,                /* 0  bLength */
  0x04,                /* 1  bDescriptorType */ 
  0x00,                /* 2  bInterfacecNumber */
  0x00,                /* 3  bAlternateSetting */
  0x01,                /* 4: bNumEndpoints */
  0x03,                /* 5: bInterfaceClass */ 
  0x01,                /* 6: bInterfaceSubClass */ 
  0x02,                /* 7: bInterfaceProtocol*/ 
  0x00,                /* 8  iInterface */ 
  
  0x09,                /* 0  bLength */ 
  0x21,                /* 1  bDescriptorType (HID) */ 
  0x10,                /* 2  bcdHID */ 
  0x01,                /* 3  bcdHID */ 
  0x00,                /* 4  bCountryCode */ 
  0x01,                /* 5  bNumDescriptors */ 
  0x22,                /* 6  bDescriptorType[0] (Report) */ 
  0x8C,                /* 7  wDescriptorLength */ 
  0x00,                /* 8  wDescriptorLength */ 
  
  0x07,                /* 0  bLength */ 
  0x05,                /* 1  bDescriptorType */ 
  0x81,                /* 2  bEndpointAddress */ 
  0x03,                /* 3  bmAttributes */ 
  0x40,                /* 4  wMaxPacketSize */ 
  0x00,                /* 5  wMaxPacketSize */ 
  0x01                 /* 6  bInterval */ 
}; 


unsigned char fullSpdConfDesc[] =
{
    0x09,              /* 0  bLength */
    OTHER_SPEED_CONFIGURATION,      /* 1  bDescriptorType */
    0x12,              /* 2  wTotalLength */
    0x00,              /* 3  wTotalLength */
    0x01,              /* 4  bNumInterface: Number of interfaces*/
    0x00,              /* 5  bConfigurationValue */
    0x00,              /* 6  iConfiguration */
    0x80,              /* 7  bmAttributes */
    0xC8,              /* 8  bMaxPower */

    0x09,              /* 0 bLength */
    0x04,              /* 1 bDescriptorType */
    0x00,              /* 2 bInterfaceNumber */
    0x00,              /* 3 bAlternateSetting */
    0x00,              /* 4 bNumEndpoints */
    0x00,              /* 5 bInterfaceClass */
    0x00,              /* 6 bInterfaceSubclass */
    0x00,              /* 7 bInterfaceProtocol */
    0x00,              /* 8 iInterface */

};


static unsigned char stringDescriptors[][40] = {
	"\009\004",                    // Language string
  	"XMOS",				           // iManufacturer 
 	"Example Mouse" 			   // iProduct
 	"" 			                   // unUsed
 	"Config"   			           // iConfiguration
};

static unsigned char hidReportDescriptor[] = 
{
   0x05, 0x01, // Usage page (desktop)
   0x09, 0x02, // Usage (mouse)
   0xA1, 0x01, // Collection (app)
     0x85, 0x01,
     0x05, 0x09, // Usage page (buttons)
     0x19, 0x01, 
     0x29, 0x03,
     0x15, 0x00,  // Logical min (0)
     0x25, 0x01,  // Logical max (1)
     0x95, 0x03,  // Report count (3)
     0x75, 0x01,  // Report size (1)
     0x81, 0x02,  // Input (Data, Absolute)
     0x95, 0x01,  // Report count (1)
     0x75, 0x05,  // Report size (5)
     0x81, 0x03,  // Input (Absolute, Constant)
     0x05, 0x01,  // Usage page (desktop)
     0x09, 0x01, // Usage (pointer)
     0xA1, 0x00, // Collection (phys)
       0x09, 0x30,  // Usage (x)
       0x09, 0x31,  // Usage (y)
       0x15, 0x81,  // Logical min (-127)
       0x25, 0x7F,  // Logical max (127)
       0x75, 0x08,  // Report size (8)
       0x95, 0x02,  // Report count (2)
       0x81, 0x06,  // Input (Data, Relative)
     0xC0,        // End collection
     0x09, 0x38,  // Usage (Wheel)
     0x95, 0x01,  // Report count (1)
     0x81, 0x06,  // Input (Data, Relative)
     0x09, 0x3C,  // Usage (Motion Wakeup)
     0x15, 0x00,  // Logical min (0)
     0x25, 0x01,  // Logical max (1)
     0x75, 0x01,  // Report size (1)
     0x95, 0x01,  // Report count (1)
     0xB1, 0x22,  // Feature (No preferred, Variable)
     0x95, 0x07,  // Report count (7)
     0xB1, 0x01,  // Feature (Constant)
   0xC0,        // End collection

   0x05, 0x01, // Usage page (desktop)
   0x09, 0x06,
   0xA1, 0x01,
      0x85, 0x02,
      0x05, 0x07,
      0x19, 0xE0,
      0x29, 0xE7,
      0x15, 0x00, 0x25, 0x01, 0x75, 0x01, 0x95, 0x08, 0x81, 0x02, 0x95, 0x01, 0x75, 0x08, 0x81, 0x01, 0x95, 0x05, 0x75, 0x01, 0x05, 0x08, 0x19, 0x01, 0x29, 0x05, 0x91, 0x02, 0x95, 0x01, 0x75, 0x03, 0x91, 0x01, 0x95, 0x06, 0x75, 0x08, 0x15, 0x00, 0x25, 0x65, 0x05, 0x07, 0x19, 0x00, 0x29, 0x65, 0x81, 0x00,
   0xC0
};

extern int min(int a, int b);

int HidInterfaceClassRequests(XUD_ep c_ep0_out, XUD_ep c_ep0_in, SetupPacket sp)
{
    unsigned char buffer[64];
    unsigned tmp, tmp2;
    // Recipient: Interface
    // NOTE: CLASS SPECIFIC REQUESTS
    switch(sp.bRequest )
    { 
        case GET_REPORT:        /* Mandatory. Allows sending of report over control pipe */
            /* Send back a hid report - note the use of asm due to shared mem */
            asm("ldaw %0, dp[reportBuffer]": "=r"(tmp));
            asm("ldw %0, %1[0]": "=r"(tmp2) : "r"(tmp));
            (buffer, unsigned[])[0] = tmp2;

            return XUD_DoGetRequest(c_ep0_out, c_ep0_in, buffer, 4, sp.wLength );
            break;

        case GET_IDLE:
            // TODO
            break;

        case GET_PROTOCOL:      /* Required only for boot devices */
            //TODO
            break;

         case SET_REPORT: 
            // TODO     
            XUD_GetBuffer(c_ep0_out, buffer);
            return XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 0, PIDn_DATA1);
            break;

        case SET_IDLE:      
            // TODO
            return XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 0, PIDn_DATA1);
            break;
            
        case SET_PROTOCOL:      /* Required only for boot devices */
            // TODO       
            return XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 0, PIDn_DATA1);
            break;
            
        default:
            /* Error case */
            break;
    }

    return 0;
}


void Endpoint0( chanend chan_ep0_out, chanend chan_ep0_in)
{
    unsigned char buffer[1024];
    SetupPacket sp;
    unsigned int current_config = 0;
    
    XUD_ep c_ep0_out = XUD_Init_Ep(chan_ep0_out);
    XUD_ep c_ep0_in  = XUD_Init_Ep(chan_ep0_in);
    
    while(1)
    {
        /* Do standard enumeration requests */ 
        int retVal = 0;

        retVal = DescriptorRequests(c_ep0_out, c_ep0_in, hiSpdDesc, sizeof(hiSpdDesc), 
            hiSpdConfDesc, sizeof(hiSpdConfDesc), fullSpdDesc, sizeof(fullSpdDesc), 
            fullSpdConfDesc, sizeof(fullSpdConfDesc), stringDescriptors, sp);
        
        if (retVal)
        {
            /* Request not covered by XUD_DoEnumReqs() so decode ourselves */
            switch(sp.bmRequestType.Type)
            {
                /* Class request */
                case BM_REQTYPE_TYPE_CLASS:
                    switch(sp.bmRequestType.Recipient)
                    {
                        case BM_REQTYPE_RECIP_INTER:

                            /* Inspect for HID interface num */
                            if(sp.wIndex == 0)
                            {
                                HidInterfaceClassRequests(c_ep0_out, c_ep0_in, sp);
                            }
                            break;
                                           
                    }
                    break;

                case BM_REQTYPE_TYPE_STANDARD:
                    switch(sp.bmRequestType.Recipient)
                    {
                        case BM_REQTYPE_RECIP_INTER:
                    
                            switch(sp.bRequest)
                            {
                                /* Set Interface */
                                case SET_INTERFACE:
                        
                                    /* TODO: Set the interface */
                        
                                    /* No data stage for this request, just do data stage */
                                    XUD_DoSetRequestStatus(c_ep0_in, 0);
                                    break;
                        
                                case GET_INTERFACE:
                                    buffer[0] = 0;
                                    XUD_DoGetRequest(c_ep0_out, c_ep0_in, buffer,1, sp.wLength );
                                    break;
                        
                                case GET_STATUS:
                                    buffer[0] = 0;
                                    buffer[1] = 0;
                                    XUD_DoGetRequest(c_ep0_out, c_ep0_in, buffer, 2, sp.wLength);
                                    break; 
             
                                case GET_DESCRIPTOR:
                                    if((sp.wValue & 0xff00) ==  0x2200) 
                                    {
                                        retVal = XUD_DoGetRequest(c_ep0_out, c_ep0_in, hidReportDescriptor, 
                                            min(sizeof(hidReportDescriptor),sp.wLength), sp.wLength);
                                    }
                                    break;
                        
                            }       
                            break;
                    
                /* Recipient: Device */
                case BM_REQTYPE_RECIP_DEV:
                    
                    /* Standard Device requests (8) */
                    switch( sp.bRequest )
                    {      
                        /* TODO We could check direction to be double safe */
                        /* Standard request: SetConfiguration */
                        case SET_CONFIGURATION:
                        
                            /* Set the config */
                            current_config = sp.wValue;
                        
                            /* No data stage for this request, just do status stage */
                            XUD_DoSetRequestStatus(c_ep0_in,  0);
                            break;
                        
                        case GET_CONFIGURATION:
                            buffer[0] = (char)current_config;
                            XUD_DoGetRequest(c_ep0_out, c_ep0_in, buffer, 1, sp.wLength);
                            break; 
                        
                        case GET_STATUS:
                            buffer[0] = 0;
                            buffer[1] = 0;
                            if (hiSpdConfDesc[7] & 0x40)
                                buffer[0] = 0x1;
                            XUD_DoGetRequest(c_ep0_out, c_ep0_in, buffer, 2, sp.wLength);
                            break; 
                    
                        case SET_ADDRESS:
                            /* Status stage: Send a zero length packet */
                            retVal = XUD_SetBuffer_ResetPid(c_ep0_in,  buffer, 0, PIDn_DATA1);

                            /* We should wait until ACK is received for status stage before changing address */
                            {
                                timer t;
                                unsigned time;
                                t :> time;
                                t when timerafter(time+50000) :> void;
                            }

                            /* Set device address in XUD */
                            XUD_SetDevAddr(sp.wValue);
                            break;
                        
                        default:
                            //XUD_Error("Unknown device request");
                            break;
                        
                    }  
                    break;
                    
                default: 
                    /* Got a request to a recipient we didn't recognise... */ 
                    //XUD_Error("Unknown Recipient"); 
                    break;
                }
                break;
            
            default:
                /* Error */ 
                break;
    
            }
            
        } /* if XUD_DoEnumReqs() */


        if (retVal == -1) 
        {
            XUD_ResetEndpoint(c_ep0_out, c_ep0_in);
        } 


    }
}
