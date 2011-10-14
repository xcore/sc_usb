// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "usb.h"
#include "ep0Support.h"

// This devices Device Descriptor:
unsigned char hiSpdDesc[] = { 
  0x12,                /* 0  bLength */
  0x01,                /* 1  bdescriptorType */ 
  0x00,                /* 2  bcdUSB */ 
  0x02,                /* 3  bcdUSB */ 
  0x02,                /* 4  bDeviceClass */ 
  0x00,                /* 5  bDeviceSubClass */  // ?? 6
  0x00,                /* 6  bDeviceProtocol */ 
  0x40,                /* 7  bMaxPacketSize */ 
  0xb1,                /* 8  idVendor */ 
  0x20,                /* 9  idVendor */ 
  0x02,                /* 10 idProduct */ 
  0x04,                /* 11 idProduct */ 
  0x00,                /* 12 bcdDevice */
  0x02,                /* 13 bcdDevice */
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
    0x02,              /* 4  bDeviceClass */ 
    0x06,              /* 5  bDeviceSubClass */ 
    0x00,              /* 6  bDeviceProtocol */ 
    0x40,              /* 7  bMaxPacketSize */ 
    0x01,              /* 8  bNumConfigurations */ 
    0x00               /* 9  bReserved  */ 
};

unsigned char hiSpdConfDesc[] = {

  0x09,                /* 0  bLength */ 
  0x02,                /* 1  bDescriptortype */ 
  0x40, 0x00,          /* 2  wTotalLength */ 
  0x02,                /* 4  bNumInterfaces */ 
  0x01,                /* 5  bConfigurationValue */
  0x04,                /* 6  iConfiguration */
  0x80,                /* 7  bmAttributes */ 
  0xC8,                /* 8  bMaxPower */

  0x09,                /* 0  bLength */
  0x04,                /* 1  bDescriptorType */ 
  0x00,                /* 2  bInterfacecNumber */
  0x00,                /* 3  bAlternateSetting */
  0x00,                /* 4: bNumEndpoints */
  0x02,                /* 5: bInterfaceClass */ 
  0x06,                /* 6: bInterfaceSubClass */ 
  0x00,                /* 7: bInterfaceProtocol*/ 
  0x00,                /* 8  iInterface */ 

  0x05,                /* 0  bLength */ 
  0x24,                /* 1  bDescriptortype, CS_INTERFACE */ 
  0x00,                /* 2  bDescriptorsubtype, HEADER */ 
  0x00, 0x02,          /* 3  BCD */ 

#if 1
  5,
  0x24,
  6,
  0,
  1,
#endif

//  0,
//  0x24,
//  7,

  0x0D,                /* 0  bLength */ 
  0x24,                /* 1  bDescriptorType CS_INTERFACE */ 
  0x0F,                /* 2  bDescriptorSubType Ethernet */ 
  0x03,                /* 3  iMACAddress index of MAC address */ 
  0,0,0,0,             /* 4  bmEthernetStatistics - none */ 
  0xEA, 0x5,           /* 8  wMaxSegementSize  (ought to be 1514)*/ 
  0, 0,                /* 10 wNumberMCFilters (0) */ 
  0,                   /* 12 wNumberPowerFilters */ 

  0x09,                /* 0  bLength */
  0x04,                /* 1  bDescriptorType */ 
  0x01,                /* 2  bInterfacecNumber */
  0x00,                /* 3  bAlternateSetting */
  0x02,                /* 4: bNumEndpoints */
  0x0A,                /* 5: bInterfaceClass */ 
  0x00,                /* 6: bInterfaceSubClass */ 
  0x00,                /* 7: bInterfaceProtocol*/ 
  0x00,                /* 8  iInterface */ 

  0x07,                /* 0  bLength */ 
  0x05,                /* 1  bDescriptorType */ 
  0x01,                /* 2  bEndpointAddress */ 
  0x02,                /* 3  bmAttributes */ 
  0x00,                /* 4  wMaxPacketSize */ 
  0x02,                /* 5  wMaxPacketSize */ 
  0x00,                /* 6  bInterval */ 
  
  0x07,                /* 0  bLength */ 
  0x05,                /* 1  bDescriptorType */ 
  0x81,                /* 2  bEndpointAddress */ 
  0x02,                /* 3  bmAttributes */ 
  0x00,                /* 4  wMaxPacketSize */ 
  0x02,                /* 5  wMaxPacketSize */ 
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


unsigned char stringDescriptors[][40] = {
	"\009\004",                    // Language string
  	"XMOS",				           // iManufacturer 
 	"XMEth", 		               // iProduct
 	"002297xxxxxx",                // MAC address
 	"Config"   			           // iConfiguration
};

unsigned int sizeofHiSpdDesc = sizeof(hiSpdDesc);
unsigned int sizeofHiSpdConfDesc = sizeof(hiSpdConfDesc);
unsigned int sizeofFullSpdDesc = sizeof(fullSpdDesc);
unsigned int sizeofFullSpdConfDesc = sizeof(fullSpdConfDesc);

extern int min(int a, int b);



void ControlInterfaceClassRequests(SetupPacket sp)
{
    // Recipient: Interface
    // NOTE: CLASS SPECIFIC REQUESTS

    switch(sp.bRequest )
    { 
        case 0x43:      
            // TODO
            ep0INack();
            break;
            
        default:
            /* Error case */
            break;
    }

}

int g_epStatusOut[2];
int g_epStatusIn[2];
void SetEndpointStatus(unsigned epNum, unsigned status)
{
  /* Inspect for IN bit */
    if( epNum & 0x80 )
    {
        epNum &= 0x7f;
        /* Range check */
        if(epNum < 2)
        {
            g_epStatusIn[ epNum & 0x7F ] = status;  
        }
    }
    else
    {
        if(epNum < 2)
        {
            g_epStatusOut[ epNum ] = status;  
        }
    }
}

char hexChar(char s) {
    static const char hex[16] = {'0','1','2','3','4','5','6','7',
                                 '8','9','A','B','C','D','E','F'};
    return hex[s&0xF];
}

void copyMacAddress() {
    extern char macAddressTheirs[6];
    for(int i = 0; i < 6; i++) {
        stringDescriptors[3][i*2]   = hexChar(macAddressTheirs[i] >> 4);
        stringDescriptors[3][i*2+1] = hexChar(macAddressTheirs[i]);
    }
}

void ep0User(SetupPacket &sp, unsigned char buffer[]) {
    unsigned int current_config = 0;

    /* Request not covered by XUD_DoEnumReqs() so decode ourselves */
    switch(sp.bmRequestType.Type)
    {
        /* Class request */
    case BM_REQTYPE_TYPE_CLASS:
        switch(sp.bmRequestType.Recipient)
        {
        case BM_REQTYPE_RECIP_INTER:
            /* Inspect for Control interface num */
            if(sp.wIndex == 0)
            {
                ControlInterfaceClassRequests(sp);
            }
            break;
            
        }
        break;
        
    case BM_REQTYPE_TYPE_STANDARD:
        switch(sp.bmRequestType.Recipient)
        {
        case BM_REQTYPE_RECIP_EP:                           
            /* Standard endpoint requests */
            switch ( sp.bRequest )
            {
                /* ClearFeature */
            case CLEAR_FEATURE:
                switch ( sp.wValue )
                {
                case ENDPOINT_HALT:
                    
                    /* Mark the endpoint status */
                    SetEndpointStatus(sp.wIndex, 0);
                    /* No data stage for this request, just do status stage */
                ep0INack();
//                    retVal = XUD_DoSetRequestStatus(c_ep0_in, 0);
                    break;
                    
                default:
                    XUD_Error( "Unknown request in Endpoint ClearFeature" );
                    break;
                }
                break; /* B_REQ_CLRFEAR */
                /* SetFeature */
            case SET_FEATURE:
                switch( sp.wValue )  
                {
                case ENDPOINT_HALT:
                    
                    /* Check request is in range */
                    SetEndpointStatus(sp.wIndex, 1);
                    
                    break;
                    
                default:
                    XUD_Error("Unknown feature in SetFeature Request");
                    break;
                }
                ep0INack();
//                retVal = XUD_DoSetRequestStatus(c_ep0_in, 0);
                break;
                
                /* Endpoint GetStatus Request */
            case GET_STATUS:
                buffer[0] = 0;
                buffer[1] = 0;
                if( sp.wIndex & 0x80 )
                {
                    /* IN Endpoint */
                    if((sp.wIndex&0x7f) < 2)                                {
                        buffer[0] = ( g_epStatusIn[ sp.wIndex & 0x7F ] & 0xff );
                        buffer[1] = ( g_epStatusIn[ sp.wIndex & 0x7F ] >> 8 );
                    }
                }
                else
                {
                    /* OUT Endpoint */
                    if(sp.wIndex < 2)
                    {
                        buffer[0] = ( g_epStatusOut[ sp.wIndex ] & 0xff );
                        buffer[1] = ( g_epStatusOut[ sp.wIndex ] >> 8 );
                    }
                }
                                   
                ep0IN(buffer,  2, sp.wLength);
                        
                break;
            default:
                //printstrln("Unknown Standard Endpoint Request");   
                break;
            }
            break;
 
        case BM_REQTYPE_RECIP_INTER:
                    
            switch(sp.bRequest)
            {
                /* Set Interface */
            case SET_INTERFACE:
                        
                /* TODO: Set the interface */
                        
                /* No data stage for this request, just do data stage */
//                XUD_DoSetRequestStatus(c_ep0_in, 0);
                ep0INack();
                break;
                        
            case GET_INTERFACE:
                buffer[0] = 0;
                ep0IN(buffer,1, sp.wLength );
                break;
                        
            case GET_STATUS:
                buffer[0] = 0;
                buffer[1] = 0;
                ep0IN(buffer, 2, sp.wLength);
                break; 
             
            case GET_DESCRIPTOR:
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
//                XUD_DoSetRequestStatus(c_ep0_in,  0);
                ep0INack();
                break;
                        
            case GET_CONFIGURATION:
                buffer[0] = (char)current_config;
                ep0IN(buffer, 1, sp.wLength);
                break; 
                        
            case GET_STATUS:
                buffer[0] = 0;
                buffer[1] = 0;
                if (hiSpdConfDesc[7] & 0x40)
                    buffer[0] = 0x1;
                ep0IN(buffer, 2, sp.wLength);
                break; 
                    
            case SET_ADDRESS:
                /* Status stage: Send a zero length packet */
                ep0INack();


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
}


