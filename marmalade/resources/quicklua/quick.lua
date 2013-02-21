-- Load these in the order of any dependencies
dofile("quicklua/QDevice.lua")
dofile("quicklua/QVideo.lua")
dofile("quicklua/QMedia.lua")

--NOTE: always load QLuasocket.lua before QCrypto.lua
dofile("quicklua/QLuasocket.lua")

--NOTE: always load QCrypto.lua after QLuasocket.lua
dofile("quicklua/QCrypto.lua")

dofile("quicklua/QFaceBook.lua")
dofile("quicklua/QCompass.lua")
dofile("quicklua/QLocation.lua")
dofile("quicklua/QIOSAchievements.lua")
dofile("quicklua/QBrowser.lua")
dofile("quicklua/QAppStore.lua")
