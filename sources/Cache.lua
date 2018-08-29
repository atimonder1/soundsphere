Cache = createClass()

Cache.init = function(self)
	self.cacheDatas = {}
	self.cacheDataDirectoryPathUniqueKey = {}
end

Cache.import = function(self)
	local status, cacheDatas = pcall(loadfile("cache"))
	
	if status then
		self.cacheDatas = cacheDatas or {}
		for _, cacheData in ipairs(self.cacheDatas) do
			self.cacheDataDirectoryPathUniqueKey[cacheData.directoryPath] = true
		end
	else
		print(cacheDatas)
		self.cacheDatas = {}
	end
	
	self:clean()
	
	self:lookup("userdata/charts")
end

Cache.export = function(self)
	local file = io.open("cache", "w")
	
	file:write("return {\n")
	for cacheData in self:getCacheDataIterator() do
		file:write(table.export(cacheData))
		file:write(",\n")
	end
	file:write("}")
end

Cache.update = function(self)
	
end

Cache.getCacheDataIterator = function(self)
	local cacheDatas = {}
	
	for _, cacheData in pairs(self.cacheDatas) do
		table.insert(cacheDatas, cacheData)
	end
	
	local cacheDataIndex = 1
	
	return function()
		local cacheData = cacheDatas[cacheDataIndex]
		cacheDataIndex = cacheDataIndex + 1
		
		return cacheData
	end
end

Cache.clean = function(self)
	for directoryPath in pairs(self.cacheDataDirectoryPathUniqueKey) do
		if not love.filesystem.exists(directoryPath) then
			for index, cacheData in pairs(self.cacheDatas) do
				if cacheData.directoryPath == directoryPath then
					self.cacheDatas[index] = nil
					print("removing from cache", directoryPath)
				end
			end
		end
	end
end

Cache.extensions = {
	{
		type = "osu",
		patterns = {
			".osu$"
		}
	},
	{
		type = "bms",
		patterns = {
			".bms$", ".bme$", ".bml$", 
		}
	},
	{
		type = "ucs",
		patterns = {
			".ucs$"
		}
	}
}

Cache.getExtensionType = function(self, fileName)
	for _, extensionData in ipairs(self.extensions) do
		for _, pattern in ipairs(extensionData.patterns) do
			if fileName:find(pattern) then
				return extensionData.type
			end
		end
	end
end

Cache.lookup = function(self, directoryPath)
	for _, itemName in pairs(love.filesystem.getDirectoryItems(directoryPath)) do
		if love.filesystem.isDirectory(directoryPath .. "/" .. itemName) then
			if not self.cacheDataDirectoryPathUniqueKey[directoryPath .. "/" .. itemName] then
				local hasCharts = self:generateCacheDataDirectory(directoryPath .. "/" .. itemName)
				self.cacheDataDirectoryPathUniqueKey[directoryPath .. "/" .. itemName] = true
				
				if not hasCharts then
					self:lookup(directoryPath .. "/" .. itemName)
				end
			end
		elseif love.filesystem.isFile(directoryPath .. "/" .. itemName) then
			
		end
	end
end

Cache.generateCacheDataDirectory = function(self, directoryPath)
	print("checking directory", directoryPath)
	local hasCharts = false
	for _, itemName in pairs(love.filesystem.getDirectoryItems(directoryPath)) do
		local extensionType = self:getExtensionType(itemName)
		if love.filesystem.isFile(directoryPath .. "/" .. itemName) and extensionType then
			self:generateCacheData(directoryPath, itemName, extensionType)
			hasCharts = true
		end
	end
	
	return hasCharts
end

Cache.generateCacheData = function(self, directoryPath, fileName, extensionType)
	print("processing file", fileName)
	if extensionType == "bms" then
		self:addCacheData(self:generateBMSCacheData(directoryPath, fileName))
	elseif extensionType == "osu" then
		self:addCacheData(self:generateOsuCacheData(directoryPath, fileName))
	elseif extensionType == "ucs" then
		self:addCacheData(self:generateUCSCacheData(directoryPath, fileName))
	end
end

Cache.addCacheData = function(self, cacheData)
	table.insert(self.cacheDatas, cacheData)
end

Cache.generateBMSCacheData = function(self, directoryPath, fileName)
	local cacheData = {}
	cacheData.directoryPath = directoryPath
	cacheData.fileName = fileName
	cacheData.title = "<title>"
	cacheData.artist = "<artist>"
	cacheData.playlevel = "<playlevel>"
	
	local file = love.filesystem.newFile(directoryPath .. "/" ..  fileName)
	file:open("r")
	
	for line in file:lines() do
		local line = iconv(line, "UTF-8", "SHIFT-JIS") or iconv(line, "UTF-8", "EUC-KR") or line
		if line:find("^#TITLE .+$") then
			cacheData.title = line:match("^#TITLE (.+)$")
		end
		if line:find("^#ARTIST .+$") then
			cacheData.artist = line:match("^#ARTIST (.+)$")
		end
		if line:find("^#PLAYLEVEL .+$") then
			cacheData.playlevel = line:match("^#PLAYLEVEL (.+)$")
		end
		if line:find("^#WAV") then
			break
		end
	end
	file:close()
	
	return cacheData
end

Cache.generateOsuCacheData = function(self, directoryPath, fileName)
	local cacheData = {}
	cacheData.directoryPath = directoryPath
	cacheData.fileName = fileName
	cacheData.title = "<title>"
	cacheData.artist = "<artist>"
	cacheData.playlevel = "<playlevel>"
	
	local file = love.filesystem.newFile(directoryPath .. "/" ..  fileName)
	file:open("r")
	
	for line in file:lines() do
		if line:find("Title:[ ]?.+$") then
			cacheData.title = line:match("^Title:[ ]?(.+)$")
		end
		if line:find("Artist:[ ]?.+$") then
			cacheData.artist = line:match("Artist:[ ]?(.+)$")
		end
		if line:find("^%[Events%]") then
			break
		end
	end
	file:close()
	
	return cacheData
end

Cache.generateUCSCacheData = function(self, directoryPath, fileName)
	local cacheData = {}
	cacheData.directoryPath = directoryPath
	cacheData.fileName = fileName
	cacheData.title = fileName:match("^(.+)%.ucs$")
	cacheData.artist = ""
	cacheData.playlevel = ""
	
	return cacheData
end
