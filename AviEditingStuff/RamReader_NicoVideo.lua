----------------------------------------------------------
-- Sample script: put variables on your video.
----------------------------------------------------------

if not aviutl then
  error("This script runs under Lua for AviUtl.")
end

----------------------------------------------------------
-- Import frame data first
----------------------------------------------------------
local basedir = "C:/trunk/gocha/tas/SeparatedProjects/dawnofsorrow/"
--local basedir = "D:/gocha/tas/gocha/SeparatedProjects/dawnofsorrow/"
dofile(basedir .. "framedata.lua.inl")

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
local dsmPath = basedir .. "CV-DoS-glitched-tas.dsm"
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
			local buttonMappings = { "right", "left", "down", "up", "select", "start", "B", "A", "Y", "X", "L", "R", "debug" }

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

function makeInputDisplayText(frameData)
	local s = ""
	if frameData ~= nil then
		local nullc = " "
		s = s .. (frameData.left and "<" or nullc)
		s = s .. (frameData.up and "^" or nullc)
		s = s .. (frameData.right and ">" or nullc)
		s = s .. (frameData.down and "v" or nullc)
		s = s .. (frameData.A and "A" or nullc)
		s = s .. (frameData.B and "B" or nullc)
		s = s .. (frameData.X and "X" or nullc)
		s = s .. (frameData.Y and "Y" or nullc)
		s = s .. (frameData.L and "L" or nullc)
		s = s .. (frameData.R and "R" or nullc)
		s = s .. (frameData.start and "S" or nullc)
		s = s .. (frameData.select and "s" or nullc)
		if frameData.isTouch then
			s = s .. string.format(" %d %d", frameData.touchX, frameData.touchY)
		end
	end
	return s
end

function touchPosToVideoPos(x, y)
	return x * 2, y * 2 + 96
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
	local ycp_edit = aviutl.get_ycp_edit()
	local f = aviutl.get_frame() + 1 - 4
	if f <= 0 then
		return
	end

	local fadeLevel

	local noRamDisplay = (f >= 0 and f < 527) or (f >= 25750 and f < 26063) or (f >= 27794 and f < 27805)
	if noRamDisplay then
		aviutl.box(ycp_edit, 512, 96+192, 512+255, 96+192+191, aviutl.get_pixel(ycp_edit, 0, 96+383))
	end

	if frame[f] == nil then
		return	-- for safety...
	end

	local counterStr = string.format("%d/%d", frame[f].count, frame[f].lagcount)
	fadeLevel = 1.0
	if f > #dsm.frame then
		counterStr = "movie end"
		fadeLevel = 1.0-((f - #dsm.frame - 30)/30.0)
		if fadeLevel < 0 then fadeLevel = 0 end
		if fadeLevel > 1 then fadeLevel = 1 end
	end
	aviutl.draw_bordered_text(ycp_edit,
		3, 6, -- x, y
		counterStr,
		255, 255, 255, 4096 - math.floor((4096-0) * fadeLevel), -- RGBA (0<alpha<4096)
		2, 0, 0, 0, 4096 - math.floor((4096-2700) * fadeLevel), -- RGBA (0<alpha<4096)
		"meiryoKeConsole", 36, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
	)

	fadeLevel = 1.0-((f - 37065)/60.0)
	if fadeLevel < 0 then fadeLevel = 0 end
	if fadeLevel > 1 then fadeLevel = 1 end
	aviutl.draw_bordered_text(ycp_edit,
		512+68, 6, -- x, y
		formatseconds(frame[f].ingamecount/60.0),
		255, 255, 255, 4096 - math.floor((4096-0) * fadeLevel), -- RGBA (0<alpha<4096)
		2, 0, 0, 0, 4096 - math.floor((4096-2700) * fadeLevel), -- RGBA (0<alpha<4096)
		"meiryoKeConsole", 36, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
	)
	aviutl.draw_bordered_text(ycp_edit,
		512+68, 50, -- x, y
		string.format("%10d", frame[f].ingamecount),
		255, 255, 255, 4096 - math.floor((4096-0) * fadeLevel), -- RGBA (0<alpha<4096)
		2, 0, 0, 0, 4096 - math.floor((4096-2700) * fadeLevel), -- RGBA (0<alpha<4096)
		"meiryoKeConsole", 36, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
	)
	fadeLevel = (f - 37065-30)/60.0
	if fadeLevel < 0 then fadeLevel = 0 end
	if fadeLevel > 1 then fadeLevel = 1 end
	aviutl.draw_bordered_text(ycp_edit,
		512+68, 6, -- x, y
		formatseconds(math.max(0, frame[f].ingamecount-0x20000)/60.0),
		255, 255, 255, 4096 - math.floor((4096-0) * fadeLevel), -- RGBA (0<alpha<4096)
		2, 0, 0, 0, 4096 - math.floor((4096-2700) * fadeLevel), -- RGBA (0<alpha<4096)
		"meiryoKeConsole", 36, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
	)
	aviutl.draw_bordered_text(ycp_edit,
		512+68, 50, -- x, y
		string.format("%10d", math.max(0, frame[f].ingamecount-0x20000)),
		255, 255, 255, 4096 - math.floor((4096-0) * fadeLevel), -- RGBA (0<alpha<4096)
		2, 0, 0, 0, 4096 - math.floor((4096-2700) * fadeLevel), -- RGBA (0<alpha<4096)
		"meiryoKeConsole", 36, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
	)

	local inputDisplayText = makeInputDisplayText(dsm.frame[f])
	if not inputDisplayText:match("^%s*$") then	-- prevent dot display bug
		aviutl.draw_bordered_text(ycp_edit,
			3, 50, -- x, y
			inputDisplayText,
			255, 255, 255, 0, -- RGBA (0<alpha<4096)
			2, 0, 0, 0, 2700, -- RGBA (0<alpha<4096)
			"meiryoKeConsole", 36, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
		)
	end

	for i = 7, 0, -1 do
		local f = math.max(f - i, 1)
		local touchalpha = {31, 63, 95, 127, 159, 191, 223, 255}
		local tr = 4096 - (touchalpha[8-i]/255.0*4096.0)

		if f <= #dsm.frame and dsm.frame[f].isTouch then
			local x, y = touchPosToVideoPos(dsm.frame[f].touchX, dsm.frame[f].touchY)
			local xlast, ylast = touchPosToVideoPos(255, 191)
			xlast, ylast = xlast + 1, ylast + 1
			local Y, Cb, Cr = aviutl.rgb2yc(0, 255, 0)
			aviutl.box(ycp_edit, 0, y-1, xlast, y+1, Y, Cb, Cr, tr)
			aviutl.box(ycp_edit, x-1, 0, x+1, ylast, Y, Cb, Cr, tr)
		end
	end

	if f >= 23869 and f <= 25562 then
		local x = frame[f].mapx
		local y = frame[f].mapy
		local i = (y * 16) + x
		local pos, mask = cvdosPosToMapFlag(x, y)
		fadeLevel = (f - 23869) / 30.0
		if fadeLevel > 1.0 then fadeLevel = 1.0 end

		aviutl.draw_bordered_text(ycp_edit,
			64, 352+96, -- x, y
			string.format("%08X:%02x", pos, mask)
				.." " .. string.format("[%04X-%04X]", cvdosPosToMapFlag(bit.band(x, bit.bnot(0x0f)), 0) % 0x10000, cvdosPosToMapFlag(bit.bor(x, 0x0f), 255) % 0x10000)
				.." " .. string.format("(%03d/%X,%03d)", x, x % 16, y)
			,
			255, 255, 255, 4096 - math.floor((4096-300) * fadeLevel), -- RGBA (0<alpha<4096)
			2, 0, 0, 0, 4096 - math.floor((4096-2500) * fadeLevel), -- RGBA (0<alpha<4096)
			"meiryoKeConsole", 22, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
		)
	end

	if not noRamDisplay and not (f >= 4323 and f < 4362) and not (f >= 5940 and f < 5947) and not (f >= 11734 and f < 11790) and not (f >= 14241 and f < 14251) and not (f >= 22884 and f < 22945) and not (f >= 27805) then
		if f >= 4362 and f <= 5939 then
			local digit = 3-#(string.format("%d", frame[f].farmorhp))
			local col
			aviutl.draw_bordered_text(ycp_edit,
				512+16+30-(digit*28), 96+192+28, -- x, y
				string.format("%3d", frame[f].farmorhp),
				255, 255, 255, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 112, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
			col = ((frame[f].farmorinv1 > 0) and 255 or 80)
			aviutl.draw_bordered_text(ycp_edit,
				512+16+48, 96+192+28+108, -- x, y
				string.format("%02d", frame[f].farmorinv1),
				col, col, col, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
			col = ((frame[f].farmorinv2 > 0) and 255 or 80)
			aviutl.draw_bordered_text(ycp_edit,
				512+16+100, 96+192+28+108, -- x, y
				string.format("%02d", frame[f].farmorinv2),
				col, col, col, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
			col = ((frame[f].farmorinv3 > 0) and 255 or 80)
			aviutl.draw_bordered_text(ycp_edit,
				512+16+152, 96+192+28+108, -- x, y
				string.format("%02d", frame[f].farmorinv3),
				col, col, col, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
		elseif f >= 11790 and f <= 14240 then
			local digit = 3-#(string.format("%d", frame[f].balorehp))
			local col
			aviutl.draw_bordered_text(ycp_edit,
				512+16+30-(digit*28), 96+192+28, -- x, y
				string.format("%3d", frame[f].balorehp),
				255, 255, 255, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 112, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
			col = ((frame[f].baloreinv1 > 0) and 255 or 80)
			aviutl.draw_bordered_text(ycp_edit,
				512+16+48, 96+192+28+108, -- x, y
				string.format("%02d", frame[f].baloreinv1),
				col, col, col, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
			col = ((frame[f].baloreinv2 > 0) and 255 or 80)
			aviutl.draw_bordered_text(ycp_edit,
				512+16+100, 96+192+28+108, -- x, y
				string.format("%02d", frame[f].baloreinv2),
				col, col, col, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
			col = ((frame[f].baloreinv3 > 0) and 255 or 80)
			aviutl.draw_bordered_text(ycp_edit,
				512+16+152, 96+192+28+108, -- x, y
				string.format("%02d", frame[f].baloreinv3),
				col, col, col, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
		elseif f >= 22945 and f <= 23837 then
			local digit = 4-#(string.format("%d", frame[f].dmitriihp))
			local col
			aviutl.draw_bordered_text(ycp_edit,
				512+16-(digit*28), 96+192+28, -- x, y
				string.format("%4d", frame[f].dmitriihp),
				255, 255, 255, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 112, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
			col = ((frame[f].dmitriiinv1 > 0) and 255 or 80)
			aviutl.draw_bordered_text(ycp_edit,
				512+16+48, 96+192+28+108, -- x, y
				string.format("%02d", frame[f].dmitriiinv1),
				col, col, col, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
			col = ((frame[f].dmitriiinv2 > 0) and 255 or 80)
			aviutl.draw_bordered_text(ycp_edit,
				512+16+100, 96+192+28+108, -- x, y
				string.format("%02d", frame[f].dmitriiinv2),
				col, col, col, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
			col = ((frame[f].dmitriiinv3 > 0) and 255 or 80)
			aviutl.draw_bordered_text(ycp_edit,
				512+16+152, 96+192+28+108, -- x, y
				string.format("%02d", frame[f].dmitriiinv3),
				col, col, col, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
		elseif f >= 23838 and f <= 25749 then
			if f >= 23897 then
				aviutl.draw_bordered_text(ycp_edit,
					512+16, 96+192+28, -- x, y
					"Black Panther",
					255, 255, 255, 0, -- RGBA (0<alpha<4096)
					2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
					"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
				)
			end
			if f >= 23984 then
				aviutl.draw_bordered_text(ycp_edit,
					512+16, 96+192+28+26, -- x, y
					"Hippogryph",
					255, 255, 255, 0, -- RGBA (0<alpha<4096)
					2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
					"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
				)
			end
			if f >= 24702 then
				aviutl.draw_bordered_text(ycp_edit,
					512+16, 96+192+28+26+26, -- x, y
					"Menace Flag = $30",
					255, 255, 255, 0, -- RGBA (0<alpha<4096)
					2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
					"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
				)
			end
			if f >= 25562 then
				aviutl.draw_bordered_text(ycp_edit,
					512+16, 96+192+28+26+26+26, -- x, y
					"Warp to The Abyss",
					255, 255, 255, 0, -- RGBA (0<alpha<4096)
					2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
					"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
				)
			end
			if f >= 25702 then
				aviutl.draw_bordered_text(ycp_edit,
					512+16, 96+192+28+26+26+26+26, -- x, y
					"Zipping finished!",
					255, 255, 255, 0, -- RGBA (0<alpha<4096)
					2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
					"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
				)
			end
--[[
			aviutl.draw_bordered_text(ycp_edit,
				512+16, 96+192+28+26+26+26+26, -- x, y
				string.format("%08X %08X", frame[f].xsuspend, frame[f].ysuspend),
				255, 255, 255, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
]]--
		else
			aviutl.draw_bordered_text(ycp_edit,
				512+16, 96+192+28, -- x, y
				string.format("X Pos    %08X", frame[f].x)
				.."\r\n"..string.format("Y Pos    %08X", frame[f].y)
				.."\r\n"..string.format("X Vel    %8d", frame[f].xv)
				.."\r\n"..string.format("Y Vel    %8d", frame[f].yv)
				.."\r\n"..string.format("Random   %08X", frame[f].random)
				,
				255, 255, 255, 0, -- RGBA (0<alpha<4096)
				2, 0, 0, 0, 4096, -- RGBA (0<alpha<4096)  2500
				"meiryoKeConsole", 26, 0, 0, 0, 1000 -- font family, height, width, angle 1&2, weight
			)
		end
	end
end
--string.format("%d/%d\nspeed (%d, %d)\ningame: %s", frame[f].count, frame[f].lagcount, frame[f].xv, frame[f].yv, formatseconds(frame[f].ingamecount/60.0)),

----------------------------------------------------------
-- Script terminated
----------------------------------------------------------
function func_exit()
end
