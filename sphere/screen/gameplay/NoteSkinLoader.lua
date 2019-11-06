local ncdk = require("ncdk")
local json = require("json")
local NoteSkin = require("sphere.screen.gameplay.NoteSkin")

local NoteSkinLoader = {}

NoteSkinLoader.data = {}
NoteSkinLoader.path = "userdata/skins"

NoteSkinLoader.load = function(self, metaData)
	if metaData.type == "json:full" then
		return self:loadJsonRaw(metaData)
	end
end

NoteSkinLoader.loadJsonRaw = function(self, metaData)
	local noteSkin = NoteSkin:new()
	noteSkin.metaData = metaData

	local file = io.open(metaData.directoryPath .. "/" .. metaData.path, "r")
	noteSkin.data = json.decode(file:read("*all"))
	file:close()

	noteSkin:load()

	return noteSkin
end

return NoteSkinLoader
