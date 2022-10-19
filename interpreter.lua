-- the idea is to make a drop-in interpreter for any preexisting Lua environment
local table = require 'ext.table'

local function printargs(...)
	if select('#', ...) > 0 then print(...) end
end

local function dynamic(k, ...)
	local writing = select('#', ...) > 0
	local v = ...
	-- level 3 is this
	-- level 4 is __index of the metatable
	-- level 5 is the xpcall function
	-- level 6 is the run() function
	-- I might've missed one in there ...
	for level = 2,math.huge do
		if not debug.getinfo(level) then break end
		for loc=1,math.huge do
			local k2,v2 = debug.getlocal(level, loc)
			if not k2 then break end
			if k2 == k then
				if writing then
					debug.setlocal(level, loc, v)
				end
				return v2
			end
		end
	end
end

--[[
builtin functions:
	__cont() = continues execution outside of the interpreter
--]]
local function run(env)
	-- add some env functions
	local done
	env = table(env or (getfenv and getfenv() or _ENV))
	function env.__cont() done = true end
	local fenv = setmetatable({}, {
		__index = function(t,k)
			-- try for a dynamic local first
			local dynv = dynamic(k)
			if dynv ~= nil then return dynv end
			
			local envv = env[k]
			if envv ~= nil then return envv end
		end,
	
		__newindex = function(t,k,v)
			-- write to a local?
			local oldv = dynamic(k,v)
			if oldv ~= nil then return end
			
			-- write to the external env table?
			if env[k] ~= nil then
				env[k] = v
				return
			end
			
			-- write to the local env table
			rawset(t,k,v)
		end,
	})
	print(_VERSION..' interpreter')
	while not done do
		io.write'> '
		local l = io.read'*l'
		l = l:gsub('^=', 'return ')
		
		-- TODO first try with 'return ' inserted, and if it works then print the results
		-- also TODO if an error happens, see if it is multi-line ...
		-- but in the lua interperter C code, it depends on load() returning LUA_ERRSYNTAX ... but does the Lua side get to see this?

		local f, err = load(l, nil, nil, fenv)
		if not f then
			io.stderr:write(err, '\n')
		else
			xpcall(function()
				printargs(f())
			end, function(err)
				io.stderr:write(err, '\n', debug.traceback(), '\n')
			end)
		end
	end
	print('quitting interpreter')
end

return run
