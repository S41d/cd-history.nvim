local M = {}

local history_file = vim.fn.stdpath("data") .. "/cd_history.txt"
local cd_history = {}

local function replace_home_with_tilde(filepath)
	local home = vim.fn.expand("$HOME")
	local path, _ = string.gsub(filepath, "^" .. vim.pesc(home), "~")
	return path
end

M.notify = function(str, level)
	vim.notify(str, level or "info", { title = "CD History" })
end

-- Load history from file
M.load_history = function()
	local f = io.open(history_file, "r")
	if f then
		for line in f:lines() do
			table.insert(cd_history, 1, replace_home_with_tilde(line)) -- Insert at the start for recently visited order
		end
		f:close()
	else
		vim.notify("Couldn't open history file", vim.log.levels.ERROR, { title = "CD History" })
	end
end

M.get_cd_history = function()
	return cd_history
end

-- Save history to file
M.save_history = function()
	local f = io.open(history_file, "w")
	if f then
		for _, dir in ipairs(cd_history) do
			f:write(dir .. "\n")
		end
		f:close()
	end
end

-- Add the current directory to the history
M.add_to_history = function()
	local cwd = vim.fn.getcwd()
	cwd = replace_home_with_tilde(cwd)
	-- Remove cwd if it already exists in the list
	for i, dir in ipairs(cd_history) do
		if dir == cwd then
			table.remove(cd_history, i)
			break
		end
	end
	table.insert(cd_history, 1, cwd) -- Add to the start for most recent order
	M.save_history()
end

-- Add this function near the top with other utility functions
M.remove_from_history = function(dir)
	local confirm = vim.fn.input("Remove '" .. dir .. "' from history? [y/N] ")
	if confirm:lower() == "y" then
		for i, path in ipairs(cd_history) do
			if path == dir then
				table.remove(cd_history, i)
				M.save_history()
				vim.notify("Removed " .. dir .. " from history", vim.log.levels.INFO, { title = "CD History" })
				break
			end
		end
	end
end

return M
