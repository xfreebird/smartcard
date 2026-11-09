#!/usr/bin/env python3
"""Independent AES/CMAC oracle for extended IAS/ECC commands (synthetic keys)."""
import json
from pathlib import Path
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.cmac import CMAC

def pad(value):
    return value + b'\x80' + b'\x00' * ((-len(value)-1) % 16)
def tlv(tag, value):
    size = len(value)
    length = bytes([size]) if size < 128 else (b'\x81' + bytes([size]) if size < 256 else b'\x82' + size.to_bytes(2, 'big'))
    return bytes([tag]) + length + value
key_enc, key_mac, counter = bytes(range(32)), bytes(range(32,64)), bytes(15)+b'\x01'
vectors=[]
for size in (0,257,513):
    payload = bytes(i % 256 for i in range(size))
    header = bytes.fromhex('002a8086')
    command = header + b'\x00' + (size.to_bytes(2,'big')+payload if size else b'') + b'\x00\x00'
    wrapped_header = bytes.fromhex('0c2a8086')
    fields=b''
    if payload:
        encryptor=Cipher(algorithms.AES(key_enc), modes.ECB()).encryptor()
        iv=encryptor.update(counter)+encryptor.finalize()
        encryptor=Cipher(algorithms.AES(key_enc), modes.CBC(iv)).encryptor()
        encrypted=encryptor.update(pad(payload))+encryptor.finalize()
        fields=tlv(0x87,b'\x01'+encrypted)
    fields+=tlv(0x97,b'\x00\x00')
    mac=CMAC(algorithms.AES(key_mac));mac.update(pad(counter+pad(wrapped_header)+fields))
    fields+=tlv(0x8e,mac.finalize()[:8])
    output=wrapped_header+b'\x00'+len(fields).to_bytes(2,'big')+fields+b'\x00\x00'
    vectors.append({'command':command.hex(),'wrapped':output.hex()})
path=Path(__file__).resolve().parents[2]/'spec/vectors/encryption/extended-sm.json'
path.write_text(json.dumps({'enc':key_enc.hex(),'mac':key_mac.hex(),'ssc':bytes(16).hex(),'vectors':vectors},indent=2)+'\n')
