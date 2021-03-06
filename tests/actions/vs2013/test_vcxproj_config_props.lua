---
-- tests/actions/vs2013/test_vcxproj_config_props.lua
-- Check the VC2013 extensions to the configuration properties block.
-- Copyright (c) 2013 Jason Perkins and the Premake project
---

	local suite = test.declare("vs2013_vcxproj_config_props")
	local vc2010 = premake.vstudio.vc2010
	local project = premake.project


---
-- Setup
---

	local sln, prj

	function suite.setup()
		_ACTION = "vs2013"
		sln, prj = test.createsolution()
	end

	local function prepare()
		local cfg = test.getconfig(prj, "Debug")
		vc2010.configurationProperties(cfg)
	end


---
-- Visual Studio 2013 adds a new <PlatformToolset> element.
---

	function suite.addsPlatformToolset()
		prepare()
		test.capture [[
	<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'" Label="Configuration">
		<ConfigurationType>Application</ConfigurationType>
		<UseDebugLibraries>false</UseDebugLibraries>
		<CharacterSet>MultiByte</CharacterSet>
		<PlatformToolset>v120</PlatformToolset>
	</PropertyGroup>
		]]
	end
