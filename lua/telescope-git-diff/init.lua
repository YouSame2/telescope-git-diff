return require("telescope").register_extension({
	exports = {
		git_hunks = require("telescope._extensions.git_diff").git_hunks,
	},
})
