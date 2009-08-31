----------------------------------------------------------
-- Sample script: put variables on your video.
----------------------------------------------------------

if not aviutl then
  error("This script runs under Lua for AviUtl.")
end

----------------------------------------------------------
-- Import frame data first
----------------------------------------------------------
dofile("C:/trunk/gocha/tas/SeparatedProjects/dawnofsorrow/framedata.lua.inl")

----------------------------------------------------------
-- Dawn of Sorrow - Map flag thing
----------------------------------------------------------
require("bit")

function cvdosPosToMapFlag(x, y)
  x, y = x % 256, y % 256

  local xl, xh = x % 16, math.floor(x / 16) % 16
  local i = (y * 16) + (xh * 46 * 16) + xl
  local pos = 0x20F6E34 + math.floor(i / 8)
  local mask = math.pow(2, math.floor(i % 8))
  return pos, mask
end

----------------------------------------------------------
-- DSM import
----------------------------------------------------------
local dsmPath = "C:/trunk/gocha/tas/SeparatedProjects/dawnofsorrow/CV-DoS-glitched-tas.dsm"
function dsmImport(path)
	local file = io.open(path, "r")
	if file == nil then
		return nil
	end

	local line = file:read("*l")
	local dsm = {}
	local f = 1
	dsm.frame = {}
	while line do
		if string.sub(line, 1, 1) == "|" then
			local padOfs = string.find(line, "|", 2) + 1
			local buttonMappings = { "right", "left", "down", "up", "start", "select", "B", "A", "Y", "X", "L", "R", "debug" }

			dsm.frame[f] = {}
			dsm.frame[f].cmd = tonumber(string.sub(line, 2, padOfs - 2))
			for i = 0, #buttonMappings - 1 do
				s = string.sub(line, padOfs + i, padOfs + i);
				dsm.frame[f][buttonMappings[i+1]] = ((s~="." and s~=" ") and true or nil)
			end
			dsm.frame[f].touchX = tonumber(string.sub(line, padOfs + 13, padOfs + 15))
			dsm.frame[f].touchY = tonumber(string.sub(line, padOfs + 17, padOfs + 19))
			dsm.frame[f].isTouch = ((tonumber(string.sub(line, padOfs + 21, padOfs + 21))~=0) and true or false)
			f = f + 1
		end
		line = file:read("*l")
	end

	file:close()
	return dsm
end
local dsm = dsmImport(dsmPath)

function makeInputDisplayText(frame)
	local s = ""
	if frame ~= nil then
		local nullc = " "
		s = s .. (frame.left and "<" or nullc)
		s = s .. (frame.up and "^" or nullc)
		s = s .. (frame.right and ">" or nullc)
		s = s .. (frame.down and "v" or nullc)
		s = s .. (frame.A and "A" or nullc)
		s = s .. (frame.B and "B" or nullc)
		s = s .. (frame.X and "X" or nullc)
		s = s .. (frame.Y and "Y" or nullc)
		s = s .. (frame.L and "L" or nullc)
		s = s .. (frame.R and "R" or nullc)
		s = s .. (frame.start and "S" or nullc)
		s = s .. (frame.select and "s" or nullc)
	end
	return s
end

----------------------------------------------------------
-- Extra functions
----------------------------------------------------------
aviutl.draw_bordered_text = function(ycp, x, y, text, R, G, B, tr,
		border_width, borderR, borderG, borderB, borderTr,
		face, fh, fw, angle1, angle2, weight, italic, under, strike)

	-- FIXME: transparency won't work well
	for yoff = -border_width, border_width do
		for xoff = -border_width, border_width do
			aviutl.draw_text(ycp, x + xoff, y + yoff, text,
				borderR, borderG, borderB, borderTr,
				face, fh, fw, angle1, angle2, weight,
				italic, under, strike)
		end
	end
	aviutl.draw_text(ycp, x, y, text, R, G, B, tr, face, fh, fw, angle1, angle2, weight, italic, under, strike)
end

-- xx seconds => h:mm:ss.ss
function formatseconds(seconds)
	local h, m, s
	s = seconds % 60
	m = math.floor(seconds / 60)
	h = math.floor(m / 60)
	m = m % 60
	return string.format("%d:%02d:%05.2f", h, m, s)
end

----------------------------------------------------------
-- Image processor
----------------------------------------------------------
function func_proc()
	local f = aviutl.get_frame() + 1
	if frame[f] == nil then
		return	-- for safety...
	end

	local ycp_edit = aviutl.get_ycp_edit()
--[[
	aviutl.draw_bordered_text(ycp_edit,
		2, 2, -- x, y
		makeInputDisplayText(dsm.frame[f]),
		255, 255, 255, 0, -- RGBA (0<alpha<4096)
		2, 0, 0, 0, 2700, -- RGBA (0<alpha<4096)
		"meiryoKeConsole", 18, 8, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
	)
]]--
	if f >= 23869 and f <= 25562 then
		local x = frame[f].mapx
		local y = frame[f].mapy
		local i = (y * 16) + x
		local pos, mask = cvdosPosToMapFlag(x, y)
		local fadeLevel = (f - 23869) / 30.0
		if fadeLevel > 1.0 then fadeLevel = 1.0 end

	aviutl.draw_bordered_text(ycp_edit,
		64, 352, -- x, y
		string.format("%08X:%02x", pos, mask)
			.." " .. string.format("[%04X-%04X]", cvdosPosToMapFlag(bit.band(x, bit.bnot(0x0f)), 0) % 0x10000, cvdosPosToMapFlag(bit.bor(x, 0x0f), 255) % 0x10000)
			.." " .. string.format("(%03d/%X,%03d)", x, x % 16, y)
		,
		255, 255, 255, 4096 - math.floor((4096-300) * fadeLevel), -- RGBA (0<alpha<4096)
		2, 0, 0, 0, 4096 - math.floor((4096-2500) * fadeLevel), -- RGBA (0<alpha<4096)
		"Verdana", 22, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
-- "meiryoKeConsole"
	)

		--agg.text(140, 5, string.format("%08X:%02x", pos, mask))
		--agg.text(140, 24, string.format("[%04X-%04X]", cvdosPosToMapFlag(x, 0) % 0x10000, cvdosPosToMapFlag(bit.bor(x, 0x0f), 255) % 0x10000))
		--agg.text(140, 43, string.format("[%04X-%04X]", cvdosPosToMapFlag(x + 0x10, 0) % 0x10000, cvdosPosToMapFlag(bit.bor(x, 0x0f) + 0x10, 255) % 0x10000))
		--agg.text(140, 62, string.format("(%03d/%X,%03d)", x, x % 16, y))	end
	end
end
--string.format("%d/%d\nspeed (%d, %d)\ningame: %s", frame[f].count, frame[f].lagcount, frame[f].xv, frame[f].yv, formatseconds(frame[f].ingamecount/60.0)),

----------------------------------------------------------
-- Script terminated
----------------------------------------------------------
function func_exit()
end
