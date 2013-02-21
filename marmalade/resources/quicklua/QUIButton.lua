--------------------------------------------------------------------------------
-- UIButtons
--------------------------------------------------------------------------------
QUIButton = {}
QUIButton.__index = QUIButton

function QUIButton:touch( event, node)
        if event.phase == "began" then
            system:setFocus(node)
            node:setFrame(2)
            if node.labelTextPressed ~= nil then
                node.label.text=node.labelTextPressed
            end
            if node.labelColorPressed ~= nil then
                node.label.color=node.labelColorPressed
            end
            
            if node.pressSound ~= nil then
                audio:playSound(node.pressSound)
            end

        elseif event.phase == "ended" and system:getFocus() == node then
            system:setFocus(nil)
            node:setFrame(1)
            --system:sendEvent("activated", { node = node })
            local e = Event:new("activated")
            node:handleEvent(e)
            if node.labelText ~= nil then
                node.label.text=node.labelText
            end
            if node.labelColor ~= nil then
                node.label.color=node.labelColor
            end

            if node.releaseSound ~= nil then
                audio:playSound(node.releaseSound)
            end

        end

        return true
end

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
function QUIButton:initUIButton(l,values)
    -- Setup an inheritence from QSprite
    local lp = {}
    setmetatable(lp,QUIButton)

    l.touch = QUIButton.touch

    -- Add a touch event listener to this button
    l:addEventListener("touch", l)

    -- Set the correct frame, stop the animation and update the w/h
    l:setFrame(1)

    -- Setup the label
    if values.labelText ~= nil then
        l.labelText=values.labelText
        l.labelColor=values.labelColor
        l.labelTextPressed=values.labelTextPressed
        l.labelColorPressed=values.labelColorPressed

        l.label = director:createLabel( {
        x=0, y=0, w=l.w, h=l.h,
   		hAlignment="centre", vAlignment="middle",
        text=l.labelText,color=l.labelColor,
        font=l.labelFont
        } )
        l:addChild(l.label)
    end

    if values.pressSound ~= nil then
        l.pressSound = values.pressSound
        audio:loadSound(l.pressSound)
    end

    if values.releaseSound ~= nil then
        l.releaseSound = values.releaseSound
        audio:loadSound(l.releaseSound)
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- See director:createUIButton() for factory function

function QUIButton:destroy()
    if self.label ~= nil then
        self.label:destroy()
    end

    -- destruct the parent
    QSprite:destroy()
end


