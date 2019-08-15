#!/usr/bin/env python3

import argparse
from ctypes import *
import struct
import wave

def main():
	ap = argparse.ArgumentParser(
		description=
			'Convert Croc 2 cvg file to '
			'uncompressed PCM wav file using ads.dll'
	)
	ap.add_argument('cvg', help='cvg file', type=argparse.FileType('rb'))
	ap.add_argument('wav', help='wav file')
	ap.add_argument('-d', '--dll', help='path to ads.dll',
		default=r'C:\Program Files (x86)\Fox\Croc 2\ads.dll')
	args = ap.parse_args()

	with args.cvg as cvg:
		cvg2wav(cvg, args.wav, args.dll)

def cvg2wav(cvg, wav_path, dll_path):
	# Get pointer to decoding function
	ads_dll = WinDLL(dll_path)
	decode_cvg = WINFUNCTYPE(c_uint32, c_void_p, c_void_p, c_uint32)(
		ads_dll._handle + 0x7740)

	# Read cvg file
	magic, size, sample_rate, hdr4, hdr8, hdrC, body_len = \
		unpack_strm('<4sIIIIII', cvg)
	if magic != b'cvg ':
		raise RuntimeError('Unexpected magic number')
	cvg_body = read_exactly(cvg, body_len)

	# Convert to wav
	out_buf = create_string_buffer(len(cvg_body) // 16 * 56)
	out_len = decode_cvg(out_buf, cvg_body, 0)
	with wave.open(wav_path, 'wb') as wav:
		wav.setnchannels(1)
		wav.setframerate(sample_rate)
		wav.setsampwidth(2)
		wav.writeframes(out_buf[:out_len])

def unpack_strm(fmt, strm):
	strct = struct.Struct(fmt)
	buf = strm.read(strct.size)
	if not buf:
		return None
	return struct.unpack(fmt, buf)

def read_exactly(strm, size):
	buf = strm.read(size)
	if len(buf) != size:
		raise RuntimeError('Unexpected end of file')
	return buf

if __name__ == '__main__':
	main()
