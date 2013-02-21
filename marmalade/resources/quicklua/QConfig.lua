--------------------------------------------------------------------------------
-- Default config is set up here
-- All possible config keys must be defined
--------------------------------------------------------------------------------
_config =
{
    debug =
    {
        mock_tolua = false,
		general = true,
        assertDialogs = true,

		testtable =
		{
			foo = 1,
			bar = 2,
		}
    }
}

-- Recursively set values in tt from values in tf
_initTableAndBelow = function(tf, tt)
    if type(tf) == "table" then
        for k,v in pairs(tf) do
            if tt[k] == nil then
                -- Index not present in config, so copy entire index (could be a table with children)
                tt[k] = v
            else
                -- Index present in config, so iterate through config index in case of children
                _initTableAndBelow(v, tt[k])
            end
        end
    end
end

-- Initialise the config table, based on the default _config table values, and any values already loaded into
-- a table called 'config'
initConfig = function()
    if config == nil then
        config = {}
    end

    -- Copy elements from '_config' to 'config'
    -- Must be done recursively, to handle embedded tables
    _initTableAndBelow(_config, config)
end
