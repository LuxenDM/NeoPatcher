require('iuplua')
--local lfs = require('lfs')

local lua_license = [[
Lua version 5.1
Copyright 1994-2023 Lua.org, PUC-Rio.
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local iup_license = [[
IUP - Portable User Interface Version 3.30
Copyright 1994-2020 Tecgraf/PUC-Rio.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local lfs_license = [[
LuaFileSystem v1.8.0
Copyright 2003-2010 Kepler Project.
Copyright 2010-2022 The LuaFileSystem authors.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local function init_inifile()
	local inifile = {
		_VERSION = "inifile 1.0",
		_DESCRIPTION = "Inifile is a simple, complete ini parser for lua",
		_URL = "http://docs.bartbes.com/inifile",
		_LICENSE = [[
inifile library v1.0
Copyright 2011-2015 Bart van Strien. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY BART VAN STRIEN ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL BART VAN STRIEN OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the authors and should not be interpreted as representing official policies, either expressed or implied, of Bart van Strien.
]] -- The above license is known as the Simplified BSD license.
	}

	local defaultBackend = "io"

	local backends = {
		io = {
			lines = function(name) return assert(io.open(name)):lines() end,
			write = function(name, contents) assert(io.open(name, "w")):write(contents) end,
		},
		memory = {
			lines = function(text) return text:gmatch("([^\r\n]+)\r?\n") end,
			write = function(name, contents) return contents end,
		},
	}

	if love then
		backends.love = {
			lines = love.filesystem.lines,
			write = function(name, contents) love.filesystem.write(name, contents) end,
		}
		defaultBackend = "love"
	end

	function inifile.parse(name, backend)
		backend = backend or defaultBackend
		local t = {}
		local section
		local comments = {}
		local sectionorder = {}
		local cursectionorder

		for line in backends[backend].lines(name) do

			-- Section headers
			local s = line:match("^%[([^%]]+)%]$")
			if s then
				section = s
				t[section] = t[section] or {}
				cursectionorder = {name = section}
				table.insert(sectionorder, cursectionorder)
			end

			-- Comments
			s = line:match("^;(.+)$")
			if s then
				local commentsection = section or comments
				comments[commentsection] = comments[commentsection] or {}
				table.insert(comments[commentsection], s)
			end

			-- Key-value pairs
			local key, value = line:match("^([%w_]+)%s-=%s-(.+)$")
			if tonumber(value) then value = tonumber(value) end
			if value == "true" then value = true end
			if value == "false" then value = false end
			if key and value ~= nil then
				t[section][key] = value
				table.insert(cursectionorder, key)
			end
		end

		-- Store our metadata in the __inifile field in the metatable
		return setmetatable(t, {
			__inifile = {
				comments = comments,
				sectionorder = sectionorder,
			}
		})
	end

	function inifile.save(name, t, backend)
		backend = backend or defaultBackend
		local contents = {}

		-- Get our metadata if it exists
		local metadata = getmetatable(t)
		local comments, sectionorder

		if metadata then metadata = metadata.__inifile end
		if metadata then
			comments = metadata.comments
			sectionorder = metadata.sectionorder
		end

		-- If there are comments before sections,
		-- write them out now
		if comments and comments[comments] then
			for i, v in ipairs(comments[comments]) do
				table.insert(contents, (";%s"):format(v))
			end
			table.insert(contents, "")
		end

		local function writevalue(section, key)
			local value = section[key]
			-- Discard if it doesn't exist (anymore)
			if value == nil then return end
			table.insert(contents, ("%s=%s"):format(key, tostring(value)))
		end

		local function writesection(section, order)
			local s = t[section]
			-- Discard if it doesn't exist (anymore)
			if not s then return end
			table.insert(contents, ("[%s]"):format(section))

			-- Write our comments out again, sadly we have only achieved
			-- section-accuracy so far
			if comments and comments[section] then
				for i, v in ipairs(comments[section]) do
					table.insert(contents, (";%s"):format(v))
				end
			end

			-- Write the key-value pairs with optional order
			local done = {}
			if order then
				for _, v in ipairs(order) do
					done[v] = true
					writevalue(s, v)
				end
			end
			for i, _ in pairs(s) do
				if not done[i] then
					writevalue(s, i)
				end
			end

			-- Newline after the section
			table.insert(contents, "")
		end

		-- Write the sections, with optional order
		local done = {}
		if sectionorder then
			for _, v in ipairs(sectionorder) do
				done[v.name] = true
				writesection(v.name, v)
			end
		end
		-- Write anything that wasn't ordered
		for i, _ in pairs(t) do
			if not done[i] then
				writesection(i)
			end
		end

		return backends[backend].write(name, table.concat(contents, "\n"))
	end

	return inifile

end

local ini = init_inifile()

cp = function(a) print(a) end

patcher_dir = lfs.currentdir()
default_mod_dir = "C:/Program Files (x86)/Vendetta Online/plugins/"
DBG = "NO"

local function wildcard_exists(dir, wild)
	local wild = "%." .. wild .. "$"
	for file in lfs.dir(dir) do
		if file:match(wild) then
			return true, file
		end
	end
	return false
end

local spickle
spickle = function(intable)
	local retstr = ""
	retstr = retstr .. "\n" .. tostring(intable) .. "{"
	for k, v in pairs(intable) do
		if type(v) == "table" then
			retstr = retstr .. "\n" .. tostring(k) .. " >> "
			if tostring(k) == "_G" or tostring(k) == "package" or tostring(k) == "iup" then
				retstr = retstr .. "\n(Nope)"
			else
				spickle(v)
			end
		else
			retstr = retstr .. "\n" .. tostring(k) .. " >> " .. tostring(v)
		end
	end
	
	return retstr
end

function declare(name, data)
	_G[name] = data
	cp("Declared " .. name .. " as " .. type(data) .. ":" .. tostring(_G[name]))
end

local function convert_folder_paths(instr)
	return string.gsub(instr, "\\", "/")
end

local fontsize = "12"
local function font(mod)
	return "Arial, " .. tostring(tonumber(fontsize) + (mod or 0))
end

if lfs.attributes("config.ini", "mode") == "file" then
	local config = ini.parse("config.ini").config
	if config then
		if config.fontsize then
			fontsize = config.fontsize
		end
		if config.default then
			default_mod_dir = config.default
		end
		if config.debug then
			DBG = config.debug
		end
	end
end

local x_max = 400
local y_max = 300

local readout = iup.text {
	multiline = "YES",
	size = "20x64",
	expand = "HORIZONTAL",
	value = "",
	readonly = "YES",
}

cp = function(instr, debug_flag)
	if debug_flag and DBG ~= "YES" then
		return
	end
	readout.value = readout.value .. "\n" .. tostring(instr)
	readout.caret = string.len(readout.value)
end

local function textframe(instr, scroll_override)
	return iup.multiline {
		value = instr,
		expand = "YES",
		font = font(),
		readonly = "YES",
		bgcolor = "240 240 240",
		scrollbar = not scroll_override and "NO" or "YES",
		border = not scroll_override and "NO" or "YES",
		wordwrap = "YES",
	}
end






local joblist = {}

local function get_root_folder(dir)
	dir = convert_folder_paths(tostring(dir))
	local last_slash_index = string.find(dir, "/[^/]*$") or 0
	local pre_folder = string.sub(dir, 1, last_slash_index)
	local root_folder = string.sub(dir, last_slash_index + 1)
	return pre_folder, root_folder
end

local function addjob(dir)
	local path, container = get_root_folder(dir)
	
	local job = {
		directory = convert_folder_paths(dir),
		original_root = container, --hidden during editing, used for backup
		id = string.lower(container) .. "_patched",
		version = "0 -patched",
		name = container,
		author = "unknown (made with NeoPatcher)",
		path = convert_folder_paths(dir) .. "/prerun.lua",
	}
	
	cp("Added job " .. job.directory)
	
	table.insert(joblist, job)
end

local function getjob(index)
	return joblist[index or 1]
end

local function setjob(index, data)
	if index > #joblist + 1 then
		index = #joblist + 1
	end
	
	if data and type(data) == "table" then
		if not joblist[index] then
			addjob(data)
		end
		for k, v in pairs(data) do
			joblist[index][k] = v
		end
		cp("Updated job " .. joblist[index].directory)
	else
		cp("Removing job " .. joblist[index].directory .. " from the joblist")
		table.remove(joblist, index)
	end
end

local function do_job(index)
	local job = joblist[index]
	cp("Processing job " .. job.directory)
	
	local ini_data = "[modreg]\ntype=patched\nid=" .. job.id .. "\nversion=" .. job.version .. "\nname=" .. job.name .. "\nauthor=" .. job.author
	
	local main_data = "local ini_path='plugins/" .. job.original_root .. "/registration.ini'" .. "\n\nif type(lib) == 'table' and lib[0] == 'LME' then\n	if not lib.is_exist(ini_path) then\n		lib.register(ini_path)\n	end\n	\n	if lib.is_ready(ini_path) then\n		lib.catch_block(ini_path, nil, function()\n			dofile(lib.find_file('plugins/" .. job.original_root .. "/core_patched.lua'))\n		end)\n	end\nelse\n	dofile('core_patched.lua')\nend"
	
	local function convert_folder_paths_back(instr)
		return string.gsub(instr, "/", "\\")
	end
	
	local function save_file(text, name, dir)
		dir = convert_folder_paths_back(dir)
		name = convert_folder_paths_back(name)
		local path = dir .. "\\" .. name
		
		cp("	svproc <text> to " .. path, true)
		
		local file = io.open(path, "w")
		if file then
			file:write(text)
			file:close()
		else
			cp("Error writing file " .. name)
			return false
		end
	end
	
	local function copy_file(name, source, dir, dest)
		local read_path = dir .. "\\" .. source
		if not dest then dest = dir end
		
		cp("	cpproc " .. name .. " from " .. read_path .. " to " .. dest, true)
		
		local read_file = io.open(read_path, "r")
		if not read_file then
			cp("Error reading file " .. source)
			return false
		end
		local read_content = read_file:read("*all")
		read_file:close()
		
		save_file(read_content, name, dest)
	end
	
	
	
	local function backup_dir(source_dir, destination_dir)
		cp("	making directory " .. patcher_dir .. "\\backup\\" .. destination_dir, true)
		lfs.mkdir(patcher_dir .. "\\backup")
		lfs.mkdir(patcher_dir .. "\\backup\\" .. destination_dir)
		
		for entry in lfs.dir(source_dir) do
			local attr = lfs.attributes(source_dir .. "\\" .. entry, "mode")
			if entry ~= "." and entry ~= ".." then
				cp("	bkproc " .. tostring(entry) .. ": " .. tostring(attr), true)
				if attr == "file" then
					copy_file(entry, entry, source_dir, patcher_dir .. "\\backup\\" .. destination_dir)
				elseif attr == "directory" then
					backup_dir(source_dir .. "\\" .. entry, destination_dir .. "\\" .. entry)
				end
			end
		end
	end
	
	cp("	backing up original mod...", true)
	--do backup
	
	backup_dir(job.directory, job.original_root)
	
	cp("	mirroring main to core_patched.lua", true)
	
	copy_file("core_patched.lua", "main.lua", job.directory .. "/")
	
	cp("	creating new main.lua", true)
	
	save_file(main_data, "main.lua", job.directory)
	--create new main.lua
	
	cp("	creating new registration file", true)
	
	save_file(ini_data, "registration.ini", job.directory)
	--create new registration.ini
	
	return true
end

local function addjobfolder(root_dir)
	for child in lfs.dir(root_dir) do
		if lfs.attributes(root_dir .. "/" .. child, "mode") == "directory" then
			if lfs.attributes(root_dir .. "/" .. child .. "/main.lua", "mode") == "file" then
				if not wildcard_exists(root_dir .. "/" .. child, "ini") then
					addjob(root_dir .. "/" .. child)
				else
					cp("skipping " .. child .. "; appears to be compatible already")
				end
			else
				cp("skipping " .. child .. "; does not appear to be a plugin (no main.lua)")
			end
		else
			cp("skipping " .. child .. "; not a directory")
		end
	end
end














local panel_list = {
	val = 1,
}
local panel_container = iup.zbox {
	expand = "YES",
}

local function next_button(name, panel_id)
	if not panel_id then
		panel_list.val = panel_list.val + 1
		panel_id = panel_list.val
	end
	return iup.button {
		title = name,
		font = font(),
		action = function()
			cp("advancing to frame " .. tostring(panel_id), true)
			panel_container.value = panel_list[panel_id]
			panel_list.val = panel_id
			if type(panel_list[panel_id].on_show) == "function" then
				panel_list[panel_id].on_show()
			end
		end,
	}
end

local function create_eula()
	local infpane = iup.vbox {
		iup.label {
			title = "License Agreement:",
			font = font(),
		},
		textframe([[
NeoPatcher
Copyright (c) 2023 Luxen De'Mark

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.]], true),
		iup.fill { },
		iup.hbox {
			iup.button {
				title = "View licenses of dependencies",
				font = font(),
				action = function()
					local license_view = iup.multiline {
						readonly = "YES",
						value = " ",
						size = "200x",
						wordwrap = "YES",
						expand = "YES",
						font = font(),
					}
					local lib_list = iup.list {
						action = function(self, t, i, c)
							if c == 1 then
								if t == "Lua" then
									license_view.value = lua_license
								elseif t == "LFS" then
									license_view.value = lfs_license
								elseif t == "IUP" then
									license_view.value = iup_license
								elseif t == "inifile" then
									license_view.value = ini._LICENSE
								else
									license_view.value = "?"
								end
							end
						end,
						font = font(),
						expand = "VERTICAL",
						size = "100x",
						[1] = "Lua",
						[2] = "IUP",
						[3] = "LFS",
						[4] = "inifile",
					}
					
					local diag = iup.dialog {
						topmost = "YES",
						size = "400x300",
						resize = "NO",
						title = "NeoPatcher dependency licenses",
						iup.vbox {
							iup.hbox {
								lib_list,
								license_view,
							},
							iup.hbox {
								iup.fill { },
								iup.button {
									font = font(),
									title = "Close",
									action = function(self)
										iup.GetDialog(self):hide()
									end,
								},
							},
						},
					}
					
					diag:popup(iup.CENTER, iup.CENTER)
				end,
			},
			iup.fill { },
			iup.button {
				title = "Don't Agree",
				font = font(),
				action = function()
					iup.Close()
				end,
			},
			next_button("Agree")
		},
	}
	
	table.insert(panel_list, infpane)
	iup.Append(panel_container, infpane)
end

local function create_infopane()
	local infpane = iup.vbox {
		on_show = function()
			joblist = {}
		end,
		textframe("NeoPatcher allows you to adjust your mods to be compatible with Neoloader or another LME provider. You can either pick a specific mod to patch, or automatically patch your entire modlist. Please select from an option below:"),
		iup.fill { },
		iup.hbox {
			iup.fill { },
			next_button("Patch a specific mod...", nil),
			next_button("Patch all mods", nil),
		},
	}
	
	table.insert(panel_list, infpane)
	iup.Append(panel_container, infpane)
end

local function create_selectmod()
	local select_folder_diag = iup.filedlg {
		title = "Select a mod to patch...",
		dialogtype = "DIR",
		directory = default_mod_dir,
	}
	
	local folder_path_view = iup.text {
		value = "",
		readonly = "YES",
		expand = "HORIZONTAL",
	}
	
	local go_next = next_button("Next...", 5)
	go_next.active = "NO"
	local go_action = go_next.action
	go_next.action = function(...)
		addjob(folder_path_view.value)
		go_action(...)
	end
	
	local infpane = iup.vbox {
		textframe("Select the mod you wish to patch below:"),
		iup.fill { },
		iup.hbox {
			iup.fill { },
			folder_path_view,
			iup.button {
				title = "Select mod folder",
				action = function()
					select_folder_diag:popup()
					local return_path = select_folder_diag.value
					if not return_path then
						return
					end
					local is_patched, ini_file = wildcard_exists(return_path, "ini")
					if is_patched then
						cp("NeoPatcher does not support importing mods that are already compatible with Neoloader. Please select a different mod to patch.")
						go_next.active = "NO"
					else
						folder_path_view.value = return_path
						go_next.active = "YES"
					end
				end,
			},
			iup.fill { },
		},
		iup.fill { },
		iup.hbox {
			next_button("Cancel", 2),
			iup.fill { },
			go_next,
		},
	}
	
	table.insert(panel_list, infpane)
	iup.Append(panel_container, infpane)
end

local function create_selectmultimod()
	local select_folder_diag = iup.filedlg {
		title = "Select the mod folder to scan...",
		dialogtype = "DIR",
		directory = "C:/Software Library/Vendetta Online/plugins/",
	}
	
	local folder_path_view = iup.text {
		value = "",
		readonly = "YES",
		expand = "HORIZONTAL",
	}
	
	local go_next = next_button("Next...", nil)
	go_next.active = "NO"
	local go_action = go_next.action
	go_next.action = function(...)
		addjobfolder(folder_path_view.value)
		go_action(...)
	end
	
	local infpane = iup.vbox {
		textframe("Select your game's mod folder or another folder of mods you wish to scan"),
		iup.fill { },
		iup.hbox {
			iup.fill { },
			folder_path_view,
			iup.button {
				title = "Select root folder",
				action = function()
					select_folder_diag:popup()
					if not select_folder_diag.value then
						return
					end
					folder_path_view.value = select_folder_diag.value
					go_next.active = "YES"
				end,
			},
			iup.fill { },
		},
		iup.fill { },
		iup.hbox {
			next_button("Cancel", 2),
			iup.fill { },
			go_next,
		},
	}
	
	table.insert(panel_list, infpane)
	iup.Append(panel_container, infpane)
end

local function create_job_manager()
	local edited_flag = "PRE"
	local dir_view = iup.text {
		value = "",
		readonly = "YES",
		expand = "HORIZONTAL",
		bgcolor = "192 192 192",
		active = "NO",
	}
	local dir_label = iup.label {
		title = "Mod Directory: ",
	}
	
	local id_view = iup.text {
		value = "",
		expand = "NO",
		action = function()
			edited_flag = "YES"
		end,
		active = "NO",
	}
	local id_label = iup.label {
		title = "Internal Name: ",
	}
	
	local ver_view = iup.text {
		value = "",
		expand = "NO",
		action = function()
			edited_flag = "YES"
		end,
		active = "NO",
	}
	local ver_label = iup.label {
		title = "Mod Version: ",
	}
	
	local name_view = iup.text {
		value = "",
		expand = "NO",
		action = function()
			edited_flag = "YES"
		end,
		active = "NO",
	}
	local name_label = iup.label {
		title = "Mod Name: ",
	}
	
	local author_view = iup.text {
		value = "",
		expand = "NO",
		action = function()
			edited_flag = "YES"
		end,
		active = "NO",
	}
	local author_label = iup.label {
		title = "Mod Author: ",
	}
	
	local pathdata = ""
	
	local selected_job_index = -1
	local list_max = 0
	local select_job = iup.list {
		expand = "VERTICAL",
		size = tostring(x_max / 3) .. "x100",
		action = function(self, t, i, c)
			if c == 1 then
				cp("edited flag is " .. edited_flag, true)
				if edited_flag == "YES" then
					setjob(selected_job_index, {
						directory = dir_view.value,
						id = id_view.value,
						version = ver_view.value,
						name = name_view.value,
						author = author_view.value,
						path = pathdata,
					})
				elseif edited_flag == "PRE" then
					dir_view.active = "YES"
					id_view.active = "YES"
					ver_view.active = "YES"
					name_view.active = "YES"
					author_view.active = "YES"
				end
				edited_flag = "NO"
				
				local job = getjob(i)
				
				dir_view.value = job.directory
				id_view.value = job.id
				ver_view.value = job.version
				name_view.value = job.name
				author_view.value = job.author
				selected_job_index = i
			end
		end,
	}
	
	for k, v in ipairs(joblist) do
		select_job[k] = v.name
	end
	
	local go_next = next_button("Begin Patching Process", 6)
	local old_action = go_next.action
	go_next.action = function(...)
		if edited_flag == "YES" then
			setjob(selected_job_index, {
				directory = dir_view.value,
				id = id_view.value,
				version = ver_view.value,
				name = name_view.value,
				author = author_view.value,
				path = pathdata,
			})
		end
		old_action(...)
	end
	
	local content = iup.vbox {
		iup.hbox {
			select_job,
			iup.vbox {
				iup.hbox {
					dir_label,
					iup.fill { },
					dir_view,
				},
				iup.hbox {
					id_label,
					iup.fill { },
					id_view,
				},
				iup.hbox {
					ver_label,
					iup.fill { },
					ver_view,
				},
				iup.hbox {
					name_label,
					iup.fill { },
					name_view,
				},
				iup.hbox {
					author_label,
					iup.fill { },
					author_view,
				},
			},
		},
		iup.hbox {
			next_button("Cancel", 2),
			next_button("Add another mod", 3),
			iup.fill { },
			go_next,
		},
	}
	
	local infpane
	infpane = iup.vbox {
		on_show = function()
			local dir_size = dir_view.size
			id_view.size = dir_size
			ver_view.size = dir_size
			name_view.size = dir_size
			author_view.size = dir_size
			iup.Refresh(infpane)
			
			for i=1, list_max do
				select_job[i] = nil
			end
			
			for k, v in ipairs(joblist) do
				select_job[k] = v.name
			end
			list_max = #joblist
		end,
		textframe("You can edit the details of your selected jobs here. If you do not know what these are, leave everything as their default values and go to the next frame"),
		content,
	}
	
	table.insert(panel_list, infpane)
	iup.Append(panel_container, infpane)
end

local function create_jobprocscreen()
	local progress = iup.progressbar {
		min = 0,
		max = 100,
		value = 0,
		expand = "HORIZONTAL",
	}
	
	local go_next = next_button("Next...", 7)
	go_next.active = "NO"
	
	local infpane = iup.vbox {
		on_show = function()
			progress.max = tostring(#joblist)
			local status
			for job_index in ipairs(joblist) do
				status = do_job(job_index)
				if not status then break end
				progress.value = job_index
			end
			progress.value = progress.max
			
			if status then
				cp("Patching process is complete!")
				go_next.active = "YES"
			else
				cp("There was an error while processing jobs. NeoPatcher has aborted further processing.")
			end
		end,
		textframe("Now patching your selected plugins..."),
		iup.fill { },
		progress,
		iup.fill { },
		iup.hbox {
			iup.fill { },
			go_next,
		},
	}
	
	table.insert(panel_list, infpane)
	iup.Append(panel_container, infpane)
end

local function create_finished()
	local infpane = iup.vbox {
		textframe("If there were any issues, or you are not happy with the created patches, backups of the mods are created in this tool's directory before processing begins.\n\nYou can now close NeoPatcher"),
		iup.fill { },
		iup.button {	
			title = "Close",
			font = font(),
			action = function()
				iup.Close()
			end,
		},
	}
	
	table.insert(panel_list, infpane)
	iup.Append(panel_container, infpane)
end










do --fill panel container here
	create_eula()
	create_infopane()
	create_selectmod()
	create_selectmultimod()
	create_job_manager()
	create_jobprocscreen()
	create_finished()
	
	
	panel_container.value = panel_list[1]
end

local function create_diag()
	local diag = iup.dialog {
		title = "NeoPatcher v2.1.0",
		size = tostring(x_max + 10) .. "x" .. tostring(y_max + 10),
		iup.vbox {
			iup.frame {
				bgcolor = "192 192 192",
				iup.hbox {
					iup.fill { },
					iup.label {
						title = "NeoPatcher",
						font = font(10),
					},
					iup.fill { },
				},
			},
			iup.fill {
				size = tostring(y_max * 0.02),
			},
			iup.hbox {
				iup.fill {
					size = tostring(y_max * 0.05),
				},
				panel_container,
				iup.fill {
					size = tostring(y_max * 0.05),
				},
			},
			iup.fill {
				size = tostring(y_max * 0.02),
			},
			readout,
		},
	}

	diag:map()
	diag:show()
end

create_diag()

cp("" .. tostring(_VERSION), true)
cp("IUP Version " .. tostring(iup.Version()), true)

cp("Working out of " .. patcher_dir, true)












iup.MainLoop()