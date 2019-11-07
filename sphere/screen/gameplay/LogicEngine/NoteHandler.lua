local Class				= require("aqua.util.Class")
local ShortNote	= require("sphere.screen.gameplay.LogicalEngine.ShortNote")
local LongNote	= require("sphere.screen.gameplay.LogicalEngine.LongNote")

local NoteHandler = Class:new()

NoteHandler.loadNoteData = function(self)
	self.noteData = {}
	
	for layerDataIndex in self.engine.noteChart:getLayerDataIndexIterator() do
		local layerData = self.engine.noteChart:requireLayerData(layerDataIndex)
		for noteDataIndex = 1, layerData:getNoteDataCount() do
			local noteData = layerData:getNoteData(noteDataIndex)
			
			if noteData.inputType == self.inputType and noteData.inputIndex == self.inputIndex then
				local logicalNote
				
				if noteData.noteType == "ShortNote" then
					logicalNote = ShortNote:new({
						startNoteData = noteData,
						pressSounds = noteData.sounds,
						noteType = "ShortNote"
					})
					self.engine.noteCount = self.engine.noteCount + 1
				elseif noteData.noteType == "LongNoteStart" then
					logicalNote = LongNote:new({
						startNoteData = noteData,
						endNoteData = noteData.endNoteData,
						pressSounds = noteData.sounds,
						releaseSounds = noteData.endNoteData.sounds,
						noteType = "LongNote"
					})
					self.engine.noteCount = self.engine.noteCount + 1
				elseif noteData.noteType == "LineNoteStart" then
					logicalNote = ShorNote:new({
						startNoteData = noteData,
						endNoteData = noteData.endNoteData,
						pressSounds = noteData.sounds,
						noteType = "SoundNote"
					})
				elseif noteData.noteType == "SoundNote" then
					logicalNote = ShortNote:new({
						startNoteData = noteData,
						pressSounds = noteData.sounds,
						noteType = "SoundNote"
					})
				end
				
				if logicalNote then
					logicalNote.noteHandler = self
					logicalNote.engine = self.engine
					logicalNote.score = self.engine.score
					table.insert(self.noteData, logicalNote)
					
					self.engine.sharedLogicalNoteData[noteData] = logicalNote
				end
			end
		end
	end
	
	table.sort(self.noteData, function(a, b)
		return a.startNoteData.timePoint < b.startNoteData.timePoint
	end)

	for index, logicalNote in ipairs(self.noteData) do
		logicalNote.index = index
	end
	
	self.startNoteIndex = 1
	self.currentNote = self.noteData[1]
end

NoteHandler.setKeyState = function(self)
	self.keyBind = self.inputType .. self.inputIndex
	self.keyState = false
end

NoteHandler.update = function(self)
	if not self.currentNote then return end
	return self.currentNote:update()
end

NoteHandler.receive = function(self, event)
	if not self.currentNote then return end
	
	local key = event.args and event.args[1]
	if key == self.keyBind then
		local currentNote = self.currentNote
		if event.name == "keypressed" then
			self.currentNote.keyState = true
			return self:switchKey(true)
		elseif event.name == "keyreleased" then
			self.currentNote.keyState = false
			return self:switchKey(false)
		end
	end
end

NoteHandler.switchKey = function(self, state)
	self.keyState = state
	return self:sendState()
end

NoteHandler.sendState = function(self)
	return self.engine.observable:send({
		name = "LogicalNoteHandlerUpdated",
		noteHandler = self
	})
end

NoteHandler.load = function(self)
	self:loadNoteData()
	self:setKeyState()
end

NoteHandler.unload = function(self) end

return NoteHandler
