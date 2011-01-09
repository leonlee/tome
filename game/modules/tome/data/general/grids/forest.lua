-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

newEntity{
	define_as = "GRASS",
	type = "floor", subtype = "grass",
	name = "grass", image = "terrain/grass.png",
	display = '.', color=colors.LIGHT_GREEN, back_color={r=44,g=95,b=43},
	grow = "TREE",
}

for i = 1, 20 do
newEntity{
	define_as = "TREE"..(i > 1 and i or ""),
	type = "wall", subtype = "grass",
	name = "tree",
	image = "terrain/grass.png",
	add_displays = class:makeTrees("terrain/tree_alpha"),
	display = '#', color=colors.LIGHT_GREEN, back_color={r=44,g=95,b=43},
	always_remember = true,
	can_pass = {pass_tree=1},
	does_block_move = true,
	block_sight = true,
	dig = "GRASS",
}
end

for i = 1, 20 do
newEntity{
	define_as = "HARDTREE"..(i > 1 and i or ""),
	type = "wall", subtype = "grass",
	name = "tall thick tree",
	image = "terrain/grass.png",
	add_displays = class:makeTrees("terrain/tree_alpha"),
	display = '#', color=colors.LIGHT_GREEN, back_color={r=44,g=95,b=43},
	always_remember = true,
	does_block_move = true,
	block_sight = true,
	block_sense = true,
	block_esp = true,
}
end

newEntity{
	define_as = "GRASS_DARK1",
	type = "floor", subtype = "grass",
	name = "grass", image = "terrain/grass_dark1.png",
	display = '.', color=colors.GREEN, back_color={r=44,g=95,b=43},
	grow = "TREE_DARK",
}

for i = 1, 20 do
newEntity{
	define_as = "TREE_DARK"..i,
	type = "wall", subtype = "grass",
	name = "tree", image = "terrain/grass_dark1.png",
	force_clone = true,
	add_displays = class:makeTrees("terrain/tree_dark_alpha"),
	display = '#', color=colors.GREEN, back_color={r=44,g=95,b=43},
	always_remember = true,
	can_pass = {pass_tree=1},
	does_block_move = true,
	block_sight = true,
	dig = "GRASS_DARK1",
}
end

for i = 1, 20 do
newEntity{
	define_as = "HARDTREE_DARK"..i,
	type = "wall", subtype = "grass",
	name = "tall thick tree", image = "terrain/grass_dark1.png",
	force_clone = true,
	add_displays = class:makeTrees("terrain/tree_dark_alpha"),
	display = '#', color=colors.GREEN, back_color={r=44,g=95,b=43},
	always_remember = true,
	does_block_move = true,
	block_sight = true,
	block_sense = true,
	block_esp = true,
}
end

newEntity{
	define_as = "FLOWER",
	type = "floor", subtype = "grass",
	name = "flower", image = "terrain/grass_flower3.png",
	display = ';', color=colors.YELLOW, back_color={r=44,g=95,b=43},
	grow = "TREE"
}

newEntity{
	define_as = "ROCK_VAULT",
	type = "wall", subtype = "grass",
	name = "huge lose rock", image = "terrain/grass.png", add_displays = {class.new{image="terrain/rock_grass.png"}},
	display = '+', color=colors.GREY, back_color={r=44,g=95,b=43},
	notice = true,
	always_remember = true,
	block_sight = true,
	block_sense = true,
	block_esp = true,
	door_player_check = "This rock is loose, you think you can move it away.",
	door_opened = "GRASS",
	dig = "GRASS",
}

newEntity{
	define_as = "ROCK_VAULT_DARK",
	type = "wall", subtype = "grass",
	name = "huge loose rock", image = "terrain/rock_grass_dark.png",
	display = '+', color=colors.GREY, back_color={r=44,g=95,b=43},
	notice = true,
	always_remember = true,
	block_sight = true,
	block_sense = true,
	block_esp = true,
	door_player_check = "This rock is loose, you think you can move it away.",
	door_opened = "GRASS_DARK1",
	dig = "GRASS_DARK1",
}

-----------------------------------------
-- Grassy exits
-----------------------------------------
newEntity{
	define_as = "GRASS_UP_WILDERNESS",
	type = "floor", subtype = "grass",
	name = "exit to the worldmap", image = "terrain/grass.png", add_displays = {class.new{image="terrain/worldmap.png"}},
	display = '<', color_r=255, color_g=0, color_b=255,
	always_remember = true,
	notice = true,
	change_level = 1,
	change_zone = "wilderness",
}

newEntity{
	define_as = "GRASS_UP8",
	type = "floor", subtype = "grass",
	name = "way to the previous level", image = "terrain/grass.png", add_displays = {class.new{image="terrain/way_next_8.png"}},
	display = '<', color_r=255, color_g=255, color_b=0,
	notice = true,
	always_remember = true,
	change_level = -1,
}
newEntity{
	define_as = "GRASS_UP2",
	type = "floor", subtype = "grass",
	name = "way to the previous level", image = "terrain/grass.png", add_displays = {class.new{image="terrain/way_next_2.png"}},
	display = '<', color_r=255, color_g=255, color_b=0,
	notice = true,
	always_remember = true,
	change_level = -1,
}
newEntity{
	define_as = "GRASS_UP4",
	type = "floor", subtype = "grass",
	name = "way to the previous level", image = "terrain/grass.png", add_displays = {class.new{image="terrain/way_next_4.png"}},
	display = '<', color_r=255, color_g=255, color_b=0,
	notice = true,
	always_remember = true,
	change_level = -1,
}
newEntity{
	define_as = "GRASS_UP6",
	type = "floor", subtype = "grass",
	name = "way to the previous level", image = "terrain/grass.png", add_displays = {class.new{image="terrain/way_next_6.png"}},
	display = '<', color_r=255, color_g=255, color_b=0,
	notice = true,
	always_remember = true,
	change_level = -1,
}

newEntity{
	define_as = "GRASS_DOWN8",
	type = "floor", subtype = "grass",
	name = "way to the next level", image = "terrain/grass.png", add_displays = {class.new{image="terrain/way_next_8.png"}},
	display = '>', color_r=255, color_g=255, color_b=0,
	notice = true,
	always_remember = true,
	change_level = 1,
}
newEntity{
	define_as = "GRASS_DOWN2",
	type = "floor", subtype = "grass",
	name = "way to the next level", image = "terrain/grass.png", add_displays = {class.new{image="terrain/way_next_2.png"}},
	display = '>', color_r=255, color_g=255, color_b=0,
	notice = true,
	always_remember = true,
	change_level = 1,
}
newEntity{
	define_as = "GRASS_DOWN4",
	type = "floor", subtype = "grass",
	name = "way to the next level", image = "terrain/grass.png", add_displays = {class.new{image="terrain/way_next_4.png"}},
	display = '>', color_r=255, color_g=255, color_b=0,
	notice = true,
	always_remember = true,
	change_level = 1,
}
newEntity{
	define_as = "GRASS_DOWN6",
	type = "floor", subtype = "grass",
	name = "way to the next level", image = "terrain/grass.png", add_displays = {class.new{image="terrain/way_next_6.png"}},
	display = '>', color_r=255, color_g=255, color_b=0,
	notice = true,
	always_remember = true,
	change_level = 1,
}
