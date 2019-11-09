local CoordinateManager	= require("aqua.graphics.CoordinateManager")
local Rectangle			= require("aqua.graphics.Rectangle")
local ModifierList		= require("sphere.screen.select.ModifierMenu.ModifierList")
local SequenceList		= require("sphere.screen.select.ModifierMenu.SequenceList")

local ModifierMenu = {}

ModifierMenu.hidden = true
ModifierMenu.csall = CoordinateManager:getCS(0, 0, 0, 0, "all")

ModifierMenu.init = function(self)
	self.background = Rectangle:new({
		x = 0,
		y = 0,
		w = 1,
		h = 1,
		color = {0, 0, 0, 191},
		cs = self.csall,
		mode = "fill"
	})
	self.background:reload()
	
	ModifierList:init()
	ModifierList:load()
	
	SequenceList:init()
	SequenceList:load()
end

ModifierMenu.hide = function(self)
	self.hidden = true
end

ModifierMenu.update = function(self)
	ModifierList:update()
	SequenceList:update()
end

ModifierMenu.draw = function(self)
	if not self.hidden then
		self.background:draw()
		ModifierList:draw()
		SequenceList:draw()
	end
end

ModifierMenu.reload = function(self)
	self.background:reload()
	ModifierList:reload()
	SequenceList:reload()
end

ModifierMenu.receive = function(self, event)
	if self.hidden then
		return
	end
	if event.name == "resize" then
		self:reload()
	elseif event.name == "keypressed" and event.args[1] == "escape" then
		self:hide()
	end
	
	ModifierList:receive(event)
	SequenceList:receive(event)
end

ModifierMenu.show = function(self)
	self.hidden = false
	self:reload()
end

return ModifierMenu