--------------------------------------------------------------------------------
-- QAtlas
--------------------------------------------------------------------------------
QAtlas = {}
QAtlas.__index = QAtlas -- presumably we can point down a chain of inheritance?

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QAtlas.
This must be called immediately after the QAtlas() constructor.
*/
--]]
function QAtlas:initAtlas(l)
    local lp = {}
    setmetatable(lp, QAtlas)
    tolua.setpeer(l, lp)
    -- Add Lua variables below...

--[[    local mt = getmetatable(l)
    mt.__gc = function(self)
        director.runTextureCleanup = true
        self:delete()
    end
    ]]
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- See director:createAtlas() for factory function
