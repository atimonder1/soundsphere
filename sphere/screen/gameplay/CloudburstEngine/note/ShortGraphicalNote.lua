local GraphicalNote = require("sphere.screen.gameplay.CloudburstEngine.note.GraphicalNote")

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
	return self.noteSkin:getShortNoteColor(self)
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
	return self.noteSkin:getShortNoteX(self)
end

ShortGraphicalNote.getY = function(self)
	return self.noteSkin:getShortNoteY(self)
end

ShortGraphicalNote.getScaleX = function(self)
	return self.noteSkin:getNoteScaleX(self, "Head")
end

ShortGraphicalNote.getScaleY = function(self)
	return self.noteSkin:getNoteScaleY(self, "Head")
end

ShortGraphicalNote.willDraw = function(self)
	return self.noteSkin:willShortNoteDraw(self)
end

ShortGraphicalNote.willDrawBeforeStart = function(self)
	return self.noteSkin:willShortNoteDrawBeforeStart(self)
end

ShortGraphicalNote.willDrawAfterEnd = function(self)
	return self.noteSkin:willShortNoteDrawAfterEnd(self)
end

return ShortGraphicalNote
