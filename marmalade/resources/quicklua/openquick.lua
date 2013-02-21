-- Load these in the order of any dependencies
--print("Loading dbg.lua")
--dofile("quicklua/dbg.lua")
--print("")

dofile("quicklua/class.lua")
dofile("quicklua/QColor.lua")
dofile("quicklua/QTimer.lua")
dofile("quicklua/QFont.lua")
dofile("quicklua/QNode.lua")
dofile("quicklua/QSystem.lua")
dofile("quicklua/QLabel.lua")
dofile("quicklua/QScene.lua")
dofile("quicklua/QDirector.lua")
dofile("quicklua/QTween.lua")
dofile("quicklua/QEvent.lua")
dofile("quicklua/QPhysics.lua")
dofile("quicklua/Qjson.lua")

if config.debug.mock_tolua == false then
	dofile("quicklua/QLsqlite3.lua")
end

dofile("quicklua/QVector.lua")
dofile("quicklua/QLines.lua")
dofile("quicklua/QCircle.lua")
dofile("quicklua/QRectangle.lua")
dofile("quicklua/QAtlas.lua")
dofile("quicklua/QJoint.lua")
dofile("quicklua/QAnimation.lua")
dofile("quicklua/QSprite.lua")
dofile("quicklua/QAudio.lua")
