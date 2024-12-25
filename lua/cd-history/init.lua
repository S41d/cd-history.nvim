local M = {}

local fzf = require("fzf-lua")
local cd_history = {}

local function add_to_history()
	local cwd = vim.fn.getcwd()
	if #cd_history == 0 or cd_history[#cd_history] ~= cwd then
		table.insert(cd_history, cwd)
	end
end

-- Change to a selected directory
local function change_directory(selected_dir)
	if selected_dir and selected_dir ~= "" then
		vim.cmd("cd " .. selected_dir)
		add_to_history()
		print("Changed directory to: " .. selected_dir)
	end
end

-- Show the directory history in fzf-lua
function M.show_cd_history()
	add_to_history()
	fzf.fzf_exec(cd_history, {
		prompt = "CD History> ",
		actions = {
			["default"] = function(selected)
				change_directory(selected[1])
			end,
		},
	})
end

-- Command to invoke the CD history
function M.setup()
	vim.api.nvim_create_user_command("CdHistory", M.show_cd_history, { nargs = 0 })

	-- Hook into `DirChanged` event to update history
	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			add_to_history()
		end,
	})
end

return M
