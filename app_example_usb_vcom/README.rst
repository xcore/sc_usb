This is the VCOM example.

- on Mac OS X: works out of the box, when plugged in you get a box asking
  you what to do with this network interface: press Cancel. Now you can
  ``cat /dev/cu.usbmodem2621`` (or equivalent), and you can write to the same
  device. The device echos all characters, translating lower into upper
  case. 

- on Linux: works out of the box. On Ububntu it appears as ``/dev/ttyACM0``.
  Note that by default hte linux kernel echos all characters *back to the
  terminal*, hence, everything gets send around in a loop forever. Break
  this by using ``stty -echo < /dev/ttyACM0``

- on Windows: Use the .inf file in this directory, and supply that as the
  driver file the first time you plug this device in.
