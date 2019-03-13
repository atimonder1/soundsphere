local Observable = require("aqua.util.Observable")
local Observer = require("aqua.util.Observer")

local Screen = require("sphere.screen.Screen")
local MapList = require("sphere.game.MapList")
local NoteChartSetList = require("sphere.game.NoteChartSetList")
local NoteChartList = require("sphere.game.NoteChartList")
local MetaDataTable = require("sphere.ui.MetaDataTable")

local BackgroundManager = require("sphere.ui.BackgroundManager")

local FileManagerScreen = Screen:new()

Screen.construct(FileManagerScreen)

FileManagerScreen.load = function(self)
	NoteChartSetList:load()
	NoteChartList:load()
	NoteChartSetList.observable:add(self)
	NoteChartList.observable:add(self)
	NoteChartSetList:postLoad()
	NoteChartList:postLoad()
	BackgroundManager:setColor({127, 127, 127})
end

FileManagerScreen.unload = function(self)
	NoteChartSetList:unload()
	NoteChartList:unload()
end

FileManagerScreen.unload = function(self) end

FileManagerScreen.update = function(self)
	Screen.update(self)
	
	NoteChartSetList:update()
	NoteChartList:update()
end

FileManagerScreen.draw = function(self)
	Screen.draw(self)
	
	NoteChartSetList:draw()
	NoteChartList:draw()
	MetaDataTable:draw()
end

FileManagerScreen.receive = function(self, event)
	if event.cacheData then
		MetaDataTable:setData(event.cacheData)
	end
	if event.backgroundPath then
		BackgroundManager:loadDrawableBackground(event.backgroundPath)
	end
	
	if event.name == "resize" then
		MetaDataTable:reload()
	end
	
	NoteChartSetList:receive(event)
	NoteChartList:receive(event)
end

return FileManagerScreen