--------------------------------------------------------------------------------
-- Scene
-- NOTE: This file must have no dependencies on the ones loaded after it by
-- openquick_init.lua. For example, it must have no dependencies on QDirector.lua
--------------------------------------------------------------------------------
if config.debug.mock_tolua == true then
	QScene = quick.QScene
else
	QScene = {}
    table.setValuesFromTable(QScene, QNode) -- previous class in hierarchy
	QScene.__index = QScene
end


--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QScene.
This must be called immediately after the QScene() constructor.
*/
--]]
function QScene:initScene(n)
	local np
	if not config.debug.mock_tolua == true then
	    local np = {}
        local ep = tolua.getpeer(n)
        table.setValuesFromTable(np, ep)
	    setmetatable(np, QScene)
	    tolua.setpeer(n, np)

--[[        local mt = getmetatable(n)
        mt.__gc = function(self)
            for i,v in ipairs(director.sceneList) do
                if v == self then
                    table.remove(director.sceneList,i)
                    break
                end
            end
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
function QScene:play(n)
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

