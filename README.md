# twinkle

Documentation and code for working with Twinkle systems. This includes a script
that can be used to dump 2ndStyle and above dongles on a RPI that's been correctly
connected to a twinkle dongle. You can accomplish this by desoldering the security
dongle holder from a legit Twinkle system or find some small pins to solder to that
can be inserted into the dongle. It also includes source and associated utility to
convert a Substream executable into a dongle dumper that uses the DB9 serial port
at 9600 baud, 8E1 to dump the data. You can use any terminal emulator such as minicom,
screen or putty to receive the data.

## Dumping 1stStyle and Substream Variants

These require compiling `encrypteddump.s` found in the `source/` directory. Make sure
to read all the comments so you select the correct password for your dongle! The code
includes a comment for how to do so on a Linux system, where it needs to be patched
and additional patches to speed up dumping and remove garbage that would otherwise
show up on the serial port when the Twinkle boots up. Unfortunately, you can't use
any old ISO editing program to replace the `FIREBALL.EXE` file on a Substream ISO
because the playstation format uses ECC bits which are not correctly replicated. If
you attempt to do so, you will get `E131 SCSI HARD ERROR` and the Twinkle will not
boot your code. The easiest way I've found to inject the modified executable is to
open up the image file (`.bin`, `.iso`, etc...) in a hex editor, locate the binary
data and replace it with the modified binary. The binary won't change in size so
this is safe to do.

## Dumping 2ndStyle and Above

With the dongle face up (serial number or dongle identification number visible) and
the pin holes facing away from you, the pinout for a dongle is as follows. Note that
this also holds for a dongle holder as the pins are not crossed when inserting the
dongle into the holder. Once the dongle is connected in this manner, it can be dumped
using the `read_dongle.py` script included in this repo.

* Pin 1 (rightmost pin) - VCC. Connect to RPI pin 1 (3.3V).
* Pin 2 - ~WE. Connect to RPI pin 1 (3.3V) to disable writes on the dongle.
* Pin 3 - SDA. Connect to RPI pin 2 (i2c data, SDA).
* Pin 4 - SCL. Connect to RPI pin 3 (i2c clock, SCL).
* Pin 5 - Not connected.
* Pin 6 - Not connected.
* Pin 7 - Not connected.
* Pin 8 - Not connected.
* Pin 9 - On dongles older than 2ndStyle this is a CS pin. Not connected.
* Pin 10 (leftmost pin) - GND. Connect to RPI pin 6 (GND).
