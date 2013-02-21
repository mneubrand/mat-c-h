--------------------------------------------------------------------------------
-- Timers
--------------------------------------------------------------------------------

if config.debug.mock_tolua == true then
	QTimer = quick.QTimer
else
    QTimer = {}
    QTimer.__index = QTimer
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
--[[
/*
Initialise the peer table for the C++ class QTimer.
This must be called immediately after the QTimer() constructor.
*/
--]]
function QTimer:initTimer(n, _funcortable, _period, _iterations, _delay)
    local np
	if not config.debug.mock_tolua == true then
        np = {}
        setmetatable(np, QTimer)
        tolua.setpeer(n, np)
    else
        np = n
    end

    dbg.assert(_funcortable)
    dbg.assert(_period)
    if _iterations == nil then
        _iterations = 0
    end
    if _delay == nil then
        _delay = 0
    end
    np.listener = _funcortable
    np.period = _period
    np.iterations = _iterations
    np.delay = _delay
    np.elapsed = 0
    np.doneIts = 0
    np.paused = false

end

-- Update timer, call listener callback if required, return false if timer has expired, otherwise return true
function QTimer:update(dt)
    dbg.assertFuncVarType("number", dt)

    if self.paused == true then
        return true
    end

    self.elapsed = self.elapsed + dt
    if self.elapsed >= self.period + self.delay then
        self.doneIts = self.doneIts + 1
        self.elapsed = self.elapsed - self.period

        -- Create event for this timer
        local ev = QEvent:recreate("timer", { doneIterations = self.doneIts, source = self })

        -- Call listener
        handleEventWithListener(ev, self.listener)

        -- Release the reference to the timer in the event
        ev.source = nil
    end
    if self.iterations > 0 and self.doneIts >= self.iterations then
        -- Done all iterations, so remove this timer
        return false
    end
    return true
end

-- Update a list of timers, deleting those that have expired
function QTimer:updateTimers(timers, dt)
    local remove_indicies = {}
    
    for i,v in ipairs(timers) do
        if v:update(dt) == false then
            table.insert( remove_indicies, 1, i)
        end
    end

    for i=1,#remove_indicies do
        -- Timer expired, remove it
        table.remove(timers, remove_indicies[i])
    end

end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Pause the timer
function QTimer:pause()
    self.paused = true
end

-- Resume the timer
function QTimer:resume()
    self.paused = false
end

-- Cancel the timer
function QTimer:cancel()
    -- Set things up so that it's deleted on next call to QTimer:update()
    self.paused = false
    self.elapsed = 0
    self.delay = 99999
    self.period = 1
    self.iterations = 1
    self.doneIts = 1
end



