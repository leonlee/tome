-- TE4 - T-Engine 4
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
local Base = require "engine.ui.Base"

--- A generic waiter bar
-- @classmod engine.ui.WaitBar
module(..., package.seeall, class.inherit(Base))

function _M:init(t)
	self.size = assert(t.size, "no waiter size")
	self.text = assert(t.text, "no waiter text")
	self.fill = t.fill or 0
	self.maxfill = t.maxfill or 100

	Base.init(self, t)
end

function _M:updateFill(v, max, text)
	self.fill = v
	if max then self.maxfill = max end
	if text then
		self.text = text
		local width = self.font_bold:size(text)
		self.text_gen:text(text)
		self.text_gen:translate(self.t_left.w + (self.size - width) / 2)
	end
	self.bar_quad:clear()
	local x2, y2 = v * self.size / self.maxfill, self.t_bar.h
	local u2, v2 = self.tbar.tw, self.tbar.th
	self.bar_quad:quad(
		0, 0, 0, 0,
		x2, 0, u2, 0,
		x2, y2, u2, v2,
		0, y2, 0, v2
	)
end

function _M:generate()
	self.do_container:clear()

	self.t_left = self:getUITexture("ui/waiter/left_basic.png")
	self.t_right = self:getUITexture("ui/waiter/right_basic.png")
	self.t_middle = self:getUITexture("ui/waiter/middle.png")
	self.t_bar = self:getUITexture("ui/waiter/bar.png")
	self.do_contaner:add(core.renderer.fromTextureTable(self.t_left, 0, 0))
	self.do_container:add(core.renderer.fromTextureTable(self.t_right, self.w - self.t_right.w, 0))
	self.do_container:add(core.renderer.texture(self.t_middle.t, self.t_left.w, (self.t_left.h - self.t_middle.h) / 2,
		self.size, self.t_middle.h))
	self.bar_quad = core.renderer.vertexes()
	self.bar_quad:translate(self.t_left.w, (self.t_left.h - self.t_bar.h) / 2)
	self.bar_quad:texture(self.t_bar.t)
	self.text_gen = core.renderer.text(self.font_bold)

	self:updateFill(self.fill, self.maxfill, self.text)

	self.w, self.h = self.size + self.t_left.w + self.t_right.w, self.t_left.h
end

function _M:display(x, y)
end
