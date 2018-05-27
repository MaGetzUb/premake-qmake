local p     = premake
local qmake = p.extensions.qmake

qmake.project = {}
local m       = qmake.project
m.configs     = {}

--
-- Generate a qmake project
--
function m.generate(prj)
	m.template(prj)

	for cfg in p.project.eachconfig(prj) do
		p.outln('')
		p.push('%s {', qmake.config(cfg))

		m.destdir(cfg)
		m.target(cfg)
		m.mocDir(cfg)
		m.rccDir(cfg)
		m.uiDir(cfg)

		m.qt(cfg)
		m.config(cfg)
		m.defines(cfg)

		m.forms(cfg)
		m.resources(cfg)
		m.headers(cfg)
		m.sources(cfg)

		m.includepath(cfg)
		m.libs(cfg)

		p.pop('}')
	end
end

--
-- Template
--
function m.template(prj)
	local templates = {
		['ConsoleApp']  = 'app',
		['WindowedApp'] = 'app',
		['SharedLib']   = 'lib',
		['StaticLib']   = 'lib',
	}
	p.w('TEMPLATE = %s', templates[prj.kind] or '')
end

--
-- Configs
--
m.configs.funcs = function(cfg)
	return {
		m.configs.kind,
		m.configs.rtti,
		m.configs.cppdialect,
	}
end

function m.configs.kind(cfg)
	local configs = {
		['ConsoleApp']  = 'console',
		['WindowedApp'] = 'windows',
		['SharedLib']   = 'shared',
		['StaticLib']   = 'static',
	}
	if configs[cfg.kind] then
		p.w(configs[cfg.kind])
	end
end

function m.configs.rtti(cfg)
	if cfg.rtti == "On" then
		p.w('rtti')
	elseif cfg.rtti == "Off" then
		p.w('rtti_off')
	end
end

function m.configs.cppdialect(cfg)
	local dialects = {
		["C++11"]   = "c++11",
		["C++14"]   = "c++14",
		["C++17"]   = "c++17",
		["gnu++11"] = "c++11",
		["gnu++14"] = "c++14",
		["gnu++17"] = "c++17",
	}
	if dialects[cfg.cppdialect] then
		p.w(dialects[cfg.cppdialect])
	end
end

--
-- Destination directory
--
function m.destdir(cfg)
	if cfg.targetdir then
		p.w('DESTDIR = %s', cfg.targetdir)
	end
end

--
-- Target
--
function m.target(cfg)
	if cfg.targetname then
		p.w('TARGET = %s', cfg.targetname)
	end
end

--
-- MOC directory
--
function m.mocDir(cfg)
	if cfg.objdir then
		p.w('MOC_DIR = "%s"', p.project.getrelative(cfg, cfg.objdir))
	end
end

--
-- RCC directory
--
function m.rccDir(cfg)
	if cfg.objdir then
		p.w('RCC_DIR = "%s"', p.project.getrelative(cfg, cfg.objdir))
	end
end

--
-- UI directory
--
function m.uiDir(cfg)
	if cfg.objdir then
		p.w('UI_DIR = "%s"', p.project.getrelative(cfg, cfg.objdir))
	end
end

--
-- Qt modules
--
function m.qt(cfg)
	if #cfg.qtmodules > 0 then
		qmake.pushVariable("QT")
		for _, qtmodule in ipairs(cfg.qtmodules) do
			p.w(qtmodule)
		end
		qmake.popVariable()
	end
end

--
-- Config
--
function m.config(cfg)
	p.eol(" \\\n")
	p.push('CONFIG +=')
	p.callArray(m.configs.funcs, cfg)
	p.pop()
	p.eol("\n")
	p.outln('')
end

--
-- Defines
--
function m.defines(cfg)
	if #cfg.defines > 0 then
		qmake.pushVariable("DEFINES")
		for _, define in ipairs(cfg.defines) do
			p.w(define)
		end
		qmake.popVariable()
	end
end

--
-- Files
--
function m.files(cfg, var, exts)
	local fconfigs = qmake.fileConfigs(cfg, exts)
	if #fconfigs > 0 then
		qmake.pushVariable(var)
		for _, fcfg in ipairs(fconfigs) do
			p.w(fcfg.path)
		end
		qmake.popVariable()
	end
end

function m.forms(cfg)
	m.files(cfg, "FORMS", {".ui"})
end

function m.resources(cfg)
	m.files(cfg, "RESOURCES", {".qrc"})
end

function m.headers(cfg)
	m.files(cfg, "HEADERS", {".h", ".hh", ".hpp", ".hxx", ".inl"})
end

function m.sources(cfg)
	m.files(cfg, "SOURCES", {".c", ".cc", ".cpp", ".cxx"})
end

--
-- Include path
--
function m.includepath(cfg)
	if #cfg.includedirs > 0 then
		qmake.pushVariable("INCLUDEPATH")
		for _, includedir in ipairs(cfg.includedirs) do
			p.w('"%s"', p.project.getrelative(cfg, includedir))
		end
		qmake.popVariable()
	end
end

--
-- Libs
--
function m.libs(cfg)
	local links

	local toolset = p.config.toolset(cfg)
	if toolset then
		links = toolset.getlinks(cfg)
	else
		links = p.config.getlinks(cfg)
	end

	if #links > 0 then
		qmake.pushVariable("LIBS")
		for _, link in ipairs(links) do
			p.w('"%s"', link)
		end
		qmake.popVariable()
	end
end
