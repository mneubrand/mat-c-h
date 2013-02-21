--------------------------------------------------------------------------------
-- QAnimation
--------------------------------------------------------------------------------
QAnimation = {}
QAnimation.__index = QAnimation -- presumably we can point down a chain of inheritance?

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QAnimation.
This must be called immediately after the QAnimation() constructor.
*/
--]]
function QAnimation:initAnimation(l)
    local lp = {}
    setmetatable(lp, QAnimation)
    tolua.setpeer(l, lp)
    -- Add Lua variables below...
--[[    local mt = getmetatable(l)
    mt.__gc = function(self)
        director.runTextureCleanup = true
        self:delete()
    end]]
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- See director:createAnimation() for factory function
