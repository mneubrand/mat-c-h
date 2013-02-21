--------------------------------------------------------------------------------
-- Rectangle
-- NOTE: This file must have no dependencies on the ones loaded after it by
-- openquick_init.lua. For example, it must have no dependencies on QDirector.lua
--------------------------------------------------------------------------------
if config.debug.mock_tolua == true then
	QRectangle = quick.QRectangle
else
	QRectangle = {}
    table.setValuesFromTable(QRectangle, QLines) -- previous class in hierarchy
	QRectangle.__index = QRectangle
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QRectangle.
This must be called immediately after the QRectangle() constructor.
*/
--]]
function QRectangle:initRectangle(n)
	local np
	if not config.debug.mock_tolua == true then
	    local np = {}
        local ep = tolua.getpeer(n)
        table.setValuesFromTable(np, ep)
	    setmetatable(np, QRectangle)
	    tolua.setpeer(n, np)
	else
		np = n
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
