# Assembly code that is meant to be patched into memory location 0x8004f20c of a SubStream executable
# which converts the dongle check code to a dongle data dumper. You can compile it using commands
# like the following:
#
# mips-linux-gnu-as -march=r3000 -mtune=r3000 -EL -no-pad-sections -o encrypteddump.o encrypteddump.s
# mips-linux-gnu-objcopy encrypteddump.o encrypteddump.padded-bin -O binary --only-section=.text
#
# The resulting bin can be loaded into MAME like so, or patched onto a legit binary in the correct
# spot. To patch a FIREBALL.EXE, use the inject_data.py script.
#
# load encrypteddump.bin,0x8004f20c
#
# To stop the binary from spitting out a "DVD wake-up" packet on the serial, load 116 bytes
# of zeros (29 NOPs) over addresss 0x80051410. To skip SCSI checks for files, load 4 bytes
# of zeros (1 NOP) over address 0x80028aec.

# Given a register to load to, and a label from this file, load the absolute address to reg.
.macro labs reg loc
    li $t6, 0x8004f20c
    li \reg, \loc
    add \reg, \reg, $t6
.endm

# Given a label from this file, jump to the absolute address of the label.
.macro jabs loc
    li $t6, 0x8004f20c
    li $t7, \loc
    add $t7, $t6, $t7
    jr $t7
.endm

# Given a label from this file, jump and link to the absolute address of the label.
.macro jalabs loc
    li $t6, 0x8004f20c
    li $t7, \loc
    add $t7, $t6, $t7
    jalr $t7
.endm

    .section .text

main:
    # Make room on the stack for this function (even though we don't return).
    addiu $sp, $sp, -12
    sw $ra, 0($sp)

    # Save the location to the password we care about.
    labs $t0, _password_863  # Change this to dump a different dongle
    sw $t0, 4($sp)

    # Save the location we're dumping.
    li $a0, 0
    sw $a0, 8($sp)

_patch_debug_print:
    # Patch to the debug stub so we can see errors on the serial output.
    labs $a0, _debug_print_stub
    li $a2, _debug_printf_patch_end - _debug_printf_patch_start
    lw $a0, 0($a0)
    labs $a1, _debug_printf_patch_start
    jalabs memcpy

_print_basic_info:
    # Print information.
    labs $a0, _dongle_dumper_title
    jalabs send_serial_string

    labs $a0, _dongle_dumper_author
    jalabs send_serial_string

_print_compiled_password:
    # Print password used.
    labs $a0, _dongle_dumper_pw
    jalabs send_serial_string
    lw $a0, 4($sp)
    li $a1, 8
    jalabs send_serial_hex
    labs $a0, _dongle_dumper_newline
    jalabs send_serial_string

_dump_and_print_dongle:
    # Execute dongle dump and print in chunks.
    labs $a0, _dongle_dumper_data
    jalabs send_serial_string

_do_copy_password:
    # First, we need to init the read password.
    lw $a1, 4($sp)
    li $a0, 1
    jalabs copy_password

_dongle_read_loop:
    # See if we're done yet.
    lw $a1, 8($sp)
    li $a0, 0x200
    beq $a0, $a1, _halt_success

    # We have another region to dump.
    addiu $a0, $a1, 0x80
    sw $a0, 8($sp)

_do_request_location:
    # Now, we need to request the right dongle location.
    # a1 already contains the correct region from the
    # loop check above, so we only need to set the offset.
    # I'm not sure if this is correct, but the original
    # code sets the region as the offset as well, so...
    ori $a0, $a1, 0x0
    jalabs request_dump_location

_do_actual_read:
    # Now, we need to read the dongle data into RAM.
    labs $a0, _dongle_read_loc
    li $a1, 0x80
    jalabs read_requested_dump_location

    # If we failed to read the chunk, it was a bad password or a bad ack.
    # This will have been printed on the serial console, so just halt.
    bne $v0, $0, _halt_failed

_print_read_chunk:
    # Now, print it out
    labs $a0, _dongle_read_loc
    li $a1, 0x80
    jalabs send_serial_hex
    labs $a0, _dongle_dumper_newline
    jalabs send_serial_string

    # Okay, now do the next region
    jabs _dongle_read_loop

_halt_success:
    # Print that we're done.
    labs $a0, _dongle_dumper_success
    jalabs send_serial_string
    jabs _halt

_halt_failed:
    # Print that we're done.
    labs $a0, _dongle_dumper_failed
    jalabs send_serial_string

_halt:
    # Pet the watchdog so we don't reboot. This isn't
    # strictly necessary since we left the main thread
    # running which displays the startup info and it also
    # pets the watchdog. But, whatever.
    li $t0, 0x1F218000
    sb $0, 0($t0)

    # Wait a vblank cycle.
    li $a0, 0
    jalabs vsync

    # Do nothing.
    jabs _halt

_debug_printf_patch_start:
    # A patch we will copy over the debug printf stub to activate it.
    jabs send_serial_string
_debug_printf_patch_end:
    .word 0xDEADBEEF

# Print hex to serial.
# a0 = Pointer to hex data.
# a1 = Length in bytes we should print.
send_serial_hex:
    addiu $sp, $sp, -12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)

_hex_string_loop:
    # First, see if we finished.
    beq $a1, $0, _hex_string_done

_hex_first_nibble:
    # Now, grab the first nibble to print.
    lw $a0, 4($sp)
    nop
    lb $a0, 0($a0)
    nop
    srl $a0, $a0, 4
    andi $a0, $a0, 0x0F

    # Figure out if it is alpha or numeric
    addiu $t0, $a0, -10
    bltz $t0, _hex_first_numeric

    # Its alpha-based.
    addiu $a0, $t0, 'A'
    jalabs send_serial_byte
    jabs _hex_second_nibble

_hex_first_numeric:
    # Its number-based.
    addiu $a0, $a0, '0'
    jalabs send_serial_byte

_hex_second_nibble:
    # Now, grab the second nibble to print, increment our pointer.
    lw $a0, 4($sp)
    nop
    addiu $t0, $a0, 1
    sw $t0, 4($sp)

    lb $a0, 0($a0)
    nop
    andi $a0, $a0, 0x0F

    # Figure out if it is alpha or numeric
    addiu $t0, $a0, -10
    bltz $t0, _hex_second_numeric

    # Its alpha-based.
    addiu $a0, $t0, 'A'
    jalabs send_serial_byte
    jabs _hex_done_nibble

_hex_second_numeric:
    # Its number-based.
    addiu $a0, $a0, '0'
    jalabs send_serial_byte

_hex_done_nibble:
    # Done, decrement the count and leave it in a1 to examine.
    lw $a1, 8($sp)
    nop
    addiu $a1, $a1, -1
    sw $a1, 8($sp)
    jabs _hex_string_loop

_hex_string_done:
    lw $ra, 0($sp)
    addiu $sp, $sp, 12
    jr $ra

# Print string to serial.
# a0 = Pointer to string.
send_serial_string:
    addiu $sp, $sp, -8
    sw $ra, 0($sp)
    sw $a0, 4($sp)

_serial_string_loop:
    # First, grab the next byte to print, advance our pointer.
    lb $t0, 0($a0)
    addiu $a0, $a0, 1
    sw $a0, 4($sp)

    # Now, see if it is null
    beq $t0, $0, _serial_string_done

_print_serial_byte:
    # Now, print it!
    ori $a0, $t0, 0
    jalabs send_serial_byte

    # Now, restore the pointer.
    lw $a0, 4($sp)
    jabs _serial_string_loop

_serial_string_done:
    lw $ra, 0($sp)
    addiu $sp, $sp, 8
    jr $ra

# Print a serial byte.
# a0 = Byte to print.
send_serial_byte:
    # We need to save the serial byte in case we need to try again.
    addiu $sp, $sp, -8
    sw $ra, 0($sp)
    sw $a0, 4($sp)

_send_try_loop:
    # First, try to call the original send serial byte function.
    labs $t0, _send_serial_byte
    lw $t0, 0($t0)
    nop
    jalr $t0

_check_byte_written_success:
    # Now, check if the HW was ready and sent the byte.
    beq $v0, $0, _print_byte_success

_wait_vblank_retry:
    # Serial isn't ready yet, pet the watchdog and wait a vblank cycle.
    li $t0, 0x1F218000
    sb $0, 0($t0)

    # Wait for one vsync refresh to give the serial time.
    li $a0, 0
    jalabs vsync

    # Restore the byte we want to print, try again.
    lw $a0, 4($sp)
    jabs _send_try_loop

_print_byte_success:
    # Oh yeah, we did it!
    lw $ra, 0($sp)
    addiu $sp, $sp, 8
    jr $ra

# Function thunks.
request_dump_location:
    labs $t0, _request_dump_location
    lw $t0, 0($t0)
    nop
    jr $t0

copy_password:
    labs $t0, _copy_password
    lw $t0, 0($t0)
    nop
    jr $t0

read_requested_dump_location:
    labs $t0, _read_requested_dump_location
    lw $t0, 0($t0)
    nop
    jr $t0

vsync:
    labs $t0, _vsync
    lw $t0, 0($t0)
    nop
    jr $t0

memcpy:
    labs $t0, _memcpy
    lw $t0, 0($t0)
    nop
    jr $t0

# These are the locations of these functions in Substream (983).
_request_dump_location:
    # a0 = Requested read location offset within block.
    # a1 = Block starting address for requested read location (0x000, 0x080, 0x100, 0x180).
    .word 0x800646e4

_copy_password:
    # a0 = Which password to copy, 0 = CONFIG, 1 = READ, 2 = WRITE.
    # a1 = Pointer to password which should be copied (should be 8 bytes).
    .word 0x80064724
    # v0 = Return value, 0 = success, 1 = bad parameters.

_read_requested_dump_location:
    # a0 = Pointer to memory where we should read the dongle data out to.
    # a1 = Length to read into above pointer.
    .word 0x80065930
    # v0 = Return value, 0 = success, 1 = ACK error, 2 = password incorrect.

_send_serial_byte:
    # a0 = Byte to send on the serial port.
    .word 0x80051294
    # v0 = Return value, 0 = success, negative value = try again.

_vsync:
    # a0 = Mode.
    .word 0x80059c70

_memcpy:
    # a0 = Address to copy to.
    # a1 = Address to copy from.
    # a2 = Length to copy.
    .word 0x80057b30

_debug_print_stub:
    # a0 = sprintf-style string.
    # a1... = varargs to use when filling in a0.
    # We don't support this, so we ignore sprintf-style and just print as-is.
    .word 0x80053638

# Random string data we need for this program.
_password_863:
    # The unlock password for 1stStyle.
    .byte 0x38, 0x36, 0x33, 0x72, 0x3E, 0xB0, 0x63, 0x17

_password_983:
    # The unlock password for Substream.
    .byte 0x39, 0x38, 0x33, 0xBC, 0x31, 0x03, 0xAD, 0x02

_password_983A:
    # The unlock password for Substream Asia release.
    .byte 0x39, 0x38, 0x33, 0xBC, 0x31, 0x03, 0x44, 0x02

_password_984:
    # The unlock password for Substream Club Ver. 2.
    .byte 0x39, 0x38, 0x34, 0xC9, 0x34, 0x03, 0xAD, 0xFE

_dongle_dumper_title:
    .asciiz "Twinkle Encrypted Dongle Dumper\n"

_dongle_dumper_author:
    .asciiz "Written by DragonMinded\n"

_dongle_dumper_pw:
    .asciiz "Password used: "

_dongle_dumper_data:
    .asciiz "Dongle data:\n"

_dongle_dumper_success:
    .asciiz "Done!\n"

_dongle_dumper_failed:
    .asciiz "Failed...\n"

_dongle_dumper_newline:
    .asciiz "\n"

_dongle_read_loc:
