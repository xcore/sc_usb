// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

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
  0x02,                /* 4  bDeviceClass */ 
  0x00,                /* 5  bDeviceSubClass */  // ?? 6
  0x00,                /* 6  bDeviceProtocol */ 
  0x40,                /* 7  bMaxPacketSize */ 
  0xb1,                /* 8  idVendor */ 
  0x20,                /* 9  idVendor */ 
  0x01,                /* 10 idProduct */ 
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

static unsigned char hiSpdConfDesc[] = {

  0x09,                /* 0  bLength */ 
  0x02,                /* 1  bDescriptortype */ 
  0x43, 0x00,          /* 2  wTotalLength */ 
  0x02,                /* 4  bNumInterfaces */ 
  0x01,                /* 5  bConfigurationValue */
  0x04,                /* 6  iConfiguration */
  0x80,                /* 7  bmAttributes */ 
  0xC8,                /* 8  bMaxPower */

  0x09,                /* 0  bLength */
  0x04,                /* 1  bDescriptorType */ 
  0x00,                /* 2  bInterfacecNumber */
  0x00,                /* 3  bAlternateSetting */
  0x01,                /* 4: bNumEndpoints */
  0x02,                /* 5: bInterfaceClass */ 
  0x02,                /* 6: bInterfaceSubClass */ 
  0x02,                /* 7: bInterfaceProtocol*/ 
  0x00,                /* 8  iInterface */ 


  0x05,                /* 0  bLength */ 
  0x24,                /* 1  bDescriptortype, CS_INTERFACE */ 
  0x00,                /* 2  bDescriptorsubtype, HEADER */ 
  0x00, 0x02,          /* 3  BCD */ 

  0x05,                /* 0  bLength */ 
  0x24,                /* 1  bDescriptortype, CS_INTERFACE */ 
  0x06,                /* 2  bDescriptorsubtype, UNION */ 
  0x00,
  0x01,

  0x05,                /* 0  bLength, Descriptor size in bytes */
  0x24,                /* 1  bDescriptortype, CS_INTERFACE */
  0x01,                /* 2  bDescriptorsubtype, CALL MANAGEMENT */
  0x03,                /* 3  bmCapabilities, DIY */
  0x01,                /* 4  bDataInterface */

  0x04,                /* 0  bLength */ 
  0x24,                /* 1  bDescriptortype, CS_INTERFACE */ 
  0x02,                /* 2  bDescriptorsubtype, ABSTRACT CONTROL MANAGEMENT */ 
  0x00,                /* 3 bmCapabilities: none */

  0x07,                /* 0  bLength */ 
  0x05,                /* 1  bDescriptorType */ 
  0x82,                /* 2  bEndpointAddress */ 
  0x03,                /* 3  bmAttributes */ 
  0x40,                /* 4  wMaxPacketSize */ 
  0x00,                /* 5  wMaxPacketSize */ 
  0xff,                /* 6  bInterval */ 


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


static unsigned char stringDescriptors[][40] = {
	"\009\004",                    // Language string
  	"XMOS",				           // iManufacturer 
 	"XMSerial", 	               // iProduct
 	"002030112233",                // Unused.
 	"Config"   			           // iConfiguration
};

extern int min(int a, int b);

int ControlInterfaceClassRequests(XUD_ep c_ep0_out, XUD_ep c_ep0_in, SetupPacket sp)
{
    unsigned char buffer[64];
    // Recipient: Interface
    // NOTE: CLASS SPECIFIC REQUESTS

    switch(sp.bRequest )
    { 
        case 0x43:      
            // TODO
            return XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 0, PIDn_DATA1);
            break;
            
        case 0x21:
            // Windows calls this - even though we say we do not support it.
            buffer[0] = 0;
            buffer[1] = 132;
            buffer[2] = 3;
            buffer[3] = 0;
            buffer[4] = 0;
            buffer[5] = 0;
            buffer[6] = 8;
            XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 7, PIDn_DATA1);
            return XUD_GetBuffer(c_ep0_out, buffer);
            break;

        case 0x22:      
            // Linux calls this - even though we say we do not support it.
            return XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 0, PIDn_DATA1);
            break;

        case 0x20:      
            // Linux calls this - even though we say we do not support it.
            (void) XUD_GetBuffer(c_ep0_out, buffer);
            return XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 0, PIDn_DATA1);
            break;
            

        default:
            /* Error case */
            printintln(sp.bRequest);
            break;
    }

    return 0;
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
#if 0
            if (sp.bRequest != 5 && sp.bRequest != 9) {
                printintln(sp.bmRequestType.Type);
                printintln(sp.bmRequestType.Recipient);
                printintln(sp.bRequest);
                while(1) ;
            }
#endif
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
                                ControlInterfaceClassRequests(c_ep0_out, c_ep0_in, sp);
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
                                    retVal = XUD_DoSetRequestStatus(c_ep0_in, 0);
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
                                retVal = XUD_DoSetRequestStatus(c_ep0_in, 0);
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
                                   
                                retVal = XUD_DoGetRequest(c_ep0_out, c_ep0_in, buffer,  2, sp.wLength);
                        
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
