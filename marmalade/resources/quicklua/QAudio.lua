--------------------------------------------------------------------------------
-- audio singleton
--------------------------------------------------------------------------------
audio = quick.QAudio:new()

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
--[[
/**
Play a stream
@param fileName The name of the file to play
@param bLoop (optional) specify if the stream is to loop
@return The created node.
*/
--]]
function audio:playStream( fileName, bLoop)
    dbg.assertFuncVarType("string", fileName)
    dbg.assertFuncVarTypes({"boolean", "nil"}, bLoop)
    self:playStreamWithLoop( fileName, bLoop or false)
end

--[[
/**
Play a sound
@param fileName The name of the file to play
@param bLoop (optional) specify if the stream is to loop
@return The created node.
*/
--]]
function audio:playSound( fileName, bLoop)
    dbg.assertFuncVarType("string", fileName)
    dbg.assertFuncVarTypes({"boolean", "nil"}, bLoop)
    return self:playSoundWithLoop( fileName, bLoop or false)
end
