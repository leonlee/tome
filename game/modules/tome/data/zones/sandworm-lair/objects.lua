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

load("/data/general/objects/objects.lua")

-- Artifact, dropped by the sandworm queen
newEntity{
	power_source = {nature=true},
	define_as = "SANDQUEEN_HEART",
	type = "corpse", subtype = "heart",
	name = "Heart of the Sandworm Queen", unique=true, unided_name="pulsing organ",
	display = "*", color=colors.VIOLET,
	desc = [[The heart of the Sandworm Queen, ripped from her dead body. You could ... consume it, should you feel mad enough.]],
	cost = 3000,

	use_simple = { name="consume the heart", use = function(self, who)
		game.logPlayer(who, "#00FFFF#You consume the heart and feel the knowledge of this very old creature fills you!")
		who.unused_stats = who.unused_stats + 3
		who.unused_talents = who.unused_talents + 1
		who.unused_generics = who.unused_generics + 1
		game.logPlayer(who, "You have %d stat point(s) to spend. Press G to use them.", who.unused_stats)
		game.logPlayer(who, "You have %d class talent point(s) to spend. Press G to use them.", who.unused_talents)
		game.logPlayer(who, "You have %d generic talent point(s) to spend. Press G to use them.", who.unused_generics)

		if who:knowTalentType("wild-gift/sand-drake") then
			who:setTalentTypeMastery("wild-gift/sand-drake", who:getTalentTypeMastery("wild-gift/sand-drake") + 0.1)
		else
			who:learnTalentType("wild-gift/sand-drake", false)
		end
		game.logPlayer(who, "You are transformed by the heart of the Queen!.")
		game.logPlayer(who, "#00FF00#You gain an affinity for sand. You can now learn new sand talents (press G).")

		game:setAllowedBuild("wilder_wyrmic", true)

		return "destroy", true
	end}
}

newEntity{
	power_source = {nature=true},
	define_as = "PUTRESCENT_POTION",
	type = "corpse", subtype = "blood",
	name = "Wyrm Bile", unique=true, unided_name="putrescent potion",
	display = "*", color=colors.VIOLET,
	desc = [[A vial of thick, lumpy fluid. Who knows what this will do to you if you drink it?]],
	cost = 3000,

	use_simple = { name="drink the vile blood", use = function(self, who)
		game.logPlayer(who, "#00FFFF#You drink the wyrm bile and feel forever transformed!")
		who.unused_talents_types = who.unused_talents_types + 1
		game.log("You have %d category point(s) to spend. Press G to use them.", who.unused_talents_types)

		local str, dex, con, mag, wil, cun = rng.range(-3, 6), rng.range(-3, 6), rng.range(-3, 6), rng.range(-3, 6), rng.range(-3, 6), rng.range(-3, 6)
		who:incStat("str", str) if str >= 0 then str="+"..str end
		who:incStat("dex", dex) if dex >= 0 then dex="+"..dex end
		who:incStat("mag", mag) if mag >= 0 then mag="+"..mag end
		who:incStat("wil", wil) if wil >= 0 then wil="+"..wil end
		who:incStat("cun", cun) if cun >= 0 then cun="+"..cun end
		who:incStat("con", con) if con >= 0 then con="+"..con end
		game.logPlayer(who, "#00FF00#Your stats have changed! (Str %s, Dex %s, Mag %s, Wil %s, Cun %s, Con %s)", str, dex, mag, wil, cun, con)

		return "destroy", true
	end}
}
