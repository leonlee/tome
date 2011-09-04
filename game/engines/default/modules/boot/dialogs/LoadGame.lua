-- TE4 - T-Engine 4
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

require "engine.class"
local Module = require "engine.Module"
local Dialog = require "engine.ui.Dialog"
local TreeList = require "engine.ui.TreeList"
local Button = require "engine.ui.Button"
local Textzone = require "engine.ui.Textzone"
local Separator = require "engine.ui.Separator"
local Savefile = require "engine.Savefile"

module(..., package.seeall, class.inherit(Dialog))

function _M:init()
	Dialog.init(self, "Load Game", game.w * 0.8, game.h * 0.8)

	local list = Module:listSavefiles(function(dir) if dir:find("^boot") then return false else return true end end)

	self.c_play = Button.new{text="  Play!  ", fct=function(text) self:playSave() end}
	self.c_delete = Button.new{text="Delete", fct=function(text) self:deleteSave() end}
	self.c_desc = Textzone.new{width=math.floor(self.iw / 3 * 2 - 10), height=self.ih - self.c_delete.h - 10, text=""}

	self.tree = {}
	local found = false
	for i = #list, 1, -1 do
		local m = list[i]
		if m.is_boot then table.remove(list, i) m.savefiles={} end

		local nodes = {}

		for j, save in ipairs(m.savefiles) do
			local mod_string = ("%s-%d.%d.%d"):format(m.short_name, save.module_version and save.module_version[1] or -1, save.module_version and save.module_version[2] or -1, save.module_version and save.module_version[3] or -1)
			local mod = list[mod_string]
			if mod and save.loadable then
				save.fct = function()
					Module:instanciate(mod, save.name, false)
				end
				save.mod = mod
				save.zone = Textzone.new{
					width=self.c_desc.w,
					height=self.c_desc.h,
					text=("#{bold}##GOLD#%s: %s#WHITE##{normal}#\nGame version: %d.%d.%d\n\n%s"):format(mod.long_name, save.name, mod.version[1], mod.version[2], mod.version[3], save.description)
				}
				if save.screenshot then
					local w, h = save.screenshot:getSize()
					save.screenshot = { save.screenshot:glTexture() }
					save.screenshot.w, save.screenshot.h = w, h
				end
				table.sort(nodes, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
				table.insert(nodes, save)
				found = true
			end
		end

		if #nodes > 0 then
			local mod = m.versions[1]
			table.insert(self.tree, {
				name=tstring{{"font","bold"}, {"color","GOLD"}, mod.name, {"font","normal"}},
				fct=function() end,
				shown=true,
				nodes=nodes,
				zone = Textzone.new{width=self.c_desc.w, height=self.c_desc.h, text="#{bold}##GOLD#"..mod.long_name.."#WHITE##{normal}#\n\n"..mod.description}
			})
		end
	end

	self.c_tree = TreeList.new{width=math.floor(self.iw / 3 - 10), height=self.ih, scrollbar=true, columns={
		{width=100, display_prop="name"},
	}, tree=self.tree,
		fct=function(item, sel, v) end,
		select=function(item, sel) self:select(item) end,
	}

	self:loadUI{
		{left=0, top=0, ui=self.c_tree},
		{right=0, top=0, ui=self.c_desc},
		{right=0, bottom=0, ui=self.c_delete},
		{left=self.c_tree.w + 5, top=5, ui=Separator.new{dir="horizontal", size=self.ih - 10}},
	}
	self:setFocus(self.c_tree)
	self:setupUI()

	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}
end

function _M:select(item)
	if item and self.uis[2] then
		self.uis[2].ui = item.zone
		self.cur_sel = item
	else
		self.cur_sel = nil
	end
end

function _M:innerDisplay(x, y, nb_keyframes)
	if not self.cur_sel or not self.cur_sel.screenshot then return end
	local s = self.cur_sel.screenshot
	local r = s.w / s.h
	local w = math.min(s.w, self.c_desc.w - 20)
	local h = w / r
	h = math.min(h, self.ih / 1.7)
	w = h * r
	s[1]:toScreenFull(x + self.ix + self.iw - self.c_desc.w, y + self.ih - h - 20, w, h, s[2] * w / s.w, s[3] * h / s.h)
end

function _M:deleteSave()
	if not self.cur_sel then return end

	Dialog:yesnoPopup("Delete savefile", "Really delete #{bold}##GOLD#"..self.cur_sel.name.."#WHITE##{normal}#", function(ret)
		if ret then
			local base = Module:setupWrite(self.cur_sel.mod)
			local save = Savefile.new(self.cur_sel.name)
			save:delete()
			save:close()
			fs.umount(base)

			game.save_list = Module:listSavefiles()

			local d = new()
			d.__showup = false
			game:replaceDialog(self, d)
		end
	end, "Delete", "Cancel")
end
