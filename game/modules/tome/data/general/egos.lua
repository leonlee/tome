--[[
newEntity{
	name = "flaming ", prefix=true,
	level_range = {1, 10},
	rarity = 3,
	wielder = {
--		melee_project={[DamageType.FIRE] = 4},
	},
}
--]]
newEntity{
	name = " of accuracy",
	level_range = {1, 50},
	rarity = 3,
	wielder = {
		combat_atk = resolvers.mbonus(20),
	},
}

newEntity{
	name = "kinetic ", prefix=true,
	level_range = {1, 50},
	rarity = 3,
	wielder = {
		combat_apr = resolvers.mbonus(15),
	},
}
