local providers = require("youtrack")
local conf = {}
return require("telescope").register_extension({
	setup = function(ext_config, config)
		assert(ext_config.token, "You must provide a token for the YouTrack extension")
		assert(ext_config.url, "You must provide a URL for the YouTrack extension")
		conf = ext_config
	end,
	exports = {
		youtrack = function(opts)
			return providers.issues(opts, conf)
		end,
	},
})
