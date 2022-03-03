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
	local frame_stop, frame_remain
	local tally

	-- colours used by continue plugin
	local BLACK = 0xff000000
	local WHITE = 0xffffffff
	local RED = 0xffff0000
	local CYAN = 0xff14f3ff

	-- compatible roms with associated function and position data
	local rom_function
	local rom_table = {}
	rom_table["pacman"] = {"pacman", 18, 216}
	rom_table["mspacman"] = {"pacman", 18, 216}
	rom_table["jrpacman"] = {"pacman", 18, 216}
	rom_table["pacplus"] = {"pacman", 18, 216}
	rom_table["dkong"] = {"dkong", 219, 9}
	rom_table["dkongjr"] = {"dkong", 229, 154}
	rom_table["dkongx"] = {"dkong", 219, 9}
	rom_table["dkongx11"] = {"dkong", 219, 9}
	rom_table["dkongpe"] = {"dkong", 219, 9}
	rom_table["dkonghrd"] = {"dkong", 219, 9}
	rom_table["dkongf"] = {"dkong", 219, 9}
	rom_table["dkongj"] = {"dkong", 219, 9}

	-- message to be displayed in continue box
	local message_table = {
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


	-- GAME/ROM SPECIFIC FUNCTIONS
	------------------------------

	function pacman()
		one_player_game = mem:read_u8(0x4e70) == 0
		game_mode = mem:read_u8(0x4e00)
		reset_continue = mem:read_u8(0x4e03) == 3
		reset_tally = game_mode == 2 or tally == nil
		show_tally = game_mode == 3
		starting_lives = mem:read_u8(0x4e6f)
		lives_lost = game_mode == 3 and mem:read_u8(0x4e14) == 0 and mem:read_u8(0x4e04) == 6

		if one_player_game then
			if reset_tally then
				tally = 0
			end
			if reset_continue then
				frame_stop = nil
			end
			if lives_lost and not frame_stop then
				frame_stop = scr:frame_number() + 600
			end
			if frame_stop then
				if scr:frame_number() < frame_stop then
					mem:write_u8(0x4e04, 2)  -- freeze game
					frame_remain = frame_stop - scr:frame_number()
					draw_continue_box(frame_remain, true)

					if to_bits(mem:read_u8(0x5040))[6] == 0 then  -- P1 button pushed
						tally = tally + 1
						mem:write_u8(0x4e04, 0)  -- unfreeze game
						mem:write_u8(0x4e14, starting_lives)  --update number of lives
						mem:write_u8(0x4e15, starting_lives - 1)  --update displayed number of lives
						frame_stop = nil

						--reset score
						for _add = 0x43f7, 0x43fd do  -- on screen score
							mem:write_u8(_add, 64)
						end
						for _add = 0x4e80, 0x4e82 do  -- score in memory
							mem:write_u8(_add, 0)
						end
					end
				else
					frame_stop = nil
					mem:write_u8(0x4e04, 6)  -- unfreeze game
				end
			end
			if show_tally then
				draw_tally(tally, true)
			end
		end
	end

	function dkong()
		one_player_game = mem:read_u8(0x600f) == 0
		game_mode = mem:read_u8(0x600a)
		reset_continue = game_mode == 11
		reset_tally = game_mode == 7 or tally == nil
		show_tally = game_mode >= 8 and game_mode <= 16
		starting_lives = mem:read_u8(0x6020)
		lives_lost = game_mode == 13 and mem:read_u8(0x6228) == 1 and mem:read_u8(0x639d) == 2

		if one_player_game then
			if reset_tally then
				tally = 0
			end
			if reset_continue then
				frame_stop = nil
			end
			if lives_lost and not frame_stop then
				frame_stop = scr:frame_number() + 600
			end
			if frame_stop and frame_stop > scr:frame_number() then
				mem:write_u8(0x6009, 8) -- freeze game
				frame_remain = frame_stop - scr:frame_number()
				draw_continue_box(frame_remain)

				if to_bits(mem:read_u8(0x7d00))[3] == 1 then  -- P1 button pushed
					tally = tally + 1
					mem:write_u8(0x6228, starting_lives + 1)
					frame_stop = nil

					--reset score
					for k, v in pairs({0x7781, 0x7761, 0x7741, 0x7721, 0x7701, 0x76e1}) do --on screen score
						mem:write_u8(v, 0)
					end
					for _add = 0x60b2, 0x60b4 do  -- score in memory
						mem:write_u8(_add, 0)
					end
				end
			end
			if show_tally then
				draw_tally(tally)
			end
		end
	end

	-- PLUGIN FUNCTIONS
	-------------------

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
			else
				print("WARNING: The continue plugin does not support this rom.")
			end
		end
	end

	function main()
		if cpu ~= nil then
			if not rom_function then
				rom_function = _G[rom_table[emu:romname()][1]]
			end
			rom_function()
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

	function draw_continue_box(remain, flip)
		local _flip = flip or false
		local _tab = message_table
		local _cnt, _col
		if _flip then
			_tab = flip_table(_tab)
		end
		scr:draw_box(96, 49, 144, 168, BLACK, BLACK)
		draw_graphic(_tab, 120, 57)
		_cnt = math.floor(remain / 6)
		_col = CYAN
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

	function flip_table(t)
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

	emu.register_start(function()
		initialize()
	end)

	emu.register_frame_done(main, "frame")
end
return exports