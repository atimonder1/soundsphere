local GraphicalNote	= require("sphere.screen.gameplay.CloudburstEngine.graphics.GraphicalNote")
local Rectangle		= require("aqua.graphics.Rectangle")

local LineGraphicalNote = GraphicalNote:new()

LineGraphicalNote.update = function(self)
	self:computeVisualTime()
	
	if not self:tryNext() then
		self.drawable.x = self:getX()
		self.drawable.y = self:getY()
		self.drawable:reload()
	end
end

LineGraphicalNote.computeVisualTime = function(self)
	self.startNoteData.timePoint:computeVisualTime(self.noteDrawer.currentTimePoint)
	self.endNoteData.timePoint:computeVisualTime(self.noteDrawer.currentTimePoint)
end

LineGraphicalNote.activate = function(self)
	self.drawable = self:getDrawable()
	self.drawable:reload()
	self.container = self:getContainer()
	self.container:add(self.drawable)
	
	self.activated = true
end

LineGraphicalNote.deactivate = function(self)
	self.container:remove(self.drawable)
	self.activated = false
end

LineGraphicalNote.reload = function(self)
	self.drawable:reload()
end

LineGraphicalNote.getLayer = function(self)
	return self.noteSkin:getNoteLayer(self, "Head")
end

LineGraphicalNote.getDrawable = function(self)
	return self.noteSkin:getRectangleDrawable(self, "Head")
end

LineGraphicalNote.getContainer = function(self)
	return self.noteSkin:getRectangleContainer(self, "Head")
end

LineGraphicalNote.getLineNoteX = function(self, note)
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


LineGraphicalNote.getLineNoteY = function(self, note)
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

LineGraphicalNote.getX = function(self)
	return self.noteSkin:getLineNoteX(self)
end
LineGraphicalNote.getY = function(self)
	return self.noteSkin:getLineNoteY(self)
end



LineGraphicalNote.getLineNoteScaledWidth = function(self, note)
	local dt1 = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local dt2 = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	return math.max(math.abs(
			  self:getG(0, dt2, note, "Head", "x")
			- self:getG(0, dt1, note, "Head", "x")
			+ self:getG(0, dt1, note, "Head", "w")
		), self:getCS(note):x(1))
end

LineGraphicalNote.getLineNoteScaledHeight = function(self, note)
	local dt1 = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local dt2 = note.engine.currentTime - note.endNoteData.timePoint.currentVisualTime
	return math.max(math.abs(
			  self:getG(0, dt2, note, "Head", "y")
			- self:getG(0, dt1, note, "Head", "y")
			+ self:getG(0, dt1, note, "Head", "h")
		), self:getCS(note):y(1))
end

LineGraphicalNote.getWidth = function(self)
	return self.noteSkin:getLineNoteScaledWidth(self)
end
LineGraphicalNote.getHeight = function(self)
	return self.noteSkin:getLineNoteScaledHeight(self)
end

LineGraphicalNote.whereWillLineNoteDrawX = function(self, note)
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
LineGraphicalNote.whereWillLineNoteDrawY = function(self, note)
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
LineGraphicalNote.whereWillLineNoteDraw = function(self, note)
	local x = self:whereWillLineNoteDrawX(note)
	local y = self:whereWillLineNoteDrawY(note)
	return x, y
end
LineGraphicalNote.willLineNoteDraw = function(self, note)
	local x, y = self:whereWillLineNoteDraw(note)
	return x == 0 and y == 0
end
LineGraphicalNote.willLineNoteDrawBeforeStart = function(self, note)
	local x, y = self:whereWillLineNoteDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign > 0 or
		self:getG(1, dt, note, "Head", "y") * y * speedSign > 0
end
LineGraphicalNote.willLineNoteDrawAfterEnd = function(self, note)
	local x, y = self:whereWillLineNoteDraw(note)
	local dt = note.engine.currentTime - note.startNoteData.timePoint.currentVisualTime
	local speedSign = sign(self.speed)
	return
		self:getG(1, dt, note, "Head", "x") * x * speedSign < 0 or
		self:getG(1, dt, note, "Head", "y") * y * speedSign < 0
end

LineGraphicalNote.willDraw = function(self)
	return self.noteSkin:willLineNoteDraw(self)
end
LineGraphicalNote.willDrawBeforeStart = function(self)
	return self.noteSkin:willLineNoteDrawBeforeStart(self)
end
LineGraphicalNote.willDrawAfterEnd = function(self)
	return self.noteSkin:willLineNoteDrawAfterEnd(self)
end

return LineGraphicalNote
