--
-- tests/actions/vs2012/test_csproj_project_props.lua
-- Check Visual Studio 2012 extensions to the project properties block.
-- Copyright (c) 2013 Jason Perkins and the Premake project
--

	local suite = test.declare("vs2012_csproj_project_props")
	local cs2005 = premake.vstudio.cs2005


--
-- Setup
--

	local sln, prj

	function suite.setup()
		_ACTION = "vs2012"
		sln = test.createsolution()
		language "C#"
	end

	local function prepare()
		prj = premake.solution.getproject(sln, 1)
		cs2005.projectProperties(prj)
	end


---
-- Visual Studio 2012 omits ProductVersion and SchemaVersion.
---

	function suite.onDefaultProps()
		prepare()
		test.capture [[
	<PropertyGroup>
		<Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
		<Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
		<ProjectGuid>{42B5DBC6-AE1F-903D-F75D-41E363076E92}</ProjectGuid>
		<OutputType>Exe</OutputType>
		<AppDesignerFolder>Properties</AppDesignerFolder>
		<RootNamespace>MyProject</RootNamespace>
		<AssemblyName>MyProject</AssemblyName>
		<TargetFrameworkVersion>v4.5</TargetFrameworkVersion>
		<FileAlignment>512</FileAlignment>
	</PropertyGroup>
		]]
	end
