-- Castlevania: Portrait of Ruin
-- Simple RAM Display (good for livestreaming!)

local opacityMaster = 0.68
gui.register(function()
	local frame = emu.framecount()
	local lagframe = emu.lagcount()
	local moviemode = ""

	local igframe = memory.readdword(0x021119e0)
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
		local basead = 0x020d26e8
		local dispy = 26
		for i = 0, 19 do
			local base = basead + i * 0x2a0
			if memory.readword(base) > 0
				and memory.readbyte(base-8) ~= 0
			then -- hp display
				gui.text(171, dispy, string.format("%X %03d %08X", i, memory.readword(base), memory.readdword(base-0x238)))
				dispy = dispy + 10
			end
		end
	end
end)
