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


newTalent{
	name = "Juggernaut",
	type = {"technique/superiority", 1},
	require = techs_req_high1,
	points = 5,
	random_ego = "attack",
	cooldown = 40,
	stamina = 60,
	action = function(self, t)
		self:setEffect(self.EFF_EARTHEN_BARRIER, 20, {power=self:getTalentLevelRaw(t) * 5})
		return true
	end,
	info = function(self, t)
		return ([[Concentrate on the battle, ignoring some of the damage you take.
		Improves physical damage reduction by %d%%.]]):format(self:getTalentLevelRaw(t) * 5)
	end,
}

newTalent{
	name = "Onslaught",
	type = {"technique/superiority", 2},
	require = techs_req_high2,
	points = 5,
	mode = "sustained",
	cooldown = 60,
	sustain_stamina = 80,
	activate = function(self, t)
		return {
			onslaught = self:addTemporaryValue("onslaught", math.floor(self:getTalentLevel(t))),
			stamina = self:addTemporaryValue("stamina_regen", -15),
		}
	end,

	deactivate = function(self, t, p)
		self:removeTemporaryValue("onslaught", p.onslaught)
		self:removeTemporaryValue("stamina_regen", p.stamina)
		return true
	end,
	info = function(self, t)
		return ([[Take an offensive stance, as you walk through your foes you knock them all back in an frontal arc (up to %d grids).
		This consumes stamina rapidly.]]):
		format(self:getTalentLevel(t))
	end,
}

newTalent{
	name = "Battle Call",
	type = {"technique/superiority", 3},
	require = techs_req_high3,
	points = 5,
	random_ego = "attack",
	cooldown = 10,
	stamina = 30,
	action = function(self, t)
		local tg = {type="ball", range=0, friendlyfire=true, radius=2 + self:getTalentLevel(t), talent=t}
		self:project(tg, self.x, self.y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end
			local tx, ty = util.findFreeGrid(self.x, self.y, 5, true, {[Map.ACTOR]=true})
			if tx and ty and taget:canBe("teleport") then
				target:move(tx, ty, true)
				game.logSeen(target, "%s is called to battle!", target.name:capitalize())
			end
		end)
		return true
	end,
	info = function(self, t)	
		return ([[Call all foes in a radius of %d around you into battle, getting them into melee range in an instant.]]):format(2+self:getTalentLevel(t))
	end,
}

newTalent{
	name = "Shattering Impact",
	type = {"technique/superiority", 4},
	require = techs_req_high4,
	points = 5,
	mode = "sustained",
	cooldown = 30,
	sustain_stamina = 40,
	activate = function(self, t)
		return {
			dam = self:addTemporaryValue("shattering_impact", self:combatTalentWeaponDamage(t, 0.2, 0.6)),
		}
	end,

	deactivate = function(self, t, p)
		self:removeTemporaryValue("shattering_impact", p.dam)
		return true
	end,
	info = function(self, t)
		return ([[Put all your strength into your weapon blows, creating shattering impact that deal %d%% weapon damage to all nearby foes.
		The impact damage will also affect you.
		Each blow will drain 15 stamina.]]):
		format(100 * self:combatTalentWeaponDamage(t, 0.1, 0.45))
	end,
}
