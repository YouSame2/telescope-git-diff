local Job = require("plenary.job")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local conf = require("telescope.config").values

local function collect_diff_lines(callback)
	local results = {}

	Job:new({
		command = "git",
		args = { "diff", "--no-prefix", "--relative" },
		on_exit = function(j)
			for _, line in ipairs(j:result()) do
				table.insert(results, line)
			end

			Job:new({
				command = "git",
				args = { "ls-files", "--others", "--exclude-standard" },
				on_exit = function(untracked_job)
					local untracked_files = untracked_job:result()
					local pending = #untracked_files
					if pending == 0 then
						callback(results)
						return
					end

					for _, file in ipairs(untracked_files) do
						Job:new({
							command = "git",
							args = { "diff", "--no-index", "--no-prefix", "--relative", "/dev/null", file },
							on_exit = function(diff_job)
								vim.schedule(function()
									for _, line in ipairs(diff_job:result()) do
										table.insert(results, line)
									end
									pending = pending - 1
									if pending == 0 then
										callback(results)
									end
								end)
							end,
						}):start()
					end
				end,
			}):start()
		end,
	}):start()
end

local function parse_diff_lines(lines)
	local entries = {}
	local current_file = nil
	local current_line = nil

	for _, line in ipairs(lines) do
		local new_file = line:match("^%+%+%+ (.+)")
		if new_file then
			current_file = new_file ~= "/dev/null" and new_file or nil
		end

		local hunk_line = line:match("^@@ .*%+([0-9]+)")
		if hunk_line then
			current_line = tonumber(hunk_line)
		elseif current_file and current_line and (line:match("^%+") or line:match("^%-")) then
			local content = line:sub(2)
			table.insert(entries, {
				value = current_file,
				display = string.format("%s:%d:1: %s", current_file, current_line, content),
				ordinal = string.format("%s:%d", current_file, current_line),
				filename = current_file,
				lnum = current_line,
			})
			current_line = nil
		elseif line:match("^ ") and current_line then
			current_line = current_line + 1
		end
	end

	return entries
end

local M = {}

M.git_hunks = function()
	collect_diff_lines(function(lines)
		local entries = parse_diff_lines(lines)

		pickers
			.new({}, {
				prompt_title = "Git hunks",
				results_title = "Git hunks",
				finder = finders.new_table({
					results = entries,
					entry_maker = function(entry)
						return entry
					end,
				}),
				sorter = sorters.get_generic_fuzzy_sorter(),
				previewer = conf.grep_previewer({}),
				layout_strategy = "flex",
			})
			:find()
	end)
end

return require("telescope").register_extension({
  exports = {
    git_hunks = M.git_hunks,
  },
