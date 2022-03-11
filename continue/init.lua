-- Continue Plugin for MAME
-- by Jon Wilson (10yard)
--
-- A continue option appears before your game is over with a 10 second countdown timer.
-- Push P1-Start button to continue your game and your score will be reset.
-- A tally of the number of continues appears at the top of screen.
--
-- Tested with latest MAME version 0.241
-- Fully compatible with all MAME versions from 0.196
--
-- Minimum start up arguments:
--   mame mspacman -plugin continue
-----------------------------------------------------------------------------------------
local exports = {}
exports.name = "continue"
exports.version = "0.11"
exports.description = "Continue plugin"
exports.license = "GNU GPLv3"
exports.author = { name = "Jon Wilson (10yard)" }
local continue = exports

function continue.startplugin()
	-- mame system objects
	local mac, scr, cpu, mem

	-- general use variables
	local h_mode, h_start_lives
	local i_frame, i_frame_stop, i_tally
	local b_1p_game, b_game_restart, b_almost_gameover, b_reset_continue, b_reset_tally, b_show_tally, b_push_p1

	-- colours
	local BLACK, WHITE, RED, YELLOW, CYAN = 0xff000000, 0xffffffff, 0xffff0000, 0xfff8f91a, 0xff14f3ff

	-- compatible roms with associated function and position data
	local rom_data, rom_table = {}, {}
	local rom_function
	-- supported rom name   function          tally yx   msg yx    color   flip   rotate  scale
	rom_table["galaga"] =   {"galaga_func",   {15, 219}, {102,50}, WHITE,  true,  false,  1}
	rom_table["galaxian"] = {"galaxian_func", {52, 216}, {328,52}, WHITE,  true,  false,  3}
	rom_table["superg"]   = {"galaxian_func", {52, 216}, {328,52}, WHITE,  true,  false,  3}
	rom_table["moonaln"]  = {"galaxian_func", {52, 216}, {328,52}, WHITE,  true,  false,  3}
	rom_table["pacman"]   = {"pacman_func",   {18, 216}, {120,50}, WHITE,  true,  false,  1}
	rom_table["mspacman"] = {"pacman_func",   {18, 216}, {120,50}, WHITE,  true,  false,  1}
	rom_table["mspacmat"] = {"pacman_func",   {18, 216}, {120,50}, WHITE,  true,  false,  1}
	rom_table["pacplus"]  = {"pacman_func",   {18, 216}, {120,50}, WHITE,  true,  false,  1}
	rom_table["dkong"]    = {"dkong_func",     {219, 9}, {96,50},  CYAN,   false, false,  1}
	rom_table["dkongjr"]  = {"dkong_func",   {229, 154}, {96,50},  YELLOW, false, false,  1}
	rom_table["dkongx"]   = {"dkong_func",     {219, 9}, {96,50},  CYAN,   false, false,  1}
	rom_table["dkongx11"] = {"dkong_func",     {219, 9}, {96,50},  CYAN,   false, false,  1}
	rom_table["dkongpe"]  = {"dkong_func",     {219, 9}, {96,50},  CYAN,   false, false,  1}
	rom_table["dkonghrd"] = {"dkong_func",     {219, 9}, {96,50},  CYAN,   false, false,  1}
	rom_table["dkongf"]   = {"dkong_func",     {219, 9}, {96,50},  CYAN,   false, false,  1}
	rom_table["dkongj"]   = {"dkong_func",     {219, 9}, {96,50},  CYAN,   false, false,  1}
	rom_table["asteroid"] = {"asteroid_func" , {8, 8}, {540,240}, WHITE,   false, true,   3}
	rom_table["cclimber"] = {"cclimber_func",  {9,48}, {156,80},   CYAN,   true,  true,   1}

	-- encoded message data
	local message_data = {"6s2S2s4S2S2SSS6Ss2SSSS4S 6S3S6S6", "2S2 2S2 2s2s2S2SSS2S2S3SSSs2s2Ss2S 2 2s2S2S 2s",
		"2S2 2S2 2SS2S2SSS2S2S 2SSSs2SSS2S2S2 2S2S 2s", "2S2 2S2s5s7SSS2S2S 2SSSS5Ss2S2S2 2s3S 2s",
		"6s2S2SS2 2S2SSS6Ss2SSSSS 2S 2S7 5SS2s", "2SS2S2 2S2 2S2SSS2SSS2SSSs2S2S 2S2S2 2 3Ss2s",
		"2SS 5S5s2S2SSS2SS 6SSS 5Ss2S2S2 2s3S 2s", "", "SSS6s5SSSS4S5s2S2s6s6 2S2 2S2 7SSs",
		"SSSs2S2S2SSS 2s2 2S2 3s2S 2SS2S3s2 2S2 2SSSS ", "SSSs2S2S2SSS2SS2S2 4 2S 2SS2S4 2 2S2 2SSSS ",
		"SSSs2S2S2SSS2SS2S2 7S 2SS2S7 2S2 6SSS", "SSSs2S2S2SSS2SS2S2 2 4S 2SS2S2 4 2S2 2SSSS ",
		"SSSs2S2S2SSS 2s2 2S2 2s3S 2SS2S2s3 2S2 2SSSS ", "SSSs2S 5SSSS4S5s2S2S 2S 6 2S2s5s7SSs"}
	local message_data_r1 = {"SSs7","SSs7","$ 1S1","$ 1S1","$ 1S1","$ 5","$s3 ","$SS","$6","SS1 7","SS1 1SS", "7 1SS", 
		"7 1SS","SS1 7","SS1s6","$SS"," 5S1s2 ","7 2 4","1Ss1 1s1s1","1Ss1 1s1s1","1Ss1 1s1 2","7 4 1 ",
		" 5S2S ","$SS","SSs7","SSs7","$s1S","$s1S","$s1S","SSs7","SSs7","$SS","s3$ "," 5$","2S2SSs","1Ss1SSs","1Ss1SSs",
		"2S2SSs"," 1S1$","$SS"," 5s7","7 7","1Ss1S1S1","1Ss1S1S1","1Ss1S1S1","7S5"," 5Ss3 ","$SS","7SSs","7 1SS",
		"S3s1S 1 ","s3S7"," 3S 7","7 1SS","7 1SS","$SS","$SS","SS1SSs","SS1SSs","7SSs","7SSs","SS1SSs","SS1SSs","$SS",
		"$1s2 ","1Ss1 2 4","1Ss1 1s1s1","7 1s1s1","7 1s1 2","1Ss1 4 1 ","1Ss1s2S ","$SS","7SSs","7SS 1","S3SSs1","s3S7",
		" 3S 7","7SS 1","7SS 1","$SS"," 6 5s","7 6 ","1$1s2","1$1S1","1$1s2","7 6 "," 6 5s","$SS","7 7","7 7", 
		"1s1s1S1S1","1s1s1s2S1","1s1s1 4s1","1s1s1 2 4","1Ss1 1s3 ","$SS","$SS","$Ss1","$Ss1","SSs7","SSs7","$Ss1","$Ss1"}
	local message_data_r2 = {"$SS 95","$SS 95","$$s11SS11","$$s11SS11","$$s11SS11","$$s91","$$S 6s","$$$S","$$9111",
		"$S11s95","$S11s11$S","95s11$S","95s11$S","$S11s95","$S11S 9111","$$$S","s91SS11S 1111s","95s1111s8",
		"11$ 11s11S 11S 11","11$ 11s11S 11S 11","11$ 11s11S 11s1111","95s8s11s","s91SS1111SSs","$$$S","$SS 95","$SS 95",
		"$$S 11SS","$$S 11SS","$$S 11SS","$SS 95","$SS 95","$$$S","S 6$$s","s91$$","1111SS1111$SS ","11$ 11$SS ",
		"11$ 11$SS ","1111SS1111$SS ","s11SS11$$","$$$S","s91S 95","95s95","11$ 11SS11SS11","11$ 11SS11SS11",
		"11$ 11SS11SS11","95SS91","s91$ 6s","$$$S","95$SS ","95s11$S","SS6S 11SSs11s","S 6SS95","s6SSs95","95s11$S",
		"95s11$S","$$$S","$$$S","$S11$SS ","$S11$SS ","95$SS ","95$SS ","$S11$SS ","$S11$SS ","$$$S","$$11S 1111s",
		"11$ 11s1111s8","11$ 11s11S 11S 11","95s11S 11S 11","95s11S 11s1111","11$ 11s8s11s","11$ 11S 1111SSs","$$$S",
		"95$SS ","95$Ss11","SS6$SS 11","S 6SS95","s6SSs95","95$Ss11","95$Ss11","$$$S","s9111s91S ","95s9111s",
		"11$$11S 1111","11$$11SS11","11$$11S 1111","95s9111s","s9111s91S ","$$$S","95s95","95s95","11S 11S 11SS11SS11",
		"11S 11S 11S 1111SS11","11S 11S 11s8S 11","11S 11S 11s1111s8","11$ 11s11S 6s","$$$S","$$$S","$$$ 11","$$$ 11",
		"$SS 95","$SS 95","$$$ 11","$$$ 11"};

	---------------------------------------------------------------------------
	-- Game specific functions
	---------------------------------------------------------------------------
	function dkong_func()
		-- ROM disassembly at:
		-- https://github.com/furrykef/dkdasm/blob/master/dkong.asm
		h_mode = read(0x600a)
		h_start_lives = read(0x6020)
		b_1p_game = read(0x600f, 0)
		b_almost_gameover = h_mode == 13 and read(0x6228, 1) and read(0x639d, 2)
		b_reset_continue = h_mode == 11
		b_reset_tally = h_mode == 7 or i_tally == nil
		b_show_tally = h_mode >= 8 and h_mode <= 16
		b_push_p1 = i_frame_stop and to_bits(read(0x7d00))[3] == 1

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not i_frame_stop then
				i_frame_stop = i_frame + 600
			end
			if i_frame_stop and i_frame_stop > i_frame then
				mem:write_u8(0x6009, 8) -- freeze game
				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x6228, h_start_lives + 1)
					i_frame_stop = nil
					for _add = 0x60b2, 0x60b4 do  mem:write_u8(_add, 0) end  -- reset score in memory
					for _add = 0x76e1, 0x7781, 0x20 do  mem:write_u8(_add, 0) end  -- reset score on screen
				end
			end
		end
	end

	function galaxian_func()
		-- ROM disassembly at:
		-- http://seanriddle.com/galaxian.asm
		h_mode = read(0x400a)
		h_start_lives = 2 + read(0x401f) -- read dip switch
		if emu:romname() == "moonaln" then
			h_start_lives = 3 + (read(0x401f) * 2) -- read dip switch
		end
		b_1p_game = read(0x400e, 0)
		b_almost_gameover = read(0x4201, 1) and read(0x421d, 0) and read(0x4205, 10)
		b_reset_continue = read(0x4200, 1)
		b_show_tally = read(0x4006)
		b_reset_tally = h_mode == 1 or i_tally == nil
		b_push_p1 = i_frame_stop and read(0x6800, 1)

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not i_frame_stop then
				i_frame_stop = i_frame + 600
			end
			if i_frame_stop and i_frame_stop > i_frame then
				mem:write_u8(0x4205, 0x10)  -- freeze by setting the animation counter
				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x421d, h_start_lives)
					i_frame_stop = nil

					for _add = 0x40a2, 0x40a4 do  mem:write_u8(_add, 0) end  -- reset score in memory
					for _add = 0x52e1, 0x53a1, 0x20 do mem:write_u8(_add, 16) end  -- reset onscreen score
					mem:write_u8(0x5301, 0)  -- rightmost zeros on screen
					mem:write_u8(0x52e1, 0)  -- rightmost zeros on screen
				end
			end
		end
	end

	function galaga_func()
		-- ROM disassembly at:
		-- https://github.com/hackbar/galaga
		h_mode = read(0x9201) -- 0=game ended, 1=attract, 2=ready to start, 3=playing
		h_start_lives = read(0x9982) + 1 --refer file "mrw.s" ram2 0x9800 + offset
		b_1p_game = read(0x99b3, 0)
		b_reset_tally = h_mode == 2 or i_tally == nil
		b_show_tally = h_mode == 3
		b_push_p1 = i_frame_stop and to_bits(ports[':IN1']:read())[3] == 0
		--check video ram for "CAPT" (part of FIGHTER CAPTURED message)
		_capt = read(0x81f1) == 0xc and read(0x81d1) == 0xa and read(0x81b1) == 0x19 and read(0x8191) == 0x1d
		-- no more ships and (explosion animation almost done or fighter was captured)
		b_reset_continue = h_mode ~= 3 or (not _capt and read(0x8863) == 2) -- not playing or explosion animation done
		b_almost_gameover = read(0x9820) == 0 and (read(0x8863) == 3 or _capt)

		if b_1p_game then
			if b_almost_gameover and not i_frame_stop then
				i_frame_stop = i_frame + 600
			end
			if i_frame_stop and i_frame_stop > i_frame then
				if not _captured then
					mem:write_u8(0x92a0, 1)  -- freeze the timer (counts upward to 255)
				end
				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x9820, h_start_lives)
					i_frame_stop = nil

					-- reset score in memory
					mem:write_u8(0x83f9, 0)
					for _add = 0x83fa, 0x83fe do mem:write_u8(_add, 36) end  -- reset score on screen
				end
			end
		end
	end

	function cclimber_func()
		-- ROM Disassembly at:
		-- https://computerarcheology.com/Arcade/CrazyClimber/
		h_mode = read(0x8075)
		h_start_lives = read(0x807e)
		b_1p_game = read(0x8080, 0)
		b_almost_gameover = read(0x8073, 0) and read(0x80d8, 0)
		b_reset_continue = h_mode == 0 or read(0x80d8) > 0
		b_show_tally = h_mode == 1
		b_reset_tally = h_mode == 0 or i_tally == nil
		b_push_p1 = i_frame_stop and to_bits(read(0xb800))[3] == 1

		if b_1p_game then
			if b_almost_gameover and not i_frame_stop then
				i_frame_stop = i_frame + 600
			end
			if i_frame_stop and i_frame_stop > i_frame then
				cpu.state["H"].value = 255  -- force delay timer to keep running
				cpu.state["L"].value = 255
				scr:draw_box(0, 224, 256, 80, BLACK, BLACK) -- black background
				draw_continue_box()
				if b_push_p1 then
					mem:write_u8(0x80d8, h_start_lives + 1)
					mem:write_u8(0x8073, 1)
					i_frame_stop = nil
					i_tally = i_tally + 1

					-- reset score in memory
					mem:write_u8(0x80d9, 0)
					mem:write_u8(0x80da, 0)
					mem:write_u8(0x80db, 0)
				end
			end
		end
	end

	function pacman_func()
		-- ROM disassembly at:
		-- https://github.com/BleuLlama/GameDocs/blob/master/disassemble/mspac.asm
		h_mode = read(0x4e00)
		h_start_lives = read(0x4e6f)
		b_1p_game = read(0x4e70, 0)
		b_game_restart = read(0x4e04, 2)
		b_almost_gameover = h_mode == 3 and read(0x4e14, 0) and read(0x4e04,4)
		b_reset_continue = read(0x4e03, 3)
		b_reset_tally = h_mode == 2 or i_tally == nil
		b_show_tally = h_mode == 3
		b_push_p1 = i_frame_stop and to_bits(read(0x5040))[6] == 0

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not i_frame_stop then
				i_frame_stop = i_frame + 600
				_pills_eaten = read(0x4e0e)
				_level = read(0x4e13)
			end
			if i_frame_stop and i_frame_stop > i_frame then
				mem:write_u8(0x4e04, 4)  -- freeze game
				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x4e04, 0)  -- unfreeze game
					mem:write_u8(0x4e14, h_start_lives)  --update number of lives
					mem:write_u8(0x4e15, h_start_lives - 1)  --update displayed number of lives
					i_frame_stop = nil

					for _addr = 0x4e80, 0x4e82 do mem:write_u8(_addr, 0) end  -- reset score in memory
					--reset score on screen
					for _i=0, 7 do
						if _i < 2 then _v = 0 else _v = 64 end
						mem:write_u8(0x43f7 + _i, _v)
					end
				end
			end
			if b_game_restart then
				mem:write_u8(0x4e0e, _pills_eaten)  -- restore the number of pills eaten after continue
				mem:write_u8(0x4e13, _level)		   -- restore level
			end
		end
	end

	function asteroid_func()
		-- Rom disassembly at:
		-- https://github.com/nmikstas/asteroids-disassembly/tree/master/AsteroidsSource
		h_mode = read(0x21b)
		h_start_lives = read(0x56)
		b_1p_game = read(0x1c, 1)
		b_reset_continue = h_mode == 255
		b_reset_tally = not b_1p_game or i_tally == nil
		b_show_tally = b_1p_game
		b_almost_gameover = h_mode == 160 and read(0x57, 0)
		b_push_p1 = i_frame_stop and read(0x2403, 128)

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not i_frame_stop then
				i_frame_stop = i_frame + 600
			end
			if i_frame_stop and i_frame_stop > i_frame then
				mem:write_u8(0x21b, 160)   -- freeze by setting the game mode counter

				message_data = flip_table(message_data_r2)
				scr:draw_box(348, 248, 660, 280, BLACK, BLACK) -- blackout the GAME OVER text
				draw_continue_box()
				if b_push_p1 then
					mem:write_u8(0x21b, 200) -- skip some of the explosion animation
					i_tally = i_tally + 1
					mem:write_u8(0x57, h_start_lives)
					i_frame_stop = nil

					--reset score in memory
					mem:write_u8(0x52, 0)
					mem:write_u8(0x53, 0)
				end
			end
		end
	end

	---------------------------------------------------------------------------
	-- Plugin functions
	---------------------------------------------------------------------------
	function initialize()
		if tonumber(emu.app_version()) >= 0.227 then
			mac = manager.machine
			ports = mac.ioport.ports
		elseif tonumber(emu.app_version()) >= 0.196 then
			mac = manager:machine()
			ports = mac:ioport().ports
		else
			print("ERROR: The continue plugin requires MAME version 0.196 or greater.")
		end
		if mac ~= nil then
			if rom_table[emu:romname()] then
				scr = mac.screens[":screen"]
				cpu = mac.devices[":maincpu"]
				mem = cpu.spaces["program"]
				rom_data = rom_table[emu:romname()]
				rom_function = _G[rom_data[1]]
				if rom_data[6] then
					message_data = message_data_r1
				end
				if rom_data[5] then
					message_data = flip_table(message_data)
				end
			else
				print("WARNING: The continue plugin does not support this rom.")
			end
		end
	end

	function main()
		if rom_function ~= nil then
			i_frame = scr:frame_number()
			rom_function()
			if b_reset_tally then i_tally = 0 end
			if b_1p_game then
				if b_reset_continue then i_frame_stop = nil end
				if b_show_tally then
					draw_tally(i_tally)
				end
			end
		end
	end

	function draw_graphic(data, pos_y, pos_x)
		local _len, _sub = string.len, string.sub
		local _pixel, _skip
		local _col, _scale = rom_data[4], rom_data[7]
		for _y, line in pairs(data) do
			_x = 1
			for _i=1, _len(line) do
				_skip = 1
				_pixel = _sub(line, _i, _i)
				if _pixel == "$" then _skip = 9     --skip multiple spaces
				elseif _pixel == "S" then _skip = 3
				elseif _pixel == "s" then _skip = 2 --
				elseif _pixel ~= " " then
					_skip = tonumber(_pixel)
					scr:draw_box(pos_y-_y*_scale, pos_x+_x, pos_y-(_y*_scale)+_scale, pos_x+_x+_skip, _col, _col)
				end
				_x = _x + _skip
			end
		end
	end

	function draw_progress_bar()
		local _y, _x, _scale = rom_data[3][1], rom_data[3][2], rom_data[7]
		local _cnt = math.floor((i_frame_stop - i_frame) / 6)
		local _col = rom_data[4]

		if _cnt < 40 and _cnt % 6 >= 3 then _col = RED end
		if rom_data[6] then  -- rotated
			scr:draw_box(_y-80, _x+(_scale*32), _y-80+_cnt, _x+(_scale*40), _col, _col)
		elseif rom_data[5] then -- flipped
			scr:draw_box(_y+(_scale*32), _x+112, _y+(_scale*40), _x+112-_cnt, _col, _col)
		else -- normal
			scr:draw_box(_y+(_scale*8), _x+8, _y+(_scale*16), _x+8+_cnt, _col, _col)
		end
	end

	function draw_continue_box()
		local _y, _x, _scale = rom_data[3][1], rom_data[3][2], rom_data[7]
		scr:draw_box(_y, _x, _y+(48*_scale), _x+120, BLACK, BLACK) -- black background
		if rom_data[5] then
			draw_graphic(message_data, _y+(24*_scale), _x+7) -- flipped graphics
		else
			draw_graphic(message_data, _y+(40*_scale), _x+7)
		end
		draw_progress_bar()
	end

	function draw_tally(n)
		-- chalk up the number of continues
		local _col, _y, _x
		local _cols = { WHITE, CYAN }
		for _i=0, n - 1 do
			_col = _cols[((math.floor(_i / 5)) % 2) + 1]
			_y, _x = rom_data[2][1], rom_data[2][2]
			if rom_data[5] and not rom_data[6] then
				scr:draw_box(_y, _x-(_i*4), _y+(4*rom_data[7]), _x+2-(_i*4), _col ,_col)  --flipped graphics
			else
				scr:draw_box(_y, _x+(_i*4), _y+(4*rom_data[7]), _x+2+(_i*4), _col ,_col)
			end
		end
	end

	function flip_table(t)
		local _f = {}
		for k, v in ipairs(t) do
			_f[#t+1-k] = string.reverse(v)
		end
		return _f
	end

	function to_bits(num)
		--return a table of bits, least significant first
		local _t={}
		while num>0 do
			rest=math.fmod(num,2)
			_t[#_t+1]=rest
			num=(num-rest)/2
		end
		return _t
	end

	function read(address, comparison)
		-- return data from memory address or boolean when the comparison value is provided
		_d = mem:read_u8(address)
		if comparison then
			return _d == comparison
		else
			return _d
		end
	end

	emu.register_start(function()
		initialize()
	end)

	emu.register_frame_done(main, "frame")
end
return exports