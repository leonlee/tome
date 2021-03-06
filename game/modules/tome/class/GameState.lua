-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2016 Nicolas Casalini
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

require "engine.class"
require "engine.Entity"
local Particles = require "engine.Particles"
local Shader = require "engine.Shader"
local Map = require "engine.Map"
local NameGenerator = require "engine.NameGenerator"
local NameGenerator2 = require "engine.NameGenerator2"
local Donation = require "mod.dialogs.Donation"

module(..., package.seeall, class.inherit(engine.Entity))

function _M:init(t, no_default)
	engine.Entity.init(self, t, no_default)

	self.allow_backup_guardians = {}
	self.world_artifacts_pool = {}
	self.seen_special_farportals = {}
	self.unique_death = {}
	self.used_events = {}
	self.boss_killed = 0
	self.stores_restock = 1
	self.east_orc_patrols = 4
	self.tier1_done = 0
	self.birth = {}
end

--- Restock all stores
function _M:storesRestock()
	self.stores_restock = self.stores_restock + 1
	game.log("#AQUAMARINE#Most stores should have new stock now.")
	print("[STORES] restocking")
end

--- Number of bosses killed
function _M:bossKilled(rank)
	self.boss_killed = self.boss_killed + 1
end

--- Register a tier1 boss kill
function _M:tier1Kill()
	self.tier1_done = self.tier1_done + 1
end

--- Return true if enough tier1 boss killed
function _M:tier1Killed(nb)
	return self.tier1_done >= nb
end

--- Sets unique as dead
function _M:registerUniqueDeath(u)
	if u.randboss then return end
	self.unique_death[u.name] = true
end

--- Is unique dead?
function _M:isUniqueDead(name)
	return self.unique_death[name]
end

--- Seen a special farportal location
function _M:seenSpecialFarportal(name)
	self.seen_special_farportals[name] = true
end

--- Is farportal already used
function _M:hasSeenSpecialFarportal(name)
	return self.seen_special_farportals[name]
end

--- Allow dropping the rod of recall
function _M:allowRodRecall(v)
	if v == nil then return self.allow_drop_recall end
	self.allow_drop_recall = v
end

--- Discovered the far east
function _M:goneEast()
	self.is_advanced = true
end

--- Is the game in an advanced state (gone east ? others ?)
function _M:isAdvanced()
	return self.is_advanced
end

--- Reduce the chance of orc patrols
function _M:eastPatrolsReduce()
	self.east_orc_patrols = self.east_orc_patrols / 2
end

--- Get the chance of orc patrols
function _M:canEastPatrol()
	return self.east_orc_patrols
end

--- Setup a backup guardian for the given zone
function _M:activateBackupGuardian(guardian, on_level, zonelevel, rumor, action)
	if self.is_advanced then return end
	print("Zone guardian dead, setting up backup guardian", guardian, zonelevel)
	self.allow_backup_guardians[game.zone.short_name] =
	{
		name = game.zone.name,
		guardian = guardian,
		on_level = on_level,
		new_level = zonelevel,
		rumor = rumor,
		action = action,
	}
end

--- Get random emote for townpeople based on backup guardians
function _M:getBackupGuardianEmotes(t)
	if not self.is_advanced then return t end
	for zone, data in pairs(self.allow_backup_guardians) do
		print("possible chatter", zone, data.rumor)
		t[#t+1] = data.rumor
	end
	return t
end

--- Activate a backup guardian & settings, if available
function _M:zoneCheckBackupGuardian()
	if not self.is_advanced then print("Not gone east, no backup guardian") return end

	-- Adjust level of the zone
	if self.allow_backup_guardians[game.zone.short_name] then
		local data = self.allow_backup_guardians[game.zone.short_name]
		game.zone.base_level = data.new_level
		if game.difficulty == game.DIFFICULTY_NIGHTMARE then
			game.zone.base_level_range = table.clone(game.zone.level_range, true)
			game.zone.specific_base_level.object = -10 -game.zone.base_level
			game.zone.base_level = game.zone.base_level * 1.5 + 0
		elseif game.difficulty == game.DIFFICULTY_INSANE then
			game.zone.base_level_range = table.clone(game.zone.level_range, true)
			game.zone.specific_base_level.object = -10 -game.zone.base_level
			game.zone.base_level = game.zone.base_level * 1.5 + 1
		elseif game.difficulty == game.DIFFICULTY_MADNESS then
			game.zone.base_level_range = table.clone(game.zone.level_range, true)
			game.zone.specific_base_level.object = -10 -game.zone.base_level
			game.zone.base_level = game.zone.base_level * 2.5 + 1
		end
		if data.action then data.action(false) end
	end

	-- Spawn the new guardian
	if self.allow_backup_guardians[game.zone.short_name] and self.allow_backup_guardians[game.zone.short_name].on_level == game.level.level then
		local data = self.allow_backup_guardians[game.zone.short_name]

		-- Place the guardian, we do not check for connectivity, vault or whatever, the player is supposed to be strong enough to get there
		local m = game.zone:makeEntityByName(game.level, "actor", data.guardian)
		if m then
			local x, y = rng.range(0, game.level.map.w - 1), rng.range(0, game.level.map.h - 1)
			local tries = 0
			while not m:canMove(x, y) and tries < 100 do
				x, y = rng.range(0, game.level.map.w - 1), rng.range(0, game.level.map.h - 1)
				tries = tries + 1
			end
			if tries < 100 then
				game.zone:addEntity(game.level, m, "actor", x, y)
				print("Backup Guardian allocated: ", data.guardian, m.uid, m.name)
			end
		else
			print("WARNING: Backup Guardian not found: ", data.guardian)
		end

		if data.action then data.action(true) end
		self.allow_backup_guardians[game.zone.short_name] = nil
	end
end

--- A boss refused to drop his artifact! Bastard! Add it to the world pool
function _M:addWorldArtifact(o)
	self.world_artifacts_pool[o.define_as] = o
end

--- Load all added artifacts
-- This is called from the world-artifacts.lua file
function _M:getWorldArtifacts()
	return self.world_artifacts_pool
end

local randart_name_rules = {
	default2 = {
		phonemesVocals = "a, e, i, o, u, y",
		phonemesConsonants = "b, c, ch, ck, cz, d, dh, f, g, gh, h, j, k, kh, l, m, n, p, ph, q, r, rh, s, sh, t, th, ts, tz, v, w, x, z, zh",
		syllablesStart = "Aer, Al, Am, An, Ar, Arm, Arth, B, Bal, Bar, Be, Bel, Ber, Bok, Bor, Bran, Breg, Bren, Brod, Cam, Chal, Cham, Ch, Cuth, Dag, Daim, Dair, Del, Dr, Dur, Duv, Ear, Elen, Er, Erel, Erem, Fal, Ful, Gal, G, Get, Gil, Gor, Grin, Gun, H, Hal, Han, Har, Hath, Hett, Hur, Iss, Khel, K, Kor, Lel, Lor, M, Mal, Man, Mard, N, Ol, Radh, Rag, Relg, Rh, Run, Sam, Tarr, T, Tor, Tul, Tur, Ul, Ulf, Unr, Ur, Urth, Yar, Z, Zan, Zer",
		syllablesMiddle = "de, do, dra, du, duna, ga, go, hara, kaltho, la, latha, le, ma, nari, ra, re, rego, ro, rodda, romi, rui, sa, to, ya, zila",
		syllablesEnd = "bar, bers, blek, chak, chik, dan, dar, das, dig, dil, din, dir, dor, dur, fang, fast, gar, gas, gen, gorn, grim, gund, had, hek, hell, hir, hor, kan, kath, khad, kor, lach, lar, ldil, ldir, leg, len, lin, mas, mnir, ndil, ndur, neg, nik, ntir, rab, rach, rain, rak, ran, rand, rath, rek, rig, rim, rin, rion, sin, sta, stir, sus, tar, thad, thel, tir, von, vor, yon, zor",
		rules = "$s$v$35m$10m$e",
	},
	default = {
		phonemesVocals = "a, e, i, o, u, y",
		syllablesStart = "Ad, Aer, Ar, Bel, Bet, Beth, Ce'N, Cyr, Eilin, El, Em, Emel, G, Gl, Glor, Is, Isl, Iv, Lay, Lis, May, Ner, Pol, Por, Sal, Sil, Vel, Vor, X, Xan, Xer, Yv, Zub",
		syllablesMiddle = "bre, da, dhe, ga, lda, le, lra, mi, ra, ri, ria, re, se, ya",
		syllablesEnd = "ba, beth, da, kira, laith, lle, ma, mina, mira, na, nn, nne, nor, ra, rin, ssra, ta, th, tha, thra, tira, tta, vea, vena, we, wen, wyn",
		rules = "$s$v$35m$10m$e",
	},
	fire = {
		syllablesStart ="Phoenix, Stoke, Fire, Blaze, Burn, Bright, Sear, Heat, Scald, Hell, Hells, Inferno, Lava, Pyre, Furnace, Cinder, Singe, Flame, Scorch, Brand, Kindle, Flash, Smolder, Torch, Ash, Abyss, Char, Kiln, Sun, Magma, Flare",
		syllablesEnd = "arc, bane, bait, bile, biter, blast, bliss, blood, blow, bloom, butcher, blur, bolt, bone, bore, brace, braid, braze, breacher, breaker, breeze, brawn, burst, bringer, bearer, bender, blight, break, born, black, bright, crypt, crack, clash, clamor, cut, cast, cutter, dredge, dash, dream, dare, death, edge, envy, fury, fear, fame, foe, fiend, fist, gore, gash, gasher, grind, grinder, guile, grit, glean, glory, glamour, hack, hacker, hash, hue, hunger, hunt, hunter, ire, idol, immortal, justice, jeer, jam, kill, killer, kiss, 's kiss, karma, kin, king, knave, knight, lord, lore, lash, lace, lady, maim, mark, moon, master, mistress, mire, monster, might, marrow, mortal, minister, malice, naught, null, noon, nail, nigh, night, oath, order, oracle, oozer, obeisance, oblivion, onslaught, obsidian, peal, parry, power, python, prophet, pain, passion, pierce, piercer, pride, pulverizer, piety, panic, pain, punish, pall, quench, quencher, quake, quarry, queen, quell, queller, quick, quill, reaper, ravage, ravager, raze, razor, roar, rage, race, radiance, raider, rain, rot, ransom, rune, reign, rupture, ream, rebel, raven, river, ripper, rip, ripper, rock, reek, reeve, resolve, rigor, rend, raptor, shine, slice, slicer, spar, spawn, spawner, spitter, squall, steel, stoker, snake, sorrow, sage, stake, serpent, shear, sin, spire, stalker, shaper, strider, streak, streaker, saw, scar, schism, star, streak, sting, stinger, strike, striker, stun, sun, sweep, sweeper, swift, stone, seam, sever, smash, smasher, spike, spiker, thorn, terror, touch, tide, torrent, trial, typhoon, titan, tickler, tooth, treason, trencher, taint, trail, umbra, usher, valor, vagrant, vile, vein, veil, venom, viper, vault, vengeance, vortex, vice, wrack, walker, wake, waker, war, ward, warden, wasp, weeper, wedge, wend, well, whisper, wild, wilder, will, wind, wilter, wing, winnow, winter, wire, wisp, wish, witch, wolf, woe, wither, witherer, worm, wreath, worth, wreck, wrecker, wrest, writher, wyrd, zeal, zephyr",
		rules = "$s$e",
	},
	cold = {
		syllablesStart ="Frost, Ice, Freeze, Sleet, Snow, Chill, Shiver, Winter, Blizzard, Glacier, Tundra, Floe, Hail, Frozen, Frigid, Rime, Haze, Rain, Tide, Quench",
		syllablesEnd = "arc, bane, bait, bile, biter, blast, bliss, blood, blow, bloom, butcher, blur, bolt, bone, bore, brace, braid, braze, breacher, breaker, breeze, brawn, burst, bringer, bearer, bender, blight, brand, break, born, black, bright, crypt, crack, clash, clamor, cut, cast, cutter, dredge, dash, dream, dare, death, edge, envy, fury, fear, fame, foe, furnace, flash, fiend, fist, gore, gash, gasher, grind, grinder, guile, grit, glean, glory, glamour, hack, hacker, hash, hue, hunger, hunt, hunter, ire, idol, immortal, justice, jeer, jam, kill, killer, kiss, 's kiss, karma, kin, king, knave, knight, lord, lore, lash, lace, lady, maim, mark, moon, master, mistress, mire, monster, might, marrow, mortal, minister, malice, naught, null, noon, nail, nigh, night, oath, order, oracle, oozer, obeisance, oblivion, onslaught, obsidian, peal, pyre, parry, power, python, prophet, pain, passion, pierce, piercer, pride, pulverizer, piety, panic, pain, punish, pall, quench, quencher, quake, quarry, queen, quell, queller, quick, quill, reaper, ravage, ravager, raze, razor, roar, rage, race, radiance, raider, rain, rot, ransom, rune, reign, rupture, ream, rebel, raven, river, ripper, rip, ripper, rock, reek, reeve, resolve, rigor, rend, raptor, shine, slice, slicer, spar, spawn, spawner, spitter, squall, steel, stoker, snake, sorrow, sage, stake, serpent, shear, sin, sear, spire, stalker, shaper, strider, streak, streaker, saw, scar, schism, star, streak, sting, stinger, strike, striker, stun, sun, sweep, sweeper, swift, stone, seam, sever, smash, smasher, spike, spiker, thorn, terror, touch, tide, torrent, trial, typhoon, titan, tickler, tooth, treason, trencher, taint, trail, umbra, usher, valor, vagrant, vile, vein, veil, venom, viper, vault, vengeance, vortex, vice, wrack, walker, wake, waker, war, ward, warden, wasp, weeper, wedge, wend, well, whisper, wild, wilder, will, wind, wilter, wing, winnow, wire, wisp, wish, witch, wolf, woe, wither, witherer, worm, wreath, worth, wreck, wrecker, wrest, writher, wyrd, zeal, zephyr",
		rules = "$s$e",
	},
	lightning = {
		syllablesStart ="Tempest, Storm, Lightning, Arc, Shock, Thunder, Charge, Cloud, Air, Nimbus, Gale, Crackle, Shimmer, Flash, Spark, Blast, Blaze, Strike, Sky, Bolt",
		syllablesEnd = "bane, bait, bile, biter, blast, bliss, blood, blow, bloom, butcher, blur, bone, bore, brace, braid, braze, breacher, breaker, breeze, brawn, burst, bringer, bearer, bender, blight, brand, break, born, black, bright, crypt, crack, clash, clamor, cut, cast, cutter, dredge, dash, dream, dare, death, edge, envy, fury, fear, fame, foe, furnace, flash, fiend, fist, gore, gash, gasher, grind, grinder, guile, grit, glean, glory, glamour, hack, hacker, hash, hue, hunger, hunt, hunter, ire, idol, immortal, justice, jeer, jam, kill, killer, kiss, 's kiss, karma, kin, king, knave, knight, lord, lore, lash, lace, lady, maim, mark, moon, master, mistress, mire, monster, might, marrow, mortal, minister, malice, naught, null, noon, nail, nigh, night, oath, order, oracle, oozer, obeisance, oblivion, onslaught, obsidian, peal, pyre, parry, power, python, prophet, pain, passion, pierce, piercer, pride, pulverizer, piety, panic, pain, punish, pall, quench, quencher, quake, quarry, queen, quell, queller, quick, quill, reaper, ravage, ravager, raze, razor, roar, rage, race, radiance, raider, rain, rot, ransom, rune, reign, rupture, ream, rebel, raven, river, ripper, rip, ripper, rock, reek, reeve, resolve, rigor, rend, raptor, shine, slice, slicer, spar, spawn, spawner, spitter, squall, steel, stoker, snake, sorrow, sage, stake, serpent, shear, sin, sear, spire, stalker, shaper, strider, streak, streaker, saw, scar, schism, star, streak, sting, stinger, stun, sun, sweep, sweeper, swift, stone, seam, sever, smash, smasher, spike, spiker, thorn, terror, touch, tide, torrent, trial, typhoon, titan, tickler, tooth, treason, trencher, taint, trail, umbra, usher, valor, vagrant, vile, vein, veil, venom, viper, vault, vengeance, vortex, vice, wrack, walker, wake, waker, war, ward, warden, wasp, weeper, wedge, wend, well, whisper, wild, wilder, will, wind, wilter, wing, winnow, winter, wire, wisp, wish, witch, wolf, woe, wither, witherer, worm, wreath, worth, wreck, wrecker, wrest, writher, wyrd, zeal, zephyr",
		rules = "$s$e",
	},
	light = {
		syllablesStart ="Light, Shine, Day, Sun, Morning, Star, Blaze, Glow, Gleam, Bright, Prism, Dazzle, Glint, Dawn, Noon, Glare, Flash, Radiance, Blind, Glimmer, Splendour, Glitter, Kindle, Lustre",
		syllablesEnd = "arc, bane, bait, bile, biter, blast, bliss, blood, blow, bloom, butcher, blur, bolt, bone, bore, brace, braid, braze, breacher, breaker, breeze, brawn, burst, bringer, bearer, bender, blight, brand, break, born, black, bright, crypt, crack, clash, clamor, cut, cast, cutter, dredge, dash, dream, dare, death, edge, envy, fury, fear, fame, foe, furnace, fiend, fist, gore, gash, gasher, grind, grinder, guile, grit, glean, glory, glamour, hack, hacker, hash, hue, hunger, hunt, hunter, ire, idol, immortal, justice, jeer, jam, kill, killer, kiss, 's kiss, karma, kin, king, knave, knight, lord, lore, lash, lace, lady, maim, mark, moon, master, mistress, mire, monster, might, marrow, mortal, minister, malice, naught, null, nail, nigh, night, oath, order, oracle, oozer, obeisance, oblivion, onslaught, obsidian, peal, pyre, parry, power, python, prophet, pain, passion, pierce, piercer, pride, pulverizer, piety, panic, pain, punish, pall, quench, quencher, quake, quarry, queen, quell, queller, quick, quill, reaper, ravage, ravager, raze, razor, roar, rage, race, radiance, raider, rain, rot, ransom, rune, reign, rupture, ream, rebel, raven, river, ripper, rip, ripper, rock, reek, reeve, resolve, rigor, rend, raptor, shine, slice, slicer, spar, spawn, spawner, spitter, squall, steel, stoker, snake, sorrow, sage, stake, serpent, shear, sin, sear, spire, stalker, shaper, strider, streak, streaker, saw, scar, schism, streak, sting, stinger, strike, striker, stun, sweep, sweeper, swift, stone, seam, sever, smash, smasher, spike, spiker, thorn, terror, touch, tide, torrent, trial, typhoon, titan, tickler, tooth, treason, trencher, taint, trail, umbra, usher, valor, vagrant, vile, vein, veil, venom, viper, vault, vengeance, vortex, vice, wrack, walker, wake, waker, war, ward, warden, wasp, weeper, wedge, wend, well, whisper, wild, wilder, will, wind, wilter, wing, winnow, winter, wire, wisp, wish, witch, wolf, woe, wither, witherer, worm, wreath, worth, wreck, wrecker, wrest, writher, wyrd, zeal, zephyr",
		rules = "$s$e",
	},
	dark = {
		syllablesStart ="Night, Umbra, Void, Dark, Gloom, Woe, Dour, Shade, Dusk, Murk, Bleak, Dim, Soot, Pitch, Fog, Black, Coal, Ebony, Shadow, Obsidian, Raven, Jet, Demon, Duathel, Unlight, Eclipse, Blind, Deeps",
		syllablesEnd = "arc, bane, bait, bile, biter, blast, bliss, blood, blow, bloom, butcher, blur, bolt, bone, bore, brace, braid, braze, breacher, breaker, breeze, brawn, burst, bringer, bearer, bender, blight, brand, break, born, bright, crypt, crack, clash, clamor, cut, cast, cutter, dredge, dash, dream, dare, death, edge, envy, fury, fear, fame, foe, furnace, flash, fiend, fist, gore, gash, gasher, grind, grinder, guile, grit, glean, glory, glamour, hack, hacker, hash, hue, hunger, hunt, hunter, ire, idol, immortal, justice, jeer, jam, kill, killer, kiss, 's kiss, karma, kin, king, knave, knight, lord, lore, lash, lace, lady, maim, mark, moon, master, mistress, mire, monster, might, marrow, mortal, minister, malice, naught, null, noon, nail, nigh, oath, order, oracle, oozer, obeisance, oblivion, onslaught, obsidian, peal, pyre, parry, power, python, prophet, pain, passion, pierce, piercer, pride, pulverizer, piety, panic, pain, punish, pall, quench, quencher, quake, quarry, queen, quell, queller, quick, quill, reaper, ravage, ravager, raze, razor, roar, rage, race, radiance, raider, rain, rot, ransom, rune, reign, rupture, ream, rebel, raven, river, ripper, rip, ripper, rock, reek, reeve, resolve, rigor, rend, raptor, shine, slice, slicer, spar, spawn, spawner, spitter, squall, steel, stoker, snake, sorrow, sage, stake, serpent, shear, sin, sear, spire, stalker, shaper, strider, streak, streaker, saw, scar, schism, star, streak, sting, stinger, strike, striker, stun, sun, sweep, sweeper, swift, stone, seam, sever, smash, smasher, spike, spiker, thorn, terror, touch, tide, torrent, trial, typhoon, titan, tickler, tooth, treason, trencher, taint, trail, usher, valor, vagrant, vile, vein, veil, venom, viper, vault, vengeance, vortex, vice, wrack, walker, wake, waker, war, ward, warden, wasp, weeper, wedge, wend, well, whisper, wild, wilder, will, wind, wilter, wing, winnow, winter, wire, wisp, wish, witch, wolf, wither, witherer, worm, wreath, worth, wreck, wrecker, wrest, writher, wyrd, zeal, zephyr",
		rules = "$s$e",
	},
	nature = {
		syllablesStart ="Nature, Green, Loam, Earth, Heal, Root, Growth, Grow, Bark, Bloom, Satyr, Rain, Pure, Wild, Wind, Cure, Cleanse, Forest, Breeze, Oak, Willow, Tree, Balance, Flower, Ichor, Offal, Rot, Scab, Squalor, Taint, Undeath, Vile, Weep, Plague, Pox, Pus, Gore, Sepsis, Corruption, Filth, Muck, Fester, Toxin, Venom, Scorpion, Serpent, Viper, Cobra, Sulfur, Mire, Ooze, Wretch, Carrion, Bile, Bog, Sewer, Swamp, Corpse, Scum, Mold, Spider, Phlegm, Mucus, Morbus, Murk, Smear, Cyst",
		syllablesEnd = "arc, bane, bait, bile, biter, blast, bliss, blood, blow, bloom, butcher, blur, bolt, bone, bore, brace, braid, braze, breacher, breaker, brawn, burst, bringer, bearer, bender, blight, brand, break, born, black, bright, crypt, crack, clash, clamor, cut, cast, cutter, dredge, dash, dream, dare, death, edge, envy, fury, fear, fame, foe, furnace, flash, fiend, fist, gore, gash, gasher, grind, grinder, guile, grit, glean, glory, glamour, hack, hacker, hash, hue, hunger, hunt, hunter, ire, idol, immortal, justice, jeer, jam, kill, killer, kiss, 's kiss, karma, kin, king, knave, knight, lord, lore, lash, lace, lady, maim, mark, moon, master, mistress, mire, monster, might, marrow, mortal, minister, malice, naught, null, noon, nail, nigh, night, oath, order, oracle, oozer, obeisance, oblivion, onslaught, obsidian, peal, pyre, parry, power, python, prophet, pain, passion, pierce, piercer, pride, pulverizer, piety, panic, pain, punish, pall, quench, quencher, quake, quarry, queen, quell, queller, quick, quill, reaper, ravage, ravager, raze, razor, roar, rage, race, radiance, raider, rot, ransom, rune, reign, rupture, ream, rebel, raven, river, ripper, rip, ripper, rock, reek, reeve, resolve, rigor, rend, raptor, shine, slice, slicer, spar, spawn, spawner, spitter, squall, steel, stoker, snake, sorrow, sage, stake, serpent, shear, sin, sear, spire, stalker, shaper, strider, streak, streaker, saw, scar, schism, star, streak, sting, stinger, strike, striker, stun, sun, sweep, sweeper, swift, stone, seam, sever, smash, smasher, spike, spiker, thorn, terror, touch, tide, torrent, trial, typhoon, titan, tickler, tooth, treason, trencher, taint, trail, umbra, usher, valor, vagrant, vile, vein, veil, venom, viper, vault, vengeance, vortex, vice, wrack, walker, wake, waker, war, ward, warden, wasp, weeper, wedge, wend, well, whisper, wild, wilder, will, wind, wilter, wing, winnow, winter, wire, wisp, wish, witch, wolf, woe, wither, witherer, worm, wreath, worth, wreck, wrecker, wrest, writher, wyrd, zeal, zephyr,",
		rules = "$s$e",
	},
}

--- Unided name possibilities for randarts
local unided_names = {"glowing","scintillating","rune-covered","unblemished","jewel-encrusted","humming","gleaming","immaculate","flawless","crackling","glistening","plated","twisted","silvered","faceted","faded","sigiled","shadowy","laminated"}

--- defined power themes, affects equipment generation
_M.power_themes = {
	'physical', 'mental', 'spell', 'defense', 'misc', 'fire',
	'lightning', 'acid', 'mind', 'arcane', 'blight', 'nature',
	'temporal', 'light', 'dark', 'antimagic'
}

--- defined power sources, used for equipment generation, defined in class descriptors
_M.power_sources = table.map(function(k, v) return k, true end, table.keys_to_values({'technique','technique_ranged','nature','arcane','psionic','antimagic'}))

--- map attributes to power restrictions for an entity
--	returns an updated list of forbidden power types including attributes
--	used for checking for compatible equipment and npc randboss classes
function _M:attrPowers(e, not_ps)
	not_ps = table.clone(not_ps or e.not_power_source or e.forbid_power_source) or {}
	if e.attr then
		if e:attr("has_arcane_knowledge") then not_ps.antimagic = true end
		if e:attr("undead") then not_ps.antimagic = true end
		if e:attr("forbid_arcane") then not_ps.arcane = true end
--		if e:attr("forbid_nature") then not_ps.nature = true end
	end
	return not_ps
end

--- Checks power_source compatibility between two entities
--	returns true if e2 is compatible with e1, false otherwise
--	by default, only checks .power_source vs. .forbid_power_source between entities
--  @param e1, e2 entities to check
--	@param require_power if true, will also check that e2.power_source (if present) has a match in e1.power_source
--  @param [opt = string] theme type of checks to perform, default to all
--	use updatePowers to resolve conflicts.
function _M:checkPowers(e1, e2, require_power, theme)
	if not e1 or not e2 then return true end
	-- print("Comparing power sources",e1.name, e2.name)
	-- check for excluded power sources first
	if theme == "antimagic_only" then -- check antimagic restrictions only
		local not_ps = self:attrPowers(e1)
		if e2.power_source and (e2.power_source.antimagic and not_ps.antimagic or e2.power_source.arcane and not_ps.arcane) then return false end
		local not_ps = self:attrPowers(e2)
		if e1.power_source and (e1.power_source.antimagic and not_ps.antimagic or e1.power_source.arcane and not_ps.arcane) then return false end
		return true
	else -- check for all conflicts
		local not_ps = self:attrPowers(e2)
		for ps, _ in pairs(e1.power_source or {}) do
			if not_ps[ps] then return false end
		end
		not_ps = self:attrPowers(e1)
		for ps, _ in pairs(e2.power_source or {}) do
			if not_ps[ps] then return false end
		end
		-- check for required power_sources
		if require_power and e1.power_source and e2.power_source then
			for yes_ps, _ in pairs(e1.power_source)	do
				if (e2.power_source and e2.power_source[yes_ps]) then return true end
			end
			return false
		end
	end
	return true
end

--- Adjusts power source parameters and themes to remove conflicts
-- @param forbid_ps = {arcane = true, technique = true, ...} forbidden power sources <none>
-- @param allow_ps = {arcane = true, technique = true, ...} allowed power sources <all allowed>
-- @param randthemes = number of themes to pick randomly from the global pool <0>
-- @param force_themes = themes to always include {"attack", "antimagic", ...} applied last (optional)
-- 	themes included can add to forbid_ps and allow_ps
-- precedence is: forbid_ps > allow_ps > force_themes
-- returns new forbid_ps, allow_ps, themes (made consistent)
function _M:updatePowers(forbid_ps, allow_ps, randthemes, force_themes)
	local spec_powers = allow_ps and next(allow_ps)
	local yes_ps = spec_powers and table.clone(allow_ps) or table.clone(self.power_sources)
	local not_ps = forbid_ps and table.clone(forbid_ps) or {}
	local allthemes, themes = table.clone(self.power_themes), {}
	local force_themes = force_themes and table.clone(force_themes) or {}

	for fps, _ in pairs(not_ps) do --enforce forbidden power restrictions
		yes_ps[fps] = nil
		if fps == "arcane" then
			table.removeFromList(allthemes, 'spell', 'arcane', 'blight', 'temporal')
			yes_ps.arcane = nil
		elseif fps == "antimagic" then
			table.removeFromList(allthemes, 'antimagic')
			yes_ps.antimagic = nil
		elseif fps == "nature" then
			table.removeFromList(allthemes, 'nature')
		elseif fps == "psionic" then
			table.removeFromList(allthemes, 'mental', 'mind')
		end
	end
	if spec_powers then --apply specified power sources
		if yes_ps.antimagic then
			not_ps.arcane = true
			table.removeFromList(allthemes, 'spell', 'arcane', 'blight', 'temporal')
		end
		if yes_ps.arcane then
			not_ps.antimagic = true
			table.removeFromList(allthemes, 'antimagic')
		end
		if yes_ps.nature then
			if not table.keys_to_values(allthemes).nature then table.insert(allthemes, 'nature') end
		end
	end
	-- build themes list if needed beginning with those requested
	local theme_count = (randthemes or 0) + #force_themes
	for n = 1, theme_count do
		local v = nil
		if #force_themes > 0 then -- always add forced_themes if possible
			v = rng.tableRemove(force_themes)
			table.removeFromList(allthemes, v)
		end
		if not v then v = rng.tableRemove(allthemes) end -- pick from remaining themes
		themes[#themes+1] = v
			-- enforce theme-theme exclusions
		if v == 'antimagic' then
			table.removeFromList(allthemes, 'spell', 'arcane', 'blight', 'temporal')
			yes_ps.antimagic, yes_ps.arcane = true, nil
			not_ps.arcane = true
		elseif v == 'spell' or v == 'arcane' or v == 'blight' or v == 'temporal' then
			table.removeFromList(allthemes, 'antimagic')
			yes_ps.antimagic, yes_ps.arcane = nil, true
			not_ps.antimagic = true
		elseif v == 'nature' then
			table.removeFromList(allthemes, 'blight')
			yes_ps.nature = true 
		elseif v == 'mind' or v == 'mental' then
			yes_ps.psionic = true
		elseif v == 'physical' then
			yes_ps.technique, yes_ps.technique_ranged = true, true
		end
	end
	return not_ps, yes_ps, themes
end

--- Generate randarts for this state with optional parameters:
-- @param data.base = base object to add powers to (base.randart_able must be defined) <random object>
-- @param data.base_filter = filter passed to makeEntity when making base object
-- @param data.lev = character level to generate for (affects point budget, #themes and #powers) <12-50>
-- @param data.power_points_factor = lev based power points multiplier <1>
-- @param data.nb_points_add = #extra budget points to spend on random powers <0>
-- @param data.powers_special = function(p) that must return true on each random power to add (from base.randart_able)
-- @param data.nb_themes = #power themes (power groups) for random powers to use <scales to 5 with lev>
-- @param data.force_themes = additional power theme(s) to use for random powers = {"attack", "arcane", ...}
-- @param data.egos = total #egos to include (forced + random) <3>
-- @param data.greater_egos_bias = #egos that should be greater egos <2/3 * data.egos>
-- @param data.force_egos = list of egos ("egoname1", "egoname2", ...) to add first (overrides restrictions)
-- @param data.ego_special = function(e) on ego table that must return true for allowed egos
-- @param data.forbid_power_source = disallowed power type(s) for egos
-- 	eg:{arcane = true, psionic = true, technique = true, nature = true, antimagic = true}
--		note some objects always have a power source by default (i.e. wands are always arcane powered)
-- @param data.power_source = allowed power type(s) <all allowed> if specified, only egos matching at least one of the power types will be added.  themes (random or forced) can add allowed power_sources
-- @param data.namescheme = parameters to be passed to the NameGenerator <local randart_name_rules table>
-- @param data.add_pool if true, adds the randart to the world artifact pool <nil>
-- @param data.post = function(o) to be applied to the randart after all egos and powers have been added and resolved
function _M:generateRandart(data)
	-- Setup basic parameters and override global variables to match data
	data = data or {}
	local lev = data.lev or rng.range(12, 50)
	data.forbid_power_source = data.forbid_power_source or {}
	local oldlev = game.level.level
	local oldclev = resolvers.current_level
	game.level.level = lev
	resolvers.current_level = math.ceil(lev * 1.4)

	-- Get a base object
	local base = data.base or game.zone:makeEntity(game.level, "object", data.base_filter or {ignore_material_restriction=true, no_tome_drops=true, ego_filter={keep_egos=true, ego_chance=-1000}, special=function(e)
		return (not e.unique and e.randart_able) and (not e.material_level or e.material_level >= 2) and true or false
	end}, nil, true)
	if not base or not base.randart_able then game.level.level = oldlev resolvers.current_level = oldclev return end
	local o = base:cloneFull()

	local display = o.display

--o.baseobj = base:cloneFull() -- debugging code
--o.gendata = table.clone(data, true) -- debugging code

	-- Load possible random powers
	local powers_list = engine.Object:loadList(o.randart_able, nil, nil,
		function(e)
			if data.powers_special and not data.powers_special(e) then e.rarity = nil end
			if e.rarity then
				e.rarity = math.ceil(e.rarity / 5)
			end
		end)
	--print(" * loaded powers list:")
	o.randart_able = nil
	
	-----------------------------------------------------------
	-- Pick Themes
	-----------------------------------------------------------
	local nb_themes = data.nb_themes
	if not nb_themes then -- Gradually increase number of themes at higher levels so there are enough powers to spend points on
		nb_themes = math.max(2,5*lev/(lev+50)) -- Maximum 5 themes possible
		nb_themes= math.floor(nb_themes) + (rng.percent((nb_themes-math.floor(nb_themes))*100) and 1 or 0)
	end
	-- update power sources and themes lists based on base object properties
	local psource
	if o.power_source then 
		psource = table.clone(o.power_source)
		if data.power_source then table.merge(psource, data.power_source) end
		-- forbid power sources that conflict with existing power source
		data.forbid_power_source, psource = self:updatePowers(data.forbid_power_source, psource)
		if data.power_source then data.power_source = psource end
	end
	-- resolve any power/theme conflicts with input data
	local themes
	data.forbid_power_source, psource, themes = self:updatePowers(data.forbid_power_source, data.power_source, nb_themes, data.force_themes)
	if data.power_source then data.power_source = psource end
	
	themes = table.map(function(k, v) return k, true end, table.keys_to_values(themes))

	-----------------------------------------------------------
	-- Determine power
	-----------------------------------------------------------
	-- Note double diminishing returns when coupled with scaling factor in merger (below)
	-- Maintains randomness throughout level range ~50% variability in points
	local points = math.max(0, math.ceil(0.1*lev^0.75*(8 + rng.range(1, 7)) * (data.power_points_factor or 1))+(data.nb_points_add or 0))
	local nb_powers = 1 + rng.dice(math.max(1, math.ceil(0.281*lev^0.6)), 2) + (data.nb_powers_add or 0)
	local nb_egos = data.egos or 3
	local gr_egos = data.greater_egos_bias or math.floor(nb_egos*2/3) -- 2/3 greater egos by default
	local powers = {}
	print("Begin randart generation:", "level = ", lev, "egos =", nb_egos,"gr egos =", gr_egos, "rand themes = ", nb_themes, "points = ", points, "nb_powers = ",nb_powers)
	if data.force_themes and #data.force_themes > 0 then print(" * forcing themes:",table.concat(data.force_themes,",")) end
	print(" * using themes", table.concat(table.keys(themes), ','))
	local force_egos = table.clone(data.force_egos)
	if force_egos then print(" * forcing egos:", table.concat(force_egos, ',')) end
	if data.forbid_power_source and next(data.forbid_power_source) then print(" * forbid power sources:", table.concat(table.keys(data.forbid_power_source), ',')) end
	if data.power_source and next(data.power_source) then print(" * allowed power sources:", table.concat(table.keys(data.power_source), ',')) end
	o.cost = o.cost + points * 7
	local use_themes = next(themes) and true or false
	-- Select some powers
	local themes_fct = function(e)
		if use_themes then
			for theme, _ in pairs(e.theme) do if themes[theme] then return true end end
			return false
		end
		return true
	end
	local power_themes = {}
	local lst = game.zone:computeRarities("powers", powers_list, game.level, themes_fct) --Note: probabilities diminish as level exceeds 50 (limited to ~1000 by mod.class.zone:adjustComputeRaritiesLevel(level, type, lev))

	for i = 1, nb_powers do
		local p = game.zone:pickEntity(lst)
		if p then
			for t, _ in pairs(p.theme) do if themes[t] and randart_name_rules[t] then power_themes[t] = (power_themes[t] or 0) + 1 end end
			powers[#powers+1] = p:clone()
		end
	end
--	print("Selected powers:") for i, p in ipairs(powers) do print(" * ",p.name, table.concat(table.keys(p.theme or {}), ",")) end
	power_themes = table.listify(power_themes)
	table.sort(power_themes, function(a, b) return a[2] < b[2] end)

	-----------------------------------------------------------
	-- Make up a name based on themes
	-----------------------------------------------------------
	local themename = power_themes[#power_themes]
	themename = themename and themename[1] or nil
	local ngd = NameGenerator.new(rng.chance(2) and randart_name_rules.default or randart_name_rules.default2)
	local ngt = (themename and randart_name_rules[themename] and NameGenerator.new(randart_name_rules[themename])) or ngd
	local name
	local namescheme = data.namescheme or ((ngt ~= ngd) and rng.range(1, 4) or rng.range(1, 3))
	if namescheme == 1 then
		name = "%s '"..ngt:generate().."'"
	elseif namescheme == 2 then
		name = ngt:generate().." the %s"
	elseif namescheme == 3 then
		name = ngt:generate()
	elseif namescheme == 4 then
		name = ngd:generate().." the "..ngt:generate()
	end
	o.unided_namescheme = rng.table(unided_names).." %s"
	o.unided_name = o.unided_namescheme:format(o.unided_name or o.name)
	o.namescheme = name
	o.define_as = name:format(o.name):upper():gsub("[^A-Z]", "_")
	o.unique = name:format(o.name)
	o.name = name:format(o.name)
	o.randart = true
	o.no_unique_lore = true
	o.rarity = rng.range(200, 290)

	print("Creating randart "..name.."("..o.unided_name..") with "..(themename or "no themename"))

	-----------------------------------------------------------
	-- Add ego properties (modified by power_source restrictions)
	-----------------------------------------------------------
	if o.egos and nb_egos > 0 then
		local picked_egos = {}
		local legos = {}
		local been_greater = 0
		game.zone:getEntities(game.level, "object") -- make sure ego definitions are loaded
		-- merge all egos into one list to correctly calculate rarities
		table.append(legos, game.level:getEntitiesList("object/"..o.egos..":prefix") or {})
		table.append(legos, game.level:getEntitiesList("object/"..o.egos..":suffix") or {})
		table.append(legos, game.level:getEntitiesList("object/"..o.egos..":") or {})
--		print(" * loaded ", #legos, "ego definitions from ", o.egos)
		for i = 1, nb_egos or 3 do
			local list = {}
			local gr_ego, ignore_filter = false, false
			if rng.percent(100*lev/(lev+50)) and been_greater < gr_egos then -- Phase out (but don't eliminate) lesser egos with level
				gr_ego = true
			end
			if force_egos then -- use forced egos list first
				local found = false
				repeat
					local fego = rng.tableRemove(force_egos)
					if not fego then break end
					for z, e in ipairs(legos) do
						if e.e.name:find(fego, nil, true) then
--							print(" * found forced ego", e.e.name)
							list[1] = e.e
							found = true
							gr_ego, ignore_filter = false, true -- make sure forced ego is not filtered out later
							break
						end
					end
				until found or #force_egos <= 0
				if #force_egos == 0 then force_egos = nil end
			end
			if #list == 0 then -- no forced egos, copy the whole list
				for z = 1, #legos do
					list[#list+1] = legos[z].e
				end
			end
			
			local ef = self:egoFilter(game.zone, game.level, "object", "randartego", o, {special=data.ego_special, forbid_power_source=data.forbid_power_source, power_source=data.power_source}, picked_egos, {})

			local filter = function(e) -- check ego definition properties
				if ignore_filter then return true end
				if not ef.special or ef.special(e) then
					if gr_ego and not e.greater_ego then return false end
					return game.state:checkPowers(ef, e, true) -- check power_source compatibility
				end
			end

			local pick_egos = game.zone:computeRarities("object", list, game.level, filter, nil, nil)
			local ego = game.zone:pickEntity(pick_egos)
			if ego then
				table.insert(picked_egos, ego)
				print(" ** selected ego", ego.name, (ego.greater_ego and "(greater)" or "(normal)"), ego.power_source and table.concat(table.keys(ego.power_source), ","))
				if ego.greater_ego then been_greater = been_greater + 1 end
				-- OMFG this is ugly, there is a very rare combination that can result in a crash there, so we .. well, ignore it :/
				-- Sorry.
				-- Fixed against overflow
				local ok, err = pcall(game.zone.applyEgo, game.zone, o, ego, "object", true)
				if not ok then
					data.fails = (data.fails or 0) + 1
					print("randart creation error", err)
					print("game.zone.applyEgo failed at creating a randart, retrying", data.fails)
					game.level.level = oldlev
					resolvers.current_level = oldclev
					if data.fails < 4 then return self:generateRandart(data) else return end
				end
			else -- no ego found: increase budget for random powers to compensate
				local xpoints = gr_ego and 8 or 5
				print((" ** no ego found (+%d points)"):format(xpoints))
				points = points + xpoints
			end
		end
--		o.egos = nil o.egos_chance = nil o.force_ego = nil
	end
	-- Re-resolve with the (possibly) new resolvers
	o:resolve()

	-----------------------------------------------------------
	-- Imbue random powers into the randart according to themes
	-----------------------------------------------------------
	local function merger(d, e, k, dst, src, rules, state) --scale: factor to adjust power limits for levels higher than 50
		if (not state.path or #state.path == 0) and not state.copy then
			if k == "copy" then -- copy into root
				state.copy = true
				table.applyRules(dst, e, rules, state)
			end
		end
		local scale = state.scaleup or 1
		if type(e) == "table" and e.__resolver and e.__resolver == "randartmax" and d then
			d.v = d.v + e.v
			d.max = e.max
			if e.max < 0 then
				if d.v < e.max * scale then --Adjust maximum values for higher levels
					d.v = math.floor(e.max * scale)
				end
			else
				if d.v > e.max * scale then --Adjust maximum values for higher levels
					d.v = math.floor(e.max * scale)
				end
			end
			return true
		end
	end

	-- Distribute points: half to any powers and half to a shortened list of powers to focus their effects
	local selected_powers = {}
	local hpoints = math.ceil(points / 2)
	local i = 0
	local fails = 0
	while hpoints > 0 and #powers >0 and fails <= #powers do
		i = util.boundWrap(i + 1, 1, #powers)
		local p = powers[i]
		if p and p.points <= hpoints*2 then -- Intentionally allow the budget to be exceeded slightly to guarantee powers at low levels
			local state = {scaleup = math.max(1,(lev/(p.level_range[2] or 50))^0.5)} --Adjust scaleup factor for each power based on lev and level_range max
		print(" * adding power: "..p.name.."("..p.points.." points)")
			selected_powers[p.name] = selected_powers[p.name] or {}
			table.ruleMergeAppendAdd(selected_powers[p.name], p, {merger}, state)
			hpoints = hpoints - p.points 
			p.points = p.points * 1.5 --increased cost (=diminishing returns) on extra applications of the same power
		else
			fails = fails + 1
		end
	end
--	o:resolve() o:resolve(nil, true)

	-- Bias towards a shortened list of powers
	local bias_powers = {}
	local nb_bias = math.max(1,rng.range(math.ceil(#powers/2), 20*lev /(lev+50))) --Limit bias powers to 20 (50/5 * 2) powers
	for i = 1, nb_bias do bias_powers[#bias_powers+1] = rng.table(powers) end
	local hpoints = math.ceil(points / 2)
	local i = 0
	fails = 0 
	while hpoints > 0 and fails <= #bias_powers do
		i = util.boundWrap(i + 1, 1, #bias_powers)

		local p = bias_powers[i] and bias_powers[i]
		if p and p.points <= hpoints * 2 then
			local state = {scaleup = math.max(1,(lev/(p.level_range[2] or 50))^0.5)} --Adjust scaleup factor for each power based on lev and level_range max
--			print(" * adding bias power: "..p.name.."("..p.points.." points)")
			selected_powers[p.name] = selected_powers[p.name] or {}
			table.ruleMergeAppendAdd(selected_powers[p.name], p, {merger}, state)
			hpoints = hpoints - p.points
			p.points = p.points * 1.5 --increased cost (=diminishing returns) on extra applications of the same power
		else
			fails = fails + 1
		end
	end

	for _, ego in pairs(selected_powers) do
		ego.instant_resolve = true  -- resolve to be able to add
		ego = engine.Entity.new(ego) -- get a real uid
		game.zone:applyEgo(o, ego, "object", true)
	end

	o:resolve()
	o:resolve(nil, true)

	-- Always assign at least one power source based on themes and restrictions
	if not o.power_source then
		local not_ps = data.forbid_power_source or {}
		local ps = data.power_source or {}
		if themes.physical or themes.defense then ps.technique = true end
		if themes.mental then ps[rng.percent(50) and 'nature' or 'psionic'] = true end
		if themes.spell or themes.arcane or themes.blight or themes.temporal then
			ps.arcane = true not_ps.antimagic = true
		end
		if themes.nature then ps.nature = true end
		if themes.antimagic then
			ps.antimagic = true not_ps.arcane = true
		end
		if not next(ps) then ps[rng.tableIndex(data.power_source or self.power_sources)] = true end
		ps = table.minus_keys(ps, not_ps)
		if not next(ps) then ps = {unknown = true} end
		print(" * using implied power source(s) ", table.concat(table.keys(ps), ','))
		o.power_source = ps
	end

	-- Assign weapon damage
	if o.combat and not (o.subtype == "staff" or o.subtype == "mindstar" or o.fixed_randart_damage_type) then
		local theme_map = {
			physical = engine.DamageType.PHYSICAL,
			--mental = engine.DamageType.MIND,
			fire = engine.DamageType.FIRE,
			lightning = engine.DamageType.LIGHTNING,
			acid = engine.DamageType.ACID,
			mind = engine.DamageType.MIND,
			arcane = engine.DamageType.ARCANE,
			blight = engine.DamageType.BLIGHT,
			nature = engine.DamageType.NATURE,
			temporal = engine.DamageType.TEMPORAL,
			light = engine.DamageType.LIGHT,
			dark = engine.DamageType.DARK,
		}

		local pickDamtype = function(themes_list)
			if not rng.percent(18) then return engine.DamageType.PHYSICAL end
				for k, v in pairs(themes_list) do
					if theme_map[k] then return theme_map[k] end
				end
			return engine.DamageType.PHYSICAL
		end
		o.combat.damtype = pickDamtype(themes)
	end

	o.display = display

	if data.post then
		data.post(o)
	end

	if data.add_pool then self:addWorldArtifact(o) end
	-- restore global variables
	game.level.level = oldlev
	resolvers.current_level = oldclev
	return o
end

--- Adds randart properties (egos and random powers) to an existing object
-- @param o is the object to be updated (o.egos and o.randart_able should be defined as needed)
-- @param data is the table of randart parameters passed to generateRandart
-- usable powers and set properties are not overwritten if present
function _M:addRandartProperties(o, data)
	print(" ** adding randart properties to ", o.name, o.uid)
	data.base = o
	-- properties to not overwrite
	local protect_props = {name = true, uid=true, rarity = true, unided_name = true, define_as = true, unique = o.unique, randart = o.unique, no_unique_lore = true, require=true, egos = true, randart_able = true}
	if o.use_power or o.use_talent or o.use_simple then -- allow only one use power
		table.merge(protect_props, {use_power = true, use_talent = true, use_simple = true,
			use_no_energy=true, use_no_blind = o.use_no_blind, use_no_silence = o.use_no_silence, use_no_wear = o.use_no_wear,
			talent_cooldown = true, power = true, max_power=true, power_regen = true, charm_on_use = o.charm_on_use})
	end
	if o.set_list then -- preserve set properties Note: mindstar set flags ARE copied
		table.merge(protect_props, {set_list = true, on_set_complete = true, on_set_broken = true})
	end
	print(" ** addRandartProperties: property merge restrictions: ", table.concat(table.keys(protect_props), ','))
	local art = game.state:generateRandart(data)
	if art then
		table.merge(o, art, true, protect_props, nil)
	else
		print(" ** FAILED to generate randart properties to add to ", o.name, o.uid)
	end
end

local wda_cache = {}

--- Runs the worldmap directory AI
function _M:worldDirectorAI()
	if not game.level.data.wda or not game.level.data.wda.script then return end
	local script = wda_cache[game.level.data.wda.script]
	if not script then
		local function getBaseName(name)
			local base = "/data"
			local _, _, addon, rname = name:find("^([^+]+)%+(.+)$")
			if addon and rname then
				base = "/data-"..addon
				name = rname
			end
			return base.."/wda/"..name..".lua"
		end

		local f, err = loadfile(getBaseName(game.level.data.wda.script))
		if not f then error(err) end
		wda_cache[game.level.data.wda.script] = f
		script = f
	end

	game.level.level = game.player.level
	setfenv(script, setmetatable({wda=game.level.data.wda}, {__index=_G}))
	local ok, err = pcall(script)
	if not ok and err then error(err) end
end

function _M:spawnWorldAmbush(enc, dx, dy, kind)
	game:onTickEnd(function()

	local gen = { class = "engine.generator.map.Forest",
		edge_entrances = {4,6},
		sqrt_percent = 50,
		zoom = 10,
		floor = "GRASS",
		wall = "TREE",
		down = "DOWN",
		up = "GRASS_UP_WILDERNESS",
	}
	local g1 = game.level.map(dx, dy, engine.Map.TERRAIN)
	local g2 = game.level.map(game.player.x, game.player.y, engine.Map.TERRAIN)
	local g = g1
	if not g or not g.can_encounter then g = g2 end
	if not g or not g.can_encounter then return false end

	if g.can_encounter == "desert" then gen.floor = "SAND" gen.wall = "PALMTREE" end

	local terrains = mod.class.Grid:loadList{"/data/general/grids/basic.lua", "/data/general/grids/forest.lua", "/data/general/grids/sand.lua"}
	terrains[gen.up].change_level_shift_back = true

	local zone = mod.class.Zone.new("ambush", {
		name = "Ambush!",
		level_range = {game.player.level, game.player.level},
		level_scheme = "player",
		max_level = 1,
		actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() + level.level-1 + rng.range(-1,2) end,
		width = enc.width or 20, height = enc.height or 20,
--		no_worldport = true,
		all_lited = true,
		ambient_music = "last",
		max_material_level = util.bound(math.ceil(game.player.level / 10), 1, 5),
		min_material_level = util.bound(math.ceil(game.player.level / 10), 1, 5) - 1,
		generator =  {
			map = gen,
			actor = { class = "mod.class.generator.actor.Random", nb_npc = enc.nb or {1,1}, filters=enc.filters },
		},

		reload_lists = false,
		npc_list = mod.class.NPC:loadList("/data/general/npcs/all.lua", nil, nil, function(e) e.make_escort=nil end),
		grid_list = terrains,
		object_list = mod.class.Object:loadList("/data/general/objects/objects.lua"),
		trap_list = {},
		post_process = function(level)
			-- Find a good starting location, on the opposite side of the exit
			local sx, sy = level.map.w-1, rng.range(0, level.map.h-1)
			level.spots[#level.spots+1] = {
				check_connectivity = "entrance",
				x = sx,
				y = sy,
			}
			level.default_down = level.default_up
			level.default_up = {x=sx, y=sy}
		end,
	})
	self.farm_factor = self.farm_factor or {}
	self.farm_factor[kind] = self.farm_factor[kind] or 1
	zone.objects_cost_modifier = self.farm_factor[kind]
	zone.exp_worth_mult = self.farm_factor[kind]

	self.farm_factor[kind] = self.farm_factor[kind] * 0.9

	game.player:runStop()
	game.player.energy.value = game.energy_to_act
	game.paused = true
	game:changeLevel(1, zone, {temporary_zone_shift=true})
	engine.ui.Dialog:simplePopup("Ambush!", "You have been ambushed!")

	end)
end

function _M:handleWorldEncounter(target)
	local enc = target.on_encounter
	if type(enc) == "function" then return enc() end
	if type(enc) == "table" then
		if enc.type == "ambush" then
			local x, y = target.x, target.y
			target:die()
			self:spawnWorldAmbush(enc, x, y, target.name or "generic")
		end
	end
end

--------------------------------------------------------------------
-- Ambient sounds stuff
--------------------------------------------------------------------
function _M:makeAmbientSounds(level, t)
	local s = {}
	level.data.ambient_bg_sounds = s

	for chan, data in pairs(t) do
		data.name = chan
		s[#s+1] = data
	end
end

function _M:playAmbientSounds(level, s, nb_keyframes)
	for i = 1, #s do
		local data = s[i]

		if data._sound then if not data._sound:playing() then data._sound = nil end end

		if not data._sound and nb_keyframes > 0 and rng.chance(math.ceil(data.chance / nb_keyframes)) then
			local f = rng.table(data.files)
			data._sound = game:playSound(f)
			local pos = {x=0,y=0,z=0}
			if data.random_pos then
				local a, r = rng.float(0, 2 * math.pi), rng.float(1, data.random_pos.rad or 10)
				pos.x = math.cos(a) * r
				pos.y = math.sin(a) * r
			end
--			print("===playing", data.name, f, data._sound)
			if data._sound then
				if data.volume_mod then data._sound:volume(data._sound:volume() * data.volume_mod) end
				if data.pitch then data._sound:pitch(data.pitch) end
			end
		end
	end
end

--------------------------------------------------------------------
-- Weather stuff
--------------------------------------------------------------------
function _M:makeWeather(level, nb, params, typ)
	if not config.settings.tome.weather_effects then return end

	local ps = {}
	params.width = level.map.w*level.map.tile_w
	params.height = level.map.h*level.map.tile_h
	for i = 1, nb do
		local p = table.clone(params, true)
		p.particle_name = p.particle_name:format(nb)
		ps[#ps+1] = Particles.new(typ or "weather_storm", 1, p)
	end
	level.data.weather_particle = ps
end

function _M:displayWeather(level, ps, nb_keyframes)
	local dx, dy = level.map:getScreenUpperCorner() -- Display at map border, always, so it scrolls with the map
	for j = 1, #ps do
		ps[j].ps:toScreen(dx, dy, true, 1)
	end
end

function _M:makeWeatherShader(level, shader, params)
	if not config.settings.tome.weather_effects then return end

	local ps = level.data.weather_shader or {}
	ps[#ps+1] = Shader.new(shader, params)
	level.data.weather_shader = ps
end

function _M:displayWeatherShader(level, ps, x, y, nb_keyframes)
	local dx, dy = level.map:getScreenUpperCorner() -- Display at map border, always, so it scrolls with the map

	local sx, sy = level.map._map:getScroll()
	local mapcoords = {(-sx + level.map.mx * level.map.tile_w) / level.map.viewport.width , (-sy + level.map.my * level.map.tile_h) / level.map.viewport.height}

	for j = 1, #ps do
		if ps[j].shad then
			ps[j]:setUniform("mapCoord", mapcoords)
			ps[j].shad:use(true)
			core.display.drawQuad(x, y, level.map.viewport.width, level.map.viewport.height, 255, 255, 255, 255)
			ps[j].shad:use(false)
		end
	end
end

local function doTint(from, to, amount)
	local tint = {r = 0, g = 0, b = 0}
	tint.r = (from.r * (1 - amount) + to.r * amount)
	tint.g = (from.g * (1 - amount) + to.g * amount)
	tint.b = (from.b * (1 - amount) + to.b * amount)
	return tint
end

--- Compute a day/night cycle
-- Works by changing the tint of the map gradualy
function _M:dayNightCycle()
	local map = game.level.map
	local shown = map.color_shown
	local obscure = map.color_obscure

	if not config.settings.tome.daynight then
		-- Restore defaults
		map._map:setShown(unpack(shown))
		map._map:setObscure(unpack(obscure))
		return
	end

	local hour, minute = game.calendar:getTimeOfDay(game.turn)
	hour = hour + (minute / 60)
	local tint = {r = 0.1, g = 0.1, b = 0.1}
	local startTint = {r = 0.1, g = 0.1, b = 0.1}
	local endTint = {r = 0.1, g = 0.1, b = 0.1}
	if hour <= 4 then
		tint = {r = 0.1, g = 0.1, b = 0.1}
	elseif hour > 4 and hour <= 7 then
		startTint = { r = 0.1, g = 0.1, b = 0.1 }
		endTint = { r = 0.3, g = 0.3, b = 0.5 }
		tint = doTint(startTint, endTint, (hour - 4) / 3)
	elseif hour > 7 and hour <= 12 then
		startTint = { r = 0.3, g = 0.3, b = 0.5 }
		endTint = { r = 0.9, g = 0.9, b = 0.9 }
		tint = doTint(startTint, endTint, (hour - 7) / 5)
	elseif hour > 12 and hour <= 18 then
		startTint = { r = 0.9, g = 0.9, b = 0.9 }
		endTint = { r = 0.9, g = 0.9, b = 0.6 }
		tint = doTint(startTint, endTint, (hour - 12) / 6)
	elseif hour > 18 and hour < 24 then
		startTint = { r = 0.9, g = 0.9, b = 0.6 }
		endTint = { r = 0.1, g = 0.1, b = 0.1 }
		tint = doTint(startTint, endTint, (hour - 18) / 6)
	end
	map._map:setShown(shown[1] * (tint.r+0.4), shown[2] * (tint.g+0.4), shown[3] * (tint.b+0.4), shown[4])
	map._map:setObscure(obscure[1] * (tint.r+0.2), obscure[2] * (tint.g+0.2), obscure[3] * (tint.b+0.2), obscure[4])
end

--------------------------------------------------------------------
-- Donations
--------------------------------------------------------------------
function _M:checkDonation(back_insert)
	-- Multiple checks to see if this is a "good" time
	-- This is only called when something nice happens (like an achievement)
	-- We then check multiple conditions to make sure the player is in a good state of mind

	-- Steam users have paid
	if core.steam then
		print("Donation check: steam user")
		return
	end

	-- If this is a reccuring donator, do not bother her/him
	if profile.auth and tonumber(profile.auth.donated) and profile.auth.sub == "yes" then
		print("Donation check: already a reccuring donator")
		return
	end

	-- Dont ask often
	if profile.auth and tonumber(profile.auth.donated) then
		local last = profile.mod.donations and profile.mod.donations.last_ask or 0
		local min_interval = 30 * 24 * 60 * 60 -- 1 month
		if os.time() < last + min_interval then
			print("Donation check: too soon (donator)")
			return
		end
	else
		local last = profile.mod.donations and profile.mod.donations.last_ask or 0
		local min_interval = 7 * 24 * 60 * 60 -- 1 week
		if os.time() < last + min_interval then
			print("Donation check: too soon (player)")
			return
		end
	end

	-- Not as soon as they start playing, wait 15 minutes
	if os.time() - game.real_starttime < 15 * 60 then
		print("Donation check: not started tome long enough")
		return
	end

	-- Total playtime must be over a few hours
	local total = profile.generic.modules_played and profile.generic.modules_played.tome or 0
	if total + (os.time() - game.real_starttime) < 4 * 60 * 60 then
		print("Donation check: total time too low")
		return
	end

	-- Dont ask low level characters, they are probably still pissed to not have progressed further
	if game.player.level < 10 then
		print("Donation check: too low level")
		return
	end

	-- Dont ask people in immediate danger
	if game.player.life / game.player.max_life < 0.7 then
		print("Donation check: too low life")
		return
	end

	-- Dont ask people that already have their hands full
	local nb_foes = 0
	for i = 1, #game.player.fov.actors_dist do
		local act = game.player.fov.actors_dist[i]
		if act and game.player:reactionToward(act) < 0 and not act.dead then
			if act.rank and act.rank > 3 then nb_foes = nb_foes + 1000 end -- Never with bosses in sight
			nb_foes = nb_foes + 1
		end
	end
	if nb_foes > 2 then
		print("Donation check: too many foes")
		return
	end

	-- Request money! Even a god has to eat :)
	profile:saveModuleProfile("donations", {last_ask=os.time()})

	if back_insert then
		game:registerDialogAt(Donation.new(), 2)
	else
		game:registerDialog(Donation.new())
	end
end

--------------------------------------------------------------
-- Loot filters
--------------------------------------------------------------

local drop_tables = {
	normal = {
		[1] = {
			uniques = 0.5,
			double_greater = 0,
			greater_normal = 0,
			greater = 0,
			double_ego = 20,
			ego = 45,
			basic = 38,
			money = 7,
			lore = 2,
		},
		[2] = {
			uniques = 0.7,
			double_greater = 0,
			greater_normal = 0,
			greater = 10,
			double_ego = 35,
			ego = 30,
			basic = 41,
			money = 8,
			lore = 2.5,
		},
		[3] = {
			uniques = 1,
			double_greater = 10,
			greater_normal = 15,
			greater = 25,
			double_ego = 25,
			ego = 25,
			basic = 10,
			money = 8.5,
			lore = 2.5,
		},
		[4] = {
			uniques = 1.1,
			double_greater = 15,
			greater_normal = 35,
			greater = 25,
			double_ego = 20,
			ego = 5,
			basic = 5,
			money = 8,
			lore = 3,
		},
		[5] = {
			uniques = 1.2,
			double_greater = 35,
			greater_normal = 30,
			greater = 20,
			double_ego = 10,
			ego = 5,
			basic = 5,
			money = 8,
			lore = 3,
		},
	},
	store = {
		[1] = {
			uniques = 0.5,
			double_greater = 10,
			greater_normal = 15,
			greater = 25,
			double_ego = 45,
			ego = 10,
			basic = 0,
			money = 0,
			lore = 0,
		},
		[2] = {
			uniques = 0.5,
			double_greater = 20,
			greater_normal = 18,
			greater = 25,
			double_ego = 35,
			ego = 8,
			basic = 0,
			money = 0,
			lore = 0,
		},
		[3] = {
			uniques = 0.5,
			double_greater = 30,
			greater_normal = 22,
			greater = 25,
			double_ego = 25,
			ego = 6,
			basic = 0,
			money = 0,
			lore = 0,
		},
		[4] = {
			uniques = 0.5,
			double_greater = 40,
			greater_normal = 30,
			greater = 25,
			double_ego = 20,
			ego = 4,
			basic = 0,
			money = 0,
			lore = 0,
		},
		[5] = {
			uniques = 0.5,
			double_greater = 50,
			greater_normal = 30,
			greater = 25,
			double_ego = 10,
			ego = 0,
			basic = 0,
			money = 0,
			lore = 0,
		},
	},
	boss = {
		[1] = {
			uniques = 3,
			double_greater = 0,
			greater_normal = 0,
			greater = 5,
			double_ego = 45,
			ego = 45,
			basic = 0,
			money = 4,
			lore = 0,
		},
		[2] = {
			uniques = 4,
			double_greater = 0,
			greater_normal = 8,
			greater = 15,
			double_ego = 40,
			ego = 35,
			basic = 0,
			money = 4,
			lore = 0,
		},
		[3] = {
			uniques = 5,
			double_greater = 10,
			greater_normal = 22,
			greater = 25,
			double_ego = 25,
			ego = 20,
			basic = 0,
			money = 4,
			lore = 0,
		},
		[4] = {
			uniques = 6,
			double_greater = 40,
			greater_normal = 30,
			greater = 25,
			double_ego = 20,
			ego = 0,
			basic = 0,
			money = 4,
			lore = 0,
		},
		[5] = {
			uniques = 7,
			double_greater = 50,
			greater_normal = 30,
			greater = 25,
			double_ego = 10,
			ego = 0,
			basic = 0,
			money = 4,
			lore = 0,
		},
	},
}

local loot_mod = {
	uvault = { -- Uber vault
		uniques = 40,
		double_greater = 8,
		greater_normal = 5,
		greater = 3,
		double_ego = 0,
		ego = 0,
		basic = 0,
		money = 0,
		lore = 0,
		material_mod = 1,
	},
	gvault = { -- Greater vault
		uniques = 10,
		double_greater = 2,
		greater_normal = 2,
		greater = 2,
		double_ego = 1,
		ego = 0,
		basic = 0,
		money = 0,
		lore = 0,
		material_mod = 1,
	},
	vault = { -- Default vault
		uniques = 5,
		double_greater = 2,
		greater_normal = 3,
		greater = 3,
		double_ego = 2,
		ego = 0,
		basic = 0,
		money = 0,
		lore = 0,
		material_mod = 1,
	},
}

local default_drops = function(zone, level, what)
	if zone.default_drops then return zone.default_drops end
	local lev = util.bound(math.ceil(zone:level_adjust_level(level, "object") / 10), 1, 5)
--	print("[TOME ENTITY FILTER] making default loot table for", what, lev)
	return table.clone(drop_tables[what][lev])
end

function _M:defaultEntityFilter(zone, level, type)
	if type ~= "object" then return end

	-- By default we dont apply special filters, but we always provide one so that entityFilter is called
	return {
		tome = default_drops(zone, level, "normal"),
	}
end

--- Alter any entity filters to process tome specific loot tables
-- Here be magic! We tweak and convert and turn and create filters! It's magic but it works :)
function _M:entityFilterAlter(zone, level, type, filter)
	if type ~= "object" then return filter end

	if filter.force_tome_drops or (not filter.tome and not filter.defined and not filter.special and not filter.unique and not filter.ego_chance and not filter.ego_filter and not filter.no_tome_drops) then
		filter = table.clone(filter)
		filter.tome = default_drops(zone, level, filter.tome_drops or "normal")
	end

	if filter.tome then
		local t = (filter.tome == true) and default_drops(zone, level, "normal") or filter.tome
		filter.tome = nil

		if filter.tome_mod then
			t = table.clone(t)
			if _G.type(filter.tome_mod) == "string" then filter.tome_mod = loot_mod[filter.tome_mod] end
			for k, v in pairs(filter.tome_mod) do
--				print(" ***** LOOT MOD", k, v)
				t[k] = (t[k] or 0) * v
			end
		end

		-- If we request a specific type/subtype, we don't want categories that could make that not happen
		if filter.type or filter.subtype or filter.name then t.money = 0 t.lore = 0	end

		local u = t.uniques or 0
		local dg = u + (t.double_greater or 0)
		local ge = dg + (t.greater_normal or 0)
		local g = ge + (t.greater or 0)
		local de = g + (t.double_ego or 0)
		local e = de + (t.ego or 0)
		local m = e + (t.money or 0)
		local l = m + (t.lore or 0)
		local total = l + (t.basic or 0)

		local r = rng.float(0, total)
		if r < u then
			print("[TOME ENTITY FILTER] selected Uniques", r, u)
			filter.unique = true
			filter.not_properties = filter.not_properties or {}
			filter.not_properties[#filter.not_properties+1] = "lore"

		elseif r < dg then
			print("[TOME ENTITY FILTER] selected Double Greater", r, dg)
			filter.not_properties = filter.not_properties or {}
			filter.not_properties[#filter.not_properties+1] = "unique"
			filter.ego_chance={tries = { {ego_chance=100, properties={"greater_ego"}, power_source=filter.power_source, forbid_power_source=filter.forbid_power_source}, {ego_chance=100, properties={"greater_ego"}, power_source=filter.power_source, forbid_power_source=filter.forbid_power_source} } }

		elseif r < ge then
			print("[TOME ENTITY FILTER] selected Greater + Ego", r, ge)
			filter.not_properties = filter.not_properties or {}
			filter.not_properties[#filter.not_properties+1] = "unique"
			filter.ego_chance={tries = { {ego_chance=100, properties={"greater_ego"}, power_source=filter.power_source, forbid_power_source=filter.forbid_power_source}, {ego_chance=100, not_properties={"greater_ego"}, power_source=filter.power_source, forbid_power_source=filter.forbid_power_source} }}

		elseif r < g then
			print("[TOME ENTITY FILTER] selected Greater", r, g)
			filter.not_properties = filter.not_properties or {}
			filter.not_properties[#filter.not_properties+1] = "unique"
			filter.ego_chance={tries = { {ego_chance=100, properties={"greater_ego"}, power_source=filter.power_source, forbid_power_source=filter.forbid_power_source} } }

		elseif r < de then
			print("[TOME ENTITY FILTER] selected Double Ego", r, de)
			filter.not_properties = filter.not_properties or {}
			filter.not_properties[#filter.not_properties+1] = "unique"
			filter.ego_chance={tries = { {ego_chance=100, not_properties={"greater_ego"}, power_source=filter.power_source, forbid_power_source=filter.forbid_power_source}, {ego_chance=100, not_properties={"greater_ego"}, power_source=filter.power_source, forbid_power_source=filter.forbid_power_source} }}

		elseif r < e then
			print("[TOME ENTITY FILTER] selected Ego", r, e)
			filter.not_properties = filter.not_properties or {}
			filter.not_properties[#filter.not_properties+1] = "unique"
			filter.ego_chance={tries = { {ego_chance=100, not_properties={"greater_ego"}, power_source=filter.power_source, forbid_power_source=filter.forbid_power_source} } }

		elseif r < m then
			print("[TOME ENTITY FILTER] selected Money", r, m)
			filter.special = function(e) return e.type == "money" or e.type == "gem" end

		elseif r < l then
			print("[TOME ENTITY FILTER] selected Lore", r, l)
			filter.special = function(e) return e.lore and true or false end

		else
			print("[TOME ENTITY FILTER] selected basic", r, total)
			filter.not_properties = filter.not_properties or {}
			filter.not_properties[#filter.not_properties+1] = "unique"
			filter.ego_chance = -1000
		end
	end

	if filter.random_object then
		print("[TOME ENTITY FILTER] random object requested, removing ego chances")
		filter.ego_chance = -1000
	end

	-- By default we dont apply special filters, but we always provide one so that entityFilter is called
	return filter
end

function _M:entityFilter(zone, e, filter, type)
	if filter.forbid_power_source then
		if e.power_source then
			for k, _ in pairs(filter.forbid_power_source) do
				if e.power_source[k] then return false end
			end
		end
	end

	if filter.power_source and e.power_source then
		local ok = false
		for k, _ in pairs(filter.power_source) do
			if e.power_source[k] then ok = true break end
		end
		if not ok then return false end
	end

	if type == "object" then
		if not filter.ignore_material_restriction then
			local min_mlvl = util.getval(zone.min_material_level)
			local max_mlvl = util.getval(zone.max_material_level)
			if filter.tome_mod and filter.tome_mod.material_mod then max_mlvl = util.bound((max_mlvl or 3) + filter.tome_mod.material_mod, 1, 5) end
			if min_mlvl and not e.material_level_min_only then
				if not e.material_level then return true end
				if e.material_level < min_mlvl then return false end
			end

			if max_mlvl then
				if not e.material_level then return true end
				if e.material_level > max_mlvl then return false end
			end
		end
		if e.lore and e.rarity and util.getval(zone.no_random_lore) then return false end
		if filter.random_object and not e.randart_able then return false end
		return true
	else
		return true
	end
end

function _M:entityFilterPost(zone, level, type, e, filter)
	if type == "actor" then
		if filter.random_boss and not e.unique then
			if _G.type(filter.random_boss) == "boolean" then filter.random_boss = {}
			else filter.random_boss = table.clone(filter.random_boss, true) end
			filter.random_boss.level = filter.random_boss.level or zone:level_adjust_level(level, zone, type)
			e = self:createRandomBoss(e, filter.random_boss)
		elseif filter.random_elite and not e.unique then
			if _G.type(filter.random_elite) == "boolean" then filter.random_elite = {}
			else filter.random_elite = table.clone(filter.random_elite, true) end
			local lev = filter.random_elite.level or zone:level_adjust_level(level, zone, type)
			local base = {
				nb_classes=1,
				rank=3.2, ai = "tactical",
				life_rating = filter.random_elite.life_rating or function(v) return v * 1.3 + 2 end,
				loot_quality = "store",
				loot_quantity = 0,
				drop_equipment = false,
				no_loot_randart = true,
				resources_boost = 1.5,
				talent_cds_factor = (lev <= 10) and 3 or ((lev <= 20) and 2 or nil),
				class_filter = filter.class_filter,
				no_class_restrictions = filter.no_class_restrictions,
				level = lev,
				nb_rares = filter.random_elite.nb_rares or 1,
				check_talents_level = true,
				user_post = filter.post,
				post = function(b, data)
					if data.level <= 20 then
						b.inc_damage = b.inc_damage or {}
						b.inc_damage.all = (b.inc_damage.all or 0) - 40 * (20 - data.level + 1) / 20
					end
					-- Drop
					for i = 1, data.nb_rares do -- generate rares as weak (1 ego) randarts
						local fil = {lev=lev, egos=1, greater_egos_bias = 0, forbid_power_source=b.not_power_source,
							base_filter = {no_tome_drops=true, ego_filter={keep_egos=true, ego_chance=-1000}, 
							special=function(e)
								return (not e.unique and e.randart_able) and (not e.material_level or e.material_level >= 1) and true or false
							end}
						}
						local o = game.state:generateRandart(fil,nil, true)
						if o then
--							print("[entityFilterPost]: Generated random object for", tostring(b.name))
							o.unique, o.randart, o.rare = nil, nil, true
							if o.__original then
								local e = o.__original
								e.unique, e.randart, e.rare = nil, nil, true
							end
							b:addObject(b.INVEN_INVEN, o)
							game.zone:addEntity(game.level, o, "object")
						else
							print("[entityFilterPost]: Failed to generate random object for", tostring(b.name))
						end
					end
					if data.user_post then data.user_post(b, data) end
				end,
			}
			e = self:createRandomBoss(e, table.merge(base, filter.random_elite, true))
		end
	elseif type == "object" then
		if filter.random_object and not e.unique and e.randart_able then
			local data = _G.type(filter.random_object) == "table" and filter.random_object or {}
			local lev = math.max(1, game.zone:level_adjust_level(game.level, game.zone, "object"))
			print("[entityFilterPost]: Generating obsolete random_object")
			print(debug.traceback())
			e = game.state:generateRandart{
				lev = lev,
				egos = 0,
				nb_powers_add = data.nb_powers_add or 2, 
				nb_points_add = data.nb_points_add or 4, -- ~1 ego Note: resolvers conflicts prevent specifying egos here
				force_themes = data.force_themes or nil,
				base = e,
				post = function(o) o.rare = true o.unique = nil o.randart = nil end,
				namescheme = 3
			}
		end
	end
	return e
end

function _M:egoFilter(zone, level, type, etype, e, ego_filter, egos_list, picked_etype)
	if type ~= "object" then return ego_filter end

	if not ego_filter then ego_filter = {}
	else ego_filter = table.clone(ego_filter, true) end

	local arcane_check = false
	local nature_check = false
	local am_check = false
	for i = 1, #egos_list do
		local e = egos_list[i]
		if e.power_source and e.power_source.arcane then arcane_check = true end
		if e.power_source and e.power_source.nature then nature_check = true end
		if e.power_source and e.power_source.antimagic then am_check = true end
	end

	local fcts = {}

	if arcane_check then
		fcts[#fcts+1] = function(ego) return not ego.power_source or not ego.power_source.nature or rng.percent(20) end
		fcts[#fcts+1] = function(ego) return not ego.power_source or not ego.power_source.antimagic end
	end
	if nature_check then
		fcts[#fcts+1] = function(ego) return not ego.power_source or not ego.power_source.arcane or rng.percent(20) end
	end
	if am_check then
		fcts[#fcts+1] = function(ego) return not ego.power_source or not ego.power_source.arcane end
	end

	if #fcts > 0 then
		local old = ego_filter.special
		ego_filter.special = function(ego)
			for i = 1, #fcts do
				if not fcts[i](ego) then return false end
			end
			if old and not old(ego) then return false end
			return true
		end
	end

	return ego_filter
end

--------------------------------------------------------------
-- Random zones
--------------------------------------------------------------

local random_zone_layouts = {
	-- Forest
	{ name="forest", rarity=3, gen=function(data) return {
		class = "engine.generator.map.Forest",
		edge_entrances = {data.less_dir, data.more_dir},
		zoom = rng.range(2,6),
		sqrt_percent = rng.range(20, 50),
		noise = "fbm_perlin",
		floor = data:getFloor(),
		wall = data:getWall(),
		up = data:getUp(),
		down = data:getDown(),
	} end },
	-- Cavern
	{ name="cavern", rarity=3, gen=function(data)
		local floors = data.w * data.h * 0.4
		return {
		class = "engine.generator.map.Cavern",
		zoom = rng.range(10, 20),
		min_floor = rng.range(floors / 2, floors),
		floor = data:getFloor(),
		wall = data:getWall(),
		up = data:getUp(),
		down = data:getDown(),
	} end },
	-- Rooms
	{ name="rooms", rarity=3, gen=function(data)
		local rooms = {"random_room"}
		if rng.percent(30) then rooms = {"forest_clearing"} end
		return {
		class = "engine.generator.map.Roomer",
		nb_rooms = math.floor(data.w * data.h / 250),
		rooms = rooms,
		lite_room_chance = rng.range(0, 100),
		['.'] = data:getFloor(),
		['#'] = data:getWall(),
		up = data:getUp(),
		down = data:getDown(),
		door = data:getDoor(),
	} end },
	-- Maze
	{ name="maze", rarity=3, gen=function(data)
		return {
		class = "engine.generator.map.Maze",
		floor = data:getFloor(),
		wall = data:getWall(),
		up = data:getUp(),
		down = data:getDown(),
		door = data:getDoor(),
	} end, guardian_alert=true },
	-- Sets
	{ name="sets", rarity=3, gen=function(data)
		local set = rng.table{
			{"3x3/base", "3x3/tunnel", "3x3/windy_tunnel"},
			{"5x5/base", "5x5/tunnel", "5x5/windy_tunnel", "5x5/crypt"},
			{"7x7/base", "7x7/tunnel"},
		}
		return {
		class = "engine.generator.map.TileSet",
		tileset = set,
		['.'] = data:getFloor(),
		['#'] = data:getWall(),
		up = data:getUp(),
		down = data:getDown(),
		door = data:getDoor(),
		["'"] = data:getDoor(),
	} end },
	-- Building
--[[ not yet	{ name="building", rarity=4, gen=function(data)
		return {
		class = "engine.generator.map.Building",
		lite_room_chance = rng.range(0, 100),
		max_block_w = rng.range(14, 20), max_block_h = rng.range(14, 20),
		max_building_w = rng.range(4, 8), max_building_h = rng.range(4, 8),
		floor = data:getFloor(),
		wall = data:getWall(),
		up = data:getUp(),
		down = data:getDown(),
		door = data:getDoor(),
	} end },
]]
	-- "Octopus"
	{ name="octopus", rarity=6, gen=function(data)
		return {
		class = "engine.generator.map.Octopus",
		main_radius = {0.3, 0.4},
		arms_radius = {0.1, 0.2},
		arms_range = {0.7, 0.8},
		nb_rooms = {5, 9},
		['.'] = data:getFloor(),
		['#'] = data:getWall(),
		up = data:getUp(),
		down = data:getDown(),
		door = data:getDoor(),
	} end },
}

local random_zone_themes = {
	-- Trees
	{ name="trees", rarity=3, gen=function() return {
		load_grids = {"/data/general/grids/forest.lua"},
		getDoor = function(self) return "GRASS" end,
		getFloor = function(self) return function() if rng.chance(20) then return "FLOWER" else return "GRASS" end end end,
		getWall = function(self) return "TREE" end,
		getUp = function(self) return "GRASS_UP"..self.less_dir end,
		getDown = function(self) return "GRASS_DOWN"..self.more_dir end,
	} end },
	-- Walls
	{ name="walls", rarity=2, gen=function() return {
		load_grids = {"/data/general/grids/basic.lua"},
		getDoor = function(self) return "DOOR" end,
		getFloor = function(self) return "FLOOR" end,
		getWall = function(self) return "WALL" end,
		getUp = function(self) return "UP" end,
		getDown = function(self) return "DOWN" end,
	} end },
	-- Underground
	{ name="underground", rarity=5, gen=function() return {
		load_grids = {"/data/general/grids/underground.lua"},
		getDoor = function(self) return "UNDERGROUND_FLOOR" end,
		getFloor = function(self) return "UNDERGROUND_FLOOR" end,
		getWall = function(self) return "UNDERGROUND_TREE" end,
		getUp = function(self) return "UNDERGROUND_LADDER_UP" end,
		getDown = function(self) return "UNDERGROUND_LADDER_DOWN" end,
	} end },
	-- Crystals
	{ name="crystal", rarity=4, gen=function() return {
		load_grids = {"/data/general/grids/underground.lua"},
		getDoor = function(self) return "CRYSTAL_FLOOR" end,
		getFloor = function(self) return "CRYSTAL_FLOOR" end,
		getWall = function(self) return {"CRYSTAL_WALL","CRYSTAL_WALL2","CRYSTAL_WALL3","CRYSTAL_WALL4","CRYSTAL_WALL5","CRYSTAL_WALL6","CRYSTAL_WALL7","CRYSTAL_WALL8","CRYSTAL_WALL9","CRYSTAL_WALL10","CRYSTAL_WALL11","CRYSTAL_WALL12","CRYSTAL_WALL13","CRYSTAL_WALL14","CRYSTAL_WALL15","CRYSTAL_WALL16","CRYSTAL_WALL17","CRYSTAL_WALL18","CRYSTAL_WALL19","CRYSTAL_WALL20",} end,
		getUp = function(self) return "CRYSTAL_LADDER_UP" end,
		getDown = function(self) return "CRYSTAL_LADDER_DOWN" end,
	} end },
	-- Sand
	{ name="sand", rarity=3, gen=function() return {
		load_grids = {"/data/general/grids/sand.lua"},
		getDoor = function(self) return "UNDERGROUND_SAND" end,
		getFloor = function(self) return "UNDERGROUND_SAND" end,
		getWall = function(self) return "SANDWALL" end,
		getUp = function(self) return "SAND_LADDER_UP" end,
		getDown = function(self) return "SAND_LADDER_DOWN" end,
	} end },
	-- Desert
	{ name="desert", rarity=3, gen=function() return {
		load_grids = {"/data/general/grids/sand.lua"},
		getDoor = function(self) return "SAND" end,
		getFloor = function(self) return "SAND" end,
		getWall = function(self) return "PALMTREE" end,
		getUp = function(self) return "SAND_UP"..self.less_dir end,
		getDown = function(self) return "SAND_DOWN"..self.more_dir end,
	} end },
	-- Slime
	{ name="slime", rarity=4, gen=function() return {
		load_grids = {"/data/general/grids/slime.lua"},
		getDoor = function(self) return "SLIME_DOOR" end,
		getFloor = function(self) return "SLIME_FLOOR" end,
		getWall = function(self) return "SLIME_WALL" end,
		getUp = function(self) return "SLIME_UP" end,
		getDown = function(self) return "SLIME_DOWN" end,
	} end },
}

function _M:createRandomZone(zbase)
	zbase = zbase or {}

	------------------------------------------------------------
	-- Select theme
	------------------------------------------------------------
	local themes = {}
	for i, theme in ipairs(random_zone_themes) do for j = 1, 100 / theme.rarity do themes[#themes+1] = theme end end
	local theme = rng.table(themes)
	print("[RANDOM ZONE] Using theme", theme.name)
	local data = theme.gen()

	local grids = {}
	for i, file in ipairs(data.load_grids) do
		mod.class.Grid:loadList(file, nil, grids)
	end

	------------------------------------------------------------
	-- Misc data
	------------------------------------------------------------
	data.depth = zbase.depth or rng.range(2, 4)
	data.min_lev, data.max_lev = zbase.min_lev or game.player.level, zbase.max_lev or game.player.level + 15
	data.w, data.h = zbase.w or rng.range(40, 60), zbase.h or rng.range(40, 60)
	data.max_material_level = util.bound(math.ceil(data.min_lev / 10), 1, 5)
	data.min_material_level = data.max_material_level - 1

	data.less_dir = rng.table{2, 4, 6, 8}
	data.more_dir = ({[2]=8, [8]=2, [4]=6, [6]=4})[data.less_dir]

	-- Give a random tint
	data.tint_s = {1, 1, 1, 1}
	if rng.percent(10) then
		local sr, sg, sb
		sr = rng.float(0.3, 1)
		sg = rng.float(0.3, 1)
		sb = rng.float(0.3, 1)
		local max = math.max(sr, sg, sb)
		data.tint_s[1] = sr / max
		data.tint_s[2] = sg / max
		data.tint_s[3] = sb / max
	end
	data.tint_o = {data.tint_s[1] * 0.6, data.tint_s[2] * 0.6, data.tint_s[3] * 0.6, 0.6}

	------------------------------------------------------------
	-- Select layout
	------------------------------------------------------------
	local layouts = {}
	for i, layout in ipairs(random_zone_layouts) do for j = 1, 100 / layout.rarity do layouts[#layouts+1] = layout end end
	local layout = rng.table(layouts)
	print("[RANDOM ZONE] Using layout", layout.name)

	------------------------------------------------------------
	-- Select Music
	------------------------------------------------------------
	local musics = {}
	for i, file in ipairs(fs.list("/data/music/")) do
		if file:find("%.ogg$") then musics[#musics+1] = file end
	end

	------------------------------------------------------------
	-- Create a boss
	------------------------------------------------------------
	local npcs = mod.class.NPC:loadList("/data/general/npcs/random_zone.lua")
	local list = {}
	for _, e in ipairs(npcs) do
		if e.rarity and e.level_range and e.level_range[1] <= data.min_lev and (not e.level_range[2] or e.level_range[2] >= data.min_lev) and e.rank > 1 and not e.unique then
			list[#list+1] = e
		end
	end
	local base = rng.table(list)
	local boss, boss_id = self:createRandomBoss(base, {level=data.min_lev + data.depth + rng.range(2, 4)})
	npcs[boss_id] = boss

	------------------------------------------------------------
	-- Entities
	------------------------------------------------------------
	local base_nb = math.sqrt(data.w * data.h)
	local nb_npc = { math.ceil(base_nb * 0.4), math.ceil(base_nb * 0.6) }
	local nb_trap = { math.ceil(base_nb * 0.1), math.ceil(base_nb * 0.2) }
	local nb_object = { math.ceil(base_nb * 0.06), math.ceil(base_nb * 0.12) }
	if rng.percent(20) then nb_trap = {0,0} end
	if rng.percent(10) then nb_object = {0,0} end

	------------------------------------------------------------
	-- Name
	------------------------------------------------------------
	local ngd = NameGenerator.new(randart_name_rules.default2)
	local name = ngd:generate()
	local short_name = name:lower():gsub("[^a-z]", "_")

	------------------------------------------------------------
	-- Final glue
	------------------------------------------------------------
	local zone = mod.class.Zone.new(short_name, {
		name = name,
		level_range = {data.min_lev, data.max_lev},
		level_scheme = "player",
		max_level = data.depth,
		actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() + level.level-1 + rng.range(-1,2) end,
		width = data.w, height = data.h,
		color_shown = data.tint_s,
		color_obscure = data.tint_o,
		ambient_music = rng.table(musics),
		min_material_level = data.min_material_level,
		max_material_level = data.max_material_level,
		no_random_lore = true,
		persistent = "zone_temporary",
		reload_lists = false,
		generator =  {
			map = layout.gen(data),
			actor = { class = "mod.class.generator.actor.Random", nb_npc = nb_npc, guardian = boss_id, abord_no_guardian=true, guardian_alert=layout.guardian_alert },
			trap = { class = "engine.generator.trap.Random", nb_trap = nb_trap, },
			object = { class = "engine.generator.object.Random", nb_object = nb_object, },
		},
		levels = { [1] = { generator = { map = { up = data:getFloor() } } } },
		basic_floor = util.getval(data:getFloor()),
		npc_list = npcs,
		grid_list = grids,
		object_list = mod.class.Object:loadList("/data/general/objects/objects.lua"),
		trap_list = mod.class.Trap:loadList("/data/general/traps/alarm.lua"),
	})
	return zone, boss
end

--- Add character classes to an actor updating stats, talents, and equipment
--	@param b = actor(boss) to update
--	@param data = optional parameters:
--	@param data.force_classes = specific classes to apply first {Corruptor = true, Bulwark = true, ...} ignores restrictions
--		forced classes are applied first, ignoring restrictions
--	@param data.nb_classes = random classes to add (in addition to any forced classes) <2>
-- 	@param data.class_filter = function(cdata, b) that must return true for any class picked.
--		(cdata, b = subclass definition in engine.Birther.birth_descriptor_def.subclass, boss (before classes are applied))
--	@param data.no_class_restrictions set true to skip class compatibility checks <nil>
--	@param data.add_trees = {["talent tree name 1"]=true, ["talent tree name 2"]=true, ..} additional talent trees to learn
--	@param data.check_talents_level set true to enforce talent level restrictions <nil>
--	@param data.auto_sustain set true to activate sustained talents at birth <nil>
--	@param data.forbid_equip set true for no equipment <nil>
--	@param data.loot_quality = drop table to use <"boss">
--	@param data.drop_equipment set true to force dropping of equipment <nil>
--	@param instant set true to force instant learning of talents and generating golem <nil>
function _M:applyRandomClass(b, data, instant)
	if not data.level then data.level = b.level end

	------------------------------------------------------------
	-- Apply talents from classes
	------------------------------------------------------------
	-- Apply a class
	local Birther = require "engine.Birther"
	b.learn_tids = {}
	local function apply_class(class)
		local mclasses = Birther.birth_descriptor_def.class
		local mclass = nil
		for name, data in pairs(mclasses) do
			if data.descriptor_choices and data.descriptor_choices.subclass and data.descriptor_choices.subclass[class.name] then mclass = data break end
		end
		if not mclass then return end

		print("Adding to random boss class", class.name, mclass.name)
		-- add class to list and build inherent power sources
		b.descriptor = b.descriptor or {}
		b.descriptor.classes = b.descriptor.classes or {}
		table.append(b.descriptor.classes, {class.name})
		
		-- build inherent power sources and forbidden power sources
		-- b.forbid_power_source --> b.not_power_source used for classes
		b.power_source = table.merge(b.power_source or {}, class.power_source or {})
		b.not_power_source = table.merge(b.not_power_source or {}, class.not_power_source or {})
		-- update power source parameters with the new class
		b.not_power_source, b.power_source = self:updatePowers(self:attrPowers(b, b.not_power_source), b.power_source)
print("   power types: not_power_source =", table.concat(table.keys(b.not_power_source),","), "power_source =", table.concat(table.keys(b.power_source),","))

		-- Add stats
		if b.auto_stats then
			b.stats = b.stats or {}
			for stat, v in pairs(class.stats or {}) do
				b.stats[stat] = (b.stats[stat] or 10) + v
				for i = 1, v do b.auto_stats[#b.auto_stats+1] = b.stats_def[stat].id end
			end
		end

		-- Add talent categories
		for tt, d in pairs(mclass.talents_types or {}) do b:learnTalentType(tt, true) b:setTalentTypeMastery(tt, (b:getTalentTypeMastery(tt) or 1) + d[2]) end
		for tt, d in pairs(mclass.unlockable_talents_types or {}) do b:learnTalentType(tt, true) b:setTalentTypeMastery(tt, (b:getTalentTypeMastery(tt) or 1) + d[2]) end
		for tt, d in pairs(class.talents_types or {}) do b:learnTalentType(tt, true) b:setTalentTypeMastery(tt, (b:getTalentTypeMastery(tt) or 1) + d[2]) end
		for tt, d in pairs(class.unlockable_talents_types or {}) do b:learnTalentType(tt, true) b:setTalentTypeMastery(tt, (b:getTalentTypeMastery(tt) or 1) + d[2]) end

		-- Add starting equipment
		local apply_resolvers = function(k, resolver)
			if type(resolver) == "table" and resolver.__resolver then
				if resolver.__resolver == "equip" and not data.forbid_equip then
					resolver[1].id = nil
					-- Make sure we equip some nifty stuff instead of player's starting iron stuff
					for i, d in ipairs(resolver[1]) do
						d.name = nil
						d.ego_chance = nil
						d.forbid_power_source=b.not_power_source
						d.tome_drops = data.loot_quality or "boss"
						d.force_drop = (data.drop_equipment == nil) and true or data.drop_equipment
					end
					b[#b+1] = resolver
				elseif resolver.__resolver == "inscription" then -- add support for inscriptions
					b[#b+1] = resolver
				end
			elseif k == "innate_alchemy_golem" then 
				b.innate_alchemy_golem = true
			elseif k == "birth_create_alchemist_golem" then
				b.birth_create_alchemist_golem = resolver
				if instant then b:check("birth_create_alchemist_golem") end
			elseif k == "soul" then
				b.soul = util.bound(1 + math.ceil(data.level / 10), 1, 10) -- Does this need to scale?
			end
		end
		for k, resolver in pairs(mclass.copy or {}) do apply_resolvers(k, resolver) end
		for k, resolver in pairs(class.copy or {}) do apply_resolvers(k, resolver) end

		-- Starting talents are autoleveling
		local tres = nil
		for k, resolver in pairs(b) do if type(resolver) == "table" and resolver.__resolver and resolver.__resolver == "talents" then tres = resolver break end end
		if not tres then tres = resolvers.talents{} b[#b+1] = tres end
		for tid, v in pairs(class.talents or {}) do
			local t = b:getTalentFromId(tid)
			if not t.no_npc_use and (not t.random_boss_rarity or rng.chance(t.random_boss_rarity)) then
				local max = (t.points == 1) and 1 or math.ceil(t.points * 1.2)
				local step = max / 50
				tres[1][tid] = v + math.ceil(step * data.level)
			end
		end

		-- Select additional talents from the class
		local list = {}
		for _, t in pairs(b.talents_def) do
			if (b.talents_types[t.type[1]] or (data.add_trees and data.add_trees[t.type[1]])) and not t.no_npc_use and not t.not_on_random_boss then
				local ok = true
				if data.check_talents_level and rawget(t, 'require') then
					local req = t.require
					if type(req) == "function" then req = req(b, t) end
					if req and req.level and util.getval(req.level, 1) > math.ceil(data.level/2) then
						print("Random boss forbade talent because of level", t.name, data.level)
						ok = false
					end
				end
				if ok then list[t.id] = true end
			end
		end

		local nb = 4 + 0.38*data.level^.75 -- = 11 at level 50
		nb = math.max(rng.range(math.floor(nb * 0.7), math.ceil(nb * 1.3)), 1)
		print("Adding "..nb.." random class talents to boss")

		for i = 1, nb do
			local tid = rng.tableIndex(list, b.learn_tids)
			local t = b:getTalentFromId(tid)
			if t then
				print(" * talent", tid)
				local max = (t.points == 1) and 1 or math.ceil(t.points * 1.2)
				local step = max / 50
				local lev = math.ceil(step * data.level)
				if instant then
					if b:getTalentLevelRaw(tid) < lev then b:learnTalent(tid, true, lev - b:getTalentLevelRaw(tid)) end
					if t.mode == "sustained" and data.auto_sustain then b:forceUseTalent(tid, {ignore_energy=true}) end
				else
					b.learn_tids[tid] = lev
				end
			end
		end
		return true
	end

	-- Select classes
	local classes = Birther.birth_descriptor_def.subclass
	local list = {}
	local force_classes = data.force_classes and table.clone(data.force_classes)
	for name, cdata in ipairs(classes) do
		if force_classes and force_classes[cdata.name] then apply_class(table.clone(cdata, true)) force_classes[cdata.name] = nil
		elseif not cdata.not_on_random_boss and (not cdata.random_rarity or rng.chance(cdata.random_rarity)) and (not data.class_filter or data.class_filter(cdata, b)) then list[#list+1] = cdata
		end
	end
	local to_apply = data.nb_classes or 2
	while to_apply > 0 do
		local c = rng.tableRemove(list)
		if not c then break end --repeat attempts until list is exhausted
		if data.no_class_restrictions or self:checkPowers(b, c) then  -- recheck power restricts here to account for any previously picked classes
			if apply_class(table.clone(c, true)) then to_apply = to_apply - 1 end
		else
			print("  class", c.name, " rejected due to power source")
		end
	end
end

--- Creates a random Boss (or elite) actor
--	@param base = base actor to add classes/talents to
--	calls _M:applyRandomClass(b, data, instant) to add classes, talents, and equipment based on class descriptors
--		handles data.nb_classes, data.force_classes, data.class_filter, ...
--	optional parameters:
--	@param data.init = function(data, b) to run before generation
--	@param data.level = minimum level range for actor generation <1>
--	@param data.rank = rank <3.5-4>
--	@param data.life_rating = function(b.life_rating) <1.7 * base.life_rating + 4-9>
--	@param data.resources_boost = multiplier for maximum resource pool sizes <3>
--	@param data.talent_cds_factor = multiplier for all talent cooldowns <1>
--	@param data.ai = ai_type <"tactical" if rank>3 or base.ai>
--	@param data.ai_tactic = tactical weights table for the tactical ai <nil - generated based on talents>
--	@param data.no_loot_randart set true to not drop a randart <nil>
--	@param data.on_die set true to run base.rng_boss_on_die and base.rng_boss_on_die_custom on death <nil>
--	@param data.name_scheme <randart_name_rules.default>
--	@param data.post = function(b, data) to run last to finish generation
function _M:createRandomBoss(base, data)
	local b = base:clone()
	data = data or {level=1}
	if data.init then data.init(data, b) end
	data.nb_classes = data.nb_classes or 2

	------------------------------------------------------------
	-- Basic stuff, name, rank, ...
	------------------------------------------------------------
	local ngd, name
	if base.random_name_def then
		ngd = NameGenerator2.new("/data/languages/names/"..base.random_name_def:gsub("#sex#", base.female and "female" or "male")..".txt")
		name = ngd:generate(nil, base.random_name_min_syllables, base.random_name_max_syllables)
	else
		ngd = NameGenerator.new(randart_name_rules.default)
		name = ngd:generate()
	end
	if data.name_scheme then
		b.name = data.name_scheme:gsub("#rng#", name):gsub("#base#", b.name)
	else
		b.name = name.." the "..b.name
	end
	print("Creating random boss ", b.name, data.level, "level", data.nb_classes, "classes")
	if data.force_classes then print("  * forcing classes:",table.concat(table.keys(data.force_classes),",")) end
	b.unique = b.name
	b.randboss = true
	local boss_id = "RND_BOSS_"..b.name:upper():gsub("[^A-Z]", "_")
	b.define_as = boss_id
	b.color = colors.VIOLET
	b.rank = data.rank or (rng.percent(30) and 4 or 3.5)
	b.level_range[1] = data.level
	b.fixed_rating = true
	if data.life_rating then
		b.life_rating = data.life_rating(b.life_rating)
	else
		b.life_rating = b.life_rating * 1.7 + rng.range(4, 9)
	end
	b.max_life = b.max_life or 150
	b.max_inscriptions = 5

	if b.can_multiply or b.clone_on_hit then
		b.clone_base = base:clone()
		b.clone_base:resolve()
		b.clone_base:resolve(nil, true)
	end

	-- Force resolving some stuff
	if type(b.max_life) == "table" and b.max_life.__resolver then b.max_life = resolvers.calc[b.max_life.__resolver](b.max_life, b, b, b, "max_life", {}) end

	-- All bosses have all body parts .. yes snake bosses can use archery and so on ..
	-- This is to prevent them from having unusable talents
	b.inven = {}
	b.body = { INVEN = 1000, QS_MAINHAND = 1, QS_OFFHAND = 1, MAINHAND = 1, OFFHAND = 1, FINGER = 2, NECK = 1, LITE = 1, BODY = 1, HEAD = 1, CLOAK = 1, HANDS = 1, BELT = 1, FEET = 1, TOOL = 1, QUIVER = 1, QS_QUIVER = 1 }
	b:initBody()

	b:resolve()
	-- Start with sustains sustained
	b[#b+1] = resolvers.sustains_at_birth()

	-- Leveling stats
	b.autolevel = "random_boss"
	b.auto_stats = {}

	-- Remove default equipment, if any
	local todel = {}
	for k, resolver in pairs(b) do if type(resolver) == "table" and resolver.__resolver and (resolver.__resolver == "equip" or resolver.__resolver == "drops") then todel[#todel+1] = k end end
	for _, k in ipairs(todel) do b[k] = nil end

	-- Boss worthy drops
	b[#b+1] = resolvers.drops{chance=100, nb=data.loot_quantity or 3, {tome_drops=data.loot_quality or "boss"} }
	if not data.no_loot_randart then b[#b+1] = resolvers.drop_randart{} end

	-- On die
	if data.on_die then
		b.rng_boss_on_die = b.on_die
		b.rng_boss_on_die_custom = data.on_die
		b.on_die = function(self, src)
			self:check("rng_boss_on_die_custom", src)
			self:check("rng_boss_on_die", src)
		end
	end

	------------------------------------------------------------
	-- Apply talents from classes
	------------------------------------------------------------
	self:applyRandomClass(b, data)

	b.rnd_boss_on_added_to_level = b.on_added_to_level
	b._rndboss_resources_boost = data.resources_boost or 3
	b._rndboss_talent_cds = data.talent_cds_factor
	b.on_added_to_level = function(self, ...)
		self:check("birth_create_alchemist_golem")
		for tid, lev in pairs(self.learn_tids) do
			if self:getTalentLevelRaw(tid) < lev then
				self:learnTalent(tid, true, lev - self:getTalentLevelRaw(tid))
			end
		end
		self:check("rnd_boss_on_added_to_level", ...)
		self.rnd_boss_on_added_to_level = nil
		self.learn_tids = nil
		self.on_added_to_level = nil

		-- Increase talent cds
		if self._rndboss_talent_cds then
			local fact = self._rndboss_talent_cds
			for tid, _ in pairs(self.talents) do
				local t = self:getTalentFromId(tid)
				if t.mode ~= "passive" then
					local bcd = self:getTalentCooldown(t) or 0
					self.talent_cd_reduction[tid] = (self.talent_cd_reduction[tid] or 0) - math.ceil(bcd * (fact - 1))
				end
			end
		end

		-- Enhance resource pools (cheat a bit with recovery)
		for res, res_def in ipairs(self.resources_def) do
			if res_def.randomboss_enhanced then
				local capacity
				if self[res_def.minname] and self[res_def.maxname] then -- expand capacity
					capacity = (self[res_def.maxname] - self[res_def.minname]) * self._rndboss_resources_boost
				end
				if res_def.invert_values then
					if capacity then self[res_def.minname] = self[res_def.maxname] - capacity end
					self[res_def.regen_prop] = self[res_def.regen_prop] - (res_def.min and res_def.max and (res_def.max-res_def.min)*.01 or 1) * self._rndboss_resources_boost
				else
					if capacity then self[res_def.maxname] = self[res_def.minname] + capacity end
					self[res_def.regen_prop] = self[res_def.regen_prop] + (res_def.min and res_def.max and (res_def.max-res_def.min)*.01 or 1) * self._rndboss_resources_boost
				end
			end
		end
		self:resetToFull()
	end

	-- Update AI
	if data.ai then b.ai = data.ai
	else b.ai = (b.rank > 3) and "tactical" or b.ai
	end
	b.ai_state = { talent_in=1, ai_move=data.ai_move or "move_astar" }
	if data.ai_tactic then
		b.ai_tactic = data.ai_tactic
	else
		b[#b+1] = resolvers.talented_ai_tactic() --calculate ai_tactic table based on talents
	end

	-- Anything else
	if data.post then data.post(b, data) end

	return b, boss_id
end

function _M:debugRandomZone()
	local zone = self:createRandomZone()
	game:changeLevel(zone.max_level, zone)

	game.level.map:liteAll(0, 0, game.level.map.w, game.level.map.h)
	game.level.map:rememberAll(0, 0, game.level.map.w, game.level.map.h)
	for i = 0, game.level.map.w - 1 do
		for j = 0, game.level.map.h - 1 do
			local trap = game.level.map(i, j, game.level.map.TRAP)
			if trap then
				trap:setKnown(game.player, true)
				game.level.map:updateMap(i, j)
			end
		end
	end
end

function _M:locationRevealAround(x, y)
	game.level.map.lites(x, y, true)
	game.level.map.remembers(x, y, true)
	for _, c in pairs(util.adjacentCoords(x, y)) do
		game.level.map.lites(x+c[1], y+c[2], true)
		game.level.map.remembers(x+c[1], y+c[2], true)
	end
end

function _M:doneEvent(id)
	return self.used_events[id]
end

function _M:canEventGrid(level, x, y)
	return game.player:canMove(x, y) and not level.map.attrs(x, y, "no_teleport") and not level.map:checkAllEntities(x, y, "change_level") and not level.map:checkAllEntities(x, y, "special")
end

function _M:canEventGridRadius(level, x, y, radius, min)
	local list = {}
	for i = -radius, radius do for j = -radius, radius do
		if game.state:canEventGrid(level, x+i, y+j) then list[#list+1] = {x=x+i, y=y+j, bx=x, by=y} end
	end end

	if #list < min then return false
	else list.center_x, list.center_y = x, y return list end
end

function _M:findEventGrid(level, checker)
	local x, y = rng.range(1, level.map.w - 2), rng.range(1, level.map.h - 2)
	local tries = 0
	local can = checker or self.canEventGrid
	while not can(self, level, x, y) and tries < 100 do
		x, y = rng.range(1, level.map.w - 2), rng.range(1, level.map.h - 2)
		tries = tries + 1
	end
	if tries >= 100 then return false end
	return x, y
end

function _M:findEventGridRadius(level, radius, min)
	local x, y = rng.range(3, level.map.w - 4), rng.range(3, level.map.h - 4)
	local tries = 0
	while not self:canEventGridRadius(level, x, y, radius, min) and tries < 100 do
		x, y = rng.range(3, level.map.w - 4), rng.range(3, level.map.h - 4)
		tries = tries + 1
	end
	if tries >= 100 then return false end
	return self:canEventGridRadius(level, x, y, radius, min)
end

function _M:eventBaseName(sub, name)
	local base = "/data"
	local _, _, addon, rname = name:find("^([^+]+)%+(.+)$")
	if addon and rname then
		base = "/data-"..addon
		name = rname
	end
	return base.."/general/events/"..sub..name..".lua"
end

function _M:startEvents()
	if not game.zone.events then print("No zone events loaded") return end

	if not game.zone.assigned_events then
		local levels = {}
		if game.zone.events_by_level then
			levels[game.level.level] = {}
		else
			for i = 1, game.zone.max_level do levels[i] = {} end
		end

		-- Generate the events list for this zone, eventually loading from group files
		local evts, mevts = {}, {}
		for i, e in ipairs(game.zone.events) do
			if e.name then if e.minor then mevts[#mevts+1] = e else evts[#evts+1] = e end
			elseif e.group then
				local f, err = loadfile(self:eventBaseName("groups/", e.group))
				if not f then error(err) end
				setfenv(f, setmetatable({level=game.level, zone=game.zone}, {__index=_G}))
				local list = f()
				for j, ee in ipairs(list) do
					if e.percent_factor and ee.percent then ee.percent = math.floor(ee.percent * e.percent_factor) end
					if e.forbid then ee.forbid = table.append(ee.forbid or {}, e.forbid) end
					if ee.name then if ee.minor then mevts[#mevts+1] = ee else evts[#evts+1] = ee end end
				end
			end
		end

		-- Randomize the order they are checked as
		table.shuffle(evts)
		print("[STARTEVENTS] Zone events list:")
		table.print(evts)
		table.shuffle(mevts)
		table.print(mevts)
		for i, e in ipairs(evts) do
			-- If we allow it, try to find a level to host it
			if (e.always or rng.percent(e.percent) or (e.special and e.special() == true)) and (not e.unique or not self:doneEvent(e.name)) then
				local lev = nil
				local forbid = e.forbid or {}
				forbid = table.reverse(forbid)
				if game.zone.events_by_level then
					lev = game.level.level
				else
					if game.zone.events.one_per_level then
						local list = {}
						for i = 1, #levels do if #levels[i] == 0 and not forbid[i] then list[#list+1] = i end end
						if #list > 0 then
							lev = rng.table(list)
						end
					else
						if forbid then
							local t = table.genrange(1, game.zone.max_level, true)
							t = table.minus_keys(t, forbid)
							lev = rng.table(table.keys(t))
						else
							lev = rng.range(1, game.zone.max_level)
						end
					end
				end

				if lev then
					lev = levels[lev]
					lev[#lev+1] = e.name
				end
			end
		end
		for i, e in ipairs(mevts) do
			local forbid = e.forbid or {}
			forbid = table.reverse(forbid)

			local start, stop = 1, game.zone.max_level
			if game.zone.events_by_level then start, stop = game.level.level, game.level.level end
			for lev = start, stop do
				if rng.percent(e.percent) and not forbid[lev] then
					local lev = levels[lev]
					lev[#lev+1] = e.name

					if e.max_repeat then
						local nb = 1
						local p = e.percent
						while nb <= e.max_repeat do
							if rng.percent(p) then
								lev[#lev+1] = e.name
								nb = nb + 1
							else
								break
							end
							p = p / 2
						end
					end
				end
			end
		end

		game.zone.assigned_events = levels
	end

	return function()
		print("[STARTEVENTS] Assigned events list:")
		table.print(game.zone.assigned_events)

		for i, e in ipairs(game.zone.assigned_events[game.level.level] or {}) do
			local f, err = loadfile(self:eventBaseName("", e))
			if not f then error(err) end
			setfenv(f, setmetatable({level=game.level, zone=game.zone, event_id=e.name, Map=Map}, {__index=_G}))
			f()
		end
		game.zone.assigned_events[game.level.level] = {}
		if game.zone.events_by_level then game.zone.assigned_events = nil end
	end
end

function _M:alternateZone(short_name, ...)
	if not world:hasSeenZone(short_name) and not config.settings.cheat and not world:hasAchievement("VAMPIRE_CRUSHER") then print("Alternate layout for "..short_name.." refused: never visited") return "DEFAULT" end

	local list = {...}
	table.insert(list, 1, {"DEFAULT", 1})

	print("[ZONE] Alternate layout computing for")
	table.print(list)

	local probs = {}
	for _, kind in ipairs(list) do
		local p = math.ceil(100 / kind[2])
		for i = 1, p do probs[#probs+1] = kind[1] end
	end

	return rng.table(probs)
end

function _M:alternateZoneTier1(short_name, ...)
	if not game.state:tier1Killed(1) and not config.settings.cheat then return "DEFAULT" end
	return self:alternateZone(short_name, ...)
end

function _M:grabOnlineEventZone()
	if not config.settings.tome.allow_online_events then return end
	if self.birth.grab_online_event_forbid then return end
	if not self.birth.grab_online_event_zone or not self.birth.grab_online_event_spot then return nil end
	return self.birth.grab_online_event_zone()
end

function _M:grabOnlineEventSpot(zone, level)
	if not config.settings.tome.allow_online_events then return end
	if self.birth.grab_online_event_forbid then return end
	if not self.birth.grab_online_event_zone or not self.birth.grab_online_event_spot then return nil end
	return self.birth.grab_online_event_spot(zone, level)
end

function _M:allowOnlineEvent()
	if not config.settings.tome.allow_online_events then return end
	if self.birth.grab_online_event_forbid then return end
	return true
end
