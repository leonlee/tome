-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
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

local Stats = require "engine.interface.ActorStats"

newTalent{
	name = "Slash",
	type = {"cursed/slaughter", 1},
	require = cursed_str_req1,
	points = 5,
	random_ego = "attack",
	cooldown = 8,
	hate = 0.2,
	tactical = { ATTACK = 2 },
	requires_target = true,
	getDamageMultiplier = function(self, t, hate)
		return 1 + self:combatTalentIntervalDamage(t, "str", 0.3, 1.5, 0.4) * getHateMultiplier(self, 0.3, 1, true, hate)
	end,
	getPoisonDamage = function(self, t)
		local level
		if self:hasCursedWeapon() then
			level = math.max(1, self:getTalentLevel(t) - 2)
		else
			level = math.max(1, self:getTalentLevel(t) - 3)
		end
		return self:rescaleDamage(math.sqrt(level) * 40 * ((100 + self:getStat("str")) / 200))
	end,
	getPoisonHealFactor = function(self, t, hate)
		return 50
	end,
	getPoisonDuration = function(self, t)
		local level
		if self:hasCursedWeapon() then
			level = math.max(1, self:getTalentLevel(t) - 2)
		else
			level = math.max(1, self:getTalentLevel(t) - 3)
		end
		return math.floor(10 * level)
	end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		
		local damageMultiplier = t.getDamageMultiplier(self, t)
		local hit = self:attackTarget(target, nil, damageMultiplier, true)
		
		local level = self:getTalentLevel(t)
		if hit and target:canBe("poison") and level >= 4 or (self:hasCursedWeapon() and level >= 3) then
			local poisonDamage = t.getPoisonDamage(self, t)
			local poisonHealFactor = t.getPoisonHealFactor(self, t)
			local poisonDuration = t.getPoisonDuration(self, t)
			target:setEffect(target.EFF_INSIDIOUS_POISON, poisonDuration, {src=self, power=poisonDamage / poisonDuration, heal_factor=poisonHealFactor})
		end

		return true
	end,
	info = function(self, t)
		local level = self:getTalentLevel(t)
		if level >= 4 or (self:hasCursedWeapon() and level >= 3) then
			local poisonDamage = t.getPoisonDamage(self, t)
			local poisonHealFactor = t.getPoisonHealFactor(self, t)
			local poisonDuration = t.getPoisonDuration(self, t)
			return ([[Slashes wildly at your target for %d%% (at 0 Hate) to %d%% (at 10+ Hate) damage.
			Your main weapon inflicts an insidious poison born of your curse causing %d damage and %d%% reduced healing over %d turns.
			Hate-based effects will improve when wielding cursed weapons (+2.5 hate). The insidious poison improves with a cursed main weapon.]]):format(t.getDamageMultiplier(self, t, 0) * 100, t.getDamageMultiplier(self, t, 10) * 100, poisonDamage, poisonHealFactor, poisonDuration)
		else
			return ([[Slashes wildly at your target for %d%% (at 0 Hate) to %d%% (at 10+ Hate) damage.
			At level 4 (3 when weilding a cursed main weapon) your curse begins to inflict an insidious poison.
			Hate-based effects will improve when wielding cursed weapons (+2.5 hate). The insidious poison improves with a cursed main weapon.]]):format(t.getDamageMultiplier(self, t, 0) * 100, t.getDamageMultiplier(self, t, 10) * 100)
		end
	end,
}

newTalent{
	name = "Frenzy",
	type = {"cursed/slaughter", 2},
	require = cursed_str_req2,
	points = 5,
	tactical = { ATTACKAREA = 2 },
	random_ego = "attack",
	cooldown = 12,
	hate = 0.2,
	getDamageMultiplier = function(self, t, hate)
		return self:combatTalentIntervalDamage(t, "str", 0.25, 0.8, 0.4) * getHateMultiplier(self, 0.5, 1, true, hate)
	end,
	getAttackChange = function(self, t)
		local level
		if self:hasCursedWeapon() then
			level = math.max(1, self:getTalentLevel(t) - 2)
		else
			level = math.max(1, self:getTalentLevel(t) - 3)
		end
		return -self:rescaleDamage((math.sqrt(level) - 0.5) * 15 * ((100 + self:getStat("str")) / 200))
	end,
	action = function(self, t)
		local targets = {}
		for i = -1, 1 do
			for j = -1, 1 do
				local x, y = self.x + i, self.y + j
				if (self.x ~= x or self.y ~= y) and game.level.map:isBound(x, y) and game.level.map(x, y, Map.ACTOR) then
					local target = game.level.map(x, y, Map.ACTOR)
					if target and self:reactionToward(target) < 0 then
						targets[#targets+1] = target
					end
				end
			end
		end
		
		if #targets <= 0 then return nil end

		local damageMultiplier = t.getDamageMultiplier(self, t)
		local attackChange = t.getAttackChange(self, t)
		
		local effStalker = self:hasEffect(self.EFF_STALKER)
		for i = 1, 4 do
			local target
			if effStalker and not effStalker.target.dead then
				target = effStalker.target
			else
				target = rng.table(targets)
			end

			if self:attackTarget(target, nil, damageMultiplier, true) and not target:hasEffect(target.EFF_OVERWHELMED) then
				target:setEffect(target.EFF_OVERWHELMED, 3, {src=self, attackChange=attackChange})
			end
		end

		return true
	end,
	info = function(self, t)
		local level = self:getTalentLevel(t)
		if level >= 4 or (self:hasCursedWeapon() and level >= 3) then
			local attackChange = t.getAttackChange(self, t)
			return ([[Assault nearby foes with 4 fast attacks for %d%% (at 0 Hate) to %d%% (at 10+ Hate) damage each. Stalked prey are always targeted if nearby.
			The intensity of your assault overwhelms anyone who is struck, reducing their attack by %d for 3 turns.
			Hate-based effects will improve when wielding cursed weapons (+2.5 hate). Attack reduction increases with a cursed main weapon and the Strength stat.]]):format(t.getDamageMultiplier(self, t, 0) * 100, t.getDamageMultiplier(self, t, 10) * 100, -attackChange)
		else
			return ([[Assault nearby foes with 4 fast attacks for %d%% (at 0 Hate) to %d%% (at 10+ Hate) damage each. Stalked prey are always targeted if nearby.
			At level 4 (3 when weilding a cursed main weapon) the intensity of your assault overwhelms anyone who is struck, reducing their attack for 3 turns.
			Hate-based effects will improve when wielding cursed weapons (+2.5 hate).]]):format(t.getDamageMultiplier(self, t, 0) * 100, t.getDamageMultiplier(self, t, 10) * 100)
		end
	end,
}

newTalent{
	name = "Reckless Charge",
	type = {"cursed/slaughter", 3},
	require = cursed_str_req3,
	points = 5,
	random_ego = "attack",
	cooldown = 20,
	hate = 0.8,
	range = 4,
	tactical = { CLOSEIN = 2 },
	requires_target = true,
	getDamageMultiplier = function(self, t, hate)
		return self:combatTalentIntervalDamage(t, "str", 0.8, 1.7, 0.4) * getHateMultiplier(self, 0.5, 1, true, hate)
	end,
	action = function(self, t)
		local targeting = {type="bolt", range=self:getTalentRange(t), nolock=true}
		local targetX, targetY, actualTarget = self:getTarget(targeting)
		if not targetX or not targetY then return nil end
		if core.fov.distance(self.x, self.y, targetX, targetY) > self:getTalentRange(t) then return nil end

		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", target) end
		local lineFunction = core.fov.line(self.x, self.y, targetX, targetY, block_actor)
		local nextX, nextY, is_corner_blocked = lineFunction:step(block_actor)
		local currentX, currentY = self.x, self.y

		while nextX and nextY and not is_corner_blocked do
			local blockingTarget = game.level.map(nextX, nextY, Map.ACTOR)
			if blockingTarget and self:reactionToward(blockingTarget) < 0 then
				-- attempt a knockback
				local level = self:getTalentLevelRaw(t)
				local maxSize = 2
				if level >= 5 then
					maxSize = 4
				elseif level >= 3 then
					maxSize = 3
				end

				local blocked = true
				if blockingTarget.size_category <= maxSize then
					if blockingTarget:checkHit(self:combatAttackStr(), blockingTarget:combatPhysicalResist(), 0, 95, 15) and blockingTarget:canBe("knockback") then
						-- determine where to move the target (any adjacent square that isn't next to the attacker)
						local start = rng.range(0, 8)
						for i = start, start + 8 do
							local x = nextX + (i % 3) - 1
							local y = nextY + math.floor((i % 9) / 3) - 1
							if core.fov.distance(currentY, currentX, x, y) > 1
									and game.level.map:isBound(x, y)
									and not game.level.map:checkAllEntities(x, y, "block_move", self) then
								blockingTarget:move(x, y, true)
								game.logSeen(self, "%s knocks back %s!", self.name:capitalize(), blockingTarget.name)
								blocked = false
								break
							end
						end
					end
				end

				if blocked then
					game.logSeen(self, "%s blocks %s!", blockingTarget.name:capitalize(), self.name)
				end
			end

			-- check that we can move
			if not game.level.map:isBound(nextX, nextY) or game.level.map:checkAllEntities(nextX, nextY, "block_move", self) then break end

			-- allow the move
			currentX, currentY = nextX, nextY
			nextX, nextY, is_corner_blocked = lineFunction:step(block_actor)

			-- attack adjacent targets
			for i = 0, 8 do
				local x = currentX + (i % 3) - 1
				local y = currentY + math.floor((i % 9) / 3) - 1
				local target = game.level.map(x, y, Map.ACTOR)
				if target and self:reactionToward(target) < 0 then
					local damageMultiplier = t.getDamageMultiplier(self, t)
					self:attackTarget(target, nil, damageMultiplier, true)

					game.level.map:particleEmitter(x, y, 1, "blood", {})
					game:playSoundNear(self, "actions/melee")
				end
			end
		end

		self:move(currentX, currentY, true)

		return true
	end,
	info = function(self, t)
		local level = self:getTalentLevelRaw(t)
		local size
		if level >= 5 then
			size = "Big"
		elseif level >= 3 then
			size = "Medium-sized"
		else
			size = "Small"
		end
		return ([[Charge through your opponents, attacking anyone near your path for %d%% (at 0 Hate) to %d%% (at 10+ Hate) damage. %s opponents may be knocked from your path.
		Hate-based effects will improve when wielding cursed weapons (+2.5 hate).]]):format(t.getDamageMultiplier(self, t, 0) * 100, t.getDamageMultiplier(self, t, 10) * 100, size)
	end,
}

--newTalent{
--	name = "Cleave",
--	type = {"cursed/slaughter", 4},
--	mode = "passive",
--	require = cursed_str_req4,
--	points = 5,
--	on_attackTarget = function(self, t, target, multiplier)
--		if inCleave then return end
--		inCleave = true
--
--		local chance = 28 + self:getTalentLevel(t) * 7
--		if rng.percent(chance) then
--			local start = rng.range(0, 8)
--			for i = start, start + 8 do
--				local x = self.x + (i % 3) - 1
--				local y = self.y + math.floor((i % 9) / 3) - 1
--				local secondTarget = game.level.map(x, y, Map.ACTOR)
--				if secondTarget and secondTarget ~= target and self:reactionToward(secondTarget) < 0 then
--					local multiplier = multiplier or 1 * self:combatTalentWeaponDamage(t, 0.2, 0.7) * getHateMultiplier(self, 0.5, 1.0, true)
--					game.logSeen(self, "%s cleaves through another foe!", self.name:capitalize())
--					self:attackTarget(secondTarget, nil, multiplier, true)
--					inCleave = false
--					return
--				end
--			end
--		end
--		inCleave = false
--
--	end,
--	info = function(self, t)
--		local chance = 28 + self:getTalentLevel(t) * 7
--		local multiplier = self:combatTalentWeaponDamage(t, 0.2, 0.7)
--		return ([[Every swing of your weapon has a %d%% chance of striking a second target for %d%% (at 0 Hate) to %d%% (at 10+ Hate) damage.
--		Hate-based effects will improve when wielding cursed weapons (+2.5 hate).]]):format(chance, multiplier * 50, multiplier * 100)
--	end,
--}

newTalent{
	name = "Cleave",
	type = {"cursed/slaughter", 4},
	mode = "sustained",
	require = cursed_str_req4,
	points = 5,
	cooldown = 10,
	no_energy = true,
	getChance = function(self, t)
		local chance = self:combatTalentIntervalDamage(t, "str", 10, 38, 0.4)
		if self:hasTwoHandedWeapon() then
			chance = chance + 15
		end
		return chance
	end,
	getDamageMultiplier = function(self, t, hate)
		local damageMultiplier = self:combatTalentIntervalDamage(t, "str", 0.3, 0.9, 0.4) * getHateMultiplier(self, 0.5, 1.0, true, hate)
		if self:hasTwoHandedWeapon() then
			damageMultiplier = damageMultiplier + 0.25
		end
		return damageMultiplier
	end,
	preUseTalent = function(self, t)
		-- prevent AI's from activating more than 1 talent
		if self ~= game.player and (self:isTalentActive(self.T_SURGE) or self:isTalentActive(self.T_REPEL)) then return false end
		return true
	end,
	activate = function(self, t)
		-- deactivate other talents and place on cooldown
		if self:isTalentActive(self.T_SURGE) then
			self:useTalent(self.T_SURGE)
		elseif self:knowTalent(self.T_SURGE) then
			local tSurge = self:getTalentFromId(self.T_SURGE)
			self.talents_cd[self.T_SURGE] = tSurge.cooldown
		end
			
		if self:isTalentActive(self.T_REPEL) then
			self:useTalent(self.T_REPEL)
		elseif self:knowTalent(self.T_REPEL) then
			local tRepel = self:getTalentFromId(self.T_REPEL)
			self.talents_cd[self.T_REPEL] = tRepel.cooldown
		end
	
		return {
			luckId = self:addTemporaryValue("inc_stats", { [Stats.STAT_LCK] = -3 })
		}
	end,
	deactivate = function(self, t, p)
		if p.luckId then self:removeTemporaryValue("inc_stats", p.luckId) end
		
		return true
	end,
	on_attackTarget = function(self, t, target)
		if inCleave then return end
		inCleave = true

		local chance = t.getChance(self, t)
		if rng.percent(chance) then
			local start = rng.range(0, 8)
			for i = start, start + 8 do
				local x = self.x + (i % 3) - 1
				local y = self.y + math.floor((i % 9) / 3) - 1
				local secondTarget = game.level.map(x, y, Map.ACTOR)
				if secondTarget and secondTarget ~= target and self:reactionToward(secondTarget) < 0 then
					local damageMultiplier = t.getDamageMultiplier(self, t)
					game.logSeen(self, "%s cleaves through %s!", self.name:capitalize(), secondTarget.name)
					self:attackTarget(secondTarget, nil, damageMultiplier, true)
					inCleave = false
					return
				end
			end
		end
		inCleave = false
	end,
	info = function(self, t)
		local chance = t.getChance(self, t)
		return ([[While active every swing of your weapon has a %d%% chance of striking a second nearby target for %d%% (at 0 Hate) to %d%% (at 10+ Hate) damage. The recklessness of your attacks brings you bad luck (luck -3). Cleave, repel and parry cannot be activate simultaneously and activating one will place the others in cooldown.
		Chance and damage increase with with the Strength stat and when wielding a two-handed weapon (+15%% chance, +25%% damage). Hate-based effects will improve when wielding cursed weapons (+2.5 hate).]]):format(chance, t.getDamageMultiplier(self, t, 0) * 100, t.getDamageMultiplier(self, t, 10) * 100)
	end,
}

