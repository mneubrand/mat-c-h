-- dbg

dbg = {}
dbg.DEBUG = config.debug.general
dbg.TYPECHECKING = config.debug.typechecking
dbg.ASSERTDIALOGS = config.debug.assertDialogs

-- Remap "print" to always end with a return, and to flush our output.txt file
_print = print
print = function(...)
--    quick.MainPrint(... .. "\r")
    _print(... .. "\r")
end

-- Print
dbg.print = function(...)
	if (dbg.DEBUG == true) then
		print(...)
	end
end

-- Simple logging
dbg.log = function(msg)
    dbg.print("QUICKLUA LOG: " .. msg)
end

-- Assert
-- From http://lua-users.org/wiki/OptimisationCodingTips
dbg.assert = function(condition, ...)
    if dbg.DEBUG == true then
        if not condition then
            if next({...}) then
                local s,r = pcall(function (...) return(string.format(...)) end, ...)
                if s then
                    if dbg.ASSERTDIALOGS == true then
--                        dbg.print("TAG 1")
--                        dbg.traceback()
                        error(r .. "\r\n" .. dbg.getProcessedCallstack(), 2)
                    else
--                        dbg.print("TAG 2")
--                        dbg.traceback()
                        dbg.print("QUICKLUA ERROR: " .. r .. "\r\n" .. dbg.getProcessedCallstack())
                    end
                end
                return
            elseif dbg.ASSERTDIALOGS == true then -- only condition was specific
--                dbg.print("TAG 3")
--                dbg.traceback()
                error(dbg.getProcessedCallstack(), 2)
            else
--                dbg.print("TAG 4")
--                dbg.traceback()
                dbg.print("QUICKLUA ERROR: " .. dbg.getProcessedCallstack())
            end
        end
    end
end

-- Warning
dbg.warning = function(condition, ...)
    if dbg.DEBUG == true then
        if not condition then
            if next({...}) then
                local s,r = pcall(function (...) return(string.format(...)) end, ...)
                if s then
                    dbg.print("QUICKLUA WARNING: " .. r)
                end
            else
                -- Only condition was specified
                dbg.print("QUICKLUA WARNING: ")
            end
        end
    end
end

-- Get filtered Lua error string
dbg.getProcessedError = function(v)
    local a, b, c, d
	if string.find(v, "[string \"f('", 1, true) then
        -- Because we load our Lua files into strings first, we embed the original filename within
        -- the first line of the string. This looks a bit messy when Lua then displays it back to us
        -- as part of any error message or stack trace. So here we clean it up
        local ss = string.sub(v, 11, -1) -- remove [string "f('
        a,b = string.find(ss, "');", 1, true)
        c,d = string.find(ss, "\"]:", 1, true)
        v = string.sub(ss, 1, b-1) .. ", line " .. string.sub(ss, d+1, -1)
	end
    return v
end

-- Get filtered Lua callstack
dbg.getProcessedCallstack = function()
    local cs = debug.traceback()
--    print(cs)

    local tin = {}
    for v in string.gmatch(cs, "%C+") do
	    table.insert(tin, v)
    end

    if tin[1] then
	    tin[1] = "Lua callstack:"
    end

    -- Process each line
    local tout = {}
    local a, b, c, d
    for i,v in ipairs(tin) do
	    -- Ignore line?
	    if string.find(v, "dbg.lua:", 1, true) or
		    string.find(v, "[C]:", 1, true) then
		    -- Ignore this line
	    else
		    -- Modify line?
		    if string.find(v, "[string \"f('", 1, true) then
                -- Because we load our Lua files into strings first, we embed the original filename within
                -- the first line of the string. This looks a bit messy when Lua then displays it back to us
                -- as part of any error message or stack trace. So here we clean it up
                local ss = string.sub(v, 11, -1) -- remove [string "f('
                a,b = string.find(ss, "');", 1, true)
                c,d = string.find(ss, "\"]:", 1, true)
                v = string.sub(ss, 1, b-1) .. ", line " .. string.sub(ss, d+1, -1)
		    end

		    -- Insert line
		    table.insert(tout, v)
	    end
    end
    if #tout < 2 then
        return ""
    end

    -- Concatenate
    cs = table.concat(tout, "\r\n")
    return cs
end

-- Print table, with recursion, only in DEBUG mode
local printedTables = {} -- use this to forbid circular table references!
dbg.printTable = function(t, indent)
	if (dbg.DEBUG == true) then
		if indent == nil then
			indent = ""
            printedTables = {}
		end
		dbg.print(indent .. "{")
		indent = indent .. "  "
		for i,v in pairs(t) do
			if type(v) == "table" then
				dbg.print(indent .. tostring(i) .. ":")
                if table.hasValue(printedTables, v) then
                    dbg.print("Circular reference! Will not print this table.")
                else
                    table.insert(printedTables, v)
				    indent = dbg.printTable(v, indent)
                end
			elseif type(v) == "string" then
				dbg.print(indent .. tostring(i) .. ": '" .. v .. "'")
			else
				dbg.print(indent .. tostring(i) .. ": " .. tostring(v))
			end
		end

	    indent = string.sub(indent, 1, string.len(indent)-2)
	    dbg.print(indent .. "}")

	end
	return indent
end

-- Print value, including table recursion, only in DEBUG mode
dbg.printValue = function(t)
	if (dbg.DEBUG == true) then
		if type(t) == "table" then
			dbg.printTable(t)
		else
			dbg.print(tostring(t))
		end
	end
end

-- Asserts if the object is NOT of the specified type
-- Pass in type as string, followed by object itself (e.g. dbg.assertFuncVarType("table", node))
dbg.assertFuncVarType = function(s, u)
    if dbg.TYPECHECKING == true then
        dbg.assert(type(u)==s, "Input 1 is of type " .. type(u) .. ", expected type " .. s)
    end
end

-- Asserts if the table of type strings does not match 1:1 with the list of inputs
-- Alternatively, if the table and input list are different sizes, we assume the table of type
-- strings are all possible matches for the FIRST input only (any other inputs are not checked)
dbg.assertFuncVarTypes = function(types, ...)
	if dbg.TYPECHECKING == true then
        local ins = {}
        local inSize = select('#',...)
        for i = 1,inSize do
            ins[i] = select(i, ...)
        end
        if #ins == #types then
            -- Size of "types" array is same as ... so assume they map 1:1
            for i,v in ipairs(ins) do
                dbg.assert(type(v)==types[i], "Input '" .. i .. "' is of type " .. type(v) .. ", expected type " .. types[i])
            end
        else
            -- Check ONLY ins[1], and assume "types" is all valid types for this input
            local ts = type(ins[1])
            for i,v in ipairs(types) do
                if v==ts then return end
            end
            dbg.assert(false, "Input is of illegal type: " .. ts)
        end
    end
end

-- Returns true if the userdata passed is the specified type
dbg.isUserDataType = function(u, t)
	if dbg.TYPECHECKING == true then
	    if type(u) == "userdata" and getmetatable(u) == debug.getregistry()[t] then
            return true
        else
            return false
        end
    end
end

-- Asserts if the object is NOT of the specified named tolua userdata type
-- Pass in type as string, followed by object itself (e.g. dbg.assertFuncVarType("table", node))
dbg.assertFuncUserDataType = function(s, u)
    if type(u) ~= "userdata" then
        dbg.assert(false, "Input is not of userdata type")
    else
        dbg.assert(dbg.isUserDataType(u, s), "Input is not of userdata type " .. s)
    end
end

--------------------------------------------------------------------------------
-- table: add functions to Lua's "table"
--------------------------------------------------------------------------------
-- Check if a table has a specified index
table.hasIndex = function(t, index)
	for i,v in pairs(t) do
		if (i == index) then
			return true
		end
	end
	return false
end

-- Check if a table has a specified value
table.hasValue = function(t, value)
	for i,v in pairs(t) do
		if (v == value) then
			return true
		end
	end
	return false
end

-- Set table values from a table of setter values
-- NOTE: WE OFTEN CALL THIS WITH T=USERDATA, I.E. PASSING IN OBJECTS CREATED THROUGH TOLUA.
-- THIS IS FINE PROVIDED WE DON'T TRY TO ITERATE OVER THE OBJECT VALUES USING pairs(). SO WE CAN'T CALL FUNCTIONS LIKE table.hasIndex
table.setValuesFromTable = function(t, s)
    if s == nil then return end
	for i,v in pairs(s) do
--		dbg.assert(table.hasIndex(t, i), "Trying to set table value at missing index: ", i)
        --dbg.print("i = " ..i ..", v = " ..v)
		t[i] = v
	end
end

-- Print types of arguments
table.printArgs = function(...)
	argt = {...}
	print("Num args: " .. table.maxn(argt))
	for i=1,table.maxn(argt) do
		print("Arg " .. i .. " is type " .. type(argt[i]))
	end
end

-- Remap "dofile" to our own version
-- THIS MUST BE THE LAST THING IN DBG.LUA
function dofile(file)
--    print("dofile: " .. file)
    
    -- Get a processed string version of the Lua file
    local s = quick.MainLuaLoadFile(file)
    
    -- Load string into a Lua chunk
    local f,r = loadstring(s)
--    local f = loadstring(s)

--    print("dofile: " .. file .. ", " .. tostring(f) .. ", " .. (r or ""))
    if tostring(f) == "nil" then
--        -- Error
        dbg.assert(false, "Failed to load Lua file '" .. file .. "', with error:\r\n" .. dbg.getProcessedError(r or ""))
        return nil
    else
        return f()
    end
end
-- Dummy required when Lua file preprocessing is used
function f(filename) end
