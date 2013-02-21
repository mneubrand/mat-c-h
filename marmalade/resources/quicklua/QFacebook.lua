--------------------------------------------------------------------------------
-- Facebook singleton
--------------------------------------------------------------------------------
facebook = quick.QFacebook:new()

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--[[
/*!
*/
]]
function facebook:showDialog(action, params)
    dbg.assertFuncVarType("string", action)
    dbg.assertFuncVarTypes({"table", "nil"}, params)

    -- Initialise the dialog
    if not facebook:_InitDialog(action) then
        return false
    end

    -- Set any parameters we were passed
    if params ~= nil then
        for i,v in pairs(params) do
            if type(v) == "string" then
                facebook:_AddDialogString( i, v)
            elseif type(v) == "number" then
                facebook:_AddDialogNumber( i, v)
            end
        end
    end

    -- do the dialog
    facebook:_ShowDialog()

    return true;

end

--[[
/*!
*/
]]
function facebook:request(methodorgraph, paramsorhttpmethod, params)
    dbg.assertFuncVarType("string", methodorgraph)
    dbg.assertFuncVarTypes({"string", "table"}, paramsorhttpmethod)
    dbg.assertFuncVarTypes({"table", "nil"}, params)

    local retval

    -- Initialise the request
    if type(paramsorhttpmethod) == "string" then
        -- Method call
        retval = facebook:_InitMethodRequest(methodorgraph, paramsorhttpmethod)
    else
        -- Graph call
        retval = facebook:_InitGraphRequest(methodorgraph)
        params = paramsorhttpmethod
    end

    if not retval then
        return false
    end

    -- Set any parameters we were passed
    if params ~= nil then
        for i,v in pairs(params) do
            if type(v) == "string" then
                facebook:_AddRequestString( i, v)
            elseif type(v) == "number" then
                facebook:_AddRequestNumber( i, v)
            end
        end
    end

    -- do the dialog
    facebook:_SendRequest()

    return true
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
