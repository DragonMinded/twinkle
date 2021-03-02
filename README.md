# twinkle

Documentation and code for working with Twinkle systems. Currently this only includes
a simple script that can be used to dump 2ndStyle and above dongles on a RPI that's
been correctly connected to a twinkle dongle. You can accomplish this by desoldering
the security dongle holder from a legit Twinkle system or find some small pins to
solder to that can be inserted into the dongle.

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
