

local LogicEngine = {}

LogicEngine.load = function(self)
	self.observable = Observable:new()
	
	self.inputMode = self.noteChart.inputMode
	
	self.sharedLogicalNoteData = {}
	
	self:loadNoteHandlers()
end

LogicEngine.update = function(self, dt)
	self:updateNoteHandlers()
end

LogicEngine.unload = function(self)
	self:unloadNoteHandlers()
end

LogicEngine.draw = function(self)
	self.noteSkin:draw()
end

LogicEngine.receive = function(self, event)
	if event.virtual then
		for noteHandler in pairs(self.noteHandlers) do
			noteHandler:receive(event)
		end
	end
end

LogicEngine.getNoteHandler = function(self, inputType, inputIndex)
	if
		inputType == "key" or
		inputType == "scratch" or
		inputType == "measure" or
		inputType == "bt" or
		inputType == "fx" or
		inputType == "laserleft" or
		inputType == "laserright" or
		inputType == "auto"
	then
		return NoteHandler:new({
			inputType = inputType,
			inputIndex = inputIndex,
			engine = self
		})
	end
end

LogicEngine.loadNoteHandlers = function(self)
	self.noteHandlers = {}
	for inputType, inputIndex in self.noteChart:getInputIteraator() do
		local noteHandler = self:getNoteHandler(inputType, inputIndex)
		if noteHandler then
			self.noteHandlers[noteHandler] = noteHandler
			noteHandler:load()
		end
	end
end

LogicEngine.updateNoteHandlers = function(self)
	for noteHandler in pairs(self.noteHandlers) do
		noteHandler:update()
	end
end

LogicEngine.unloadNoteHandlers = function(self)
	for noteHandler in pairs(self.noteHandlers) do
		noteHandler:unload()
	end
	self.noteHandlers = nil
end

return LogicEngine
