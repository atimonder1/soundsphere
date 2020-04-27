load = function()
	scoreTable.hits = {}
end

receive = function(event)
	if event.name ~= "ScoreNoteState" then
		return
	end

	local hits = scoreTable.hits
	local oldState, newState = event.oldState, event.newState
	if event.noteType == "ShortScoreNote" then
		local deltaTime = (event.currentTime - event.noteTime) / event.timeRate
		if newState == "passed" then
			hits[#hits + 1] = {event.currentTime, deltaTime}
		elseif newState == "missed" then
		end
	elseif event.noteType == "LongScoreNote" then
		local deltaTime = (event.currentTime - event.noteStartTime) / event.timeRate
		if oldState == "clear" then
			if newState == "startPassedPressed" then
				hits[#hits + 1] = {event.currentTime, deltaTime}
			elseif newState == "startMissed" then
			elseif newState == "startMissedPressed" then
			end
		elseif oldState == "startPassedPressed" then
			if newState == "startMissed" then
			elseif newState == "endMissed" then
			elseif newState == "endPassed" then
			end
		elseif oldState == "startMissedPressed" then
			if newState == "endMissedPassed" then
			elseif newState == "startMissed" then
			elseif newState == "endMissed" then
			end
		elseif oldState == "startMissed" then
			if newState == "startMissedPressed" then
			elseif newState == "endMissed" then
			end
		end
	end
end