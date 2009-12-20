return {
	name = "ancient ruins",
	level_range = {1, 5},
	max_level = 5,
	width = 100, height = 100,
	all_remembered = true,
	all_lited = true,
--	persistant = true,
	generator =  {
		map = {
			class = "engine.generator.map.Roomer",
			nb_rooms = 9,
			rooms = {"simple", "pilar"},
			['.'] = "FLOOR",
			['#'] = "WALL",
			up = "UP",
			down = "DOWN",
			door = "DOOR",
		},
		actor = {
			class = "engine.generator.actor.Random",
			nb_npc = {1, 1},
			ood = {chance=5, range={1, 10}},
			adjust_level_to_player = {-1, 2},
		},
		object = {
			class = "engine.generator.object.Random",
			nb_object = {1, 1},
			ood = {chance=5, range={1, 10}},
		},
	}
}
