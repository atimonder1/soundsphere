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

local NoteSkin = Class:new()

NoteSkin.color = {
	transparent = {255, 255, 255, 0},
	clear = {255, 255, 255, 255},
	missed = {127, 127, 127, 255},
	passed = {255, 255, 255, 0},
	startMissed = {127, 127, 127, 255},
	startMissedPressed = {191, 191, 191, 255},
	startPassedPressed = {255, 255, 255, 255},
	endPassed = {255, 255, 255, 0},
	endMissed = {127, 127, 127, 255},
	endMissedPassed = {127, 127, 127, 255}
}

NoteSkin.speed = 1
NoteSkin.targetSpeed = 1
NoteSkin.rate = 1

NoteSkin.construct = function(self)
	self.allcs = CoordinateManager:getCS(0, 0, 0, 0, "all")
	
	self.cses = {}
	for i = 1, #self.noteSkinData.cses do
		self.cses[i] = CoordinateManager:getCS(
			tonumber(self.noteSkinData.cses[i][1]),
			tonumber(self.noteSkinData.cses[i][2]),
			tonumber(self.noteSkinData.cses[i][3]),
			tonumber(self.noteSkinData.cses[i][4]),
			self.noteSkinData.cses[i][5]
		)
	end
	
	self.data = self.noteSkinData.notes or {}
	
	self.images = {}
	self:loadImages()
	
	self.containers = {}
	self:loadContainers()
end

local newImage = love.graphics.newImage
NoteSkin.loadImage = function(self, imageData)
	self.images[imageData.name] = newImage(self.directoryPath .. "/" .. imageData.path)
end

NoteSkin.loadImages = function(self)
	if not self.noteSkinData.images then
		return
	end
	
	for _, imageData in pairs(self.noteSkinData.images) do
		self:loadImage(imageData)
	end
end

local sortContainers = function(a, b)
	return a.layer < b.layer
end
NoteSkin.loadContainers = function(self)
	self.containerList = {}
	
	if not self.noteSkinData.images then
		return
	end
	
	for _, imageData in pairs(self.noteSkinData.images) do
		local container = SpriteBatch:new(nil, self.images[imageData.name], 1000)
		container.layer = imageData.layer
		self.containers[imageData.name] = container
		table.insert(self.containerList, container)
	end
	table.sort(self.containerList, sortContainers)
	
	self.rectangleContainer = Container:new()
	table.insert(self.containerList, 1, self.rectangleContainer)
end

NoteSkin.update = function(self, dt)
	if self.speedTween and self.updateTween then
		self.speedTween:update(dt)
	end
	
	for _, container in ipairs(self.containerList) do
		container:update()
	end
end

NoteSkin.draw = function(self)
	for _, container in ipairs(self.containerList) do
		container:draw()
	end
end

NoteSkin.setSpeed = function(self, speed)
	if speed * self.speed < 0 then
		self.speed = speed
		self.updateTween = false
	else
		self.updateTween = true
		self.speedTween = tween.new(0.25, self, {speed = speed}, "inOutQuad")
	end
	Config.data.speed = speed
end

NoteSkin.getSpeed = function(self)
	return self.speed / self.rate
end

NoteSkin.getCS = function(self, note)
	return self.cses[self.data[note.id]["Head"].cs]
end

NoteSkin.checkNote = function(self, note)
	if self.data[note.id] then
		return true
	end
end

NoteSkin.getNoteLayer = function(self, note, part)
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

NoteSkin.getNoteImage = function(self, note, part)
	return self.images[self.data[note.id][part].image]
end

NoteSkin.getRectangleDrawable = function(self, note, part)
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

NoteSkin.getImageDrawable = function(self, note, part)
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

NoteSkin.getImageContainer = function(self, note, part)
	return self.containers[self.data[note.id][part].image]
end

NoteSkin.getRectangleContainer = function(self, note, part)
	return self.rectangleContainer
end

--------------------------------
-- get*X get*Y
--------------------------------

NoteSkin.getG = function(self, order, dt, note, part, name)
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

NoteSkin.getShortNoteX = function(self, note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	return
		  self:getG(0, dt, note, "Head", "x")
		+ self:getG(0, dt, note, "Head", "w")
		* self:getG(0, dt, note, "Head", "ox")
end
NoteSkin.getLongNoteHeadX = function(self, note)
	local dt = note.engine.currentTime - (note:getFakeVisualStartTime() or note.startNoteData.timePoint.currentVisualTime)
	return
		  self:getG(0, dt, note, "Head", "x")
		+ self:getG(0, dt, note, "Head", "w")
		* self:getG(0, dt, note, "Head", "ox")
end
NoteSkin.getLongNoteTailX = function(self, note)
	local dt = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	return
		  self:getG(0, dt, note, "Tail", "x")
		+ self:getG(0, dt, note, "Tail", "w")
		* self:getG(0, dt, note, "Tail", "ox")
end
NoteSkin.getLongNoteBodyX = function(self, note)
	local dg = self:getLongNoteHeadX(note) - self:getLongNoteTailX(note)
	local dt
	if dg * sign(self.speed) >= 0 then
		dt = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	else
		dt = note.engine.currentTime - (note:getFakeVisualStartTime() or note.startNoteData.timePoint.currentVisualTime)
	end
	return
		  self:getG(0, dt, note, "Body", "x")
		+ self:getG(0, dt, note, "Head", "w")
		* self:getG(0, dt, note, "Body", "ox")
end
NoteSkin.getLineNoteX = function(self, note)
	local dt1 = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local dt2 = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	local dg = self:getG(0, dt2, note, "Head", "x") - self:getG(0, dt2, note, "Head", "x")
	local dt
	if dg * sign(self.speed) >= 0 then
		dt = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	else
		dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	end
	return self:getG(0, dt, note, "Head", "x")
end

NoteSkin.getShortNoteY = function(self, note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	return
		  self:getG(0, dt, note, "Head", "y")
		+ self:getG(0, dt, note, "Head", "h")
		* self:getG(0, dt, note, "Head", "oy")
end
NoteSkin.getLongNoteHeadY = function(self, note)
	local dt = note.engine.currentTime - (note:getFakeVisualStartTime() or note.startNoteData.timePoint.currentVisualTime)
	return
		  self:getG(0, dt, note, "Head", "y")
		+ self:getG(0, dt, note, "Head", "h")
		* self:getG(0, dt, note, "Head", "oy")
end
NoteSkin.getLongNoteTailY = function(self, note)
	local dt = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	return
		  self:getG(0, dt, note, "Tail", "y")
		+ self:getG(0, dt, note, "Tail", "h")
		* self:getG(0, dt, note, "Tail", "oy")
end
NoteSkin.getLongNoteBodyY = function(self, note)
	local dg = self:getLongNoteHeadY(note) - self:getLongNoteTailY(note)
	local dt
	if dg * sign(self.speed) >= 0 then
		dt = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	else
		dt = note.engine.currentTime - (note:getFakeVisualStartTime() or note.startNoteData.timePoint.currentVisualTime)
	end
	return
		  self:getG(0, dt, note, "Body", "y")
		+ self:getG(0, dt, note, "Head", "h")
		* self:getG(0, dt, note, "Body", "oy")
end
NoteSkin.getLineNoteY = function(self, note)
	local dt1 = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local dt2 = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	local dg = self:getG(0, dt2, note, "Head", "y") - self:getG(0, dt2, note, "Head", "y")
	local dt
	if dg * sign(self.speed) >= 0 then
		dt = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	else
		dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	end
	return self:getG(0, dt, note, "Head", "y")
end

--------------------------------
-- get*Width get*Height
--------------------------------
NoteSkin.getNoteWidth = function(self, note, part)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	return self:getG(0, dt, note, part, "w")
end

NoteSkin.getNoteHeight = function(self, note, part)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	return self:getG(0, dt, note, part, "h")
end

--------------------------------
-- getLineNoteScaledWidth getLineNoteScaledHeight
--------------------------------

NoteSkin.getLineNoteScaledWidth = function(self, note)
	local dt1 = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local dt2 = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	return math.max(math.abs(
			  self:getG(0, dt2, note, "Head", "x")
			- self:getG(0, dt1, note, "Head", "x")
			+ self:getG(0, dt1, note, "Head", "w")
		), self:getCS(note):x(1))
end

NoteSkin.getLineNoteScaledHeight = function(self, note)
	local dt1 = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local dt2 = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	return math.max(math.abs(
			  self:getG(0, dt2, note, "Head", "y")
			- self:getG(0, dt1, note, "Head", "y")
			+ self:getG(0, dt1, note, "Head", "h")
		), self:getCS(note):y(1))
end

--------------------------------
-- get*ScaleX get*ScaleY
--------------------------------
NoteSkin.getNoteScaleX = function(self, note, part)
	if part == "Body" then
		local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
		local speedSign = sign(self.speed)
		return
			(
				math.max(
					(self:getLongNoteHeadX(note) - self:getLongNoteTailX(note)) * speedSign,
					0
				)
				+ self:getG(0, dt, note, "Body", "w")
			) / self:getCS(note):x(self:getNoteImage(note, part):getWidth())
	end
	
	return self:getNoteWidth(note, part) / self:getCS(note):x(self:getNoteImage(note, part):getWidth())
end

NoteSkin.getNoteScaleY = function(self, note, part)
	if part == "Body" then
		local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
		local speedSign = sign(self.speed)
		return
			(
				math.max(
					(self:getLongNoteHeadY(note) - self:getLongNoteTailY(note)) * speedSign,
					0
				)
				+ self:getG(0, dt, note, "Body", "h")
			) / self:getCS(note):y(self:getNoteImage(note, part):getHeight())
	end
	
	return self:getNoteHeight(note, part) / self:getCS(note):y(self:getNoteImage(note, part):getHeight())
end

--------------------------------
-- will*Draw
--------------------------------
NoteSkin.whereWillShortNoteDrawX = function(self, note)
	local shortNoteX = self:getShortNoteX(note)
	local shortNoteWidth = self:getNoteWidth(note, "Head")

	local cs = self:getCS(note)
	local x
	if (self.allcs:x(cs:X(shortNoteX + shortNoteWidth, true), true) > 0) and (self.allcs:x(cs:X(shortNoteX, true), true) < 1) then
		x = 0
	elseif self.allcs:x(cs:X(shortNoteX, true), true) >= 1 then
		x = 1
	elseif self.allcs:x(cs:X(shortNoteX + shortNoteWidth, true), true) <= 0 then
		x = -1
	end

	return x
end
NoteSkin.whereWillShortNoteDrawY = function(self, note)
	local shortNoteY = self:getShortNoteY(note)
	local shortNoteHeight = self:getNoteHeight(note, "Head")
	
	local cs = self:getCS(note)
	local y
	if (self.allcs:y(cs:Y(shortNoteY + shortNoteHeight, true), true) > 0) and (self.allcs:y(cs:Y(shortNoteY, true), true) < 1) then
		y = 0
	elseif self.allcs:y(cs:Y(shortNoteY, true), true) >= 1 then
		y = 1
	elseif self.allcs:y(cs:Y(shortNoteY + shortNoteHeight, true), true) <= 0 then
		y = -1
	end

	return y
end
NoteSkin.whereWillShortNoteDraw = function(self, note)
	local x = self:whereWillShortNoteDrawX(note)
	local y = self:whereWillShortNoteDrawY(note)
	return x, y
end
NoteSkin.willShortNoteDraw = function(self, note)
	local x, y = self:whereWillShortNoteDraw(note)
	return x == 0 and y == 0
end
NoteSkin.willShortNoteDrawBeforeStart = function(self, note)
	local x, y = self:whereWillShortNoteDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign > 0 or
		self:getG(1, dt, note, "Head", "y") * y * speedSign > 0
end
NoteSkin.willShortNoteDrawAfterEnd = function(self, note)
	local x, y = self:whereWillShortNoteDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign < 0 or
		self:getG(1, dt, note, "Head", "y") * y * speedSign < 0
end

NoteSkin.whereWillLongNoteDrawX = function(self, note)
	local longNoteHeadX = self:getLongNoteHeadX(note)
	local longNoteTailX = self:getLongNoteTailX(note)
	local longNoteHeadWidth = self:getNoteWidth(note, "Head")
	local longNoteTailWidth = self:getNoteWidth(note, "Tail")
	
	local cs = self:getCS(note)
	local x
	if
		(self.allcs:x(cs:X(longNoteHeadX + longNoteHeadWidth, true), true) > 0) and (self.allcs:x(cs:X(longNoteHeadX, true), true) < 1) or
		(self.allcs:x(cs:X(longNoteTailX + longNoteTailWidth, true), true) > 0) and (self.allcs:x(cs:X(longNoteTailX, true), true) < 1) or
		self.allcs:x(cs:X(longNoteTailX + longNoteTailWidth, true), true) * self.allcs:x(cs:X(longNoteHeadX, true), true) < 0
	then
		x = 0
	elseif self.allcs:x(cs:X(longNoteTailX, true), true) >= 1 then
		x = 1
	elseif self.allcs:x(cs:X(longNoteHeadX + longNoteHeadWidth, true), true) <= 0 then
		x = -1
	end
	
	return x
end
NoteSkin.whereWillLongNoteDrawY = function(self, note)
	local longNoteHeadY = self:getLongNoteHeadY(note)
	local longNoteTailY = self:getLongNoteTailY(note)
	local longNoteHeadHeight = self:getNoteHeight(note, "Head")
	local longNoteTailHeight = self:getNoteHeight(note, "Tail")
	
	local cs = self:getCS(note)
	local y
	if
		(self.allcs:y(cs:Y(longNoteHeadY + longNoteHeadHeight, true), true) > 0) and (self.allcs:y(cs:Y(longNoteHeadY, true), true) < 1) or
		(self.allcs:y(cs:Y(longNoteTailY + longNoteTailHeight, true), true) > 0) and (self.allcs:y(cs:Y(longNoteTailY, true), true) < 1) or
		self.allcs:y(cs:Y(longNoteTailY + longNoteTailHeight, true), true) * self.allcs:y(cs:Y(longNoteHeadY, true), true) < 0
	then
		y = 0
	elseif self.allcs:y(cs:Y(longNoteTailY, true), true) >= 1 then
		y = 1
	elseif self.allcs:y(cs:Y(longNoteHeadY + longNoteHeadHeight, true), true) <= 0 then
		y = -1
	end
	
	return y
end
NoteSkin.whereWillLongNoteDraw = function(self, note)
	local x = self:whereWillLongNoteDrawX()
	local y = self:whereWillLongNoteDrawY()
	return x, y
end
NoteSkin.willLongNoteDraw = function(self, note)
	local x, y = self:whereWillLongNoteDraw(note)
	return x == 0 and y == 0
end
NoteSkin.willLongNoteDrawBeforeStart = function(self, note)
	local x, y = self:whereWillLongNoteDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign > 0 or
		self:getG(1, dt, note, "Head", "x") * y * speedSign > 0
end
NoteSkin.willLongNoteDrawAfterEnd = function(self, note)
	local x, y = self:whereWillLongNoteDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign < 0 or
		self:getG(1, dt, note, "Head", "y") * y * speedSign < 0
end


NoteSkin.whereWillLineNoteDrawX = function(self, note)
	local notex = self:getLineNoteX(note)
	local width = self:getLineNoteScaledWidth(note)
	
	local cs = self:getCS(note)
	local x
	if
		(self.allcs:x(cs:X(notex + width, true), true) > 0) and (self.allcs:x(cs:X(notex, true), true) < 1)
	then
		x = 0
	elseif self.allcs:x(cs:X(notex, true), true) >= 1 then
		x = 1
	elseif self.allcs:x(cs:X(notex + width, true), true) <= 0 then
		x = -1
	end

	return x
end
NoteSkin.whereWillLineNoteDrawY = function(self, note)
	local notey = self:getLineNoteY(note)
	local height = self:getLineNoteScaledHeight(note)
	
	local cs = self:getCS(note)
	local y
	if
		(self.allcs:y(cs:Y(notey + height, true), true) > 0) and (self.allcs:y(cs:Y(notey, true), true) < 1)
	then
		y = 0
	elseif self.allcs:y(cs:Y(notey, true), true) >= 1 then
		y = 1
	elseif self.allcs:y(cs:Y(notey + height, true), true) <= 0 then
		y = -1
	end

	return y
end
NoteSkin.whereWillLineNoteDraw = function(self, note)
	local x = self:whereWillLineNoteDrawX()
	local y = self:whereWillLineNoteDrawY()
	return x, y
end
NoteSkin.willLineNoteDraw = function(self, note)
	local x, y = self:whereWillLineNoteDraw(note)
	return x == 0 and y == 0
end
NoteSkin.willLineNoteDrawBeforeStart = function(self, note)
	local x, y = self:whereWillLineNoteDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign > 0 or
		self:getG(1, dt, note, "Head", "y") * y * speedSign > 0
end
NoteSkin.willLineNoteDrawAfterEnd = function(self, note)
	local x, y = self:whereWillLineNoteDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign < 0 or
		self:getG(1, dt, note, "Head", "y") * y * speedSign < 0
end

--------------------------------
-- get*Color
--------------------------------
NoteSkin.getShortNoteColor = function(self, note)
	local color = self.color
	if note.logicalNote.state == "clear" or note.logicalNote.state == "skipped" then
		return color.clear
	elseif note.logicalNote.state == "missed" then
		return color.missed
	elseif note.logicalNote.state == "passed" then
		return color.passed
	end
end

NoteSkin.getLongNoteColor = function(self, note)
	local logicalNote = note.logicalNote
	
	local color = self.color
	if note.fakeStartTime and note.fakeStartTime >= note.endNoteData.timePoint.absoluteTime then
		return color.transparent
	elseif logicalNote.state == "clear" then
		return color.clear
	elseif logicalNote.state == "startMissed" then
		return color.startMissed
	elseif logicalNote.state == "startMissedPressed" then
		return color.startMissedPressed
	elseif logicalNote.state == "startPassedPressed" then
		return color.startPassedPressed
	elseif logicalNote.state == "endPassed" then
		return color.endPassed
	elseif logicalNote.state == "endMissed" then
		return color.endMissed
	elseif logicalNote.state == "endMissedPassed" then
		return color.endMissedPassed
	end
end

return NoteSkin
