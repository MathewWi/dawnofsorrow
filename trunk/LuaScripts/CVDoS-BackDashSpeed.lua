-- Average speed display for backdash sequence
-- *Do not load a state during the calcuration.
-- *This script doesn't care a lag, it's too stupid :(

if not emu then
  error("This script runs under DeSmuME.")
end

-- require("bit")
local bit = {}
bit.band = AND
bit.bor  = OR
bit.bxor = XOR
function bit.lshift(num, shift) return SHIFT(num, -shift) end
function bit.rshift(num, shift) return SHIFT(num,  shift) end

local distance = 0
local frames = 0
local pad
emu.registerbefore(function()
  pad = joypad.get(1)
end)

emu.registerafter(function()
  local xv = memory.readwordsigned(0x020CA968)

  -- FIXME: support non-default setting
  if pad.l then
    distance = 0
    frames = 0
  end
  distance = distance + xv
  frames = frames + 1
  gui.text(157, 369, string.format("%08.2f/f", math.abs(distance) / frames))
end)
