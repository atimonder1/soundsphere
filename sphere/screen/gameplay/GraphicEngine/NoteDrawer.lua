local CoordinateManager	= require("aqua.graphics.CoordinateManager")
local Container			= require("aqua.graphics.Container")
local Image				= require("aqua.graphics.Image")
local Rectangle			= require("aqua.graphics.Rectangle")
local SpriteBatch		= require("aqua.graphics.SpriteBatch")
local map				= require("aqua.math").map
local sign				= require("aqua.math").sign
local Class				= require("aqua.util.Class")
local Config			= require("sphere.config.Config")
local tween				= require("tween")

local NoteDrawer = Class:new()

NoteDrawer.speed = 1
NoteDrawer.targetSpeed = 1
NoteDrawer.rate = 1

NoteDrawer.construct = function(self)
	self.allcs = CoordinateManager:getCS(0, 0, 0, 0, "all")
	
	self.cses = {}
	for i = 1, #self.NoteDrawerData.cses do
		local ics = self.NoteDrawerData.cses[i]
		self.cses[i] = CoordinateManager:getCS(
			tonumber(ics[1]),
			tonumber(ics[2]),
			tonumber(ics[3]),
			tonumber(ics[4]),
			ics[5]
		)
	end
	
	self.data = self.NoteDrawerData.notes or {}
	
	self.images = {}
	self:loadImages()
	
	self.containers = {}
	self:loadContainers()
end

local newImage = love.graphics.newImage
NoteDrawer.loadImage = function(self, imageData)
	self.images[imageData.name] = newImage(self.directoryPath .. "/" .. imageData.path)
end

NoteDrawer.loadImages = function(self)
	if not self.NoteDrawerData.images then
		return
	end
	
	for _, imageData in pairs(self.NoteDrawerData.images) do
		self:loadImage(imageData)
	end
end

local sortContainers = function(a, b)
	return a.layer < b.layer
end
NoteDrawer.loadContainers = function(self)
	self.containerList = {}
	
	if not self.NoteDrawerData.images then
		return
	end
	
	for _, imageData in pairs(self.NoteDrawerData.images) do
		local container = SpriteBatch:new(nil, self.images[imageData.name], 1000)
		container.layer = imageData.layer
		self.containers[imageData.name] = container
		table.insert(self.containerList, container)
	end
	table.sort(self.containerList, sortContainers)
	
	self.rectangleContainer = Container:new()
	table.insert(self.containerList, 1, self.rectangleContainer)
end

NoteDrawer.update = function(self, dt)
	if self.speedTween and self.updateTween then
		self.speedTween:update(dt)
	end
	
	for _, container in ipairs(self.containerList) do
		container:update()
	end
end

NoteDrawer.draw = function(self)
	for _, container in ipairs(self.containerList) do
		container:draw()
	end
end

NoteDrawer.setSpeed = function(self, speed)
	if speed * self.speed < 0 then
		self.speed = speed
		self.updateTween = false
	else
		self.updateTween = true
		self.speedTween = tween.new(0.25, self, {speed = speed}, "inOutQuad")
	end
	Config.data.speed = speed
end

NoteDrawer.getSpeed = function(self)
	return self.speed / self.rate
end

NoteDrawer.getCS = function(self, note)
	return self.cses[self.data[note.id]["Head"].cs]
end

NoteDrawer.checkNote = function(self, note)
	if self.data[note.id] then
		return true
	end
end

NoteDrawer.getNoteLayer = function(self, note, part)
	return
		self.data[note.id][part].layer
		+ map(
			note.startNoteData.timePoint.absoluteTime,
			note.startNoteData.timePoint.firstTimePoint.absoluteTime,
			note.startNoteData.timePoint.lastTimePoint.absoluteTime,
			0,
			1
		)
end

NoteDrawer.getNoteImage = function(self, note, part)
	return self.images[self.data[note.id][part].image]
end

NoteDrawer.getRectangleDrawable = function(self, note, part)
	return Rectangle:new({
		cs = self:getCS(note),
		mode = "fill",
		x = 0,
		y = 0,
		w = self:getLineNoteScaledWidth(note),
		h = self:getLineNoteScaledHeight(note),
		lineStyle = "rough",
		lineWidth = 1,
		layer = self:getNoteLayer(note, part),
		color = self.color.clear
	})
end

NoteDrawer.getImageDrawable = function(self, note, part)
	return Image:new({
		cs = self:getCS(note),
		x = 0,
		y = 0,
		sx = self:getNoteScaleX(note, part),
		sy = self:getNoteScaleY(note, part),
		image = self:getNoteImage(note, part),
		layer = self:getNoteLayer(note, part),
		color = self.color.clear
	})
end

NoteDrawer.getImageContainer = function(self, note, part)
	return self.containers[self.data[note.id][part].image]
end

NoteDrawer.getRectangleContainer = function(self, note, part)
	return self.rectangleContainer
end

NoteDrawer.getG = function(self, order, dt, note, part, name)
	local dt = dt * self:getSpeed()
	local seq = self.data[note.id][part].gc[name]
	if not seq then print(order, dt, note, part, name) end
	local sum = 0
	for i = order, #seq - 1 do
		local delta = seq[i + 1] * dt ^ (i - order)
		sum = sum + delta
	end
	return sum
end

NoteDrawer.whereWillBelongSegment = function(self, note, part, name, value)
	local seq = self.data[note.id][part].sb[name]

	if not seq then
		return 0
	end
	
	local a, b = seq[1], seq[2]
	if a < b then
		if value < a then
			return -1
		elseif value > b then
			return 1
		else
			return 0
		end
	elseif b < a then
		if value < b then
			return -1
		elseif value > a then
			return 1
		else
			return 0
		end
	end

	return 0
end

return NoteDrawer
