local ScoreSystem = require("sphere.models.RhythmModel.ScoreEngine.ScoreSystem")

local JudgementScoreSystem = ScoreSystem:new()

JudgementScoreSystem.name = "judgement"

JudgementScoreSystem.judgements = {
	{-1, "early not perfect", "not perfect"},
	{-0.016, "perfect"},
	{0.016, "perfect"},
	{1, "late not perfect", "not perfect"},
}

JudgementScoreSystem.construct = function(self)
	self.judgementName = ""
	self.counters = {}
	table.sort(self.judgements, function(a, b) return math.abs(a[1]) < math.abs(b[1]) end)
end

ScoreSystem.processJudgement = function(self, event)
	local noteStartTime = event.noteStartTime or event.noteTime
	local deltaTime = (event.currentTime - noteStartTime) / math.abs(event.timeRate)

	for _, judgement in ipairs(self.judgements) do
		local time = judgement[1]
		if deltaTime * time > 0 and math.abs(deltaTime) <= math.abs(time) then
			for i = 2, #judgement do
				local name = judgement[i]
				self.counters[name] = (self.counters[name] or 0) + 1
			end
			self.judgementName = judgement[2]
			break
		end
	end
end

JudgementScoreSystem.notes = {
	ShortScoreNote = {
		clear = {
			passed = JudgementScoreSystem.processJudgement,
			missed = nil,
		},
	},
	LongScoreNote = {
		clear = {
			startPassedPressed = JudgementScoreSystem.processJudgement,
			startMissed = nil,
			startMissedPressed = nil,
		},
		startPassedPressed = {
			startMissed = nil,
			endMissed = nil,
			endPassed = nil,
		},
		startMissedPressed = {
			endMissedPassed = nil,
			startMissed = nil,
			endMissed = nil,
		},
		startMissed = {
			startMissedPressed = nil,
			endMissed = nil,
		},
	},
}

return JudgementScoreSystem
