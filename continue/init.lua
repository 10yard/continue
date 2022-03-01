-- Continue Plugin for Donkey Kong, Donkey Kong II, Donkey Kong Junior
-- by Jon Wilson (10yard)
--
-- Tested with latest MAME version 0.240
-- Fully compatible with all MAME versions from 0.227
--
-- Minimum start up arguments:
--   mame dkong -plugin continue
-----------------------------------------------------------------------------------------
local exports = {}
exports.name = "continue"
exports.version = "0.1"
exports.description = "Continue Plugin"
exports.license = "GNU GPLv3"
exports.author = { name = "Jon Wilson (10yard)" }
local continue = exports

function continue.startplugin()
	local mac, scr, cpu, mem
	local frame_stop, frame_remain
	local tally, flash

	-- compatible roms with associated position data
	local rom_table = {}
	rom_table["dkong"] = {219, 9}
	rom_table["dkongjr"] = {229, 154}
	rom_table["dkongx"] = {219, 9}
	rom_table["dkongx11"] = {219, 9}
	rom_table["dkongpe"] = {219, 9}
	rom_table["dkonghrd"] = {219, 9}
	rom_table["dkongf"] = {219, 9}
	rom_table["dkongj"] = {219, 9}

	local CYAN = 0xff14f3ff
	local BLACK = 0xff000000
	local WHITE = 0xffffffff
	local RED = 0xffff0000
	local cycle_table = { WHITE, CYAN }

	local message_table = {
		"######  ##   ##  ####   ##   ##              ## ##   ## ##   ## ######           ######  #####",
		"##   ## ##   ## ##  ##  ##   ##              ## ##   ## ### ### ##   ##            ##   ##   ##",
		"##   ## ##   ## ##      ##   ##              ## ##   ## ####### ##   ##            ##   ##   ##",
		"##   ## ##   ##  #####  #######              ## ##   ## ####### ##   ##            ##   ##   ##",
		"######  ##   ##      ## ##   ##              ## ##   ## ## # ## ######             ##   ##   ##",
		"##      ##   ## ##   ## ##   ##         ##   ## ##   ## ##   ## ##                 ##   ##   ##",
		"##       #####   #####  ##   ##          #####   #####  ##   ## ##                 ##    #####",
		"",
		"                  ####   #####  ##   ##  ######  ###### ##   ## ##   ##  ######",
		"                 ##  ## ##   ## ###  ##    ##      ##   ###  ## ##   ##  ##",
		"                ##      ##   ## #### ##    ##      ##   #### ## ##   ##  ##",
		"                ##      ##   ## #######    ##      ##   ####### ##   ##  #####",
		"                ##      ##   ## ## ####    ##      ##   ## #### ##   ##  ##",
		"                 ##  ## ##   ## ##  ###    ##      ##   ##  ### ##   ##  ##",
		"                  ####   #####  ##   ##    ##    ###### ##   ##  #####   ######"}

	function initialize()
		if tonumber(emu.app_version()) >= 0.227 then
			mac = manager.machine
		elseif tonumber(emu.app_version()) >= 0.196 then
			mac = manager:machine()
		else
			print("ERROR: The continue plugin requires MAME version 0.196 or greater.")
		end				
		if mac ~= nil and rom_table[emu:romname()] then
			scr = mac.screens[":screen"]
			cpu = mac.devices[":maincpu"]
			mem = cpu.spaces["program"]
		end
	end
		
	function main()
		local _col, _cnt, _y, _x
		if cpu ~= nil then
			if mem:read_u8(0x600f) == 0 then								  -- 1 player game
				mode = mem:read_u8(0x600a)

				if mode == 0x7 or tally == nil then					  		  -- reset continue tally
					tally = 0
				elseif mode >= 0x8 and mode <= 0xd then  					  -- display number of continues
					if not flash or mem:read_u8(0xc601a) % 32 > 16 then       -- flash only when continuing
						for i=0, tally - 1 do
							_col = cycle_table[((math.floor(i / 5)) % 2) + 1]
							_y, _x = rom_table[emu:romname()][1], rom_table[emu:romname()][2]
							scr:draw_box(_y, _x + (i * 4), _y + 3, _x + 2 + (i * 4), _col ,_col)
						end
					end
					if mode == 0xb then
						flash = false
					end
				end

				if mode == 0xd and mem:read_u8(0x6228) == 1 then 				-- jumpman has lost his last life
					if mem:read_u8(0x639d) == 1 then                            -- death animation is starting
						frame_stop = scr:frame_number() + 600                   -- set a stop frame for the continue option (+10 seconds)
					end
					if frame_stop and mem:read_u8(0x639d) == 2 then             -- death animation is finishing
						frame_remain = frame_stop - scr:frame_number()
						if frame_remain > 0 then
							mem:write_u8(0x6009, 8) 							-- freeze the death timer

							scr:draw_box(96, 57, 144, 168, BLACK, BLACK)
							draw_graphic(message_table, 120, 65)
							_cnt = math.floor((frame_remain) / 6.25)
							_col = CYAN
							if _cnt < 40 and _cnt % 6 >= 3 then
								_col = RED
							end
							scr:draw_box(128, 65, 136, 65 + _cnt, _col, _col) -- draw countdown timer

							if mem:read_u8(0x6010) >= 128 then					-- read input state and check for jump
								tally = tally + 1           	-- chalk up a continue
								mem:write_u8(0x6228, mem:read_u8(0x6020) + 1) 	-- reset lives with starting lives
								frame_stop = scr:frame_number()                 -- stop the countdown timer
								flash = true
							end
						end
					end
				end
			end
		end
	end

	function draw_graphic(data, pos_y, pos_x)
		local _col
		for _y, line in pairs(data) do
			for _x=1, string.len(line) do
				_col = string.sub(line, _x, _x)
				if _col ~= " " then
					scr:draw_box(pos_y -_y, pos_x + _x, pos_y -_y + 1, pos_x +_x + 1, CYAN, CYAN)
				end
			end
		end
	end

	emu.register_start(function()
		initialize()
	end)
	
	emu.register_frame_done(main, "frame")
end
return exports