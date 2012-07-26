-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011, 2012 Nicolas Casalini
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

-- Edge TODO: Sounds, Particles

newTalent{
	name = "Sunder Mind",
	type = {"psionic/psychic-assault", 1},
	require = psi_wil_req1,
	points = 5,
	cooldown = 2,
	psi = 5,
	tactical = { ATTACK = { MIND = 2}, DISABLE = 1},
	range = 10,
	requires_target = true,
	getDamage = function(self, t) return self:combatTalentMindDamage(t, 10, 150) end,
	target = function(self, t)
		return {type="hit", range=self:getTalentRange(t), talent=t}
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return end
		
		local dam =self:mindCrit(t.getDamage(self, t))
		self:project(tg, x, y, DamageType.MIND, {dam=dam, alwaysHit=true})
		target:setEffect(target.EFF_SUNDER_MIND, 2, {power=dam/10})
			
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local power = t.getDamage(self, t) / 10
		return ([[Cripples the target's mind, inflicting %0.2f mind damage and reducing it's mental save by %d.  This attack always hits and the mental save reduction stacks.
		The damage and save reduction will scale with your mindpower.]]):
		format(damDesc(self, DamageType.MIND, (damage)), power)
	end,
}

newTalent{
	name = "Mind Sear",
	type = {"psionic/psychic-assault", 2},
	require = psi_wil_req2,
	points = 5,
	cooldown = 2,
	psi = 5,
	range = 7,
	direct_hit = true,
	requires_target = true,
	target = function(self, t)
		return {type="beam", range=self:getTalentRange(t), talent=t}
	end,
	tactical = { ATTACKAREA = { MIND = 3 } },
	getDamage = function(self, t) return self:combatTalentMindDamage(t, 10, 340) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.MIND, self:mindCrit(t.getDamage(self, t)), {type="mind"})
		game:playSoundNear(self, "talents/spell_generic")
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[Sends a telepathic attack, trying to destroy the brains of any target in the beam, doing %0.2f mind damage.
		The damage will increase with your mindpower.]]):format(damDesc(self, DamageType.MIND, damage))
	end,
}

newTalent{
	name = "Psychic Lobotomy",
	type = {"psionic/psychic-assault", 3},
	require = psi_wil_req3,
	points = 5,
	cooldown = 6,
	range = 10,
	psi = 10,
	direct_hit = true,
	requires_target = true,
	tactical = { ATTACK = { MIND = 2 }, DISABLE = { confusion = 2 } },
	getDamage = function(self, t) return self:combatTalentMindDamage(t, 20, 200) end,
	getPower = function(self, t) return self:combatTalentMindDamage(t, 20, 60) end,
	getDuration = function(self, t) return math.floor(self:getTalentLevel(t)) end,
	no_npc = true,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		if not x or not y then return nil end
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return nil end
		local ai = target.ai or nil		
		
		if target:canBe("confused") then
			target:setEffect(target.EFF_LOBOTOMIZED, t.getDuration(self, t), {src=self, dam=t.getDamage(self, t), power=t.getPower(self, t), apply_power=self:combatMindpower()})
		else
			game.logSeen(target, "%s resists the lobotomy!", target.name:capitalize())
		end

		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local cunning_damage = t.getPower(self, t)/2
		local power = t.getPower(self, t)
		local duration = t.getDuration(self, t)
		return ([[Inflicts %0.2f mind damage and cripples the target's higher mental functions, reducing cunning by %d and confusing (%d%% power) the target for %d turns.
		The damage, cunning penalty, and confusion power will scale with your mindpower.]]):
		format(damDesc(self, DamageType.MIND, (damage)), cunning_damage, power, duration)
	end,
}

newTalent{
	name = "Synaptic Static",
	type = {"psionic/psychic-assault", 4},
	require = psi_wil_req4,
	points = 5,
	cooldown = 10,
	psi = 25,
	range = 0,
	direct_hit = true,
	requires_target = true,
	radius = function(self, t) return math.min(10, 3 + math.ceil(self:getTalentLevel(t))) end,
	target = function(self, t) return {type="ball", radius=self:getTalentRadius(t), range=self:getTalentRange(t), talent=t, selffire=false} end,
	tactical = { ATTACKAREA = { MIND = 3 }, DISABLE=1 },
	getDamage = function(self, t) return self:combatTalentMindDamage(t, 20, 200) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		self:project(tg, self.x, self.y, DamageType.MIND, {dam=self:mindCrit(self:combatTalentMindDamage(t, 20, 200)), crossTierChance=100}, {type="mind"})
		game:playSoundNear(self, "talents/spell_generic")
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local radius = self:getTalentRadius(t)
		return ([[Sends out a blast of telepathic static in a %d radius, inflicting %0.2f mind damage.  This attack can brain-lock affected targets.
		The damage will increase with your mindpower.]]):format(radius, damDesc(self, DamageType.MIND, damage))
	end,
}