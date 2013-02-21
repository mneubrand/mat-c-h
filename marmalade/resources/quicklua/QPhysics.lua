--------------------------------------------------------------------------------
-- Physics singleton
--------------------------------------------------------------------------------
physics = quick.QPhysics:new()

local oldNodePropsMTNI
if config.debug.mock_tolua == true then
	oldNodePropsMTNI = function(t, name, value) t.name = value end
else
	oldNodePropsMTNI = getmetatable(quick.QPhysics.NodeProps).__newindex
end
NodeProps_set = function(t, name, value)
    if name == "debugDrawColor" then
        prop_setColor(t.debugDrawColor, value)
    else
        oldNodePropsMTNI(t, name, value)
    end
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
--[[
/**
Add a node to the physics simulation, and potentially set physics properties of the node.
If the node is already part of the simulation, we simply set the physics properties.
Otherwise, we add the node to the simulation, and set any specified physics properties.
@param n The node to add to the physics simulation.
@param values Table of values to set as physics properties on the node.
*/
--]]
function physics:addNode(n, values)
    dbg.assertFuncVarType("userdata", n)
    dbg.assertFuncVarTypes({"table", "nil"}, values)

	self:_addNode(n)
	local isSensor = false
    if values then
	    table.setValuesFromTable(n.physics, values)

        -- Add shape points?
        if values.shape then
            dbg.assert(type(values.shape) == "table")
            for i = 1,#values.shape,2 do
                n.physics:_addShapePoint(values.shape[i+0], values.shape[i+1])
            end
        end
		if(values.isSensor) then
			isSensor = true
		end
    end

    -- Initialise NodeProps
    -- Allow explicit control over assignment... see above
	if config.debug.mock_tolua == false then
		getmetatable(n.physics).__newindex = NodeProps_set
	end
--	dbg.print("physics:addNode calling C++ init...")
	n.physics:_init(isSensor)
--	dbg.print("physics:addNode calling C++ init... done")
end

--[[
/**
Remove a node from the physics simulation.
All physics properties are lost.
If the node is not currently part of the simulation, the function has no effect.
@param n The node to remove from the physics simulation.
*/
--]]
function physics:removeNode(n)
    dbg.assertFuncVarType("userdata", n)
	n.physics = nil -- Lua GC should sort it out!
end

