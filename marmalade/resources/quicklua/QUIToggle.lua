--------------------------------------------------------------------------------
-- UIToggles
--------------------------------------------------------------------------------
QUIToggle = {}
QUIToggle.__index = QUIToggle

function QUIToggle:touch( event, node)
    if event.phase == "began" then
        if node.state == "on" then
            node.state = "off"

            if node.toggleOffSound ~= nil then
                audio:playSound(node.toggleOffSound)
            end
        else
            node.state = "on"

            if node.toggleOnSound ~= nil then
                audio:playSound(node.toggleOnSound)
            end
        end

        node:setFrame( (node.state == "on" and 2) or 1)

        local e = Event:new("toggled")
        node:handleEvent(e)
    end

    return true
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
function QUIToggle:initUIToggle(l,values)
    -- Setup an inheritence from QSprite
    local lp = {}
    setmetatable(lp,QUIToggle)

    l.touch = QUIToggle.touch

    -- Add a touch event listener to this button
    l:addEventListener("touch", l)

    -- Set the initial state
    l.state = values.state or "off"

    -- Set the correct frame, stop the animation and update the w/h
    l:setFrame( (l.state == "on" and 2) or 1)

    if values.toggleOnSound ~= nil then
        l.toggleOnSound = values.toggleOnSound
        audio:loadSound(l.toggleOnSound)
    end

    if values.toggleOffSound ~= nil then
        l.toggleOffSound = values.toggleOffSound
        audio:loadSound(l.toggleOffSound)
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- See director:createUIToggle() for factory function

function QUIToggle:destroy()
    -- destruct the parent
    QSprite:destroy()
end


