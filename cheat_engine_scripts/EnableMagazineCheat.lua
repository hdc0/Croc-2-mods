-- Cheat Engine script that enables "magazine" cheat in Croc 2 (PC)
-- After executing the script, the magazine cheat can be toggled by
-- holding S and pressing backslash in the main menu.

-- Writes the same value to multiple addresses using the specified function
local function writeToMultipleAddrs(func, addrs, val)
  for key, addr in pairs(addrs)
  do
    func(addr, val)
  end
end

-- Determine game version from the process' main module size
local VER = ({[0x23A000] = "US", [0x242000] = "EU"})[getModuleSize(process)]
if not VER then
  print("Unknown game version")
  return
end

-- Read original cheat key sequences
local ORIG_ADDR_CHEAT_KEY_SEQS = ({US = 0x4A8D20, EU = 0x4A9D24})[VER]
local ORIG_NUM_CHEATS = 7
local CHEAT_KEY_SEQ_LEN = 10 -- Max # of keys in a sequence plus terminating 0
local cheatKeySeqs = readBytes(
  ORIG_ADDR_CHEAT_KEY_SEQS, ORIG_NUM_CHEATS * CHEAT_KEY_SEQ_LEN * 4, true)

-- Add new key sequence (hold S + press backslash) for magazine cheat
local KEY_BACKSLASH = 1
table.move({KEY_BACKSLASH, 0, 0, 0, 0, 0, 0}, 1, 8,
  #cheatKeySeqs + 1, cheatKeySeqs)

-- Write new cheat key sequences array to process
local newAddrSeqs = allocateMemory(#cheatKeySeqs)
writeBytes(newAddrSeqs, cheatKeySeqs)

-- Enlarge cheat input progress array by allocating a new one
local newNumCheats = #cheatKeySeqs // 4
local newAddrCheatInputProgress = allocateMemory(newNumCheats * 4)

-- Update code where the number of cheats is used
writeToMultipleAddrs(({writeBytes,
  US = {0x41AB77, 0x41ACC1},
  EU = {0x41B097, 0x41B1E1}
  })[VER], newNumCheats)

-- Update code where the cheat input progress array is used
writeToMultipleAddrs(({writeInteger,
  US = {0x41AB85, 0x41ABA8, 0x41ACB8},
  EU = {0x41B0A5, 0x41B0C8, 0x41B1D8}
  })[VER], newAddrCheatInputProgress)

-- Update code where the cheat key sequences array is referenced
writeToMultipleAddrs(({writeInteger,
  US = {0x41AB9A, 0x41ABB1},
  EU = {0x41B0BA, 0x41B0D1}
  })[VER], newAddrSeqs)
