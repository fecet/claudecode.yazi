-- claudecode.yazi plugin
-- Copy selected files as @relative_path format for Claude projects

-- Function to get selected files or hovered file
local selected_or_hovered = ya.sync(function()
	local tab, paths = cx.active, {}
	for _, u in pairs(tab.selected) do
		paths[#paths + 1] = tostring(u)
	end
	if #paths == 0 and tab.current.hovered then
		paths[1] = tostring(tab.current.hovered.url)
	end
	return paths
end)

-- Function to get current working directory from yazi context
local get_current_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

-- Function to find project root by looking for .git or .claude directories
local function find_project_root(start_path)
	local current_path = start_path or get_current_cwd()

	-- Normalize path (remove trailing slash)
	current_path = current_path:gsub("/$", "")
	if current_path == "" then
		current_path = "/"
	end

	while current_path and current_path ~= "/" and current_path ~= "" do
		-- Check for .git directory or file (for git worktrees)
		local git_url = Url(current_path .. "/.git")
		local git_cha = fs.cha(git_url)
		if git_cha then
			return current_path
		end

		-- Check for .claude directory
		local claude_url = Url(current_path .. "/.claude")
		local claude_cha = fs.cha(claude_url)
		if claude_cha and claude_cha.is_dir then
			return current_path
		end

		-- Move up one directory
		local parent = current_path:match("(.+)/[^/]*$")
		if not parent or parent == current_path then
			break
		end
		current_path = parent
	end

	return nil
end

-- Function to get relative path from project root
local function get_relative_path(file_path, project_root)
	if not project_root or not file_path then
		return file_path or ""
	end

	-- Normalize both paths (remove trailing slashes)
	local normalized_root = project_root:gsub("/$", "")
	local normalized_file = file_path:gsub("/$", "")

	-- If file path is exactly the project root, return "."
	if normalized_file == normalized_root then
		return "."
	end

	-- Escape special regex characters in project root path
	local escaped_root = normalized_root:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")

	-- Remove project root prefix
	local relative = normalized_file:gsub("^" .. escaped_root, "")

	-- Remove leading slash if present
	relative = relative:gsub("^/", "")

	-- If relative path is empty, it means the file is in the project root
	if relative == "" then
		-- Extract just the filename
		relative = normalized_file:match("[^/]*$") or ""
	end

	return relative
end

-- Function to copy text to clipboard
local function copy_to_clipboard(text)
	local success = false

	-- Try different clipboard commands based on the system
	if ya.target_family() == "unix" then
		-- Try wl-copy (Wayland)
		local wl_copy = io.popen("command -v wl-copy 2>/dev/null"):read("*a")
		if wl_copy and wl_copy ~= "" then
			local cmd = io.popen("wl-copy", "w")
			if cmd then
				cmd:write(text)
				local close_result = cmd:close()
				success = close_result == true
			end
		end

		-- Try xclip (X11) if wl-copy failed
		if not success then
			local xclip = io.popen("command -v xclip 2>/dev/null"):read("*a")
			if xclip and xclip ~= "" then
				local cmd = io.popen("xclip -selection clipboard", "w")
				if cmd then
					cmd:write(text)
					local close_result = cmd:close()
					success = close_result == true
				end
			end
		end

		-- Try pbcopy (macOS) if others failed
		if not success then
			local pbcopy = io.popen("command -v pbcopy 2>/dev/null"):read("*a")
			if pbcopy and pbcopy ~= "" then
				local cmd = io.popen("pbcopy", "w")
				if cmd then
					cmd:write(text)
					local close_result = cmd:close()
					success = close_result == true
				end
			end
		end
	elseif ya.target_family() == "windows" then
		-- Windows clipboard using PowerShell
		local cmd = string.format("powershell -Command \"Set-Clipboard -Value '%s'\"", text:gsub("'", "''"))
		success = os.execute(cmd) == 0
	end

	return success
end

return {
	entry = function()
		-- Exit visual mode
		ya.emit("escape", { visual = true })

		-- Get selected or hovered files
		local file_paths = selected_or_hovered()

		if #file_paths == 0 then
			return ya.notify({
				title = "Claude Code",
				content = "No file selected",
				level = "warn",
				timeout = 5,
			})
		end

		-- Find project root starting from current working directory
		local project_root = find_project_root()

		if not project_root then
			local current_cwd = get_current_cwd()
			return ya.notify({
				title = "Claude Code",
				content = "No .git or .claude directory found in parent directories of " .. current_cwd,
				level = "warn",
				timeout = 5,
			})
		end

		-- Convert file paths to @relative_path format
		local claude_paths = {}
		for _, file_path in ipairs(file_paths) do
			local relative_path = get_relative_path(file_path, project_root)
			table.insert(claude_paths, "@" .. relative_path)
		end

		-- Join paths with spaces
		local result = table.concat(claude_paths, " ")

		-- Copy to clipboard
		local success = copy_to_clipboard(result)

		if success then
			ya.notify({
				title = "Claude Code",
				content = string.format("Copied %d file(s) as Claude paths: %s", #file_paths, result),
				level = "info",
				timeout = 5,
			})
		else
			ya.notify({
				title = "Claude Code",
				content = "Failed to copy to clipboard",
				level = "error",
				timeout = 5,
			})
		end
	end,
}
