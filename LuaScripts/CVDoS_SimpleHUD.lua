-- Castlevania: Portrait of Ruin
-- Simple RAM Display (good for livestreaming!)

local opacityMaster = 0.68
local showHitboxes = true
gui.register(function()
	local frame = emu.framecount()
	local lagframe = emu.lagcount()
	local moviemode = ""

	local igframe = memory.readdword(0x021119e0)
	local camx = math.floor(memory.readdwordsigned(0x020f707c) / 0x1000)
	local camy = math.floor(memory.readdwordsigned(0x020f7080) / 0x1000)
	local posx = memory.readdwordsigned(0x020ca95c)
	local posy = memory.readdwordsigned(0x020ca960)
	local velx = memory.readdwordsigned(0x020ca968)
	local vely = memory.readdwordsigned(0x020ca96c)
	local inv = memory.readbyte(0x020ca9f3)
	local mptimer = memory.readword(0x020ca948)
	local hp = memory.readword(0x020f7410)
	local mp = memory.readword(0x020f7414)
	local mode = memory.readbyte(0x020c07e8)
	local fade = math.min(1.0, 1.0 - math.abs(memory.readbytesigned(0x020c0768)/16.0))

	moviemode = movie.mode()
	if not movie.active() then moviemode = "no movie" end

	local framestr = ""
	if movie.active() and not movie.recording() then
		framestr = string.format("%d/%d", frame, movie.length())
	else
		framestr = string.format("%d", frame)
	end
	framestr = framestr .. (moviemode ~= "" and string.format(" (%s)", moviemode) or "")

	gui.opacity(opacityMaster)
	gui.text(1, 26, string.format("%s\n%d", framestr, lagframe))

	if mode == 2 then
		gui.opacity(opacityMaster * (fade/2 + 0.5))

		gui.text(1, 60, string.format("(%6d,%6d) %d %04X\nHP%03d/MP%03d",
			velx, vely, inv, mptimer, hp, mp
		))

		-- enemy info
		local basead = 0x020d2448
		local dispy = 26
		for i = 0, 63 do
			local base = basead + i * 0x2a0
			if memory.readword(base) > 0
				and memory.readbyte(base-8) ~= 0
			then
				-- hp display
				local en_hp = memory.readword(base)
				local en_mp = memory.readword(base+2)
				local en_x = memory.readdword(base-0x22c)
				-- gui.text(183, dispy, string.format("%02X %4d %4d", i, en_hp, en_mp))
				gui.text(171, dispy, string.format("%X %03d %08X", i, en_hp, en_x))
				dispy = dispy + 10
			end
		end

		-- enemy's hitbox
		if showHitboxes then
			for i = 0, 63 do
				local rectad = 0x0210b2ee + (i * 0x14)
				local left = memory.readwordsigned(rectad+0) - camx
				local top = memory.readwordsigned(rectad+2) - camy
				local right = memory.readwordsigned(rectad+4) - camx
				local bottom = memory.readwordsigned(rectad+6) - camy
				if top >= 0 then
					gui.box(left, top, right, bottom, "clear", "#00ff00aa")
				end
			end
		end

		-- Soma's hitbox
		if showHitboxes then
			local left = memory.readwordsigned(0x0210af42) - camx
			local top = memory.readwordsigned(0x0210af44) - camy
			local right = memory.readwordsigned(0x0210af46) - camx
			local bottom = memory.readwordsigned(0x0210af48) - camy
			gui.box(left, top, right, bottom, "clear", "#00ff00aa")
		end
	end
end)
