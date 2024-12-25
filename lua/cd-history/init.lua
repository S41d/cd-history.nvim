local core = require("cd-history.core")

---@class M
---@field setup fun(opts: Opts)
---@field show_cd_history fun()
---@field show_cd_history_fzf fun()
---@field show_cd_history_telescope fun()
---@field show_cd_history_vim_input fun()
---@field remove_from_history fun(dir: string)
---@field notify fun(str: string, level: string)
---@field load_history fun()
---@field save_history fun()
---@field get_cd_history fun()
---@field add_to_history fun()
---@field remove_from_history fun(dir: string)
local M = {}

local has_fzf, fzf = pcall(require, "fzf-lua")
local has_telescope, telescope = pcall(require, "telescope")
local actions = has_telescope and require("telescope.actions") or nil
local action_state = has_telescope and require("telescope.actions.state") or nil
local selector = "vim_input"

-- Show the directory history in fzf-lua
function M.show_cd_history_fzf()
	if not has_fzf then
		core.notify("FZF-Lua is not installed", "error")
		return
	end

	fzf.fzf_exec(core.get_cd_history(), {
		prompt = "CD History> ",
		actions = {
			["default"] = function(selected)
				vim.cmd("cd " .. selected[1])
			end,
			["ctrl-d"] = function(selected)
				core.remove_from_history(selected[1])
				M.show_cd_history_fzf() -- Refresh the list
			end,
		},
	})
end

-- Show the directory history in Telescope
function M.show_cd_history_telescope()
	if not has_telescope then
		core.notify("Telescope is not installed", "error")
		return
	end
	if not actions or not action_state then
		core.notify("Telescope actions not loaded", "error")
		return
	end

	local map = actions.set_map_function

	telescope.pickers
		.new({}, {
			prompt_title = "CD History",
			finder = telescope.finders.new_table({
				results = core.get_cd_history(),
			}),
			sorter = telescope.configs.generic_sorter({}),
			on_attach = function(prompt_bufnr)
				map("i", "<C-d>", function()
					local selection = action_state.get_selected_entry()
					if selection then
						actions.close(prompt_bufnr)
						core.remove_from_history(selection.value)
						-- Reopen telescope to refresh the list
						M.show_cd_history_telescope()
					end
				end)
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
	local cd_history = core.get_cd_history()
	if #cd_history == 0 then
		core.notify("No directories in history", "info")
		return
	end

	-- Create numbered list
	local choices = {}
	for i, dir in ipairs(cd_history) do
		table.insert(choices, string.format("%d. %s", i, dir))
	end

	local prompt = table.concat(choices, "\n")
	local choice = vim.fn.input("CD History:\n" .. prompt .. "\nEnter number: ")

	local num = tonumber(choice)
	if num and num >= 1 and num <= #cd_history then
		vim.cmd("cd " .. cd_history[num])
	else
		core.notify("Invalid selection", "error")
	end
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

---@class Opts
---@field selector string

--- setup CD history plugin
---@param opts Opts
function M.setup(opts)
	opts = opts or {}
	selector = opts.selector or "vim_input"
	core.load_history()
	vim.api.nvim_create_user_command("CdHistory", M.show_cd_history, { nargs = 0 })

	-- Hook into `DirChanged` event to update history
	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			core.add_to_history()
		end,
	})
end

return M
