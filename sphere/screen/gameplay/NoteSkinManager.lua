local ncdk = require("ncdk")
local json = require("json")

local NoteSkinManager = {}

NoteSkinManager.data = {}
NoteSkinManager.path = "userdata/skins"

NoteSkinManager.load = function(self)
	self.metaDatas = {}
	return self:lookup("userdata/skins")
end

NoteSkinManager.lookup = function(self, directoryPath)
	for _, itemName in pairs(love.filesystem.getDirectoryItems(directoryPath)) do
		local path = directoryPath .. "/" .. itemName
		if love.filesystem.isDirectory(path) then
			if love.filesystem.exists(path .. "/metadata.json") then
				self:loadMetaData(path, "metadata.json")
			end
		end
	end
end

NoteSkinManager.loadMetaData = function(self, path, fileName)
	local file = io.open(path .. "/" .. fileName, "r")
	local jsonData = json.decode(file:read("*all"))
	file:close()

	local metaDatas = self.metaDatas
	for _, metaData in ipairs(jsonData) do
		metaData.directoryPath = path
		metaData.inputMode = ncdk.InputMode:new():setString(metaData.inputMode)
		metaDatas[#metaDatas + 1] = metaData
	end
end

NoteSkinManager.getNoteSkinList = function(self, inputMode)
	local list = {}

	for _, metaData in ipairs(self.metaDatas) do
		if metaData.inputMode >= inputMode then
			list[#list + 1] = metaData
		end
	end
	
	return list
end

-- NoteSkinManager.loadNoteSkinMetaData = function(self, filePath)
-- 	local file = io.open(self.directoryPath .. "/" .. filePath, "r")
-- 	self:processNoteSkin(json.decode(file:read("*all")))
-- 	file:close()
-- end

-- NoteSkinManager.loadPlayField = function(self, filePath)
-- 	local file = io.open(self.directoryPath .. "/" .. filePath, "r")
-- 	local playField = json.decode(file:read("*all"))
-- 	file:close()
	
-- 	return playField
-- end

-- NoteSkinManager.processNoteSkin = function(self, noteSkin)
-- 	local data = {}
-- 	data.directoryPath = self.directoryPath
-- 	data.noteSkin = noteSkin
	
-- 	data.inputMode = ncdk.InputMode:new()
-- 	for inputType, inputCount in pairs(noteSkin.inputMode) do
-- 		data.inputMode:setInputCount(inputType, inputCount)
-- 	end
	
-- 	if noteSkin.playfield then
-- 		data.playField = self:loadPlayField(noteSkin.playfield)
-- 	end
	
-- 	table.insert(self.data, data)
-- end

return NoteSkinManager
