--[[
/**
System browser calls.
*/
--]]
browser = {}

--[[
/**
Checks if the system call exec is available.
@return true if available, false otherwise.
*/
--]]
function browser:isAvailable()
	return quick.QBrowser:isExecAvailable()
end

--[[
/**
Perform a system call to open the system predefined browser to the specified URL.
@param url the url to open in the browser.
@param exitFlag if the application should exit on opening the browser (on iOS this is ignored)
@return true on success, false otherwise.
*/
--]]
function browser:launchURL(url, exitFlag)
	return quick.QBrowser:execUrl(url, exitFlag)
end
