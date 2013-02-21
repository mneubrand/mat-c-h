--------------------------------------------------------------------------------
-- Sprite
-- NOTE: This file must have no dependencies on the ones loaded after it by
-- openquick_init.lua. For example, it must have no dependencies on QDirector.lua
--------------------------------------------------------------------------------
if config.debug.mock_tolua == true then
	QSprite = quick.QSprite
else
	QSprite = {}
    table.setValuesFromTable(QSprite, QNode) -- previous class in hierarchy
	QSprite.__index = QSprite
end


--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QSprite.
This must be called immediately after the QSprite() constructor.
*/
--]]
function QSprite:initSprite(n)
	local np
	if not config.debug.mock_tolua == true then
	    local np = {}
        local ep = tolua.getpeer(n)
        table.setValuesFromTable(np, ep)
	    setmetatable(np, QSprite)
	    tolua.setpeer(n, np)

--[[        local mt = getmetatable(n)
        mt.__gc = function(self)
            director.runTextureCleanup = true
            self:delete()
        end
        ]]
	else
		np = n
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--[[
/*! Play the current assigned animation.
    @param n (optional) A table containing playback parameters
        startFrame (optional) = The first frame of the animation to play
        loopCount (optional) = The number of times to play the animation. 0 = infinate
*/
--]]
function QSprite:play(n)
	dbg.assertFuncVarTypes({"nil", "table"}, n)

    local startFrame = 1
    local loopCount = 0

    if type(n) == "table" then
        if n.startFrame ~= nil then
            startFrame = n.startFrame
        end
        if n.loopCount ~= nil then
            loopCount = n.loopCount
        end
    end

    self:_play( startFrame, loopCount)
end

