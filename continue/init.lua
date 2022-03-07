-- Continue Plugin for MAME
-- by Jon Wilson (10yard)
--
-- Adds continue option with countdown timer.  Push P1 Start button to continue your game.  Your score will be reset.
-- A tally of the number of continues appears at top of screen.
--
-- Tested with latest MAME version 0.241
-- Fully compatible with all MAME versions from 0.196
--
-- Minimum start up arguments:
--   mame mspacman -plugin continue
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
	local frame, frame_stop
	local mode, start_lives, tally
	local b_1p_game, b_game_restart, b_almost_gameover, b_reset_continue, b_reset_tally, b_show_tally

	-- colours
	local BLACK = 0xff000000
	local WHITE = 0xffffffff
	local RED = 0xffff0000
	local YELLOW = 0xfff8f91a
	local CYAN = 0xff14f3ff

	-- compatible roms with associated function and position data
	local rom_function
	local rom_data = {}
	local rom_table = {}

	-- supported rom name   function          tally yx   msg yx   color   flip   scale
	rom_table["galaxian"] = {"galaxian_func", {52, 216}, {96,50}, WHITE,  true,  3}
	rom_table["superg"]   = {"galaxian_func", {52, 216}, {96,50}, WHITE,  true,  3}
	rom_table["moonaln"]  = {"galaxian_func", {52, 216}, {96,50}, WHITE,  true,  3}
	rom_table["pacman"]   = {"pacman_func",   {18, 216}, {96,50}, WHITE,  true,  1}
	rom_table["mspacman"] = {"pacman_func",   {18, 216}, {96,50}, WHITE,  true,  1}
	rom_table["mspacmat"] = {"pacman_func",   {18, 216}, {96,50}, WHITE,  true,  1}
	rom_table["pacplus"]  = {"pacman_func",   {18, 216}, {96,50}, WHITE,  true,  1}
	rom_table["dkong"]    = {"dkong_func",     {219, 9}, {96,50}, CYAN,   false, 1}
	rom_table["dkongjr"]  = {"dkong_func",   {229, 154}, {96,50}, YELLOW, false, 1}
	rom_table["dkongx"]   = {"dkong_func",     {219, 9}, {96,50}, CYAN,   false, 1}
	rom_table["dkongx11"] = {"dkong_func",     {219, 9}, {96,50}, CYAN,   false, 1}
	rom_table["dkongpe"]  = {"dkong_func",     {219, 9}, {96,50}, CYAN,   false, 1}
	rom_table["dkonghrd"] = {"dkong_func",     {219, 9}, {96,50}, CYAN,   false, 1}
	rom_table["dkongf"]   = {"dkong_func",     {219, 9}, {96,50}, CYAN,   false, 1}
	rom_table["dkongj"]   = {"dkong_func",     {219, 9}, {96,50}, CYAN,   false, 1}
	rom_table["asteroid"] = {"asteroid_func" , {10, 10}, {-96,50}, WHITE,  true,  3}

	local message_data = {
		"6  2S2  4S2S2SSS6S  2SSSS4S 6S3S6S6", "2S2 2S2 2  2  2S2SSS2S2S3SSS  2  2S  2S 2 2  2S2S 2  ",
		"2S2 2S2 2SS2S2SSS2S2S 2SSS  2SSS2S2S2 2S2S 2  ", "2S2 2S2  5  7SSS2S2S 2SSSS5S  2S2S2 2  3S 2  ",
		"6  2S2SS2 2S2SSS6S  2SSSSS 2S 2S7 5SS2  ", "2SS2S2 2S2 2S2SSS2SSS2SSS  2S2S 2S2S2 2 3S  2  ",
		"2SS 5S5  2S2SSS2SS 6SSS 5S  2S2S2 2  3S 2  ", "", "SSS6  5SSSS4S5  2S2  6  6 2S2 2S2 7SS  ",
		"SSS  2S2S2SSS 2  2 2S2 3  2S 2SS2S3  2 2S2 2SSSS ", "SSS  2S2S2SSS2SS2S2 4 2S 2SS2S4 2 2S2 2SSSS ",
		"SSS  2S2S2SSS2SS2S2 7S 2SS2S7 2S2 6SSS", "SSS  2S2S2SSS2SS2S2 2 4S 2SS2S2 4 2S2 2SSSS ",
		"SSS  2S2S2SSS 2  2 2S2 2  3S 2SS2S2  3 2S2 2SSSS ", "SSS  2S 5SSSS4S5  2S2S 2S 6 2S2  5  7SS  "}
	local message_data_flipped = {}

	---------------------------------------------------------------------------
	-- GAME/ROM SPECIFIC FUNCTIONS
	---------------------------------------------------------------------------
	function pacman_func()
		mode = read(0x4e00)
		start_lives = read(0x4e6f)
		b_1p_game = read(0x4e70, 0)
		b_game_restart = read(0x4e04, 2)
		b_almost_gameover = mode == 3 and read(0x4e14, 0) and read(0x4e04,6)
		b_reset_continue = read(0x4e03, 3)
		b_reset_tally = mode == 2 or tally == nil
		b_show_tally = mode == 3

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not frame_stop then
				frame_stop = frame + 600
				pills_eaten = read(0x4e0e)
			end
			if frame_stop then
				if frame < frame_stop then
					mem:write_u8(0x4e04, 2)  -- freeze game
					draw_continue_box()

					if to_bits(read(0x5040))[6] == 0 then  -- P1 button pushed
						tally = tally + 1
						mem:write_u8(0x4e04, 0)  -- unfreeze game
						mem:write_u8(0x4e14, start_lives)  --update number of lives
						mem:write_u8(0x4e15, start_lives - 1)  --update displayed number of lives
						frame_stop = nil

						-- reset score in memory
						for _addr = 0x4e80, 0x4e82 do
							mem:write_u8(_addr, 0)
						end

						--reset score on screen
						_addr = 0x43f7
						if emu:romname() == "jrpacman" then
							_addr = 0x4777
						end
						for _i=0, 7 do
							if _i < 2 then
								mem:write_u8(_addr + _i, 0)
							else
								mem:write_u8(_addr + _i, 64)
							end
						end
					end
				else
					frame_stop = nil
					mem:write_u8(0x4e04, 6)  -- unfreeze game
				end
			end
			if b_game_restart then
				mem:write_u8(0x4e0e, pills_eaten)  -- restore the number of pills eaten after continue
			end
		end
	end

	function galaxian_func()
		mode = read(0x400a)
		start_lives = 2 + read(0x401f) -- read dip switch
		if emu:romname() == "moonaln" then
			start_lives = 3 + (read(0x401f) * 2) -- read dip switch
		end
		b_1p_game = read(0x400e, 0)
		b_almost_gameover = read(0x4201, 1) and read(0x421d, 0) and read(0x4205, 10)
		b_reset_continue = read(0x4200, 1)
		b_show_tally = read(0x4006)
		b_reset_tally = mode == 1 or tally == nil

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not frame_stop then
				frame_stop = frame + 600
			end
			if frame_stop and frame_stop > frame then
				mem:write_u8(0x4205, 0x10) -- freeze by setting the animation counter
				draw_continue_box()

				if read(0x6800, 1) then -- P1 button pushed
					tally = tally + 1
					mem:write_u8(0x421d, start_lives)
					frame_stop = nil

					--reset score
					for _add = 0x40a2, 0x40a4 do  -- score in memory
						mem:write_u8(_add, 0)
					end
					for _add = 0x52e1, 0x53a1, 0x20 do -- on screen score
						mem:write_u8(_add, 16)
					end
					mem:write_u8(0x5301, 0)  -- rightmost zeros on screen
					mem:write_u8(0x52e1, 0)  -- rightmost zeros on screen
				end
			end
		end
	end

	function dkong_func()
		mode = read(0x600a)
		start_lives = read(0x6020)
		b_1p_game = read(0x600f, 0)
		b_almost_gameover = mode == 13 and read(0x6228, 1) and read(0x639d, 2)
		b_reset_continue = mode == 11
		b_reset_tally = mode == 7 or tally == nil
		b_show_tally = mode >= 8 and mode <= 16

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not frame_stop then
				frame_stop = frame + 600
			end
			if frame_stop and frame_stop > frame then
				mem:write_u8(0x6009, 8) -- freeze game
				draw_continue_box()

				if to_bits(read(0x7d00))[3] == 1 then  -- P1 button pushed
					tally = tally + 1
					mem:write_u8(0x6228, start_lives + 1)
					frame_stop = nil
					--reset score
					for _add = 0x60b2, 0x60b4 do  -- score in memory
						mem:write_u8(_add, 0)
					end
					for _add = 0x76e1, 0x7781, 0x20 do  -- on screen score
						mem:write_u8(_add, 0)
					end
				end
			end
		end
	end

	function asteroid_func()
		-- Standard data
		mode = read(0x21b)
		start_lives = read(0x56)
		b_1p_game = read(0x1c, 1)
		b_reset_continue = mode == 255
		b_reset_tally = not b_1p_game or tally == nil
		b_show_tally = b_1p_game
		b_almost_gameover = mode == 160 and read(0x57, 0)

		-- Logic
		if b_1p_game then
			if b_almost_gameover and not frame_stop then
				frame_stop = frame + 600
			end
			if frame_stop and frame_stop > frame then
				mem:write_u8(0x21b, 160)   -- freeze by setting the game mode counter

				--TODO: Fix this hack to continue box text
				message_data, message_data_flipped = {}, {}
				draw_continue_box()
				scr:draw_text(40, 50,  "P U S H")
				scr:draw_text(40, 80,  "P 1   S T A R T")
				scr:draw_text(40, 110, "T O")
				scr:draw_text(40, 140, "C O N T I N U E")

				if read(0x2403, 128) then -- P1 button pushed
					tally = tally + 1
					mem:write_u8(0x57, start_lives)
					frame_stop = nil

					--reset score
					mem:write_u8(0x52, 0)
					mem:write_u8(0x53, 0)
				end
			end
		end
	end

	---------------------------------------------------------------------------
	-- PLUGIN FUNCTIONS
	---------------------------------------------------------------------------
	function initialize()
		if tonumber(emu.app_version()) >= 0.227 then
			mac = manager.machine
		elseif tonumber(emu.app_version()) >= 0.196 then
			mac = manager:machine()
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
				message_data_flipped = flip_table(message_data)
			else
				print("WARNING: The continue plugin does not support this rom.")
			end
		end
	end

	function main()
		if rom_function ~= nil then
			frame = scr:frame_number()
			rom_function()
			if b_1p_game then
				if b_reset_tally then tally = 0 end
				if b_reset_continue then frame_stop = nil end
				if b_show_tally then
					draw_tally(tally)
				end
			end
		end
	end

	function draw_graphic(data, pos_y, pos_x)
		local _len, _sub = string.len, string.sub
		local _pixel, _skip
		local _col, _scale = rom_data[4], rom_data[6]
		for _y, line in pairs(data) do
			_x = 1
			for _i=1, _len(line) do
				_skip = 1
				_pixel = _sub(line, _i, _i)
				if _pixel == "S" then
					_skip = 3 --skip multiple spaces
				elseif _pixel ~= " " then
					_skip = tonumber(_pixel)
					scr:draw_box(pos_y -_y*_scale, pos_x+_x, pos_y-(_y*_scale) + _scale, pos_x+_x+_skip, _col, _col)
				end
				_x = _x + _skip
			end
		end
	end

	function draw_continue_box()
		local _y, _x, _scale = rom_data[3][1], rom_data[3][2], rom_data[6]
		local _w, _h = 120, 48 * _scale
		local _col = rom_data[4]
		local _cnt

		scr:draw_box(_y, _x, _y + _h, _x + _w, BLACK, BLACK) -- background
		_cnt = math.floor((frame_stop - frame) / 6)
		if _cnt < 40 and _cnt % 6 >= 3 then _col = RED end
		if rom_data[5] then
			draw_graphic(message_data_flipped, _y + (24*_scale), _x + 7) -- wording
			scr:draw_box(_y+(_scale*32), _x+112, _y+(_scale*40), _x+112-_cnt, _col, _col) -- flipped countdown bar
		else
			draw_graphic(message_data, _y + (40*_scale), _x + 7) --wording
			scr:draw_box(_y+(_scale*8), _x+8, _y+(_scale*16), _x+8+_cnt, _col, _col) -- countdown bar
		end
	end

	function draw_tally(n)
		-- chalk up the number of continues
		local _col, _y, _x
		local _cols = { WHITE, CYAN }
		for _i=0, n - 1 do
			_col = _cols[((math.floor(_i / 5)) % 2) + 1]
			_y, _x = rom_data[2][1], rom_data[2][2]
			if rom_data[5] then
				scr:draw_box(_y, _x - (_i * 4), _y + (3 * rom_data[6]), _x + 2 - (_i * 4), _col ,_col)
			else
				scr:draw_box(_y, _x + (_i * 4), _y + (3 * rom_data[6]), _x + 2 + (_i * 4), _col ,_col)
			end
		end
	end

	function flip_table(t)
		local _f = {}
		for k, v in ipairs(t) do
			_f[#t + 1 - k] = string.reverse(v)
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