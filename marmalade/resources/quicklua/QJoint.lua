--------------------------------------------------------------------------------
-- joints
-- NOTE: This file must have no dependencies on the ones loaded after it by
-- openquick_init.lua. For example, it must have no dependencies on QDirector.lua
--------------------------------------------------------------------------------
if config.debug.mock_tolua == true then
	QJoint = quick.QJoint
else
	QJoint = {}
	QJoint.__index = QJoint -- presumably we can point down a chain of inheritance?
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QJoint.
This must be called immediately after the QJoint() constructor.
*/
--]]
function QJoint:initJoint(n)
	local np
	if not config.debug.mock_tolua == true then
		np = {}
		setmetatable(np, QJoint)
		tolua.setpeer(n, np)
	else
		np = n
	end
	--np.testProperty = 10
	--np.onlyLuaProperty = -1
	
end

--------------------------------------------------------------------------------
-- Unit tests
--------------------------------------------------------------------------------
function Joint_tests()
	print("Joint_tests")
end
