-- function definitions
local initMenu
local menuTouched
local showHighScores

local countdown_atlas = director:createAtlas( {
  width = 252,
  height = 196,
  numFrames = 3,
  textureName = "assets/countdown_atlas.png"
} )

local countdown_animation = director:createAnimation( {
  start = 1,
  count = 3,
  atlas = countdown_atlas,
} )

local background

initMenu = function()
  background = director:createSprite(0, 0, "assets/splashscreen.png")

  local classic = director:createSprite(361, 250, "assets/classic.png")
  classic:addEventListener("touch", menuTouched)
  classic:sync()
  background:addChild(classic)

  local one_minute = director:createSprite(361, 150, "assets/one_minute.png")
  one_minute:addEventListener("touch", menuTouched)
  one_minute:sync()
  background:addChild(classic)

  local ten_numbers = director:createSprite(361, 50, "assets/ten_numbers.png")
  ten_numbers:addEventListener("touch", menuTouched)
  ten_numbers:sync()
  background:addChild(classic)
  
  local tutorial = director:createSprite(1024 - 120, 20, "assets/tutorial.png")
  tutorial:addEventListener("touch", function(event)
    if event.phase == "ended" then
      showTutorial()
    end
  end)
  tutorial:sync()
  background:addChild(tutorial)
  
  local high_scores = director:createSprite(23, 20, "assets/scores.png")
  high_scores:addEventListener("touch", showHighScores)
  high_scores:sync()
  background:addChild(high_scores)
end

menuTouched = function(event)
  if ui_blocked == true or event.phase ~= "ended" then
    return
  end

  audio:playSound("sounds/simple_click.wav")
  ui_blocked = true
  if event.y > 250 then
    game_mode = MODE_CLASSIC
  elseif event.y > 150 then
    game_mode = MODE_ONE_MINUTE
  else
    game_mode = MODE_TEN_NUMBERS
  end

  dbg.print("Moving to game scene in mode " .. game_mode)
  director:moveToScene(game_scene, { transitionType = "slideInR", transitionTime = 0.5 } )
end

showHighScores = function(event)
  if ui_blocked == true or event.phase ~= "ended" then
    return
  end
  
  audio:playSound("sounds/simple_click.wav")
  ui_blocked = true
  
  dbg.print("Showing high scores")

  local overlay = director:createSprite(0, 0, "assets/dialog_overlay.png")
  local high_scores = director:createSprite(118, 20, "assets/high_scores.png")
  overlay:addChild(high_scores)
  
  local db_path = system:getFilePath("storage", "settings.sqlite")
  dbg.print("DB Path: " .. db_path)
  local db = sqlite3.open(db_path)
  
  overlay.zOrder = 3
  
  local count = 0
  for row in db:nrows("SELECT * FROM high_scores WHERE game = " .. MODE_CLASSIC .. " ORDER BY score DESC LIMIT 10") do
    drawScore(row.score, 160, 386 - (count * 34), high_scores) 
    count = count + 1
  end
  
  count = 0
  for row in db:nrows("SELECT * FROM high_scores WHERE game = " .. MODE_ONE_MINUTE .. " ORDER BY score DESC LIMIT 10") do
    drawScore(row.score, 425, 386 - (count * 34), high_scores) 
    count = count + 1
  end
  
  count = 0
  for row in db:nrows("SELECT * FROM high_scores WHERE game = " .. MODE_TEN_NUMBERS .. " ORDER BY score DESC LIMIT 10") do
    dbg.print("Draw score")
    drawScore(row.score, 660, 386 - (count * 34), high_scores) 
    count = count + 1
  end
  
  db:close()

  high_scores:addEventListener("touch", function(event)
    if event.phase == "ended" then
      ui_blocked = false
      audio:playSound("sounds/simple_click.wav")
      overlay:removeFromParent()
    end
  end)

end

local scene = director:createScene()
scene.name = "Menu"
scene:addEventListener( { "setUp" }, initMenu )
return scene