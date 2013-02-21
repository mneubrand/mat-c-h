--------------------------------------------------------------------------------
-- Labels
--------------------------------------------------------------------------------
QLabel = {}
QLabel.__index = QNode -- presumably we can point down a chain of inheritance?

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QNode.
This must be called immediately after the QNode() constructor.
*/
--]]
function QLabel:initLabel(l)
    local lp = {}
    setmetatable(lp, QLabel)
    tolua.setpeer(l, lp)
    -- Add Lua variables below...
--    lp.foo = "bar"
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- See director:createLabel() for factory function

