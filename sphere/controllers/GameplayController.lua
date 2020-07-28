local Class = require("aqua.util.Class")
local ScreenManager = require("sphere.screen.ScreenManager")

local GameplayController = Class:new()

GameplayController.receive = function(self, event)
	if event.name == "play" then
		self:play()
	elseif event.name == "pause" then
		self:pause()
	elseif event.name == "keypressed" then
		if event.args[1] == "1" then
			self:pause()
		elseif event.args[1] == "2" then
			self:play()
		elseif event.args[1] == "escape" then
			self:saveScore()
			ScreenManager:set(require("sphere.screen.ResultScreen"),
				function()
					ScreenManager:receive({
						name = "scoreSystem",
						scoreSystem = self.rhythmModel.scoreEngine.scoreSystem,
						noteChart = self.noteChart,
						noteChartEntry = self.noteChartModel.noteChartEntry,
						noteChartDataEntry = self.noteChartModel.noteChartDataEntry,
						autoplay = self.rhythmModel.logicEngine.autoplay
					})
				end
			)
		end
	end
end

GameplayController.saveScore = function(self)
	-- if scoreSystem.scoreTable.score > 0 and ReplayManager.mode ~= "replay" and not event.autoplay then
	-- 	local modifierSequence = ModifierManager:getSequence()
	-- 	local replayHash = ReplayManager:saveReplay(event.noteChartDataEntry, modifierSequence)
	-- 	ScoreManager:insertScore(scoreSystem.scoreTable, event.noteChartDataEntry, replayHash, modifierSequence)
	-- end
end

GameplayController.pause = function(self)
	self.rhythmModel.timeEngine:setTimeRate(0)
end

GameplayController.play = function(self)
	self.rhythmModel.timeEngine:setTimeRate(self.rhythmModel.timeEngine:getBaseTimeRate())
end

return GameplayController
