-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2015 Nicolas Casalini
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

-- EDGE TODO: Particles, Timed Effect Particles

newTalent{
	name = "Thread Walk",
	type = {"chronomancy/threaded-combat", 1},
	require = chrono_req_high1,
	points = 5,
	cooldown = 10,
	paradox = function (self, t) return getParadoxCost(self, t, 10) end,
	tactical = { ATTACK = {weapon = 2}, CLOSEIN = 2, ESCAPE = 2 },
	requires_target = true,
	is_teleport = true,
	range = function(self, t)
		if self:hasArcheryWeapon("bow") then return util.getval(archery_range, self, t) end
		return 1
	end,
	is_melee = function(self, t) return not self:hasArcheryWeapon("bow") end,
	speed = function(self, t) return self:hasArcheryWeapon("bow") and "archery" or "weapon" end,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1, 1.5) end,
	getDefense = function(self, t) return self:combatTalentStatDamage(t, "mag", 10, 50) end,
	getResist = function(self, t) return self:combatTalentStatDamage(t, "mag", 10, 25) end,
	getReduction = function(self, t) return self:combatTalentStatDamage(t, "mag", 10, 25) end,
	on_pre_use = function(self, t, silent) if self:attr("disarmed") then if not silent then game.logPlayer(self, "You require a weapon to use this talent.") end return false end return true end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "defense_on_teleport", t.getDefense(self, t))
		self:talentTemporaryValue(p, "resist_all_on_teleport", t.getResist(self, t))
		self:talentTemporaryValue(p, "effect_reduction_on_teleport", t.getReduction(self, t))
	end,
	callbackOnStatChange = function(self, t, stat, v)
		if stat == self.STAT_MAG then
			self:updateTalentPassives(t)
		end
	end,
	
	archery_onhit = function(self, t, target, x, y)
		game:onTickEnd(function()
			game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
			game:playSoundNear(self, "talents/teleport")
			
			if self:teleportRandom(x, y, 0) then
				game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
			else
				game.logSeen(self, "The spell fizzles!")
			end
		end)
	end,
	action = function(self, t)
		local mainhand, offhand = self:hasDualWeapon()

		if self:hasArcheryWeapon("bow") then
			-- Ranged attack
			local targets = self:archeryAcquireTargets({type="bolt"}, {one_shot=true, no_energy = true})
			if not targets then return end
			self:archeryShoot(targets, t, {type="bolt"}, {mult=t.getDamage(self, t)})
		elseif mainhand then
			-- Melee attack
			local tg = {type="hit", range=self:getTalentRange(t), talent=t}
			local _, x, y = self:canProject(tg, self:getTarget(tg))
			local target = game.level.map(x, y, game.level.map.ACTOR)
			if not target then return nil end
			
			local hitted = self:attackTarget(target, nil, t.getDamage(self, t), true)
				
			if hitted then
				-- Find our teleport location
				local dist = 10 / core.fov.distance(x, y, self.x, self.y)
				local destx, desty = math.floor((self.x - x) * dist + x), math.floor((self.y - y) * dist + y)
				local l = core.fov.line(x, y, destx, desty, false)
				local lx, ly, is_corner_blocked = l:step()
				local ox, oy
				
				while game.level.map:isBound(lx, ly) and not game.level.map:checkEntity(lx, ly, Map.TERRAIN, "block_move") and not is_corner_blocked do
					if not game.level.map(lx, ly, Map.ACTOR) then ox, oy = lx, ly end
					lx, ly, is_corner_blocked = l:step()
				end
				
				game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
				game:playSoundNear(self, "talents/teleport")
				
				-- ox, oy now contain the last square in line not blocked by actors.
				if ox and oy then 
					self:teleportRandom(ox, oy, 0)
					game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
				end

			end

		else
			game.logPlayer(self, "You cannot use Thread Walk without an appropriate weapon!")
			return nil
		end
		
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t) * 100
		local defense = t.getDefense(self, t)
		local resist = t.getResist(self, t)
		local reduction = t.getReduction(self, t)
		return ([[Attack with your bow or dual-weapons for %d%% damage.  If you shoot an arrow you'll teleport near any target hit.  If you hit with either of your dual-weapons you'll teleport up to ten tiles away from the target.
		Additionally you now go Out of Phase for five turns after any teleport, gaining %d defense, %d%% resist all, and reducing the duration of new detrimental effects by %d%%.
		The Out of Phase bonuses will scale with your Magic stat.]])
		:format(damage, defense, resist, reduction)
	end
}

newTalent{
	name = "Blended Threads",
	type = {"chronomancy/threaded-combat", 2},
	require = chrono_req_high2,
	mode = "passive",
	points = 5,
	getPercent = function(self, t) return self:combatTalentScale(t, 10, 50)/100 end,
	info = function(self, t)
		local percent = t.getPercent(self, t) * 100
		return ([[Your Bow Threading and Blade Threading attacks now deal %d%% more weapon damage if you did not have the appropriate weapon equipped when you initiated the attack.]])
		:format(percent)
	end
}

newTalent{
	name = "Thread the Needle",
	type = {"chronomancy/threaded-combat", 3},
	require = chrono_req_high3,
	points = 5,
	cooldown = 8,
	fixed_cooldown = true,
	paradox = function (self, t) return getParadoxCost(self, t, 18) end,
	tactical = { ATTACKAREA = { weapon = 3 } , DISABLE = 3 },
	requires_target = true,
	range = function(self, t)
		if self:hasArcheryWeapon("bow") then return util.getval(archery_range, self, t) end
		return 0
	end,
	is_melee = function(self, t) return not self:hasArcheryWeapon("bow") end,
	speed = function(self, t) return self:hasArcheryWeapon("bow") and "archery" or "weapon" end,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1.2, 1.9) end,
	getCooldown = function(self, t) return self:getTalentLevel(t) >= 5 and 2 or 1 end,
	on_pre_use = function(self, t, silent) if self:attr("disarmed") then if not silent then game.logPlayer(self, "You require a weapon to use this talent.") end return false end return true end,
	target = function(self, t)
		local tg = {type="beam", range=self:getTalentRange(t)}
		if not self:hasArcheryWeapon("bow") then
			tg = {type="ball", radius=1, range=self:getTalentRange(t)}
		end
		return tg
	end,
	archery_onhit = function(self, t, target, x, y)
		-- Refresh blade talents
		for tid, cd in pairs(self.talents_cd) do
			local tt = self:getTalentFromId(tid)
			if tt.type[1]:find("^chronomancy/blade") then
				self:alterTalentCoolingdown(tt, - t.getCooldown(self, t))
			end
		end
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local damage = t.getDamage(self, t)
		local mainhand, offhand = self:hasDualWeapon()

		if self:hasArcheryWeapon("bow") then
			-- Ranged attack
			local targets = self:archeryAcquireTargets(tg, {one_shot=true, no_energy = true})
			if not targets then return end
			self:archeryShoot(targets, t, tg, {mult=dam})
		elseif mainhand then
			-- Melee attack
			self:project(tg, self.x, self.y, function(px, py, tg, self)
				local target = game.level.map(px, py, Map.ACTOR)
				if target and target ~= self then
					local hit = self:attackTarget(target, nil, dam, true)
					-- Refresh bow talents
					if hit then
						for tid, cd in pairs(self.talents_cd) do
							local tt = self:getTalentFromId(tid)
							if tt.type[1]:find("^chronomancy/bow") then
								self:alterTalentCoolingdown(tt, - t.getCooldown(self, t))
							end
						end
					end
				end
			end)
			self:addParticles(Particles.new("meleestorm2", 1, {}))
		else
			game.logPlayer(self, "You cannot use Thread the Needle without an appropriate weapon!")
			return nil
		end

		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t) * 100
		local cooldown = t.getCooldown(self, t)
		return ([[Attack with your bow or dual-weapons for %d%% damage.
		If you use your bow you'll shoot a beam and each target hit will reduce the cooldown of one Blade Threading spell currently on cooldown by %d.
		If you use your dual-weapons you'll attack all targets within a radius of one around you and each target hit will reduce the cooldown of one Bow Threading spell currently on cooldown by %d.
		At talent level five cooldowns are reduced by two.]])
		:format(damage, cooldown, cooldown)
	end
}

newTalent{
	name = "Warden's Call", short_name = WARDEN_S_CALL,
	type = {"chronomancy/threaded-combat", 4},
	require = chrono_req_high4,
	mode = "passive",
	points = 5,
	remove_on_clone = true,
	getDamagePenalty = function(self, t) return 100 - self:combatTalentLimit(t, 80, 10, 60) end,
	doBladeWarden = function(self, t, target)
		if self.turn_procs.wardens_call then
			return
		else
			self.turn_procs.wardens_call = true
		end
		
		-- Make our clone
		local m = makeParadoxClone(self, self, 2)
		m.energy.value = 1000
		m.generic_damage_penalty = (m.generic_damage_penalty or 0) + t.getDamagePenalty(self, t)
		doWardenWeaponSwap(m, t, nil, "blade")
		m.on_act = function(self)
			if not self.blended_target.dead then
				self:forceUseTalent(self.T_ATTACK, {ignore_cd=true, ignore_energy=true, force_target=self.blended_target, ignore_ressources=true, silent=true})
			end
			self:useEnergy()
			game:onTickEnd(function()self:die()end)
			game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
		end
		
		-- Check Focus first
		local wf = checkWardenFocus(self)
		if wf and not wf.dead then
			local tx, ty = util.findFreeGrid(wf.x, wf.y, 1, true, {[Map.ACTOR]=true})
			if tx and ty then
				game.zone:addEntity(game.level, m, "actor", tx, ty)
				m.blended_target = wf
			end
		end
		if not m.blended_target then
			local tgts= t.findTarget(self, t)
			local attempts = 10
			while #tgts > 0 and attempts > 0 do
				local a, id = rng.tableRemove(tgts)
				-- look for space
				local tx, ty = util.findFreeGrid(a.x, a.y, 1, true, {[Map.ACTOR]=true})
				if tx and ty and not a.dead then			
					game.zone:addEntity(game.level, m, "actor", tx, ty)
					m.blended_target = a
					break
				else
					attempts = attempts - 1
				end
			end
		end
	end,
	doBowWarden = function(self, t, target)
		if self.turn_procs.wardens_call then
			return
		else
			self.turn_procs.wardens_call = true
		end

		-- Make our clone
		local m = makeParadoxClone(self, self, 2)
		m.energy.value = 1000
		m.generic_damage_penalty = (m.generic_damage_penalty or 0) + t.getDamagePenalty(self, t)
		m:attr("archery_pass_friendly", 1)
		doWardenWeaponSwap(m, t, nil, "bow")
		m.on_act = function(self)
			if not self.blended_target.dead then
				local targets = self:archeryAcquireTargets(nil, {one_shot=true, x=self.blended_target.x, y=self.blended_target.y, no_energy = true})
				if targets then
					self:forceUseTalent(self.T_SHOOT, {ignore_cd=true, ignore_energy=true, force_target=self.blended_target, ignore_ressources=true, silent=true})
				end
			end
			self:useEnergy()
			game:onTickEnd(function()self:die()end)
			game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
		end
		
		-- Find a good location for our shot
		local function find_space(self, target, clone)
			local poss = {}
			local range = util.getval(archery_range, clone, t)
			local x, y = target.x, target.y
			for i = x - range, x + range do
				for j = y - range, y + range do
					if game.level.map:isBound(i, j) and
						core.fov.distance(x, y, i, j) <= range and -- make sure they're within arrow range
						core.fov.distance(i, j, self.x, self.y) <= range/2 and -- try to place them close to the caster so enemies dodge less
						self:canMove(i, j) and target:hasLOS(i, j) then
						poss[#poss+1] = {i,j}
					end
				end
			end
			if #poss == 0 then return end
			local pos = poss[rng.range(1, #poss)]
			x, y = pos[1], pos[2]
			return x, y
		end
		
		-- Check Focus first
		local wf = checkWardenFocus(self)
		if wf and not wf.dead then
			local tx, ty = find_space(self, target, m)
			if tx and ty then
				game.zone:addEntity(game.level, m, "actor", tx, ty)
				m.blended_target = wf
			end
		else
			local tgts = t.findTarget(self, t)
			if #tgts > 0 then
				local a, id = rng.tableRemove(tgts)
				local tx, ty = find_space(self, target, m)
				game.zone:addEntity(game.level, m, "actor", tx, ty)
				m.blended_target = a
			end
		end
	end,
	findTarget = function(self, t)
		local tgts = {}
		local grids = core.fov.circle_grids(self.x, self.y, 10, true)
		for x, yy in pairs(grids) do for y, _ in pairs(grids[x]) do
			local target_type = Map.ACTOR
			local a = game.level.map(x, y, Map.ACTOR)
			if a and self:reactionToward(a) < 0 and self:hasLOS(a.x, a.y) then
				tgts[#tgts+1] = a
			end
		end end
		
		return tgts
	end,
	info = function(self, t)
		local damage_penalty = t.getDamagePenalty(self, t)
		return ([[When you hit with a blade-threading or a bow-threading talent a warden may appear, depending on available space, from another timeline and shoot or attack a random enemy.
		The wardens are out of phase with this reality and deal %d%% less damage but the bow warden's arrows will pass through friendly targets.
		This effect can only occur once per turn and the wardens return to their own timeline after attacking.]])
		:format(damage_penalty)
	end
}
