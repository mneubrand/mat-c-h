--[[
/**
Game Center Achievement manager global object.
*/
--]]
iosGameCenterAchievements = {}

--[[
    /**
    Loads all the possible achievements for this application.
	On completion the event "GameCenterAchievements" is triggered returning an array
	a table as follows:
	GameCenterAchievements = 
	{
		name = "gameCenter"
		type = "loadAllAchievements"
		count,--the number of returned entries
		[1] = 
		{
		"description",
        "id",
        "maxPoints",
        "title",
        "unachievedDescr"
		}
		
		[2] = 
		{
		"description",
        "id",
        "maxPoints",
        "title",
        "unachievedDescr"
		}
		
		result --true if the operation was successful, false otherwise
		
		error --optional contains the error description: if nil the operation was successful.
		errorCode --optional contains the error code: if nil the operation was successful.
	}
    */
--]]
function iosGameCenterAchievements:loadAllAchievements()
	quick.QIOSGameCenterAchievements:loadAllAchievements()
end

--[[
/**
Check Game Center availability.
@return true if the "Game Center" is available.
*/
--]]
function iosGameCenterAchievements:isGameCenterAvailable()
	return quick.QIOSGameCenterAchievements:isGameCenterAvailable()
end

--[[
/**
Authenticate the local player. On completion it triggers the following event is triggered:
event
{
	name = "gameCenter"
	type = "authentication"
	result = --true if successful, false otherwise
	error = --optional if result == false error contains the error description
	errorCode = --optional if result == false error contains the error code
}
@return true on success.
*/
--]]
function iosGameCenterAchievements:authenticate()
	return quick.QIOSGameCenterAchievements:authenticate()
end

--[[
/**
Shows the Game Center system GUI. The application is suspended.
@return true on success, false otherwise.
*/
--]]
function iosGameCenterAchievements:showGUI()
	return quick.QIOSGameCenterAchievements:showGUI()
end

--[[
/**
Loads the achievements of the currently authenticated player. NOTE: only the achievement with a progress percentage
> 0 are returned. 
It triggers the event 
{
	type = "loadPlayerAchievements"
	count,--the number of returned entries
	name = "gameCenter",--the name of the event
	[1] = 
	{
		"id",
		"percentage"
	}
	
	[2] = 
	{
		"id",
		"percentage"
	}
	.....
	error --optional contains the error description: if nil the operation was successful.
	errorCode --optional contains the error code: if nil the operation was successful.
}
*/
--]]
function iosGameCenterAchievements:loadPlayerAchievements()
	return quick.QIOSGameCenterAchievements:loadPlayerAchievements()
end

--[[
/**
Set a progress in percentage (integer) for an achievement. On operation completed the follwing event

event
{
	name = "gameCenter"
	type = "operationComplete"
	error --optional contains the error description: if nil the operation was successful.
	errorCode --optional contains the error code: if nil the operation was successful.
}
@return true on success, false otherwise.
*/
--]]
function iosGameCenterAchievements:setAchievementProgress(id, perc)
	return quick.QIOSGameCenterAchievements:setAchievementProgress(id, perc)
end
