--[[
/**
Global object for Compass management.
After starting the service add a listener to the system events named "compassDegrees" and - or "compassVector" 
that are triggered when the compass data change.
*/
--]]
compass = {}

--[[
    /**
    If the service has started this method is called on every update by the system.
	It queries the Compass values and if any change is detected, the corresponding following events are triggered:
	triggeredEvent 
	{
		event.name = "compassDegrees"
		event.heading = number
	}
	
	triggeredEvent 
	{
		event.name = "compassVector" 
		event.heading = number
		event.x = number
		event.y = number
		event.z = number
	}
	@param event the system update event
    */
--]]
function compass:update(event)
	quick.QCompass:update()
end

--[[
    /**
    Gets the availability of the compass.
    @return true if the compass is supported, false otherwise
    */
--]]
function compass:isSupported()
	return quick.QCompass:isSupported()
end

--[[
    /**
    Gets the current compass reading.
    @return On success, an integer representing the current direction relative to magnetic north, -1 on failure. 
	This value is represented in degrees and so varies between 0 and 359. 
	The value is relative to the top of device in the current OS orientation. North, East, South and West are represented 
	by 0, 90, 180 and 270 respectively.
	A negative value means non valid reading.
    */
--]]
function compass:getHeadingDegrees()
	return quick.QCompass:getHeadingDegrees()
end

--[[
    /**
    Gets the current compass 3d-vector and heading.
    @return in order: true if successful or false otherwise,
	the heading of the compass vector, 
	the x value of the compass 3d-vector, 
	the y value of the compass 3d-vector, 
	the z value of the compass 3d-vector.
    */
--]]
function compass:getHeadingVector()
	return quick.QCompass:getHeadingVector()
end

--[[
    /**
    Starts the compass service.
    @return true on success, false otherwise.
    */
--]]
function compass:start()
	if(quick.QCompass:start()) then
		system:addEventListener("update", compass)
		return true
	end
	return false
end

--[[
    /**
    Stops the compass service.
    */
--]]
function compass:stop()
	system:removeEventListener("update", compass)
	return quick.QCompass:stop()
end

--[[
    /**
    Gets the status of the service.
    @return true if the service has started, false otherwise.
    */
--]]
function compass:hasStarted()
	return quick.QCompass:hasStarted()
end
