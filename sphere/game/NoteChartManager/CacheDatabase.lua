local sqlite = require("ljsqlite3")
local NoteChartFactory = require("sphere.game.NoteChartManager.NoteChartFactory")
local CacheDataFactory = require("sphere.game.NoteChartManager.CacheDataFactory")
local ThreadPool = require("aqua.thread.ThreadPool")

local CacheDatabase = {}

CacheDatabase.dbpath = "userdata/cache.sqlite"
CacheDatabase.chartspath = "userdata/charts"

CacheDatabase.colnames = {
	"path",
	"hash",
	"container",
	"title",
	"artist",
	"source",
	"tags",
	"name",
	"level",
	"creator",
	"audioPath",
	"stagePath",
	"previewTime",
	"noteCount",
	"length",
	"bpm",
	"inputMode"
}

CacheDatabase.load = function(self)
	self.db = sqlite.open(self.dbpath)
	
	self.db:exec[[
		CREATE TABLE IF NOT EXISTS `cache` (
			`path` TEXT,
			`hash` TEXT,
			`container` REAL,
			`title` TEXT,
			`artist` TEXT,
			`source` TEXT,
			`tags` TEXT,
			`name` TEXT,
			`level` REAL,
			`creator` TEXT,
			`audioPath` TEXT,
			`stagePath` TEXT,
			`previewTime` REAL,
			`noteCount` REAL,
			`length` REAL,
			`bpm` REAL,
			`inputMode` TEXT,
			PRIMARY KEY (`path`)
		);
	]]
	
	self.insertStatement = self.db:prepare([[
		INSERT OR IGNORE INTO `cache` (
			path,
			hash,
			container,
			title,
			artist,
			source,
			tags,
			name,
			level,
			creator,
			audioPath,
			stagePath,
			previewTime,
			noteCount,
			length,
			bpm,
			inputMode
		)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
	]])
	
	self.updateStatement = self.db:prepare([[
		UPDATE `cache` SET
			`hash` = ?,
			`container` = ?,
			`title` = ?,
			`artist` = ?,
			`source` = ?,
			`tags` = ?,
			`name` = ?,
			`level` = ?,
			`creator` = ?,
			`audioPath` = ?,
			`stagePath` = ?,
			`previewTime` = ?,
			`noteCount` = ?,
			`length` = ?,
			`bpm` = ?,
			`inputMode` = ?
		WHERE `path` = ?;
	]])
	
	self.selectStatement = self.db:prepare([[
		SELECT * FROM `cache` WHERE path = ?
	]])
	
	self:setEntry({
		path = self.chartspath,
		container = 2,
		title = self.chartspath:match("^.+/(.-)$"),
	})
end

CacheDatabase.begin = function(self)
	self.db:exec("BEGIN;")
end

CacheDatabase.commit = function(self)
	self.db:exec("COMMIT;")
end

CacheDatabase.update = function(self, path, recursive, callback)
	if not self.isUpdating then
		ThreadPool:execute(
			[[
				local path, recursive = ...
				local CacheDatabase = require("sphere.game.NoteChartManager.CacheDatabase")
				if not CacheDatabase.db then CacheDatabase:load() end
				CacheDatabase:lookup(path, recursive)
			]],
			{path, recursive},
			function(result)
				if not result[1] then
					print(result[2])
				end
				callback()
				self.isUpdating = false
			end
		)
		self.isUpdating = true
	end
end

CacheDatabase.rowByPath = function(self, path)
	return self.selectStatement:reset():bind(path):step()
end

CacheDatabase.lookup = function(self, directoryPath, recursive)
	if love.filesystem.isFile(directoryPath) then
		return -1
	end
	
	local items = love.filesystem.getDirectoryItems(directoryPath)
	
	local chartPaths = {}
	local containers = 0
	
	for _, itemName in ipairs(items) do
		local path = directoryPath .. "/" .. itemName
		if love.filesystem.isFile(path) and NoteChartFactory:isNoteChart(path) then
			chartPaths[#chartPaths + 1] = path
		end
	end
	
	if #chartPaths > 0 then
		self:processNoteChartSet(chartPaths, directoryPath)
		return 1
	end
	
	for _, itemName in ipairs(items) do
		local path = directoryPath .. "/" .. itemName
		if love.filesystem.isDirectory(path) and (recursive or not self:rowByPath(path)) then
			if self:lookup(path, true) > 0 then
				containers = containers + 1
			end
		end
	end
	
	if containers > 0 then
		self:setEntry({
			path = directoryPath,
			container = 2,
			title = directoryPath:match("^.+/(.-)$"),
		})
		
		return 2
	end
	
	return -1
end

CacheDatabase.processNoteChartSet = function(self, chartPaths, directoryPath)
	local cacheDatas = CacheDataFactory:getCacheDatas(chartPaths)
	
	self:begin()
	for i = 1, #cacheDatas do
		self:setEntry(cacheDatas[i])
	end
	print(cacheDatas[#cacheDatas].path)
	self:commit()
end

CacheDatabase.select = function(self)
	local data = {}
	
	for _, cacheData in pairs(self.data) do
		table.insert(data, cacheData)
	end
	
	local cacheDataIndex = 1
	
	return function()
		local cacheData = data[cacheDataIndex]
		cacheDataIndex = cacheDataIndex + 1
		
		return cacheData
	end
end

CacheDatabase.setEntry = function(self, cacheData)
	self.insertStatement:reset():bind(
		cacheData.path,
		cacheData.hash,
		cacheData.container,
		cacheData.title,
		cacheData.artist,
		cacheData.source,
		cacheData.tags,
		cacheData.name,
		cacheData.level,
		cacheData.creator,
		cacheData.audioPath,
		cacheData.stagePath,
		cacheData.previewTime,
		cacheData.noteCount,
		cacheData.length,
		cacheData.bpm,
		cacheData.inputMode
	):step()
	self.updateStatement:reset():bind(
		cacheData.hash,
		cacheData.container,
		cacheData.title,
		cacheData.artist,
		cacheData.source,
		cacheData.tags,
		cacheData.name,
		cacheData.level,
		cacheData.creator,
		cacheData.audioPath,
		cacheData.stagePath,
		cacheData.previewTime,
		cacheData.noteCount,
		cacheData.length,
		cacheData.bpm,
		cacheData.inputMode,
		cacheData.path
	):step()
end

return CacheDatabase