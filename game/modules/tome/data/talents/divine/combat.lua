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
	name = "Weapon of Light",
	type = {"divine/combat", 1},
	mode = "sustained",
	require = divi_req1,
	points = 5,
	cooldown = 10,
	sustain_positive = 10,
	tactical = {
		BUFF = 10,
	},
	range = 20,
	activate = function(self, t)
		game:playSoundNear(self, "talents/spell_generic2")
		local ret = {
		}
		return ret
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		return ([[Infuse your weapon of the power of the Sun, doing %0.2f light damage with each hit.
		Each hit will drain 3 positive energy, the spell ends when energy reaches 0.
		The damage will increase with the Magic stat]]):format(7 + self:combatSpellpower(0.092) * self:getTalentLevel(t))
	end,
}

newTalent{
	name = "Martyrdom",
	type = {"divine/combat", 2},
	require = divi_req2,
	points = 5,
	cooldown = 22,
	positive = 25,
	tactical = {
		ATTACK = 10,
	},
	range = 6,
	reflectable = true,
	action = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		game:playSoundNear(self, "talents/spell_generic")
		local target = game.level.map(x, y, Map.ACTOR)
		if target and target:checkHit(self:combatSpellpower(), target:combatMentalResist(), 0, 95, 15)then
			target:setEffect(self.EFF_MARTYRDOM, 10, {power=8 * self:getTalentLevelRaw(t)})
		else
			return
		end
		return true
	end,
	info = function(self, t)
		return ([[Designate a target as martyr. When the martyr deals damage it also damages itself for %d%% of its damage dealt.
		The damage percent will increase with the Magic stat]]):
		format(
			8 * self:getTalentLevelRaw(t)
		)
	end,
}

newTalent{
	name = "Wave of Power",
	type = {"divine/combat",3},
	require = divi_req3,
	points = 5,
	cooldown = 6,
	positive = 10,
	tactical = {
		ATTACK = 10,
	},
	range = function(self, t) return 2 + self:getStr(12) end,
	action = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			self:attackTarget(target, nil, 1.1 + self:getTalentLevel(t) / 7, true)
		else
			return
		end
		return true
	end,
	info = function(self, t)
		return ([[In a pure display of power you project a melee attack up to a range of %d, doing %d%% damage.
		The range will increase with the Strength stat]]):
		format(self:getTalentRange(t), 100 * (1.1 + self:getTalentLevel(t) / 7))
	end,
}

newTalent{
	name = "Crusade",
	type = {"divine/combat", 4},
	require = divi_req4,
	points = 5,
	cooldown = 10,
	positive = 10,
	tactical = {
		ATTACKAREA = 10,
	},
	range = 3,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if math.floor(core.fov.distance(self.x, self.y, x, y)) > 1 then return nil end
		self:attackTarget(target, DamageType.LIGHT, 1.1 + self:getTalentLevel(t) / 7, true)
		return true
	end,
	info = function(self, t)
		return ([[Concentrate the power of the sun in a single blow doing %d%% light damage.]]):
		format(100 * (1.1 + self:getTalentLevel(t) / 7))
	end,
}
