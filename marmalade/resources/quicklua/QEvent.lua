--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

QEvent = {}

-- Static event objects
-- For these types, we assume that no listener will generate an event of the same type, so a singleton pattern is OK
QEvent.statics = {
    update = { name="update", time=0, system=1 },
    touch = { name="touch", time=0, phase="", x=0, y=0, id=0 },
    accelerometer = { name="accelerometer", time=0, phase="", x=0, y=0, z=0 },
    key = { name="key", time=0, phase="", keyCode=0 },
    anim = { name="anim", time=0, phase="", target=0, loopsleft=0 },
    timer = { name="timer", time=0, doneIterations=0 },
}

-- This function creates a NEW event object (table)
function QEvent:create( _name, params)
    dbg.assertFuncVarTypes({"string", "nil"}, _name)
    dbg.assertFuncVarTypes({"table", "nil"}, params)
    
    local ob = { name = _name }
    table.setValuesFromTable( ob, params)
    return ob
end

-- This function tries to REUSE an existing event object (table)
function QEvent:recreate(_name, params)
    local event = self.statics[_name]
    if event then
        if _name == "touch" then
            event.target = nil
        end
        event.time = system:getTime() * 1000
        table.setValuesFromTable( event, params)
        return event
    else
        return self:create(_name, params)
    end
end

if config.debug.mock_tolua == true then
	QEventListener = quick.QEventListener
else
    QEventListener = {}
    QEventListener.__index = QEventListener
end

--[[
/*
Initialise the peer table for the C++ class QEventListener.
This must be called immediately after the QEventListener() constructor.
*/
--]]
function QEventListener:initEventListener(n, _name, _funcortable)
    dbg.assertFuncVarTypes({"userdata", "string"}, n, _name)
    dbg.assertFuncVarTypes({"function", "table", "userdata"}, _funcortable)

    local np
	if not config.debug.mock_tolua == true then
        np = {}
        setmetatable(np, QEventListener)
        tolua.setpeer(n, np)
    else
        np = n
    end
	np.name = _name
	if type(_funcortable) == "function" then
		np.func = _funcortable
		np.table = nil
	else
        if type(_funcortable) == "userdata" then
    		np.table = _funcortable
        else
    		dbg.assert(type(_funcortable) == "table", "Input is of type " .. type(_funcortable) .. ", expected table")
    		np.table = _funcortable
        end
		dbg.assert(np.table[_name], "Listener table does not contain function named " .. _name)
		np.func = nil
	end
end

-- Generic function to pass an event object to a SPECIFIC listener (func or table)
-- This is the only function that actually calls the listener function
function handleEventWithListener(event, listener)
    dbg.assertFuncVarTypes({"table", "userdata"}, event, listener)

    local result = false

	if listener.func then
        -- Listener is a function: pass event to function
		result = listener.func(event)
	elseif listener.table then
        -- Listener is a table: check for table index with same name as event
        if listener.table[event.name] then
			result = listener.table[event.name](listener.table, event)
        end
	end
	return result
end

-- Generic function to pass an event object to a list of listeners (funcs or tables)
-- Note that ALL listeners matching the event name will be called, even if one of them returns true
function handleEventWithListeners(event, listeners)
    dbg.assertFuncVarTypes({"table", "table"}, event, listeners)

    local ret_val = false
    if listeners then
        local listener_list = listeners[event.name]
        if listener_list then
            for i,listener in pairs(listener_list) do
                if handleEventWithListener(event, listener) == true then
                    ret_val = true
                end
            end
	    end
    end

	return ret_val
end
