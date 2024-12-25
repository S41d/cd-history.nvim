local M = {}

local has_fzf, fzf = pcall(require, "fzf-lua")
local has_telescope, telescope = pcall(require, "telescope")
local actions = has_telescope and require("telescope.actions") or nil
local action_state = has_telescope and require("telescope.actions.state") or nil
local cd_history = {}
local history_file = vim.fn.stdpath("data") .. "/cd_history.txt"
local selector = "vim_input"

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
function M.show_cd_history_fzf()
	if not has_fzf then
		vim.notify("FZF-Lua is not installed", vim.log.levels.ERROR, { title = "CD History" })
		return
	end

	fzf.fzf_exec(cd_history, {
		prompt = "CD History> ",
		actions = {
			["default"] = function(selected)
				vim.cmd("cd " .. selected[1])
			end,
		},
	})
end

-- Show the directory history in Telescope
function M.show_cd_history_telescope()
	if not has_telescope then
		vim.notify("Telescope is not installed", vim.log.levels.ERROR, { title = "CD History" })
		return
	end
	assert(actions ~= nil, "Telescope actions not loaded")
	assert(action_state ~= nil, "Telescope action state not loaded")

	telescope.pickers
		.new({}, {
			prompt_title = "CD History",
			finder = telescope.finders.new_table({
				results = cd_history,
			}),
			sorter = telescope.configs.generic_sorter({}),
			on_attach = function(prompt_bufnr)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						vim.cmd("cd " .. selection.value)
					end
				end)
			end,
		})
		:find()
end

-- Show the directory history using Vim input
function M.show_cd_history_vim_input()
	if #cd_history == 0 then
		vim.notify("No directories in history", vim.log.levels.INFO, { title = "CD History" })
		return
	end

	local choices = table.concat(cd_history, "\n")
	local choice = vim.fn.input("CD History:\n" .. choices .. "\n> ")
	for _, dir in ipairs(cd_history) do
		if dir == choice then
			vim.cmd("cd " .. dir)
			return
		end
	end

	vim.notify("Invalid selection", vim.log.levels.ERROR, { title = "CD History" })
end

-- Show the directory history based on the preferred method
function M.show_cd_history()
	if selector == "fzflua" and has_fzf then
		M.show_cd_history_fzf()
	elseif selector == "telescope" and has_telescope then
		M.show_cd_history_telescope()
	else
		M.show_cd_history_vim_input()
	end
end

function M.setup(opts)
	opts = opts or {}
	selector = opts.selector or "vim_input"
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
