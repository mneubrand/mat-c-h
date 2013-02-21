--------------------------------------------------------------------------------
-- Fonts
--------------------------------------------------------------------------------
QFont = {}
QFont.__index = QFont -- presumably we can point down a chain of inheritance?

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QNode.
This must be called immediately after the QNode() constructor.
*/
--]]
function QFont:initFont(l)
    local lp = {}
    setmetatable(lp, QFont)
    tolua.setpeer(l, lp)
    -- Add Lua variables below...
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- See director:createFont() for factory function
