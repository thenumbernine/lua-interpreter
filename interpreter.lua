-- the idea is to make a drop-in interpreter for any preexisting Lua environment
local table = require 'ext.table'

local function printargs(...)
	if select('#', ...) > 0 then print(...) end
end

-- hmm, all this function does is let me reference locals of calling functions.
-- why do I want that?
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
--DEBUG:print('at level', level,'writing', k, v)
					debug.setlocal(level, loc, v)
				end
--DEBUG:print('at level', level,'getting', k, v2)
				return v2
			end
		end
	end
end

--[[
builtin functions:
	__cont() = continues execution outside of the interpreter
--]]
local run = setmetatable({
	title = _VERSION..' interpreter',
}, {
__call = function(run, env)
	-- add some env functions
	local done
	--[[ why create and modify a new env table?
	env = table(env or (getfenv and getfenv() or _ENV))
	env._G = env
	function env.__cont() done = true end
	--]]
	-- [[ why not just use the original?
	env = env or _G
	--]]
	local fenv = setmetatable({}, {
		__index = function(t,k)
			--[[ try for a dynamic local first ... ?
			local dynv = dynamic(k)
			if dynv ~= nil then
--DEBUG:print('using a dynamic variable for', k)
				return dynv
			end
			--]]

			local envv = env[k]
			if envv ~= nil then
--DEBUG:print('using an env variable for', k)
				return envv
			end
		end,
		__newindex = function(t,k,v)
			--[[ write to a local ... ?
			local oldv = dynamic(k,v)
			if oldv ~= nil then return end
			--]]

			-- write to the external env table?
			if env[k] ~= nil then
				env[k] = v
				return
			end

			-- write to the local env table
			rawset(t,k,v)
		end,
	})
	print(run.title)
	while not done do
		io.write'> '
		local l = io.read'*l'
		l = l:gsub('^=', 'return ')

		-- first try with 'return ' inserted, and if it works then print the results
		local f, err
		xpcall(function()
			f, err = assert(load('return '..l, nil, nil, fenv))
		end, function(err)
		end)

		--[[
		also TODO if an error happens, see if it is multi-line ...
		but in the lua interperter C code, it depends on load() returning LUA_ERRSYNTAX ... but does the Lua side get to see this?
		llex.c:
			lexerror:
				save:
					"lexical element too long"
				luaX_syntaxerror:
					...
				inclinenumber:
					"chunk has too many lines"
				read_numeral:
					"malformed number"
				read_long_string:
					"unfinished long %s (starting at line %d)"
				esccheck:
					gethexa:
						"hexadecimal digit expected"
					readutf8esc:
						"missing '{'"
						"UTF-8 value too large"
						"missing '}'"
				readdecesc:
					"decimal escape too large"
				read_string:
					"unfinished string"
					"invalid long string delimiter"
					"invalid escape sequence"
		ldo.c:
			...
		lundump.c:
			...
		... so looks like there's no consistent message for ERRSYNTAX
		--]]
		if not f then
			f, err = load(l, nil, nil, fenv)
		end
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
end})

return run
