local Class = require("aqua.util.Class")

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

NoteSkin.construct = function(self)
	self.images = {}
end

NoteSkin.load = function(self)
	self:loadImages()
end

NoteSkin.loadImages = function(self)
	if not self.data.images then
		return
	end
	
	for _, imageData in pairs(self.data.images) do
		self.images[imageData.name] = self.metaData.directoryPath .. "/" .. imageData.path
	end
end

NoteSkin.checkNote = function(self, note)
	if self.data[note.id] then
		return true
	end
end

NoteSkin.getNoteImage = function(self, note, part)
	return self.images[self.data[note.id][part].image]
end

return NoteSkin
