--
-- Embed the Lua scripts into src/host/scripts.c as static data buffers.
-- I embed the actual scripts, rather than Lua bytecodes, because the
-- bytecodes are not portable to different architectures, which causes
-- issues in Mac OS X Universal builds.
--

	-- remember where I live, so I can find the files I need
	local basedir = path.getdirectory(os.getcwd())

	local function stripfile(fname)
		local f = io.open(fname)
		local s = assert(f:read("*a"))
		f:close()

		-- strip tabs
		s = s:gsub("[\t]", "")

		-- strip any CRs
		s = s:gsub("[\r]", "")

		-- strip out block comments
		s = s:gsub("[^\"']%-%-%[%[.-%]%]", "")
		s = s:gsub("[^\"']%-%-%[=%[.-%]=%]", "")
		s = s:gsub("[^\"']%-%-%[==%[.-%]==%]", "")

		-- strip out inline comments
		s = s:gsub("\n%-%-[^\n]*", "\n")

		-- escape backslashes
		s = s:gsub("\\", "\\\\")

		-- strip duplicate line feeds
		s = s:gsub("\n+", "\n")

		-- strip out leading comments
		s = s:gsub("^%-%-[^\n]*\n", "")

		-- escape line feeds
		s = s:gsub("\n", "\\n")

		-- escape double quote marks
		s = s:gsub("\"", "\\\"")

		return s
	end


	local function writeline(out, s, continues)
		out:write("\t\"")
		out:write(s)
		out:write(iif(continues, "\"\n", "\",\n"))
	end


	local function writefile(out, fname, contents)
		local max = 1024

		out:write("\t/* " .. fname .. " */\n")

		-- break up large strings to fit in Visual Studio's string length limit
		local start = 1
		local len = contents:len()
		while start <= len do
			local n = len - start
			if n > max then n = max end
			local finish = start + n

			-- make sure I don't cut an escape sequence
			while contents:sub(finish, finish) == "\\" do
				finish = finish - 1
			end

			writeline(out, contents:sub(start, finish), finish < len)
			start = finish + 1
		end

		out:write("\n")
	end


	function doembed()

		-- Find and run the manifest file. Checks the normal search paths to
		-- allow for manifest and _premake_main customizations, then falls
		-- back to the canonical version at ../src if not found.

		local dir = os.pathsearch("_manifest.lua", _OPTIONS["scripts"], os.getenv("PREMAKE_PATH"))
		if not dir then
			dir = path.join(basedir, "src")
		end

		scripts = dofile(path.join(dir, "_manifest.lua"))

		-- Main script always goes first
		table.insert(scripts, 1, "_premake_main.lua")

		-- Embed all the scripts to a temporary file first
		local file = io.tmpfile()
		file:write("/* Premake's Lua scripts, as static data buffers for release mode builds */\n")
		file:write("/* DO NOT EDIT - this file is autogenerated - see BUILD.txt */\n")
		file:write("/* To regenerate this file, run: premake5 embed */ \n\n")
		file:write("const char* builtin_scripts[] = {\n")

		for i, fn in ipairs(scripts) do
			local s = stripfile(path.join(dir, fn))
			writefile(file, fn, s)
		end

		file:write("\t0\n};\n");

		-- Now read it back in and compare it to the current scripts.c; only
		-- write it out if changed.

		file:seek("set", 0)
		local newVersion = file:read("*a")
		file:close()

		local oldVersion
		local scriptsFile = path.join(basedir, "src/host/scripts.c")

		local file = io.open(scriptsFile, "r")
		if file then
			oldVersion = file:read("*a")
			file:close()
		end

		if newVersion ~= oldVersion then
			print("Writing scripts.c")
			file = io.open(scriptsFile, "w+b")
			file:write(newVersion)
			file:close()
		end

	end
