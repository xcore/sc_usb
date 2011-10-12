USB CDC/ECM example
===================


CDC/ECM is the standard for transmitting Ethernet frames over USB. It is
normally used to implement Ethernet over USB dongles, but you can also use
it for other purposes. 

The demo app in ``app_example_usb_ecm`` runs a WWW server over a virtual
ethernet connection over USB. To the host this device appears as a network
interface. THe interface is assigned an address, and we can access a web
server over this interface on ``http://blah.local/``. This web server can
control, for example, LEDs (as shown on the video on
http://www.youtube.com/watch?v=5TBCFPfe3_w ), or it could report values on
the device.

The demo is implemented on the L1-audio board, but it does not use any of
the audio stuff - it just uses the L1 and the USB PHY.

Detail: inside the device we emulate two Ethernet interfaces: one on the
host side, and one on the device side. The one on the host side is tunneled
over USB to the host, the other is connected to the WWW server. An
absolutely minimal TCP/IP "stack" is implemented to make the WWW server
talk to the host.
