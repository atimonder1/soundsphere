local ListItemView = require("sphere.views.ListItemView")
local transform = require("aqua.graphics.transform")

local ScoreListItemView = ListItemView:new({construct = false})

ScoreListItemView.draw = function(self)
	local scoreEngine = self.listView.gameController.rhythmModel.scoreEngine
	local scoreEntry = scoreEngine.scoreEntry
	local item = self.item
	item.selectModel = self.listView.gameController.selectModel
	item.scoreEngine = scoreEngine

	if scoreEntry then
		item.loaded = scoreEntry.replayHash == item.scoreEntry.replayHash
	else
		item.loaded = false
	end

	return ListItemView.draw(self)
end

ScoreListItemView.receive = function(self, event)
	local config = self.listView.config

	local x, y, w, h = self.listView:getItemPosition(self.itemIndex)
	local tf = transform(config.transform):translate(config.x, config.y)
	local mx, my = tf:inverseTransformPoint(love.mouse.getPosition())
	tf:release()

	if event.name == "mousepressed" and (mx >= x and mx <= x + w and my >= y and my <= y + h) then
		local button = event.args[3]
		if button == 1 then
			self.listView.navigator:loadScore(self.itemIndex)
		end
	end
end

return ScoreListItemView
