local M = {}

local fzf = require("fzf-lua")
local cd_history = {}
local history_file = vim.fn.stdpath("data") .. "/cd_history.txt"

-- Load history from file
local function load_history()
	local f = io.open(history_file, "r")
	if f then
		for line in f:lines() do
			table.insert(cd_history, 1, line) -- Insert at the start for recently visited order
		end
		f:close()
	else
		vim.notify("Couldn't open history file", vim.log.levels.ERROR, { title = "CD History" })
	end
end

-- Save history to file
local function save_history()
	local f = io.open(history_file, "w")
	if f then
		for _, dir in ipairs(cd_history) do
			f:write(dir .. "\n")
		end
		f:close()
	end
end

-- Add the current directory to the history
local function add_to_history()
	local cwd = vim.fn.getcwd()
	-- Remove cwd if it already exists in the list
	for i, dir in ipairs(cd_history) do
		if dir == cwd then
			table.remove(cd_history, i)
			break
		end
	end
	table.insert(cd_history, 1, cwd) -- Add to the start for most recent order
	save_history()
end

-- Show the directory history in fzf-lua
function M.show_cd_history()
	fzf.fzf_exec(cd_history, {
		prompt = "CD History> ",
		actions = {
			["default"] = function(selected)
				vim.cmd("cd" .. selected[1])
			end,
		},
	})
end

-- Command to invoke the CD history
function M.setup()
	load_history()
	vim.api.nvim_create_user_command("CdHistory", M.show_cd_history, { nargs = 0 })

	-- Hook into `DirChanged` event to update history
	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			add_to_history()
		end,
	})
end

return M
