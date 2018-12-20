# WAD files

A WAD file represents a map in the game. They are identified by their tribe index, type (level/boss/secret/intro), level index and map index.

## Naming scheme

```
t___m___.wad
 ||| |||
 ||| map index
 |||
 ||level index
 ||
 |type: l(evel), b(oss), s(ecret), i(ntro)
 |
 tribe index (Croc 2: 0 = Menu, 1 = Sailor, 2 = Cossack, 3 = Caveman, 4 = Inca, 5 = Dante)
```

### Example
```
t3b1m002.wad ("Venus Fly Von-Trappe" Part 2)
 ||| |||
 ||| map = 2
 |||
 ||level = 1
 ||
 |type = boss
 |
 tribe = 3 (Caveman)
```

## Format

A WAD file starts with an uint32 that apparently specifies the size of the file excluding this uint32. It is ignored by the engine. The rest of the file is a sequence of chunks whose format resembles the [Resource Interchange File Format](https://en.wikipedia.org/wiki/Resource_Interchange_File_Format). Each chunk starts with a 4 bytes ASCII identifier that has to be reversed in order to get a meaningful name. Then an uint32 specifying the chunk's payload size and the payload follows. If the engine encounters an unknown chunk, it is silently skipped using the chunk size. Some of the chunk sizes specified in the Croc 2 WAD files are slightly off the actual payload size, however, the game does not crash since the engine ignores chunk sizes of most known chunk types. The engine stops processing the WAD file upon reaching the end of the file or encountering an *END* chunk. Some chunk types rely on other chunks already being processed, so the order is important.

### Chunk types (in correct order)

#### INFO

* Unknown to the engine
* Present and payload is always `01 00 00 00` in all Croc 2 maps

#### VERS

* Probably stands for *​**VERS**ion*
* Same as INFO

#### WFPC

* Probably stands for *​**W**ad **F**lags for **PC** version*
* int32 containing bit flags needed by most chunk types
* Engine ignores chunk size

#### SMPC

* Probably stands for *​**S**a**M**ples for **PC** version*
* Contains sounds in (probably) PSX ADPCM format
* Not always present in Croc 2 maps
* Engine ignores chunk size (exception: if sound is disabled, chunk is skipped using chunk size)
* Decoding:
	* First uint32 specifies number of entries
	* For each entry:
		* Read two uint32 and treat the latter as size
		* Read the rest
		* Call `ads.dll:ADS_LoadResource(<entry>, 0x300);` and store result in audio sample array
			* Whole entry (including the first two uint32) is passed to function

#### AMPC

* Probably stands for *​**AM**bient audio for **PC** version*
* Contains ambient audio in [DirectMusic SGT](http://www.vgmpf.com/Wiki/index.php?title=SGT) format
* Not always present in Croc 2 maps
* Engine ignores chunk size (exception: if sound or ambient sound is disabled, chunk is skipped using chunk size)
* Decoding:
	* First part:
		* First uint32 is number of entries
		* For each entry:
			* Skip unused uint32 (apparently size)
			* Read two uint32 and treat the latter as size
			* Read the rest
			* Call `ads.dll:ADS_LoadResource(<entry>, 0xA00);` and store result in audio sample array
				* Whole entry (excluding very first uint32, including the two following uint32) is passed to function
	* Second part:
		* First uint32 is number of entries
		* Rest is entries of 40 bytes each

#### TEXT

* Probably stands for *​**TEXT**ures*
* Contains the textures
* Engine loads whole chunk data into memory using chunk size

#### SPRT

* Engine ignores chunk size
* First uint32 is unused
* If `WFPC & 0x100000`:
	* Next uint32 specifies number of following uint32s
	* rest is list of uint32s

#### FONT

* Seems to define where the characters are stored in the textures
* Engine ignores chunk size
* Contains 256 * 4 uint16
* Each line belongs to a character

#### RIMG

* In Croc 2 only present in *t0i0m001*, *t0i0m002*, *t0i0m003*, *t0i0m004*, *t0l0m005*
* Probably background images
* Engine ignores chunk size

#### TRAK

* Unknown purpose
* MAP chunk depends on it
* Engine loads whole chunk data into memory using chunk size

#### STPC

* Probably stands for *​**S**crip**T** for **PC** version*
* Contains script besides other yet unknown data
* Engine loads whole chunk data into memory using chunk size

#### MAP

* Unknown purpose
* Probably contains initial object data besides other data
* Engine ignores chunk size

#### LGHT

* Probably stands for *​**L**i**GHT***
* Engine ignores chunk size
* Decoding:
	* First uint32 specifies number of entries
	* Each entry starts with byte that specifies its type
	* Types:
		* Type 1: 3 bytes + 3 floats
		* Type 2: 3 bytes + 5 floats + 1 byte
		* Else: 3 bytes
	* Observation: if you set all values to zero no lighting is applied to the objects

#### LGPC

* Probably stands for *​**L**an**G**uage data for **PC** version*
* Engine ignores chunk size
* Starts with 3 uint32: number of languages - 1, number of entries and an unused value
* Then a list of uint32 that specifies the string lengths follows
* Rest is the string data (already null-terminated)

#### END

* If this chunk type is encountered the engine stops processing the WAD file
* Engine ignores chunk size
* Present in all Croc 2 maps
