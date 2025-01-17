local NoteView = require("sphere.views.RhythmView.NoteView")
local ImageNoteView		= require("sphere.views.RhythmView.ImageNoteView")
local video			= require("aqua.video")

local VideoNoteView = NoteView:new({construct = false})

VideoNoteView.timeRate = 0

VideoNoteView.construct = function(self)
	NoteView.construct(self)
	self.headView = self:newNotePartView("Head")

	local images = self.startNoteData.images
	local graphicEngine = self.graphicalNote.graphicEngine
	local path = graphicEngine.localAliases[images[1][1]] or graphicEngine.globalAliases[images[1][1]]

	local vid = video.new(path)
	local image

	if vid then
		vid:rewind()
		image = vid.image

		local deltaTime = self.startNoteData.timePoint.absoluteTime
		vid.getAdjustTime = function()
			return graphicEngine.currentTime - deltaTime
		end
		vid:setRate(graphicEngine.timeRate)

		self.video = vid
		self.drawable = image
	end
end

VideoNoteView.draw = ImageNoteView.draw
VideoNoteView.getTransformParams = ImageNoteView.getTransformParams

VideoNoteView.update = function(self, dt)
	self.timeState = self.graphicalNote.timeState
	self.logicalState = self.graphicalNote.logicalNote:getLastState()
	self.headView.timeState = self.graphicalNote.startTimeState or self.graphicalNote.timeState

	local vid = self.video
	if vid then
		vid:update(dt)
	end
end

VideoNoteView.receive = function(self, event)
	if event.name == "TimeState" then
		self:setTimeRate(event.timeRate)
		self.timeRate = event.timeRate
	end
end

VideoNoteView.setTimeRate = function(self, timeRate)
	local vid = self.video
	if not vid then
		return
	end

	if timeRate == 0 and self.timeRate ~= 0 then
		vid:pause()
	elseif timeRate ~= 0 and self.timeRate == 0 then
		vid:setRate(timeRate)
		vid:play()
	elseif timeRate ~= 0 and self.timeRate ~= 0 then
		vid:setRate(timeRate)
	end
end

return VideoNoteView
