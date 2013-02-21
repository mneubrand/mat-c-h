--------------------------------------------------------------------------------
-- Director singleton
--------------------------------------------------------------------------------
director = quick.QDirector:new()
director.destroyList = {}

--------------------------------------------------------------------------------
-- Private API
--------------------------------------------------------------------------------
-- Update display info
function directorUpdateDisplayInfo(dw, dh)
    dbg.assertFuncVarTypes({"number", "number"}, dw, dh)
    
    director:_updateDisplayInfo(dw, dh)
end

-- Purge everything
function director:_purge()
    -- Destroy anything pending
--    director:_destroyPending()

    -- Delete current scene object
-- dereference should do this now
--    director:getCurrentScene():delete()
    
--    director:setCurrentScene(nil)
--    director.globalScene = nil

--    director.globalScene = director:createDefaultScene()
    director.globalScene = director:createScene({name="globalScene"})
    collectgarbage("collect")
end

-- Overall update
--Recursion for director:update() below
function director:_updateNodeAndChildren(n, dt)
    dbg.assertFuncVarType("userdata", n)
    dbg.assertFuncVarType("number", dt)

    -- Update node tweens
    n:updateTweens(system:getTime())

    -- Update node timers
    QTimer:updateTimers(n.timers, dt)

    -- Sync stuff to other C++ subsystems
    n:sync()

    -- Update children
    for i,v in ipairs(n.children) do
        self:_updateNodeAndChildren(v, dt)
    end
end

-- Destroy any objects pending destruction
--[[ This is now depreciated because of the new object lifecycle code
function director:Purge()
    for i,v in ipairs(self.destroyList) do
        v:delete() -- calls QNode::~QNode(), or derived destructor
    end
    self.destroyList = {}

end
]]

-- Called from QSystemObject::Update()
function director:update()
    -- Update global timers
    QTimer:updateTimers(system.timers, system.deltaTime)

    -- Update scene graph
    local s = director:getCurrentScene()
    director:_updateNodeAndChildren(s, system.deltaTime)

    -- Process instant scene changes without event locks getting in the way of
    -- the tearDown process
    director:_processInstantSceneChange()

end

--[[
/*
Create a tween object. We use a factory method to create these, so we can ensure that
QTween:initTween is called, which sets up the Lua peer table for the C++ userdata object.
@return A tween object.
*/
--]]
function director:createTween()
    local t = quick.QTween()
    QTween:initTween(t)
    return t
end

-- Called to complete a scene transition
function director:_transitionComplete()
--    dbg.print("director:_transitionComplete")
    if self._outgoingScene ~= nil then
        -- Send events to current scene
--        dbg.print("exitPostTransition")
        local exitPostTransitionEvent = QEvent:create("exitPostTransition")
        self._outgoingScene:handleEvent(exitPostTransitionEvent)

        if self._outgoingScene.isSetUp == true then
--            dbg.print("tearDown")
            local tearDownEvent = QEvent:create("tearDown", { nopropagation = true })
            self._outgoingScene:handleEvent(tearDownEvent)
            self._outgoingScene.isSetUp = false
        end

        self._outgoingScene = nil
    end

    self:setCurrentScene( self._incomingScene)

    -- Perform a bit of GC so we can load the new scene
	collectgarbage("collect")
    self:cleanupTextures()

    if self._incomingScene ~= nil then
        -- Send events to new scene
        local enterPostTransitionEvent = QEvent:create("enterPostTransition", { nopropagation = true })
        self._incomingScene:handleEvent(enterPostTransitionEvent)

        self._incomingScene = nil
    end

end

function director:setCurrentScene(scene)
    -- nil will set the global scene
    if scene == nil then
        scene = director.globalScene
    end
    dbg.assertFuncUserDataType("quick::QScene", scene)

    -- Store the LUA reference to the current scene
    self.currentScene = scene

    -- Pass it down to the CPP code as well (as this dosn't count as a LUA reference)
    self._currentScene = scene
end

-- Processing of instant scene changes
function director:_processInstantSceneChange()

    if self._newScene ~= nil then
        
        -- Tear down the old scene
        if self.currentScene.isSetUp == true then
            local tearDownEvent = QEvent:create("tearDown", { nopropagation = true })
            self.currentScene:handleEvent(tearDownEvent)
            self.currentScene.isSetUp = false
        end

        -- Flip to the new scene
        self:setCurrentScene( self._newScene)

        -- Perform a bit of GC so we can load the new scene
		collectgarbage("collect")
        self:cleanupTextures()

        if self._newScene.isSetUp == false then
--            dbg.print("Performing new scene setup on scene: " .. self._newScene.name)

            local setUpEvent = QEvent:create("setUp", { nopropagation = true })
            self._newScene:handleEvent(setUpEvent)
            self._newScene.isSetUp = true
        end

        -- Clear the new scene pointer
        self._newScene = nil
    end

end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
--[[
/**
Gets the currently active scene
*/
--]]
function director:getCurrentScene()
    -- Get the current scene from LUA side
    return self.currentScene
end

--[[
/**
Remove a node from its scene.
@param n The node to remove.
*/
--]]
function director:removeNode(n)
    dbg.assertFuncVarType("userdata", n)
    n:setParent(nil)
end

function director:addNodeToLists(n)
    dbg.assertFuncVarType("userdata", n)
    if self.addNodesToScene == true then
        local sc = self:getCurrentScene()
        dbg.assert(sc, "No current scene")
        sc:addChild(n)
    end
end

--[[
/**
Set the default color for newly created nodes.
@param r The red component of the color.
@param g The green component of the color.
@param b The blue component of the color.
*/
--]]
function director:setNodesColor(r, g, b, a)
    dbg.assertFuncVarTypes({"number", "number", "number", "number"}, r, g, b, a)
    self.nodesColor.r = r or 255
    self.nodesColor.g = g or 255
    self.nodesColor.b = b or 255
    self.nodesColor.a = a or 255
end


--------------------------------------------------------------------------------
-- Public API - factory functions
--------------------------------------------------------------------------------

--[[
/*
Create a node (base class object), specifying arbitrary input values.
@return The created node.
*/
--]]
function director:createNode(v)
    dbg.assertFuncVarTypes({"table", "nil"}, v)
    
    local n = quick.QNode()
    n:_createCCNode()
    QNode:initNode(n)
    self:addNodeToLists(n)
    table.setValuesFromTable(n, v)
    return n
end

--[[
/**
Create a texture atlas, specifying arbitrary input values.
@param values Lua table specifying name/value pairs, the path to a .plist file or the path to a texture.
@return The created atlas.
*/
--]]
function director:createAtlas(values)
    dbg.assertFuncVarTypes({"table", "string"}, values)
    local n = quick.QAtlas()
    QAtlas:initAtlas(n)

    if (type(values) == "table") then

        dbg.assert( values.textureName ~= nil, "director:createAtlas called without a valid textureName")
        n:initTexture( values.textureName)

        -- Calculate the scaling values for dynamic resolution support
        local texture_width, texture_height = n:getAtlasTextureSize()
        local source_width = values.originalSheetWidth or texture_width
        local source_height = values.originalSheetWidth or texture_width
        local scale_x = texture_width / source_width
        local scale_y = texture_width / source_width

        if values.frames ~= nil then
            -- initialise from a frames array
            for i,frame in ipairs(values.frames) do
                dbg.assert( frame.x ~= nil and frame.y ~= nil and frame.width ~= nil and frame.height ~= nil, "Each frame must contain an x, y, width and height member")

                local scaled_width = frame.width * scale_x
                local scaled_height = frame.height * scale_y

                n:addSpriteFrame( frame.x * scale_x, frame.y * scale_y,
                                    scaled_width, scaled_height,
                                    false,
                                    0, 0, scaled_width, scaled_height)

            end
        else
            -- initialise from a width/height/numFrames process
            dbg.assert( values.width ~= nil and values.height ~= nil and values.numFrames ~= nil, "Atlas simple parameter initialisation needs at least width, height and numFrames")

            -- Step the sprites at native resolution
            local sx = values.xStart or 0
            local x = sx
            local y = values.yStart or 0
            local remaining_frames = values.numFrames

            local border = values.border or 0
            local coverage_width = values.width + (border * 2)
            local coverage_height = values.height + (border * 2)

            local scaled_width = values.width * scale_x
            local scaled_height = values.height * scale_y

            -- Loop across and down the texture adding frames
            repeat
                repeat
                    n:addSpriteFrame( (x + border) * scale_x, (y + border) * scale_y,
                                       scaled_width, scaled_height,
                                       false,
                                       0, 0, scaled_width, scaled_height)

                    x = x + coverage_width

                    remaining_frames = remaining_frames - 1

                until (x + coverage_width) > texture_width or remaining_frames == 0

                x = sx
                y = y + coverage_height

            until (y + coverage_height) > texture_height or remaining_frames == 0

            dbg.assert( remaining_frames == 0, "The texture was too small for the number of images specified")

        end

    else
        -- Load via a path
        dbg.assertFuncVarTypes({"string"}, values)
        n:initFromFile(values)
    end

    return n
end

--[[
/**
Create an animation, specifying arbitrary input values.
@param values Lua table specifying name/value pairs.
@return The created animation.
*/
--]]
function director:createAnimation(values)
    dbg.assertFuncVarTypes({"table", "userdata", "nil"}, values)

    local n = quick.QAnimation()
    QAnimation:initAnimation(n)

    if type(values) ~= "table" then
        -- super simple creation
        n:addFrame(1, values)
    else
        if values.frames ~= nil then
            n.usedAtlases = {}
            -- Framed creation
            for i,v in ipairs(values.frames) do
                local frame, atlas
                if type(v) == "table" then
                    dbg.assert( v.frame ~= nil and v.atlas ~= nil, "A frame and atlas must be supplied")
                    atlas = v.atlas
                    frame = v.frame
                else
                    dbg.assert( values.atlas ~= nil, "A default atlas must be supplied")
                    atlas = values.atlas
                    frame = v
                end

                -- Add a lua reference to the atlas to avoid it being released too soon
                table.insert( n.usedAtlases, atlas)

                if type(frame) == "string" then
                    n:addFrameByName( frame, atlas)
                else
                    n:addFrame( frame, atlas)
                end
            end
        else
            -- Simple creation
            dbg.assert( values.start ~= nil and values.count ~= nil and values.atlas ~= nil, "Simple creation requires start, count and atlas to be passed")

            local last_frame = values.start + values.count - 1
            for frame = values.start, last_frame do
                n:addFrame( frame, values.atlas)
            end

            -- Add a lua reference to the atlas to avoid it being released too soon
            n.usedAtlases = values.atlas
        end
    end

    n:setDelay( values.delay or 1)

    return n
end


--[[
/**
Create a sprite node, specifying arbitrary input values.
@param values Lua table specifying name/value pairs.
@return The created sprite.
*/
--]]
function director:createSprite(values)
end
--[[
/**
Create a sprite node, at the specified screen position, with the specified texture name.
@param x X coordinate of sprite.
@param y Y coordinate of sprite.
@param source Either a full filename (including extension) of the texture or an animation to associate with
@return The created sprite.
*/
--]]
function director:createSprite(x, y, source)
    local n = quick.QSprite()
    QNode:initNode(n)
    QSprite:initSprite(n)
    self:addNodeToLists(n)

    local frame = nil

    if type(x) == "table" then
        -- Copy any "source" input to local
        source = x["source"]
        x["source"] = nil
        table.setValuesFromTable(n, x)
        if x.frame then
            frame = x.frame
        end
    else
        dbg.assertFuncVarTypes({"number", "number", "string"}, x, y, source)
        n.x = x
        n.y = y
    end
    n.source = source

    -- See if we need to create a real source
    if type(source) == "string" then
        -- "source" is assumed to point to a single image file
        -- Create an atlas and animation from this file
        local atlas = director:createAtlas(source)
        n.source = director:createAnimation( { start = 1, count = 1, atlas = atlas } )
    end

    dbg.assert(n.source, "Source data is nil")
    n.animation = n.source
    n.source = nil
    if frame then
        n.frame = frame
    end

    return n
end

--[[
/**
Create a font, specifying arbitrary input values.
@param values Lua table specifying name/value pairs.
@return The created font.
*/
--]]
function director:createFont(values)
end
--[[
/**
Create a font from a .fnt file.
@param filepath path to the .fnt file.
@return The created font.
*/
--]]
function director:createFont(filepath)
    dbg.assertFuncVarType("string", filepath)

    local n = quick.QFont()
    QFont:initFont(n)

    if (type(filepath) == "table") then
		error("director:createFont(values) is currently unsupported")
    else
        dbg.assertFuncVarType("string", filepath)
        retval = n:initFromFntFile(filepath)
		dbg.assert(retval, "Failed to load .fnt file")
    end
    return n
end

--[[
/**
Create a label node, specifying arbitrary input values.
@param values Lua table specifying name/value pairs.
@return The created label.
*/
--]]
function director:createLabel(values)
end
--[[
/**
Create a label node, at the specified screen position, with the specified text string.
@param x X coordinate of label origin.
@param y Y coordinate of label origin.
@param text Text string.
@param font a string or QFont defining the font to use.
@return The created label.
*/
--]]
function director:createLabel(x, y, text, font)
    local n = quick.QLabel()
    QNode:initNode(n)

    if (type(x) == "table") then
        -- Remove 'font' key from table, place in local variable
        font = x["font"] -- could be nil
        x["font"] = nil
        table.setValuesFromTable(n, x)
    else
        dbg.assertFuncVarTypes({"number", "number", "string"}, x, y, text)
        dbg.assertFuncVarTypes({"string", "userdata", "nil"}, font)
        n.x = x
        n.y = y
        n.text = text
    end
	if font == nil then
		-- Specify the default font
        if self.defaultFont == nil then
            dbg.print("Creating default font")
            self.defaultFont = self:createFont("fonts/Default.fnt")
        end
		font = self.defaultFont
	elseif type(font) == "string" then
		-- This version creates a font object from the string first
		font = self:createFont(font)
	end
	n.font = font
	n:init()
    self:addNodeToLists(n)

    return n
end

--[[
/**
Create a lines node, specifying arbitrary input values.
@param values Lua table specifying name/value pairs.
@return The created lines object.
*/
--]]
function director:createLines(values)
end
--[[
/**
Create a lines node, with the specified coordinates.
@param coords The table of coordinates to initialise with. These are x,y pairs, so the size of the table must be even.
@return The created lines object.
*/
--]]
function director:createLines(x, y, coords)
    local n = quick.QLines()
    -- Must call init.. on all subclasses in hierarchy order
    QNode:initNode(n)
    QVector:initVector(n)
    QLines:initLines(n)

    if (type(x) == "table") then
        table.setValuesFromTable(n, x)
        if x.coords then
            n:append(x.coords)
        end
    else
        dbg.assertFuncVarTypes({"number", "number", "table"}, x, y, coords)
        n.x = x
        n.y = y
        if coords then
            n:append(coords)
        end
    end

    self:addNodeToLists(n)
    return n
end

--[[
/**
Create a circle node, specifying arbitrary input values.
@param values Lua table specifying name/value pairs.
@return The created circle object.
*/
--]]
function director:createCircle(values)
end
--[[
/**
Create a circle node, with the specified position and radius.
@param x X coordinate of circle origin.
@param y Y coordinate of circle origin.
@param radius The radius of the circle.
@return The created circle object.
*/
--]]
function director:createCircle(x, y, radius)
    local n = quick.QCircle()
    -- Must call init.. on all subclasses in hierarchy order
    QNode:initNode(n)
    QVector:initVector(n)
    QCircle:initCircle(n)

    if (type(x) == "table") then
        table.setValuesFromTable(n, x)
    else
        dbg.assertFuncVarTypes({"number", "number", "number"}, x, y, radius)
        n.x = x
        n.y = y
        n.radius = radius
    end

    self:addNodeToLists(n)
    return n
end

--[[
/**
Create a rectangle node, specifying arbitrary input values.
@param values Lua table specifying name/value pairs.
@return The created rectangle object.
*/
--]]
function director:createRectangle(values)
end
--[[
/**
Create a rectangle node, with the specified position and radius.
@param x X coordinate of rectangle origin.
@param y Y coordinate of rectangle origin.
@param w The width of the rectangle.
@param h The height of the rectangle.
@return The created rectangle object.
*/
--]]
function director:createRectangle(x, y, w, h)
    local n = quick.QRectangle()
    -- Must call init.. on all subclasses in hierarchy order
    QNode:initNode(n)
    QVector:initVector(n)
    QLines:initLines(n)
    QRectangle:initRectangle(n)

    if (type(x) == "table") then
        table.setValuesFromTable(n, x)
    else
        dbg.assertFuncVarTypes({"number", "number", "number", "number"}, x, y, w, h)
        n.x = x
        n.y = y
        n.w = w
        n.h = h
    end

    self:addNodeToLists(n)
    return n
end

--[[
/**
Create a bounding box object, from x and y bounds.
@param xMin Local minimum x value.
@param xMax Local maximum x value.
@param yMin Local minimum y value.
@param yMax Local maximum y value.
@return The created bounding box object.
*/
--]]
function director:createBBox(_xMin, _xMax, _yMin, _yMax)
    dbg.assertFuncVarTypes({"number", "number", "number", "number"}, _xMin, _xMax, _yMin, _yMax)
    local bb = {xMin=_xMin, xMax=_xMax, yMin=_yMin, yMax=_yMax}
    return bb
end

--[[
/**
Creates a pivot (revolute) joint that constrains the two attached bodies to rotate about a point.
@param values a table containing the acceptable values for a pivot joint. Example:
values = {nodeA = spriteA, nodeB = spriteB, absDX = spriteA.x, absDY = spriteA.y, collideConnected = false, 
motorEnabled = true,
motorSpeed = 10,
maxMotorTorque  100,
limitEnabled = false
}

*/
--]]
function director:createPivotJoint(values)

end

--[[
/**
Creates a pivot (revolute) joint that constrains the two attached bodies to rotate about a point.
@param nodeA the first scene node to which this joint will be attached
@param nodeB the second scene node to which this joint will be attached
@param OPTIONAL: anchorX the x position of the joint in display world coordinates
@param OPTIONAL: anchorY the y position of the joint in display world coordinates
@param OPTIONAL: collideConnected enables / disables collisions for the attached bodies, usually = false
*/
--]]
function director:createPivotJoint(nodeA, nodeB, anchorX, anchorY, collideConnected)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA) --nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarTypes({"userdata", "userdata"}, nodeA, nodeB)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorY)
        dbg.assertFuncVarTypes({"boolean", "nil"}, collideConnected)

        n.nodeA = nodeA
        n.nodeB = nodeB
        n.anchorX = anchorX
        n.anchorY = anchorY
		n.collideConnected = collideConnected
    end
	dbg.assert(n.nodeA, " nodeA was not specified")
    dbg.assert(n.nodeB, " nodeB was not specified")

	-- Defaults
	if (not n.anchorX) or (not n.anchorY) then
		n.anchorX = n.nodeA.x
		n.anchorY = n.nodeA.y
	end
    n.collideConnected = n.collideConnected or false

	n:_createBox2DRevoluteJoint(n.nodeA, n.nodeB, n.anchorX, n.anchorY, n.collideConnected) --nodeA and nodeB have been stored in to_lua properties
	n:_sync()--TODO check if this should go here and / or elswhere
	return n
end

--[[
/**
Creates a friction joint that is a special kind of pivot / piston joint that resists motion.
It provides 2D translational and angular friction.
@param values a table containing the allowed initialization values.
@return the new joint
Example:
values = {nodeA = spriteA, nodeB = spriteB, anchorX = spriteA.x, anchorY = spriteA.y, collideConnected = false
maxForce = 10,
maxTorque = 20
}
*/
--]]
function director:createFrictionJoint(values)
	
end

--[[
/**
Creates a friction joint that is a special kind of pivot / piston joint that resists motion.
It provides 2D translational and angular friction.
@param nodeA the first scene node to which this joint will be attached
@param nodeB the second scene node to which this joint will be attached
@param OPTIONAL: anchorX the x position of the joint in display world coordinates
@param OPTIONAL: anchorY the y position of the joint in display world coordinates
@param OPTIONAL: collideConnected enables / disables collisions for the attached bodies, usually = false
@return the new joint
*/
--]]
function director:createFrictionJoint(nodeA, nodeB, anchorX, anchorY, collideConnected)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA)--nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarTypes({"userdata", "userdata"}, nodeA, nodeB)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorY)
        dbg.assertFuncVarTypes({"boolean", "nil"}, collideConnected)

        n.nodeA = nodeA
        n.nodeB = nodeB
        n.anchorX = anchorX
        n.anchorY = anchorY
		n.collideConnected = collideConnected
    end
	dbg.assert(n.nodeA, " nodeA was not specified")
    dbg.assert(n.nodeB, " nodeB was not specified")

	-- Defaults
	if (not n.anchorX) or (not n.anchorY) then
		n.anchorX = n.nodeA.x
		n.anchorY = n.nodeA.y
	end
    n.collideConnected = n.collideConnected or false

	n:_createBox2DFrictionJoint(n.nodeA, n.nodeB, n.anchorX, n.anchorY, n.collideConnected) --nodeA and nodeB have been stored in to_lua properties
	n:_sync()--TODO check if this should go here and / or elswhere
	return n
end

--[[
/**
Calls Box2D to create a new Prismatic joint.
@param values a table containing the allowed initialization values.
Example : 
values = {nodeA = spriteA, nodeB = spriteB, anchorX = spriteA.x, anchorY = spriteA.x, localAxisX = 0, localAxisY = 1, collideConnected = true,
motorEnabled = true,
motorSpeed = 10,
limitEnabled = true
}
@return a pointer to the newly created Box2D joint
*/
--]]
function director:createPistonJoint(values)

end

--[[
/**
Calls Box2D to create a new Prismatic joint.
@param nodeA the first scene node to which this joint will be attached
@param nodeB the second scene node to which this joint will be attached
@param OPTIONAL: anchorX the x position of the joint in display world coordinates
@param OPTIONAL: anchorY the y position of the joint in display world coordinates
@param OPTIONAL: localAxisX the joint axis x component in display coordinate in local body A space
@param OPTIONAL: localAxisY the joint axis y component in display coordinate in local body A space
@param OPTIONAL: collideConnected enables / disables collisions for the attached bodies, usually = false        
@return a pointer to the newly created Box2D joint
*/
--]]
function director:createPistonJoint(nodeA, nodeB, anchorX, anchorY, localAxisX, localAxisY, collideConnected)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA)--nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarTypes({"userdata", "userdata"}, nodeA, nodeB)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorY)
        dbg.assertFuncVarTypes({"number", "nil"}, localAxisX)
        dbg.assertFuncVarTypes({"number", "nil"}, localAxisY)
        dbg.assertFuncVarTypes({"boolean", "nil"}, collideConnected)

        n.nodeA = nodeA
        n.nodeB = nodeB
        n.anchorX = anchorX
        n.anchorY = anchorY
		n.localAxisX = localAxisX
		n.localAxisY = localAxisY
		n.collideConnected = collideConnected
    end
	dbg.assert(n.nodeA, " nodeA was not specified")
    dbg.assert(n.nodeB, " nodeB was not specified")

	-- Defaults
	if (not n.anchorX) or (not n.anchorY) then
		n.anchorX = n.nodeA.x
		n.anchorY = n.nodeA.y
	end
	if (not n.localAxisX) or (not n.localAxisY) then
        n.localAxisX = 0
        n.localAxisY = 1
    end
    n.collideConnected = n.collideConnected or false

	n:_createBox2DPrismaticJoint(n.nodeA, n.nodeB, n.anchorX, n.anchorY, n.localAxisX, n.localAxisY, n.collideConnected)
	n:_sync()--TODO check if this should go here and / or elswhere
	return n
end

--[[
/**
Creates a wheel joint that combines a piston and a pivot joint.
@param values the first scene node to which this joint will be attached
Example:
values = {nodeA = spriteA, nodeB = spriteB, anchorX = spriteA.x, anchorY = spriteA.y, localAxisX = 1, localAxisY = 0, collideConnected = false, 
motorEnabled = true
motorSpeed = 50
limitEnabled = false
}
@return the new joint.
*/
--]]
function director:createWheelJoint(values)

end

--[[
/**
Creates a wheel joint that combines a piston and a pivot joint.
@param nodeA the first scene node to which this joint will be attached
@param nodeB the second scene node to which this joint will be attached
@param OPTIONAL: anchorX the x position of the anchor point in display world coordinates
@param OPTIONAL: anchorY the y position of the anchor point in display world coordinates
@param OPTIONAL: localAxisX the x component of the piston axis in display world coordinates
@param OPTIONAL: localAxisY the y component of the piston axis in display world coordinates
@param OPTIONAL: collideConnected enables / disables collisions for the attached bodies, usually = false
@return the new joint.
*/
--]]
function director:createWheelJoint(nodeA, nodeB, anchorX, anchorY, localAxisX, localAxisY, collideConnected)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA)--nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarTypes({"userdata", "userdata"}, nodeA, nodeB)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorY)
        dbg.assertFuncVarTypes({"number", "nil"}, localAxisX)
        dbg.assertFuncVarTypes({"number", "nil"}, localAxisY)
        dbg.assertFuncVarTypes({"boolean", "nil"}, collideConnected)

        n.nodeA = nodeA
        n.nodeB = nodeB
        n.anchorX = anchorX
        n.anchorY = anchorY
		n.localAxisX = localAxisX
		n.localAxisY = localAxisY
		n.collideConnected = collideConnected
    end
	dbg.assert(n.nodeA, " nodeA was not specified")
    dbg.assert(n.nodeB, " nodeB was not specified")

	-- Defaults
	if (not n.anchorX) or (not n.anchorY) then
		n.anchorX = n.nodeA.x
		n.anchorY = n.nodeA.y
	end
	if (not n.localAxisX) or (not n.localAxisY) then
        n.localAxisX = 0
        n.localAxisY = 1
    end
    n.collideConnected = n.collideConnected or false

	n:_createBox2DWheelJoint(n.nodeA, n.nodeB, n.anchorX, n.anchorY, n.localAxisX, n.localAxisY, n.collideConnected)
	n:_sync()--TODO check if this should go here and / or elswhere
	return n
end

--[[
/**
Creates a weld joint that literaly welds the two attached body in a point.
@param values a table containing any of the possible initialization values.
Example:
values = {nodeA = spriteB, nodeB = spriteB, anchorX = spriteA.x, anchorY = spriteA.y, collideConnected = false}
@return the new joint
*/
--]]
function director:createWeldJoint(values)

end

--[[
/**
Creates a weld joint that literaly welds the two attached body in a point.
@param nodeA the first scene node to which this joint will be attached
@param nodeB the second scene node to which this joint will be attached
@param OPTIONAL: anchorX the x position of the joint in display world coordinates
@param OPTIONAL: anchorY the y position of the joint in display world coordinates
@param OPTIONAL: collideConnected enables / disables collisions for the attached bodies, usually = false
@return the new joint
*/
--]]
function director:createWeldJoint(nodeA, nodeB, anchorX, anchorY, collideConnected)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA)--nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarTypes({"userdata", "userdata"}, nodeA, nodeB)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorY)
        dbg.assertFuncVarTypes({"boolean", "nil"}, collideConnected)

        n.nodeA = nodeA
        n.nodeB = nodeB
        n.anchorX = anchorX
        n.anchorY = anchorY
		n.collideConnected = collideConnected
    end
	dbg.assert(n.nodeA, " nodeA was not specified")
    dbg.assert(n.nodeB, " nodeB was not specified")

	-- Defaults
	if (not n.anchorX) or (not n.anchorY) then
		n.anchorX = n.nodeA.x
		n.anchorY = n.nodeA.y
	end
    n.collideConnected = n.collideConnected or false

	n:_createBox2DWeldJoint(n.nodeA, n.nodeB, n.anchorX, n.anchorY, n.collideConnected)
	n:_sync()--TODO check if this should go here and / or elswhere
	return n
end


--[[
/**
Creates a distance joint that constrains the two attached bodies to maintain a costant distance through a line defined
by the two anchor points.
@param values a table containing the possible initialization values.
values = {nodeA = spriteA, nodeB = spriteB, anchorAX = spriteA.x, anchorAY = spriteA.y, anchorBX = spriteB.x, anchorBY = spriteB.y, collideConnected = false,
length = 2, 
frequency = 1, 
dampingRatio = 0.9
}
*/
--]]
function director:createDistanceJoint(values)

end

--[[
/**
Creates a distance joint that constrains the two attached bodies to maintain a costant distance defined
by the two anchor points.
@param nodeA the first scene node to which this joint will be attached
@param nodeB the second scene node to which this joint will be attached
@param OPTIONAL: anchorAX the x position of the first anchor point in display world coordinates
@param OPTIONAL: anchorAY the y position of the first anchor point in display world coordinates
@param OPTIONAL: anchorBX the x position of the first anchor point in display world coordinates
@param OPTIONAL: anchorBY the y position of the first anchor point in display world coordinates
@param OPTIONAL: collideConnected enables / disables collisions for the attached bodies, usually = false
*/
--]]
function director:createDistanceJoint(nodeA, nodeB, anchorAX, anchorAY, anchorBX, anchorBY, collideConnected)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA)--nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarTypes({"userdata", "userdata"}, nodeA, nodeB)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorAX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorAY)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorBX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorBY)
        dbg.assertFuncVarTypes({"boolean", "nil"}, collideConnected)

        n.nodeA = nodeA
        n.nodeB = nodeB
        n.anchorAX = anchorAX
        n.anchorAY = anchorAY
        n.anchorBX = anchorBX
        n.anchorBY = anchorBY
		n.collideConnected = collideConnected
    end

	dbg.assert(n.nodeA, " nodeA was not specified")
    dbg.assert(n.nodeB, " nodeB was not specified")

    -- Defaults
	if(not n.anchorAX or not n.anchorAY) then
		n.anchorAX = n.nodeA.x
		n.anchorAY = n.nodeA.y
	end
	if(not n.anchorBX or not n.anchorBY) then
		n.anchorBX = n.nodeB.x
		n.anchorBY = n.nodeB.y
	end
    n.collideConnected = n.collideConnected or false

	n:_createBox2DDistanceJoint(n.nodeA, n.nodeB, n.anchorAX, n.anchorAY, n.anchorBX, n.anchorBY, n.collideConnected) --nodeA and nodeB have been stored in to_lua properties
	n:_sync()
	return n
end

--[[
/**
Creates a pulley joint that attaches two bodies with an imaginary rope whose length remains constant: if one body is pulled down, the other one will move up.
@param values a table containing any allowed initialization value.
Example
values = {nodeA = spriteA, nodeB = spriteB, groundAnchorAX = spriteA.x, groundAnchorAY = spriteA.y + 100,
 groundAnchorBX = spriteB.x, groundAnchorBY = spriteB.y + 100, anchorAX = spriteA.x, anchorAY = spriteA.y, 
 anchorBX = spriteB.x, anchorBY = spriteB.y, ratio = 1, collideConnected = false }
@return the new joint
*/
--]]
function director:createPulleyJoint(values)
	
end
--[[
/**
Creates a pulley joint that attaches two bodies with an imaginary rope whose length remains constant: if one body is pulled down, the other one will move up.
@param nodeA the first scene node to which this joint will be attached
@param nodeB the second scene node to which this joint will be attached
@param groundAnchorAX x position of a stationary anchor point from which the body A hangs in display world coordinates
@param groundAnchorAY y position of a stationary anchor point from which the body A hangs in display world coordinates
@param groundAnchorBX x position of a stationary anchor point from which the body A hangs in display world coordinates
@param groundAnchorBY y position of a stationary anchor point from which the body A hangs in display world coordinates
@param OPTIONAL: anchorAX x position of the anchor point on body A in display world coordinates
@param OPTIONAL: anchorAY y position of the anchor point on body A in display world coordinates
@param OPTIONAL: anchorBX x position of the anchor point on body A in display world coordinates
@param OPTIONAL: anchorBY y position of the anchor point on body A in display world coordinates
@param OPTIONAL: ratio the ratio between the speed of the two sides of the rope
@param OPTIONAL: collideConnected enables / disables collisions for the attached bodies, usually = false
@return the new joint
*/
--]]
function director:createPulleyJoint(nodeA, nodeB, groundAnchorAX, groundAnchorAY, groundAnchorBX, groundAnchorBY, anchorAX, anchorAY, anchorBX, anchorBY, ratio, collideConnected)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA)--nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarTypes({"userdata", "userdata", "number", "number", "number", "number"}, nodeA, nodeB, groundAnchorAX, groundAnchorAY, groundAnchorBX, groundAnchorBY)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorAX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorAY)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorBX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorBY)
        dbg.assertFuncVarTypes({"number", "nil"}, ratio)
        dbg.assertFuncVarTypes({"boolean", "nil"}, collideConnected)

        n.nodeA = nodeA
        n.nodeB = nodeB
		n.groundAnchorAX = groundAnchorAX
		n.groundAnchorAY = groundAnchorAY
		n.groundAnchorBX = groundAnchorBX
		n.groundAnchorBY = groundAnchorBY
        n.anchorAX = anchorAX
        n.anchorAY = anchorAY
        n.anchorBX = anchorBX
        n.anchorBY = anchorBY
		n.ratio = ratio
		n.collideConnected = collideConnected
    end

	dbg.assert(n.nodeA, " nodeA was not specified")
    dbg.assert(n.nodeB, " nodeB was not specified")
	dbg.assert(n.groundAnchorAX, " groundAnchorAX was not specified")
    dbg.assert(n.groundAnchorAY, " groundAnchorAY was not specified")
    
    -- Defaults
	if(not n.anchorAX or not n.anchorAY) then
		n.anchorAX = n.nodeA.x
		n.anchorAY = n.nodeA.y
	end
	if(not n.anchorBX or not n.anchorBY) then
		n.anchorBX = n.nodeB.x
		n.anchorBY = n.nodeB.y
	end
    n.ratio = n.ratio or 1
    n.collideConnected = n.collideConnected or false
	
    --creating the physics joint
	n:_createBox2DPulleyJoint(n.nodeA, n.nodeB, n.groundAnchorAX, n.groundAnchorAY, n.groundAnchorBX, n.groundAnchorBY, n.anchorAX, n.anchorAY, n.anchorBX, n.anchorBY, n.ratio, n.collideConnected) --nodeA and nodeB have been stored in to_lua properties
	n:_sync()
	return n

end

--[[
/**
Creates a mouse (touch) joint that attaches a body to the world through a spring.
The world is represented by a hidden default static object that is created by the physics singleton.
@param values a table containing any allowed value.
Example
values = {nodeA = spriteA, anchorX = spriteA.x, anchorY = spriteA.y,
maxForce = 1000,
frequency  = 1.0,
dampingRatio = 0.95
}
@return the new joint
*/
--]]
function director:createTouchJoint(values)
	
end
--[[
/**
Creates a mouse (touch) joint that attaches a body to the world through a spring.
The world is represented by a hidden default static object that is created by the physics singleton.
@param nodeA the first scene node to which this joint will be attached
@param OPTIONAL: anchorX x position of the anchor point on body A in display world coordinates (usually the position of a click event)
@param OPTIONAL: anchorY y position of the anchor point on body A in display world coordinates (usually the position of a click event)
@return the new joint
*/
--]]
function director:createTouchJoint(nodeA, anchorX, anchorY)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA)--nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarType("userdata", nodeA)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorAX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorAY)

        n.nodeA = nodeA
        n.anchorX = anchorX
        n.anchorY = anchorY
    end

	dbg.assert(n.nodeA, " nodeA was not specified")

    -- Defaults
	if(not n.anchorX or not n.anchorY) then
		n.anchorX = n.nodeA.x
		n.anchorY = n.nodeA.y
	end
	
    -- Creating the physics joint
	n:_createBox2DMouseJoint(n.nodeA, n.anchorX, n.anchorY)
	n:_sync()
	return n

end


--[[
/**
///from http://www.box2d.org/manual.html
Creates a gear joint that can only connect revolute and/or prismatic joints.
Like the pulley ratio, you can specify a gear ratio. 
However, in this case the gear ratio can be negative. 
Also keep in mind that when one joint is a revolute joint (angular) and the other joint is prismatic (translation), and then the gear ratio will have units of length or one over length.
Caution:
	deleting one of the connected joints automatically deletes this joint.
/note NOTE: the jointA's bodyB and the jointB's bodyB MUST NOT be the same and MUST NOT be static
@param values a table containing any allowed initialization value.
Example
values = {jointA = pivotJointA, jointB = pivotJointB, collideConnected = false,
gearRatio = 1.0
}
@return the new joint.
*/
--]]
function director:createGearJoint(values)
	
end
--[[
/**
///from http://www.box2d.org/manual.html
Creates a gear joint that can only connect revolute and/or prismatic joints.
Like the pulley ratio, you can specify a gear ratio. 
However, in this case the gear ratio can be negative. 
Also keep in mind that when one joint is a revolute joint (angular) and the other joint is prismatic (translation), and then the gear ratio will have units of length or one over length.
Caution:
	deleting one of the connected joints automatically deletes this joint.
/note NOTE: the jointA's bodyB and the jointB's bodyB MUST NOT be the same and MUST NOT be static
@param jointA the first joint to which this is connected. Note bodyB of jointA and jointB must be non static.
@param jointB the first joint to which this is connected. Note bodyB of jointA and jointB must be non static.
@param collideConnected enables / disables collisions for the attached bodies, usually = false
@return the new joint.
*/
--]]
function director:createGearJoint(jointA, jointB, collideConnected)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA)--nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarTypes({"userdata", "userdata"}, jointA, jointB)
        dbg.assertFuncVarTypes({"boolean", "nil"}, collideConnected)

        n.jointA = jointA
		n.jointB = jointB
		n.collideConnected = collideConnected
    end

	dbg.assert(n.jointA, " jointA was not specified")
	dbg.assert(n.jointB, " jointB was not specified")

    -- Defaults
    n.collideConnected = n.collideConnected or false
	
    --creating the physics joint
	n:_createBox2DGearJoint(n.jointA, n.jointB, n.collideConnected)
	n:_sync()
	return n

end


--[[
/**
///from http://www.box2d.org/manual.html
Creates a rope joint that restricts the maximum distance between two points. This can be useful to prevent chains of bodies from stretching, even under high load.
@param values a table containing any allowed initialization value.
Example:
values = {nodeA = spriteA, nodeB = spriteB, anchorAX = spriteA.x, anchorAY = spriteA.y, anchorBX = spriteB.x, anchorBY = spriteB.y, collideConnected = false,
maxLength = 2.0
}
@return the new joint.
*/
--]]
function director:createRopeJoint(values)
	
end
--[[
/**
///from http://www.box2d.org/manual.html
Creates a rope joint that restricts the maximum distance between two points. This can be useful to prevent chains of bodies from stretching, even under high load.
@param nodeA the first scene node to which this joint will be attached
@param nodeB the second scene node to which this joint will be attached
@param anchorAX x position of the anchor point on body A in display world coordinates
@param anchorAY y position of the anchor point on body A in display world coordinates
@param anchorBX x position of the anchor point on body A in display world coordinates
@param anchorBY y position of the anchor point on body A in display world coordinates
@param collideConnected enables / disables collisions for the attached bodies, usually = false
@return the new joint.
*/
--]]
function director:createRopeJoint(nodeA, nodeB, anchorAX, anchorAY, anchorBX, anchorBY, collideConnected)
	local n = physics:_createNewQJoint()
	QJoint:initJoint(n)

	if (type(nodeA) == "table") then
        table.setValuesFromTable(n, nodeA)--nodeA in this case contains the table of the initialization valules
    else
        dbg.assertFuncVarTypes({"userdata", "userdata"}, nodeA, nodeB)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorAX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorAY)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorBX)
        dbg.assertFuncVarTypes({"number", "nil"}, anchorBY)
        dbg.assertFuncVarTypes({"boolean", "nil"}, collideConnected)

        n.nodeA = nodeA
        n.nodeB = nodeB
        n.anchorAX = anchorAX
        n.anchorAY = anchorAY
        n.anchorBX = anchorBX
        n.anchorBY = anchorBY
		n.collideConnected = collideConnected
    end

	dbg.assert(n.nodeA, " nodeA was not specified")
    dbg.assert(n.nodeB, " nodeB was not specified")

    -- Defaults
	if(not n.anchorAX or not n.anchorAY) then
		n.anchorAX = n.nodeA.x
		n.anchorAY = n.nodeA.y
	end
	if(not n.anchorBX or not n.anchorBY) then
		n.anchorBX = n.nodeB.x
		n.anchorBY = n.nodeB.y
	end
    n.collideConnected = n.collideConnected or false

	n:_createBox2DRopeJoint(n.nodeA, n.nodeB, n.anchorAX, n.anchorAY, n.anchorBX, n.anchorBY, n.collideConnected) --nodeA and nodeB have been stored in to_lua properties
	n:_sync()
	return n
end


----------------------------------
-- Scenes
----------------------------------
--[[
/**
Create a scene node, and set it to be the director's current scene.
Note that no transition occurs from any previous scene, and no scene events are thrown.
*/
--]]
function director:createScene(v)
    dbg.assertFuncVarTypes({"table", "nil"}, v)

    local n = quick.QScene()
    QNode:initNode(n)
    QScene:initScene(n)
    n:_init(false)
    table.setValuesFromTable(n, v)
    self:setCurrentScene(n)

    -- Mark that setUp has NOT been called yet
    n.isSetUp = false
    return n
end

-- PRIVATE:
-- Create default scene. Use of global variable ensures Lua doesn't GC it.
-- Doesn't use createScene because of extra parameters
function director:createDefaultScene()
--    dbg.print("director:createDefaultScene")
    local n = quick.QScene()
    QNode:initNode(n)
    QScene:initScene(n)
    n:_init(true)
    n.name = "globalScene"
    self:setCurrentScene(n)

    return n
end


--[[
/**
Move to a new scene.
Throws the following events:
<new scene> - setUp (only if the new scene is not already set up)
<new scene> - enterPreTransition
<current scene> - exitPreTransition

@param newScene The new Scene object to move to
@param options A table of options, e.g. "transition", "time"
*/
--]]
function director:moveToScene(newScene, options)
    -- Check if we are moving to the default scene
    if newScene == nil then
--        dbg.print("moveToScene(nil)")
        newScene = self.globalScene
    end

    dbg.assertFuncUserDataType("quick::QScene", newScene)
    dbg.assertFuncVarTypes({"table", "nil"}, options)

    -- If this is the same as the current scene, then bail at this point
    local oldScene = self.currentScene
    if newScene == oldScene then
        dbg.print("Already in target scene")
        return
    end
 
    -- Set details of transition
    self._transitionScene = newScene
    self._transitionTime = 0
    self._transitionType = ""

    if options ~= nil then
        -- get transition information
        self._transitionTime = options.transitionTime or 0
        self._transitionType = options.transitionType or ""
    end

    if self._transitionType ~= "" then
        -- this is a timed transition
--        dbg.print("Timed transition to " .. newScene.name)

        -- Send events to new scene
        -- NOTE: We temporarily set director.currentScene to this scene, so that the setUp function
        -- can assume newly created objects will get added to this scene
        self.currentScene = newScene
        if newScene.isSetUp == false then
            local setUpEvent = QEvent:create("setUp", { nopropagation = true })
            newScene:handleEvent(setUpEvent)
            newScene.isSetUp = true
        end
        local enterPreTransitionEvent = QEvent:create("enterPreTransition", { nopropagation = true })
        newScene:handleEvent(enterPreTransitionEvent)
        self.currentScene = oldScene

        -- Send events to current scene
        local exitPreTransitionEvent = QEvent:create("exitPreTransition", { nopropagation = true })
        oldScene:handleEvent(exitPreTransitionEvent)

        -- LUA side storage for usage in _transitionComplete
        self._outgoingScene = oldScene
        self._incomingScene = newScene

    else
        -- this is actually an instant transition
--        dbg.print("Instant transition to " .. newScene.name)

        -- no need to actually do a transition
        self._transitionScene = nil

        -- Queue up a scene change for next update
        self._newScene = newScene

    end
end

-- Create the Director's global scene
director.globalScene = director:createDefaultScene()
