local Class = require("aqua.util.Class")
local WebApi = require("sphere.models.OnlineModel.WebApi")
local AuthManager = require("sphere.models.OnlineModel.AuthManager")
local OnlineScoreManager = require("sphere.models.OnlineModel.OnlineScoreManager")

local OnlineModel = Class:new()

OnlineModel.construct = function(self)
	self.webApi = WebApi:new()
	self.authManager = AuthManager:new()
	self.onlineScoreManager = OnlineScoreManager:new()
end

OnlineModel.load = function(self)
	local webApi = self.webApi
	local onlineScoreManager = self.onlineScoreManager
	local authManager = self.authManager

	authManager.onlineModel = self
	onlineScoreManager.onlineModel = self

	local config = self.configModel.configs.online
	webApi.config = config
	webApi:load()

	onlineScoreManager.config = config
	authManager.config = config

	onlineScoreManager.webApi = webApi
	authManager.webApi = webApi
end

OnlineModel.unload = function(self) end

return OnlineModel
