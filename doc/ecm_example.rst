USB CDC/ECM example
===================


CDC/ECM is the standard for transmitting Ethernet frames over USB. It is
normally used to implement Ethernet over USB dongles, but this example
shows an alternative use: running a WWW server over USB: plug your USB
device into a PC, and point your web browser to ``http://blah.local/`` to
contact the web server.

Use cases for this include configuring devices that are connected over USB,
authentication by storing a key on the USB dongle, or a user interface
for sensor data that uses standard protocols rather than libusb. The
current example, where a web server controls two LEDs is demonstrated on
http://www.youtube.com/watch?v=5TBCFPfe3_w

The details
-----------

Keep in mind that this example program does not use the USB stack as
intended. It uses the following structure::


      Web Browser <-> TCP/IP/Ethernet <-> USB               HOST
                                           ^
   .  .  .  .  .  .  .  .  .  .  .  .  .   |  .  .  .  .  .  .  .
                                           v     
                  +-> TCP/IP/Ethernet <-> USB       
                  |
                  |                                        DEVICE
                  |                     +-> MDNS server
                  +-> TCP/IP/Ethernet <-+-> WWW server
                                        +-> DHCP server

A host (PC/Mac) runs a web browser that interfaces through normal means to
the host's network stack, which in turn encapsulates the ethernet packets
to be transmitted over the USB bus. The device receives those packets and
*emulates* two Ethernet interfaces connected by means of a cable; each of
these devices has an IP address and a MAC address. The IP address of the
first device (on the host side) will be set using link-local addressing or
DHCP (to be done), the other device is set to a number that matches the
network. The WWW server lives, conceptually on the second Ethernet
interface. Neither interface exists, but as far as the host is concerned
there is a chunk of Ethernet cable present.

Only a very limited subset of the network set needs to be implemented. No
cable is present, no packets can get lost or shuffled in transmission, and
the world comprises just two IP addresses (mac addresses): called *theirs*
and *ours* (for the host and device side).

The servers that need to be implemented are:

* MDNS for domain name matching (for windows some version of zeroconf will
  need to be supported)

* DHCP server. This is to be done, the present example uses link-local
  addressing, but this is slow and takes 5-10 seconds to take hold.

* WWW server. For serving contents. It just needs to support the GET
  message.

The demo is implemented on the L1-audio board, but it does not use any of
the audio stuff - it just uses the L1 and the USB PHY.

USB/EEM
-------

You should be able to do this with USB/EEM, but I couldn't get that to work
and suspect that drivers aren't readily available.
