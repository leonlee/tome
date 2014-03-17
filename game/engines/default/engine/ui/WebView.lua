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
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"

--- A web browser
module(..., package.seeall, class.inherit(Base, Focusable))

function _M:init(t)
	self.w = assert(t.width, "no webview width")
	self.h = assert(t.height, "no webview height")
	self.url = assert(t.url, "no webview url")
	self.on_title = t.on_title
	self.allow_downloads = t.allow_downloads or {}
	self.has_frame = t.has_frame
	self.never_clean = t.never_clean
	self.allow_popup = t.allow_popup
	self.allow_login = t.allow_login

	if self.allow_login and self.url:find("^http://te4%.org/") and profile.auth then
		local param = "_te4ah="..profile.auth.hash.."&_te4ad="..profile.auth.drupid

		local first = self.url:find("?", 1, 1)
		if first then self.url = self.url.."&"..param
		else self.url = self.url.."?"..param end
	end

	if self.url:find("^http://te4%.org/")  then
		local param = "_te4"

		local first = self.url:find("?", 1, 1)
		if first then self.url = self.url.."&"..param
		else self.url = self.url.."?"..param end
	end

	Base.init(self, t)
end

function _M:generate()
	self.mouse:reset()
	self.key:reset()

	local handlers = {
		on_title = function(view, title) if self.on_title then self.on_title(title) end end,
		on_popup = function(view, url, w, h) if self.allow_popup then
			local Dialog = require "engine.ui.Dialog"
			Dialog:webPopup(url, w, h)
		end end,
	}
	if self.allow_downloads then self:onDownload(handlers) end
	self.view = core.webview.new(self.w, self.h, self.url, handlers)
	self.oldloading = true
	self.scroll_inertia = 0

	if self.has_frame then
		self.frame = Base:makeFrame("ui/tooltip/", self.w + 8, self.h + 8)
	end

	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if not self.view then return end
		if event == "button" then
			if button == "wheelup" then self.scroll_inertia = math.min(self.scroll_inertia, 0) - 5
			elseif button == "wheeldown" then self.scroll_inertia = math.max(self.scroll_inertia, 0) + 5
			elseif button == "left" then self.view:injectMouseButton(false, 1) self.view:injectMouseButton(true, 1)
			elseif button == "middle" then self.view:injectMouseButton(false, 2) self.view:injectMouseButton(true, 2)
			elseif button == "right" then self.view:injectMouseButton(false, 3) self.view:injectMouseButton(true, 3)
			end				
		elseif event == "button-down" then
			if button == "wheelup" then self.scroll_inertia = math.min(self.scroll_inertia, 0) - 5
			elseif button == "wheeldown" then self.scroll_inertia = math.max(self.scroll_inertia, 0) + 5
			elseif button == "left" then self.view:injectMouseButton(false, 1)
			elseif button == "middle" then self.view:injectMouseButton(false, 2)
			elseif button == "right" then self.view:injectMouseButton(false, 3)
			end				
		else
			self.view:injectMouseMove(bx, by)
		end
	end)
	
	function self.key.receiveKey(_, sym, ctrl, shift, alt, meta, unicode, isup, key, keysym)
		if not self.view then return end
		if unicode then
			keysym = unicode:sub(1):byte()
		end
		self.view:injectKey(isup, keysym)
	end
end

function _M:on_focus(v)
	game:onTickEnd(function() self.key:unicodeInput(v) end)
	if self.view then self.view:focus(v) end
end

function _M:makeDownloadbox(downid, file)
	local Dialog = require "engine.ui.Dialog"
	local Waitbar = require "engine.ui.Waitbar"
	local Button = require "engine.ui.Button"

	local d = Dialog.new("Download: "..file, 600, 100)
	local b = Button.new{text="Cancel", fct=function() self.view:downloadAction(downid, false) game:unregisterDialog(d) end}
	local w = Waitbar.new{size=600, text=file}
	d:loadUI{
		{left=0, top=0, ui=w},
		{right=0, bottom=0, ui=b},
	}
	d:setupUI(true, true)
	function d:updateFill(...) w:updateFill(...) end
	return d
end

function _M:on_dialog_cleanup()
	if not self.never_clean then
		self.downloader = nil
		self.view = nil
	end
end

function _M:onDownload(handlers)
	local Dialog = require "engine.ui.Dialog"

	handlers.on_download_request = function(view, downid, url, file, mime)
		if mime == "application/t-engine-addon" and self.allow_downloads.addons and url:find("^http://te4%.org/") then
			local path = fs.getRealPath("/addons/")
			if path then
				Dialog:yesnoPopup("Confirm addon install/update", "Are you sure you want to install this addon? ("..file..")", function(ret)
					if ret then
						print("Accepting addon download to:", path..file)
						self.download_dialog = self:makeDownloadbox(downid, file)
						self.download_dialog.install_kind = "Addon"
						game:registerDialog(self.download_dialog)
						self.view:downloadAction(downid, path..file)
					else
						self.view:downloadAction(downid, false)
					end
				end)
				return
			end
		elseif mime == "application/t-engine-module" and self.allow_downloads.modules and url:find("^http://te4%.org/") then
			local path = fs.getRealPath("/modules/")
			if path then
				Dialog:yesnoPopup("Confirm module install/update", "Are you sure you want to install this module? ("..file..")", function(ret)
					if ret then
						print("Accepting module download to:", path..file)
						self.download_dialog = self:makeDownloadbox(downid, file)
						self.download_dialog.install_kind = "Game Module"
						game:registerDialog(self.download_dialog)
						self.view:downloadAction(downid, path..file)
					else
						self.view:downloadAction(downid, false)
					end
				end)
				return
			end
		end
		self.view:downloadAction(downid, false)
	end

	handlers.on_download_update = function(view, downid, cur_size, total_size, percent, speed)
		if not self.download_dialog then return end
		self.download_dialog:updateFill(cur_size, total_size, ("%d%% - %d KB/s"):format(cur_size * 100 / total_size, speed / 1024))
		if cur_size == total_size then
			game:unregisterDialog(self.download_dialog)
			if self.download_dialog.install_kind == "Addon" then
				Dialog:simplePopup("Addon installed!", "Addon installation successful. New addons are only active for new characters.")
			elseif self.download_dialog.install_kind == "Game Module" then
				Dialog:simplePopup("Game installed!", "Game installation successful. Have fun!")
			end
			self.download_dialog = nil
		end
	end
end

function _M:display(x, y, nb_keyframes, screen_x, screen_y, offset_x, offset_y, local_x, local_y)
	if self.scroll_inertia > 0 then self.scroll_inertia = math.max(self.scroll_inertia - 1, 0)
	elseif self.scroll_inertia < 0 then self.scroll_inertia = math.min(self.scroll_inertia + 1, 0)
	end

	if self.frame then
		self:drawFrame(self.frame, x - 4, y - 4, 0, 0, 0, 0.3, self.w, self.h) -- shadow
		self:drawFrame(self.frame, x - 4, y - 4, 1, 1, 1, 0.75) -- unlocked frame
	end

	if self.view then
		if self.scroll_inertia ~= 0 then self.view:injectMouseWheel(0, self.scroll_inertia) end
		self.view:toScreen(x, y)
	end
end