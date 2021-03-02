# Extremely basic script that can be executed on a RPI that has i2c enabled.
# See raspi-config or Ubuntu i2c documentation to do so. Assumes you have
# the pyrpiic package installed. Run this like "python3 read_dongle.py <file>"
# to dump the entire dongle contents to a file. Note that this only works
# for 2ndStyle and above dongles as they are not password-protected. It is
# normal for the majority of the dongle to be 0xFF. You can verify your dongle
# is correct by naming it correctly and placing it in the zip file that goes
# with the mix you are dumping in MAME and deleting the NVRAM folder for that
# mix. MAME will complain of a checksum mismatch, so launch it from the command
# line to tell it to ignore this. If you dumped your dongle correctly, the serial
# number from the shell of the dongle will appear on the title screen of the mix
# after you insert a credit.
import sys
from pyrpio.i2c import I2C
from pyrpiic.eeprom import M24C02

i2c1 = I2C('/dev/i2c-1')
i2c1.open()

eeprom = M24C02(i2c1, 0x50)
with open(sys.argv[1], "wb") as bfp:
    bfp.write(eeprom.dump())
print(f"Wrote dongle data to {sys.argv[1]}")
