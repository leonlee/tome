return {
	name = "The Maze",
	level_range = {7, 18},
	level_scheme = "player",
	max_level = 7,
	actor_adjust_level = function(zone, level, e) return zone.base_level + level.level-1 + rng.range(-1,2) end,
	width = 40, height = 40,
--	all_remembered = true,
--	all_lited = true,
	persistant = true,
	generator =  {
		map = {
			class = "engine.generator.map.Maze",
			up = "UP",
			down = "DOWN",
			wall = "MAZE_WALL",
			floor = "MAZE_FLOOR",
		},
		actor = {
			class = "engine.generator.actor.Random",
			nb_npc = {20, 30},
			guardian = "MINOTAUR_MAZE",
		},
		object = {
			class = "engine.generator.object.Random",
			nb_object = {4, 6},
			filters = { {type="potion" }, {type="potion" }, {type="potion" }, {type="scroll" }, {}, {} }
		},
		trap = {
			class = "engine.generator.trap.Random",
			nb_trap = {9, 15},
		},
	},
	levels =
	{
		[1] = {
			generator = { map = {
				up = "UP_WILDERNESS",
			}, },
		},
		[7] = {
			generator = { map = {
				force_last_stair = true,
				down = "QUICK_EXIT",
			}, },
		},
	},
}
