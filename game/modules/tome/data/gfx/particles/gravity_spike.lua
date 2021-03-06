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

--------------------------------------------------------------------------------------
-- Advanced shaders
--------------------------------------------------------------------------------------
if core.shader.allow("distort") and allow then
use_shader = {type="distort"} alterscreen = true
base_size = 64
local nb = 0

local size=2*radius*64
local sizev=-radius*8
local life=16
local rotation=22

return {
	system_rotation = 0, system_rotationv = rotation or 0, 
	generator = function()
	return {
		trail = 0,
		life = life or 32,
		size = size or 64, sizev = sizev or 0, sizea = 0,

		x = 0, xv = 0, xa = 0,
		y = 0, yv = 0, ya = 0,
		dir = 0, dirv = dirv, dira = 0,
		vel = 0, velv = 0, vela = 0,

		r = 1, rv = 0, ra = 0,
		g = 1, gv = 0, ga = 0,
		b = 1, bv = 0, ba = 0,
		a = 1, av = 0, aa = 0,
	}
end, },
function(self)
	if nb < 1 then self.ps:emit(1) nb = nb + 1 end
end,
1, "particles_images/distort_wave2"


--------------------------------------------------------------------------------------
-- Default
--------------------------------------------------------------------------------------
else
local nb = 0
return { generator = function()
	local radius = radius
	local sradius = (radius + 0.5) * (engine.Map.tile_w + engine.Map.tile_h) / 2
	local ad = rng.float(0, 360)
	local a = math.rad(ad)
	local r = rng.float(sradius - 5, sradius)
	local x = r * math.cos(a)
	local y = r * math.sin(a)
	local bx = math.floor(x / engine.Map.tile_w)
	local by = math.floor(y / engine.Map.tile_h)
	local static = rng.percent(40)

	return {
		trail = 1,
		life = 24,
		size = 3, sizev = static and 0.05 or 0.15, sizea = 0,

		x = x, xv = 0, xa = 0,
		y = y, yv = 0, ya = 0,
		dir = static and a + math.rad(90 - rng.range(10, 20)) or a, dirv = 0, dira = 0,
		vel = static and -2 or 0.5 * (-1-nb) * radius / 2.7, velv = 0, vela = static and -0.01 or rng.float(-0.3, -0.2) * 0.3,

		r = rng.range(200, 230)/255,   rv = 0, ra = 0,
		g = rng.range(130, 160)/255,   gv = 0.005, ga = 0.0005,
		b = rng.range(50, 70)/255,      bv = 0, ba = 0,
		a = rng.range(255, 255)/255,    av = static and -0.034 or 0, aa = 0.005,
	}
end, },
function(self)
	if nb < 5 then
		self.ps:emit(radius*266)
		nb = nb + 1
		self.ps:emit(radius*266)
		nb = nb + 1
		self.ps:emit(radius*266)
		nb = nb + 1
		self.ps:emit(radius*266)
		nb = nb + 1
		self.ps:emit(radius*266)
		nb = nb + 1
	end
end,
5*radius*266
end
