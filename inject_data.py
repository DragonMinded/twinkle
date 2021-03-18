import argparse
import struct
import sys

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Injection utility to update PS-X EXE binaries.",
    )
    parser.add_argument(
        'infile',
        metavar='IN',
        type=str,
        help='The EXE file we want to patch.',
    )
    parser.add_argument(
        'outfile',
        metavar='OUT',
        type=str,
        help='The EXE file we should write.',
    )
    parser.add_argument(
        '--offset',
        metavar='ADDRESS',
        type=str,
        required=True,
        help='The address where we want to put the binary chunk (overwriting original code/data).',
    )
    parser.add_argument(
        '--data',
        metavar='BIN',
        type=str,
        required=True,
        help='The file that we should place at the address we specified.',
    )

    args = parser.parse_args()
    with open(args.infile, "rb") as bfp:
        binary = bfp.read()
    with open(args.data, "rb") as bfp:
        data = bfp.read()

    # Now, parse out information we need to patch the right address.
    if binary[0x000:0x008] != b'PS-X EXE':
        raise Exception("Invalid binary type!")
    if binary[0x04C:0x07B] != b'Sony Computer Entertainment Inc. for Japan area':
        raise Exception("Invalid binary region!")

    text_start, text_length = struct.unpack('<II', binary[0x018:0x020])
    address = int(args.offset, 16)

    if address < text_start:
        raise Exception(f"Address {hex(address)} comes before text section {hex(text_start)}!")
    if (address + len(data)) > (text_start + text_length):
        raise Exception(f"Address {hex(address)} comes after end of text section {hex(text_start + text_length)}!")

    file_offset = (address - text_start) + 0x800

    print(f"File {args.infile} has text section at {hex(text_start)} with length {text_length} bytes")
    print(f"Patching {len(data)} bytes at address {hex(address)}")

    newbinary = binary[:file_offset] + data + binary[(file_offset + len(data)):]
    if len(newbinary) != len(binary):
        raise Exception("Logic error!")

    with open(args.outfile, "wb") as bfp:
        bfp.write(newbinary)

    print(f"Wrote patched data to {args.outfile}")

    return 0

if __name__ == "__main__":
    sys.exit(main())
