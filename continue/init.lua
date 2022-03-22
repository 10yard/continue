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
exports.version = "0.15"
exports.description = "Continue plugin"
exports.license = "GNU GPLv3"
exports.author = { name = "Jon Wilson (10yard)" }
local continue = exports

function continue.startplugin()
	-- mame system objects
	local mac, scr, cpu, mem

	-- general use variables
	local h_mode, h_start_lives, h_remain_lives
	local i_frame, i_stop, i_tally
	local b_1p_game, b_game_restart, b_almost_gameover, b_reset_continue, b_reset_tally, b_show_tally, b_push_p1

	-- colours
	local BLK, WHT, RED, YEL, CYN, GRN = 0xff000000, 0xffffffff, 0xffff0000, 0xfff8f91a, 0xff14f3ff, 0xff1fff1f

	-- compatible roms with associated function and position data
	local rom_data, rom_table = {}, {}
	local rom_function
	-- supported rom name     function       tally yx    msg yx    col  flip   rotate scale
	rom_table["missile"]    = {"missl_func", {001,001}, {152,080}, WHT, true,  true,  1}
	rom_table["suprmatk"]   = {"missl_func", {001,001}, {152,080}, WHT, true,  true,  1}
	rom_table["qbert"]      = {"qbert_func", {217,016}, {102,060}, WHT, false, false, 1}
	rom_table["qberta"]     = {"qbert_func", {217,016}, {102,060}, WHT, false, false, 1}
	rom_table["robotron"]   = {"rbtrn_func", {000,015}, {172,096}, YEL, true,  true,  1}
	rom_table["robotrontd"] = {"rbtrn_func", {000,015}, {172,096}, YEL, true,  true,  1}
	rom_table["robotron12"] = {"rbtrn_func", {000,015}, {172,096}, YEL, true,  true,  1}
	rom_table["robotronyo"] = {"rbtrn_func", {000,015}, {172,096}, YEL, true,  true,  1}
	rom_table["robotron87"] = {"rbtrn_func", {000,015}, {172,096}, YEL, true,  true,  1}
	rom_table["frogger"]    = {"frogr_func", {052,219}, {336,050}, WHT, true,  false, 3}
	rom_table["invaders"]   = {"invad_func", {237,009}, {102,050}, GRN, false, false, 1}
	rom_table["galaga"]     = {"galag_func", {016,219}, {102,050}, WHT, true,  false, 1}
	rom_table["galagamf"]   = {"galag_func", {016,219}, {102,050}, WHT, true,  false, 1}
	rom_table["galagamk"]   = {"galag_func", {016,219}, {102,050}, WHT, true,  false, 1}
	rom_table["galaxian"]   = {"galax_func", {052,216}, {328,052}, WHT, true,  false, 3}
	rom_table["superg"]     = {"galax_func", {052,216}, {328,052}, WHT, true,  false, 3}
	rom_table["moonaln"]    = {"galax_func", {052,216}, {328,052}, WHT, true,  false, 3}
	rom_table["pacman"]     = {"pacmn_func", {018,216}, {120,050}, WHT, true,  false, 1}
	rom_table["pacmanf"]    = {"pacmn_func", {018,216}, {120,050}, WHT, true,  false, 1}
	rom_table["mspacman"]   = {"pacmn_func", {018,216}, {120,050}, WHT, true,  false, 1}
	rom_table["mspacmnf"]   = {"pacmn_func", {018,216}, {120,050}, WHT, true,  false, 1}
	rom_table["mspacmat"]   = {"pacmn_func", {018,216}, {120,050}, WHT, true,  false, 1}
	rom_table["pacplus"]    = {"pacmn_func", {018,216}, {120,050}, WHT, true,  false, 1}
	rom_table["dkong"]      = {"dkong_func", {219,009}, {096,050}, CYN, false, false, 1}
	rom_table["dkongjr"]    = {"dkong_func", {230,154}, {096,050}, YEL, false, false, 1}
	rom_table["dkongx"]     = {"dkong_func", {219,009}, {096,050}, CYN, false, false, 1}
	rom_table["dkongx11"]   = {"dkong_func", {219,009}, {096,050}, CYN, false, false, 1}
	rom_table["dkongpe"]    = {"dkong_func", {219,009}, {096,050}, CYN, false, false, 1}
	rom_table["dkonghrd"]   = {"dkong_func", {219,009}, {096,050}, CYN, false, false, 1}
	rom_table["dkongf"]     = {"dkong_func", {219,009}, {096,050}, CYN, false, false, 1}
	rom_table["dkongj"]     = {"dkong_func", {219,009}, {096,050}, CYN, false, false, 1}
	rom_table["asteroid"]   = {"aster_func", {008,008}, {540,240}, WHT, false, true,  2}
	rom_table["cclimber"]   = {"climb_func", {009,048}, {156,080}, CYN, true,  true,  1}
	--rom_table["sinistar"]   = {"snstr_func", {217,016}, {102,060}, WHT, false, false, 1}

	-- encoded message data
	local message_data = {"6s2S2s4S2S2SSS6Ss2SSSS4S 6S3S6S6", "2S2 2S2 2s2s2S2SSS2S2S3SSSs2s2Ss2S 2 2s2S2S 2s",
		"2S2 2S2 2SS2S2SSS2S2S 2SSSs2SSS2S2S2 2S2S 2s", "2S2 2S2s5s7SSS2S2S 2SSSS5Ss2S2S2 2s3S 2s",
		"6s2S2SS2 2S2SSS6Ss2SSSSS 2S 2S7 5SS2s", "2SS2S2 2S2 2S2SSS2SSS2SSSs2S2S 2S2S2 2 3Ss2s",
		"2SS 5S5s2S2SSS2SS 6SSS 5Ss2S2S2 2s3S 2s", "", "SSS6s5SSSS4S5s2S2s6s6 2S2 2S2 7SSs",
		"SSSs2S2S2SSS 2s2 2S2 3s2S 2SS2S3s2 2S2 2SSSS ", "SSSs2S2S2SSS2SS2S2 4 2S 2SS2S4 2 2S2 2SSSS ",
		"SSSs2S2S2SSS2SS2S2 7S 2SS2S7 2S2 6SSS", "SSSs2S2S2SSS2SS2S2 2 4S 2SS2S2 4 2S2 2SSSS ",
		"SSSs2S2S2SSS 2s2 2S2 2s3S 2SS2S2s3 2S2 2SSSS ", "SSSs2S 5SSSS4S5s2S2S 2S 6 2S2s5s7SSs"}
	local message_data_r1 = {"SSs7","SSs7","$ 1S1","$ 1S1","$ 1S1","$ 5","$s3 ","$SS","$6","SS1 7","SS1 1SS", "7 1SS",
		"7 1SS","SS1 7","SS1s6","$SS"," 5S1s2 ","7 2 4","1Ss1 1s1s1","1Ss1 1s1s1","1Ss1 1s1 2","7 4 1 "," 5S2S ","$SS",
		"SSs7","SSs7","$s1S","$s1S","$s1S","SSs7","SSs7","$SS","s3$ "," 5$","2S2SSs","1Ss1SSs","1Ss1SSs","2S2SSs",
		" 1S1$","$SS"," 5s7","7 7","1Ss1S1S1","1Ss1S1S1","1Ss1S1S1","7S5"," 5Ss3 ","$SS","7SSs","7 1SS","S3s1S 1 ",
		"s3S7"," 3S 7","7 1SS","7 1SS","$SS","$SS","SS1SSs","SS1SSs","7SSs","7SSs","SS1SSs","SS1SSs","$SS","$1s2 ",
		"1Ss1 2 4","1Ss1 1s1s1","7 1s1s1","7 1s1 2","1Ss1 4 1 ","1Ss1s2S ","$SS","7SSs","7SS 1","S3SSs1","s3S7"," 3S 7",
		"7SS 1","7SS 1","$SS"," 6 5s","7 6 ","1$1s2","1$1S1","1$1s2","7 6 "," 6 5s","$SS","7 7","7 7","1s1s1S1S1",
		"1s1s1s2S1","1s1s1 4s1","1s1s1 2 4","1Ss1 1s3 ","$SS","$SS","$Ss1","$Ss1","SSs7","SSs7","$Ss1","$Ss1"}
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
	function missl_func()
		-- ROM disassembly at https://6502disassembly.com/va-missile-command/
		h_mode = read(0x93)  -- 0x0=not playing, 0xff=playing
		h_remain_lives = read(0xc0)  -- remaining cities
		b_push_p1 = to_bits(ports[":IN0"]:read())[5] == 0
		b_1p_game = read(0xae, 0)
		b_reset_tally = h_mode == 0x0 or i_tally == nil
		b_reset_continue = h_remain_lives > 1
		b_show_tally = h_mode == 0xff
		if b_reset_tally or not h_start_lives then
			h_start_lives = 3 + to_bits(ports[":R8"]:read())[1]*2 + to_bits(ports[":R8"]:read())[2] -- read lives from dips
			if h_start_lives == 3 then
				h_start_lives = 7
			end
		end
		b_almost_gameover = b_1p_game and h_mode == 0xff and h_remain_lives == 0

		---- Logic
		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 170
				_hide_stop = i_stop + 90  -- hide the playfield during message and for 90 frames after pushing continue
				video.throttle_rate = 0.35 -- adjust emulation speed to allow more time for decision
			end
			if _hide_stop and _hide_stop > i_frame then
				scr:draw_box(0,8, 256, 232, BLK, BLK)  -- temporarily hide the play field
			end
			if i_stop and i_stop > i_frame then
				draw_continue_box(4)
				if b_push_p1 then
					video.throttle_rate = 1  -- restore emulation to full speed
					i_tally = i_tally + 1
					mem:write_u8(0xc0, h_start_lives)
					mem:write_u8(0xcf, 0)
					i_stop = nil
					for _add = 0x01d6, 0x01db do  mem:write_u8(_add, 0) end  -- reset score in memory
					mem:write_u8(0xd4, 0xff)  -- set flag to redraw the score
				end
			else
				video.throttle_rate = 1  -- restore emulation to full speed
			end
		end
	end

	function rbtrn_func()
		h_mode = read(0x98d1)  -- 0=high score screen, 1=attract mode, 2=playing
		h_start_lives = 3
		h_remain_lives = read(0xbdec)
		b_1p_game = read(0x983f, 1)
		b_push_p1 = i_stop and to_bits(ports[":IN0"]:read())[5] == 1
		b_reset_tally = h_mode ~= 2 or i_tally == nil
		b_show_tally = b_1p_game and h_mode == 2
		b_reset_continue = h_mode ~=2 or h_remain_lives >= 1
		b_almost_gameover = h_mode == 2 and h_remain_lives == 0 and read(0x9859) == 0x1b  -- 0x1b when player dies
		if not sound then sound = {} end
		if b_reset_tally then
			_attenuation = sound.attenuation
		end

		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 90
				_hide_stop = i_stop + 35  -- hide the playfield during message and for 35 frames after pushing continue
				video.throttle_rate = 0.2 -- adjust emulation speed to allow more time for decision
			end

			if _hide_stop and _hide_stop > i_frame then
				scr:draw_box(8,17, 282, 228, BLK, BLK)  -- temporarily hide the play field
			end

			if i_stop and i_stop > i_frame then
				mem:write_u8(0x9848, 0)  -- switch off player collisions while waiting for decision
				draw_continue_box(6)
				if sound then sound.attenuation = -32 end
				if b_push_p1 then
					video.throttle_rate = 1  -- restore emulation to full speed
					if sound then sound.attenuation = _attenuation end
					i_tally = i_tally + 1
					i_stop = nil
					mem:write_u8(0xbdec, h_start_lives)
					-- reset score in memory
					for _addr=0xbde4, 0xbde7 do
						mem:write_u8(_addr, 0x00)
					end
				end
			else
				video.throttle_rate = 1  -- restore emulation to full speed
				if sound then sound.attenuation = _attenuation end
			end
		end
	end

	function qbert_func()
		-- No commented rom disassembly available. I worked this one out using MAME debugger.
		--   0000-1fff RAM
		--   3800-3fff video RAM
		_demo = to_bits(read(0x5800))[4] == 1  -- unlimited lives/demo mode.  Disable continue option
		h_mode =  read(0x1fee) -- 0xf4=waiting to start
		h_start_lives = 3
		h_remain_lives = read(0xd00)
		b_1p_game = read(0xb2, 0)
		_dead = read(0x1fed, 0xbb) or read(0x1fed, 0xbd)
		b_almost_gameover = h_remain_lives == 1 and _dead and _dead_count == 50 -- react to dead status at 50 ticks
		b_reset_tally = h_mode == 0xf4 or i_tally == nil
		b_show_tally = h_remain_lives >= 1 and h_mode ~=0xf4 and read(0x3da3) ~= 0xa5  --0xa5 is a tile on level screen
		b_reset_continue = h_remain_lives > 1
		b_push_p1 = i_stop and to_bits(ports[":IN1"]:read())[1] == 1
		-- count the dead status flag and react when it hits 50
		if _dead then _dead_count = _dead_count + 1 else _dead_count = 0 end

		-- Logic
		if b_1p_game and not _demo then
			-- redraw lives as game does not refresh them
			if b_show_tally then
				for _k, _v in ipairs({0x3835, 0x3833, 0x3831}) do
					if _k < h_remain_lives then
						mem:write_u8(_v, 0xac)
						mem:write_u8(_v+1, 0xad)
					else
						mem:write_u8(_v, 0x24)
						mem:write_u8(_v+1, 0x24)
					end
				end
			end

			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 600
			end
			if i_stop and i_stop > i_frame then
				cpu.state["CX"].value = 5  -- force delay timer to keep running
				draw_continue_box()

				if b_push_p1 then
					i_tally = i_tally + 1
					i_stop = nil
					mem:write_u8(0xd00, h_start_lives + 1)

					--reset this counter - to fix a glitch wih blank lines being written to screen.  Assume these
					--blank lines were removing the lives from screen.`
					mem:write_u8(0xd24, 0x30)

					-- reset score in memory (do we need to clear more bytes?)
					for _addr=0xbc, 0xc1 do mem:write_u8(_addr, 0) end

					-- and also here in memory
					for _addr=0xc6, 0xca do mem:write_u8(_addr, 0x24) end
					for _addr=0xcb, 0xcd do mem:write_u8(_addr, 0x0) end

					-- and also on screen
					mem:write_u8(0x385c, 0x0)
					for _addr=0x387c, 0x397c, 0x20 do mem:write_u8(_addr, 0x24) end
				end
			end
		end
	end

	function dkong_func()
		-- ROM disassembly at https://github.com/furrykef/dkdasm/blob/master/dkong.asm
		h_mode = read(0x600a)
		h_start_lives = read(0x6020)
		b_1p_game = read(0x600f, 0)
		b_almost_gameover = h_mode == 13 and read(0x6228, 1) and read(0x639d, 2)
		b_reset_continue = h_mode == 11
		b_reset_tally = h_mode == 7 or i_tally == nil
		b_show_tally = h_mode >= 8 and h_mode <= 16
		b_push_p1 = i_stop and to_bits(read(0x7d00))[3] == 1

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 600
			end
			if i_stop and i_stop > i_frame then
				mem:write_u8(0x6009, 8) -- suspend game
				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x6228, h_start_lives + 1)
					i_stop = nil
					for _add = 0x60b2, 0x60b4 do  mem:write_u8(_add, 0) end  -- reset score in memory
					for _add = 0x76e1, 0x7781, 0x20 do  mem:write_u8(_add, 0) end  -- reset score on screen
				end
			end
		end
	end

	function galax_func()
		-- ROM disassembly at http://seanriddle.com/galaxian.asm
		h_mode = read(0x400a)
		h_start_lives = 2 + read(0x401f)  -- read dip switch
		if emu:romname() == "moonaln" then
			h_start_lives = 3 + (read(0x401f) * 2)  -- read dip switch
		end
		b_1p_game = read(0x400e, 0)
		b_almost_gameover = read(0x4201, 1) and read(0x421d, 0) and read(0x4205, 10)
		b_reset_continue = read(0x4200, 1)  -- player has spawned
		b_show_tally = read(0x4006)  -- game is in play
		b_reset_tally = h_mode == 1 or i_tally == nil
		b_push_p1 = i_stop and read(0x6800, 1)

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 600
			end
			if i_stop and i_stop > i_frame then
				mem:write_u8(0x4205, 0x10)  -- suspend game by setting the animation counter
				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x421d, h_start_lives)
					i_stop = nil
					for _add = 0x40a2, 0x40a4 do  mem:write_u8(_add, 0) end  -- reset score in memory
					for _add = 0x52e1, 0x53a1, 0x20 do mem:write_u8(_add, 16) end  -- reset onscreen score
					mem:write_u8(0x5301, 0)  -- rightmost zeros on screen
					mem:write_u8(0x52e1, 0)  -- rightmost zeros on screen
				end
			end
		end
	end

	function galag_func()
		-- ROM disassembly at https://github.com/hackbar/galaga
		h_mode = read(0x9201)  -- 0=game ended, 1=attract, 2=ready to start, 3=playing
		h_start_lives = read(0x9982) + 1  --refer file "mrw.s" ram2 0x9800 + offset
		h_remain_lives = read(0x9820)
		b_1p_game = read(0x99b3, 0)
		b_reset_tally = h_mode == 2 or i_tally == nil
		b_show_tally = h_mode == 3
		b_push_p1 = i_stop and to_bits(ports[':IN1']:read())[3] == 0
		b_reset_continue = h_mode ~= 3 or h_remain_lives >= 1

		-- check video ram for "CAPT" (part of FIGHTER CAPTURED message)
		_capt = read(0x81f1) == 0xc and read(0x81d1) == 0xa and read(0x81b1) == 0x19 and read(0x8191) == 0x1d
		-- no more ships and (explosion animation almost done or fighter was captured)
		b_almost_gameover = read(0x9820) == 0 and (read(0x8863) == 3 or _capt)

		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 600
			end
			if i_stop and i_stop > i_frame then
				if not _capt then
					mem:write_u8(0x92a0, 1)  -- suspend game by resetting the timer (counts upward to 255)
				end
				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x9820, h_start_lives)
					i_stop = nil
					-- reset score in memory
					mem:write_u8(0x83f9, 0)
					for _add = 0x83fa, 0x83fe do mem:write_u8(_add, 36) end  -- reset score on screen
				end
			end
		end
	end

	function frogr_func()
		-- No commented rom disassembly available. I worked this one out using MAME debugger.
		-- Useful map info from MAME Driver:
		--   map(0x8000, 0x87ff) is ram
		--   map(0xa800, 0xabff) is videoram
		h_mode = read(0x803f) -- 1=not playing, 3=playing game (can mean attract mode too)
		h_start_lives = read(0x83e4)
		h_remain_lives = read(0x83e5)
		b_1p_game = read(0x83fe) == 1
		b_push_p1 = i_stop and not to_bits(ports[":IN1"]:read())[8]
		b_reset_tally = h_mode == 1 or i_tally == nil
		b_show_tally = h_mode == 3 and b_1p_game
		b_reset_continue = h_mode ~= 3 or h_remain_lives >= 1

		if h_mode == 0 and read(0x83dd, 0) and read(0x83dc) < 10 then
			-- force death just before timer expiry so we can display the continue message
			mem:write_u8(0x803f, 3)
			mem:write_u8(0x8004, 1)
		end

		b_almost_gameover = h_remain_lives == 0 and  h_mode == 3 and read(0x8045, 0x3c)

		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 600
			end
			if i_stop and i_stop > i_frame then
				cpu.state["H"].value = 255  -- force delay timer to keep running
				cpu.state["L"].value = 255

				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x83e5, h_start_lives + 1)
					mem:write_u8(0x83ae, 1)
					mem:write_u8(0x83ea, 0)
					i_stop = nil
					-- reset score in memory
					mem:write_u8(0x83ec, 0)
					mem:write_u8(0x83ed, 0)
					mem:write_u8(0x83ee, 0)
				end
			end
		end
	end

	function invad_func()
		-- ROM Disassembly at https://computerarcheology.com
		h_mode = read(0x20ef)  -- 1=game running, 0=demo or splash screens
		h_remain_lives = read(0x21ff)
		b_1p_game = read(0x20ce, 0)
		b_reset_tally = h_mode == 0 or i_tally == nil
		b_show_tally = h_mode == 1
		b_push_p1 = i_stop and to_bits(ports[':IN1']:read())[3] == 1
		-- player was blown up on last life. Animation sprite and timer indicate a specific frame
		b_almost_gameover = read(0x2015) < 128 and h_remain_lives == 0 and read(0x2016) == 1 and read(0x2017) == 1
		b_reset_continue = mode == 0 or h_remain_lives >= 1
		h_start_lives = 3
		if to_bits(ports[':IN2']:read())[1] == 1 then h_start_lives = h_start_lives + 1 end  -- dip adjust start lives
		if to_bits(ports[':IN2']:read())[2] == 1 then h_start_lives = h_start_lives + 1 end  -- dip adjust start lives

		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 600
			end
			if i_stop and i_stop > i_frame then
				mem:write_u8(0x20e9, 0) -- suspend game
				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x21ff, h_start_lives)
					mem:write_u8(0x20e9, 1) -- unsuspend game
					i_stop = nil
					--update score in memory
					mem:write_u8(0x20f8, 0)
					mem:write_u8(0x20f9, 0)
					-- dummy screen update - by pushing 0 score adjustment
					mem:write_u8(0x20f1,1)  -- adjust score flag
					mem:write_u8(0x20f2,0)  -- score adjustment
				end
			else
				mem:write_u8(0x20e9, 1) -- unsuspend game
				-- dummy screen update - by pushing 0 score adjustment
				mem:write_u8(0x20f1,1)  -- adjust score flag
				mem:write_u8(0x20f2,0)  -- score adjustment
			end
		end
	end

	function climb_func()
		-- ROM Disassembly at https://computerarcheology.com
		h_mode = read(0x8075)
		h_start_lives = read(0x807e)
		h_remain_lives = read(0x80d8)
		b_1p_game = read(0x8080, 0)
		b_almost_gameover = read(0x8073, 0) and h_remain_lives == 0
		b_reset_continue = h_mode == 0 or h_remain_lives >= 1
		b_show_tally = h_mode == 1
		b_reset_tally = h_mode == 0 or i_tally == nil
		b_push_p1 = i_stop and to_bits(read(0xb800))[3] == 1

		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 600
			end
			if i_stop and i_stop > i_frame then
				cpu.state["H"].value = 255  -- force delay timer to keep running
				cpu.state["L"].value = 255
				scr:draw_box(0, 224, 256, 80, BLK, BLK)  -- black background
				draw_continue_box()
				if b_push_p1 then
					mem:write_u8(0x80d8, h_start_lives + 1)
					mem:write_u8(0x8073, 1)
					i_stop = nil
					i_tally = i_tally + 1
					-- reset score in memory
					mem:write_u8(0x80d9, 0)
					mem:write_u8(0x80da, 0)
					mem:write_u8(0x80db, 0)
				end
			end
		end
	end

	function pacmn_func()
		-- ROM disassembly at https://github.com/BleuLlama/GameDocs/blob/master/disassemble/mspac.asm
		h_mode = read(0x4e00)
		h_start_lives = read(0x4e6f)
		h_remain_lives = read(0x4e14)
		b_1p_game = read(0x4e70, 0)
		b_game_restart = read(0x4e04, 2)
		b_almost_gameover = h_mode == 3 and h_remain_lives == 0 and read(0x4e04,4)
		b_reset_continue = read(0x4e03, 3)
		b_reset_tally = h_mode == 2 or i_tally == nil
		b_show_tally = h_mode == 3
		b_push_p1 = i_stop and to_bits(read(0x5040))[6] == 0

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 600
				_pills_eaten = read(0x4e0e)
				_level = read(0x4e13)
			end
			if i_stop and i_stop > i_frame then
				mem:write_u8(0x4e04, 4)  -- suspend game
				draw_continue_box()
				if b_push_p1 then
					i_tally = i_tally + 1
					mem:write_u8(0x4e04, 0)  -- unsuspend
					mem:write_u8(0x4e14, h_start_lives)  --update number of lives
					mem:write_u8(0x4e15, h_start_lives - 1)  --update displayed number of lives
					i_stop = nil

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
				mem:write_u8(0x4e13, _level)  -- restore level
			end
		end
	end

	function aster_func()
		-- Rom disassembly at https://github.com/nmikstas/asteroids-disassembly/tree/master/AsteroidsSource
		h_mode = read(0x21b)
		h_start_lives = read(0x56)
		h_remain_lives = read(0x57)
		b_1p_game = read(0x1c, 1)
		b_reset_continue = h_mode == 255
		b_reset_tally = not b_1p_game or i_tally == nil
		b_show_tally = b_1p_game
		b_almost_gameover = h_mode == 160 and h_remain_lives == 0
		b_push_p1 = i_stop and read(0x2403, 128)

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not i_stop then
				i_stop = i_frame + 600
			end
			if i_stop and i_stop > i_frame then
				mem:write_u8(0x21b, 160)  -- suspend game by setting the game mode counter

				message_data = flip_table(message_data_r2)
				scr:draw_box(348, 248, 660, 280, BLK, BLK)  -- blackout the GAME OVER text
				draw_continue_box()
				if b_push_p1 then
					mem:write_u8(0x21b, 200)  -- skip some of the explosion animation
					i_tally = i_tally + 1
					mem:write_u8(0x57, h_start_lives)
					i_stop = nil

					--reset score in memory
					mem:write_u8(0x52, 0)
					mem:write_u8(0x53, 0)
				end
			end
		end
	end

	--function snstr_func()
	--	-- WORK IN PROGRESS
	--	-- No commented rom disassembly available. I worked this one out using MAME debugger.
	--	-- Useful map info from MAME Driver:
	--	--   0000-8fff Video RAM
    --	--   9800-bfff RAM
	--	h_start_lives = 3
	--	h_remain_lives = read(0x9ffc)
	--
	--	i_stop = true
	--	b_push_p1 = i_stop and to_bits(ports[":IN1"]:read())[5] == 1
	--	if b_push_p1 then
	--		-- search for 2450
	--		for _addr=0x0000, 0xbfff do
	--			if read(_addr, 0) and read(_addr+1, 5) and read(_addr+2, 4) and read(_addr+3, 2) then
	--				print(string.format("%x",_addr))
	--			end
	--		end
	--
	--		-- reset score in memory
	--		--for _addr=0xa004, 0xa009 do mem:write_u8(_addr, 0x00) end
	--		-- reset score in video ram
	--		--for _addr=0x9ffd, 0xa000 do mem:write_u8(_addr, 0x00) end
	--
	--	end
	--end

	---------------------------------------------------------------------------
	-- Plugin functions
	---------------------------------------------------------------------------
	function initialize()
		if tonumber(emu.app_version()) >= 0.227 then
			mac = manager.machine
			ports = mac.ioport.ports
			video = mac.video
			sound = mac.sound
		elseif tonumber(emu.app_version()) >= 0.196 then
			mac = manager:machine()
			ports = mac:ioport().ports
			video = mac:video()
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
				if b_reset_continue then i_stop = nil end
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
				if _pixel == "$" then _skip = 9  --skip multiple spaces
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

	function draw_progress_bar(speed_factor)
		local _y, _x, _scale = rom_data[3][1], rom_data[3][2], rom_data[7]
		local _cnt = math.floor((i_stop - i_frame) / 6)
		local _col = rom_data[4]

		if _cnt < 35 / speed_factor and (_cnt % 6 >= 3 or speed_factor > 2) then _col = RED end
		if rom_data[6] then  -- rotated
			scr:draw_box(_y-80, _x+(_scale*32), _y-80+(_cnt*speed_factor), _x+(_scale*40), _col, _col)
		elseif rom_data[5] then -- flipped
			scr:draw_box(_y+(_scale*32), _x+112, _y+(_scale*40), _x+112-(_cnt*speed_factor), _col, _col)
		else -- normal
			scr:draw_box(_y+(_scale*8), _x+8, _y+(_scale*16), _x+8+(_cnt*speed_factor), _col, _col)
		end
	end

	function draw_continue_box(speed_factor)
		_speed = speed_factor or 1
		local _y, _x, _scale = rom_data[3][1], rom_data[3][2], rom_data[7]
		if rom_data[6] then
			scr:draw_box(_y-88, _x, _y+32, _x+(48*_scale), BLK, BLK)  -- rotate black backround
		else
			scr:draw_box(_y, _x, _y+(48*_scale), _x+120, BLK, BLK)  -- black background
		end
		if rom_data[5] then
			draw_graphic(message_data, _y+(24*_scale), _x+7)  -- flipped graphics
		else
			draw_graphic(message_data, _y+(40*_scale), _x+7)
		end
		draw_progress_bar(_speed)
	end

	function draw_tally(n)
		-- chalk up the number of continues
		local _col, _y, _x
		local _cols = { WHT, CYN }
		_y, _x = rom_data[2][1], rom_data[2][2]
		for _i=0, n - 1 do
			_col = _cols[((math.floor(_i / 5)) % 2) + 1]
			if rom_data[5] and not rom_data[6] then
				scr:draw_box(_y-1, _x-(_i*4)-1, _y+(4*rom_data[7])+1, _x+2-(_i*4)+1, BLK ,BLK)  -- black background
				scr:draw_box(_y, _x-(_i*4), _y+(4*rom_data[7]), _x+2-(_i*4), _col ,_col)  --flipped
			else
				scr:draw_box(_y-1, _x+(_i*4)-1, _y+(4*rom_data[7])+1, _x+2+(_i*4)+1, BLK ,BLK) -- black background
				scr:draw_box(_y, _x+(_i*4), _y+(4*rom_data[7]), _x+2+(_i*4), _col ,_col) -- regular
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