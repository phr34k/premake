--
-- template.lua
-- The templating system.
-- Copyright (c) 2008 Jason Perkins and the Premake project
--
	

	premake.template = { }


--
-- Process a literal string, splitting up newlines so that the generated
-- code will match the original template line for line, so error messages
-- can refer to the correct line in the template. Lua's [[ ]] string syntax
-- messes with newlines, making this more complicated than it needs to be.
--

	local function literal(str)
		local code = ""
		
		for line in str:gmatch("[^\n]*") do
			if (line:len() > 0) then
				code = code .. "io.write[=[" .. line .. "]=]"
			else
				code = code .. "io.write(eol)\n"
			end
		end

		return code:sub(1, -15)
	end


--
-- Convert a template to Lua script code.
--

	function premake.template.encode(tmpl)
		code = ""
		
		-- normalize line endings
		tmpl = tmpl:gsub("\r\n", "\n")
		
		while (true) do
			-- find an escaped block
			start, finish = tmpl:find("<%%.-%%>")
			if (not start) then break end
		
			local before = tmpl:sub(1, start - 1)
			local after  = tmpl:sub(finish + 1)
		
			-- get the block type and contents
			local block
			local isexpr = (tmpl:sub(start + 2, start + 2) == "=")
			if (isexpr) then
				block = tmpl:sub(start + 3, finish - 2)
			else
				block = tmpl:sub(start + 2, finish - 2)
			end
		
			-- if a statement block, strip out everything else on that line
			if (not isexpr) then
				finish = before:findlast("\n", true)
				if (finish) then before = before:sub(1, finish) end
				
				start = after:find("\n", 1, true)
				if (start) then after = after:sub(start + 1) end
			end
						
			-- output everything before the block
			code = code .. literal(before)
			
			-- output the block itself
			if (isexpr) then
				code = code .. "io.write(" .. block .. ")"
			else
				code = code .. block .. "\n"
			end
		
			-- do it again, with everything after the block
			tmpl = after
		end	
			
		-- tack on everything after the last block
		code = code .. literal(tmpl)
		return code
	end
	

--
-- Generate output from a template, provided a filename and an object.
--

	function premake.template.generate(tmpl, fname, this)
		premake.template.newline = "\\n"
		
		local f, err = io.open(fname, "wb")
		if (not f) then
			error(err, 0)
		end
		
		io.output(f)
		tmpl(this)
		io.output():close()
	end
	
	
--
-- Load a template from a string and convert to a template function.
--

	function premake.template.loadstring(name, str)
		local code = premake.template.encode(str)
		local fn, msg = loadstring("return function (this) eol='\\n';" .. code .. " end", name)
		if (not fn) then
			error(msg, 0)
		end
		return fn()
	end


--
-- Load a template from a file and convert it to a template function.
--

	function premake.template.loadfile(fname)
		local f = io.open(fname, "rb")
		local tmpl = f:read("*a")
		f:close()
		return premake.template.loadstring(path.getname(fname), tmpl)
	end
	