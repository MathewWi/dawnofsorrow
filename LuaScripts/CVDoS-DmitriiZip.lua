-- Dmitrii room zipping help (nah, it's wrong. I don't know the real formula :/)

if not emu then
  error("This script runs under DeSmuME.")
end

emu.registerbefore(function()
  local x = math.floor(memory.readword(0x020CA95E) / 0x10)
  local y = math.floor(memory.readword(0x020CA962) / 0x10 % 192)
  local i = (y * 16) + x + 1
  local pos = 0x20F7085 + math.floor(i / 8)
  local mask = math.pow(2, math.floor(i % 8))
  gui.text(144, 4, string.format("%08X:%02x\n[%04X-%04X]", pos, mask,
           0x7085 - 0x198 + math.floor(((0 * 16) + x + 1) / 8),
           0x7085 - 0x118 + math.floor(((191 * 16) + x + 1) / 8)))
end)
