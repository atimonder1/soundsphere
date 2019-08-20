local Modifier = require("sphere.screen.gameplay.ModifierManager.Modifier")

local Mirror = Modifier:new()

Mirror.name = "Mirror"

Mirror.apply = function(self)
	local noteChart = self.noteChart
	local keyCount = noteChart.inputMode:getInputCount("key")
	local scratchCount = noteChart.inputMode:getInputCount("scratch")
	
	for layerIndex in noteChart:getLayerDataIndexIterator() do
		local layerData = noteChart:requireLayerData(layerIndex)
		
		for noteDataIndex = 1, layerData:getNoteDataCount() do
			local noteData = layerData:getNoteData(noteDataIndex)
			
			if noteData.inputType == "key" then
				noteData.inputIndex = keyCount - noteData.inputIndex + 1
			elseif noteData.inputType == "scratch" then
				noteData.noteType = scratchCount - noteData.inputIndex + 1
			end
		end
	end
end

return Mirror