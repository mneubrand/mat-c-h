quick.lsqlite3.instantiate_lsqlite3_global()--loading and instantiating the whole lsqlite3 library 
sqlite3 = require("sqlite3")
--dbg.print("sqlite3 version = " ..sqlite3.version())

--[[
local lsql3instance = require("sqlite3")
dbg.print("sqlite3 version = " ..lsql3instance.version())
--]]
