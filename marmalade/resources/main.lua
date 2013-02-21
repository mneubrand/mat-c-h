math.randomseed( os.time() )

audio:playSound("sounds/simple_click.wav")
audio:playStream("sounds/POL-aurora-borealis-short.wav", true)

MODE_CLASSIC = 0
MODE_ONE_MINUTE = 1
MODE_TEN_NUMBERS = 2

ui_blocked = false
game_mode = MODE_CLASSIC
first_run = true

showTutorial = function(params)
  if ui_blocked == true then
    return
  end
  
  audio:playSound("sounds/simple_click.wav")

  dbg.print("Showing tutorial")

  ui_blocked = true
  first_run = false

  local overlay = director:createSprite(0, 0, "assets/dialog_overlay.png")
  overlay.zOrder = 3

  local tutorial_atlas = director:createAtlas( {
    width = 687,
    height = 409,
    numFrames = 4,
    textureName = "assets/tutorial_atlas.png"
  } )

  local tutorial_animation = director:createAnimation( {
    start = 1,
    count = 4,
    atlas = tutorial_atlas
  } )

  local tutorial = director:createSprite( {
    x = 168,
    y = 95,
    source = tutorial_animation,
    frame = 1
  } )

  overlay:addChild(tutorial)

  local current_frame = 1
  tutorial:addEventListener("touch", function(event)
    if event.phase == "ended" then
      audio:playSound("sounds/simple_click.wav")
      if event.x > 512 then
        current_frame = current_frame + 1
      else
        current_frame = current_frame - 1
      end

      if current_frame >= 1 and current_frame <= 4 then
        ui_blocked = true
        tutorial:setFrame(current_frame)
      else
        ui_blocked = false
        overlay:removeFromParent()
        if params.callback ~= nil then
          params.callback()
        end
      end

    end
  end)

end

drawScore = function(score, positionX, positionY, container)
  local score_label = {}
  local scoreString = tostring(score)
  local width = 0
  for i = 1, # scoreString do
    score_label[i] = director:createSprite(0, positionY, "assets/font_white_small/" .. scoreString:sub(i,i) .. ".png")
    width = width + score_label[i].w + 3
  end

  local offset = 0
  for i = 1, # score_label do
    score_label[i].x = positionX - width/2 + offset
    score_label[i]:sync()
    offset = offset + score_label[i].w + 3
    container:addChild(score_label[i])
  end
  return score_label
end

-- read settings from db
local db_path = system:getFilePath("storage", "settings.sqlite")
dbg.print("DB Path: " .. db_path)
local db = sqlite3.open(db_path)
db:exec[[
         CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT);
         CREATE TABLE IF NOT EXISTS high_scores (id NUMBER PRIMARY KEY, game NUMBER, score NUMBER);
       ]]

for row in db:nrows("SELECT * FROM settings") do
  if row.key == "first_run" and row.value == "false" then
    first_run = false
  end
end

-- check if it is first run
if first_run == true then
  db:exec[[INSERT INTO settings VALUES ('first_run', 'false');]]
end

db:close()

game_scene = dofile("game.lua")
menu_scene = dofile("menu.lua")

director:setCurrentScene(nil)
director:moveToScene(menu_scene)