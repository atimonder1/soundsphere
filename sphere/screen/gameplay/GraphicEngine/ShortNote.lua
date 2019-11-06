local GraphicalNote = require("sphere.screen.gameplay.CloudburstEngine.graphics.GraphicalNote")

local ShortGraphicalNote = GraphicalNote:new()

ShortGraphicalNote.update = function(self)
	self:computeVisualTime()
	
	if not self:tryNext() then
		self.drawable.y = self:getY()
		self.drawable.x = self:getX()
		self.drawable.sx = self:getScaleX()
		self.drawable.sy = self:getScaleY()
		self.drawable:reload()
		self.drawable.color = self:getColor()
	end
end

ShortGraphicalNote.computeVisualTime = function(self)
	self.startNoteData.timePoint:computeVisualTime(self.noteDrawer.currentTimePoint)
end

ShortGraphicalNote.activate = function(self)
	self.drawable = self:getDrawable()
	self.drawable:reload()
	self.container = self:getContainer()
	self.container:add(self.drawable)
	
	self.activated = true
end

ShortGraphicalNote.deactivate = function(self)
	self.container:remove(self.drawable)
	self.activated = false
end

ShortGraphicalNote.reload = function(self)
	self.drawable.sx = self:getScaleX()
	self.drawable.sy = self:getScaleY()
	self.drawable:reload()
end

ShortGraphicalNote.getColor = function(self)
	local color = self.noteSkin.color
	if note.logicalNote.state == "clear" or note.logicalNote.state == "skipped" then
		return color.clear
	elseif note.logicalNote.state == "missed" then
		return color.missed
	elseif note.logicalNote.state == "passed" then
		return color.passed
	end
end

ShortGraphicalNote.getLayer = function(self)
	return self.noteSkin:getNoteLayer(self, "Head")
end

ShortGraphicalNote.getDrawable = function(self)
	return self.noteSkin:getImageDrawable(self, "Head")
end

ShortGraphicalNote.getContainer = function(self)
	return self.noteSkin:getImageContainer(self, "Head")
end

ShortGraphicalNote.getX = function(self)
	local dt = self.engine.currentTime - self.startNoteData.timePoint.currentVisualTime
	local noteSkin = self.noteSkin
	return
		  noteSkin:getG(0, dt, note, "Head", "x")
		+ noteSkin:getG(0, dt, note, "Head", "w")
		* noteSkin:getG(0, dt, note, "Head", "ox")
end

ShortGraphicalNote.getY = function(self)
	local dt = self.engine.currentTime - self.startNoteData.timePoint.currentVisualTime
	local noteSkin = self.noteSkin
	return
		  noteSkin:getG(0, dt, note, "Head", "y")
		+ noteSkin:getG(0, dt, note, "Head", "h")
		* noteSkin:getG(0, dt, note, "Head", "oy")
end

ShortGraphicalNote.getNoteWidth = function(self, note, part)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	return self.noteSkin:getG(0, dt, note, part, "w")
end

ShortGraphicalNote.getNoteHeight = function(self, note, part)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	return self.noteSkin:getG(0, dt, note, part, "h")
end

ShortGraphicalNote.getScaleX = function(self)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local noteSkin = self.noteSkin
	return self:getNoteWidth(note, "Head") / noteSkin:getCS(note):x(noteSkin:getNoteImage(note, "Head"):getWidth())
end

ShortGraphicalNote.getScaleY = function(self)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local noteSkin = self.noteSkin
	return self:getNoteHeight(note, "Head") / noteSkin:getCS(note):y(noteSkin:getNoteImage(note, "Head"):getHeight())
end

ShortGraphicalNote.whereWillDrawX = function(self, note)
	local shortNoteX = self:getX(note)
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
ShortGraphicalNote.whereWillShortNoteDrawY = function(self, note)
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
ShortGraphicalNote.whereWillShortNoteDrawW = function(self, note)
	local shortNoteWidth = self:getNoteWidth(note, "Head")
	return self:whereWillBelongSegment(note, "Head", "w", shortNoteWidth)
end
ShortGraphicalNote.whereWillShortNoteDrawH = function(self, note)
	local shortNoteHeight = self:getNoteHeight(note, "Head")
	return self:whereWillBelongSegment(note, "Head", "h", shortNoteHeight)
end
ShortGraphicalNote.whereWillShortNoteDraw = function(self, note)
	local x = self:whereWillDrawX(note)
	local y = self:whereWillDrawY(note)
	local w = self:whereWillDrawW(note)
	local h = self:whereWillDrawH(note)
	return x, y, w, h
end
ShortGraphicalNote.willDraw = function(self, note)
	local x, y, w, h = self:whereWillDraw(note)
	return
		x == 0 and
		y == 0 and
		w == 0 and
		h == 0
end
ShortGraphicalNote.willDrawBeforeStart = function(self, note)
	local x, y, w, h = self:whereWillDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign > 0 or
		self:getG(1, dt, note, "Head", "y") * y * speedSign > 0 or
		self:getG(1, dt, note, "Head", "w") * w * speedSign > 0 or
		self:getG(1, dt, note, "Head", "h") * h * speedSign > 0
end
ShortGraphicalNote.willDrawAfterEnd = function(self, note)
	local x, y, w, h = self:whereWillDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign < 0 or
		self:getG(1, dt, note, "Head", "y") * y * speedSign < 0 or
		self:getG(1, dt, note, "Head", "w") * w * speedSign < 0 or
		self:getG(1, dt, note, "Head", "h") * h * speedSign < 0
end

return ShortGraphicalNote
