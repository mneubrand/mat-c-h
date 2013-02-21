quick.QMedia:registerLuaFunctions()

media = {}


--[[
/**
Plays in loop an audio medium from a file.
@param filename the path of the vidoe file to play
@return true on success, false otherwise
*/
--]]
function media:playSoundLoop(fileName)
	return media:playSound(fileName, 0)
end

--[[
/**
Plays once an audio medium from a file.
@param filename the path of the vidoe file to play
@return true on success, false otherwise
*/
--]]
function media:playSoundOnce(fileName)
	return media:playSound(fileName, 1)
end

--[[
/**
Plays a media from a file.
@param filename the path of the vidoe file to play
@param repeatCount 0 = loop, 1= once, any other n is the number of times it will be repeated.
@return true on success, false otherwise
*/
--]]
function media:playSound(fileName, repeatCount)
	return quick.QMedia:playSound(fileName, repeatCount)
end

--[[
/**
Checks if a media is currently being played.
@return true if the media is playing, false otherwise.
*/
--]]
function media:isSoundPlaying()
	return quick.QMedia:isSoundPlaying()
end

--[[
/**
Pauses the current media. If the media has never started
the error S3E_AUDIO_ERR_WRONG_STATE is thrown.
@return true on success, false otherwise.
*/
--]]
function media:pauseSound()
	return quick.QMedia:pauseSound()
end

--[[
/**
Resumes the current media. If the media has never started
the error S3E_AUDIO_ERR_WRONG_STATE is thrown.
@return true on success, false otherwise.
*/
--]]
function media:resumeSound()
	return quick.QMedia:resumeSound()
end

--[[
/**
Stops the current media.
*/
--]]
function media:stopSound()
	quick.QMedia:stopSound()
end

--[[
/**
Increases the volume of the current media by few units.
The value is clamped between the maximum and the minimum.
@return true on success, false otherwise.
*/
--]]
function media:volumeUp()
	return quick.QMedia:volumeUp()
end

--[[
/**
Decreases the volume of the current media by few units.
The value is clamped between the maximum and the minimum.
@return true on success, false otherwise.
*/
--]]
function media:volumeDown()
	return quick.QMedia:volumeDown()
end

--[[
/**
Gets the volume from 0 to 1.
@return the current volume from 0 to 1.
*/
--]]
function media:getVolume()
	return quick.QMedia:getVolume()
end

--[[
/**
Gets the current vidoe position in milliseconds.
@return the current vidoe position in milliseconds or 0 if no media is playing, -1 on error.
*/
--]]
function media:getPosition()
	return quick.QMedia:getPosition()
end

--[[
/**
Gets the audio state. Possible values "playing", "stopped", "failed", "paused"
@return the audio state. Possible values "playing", "stopped", "failed", "paused"
*/
--]]
function media:getAudioState()
	return quick.QMedia:getAudioState()
end

--[[
/**
Sets the audio volume clamping from 0 to 1.
@param the audio volume clamping from 0 to 1.
@return true on success, false otherwise.
*/
--]]
function media:setVolume(volume)
	return quick.QMedia:setVolume(volume)
end

--[[
/**
Checks if an audio codec is supported.
@param an audio codec name.
@return true if suported, false otherwise.
*/
--]]
function media:isAudioCodecSupported(codecName)
	return quick.QMedia:isAudioCodecSupported(codecName)
end

--[[
/**
Gets a vector of allowed video codec strings.
@return a vector of allowed codec names.
*/
--]]
function media:getSupportedAudioCodecsList()
	return cl_QMedia_getSupportedAudioCodecsList()
end

--[[
/**
Gets a table of allowed video codecs.
The keys are the codec names and values are true for those which are supported, false otherwise.
@return a table of allowed codec names.
*/
--]]
function media:getSupportedAudioCodecsTable()
	return cl_QMedia_getSupportedAudioCodecsTable()
end
