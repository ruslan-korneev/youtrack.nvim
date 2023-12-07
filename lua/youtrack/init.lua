local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local curl = require("plenary.curl")

local function fetch_issues(ext_config)
	-- Set up the request headers and URL
	local headers = {
		Accept = "application/json",
		Authorization = "Bearer " .. ext_config.token,
		["Cache-Control"] = "no-cache",
		["Content-Type"] = "application/json",
	}
	local url = ext_config.url .. "/api/issues"

	local page_size = 20
	local first_element = 0

	local query = "for: me #Unresolved "
	if ext_config.query ~= nil then
		query = ext_config.query
	end

	-- Set up the query parameters
	local params = {
		query = query,
		fields = "id,idReadable,summary,description,project(name),customFields(name,value(name))",
		["$top"] = tostring(page_size),
		["$skip"] = tostring(first_element),
	}

	local entries = {}
	repeat
		-- Make the HTTP request using plenary.curl
		local res = curl.get(url, {
			headers = headers,
			query = params,
		})
		local body = res.body
		-- Parse the response body as JSON
		issues = vim.fn.json_decode(body)

		-- Return the list of entries
		for _, issue in ipairs(issues) do
			local entry = {
				summary = issue.summary,
				description = issue.description,
				idReadable = issue.idReadable,
				project = issue.project,
			}
			for _, customField in ipairs(issue.customFields) do
				if customField.name == "Type" then
					entry.type = customField.value.name
				elseif customField.name == "Assignee" then
					entry.assignee = customField.value.name
				elseif customField.name == "Priority" then
					entry.priority = customField.value.name
				elseif customField.name == "State" or customField.name == "Stage" then
					entry.state = customField.value.name
				elseif customField.name == "Sprints" then
					local sprints = {}
					for _, sprint in ipairs(customField.value) do
						table.insert(sprints, sprint.name)
					end
					entry.sprints = sprints
				end
			end
			table.insert(entries, entry)
		end

		first_element = first_element + page_size
		params["$skip"] = tostring(first_element)

	until #issues <= 0
	return entries
end

function split_string(str)
	local res = {}
	local i = 1
	while i <= #str do
		local j = i + 59 -- start with a substring of length 20
		if j > #str then -- if substring is longer than the string, set j to the end
			j = #str
		else
			-- if the substring is not at the end of a word, move j backwards until it is
			while j > i and str:sub(j, j) ~= " " do
				j = j - 1
			end
		end
		table.insert(res, str:sub(i, j)) -- add the substring to the result table
		i = j + 1 -- move i to the start of the next substring
	end
	return res
end

local function my_previewer(opts)
	-- Define the previewer text
	-- Return a previewer object with the previewer text
	return previewers.new_buffer_previewer({
		title = "Issues",
		get_buffer_by_name = function(_, entry)
			return entry.value[1]
		end,
		define_preview = function(self, entry, status)
			local description = entry.value.description
			if description == vim.NIL then
				description = "No Description"
			end
			if entry.value.sprints == nil then
				entry.value.sprints = {}
			end
			-- print(vim.inspect(split_string(description)))
			local lines = {
				string.format("Project: %s", entry.value.project.name),
				string.format("Sprint: %s", table.concat(entry.value.sprints, ", ")),
        string.format("Id: %s", entry.value.idReadable),
				string.format("Type: %s", entry.value.type),
				string.format("State: %s", entry.value.state),
				string.format("Priority: %s", entry.value.priority),
				string.format("Assignee: %s", entry.value.assignee),
				"",
				string.format("Summary: %s", entry.value.summary),
				"----------------",
				unpack(split_string(description)),
			}
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
			require("telescope.previewers.utils").regex_highlighter(self.state.bufnr, "youtracktelescope")
		end,
	})
end

-- our picker function: colors
local M = {}
M.issues = function(opts, ext_config)
	-- print("called M.issues")
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Issues",
			finder = finders.new_table({
				results = fetch_issues(ext_config),
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.summary,
						ordinal = string.format("[%s] %s", entry.summary, entry.description),
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			previewer = my_previewer(),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					if selection ~= nil then
						actions.close(prompt_bufnr)
						vim.api.nvim_put({ selection.value.idReadable }, "", false, true)
						if opts.insert_mode == true then
							vim.cmd([[normal! a ]]) -- add empty space so the cursor respects the indent
						end
					end
				end)
				-- Return true to indicate that we've modified the key mappings
				return true
			end,
		})
		:find()
end
return M
