--------------------------------------------------------------------------------
-- Vector
-- NOTE: This file must have no dependencies on the ones loaded after it by
-- openquick_init.lua. For example, it must have no dependencies on QDirector.lua
--------------------------------------------------------------------------------
if config.debug.mock_tolua == true then
	QVector = quick.QVector
else
	QVector = {}
    table.setValuesFromTable(QVector, QNode) -- previous class in hierarchy
	QVector.__index = QVector
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QVector.
This must be called immediately after the QVector() constructor.
*/
--]]
function QVector:initVector(n)
	local np
	if not config.debug.mock_tolua == true then
	    local np = {}
        local ep = tolua.getpeer(n)
        table.setValuesFromTable(np, ep)
	    setmetatable(np, QVector)
	    tolua.setpeer(n, np)
	else
		np = n
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
