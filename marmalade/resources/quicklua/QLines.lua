--------------------------------------------------------------------------------
-- Lines
-- NOTE: This file must have no dependencies on the ones loaded after it by
-- openquick_init.lua. For example, it must have no dependencies on QDirector.lua
--------------------------------------------------------------------------------
if config.debug.mock_tolua == true then
	QLines = quick.QLines
else
	QLines = {}
    table.setValuesFromTable(QLines, QVector) -- previous class in hierarchy
	QLines.__index = QLines
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QLines.
This must be called immediately after the QLines() constructor.
*/
--]]
function QLines:initLines(n)
	local np
	if not config.debug.mock_tolua == true then
	    local np = {}
        local ep = tolua.getpeer(n)
        table.setValuesFromTable(np, ep)
	    setmetatable(np, QLines)
	    tolua.setpeer(n, np)
	else
		np = n
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
--[[
/*
Append an array of points to the lines object.
The array is assumed to be x,y pairs, so must have an even number of entries.
*/
--]]
function QLines:append(coords)
    dbg.assertFuncVarType("table", coords)

    for i = 1,#coords,2 do
        self:_appendPoint(coords[i+0], coords[i+1])
    end
    self:_appendFinalise()
end
