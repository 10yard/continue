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
	local frame, frame_stop, frame_remain
	local mode, start_lives, tally
	local b_1p_game, b_game_restart, b_almost_gameover, b_reset_continue, b_reset_tally, b_show_tally

	-- colours used by continue plugin
	local BLACK = 0xff000000
	local WHITE = 0xffffffff
	local RED = 0xffff0000
	local YELLOW = 0xfff8f91a
	local CYAN = 0xff14f3ff

	-- compatible roms with associated function and position data
	local rom_function
	local rom_table = {}
	rom_table["galaxian"] = {"galaxian_driver", 52, 216, WHITE}
	rom_table["superg"] = {"galaxian_driver", 52, 216, WHITE}
	rom_table["moonaln"] = {"galaxian_driver", 52, 216, WHITE}
	rom_table["pacman"] = {"pacman_driver", 18, 216, WHITE}
	rom_table["mspacman"] = {"pacman_driver", 18, 216, WHITE}
	rom_table["mspacmat"] = {"pacman_driver", 18, 216, WHITE}
	rom_table["pacplus"] = {"pacman_driver", 18, 216, WHITE}
	rom_table["dkong"] = {"dkong_driver", 219, 9}
	rom_table["dkongjr"] = {"dkong_driver", 229, 154, YELLOW}
	rom_table["dkongx"] = {"dkong_driver", 219, 9}
	rom_table["dkongx11"] = {"dkong_driver", 219, 9}
	rom_table["dkongpe"] = {"dkong_driver", 219, 9}
	rom_table["dkonghrd"] = {"dkong_driver", 219, 9}
	rom_table["dkongf"] = {"dkong_driver", 219, 9}
	rom_table["dkongj"] = {"dkong_driver", 219, 9}
	rom_table["asteroid"] = {"asteroid_driver", 10, 10, WHITE}
	--rom_table["jrpacman"] = {"pacman_driver", 18, 216, WHITE} -- issue with restart/pill count

	-- message to be displayed in continue box
	local continue_message = {
		"######  ##   ##  ####   ##   ##         ######     ##            ####    ######   ###   ######   ######",
		"##   ## ##   ## ##  ##  ##   ##         ##   ##   ###           ##  ##     ##    ## ##  ##   ##    ##  ",
		"##   ## ##   ## ##      ##   ##         ##   ##    ##           ##         ##   ##   ## ##   ##    ##  ",
		"##   ## ##   ##  #####  #######         ##   ##    ##            #####     ##   ##   ## ##  ###    ##  ",
		"######  ##   ##      ## ##   ##         ######     ##                ##    ##   ####### #####      ##  ",
		"##      ##   ## ##   ## ##   ##         ##         ##           ##   ##    ##   ##   ## ## ###     ##  ",
		"##       #####   #####  ##   ##         ##       ######          #####     ##   ##   ## ##  ###    ##  ",
		"                                                                                                       ",
		"         ######  #####            ####   #####  ##   ##  ######  ###### ##   ## ##   ## #######        ",
		"           ##   ##   ##          ##  ## ##   ## ###  ##    ##      ##   ###  ## ##   ## ##             ",
		"           ##   ##   ##         ##      ##   ## #### ##    ##      ##   #### ## ##   ## ##             ",
		"           ##   ##   ##         ##      ##   ## #######    ##      ##   ####### ##   ## ######         ",
		"           ##   ##   ##         ##      ##   ## ## ####    ##      ##   ## #### ##   ## ##             ",
		"           ##   ##   ##          ##  ## ##   ## ##  ###    ##      ##   ##  ### ##   ## ##             ",
		"           ##    #####            ####   #####  ##   ##    ##    ###### ##   ##  #####  #######        "
		}
	local continue_message_x2, continue_message_x3

	---------------------------------------------------------------------------
	-- GAME/ROM SPECIFIC FUNCTIONS
	---------------------------------------------------------------------------
	function pacman_driver()
		-- Standard data
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
			if b_reset_tally then tally = 0 end
			if b_reset_continue then frame_stop = nil end

			if b_almost_gameover and not frame_stop then
				frame_stop = frame + 600
				pills_eaten = read(0x4e0e)
			end
			if frame_stop then
				if frame < frame_stop then
					mem:write_u8(0x4e04, 2)  -- freeze game
					frame_remain = frame_stop - frame
					draw_continue_box(frame_remain, true)

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
			if b_show_tally then
				draw_tally(tally, true)
			end
		end
	end

	function galaxian_driver()
		-- Standard data
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
			if b_reset_tally then tally = 0 end
			if b_reset_continue then frame_stop = nil end

			if b_almost_gameover and not frame_stop then
				frame_stop = frame + 600
			end
			if frame_stop and frame_stop > frame then
				mem:write_u8(0x4205, 0x10) -- freeze by setting the animation counter
				frame_remain = frame_stop - frame
				draw_continue_box(frame_remain, true, continue_message_x3)

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
			if b_show_tally then
				draw_tally(tally, true)
			end
		end
	end

	function dkong_driver()
		-- Standard data
		mode = read(0x600a)
		start_lives = read(0x6020)
		b_1p_game = read(0x600f, 0)
		b_almost_gameover = mode == 13 and read(0x6228, 1) and read(0x639d, 2)
		b_reset_continue = mode == 11
		b_reset_tally = mode == 7 or tally == nil
		b_show_tally = mode >= 8 and mode <= 16

		-- Logic
		if b_1p_game then
			if b_reset_tally then tally = 0 end
			if b_reset_continue then frame_stop = nil end

			if b_almost_gameover and not frame_stop then
				frame_stop = frame + 600
			end
			if frame_stop and frame_stop > frame then
				mem:write_u8(0x6009, 8) -- freeze game
				frame_remain = frame_stop - frame
				draw_continue_box(frame_remain)

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
			if b_show_tally then
				draw_tally(tally)
			end
		end
	end

	function asteroid_driver()
		-- Standard data
		mode = read(0x21b)
		start_lives = read(0x56)
		b_1p_game = read(0x1c, 1)
		b_reset_continue = mode == 255
		b_reset_tally = not b_1p_game or tally == nil
		b_show_tally = b_1p_game
		b_almost_gameover = mode == 160 and read(0x57, 0) --immediately before game over

		-- Logic
		if b_1p_game then
			if b_reset_tally then tally = 0 end
			if b_reset_continue then frame_stop = nil end

			if b_almost_gameover and not frame_stop then
				frame_stop = frame + 600
			end
			if frame_stop and frame_stop > frame then
				mem:write_u8(0x21b, 160)   -- freeze by setting the game mode counter
				frame_remain = frame_stop - frame

				--TODO: Fix this hack to display continue graphic
				draw_continue_box(frame_remain, true, {})
				scr:draw_text(15, 50,  "PUSH")
				scr:draw_text(15, 80,  "P1 START")
				scr:draw_text(15, 110, "TO")
				scr:draw_text(15, 140, "CONTINUE")

				if read(0x2403, 128) then -- P1 button pushed
					tally = tally + 1
					mem:write_u8(0x57, start_lives)
					frame_stop = nil

					--reset score
					mem:write_u8(0x52, 0)
					mem:write_u8(0x53, 0)
				end
			end
			if b_show_tally then
				draw_tally(tally)
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
				rom_function = _G[rom_table[emu:romname()][1]]
			else
				print("WARNING: The continue plugin does not support this rom.")
			end
			continue_message_x2 = stretch_table(continue_message, 2)
			continue_message_x3 = stretch_table(continue_message, 3)
		end
	end

	function main()
		if rom_function ~= nil then
			frame = scr:frame_number()
			rom_function()
		end
	end

	function draw_graphic(data, pos_y, pos_x)
		local _pixel, _col
		_col = rom_table[emu:romname()][4] or CYAN
		for _y, line in pairs(data) do
			for _x=1, string.len(line) do
				_pixel = string.sub(line, _x, _x)
				if _pixel ~= " " then
					scr:draw_box(pos_y -_y, pos_x + _x, pos_y -_y + 1, pos_x +_x + 1, _col, _col)
				end
			end
		end
	end

	function draw_continue_box(remain, flip, table)
		local _flip = flip or false
		local _tab = table or continue_message
		local _cnt, _col
		if _flip  then
			_tab = flip_table(_tab)
		end
		scr:draw_box(96, 49, 144, 168, BLACK, BLACK)
		draw_graphic(_tab, 120, 57)
		_cnt = math.floor(remain / 6)
		_col = rom_table[emu:romname()][4] or CYAN
		if _cnt < 40 and _cnt % 6 >= 3 then
			_col = RED
		end
		if flip then
			scr:draw_box(128, 162, 136, 162 - _cnt, _col, _col) -- draw countdown timer
		else
			scr:draw_box(128, 57, 136, 57 + _cnt, _col, _col) -- draw countdown timer
		end
	end

	function draw_tally(n, flip)
		-- chalk up the number of continues
		local _flip = flip or false
		local cycle_table = { WHITE, CYAN }
		for i=0, n - 1 do
			_col = cycle_table[((math.floor(i / 5)) % 2) + 1]
			_y, _x = rom_table[emu:romname()][2], rom_table[emu:romname()][3]
			if _flip then
				scr:draw_box(_y, _x - (i * 4), _y + 3, _x + 2 - (i * 4), _col ,_col)
			else
				scr:draw_box(_y, _x + (i * 4), _y + 3, _x + 2 + (i * 4), _col ,_col)
			end
		end
	end

	function stretch_table(t, factor)
		-- Increase height of table by given factor integer
		_table = {}
		for _, v in ipairs(t) do
			for _=1, factor do
				table.insert(_table, v)
			end
		end
		return _table
	end

	function flip_table(t)
		-- reverse table content
		local flipped_table = {}
		local item_count = #t
		for k, v in ipairs(t) do
			flipped_table[item_count + 1 - k] = string.reverse(v)
		end
		return flipped_table
	end

	function to_bits(num)
		--return a table of bits, least significant first
		local t={}
		while num>0 do
			rest=math.fmod(num,2)
			t[#t+1]=rest
			num=(num-rest)/2
		end
		return t
	end

	function read(address, comparison)
		-- return data from memory address or boolean when the comparison value is provided
		data = mem:read_u8(address)
		if comparison then
			return data == comparison
		else
			return data
		end
	end

	emu.register_start(function()
		initialize()
	end)

	emu.register_frame_done(main, "frame")
end
return exports