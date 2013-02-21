--------------------------------------------------------------------------------
-- Circle
-- NOTE: This file must have no dependencies on the ones loaded after it by
-- openquick_init.lua. For example, it must have no dependencies on QDirector.lua
--------------------------------------------------------------------------------
if config.debug.mock_tolua == true then
	QCircle = quick.QCircle
else
	QCircle = {}
    table.setValuesFromTable(QCircle, QVector) -- previous class in hierarchy
	QCircle.__index = QCircle
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QCircle.
This must be called immediately after the QCircle() constructor.
*/
--]]
function QCircle:initCircle(n)
	local np
	if not config.debug.mock_tolua == true then
	    local np = {}
        local ep = tolua.getpeer(n)
        table.setValuesFromTable(np, ep)
	    setmetatable(np, QCircle)
	    tolua.setpeer(n, np)
	else
		np = n
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
