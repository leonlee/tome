-- ToME - Tales of Middle-Earth
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

-- Orcs & trolls
load("/data/general/npcs/orc-grushnak.lua", rarity(0))
load("/data/general/npcs/orc-vor.lua", rarity(0))
load("/data/general/npcs/orc-gorbat.lua", rarity(0))
load("/data/general/npcs/orc-rak-shor.lua", rarity(6))
load("/data/general/npcs/orc.lua", rarity(8))
--load("/data/general/npcs/troll.lua", rarity(0))

-- Others
load("/data/general/npcs/naga.lua", rarity(6))
load("/data/general/npcs/snow-giant.lua", rarity(6))

-- Demons
load("/data/general/npcs/minor-demon.lua", rarity(3))
load("/data/general/npcs/major-demon.lua", rarity(3))

-- Drakes
load("/data/general/npcs/fire-drake.lua", rarity(10))
load("/data/general/npcs/cold-drake.lua", rarity(10))
load("/data/general/npcs/multihued-drake.lua", rarity(10))

-- Undeads
load("/data/general/npcs/bone-giant.lua", rarity(10))
load("/data/general/npcs/vampire.lua", rarity(10))
load("/data/general/npcs/ghoul.lua", rarity(10))
load("/data/general/npcs/skeleton.lua", rarity(10))
load("/data/general/npcs/ghost.lua", rarity(4))

load("/data/general/npcs/all.lua", rarity(4, 35))

local Talents = require("engine.interface.ActorTalents")

-- Alatar & Palando, the final bosses
newEntity{
	define_as = "ELANDAR",
	type = "humanoid", subtype = "sorcerer",
	name = "Elandar",
	display = "@", color=colors.AQUAMARINE,
	faction = "sorcerers",

	desc = [[The renegates mages from Angolwen, the Sorcerers have setup in the Far East, slowly growing corrupt. Now they must be stopped.]],
	level_range = {75, 75}, exp_worth = 15,
	max_life = 1000, life_rating = 36, fixed_rating = true,
	max_mana = 10000,
	mana_regen = 10,
	negative_regen = 10,
	rank = 5,
	size_category = 3,
	stats = { str=40, dex=60, cun=60, mag=30, con=40 },

	see_invisible = 100,
	instakill_immune = 1,
	stun_immune = 0.5,
	blind_immune = 1,

	combat_armor = 20,
	combat_def = 20,

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, HEAD=1, FEET=1 },
	resolvers.equip{
		{type="weapon", subtype="staff", defined="STAFF_ABSORPTION_AWAKENED", autoreq=true},
		{type="armor", subtype="cloth", ego_chance=100, autoreq=true},
		{type="armor", subtype="head", ego_chance=100, autoreq=true},
		{type="armor", subtype="feet", ego_chance=100, autoreq=true},
	},
	resolvers.drops{chance=100, nb=5, {ego_chance=100} },

	resolvers.talents{
		[Talents.T_STONE_SKIN]=5,
		[Talents.T_QUICKEN_SPELLS]=5,
		[Talents.T_SPELL_SHAPING]=5,
		[Talents.T_ARCANE_POWER]=5,
		[Talents.T_ESSENCE_OF_SPEED]=5,
		[Talents.T_HYMN_OF_SHADOWS]=5,

		[Talents.T_FLAME]=5,
		[Talents.T_FREEZE]=5,
		[Talents.T_LIGHTNING]=5,
		[Talents.T_MANATHRUST]=5,
		[Talents.T_FLAMESHOCK]=5,
		[Talents.T_STRIKE]=5,
		[Talents.T_HEAL]=5,
		[Talents.T_REGENERATION]=5,
		[Talents.T_ILLUMINATE]=5,
		[Talents.T_METAFLOW]=5,
		[Talents.T_PHASE_DOOR]=5,

		[Talents.T_MOONLIGHT_RAY]=5,
		[Talents.T_STARFALL]=5,
		[Talents.T_TWILIGHT_SURGE]=5,
	},
	resolvers.sustains_at_birth(),

	autolevel = "caster",
	ai = "dumb_talented_simple", ai_state = { talent_in=1, ai_move="move_astar" },

	on_die = function(self, who)
		game.player:resolveSource():setQuestStatus("high-peak", engine.Quest.COMPLETED, "alatar-dead")
	end,
}

newEntity{
	define_as = "ARGONIEL",
	type = "humanoid", subtype = "sorcerer",
	name = "Argoniel",
	display = "@", color=colors.ROYAL_BLUE,
	faction = "sorcerers",

	desc = [[The renegates mages from Angolwen, the Sorcerers have setup in the Far East, slowly growing corrupt. Now they must be stopped.]],
	level_range = {75, 75}, exp_worth = 15,
	max_life = 1000, life_rating = 36, fixed_rating = true,
	max_mana = 10000,
	mana_regen = 10,
	vim_regen = 50,
	rank = 5,
	size_category = 3,
	stats = { str=40, dex=60, cun=60, mag=30, con=40 },

	see_invisible = 100,
	instakill_immune = 1,
	stun_immune = 0.5,
	blind_immune = 1,

	combat_armor = 20,
	combat_def = 20,

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, FEET=1, HEAD=1, HANDS=1 },
	resolvers.equip{
		{type="weapon", subtype="sword", ego_chance=100, autoreq=true},
		{type="weapon", subtype="waraxe", ego_chance=100, autoreq=true},
		{type="armor", subtype="massive", ego_chance=100, autoreq=true},
		{type="armor", subtype="feet", name="pair of mithril boots",ego_chance=100, autoreq=true},
		{type="armor", subtype="head", name="mithril helm",ego_chance=100, autoreq=true},
		{type="armor", subtype="hands", name="mithril gauntlets",ego_chance=100, autoreq=true},
	},
	resolvers.drops{chance=100, nb=1, {defined="PEARL_LIFE_DEATH"} },
	resolvers.drops{chance=100, nb=5, {ego_chance=100} },

	resolvers.talents{
		[Talents.T_BONE_GRAB]=5,
		[Talents.T_BONE_SPEAR]=5,
		[Talents.T_BONE_SHIELD]=5,
		[Talents.T_BURNING_HEX]=5,
		[Talents.T_EMPATHIC_HEX]=5,
		[Talents.T_CURSE_OF_VULNERABILITY]=5,
		[Talents.T_CURSE_OF_DEFENSELESSNESS]=5,
		[Talents.T_CURSE_OF_DEATH]=5,
		[Talents.T_VIRULENT_DISEASE]=5,
		[Talents.T_CYST_BURST]=5,
		[Talents.T_CATALEPSY]=5,
		[Talents.T_EPIDEMIC]=5,
		[Talents.T_REND]=5,
		[Talents.T_RUIN]=5,
		[Talents.T_DARK_SURPRISE]=5,
		[Talents.T_CORRUPTED_STRENGTH]=5,
		[Talents.T_BLOODLUST]=5,
		[Talents.T_ACID_BLOOD]=5,
		[Talents.T_DRAIN]=5,

		[Talents.T_WEAPON_COMBAT]=10,
		[Talents.T_WEAPONS_MASTERY]=7,
		[Talents.T_MASSIVE_ARMOUR_TRAINING]=5,
	},
	resolvers.sustains_at_birth(),

	autolevel = "warriormage",
	ai = "dumb_talented_simple", ai_state = { talent_in=3, ai_move="move_astar" },

	on_die = function(self, who)
		game.player:resolveSource():setQuestStatus("high-peak", engine.Quest.COMPLETED, "pallando-dead")
	end,
}

-- Aeryn trying to kill the player if charred scar quest failed
newEntity{ define_as = "FALLEN_SUN_PALADIN_AERYN",
	type = "humanoid", subtype = "human",
	display = "p",
	faction = "blue-wizards",
	name = "Fallen Sun Paladin Aeryn", color=colors.VIOLET, unique = true,
	desc = [[A beautiful woman, clad in a shining plate armour. Power radiates from her.]],
	level_range = {56, 56}, exp_worth = 2,
	rank = 5,
	size_category = 3,
	female = true,
	max_life = 250, life_rating = 30, fixed_rating = true,
	infravision = 20,
	stats = { str=15, dex=10, cun=12, mag=16, con=14 },
	instakill_immune = 1,
	move_others=true,

	open_door = true,

	autolevel = "warriormage",
	ai = "dumb_talented_simple", ai_state = { talent_in=2, ai_move="move_astar", },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, HEAD=1, FEET=1 },
	resolvers.drops{chance=100, nb=3, {ego_chance=100} },

	resolvers.equip{
		{type="weapon", subtype="mace", ego_chance=100, autoreq=true},
		{type="armor", subtype="shield", ego_chance=100, autoreq=true},
		{type="armor", subtype="massive", ego_chance=100, autoreq=true},
		{type="armor", subtype="feet", ego_chance=100, autoreq=true},
		{type="armor", subtype="head", ego_chance=100, autoreq=true},
	},

	die = function(self, src)
		self.die = function() end
		local Chat = require "engine.Chat"
		local chat = Chat.new("fallen-aeryn", self, game.player)
		chat:invoke()
	end,

	positive_regen = 15,

	resolvers.talents{
		[Talents.T_MASSIVE_ARMOUR_TRAINING]=5,
		[Talents.T_WEAPON_COMBAT]=10,
		[Talents.T_WEAPONS_MASTERY]=10,
		[Talents.T_RUSH]=3,

		[Talents.T_CHANT_OF_FORTITUDE]=5,
		[Talents.T_SEARING_LIGHT]=5,
		[Talents.T_MARTYRDOM]=5,
		[Talents.T_BARRIER]=5,
		[Talents.T_WEAPON_OF_LIGHT]=5,
		[Talents.T_MARTYRDOM]=5,
		[Talents.T_HEALING_LIGHT]=5,
		[Talents.T_CRUSADE]=8,
		[Talents.T_SUN_FLARE]=5,
		[Talents.T_FIREBEAM]=7,
		[Talents.T_SUNBURST]=8,
	},
	resolvers.sustains_at_birth(),
}

-- Aeryn coming back to help the player in the fight with the Sorcerers
newEntity{ define_as = "HIGH_SUN_PALADIN_AERYN",
	type = "humanoid", subtype = "human",
	display = "p",
	faction = "sunwall",
	name = "High Sun Paladin Aeryn", color=colors.VIOLET, unique = "High Sun Paladin Aeryn High Peak Help",
	desc = [[A beautiful woman, clad in a shining plate armour. Power radiates from her.]],
	level_range = {56, 56}, exp_worth = 2,
	rank = 5,
	size_category = 3,
	female = true,
	max_life = 250, life_rating = 30, fixed_rating = true,
	infravision = 20,
	stats = { str=15, dex=10, cun=12, mag=16, con=14 },
	instakill_immune = 1,
	stun_immune = 0.5,
	move_others=true,

	open_door = true,

	autolevel = "warriormage",
	ai = "dumb_talented_simple", ai_state = { talent_in=2, ai_move="move_astar", },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, HEAD=1, FEET=1 },
	resolvers.drops{chance=100, nb=3, {ego_chance=100} },

	resolvers.equip{
		{type="weapon", subtype="mace", ego_chance=100, autoreq=true},
		{type="armor", subtype="shield", ego_chance=100, autoreq=true},
		{type="armor", subtype="massive", ego_chance=100, autoreq=true},
		{type="armor", subtype="feet", ego_chance=100, autoreq=true},
		{type="armor", subtype="head", ego_chance=100, autoreq=true},
	},

	positive_regen = 15,

	resolvers.talents{
		[Talents.T_MASSIVE_ARMOUR_TRAINING]=5,
		[Talents.T_WEAPON_COMBAT]=10,
		[Talents.T_WEAPONS_MASTERY]=10,
		[Talents.T_RUSH]=3,

		[Talents.T_CHANT_OF_FORTITUDE]=5,
		[Talents.T_SEARING_LIGHT]=5,
		[Talents.T_MARTYRDOM]=5,
		[Talents.T_BARRIER]=5,
		[Talents.T_WEAPON_OF_LIGHT]=5,
		[Talents.T_HEALING_LIGHT]=5,
		[Talents.T_CRUSADE]=8,
		[Talents.T_SUN_FLARE]=5,
		[Talents.T_FIREBEAM]=7,
		[Talents.T_SUNBURST]=8,
	},
	resolvers.sustains_at_birth(),
}
