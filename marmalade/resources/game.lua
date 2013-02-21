-- function definitions
local initGame
local initUI
local initField
local initPossibilities

local sceneTouched
local isItemTouched
local isPowerupTouched
local fieldTouched
local powerupTouched

local calculateSolution
local nextNumber
local gameOver

local blockPowerup
local powerupSkip
local powerupRandom
local powerupBomb
local powerupSwap

local clearSelectedFields
local clearNumber
local clearPowerups
local resetField

local updateTimeLabel
local updateScoreLabel
local updateNumbersLeftLabel

local showPaused

-- variable definitions
local field = {}
local powerups = {}
local possibilities = {}

-- hardcoded offsets
local OFFSET_ITEM_X = 172
local OFFSET_ITEM_Y = 20

local OFFSET_POWERUP_X = 25
local OFFSET_POWERUP_Y = 80

local NUMBER_ANIMATION_OFFSET = 140
local OFFSET_NUMBER_X = 892 + NUMBER_ANIMATION_OFFSET
local OFFSET_NUMBER_Y = 372

-- item animation
local ITEM_NORMAL = 1
local ITEM_PRESSED = 2
local ITEM_CORRECT = 3
local ITEM_WRONG = 4

local current_item

local item_atlas = director:createAtlas( {
  width = 55,
  height = 58,
  numFrames = 4,
  textureName = "assets/button_atlas.png"
} )

local item_animation = director:createAnimation( {
  start = 1,
  count = 4,
  atlas = item_atlas
} )

-- powerup animation
local POWERUP_RANDOM = 0
local POWERUP_BOMB = 1
local POWERUP_SKIP = 2
local POWERUP_SWAP = 3

local powerup_atlas = director:createAtlas( {
  width = 82,
  height = 86,
  numFrames = 2,
  textureName = "assets/powerup_atlas.png"
} )

local powerup_animation = director:createAnimation( {
  start = 1,
  count = 2,
  atlas = powerup_atlas
} )

local countdown_atlas = director:createAtlas( {
  width = 252,
  height = 196,
  numFrames = 3,
  textureName = "assets/countdown_atlas.png"
} )

local countdown_animation = director:createAnimation( {
  start = 1,
  count = 3,
  delay = 1,
  atlas = countdown_atlas,
} )

local guess_atlas = director:createAtlas( {
  width = 78,
  height = 78,
  numFrames = 3,
  textureName = "assets/guess_atlas.png"
} )

local guess_animation = director:createAnimation( {
  start = 1,
  count = 3,
  atlas = guess_atlas
} )

local guess_atlas2 = director:createAtlas( {
  width = 78,
  height = 78,
  numFrames = 3,
  textureName = "assets/guess_atlas2.png"
} )

local guess_animation2 = director:createAnimation( {
  start = 1,
  count = 3,
  atlas = guess_atlas2
} )

local background
local number_background
local countdown
local guess, guess2
local number_label = {}
local guess_label = {}
local guess_label2 = {}
local old_number_label

local NUMBER_ANIMATION_TIME = 0.2
local RESET_ANIMATION_TIME = 0.45
local POWERUP_ANIMATION_TIME = 40

-- game logic
local currently_selected = {}
local current_number = 0
local current_powerup = -1

local numbers_left = 10
local time_left = 11
local time_label = {}
local time_last_number
local update_timer

local score = 0
local score_label = {}

initGame = function()
  dbg.print("Init game")
  initUI()
  initPossibilities()

  if first_run == true then
    ui_blocked = false
    showTutorial( { callback = initGame } )
  else
    ui_blocked = true

    score = 0

    if game_mode ~= MODE_TEN_NUMBERS then
      time_left = 61
      updateScoreLabel()
    else
      numbers_left = 10
      time_left = -1
      updateNumbersLeftLabel()
    end

    clearSelectedFields()
    clearNumber()
    clearPowerups()

    updateTimeLabel()

    countdown = director:createSprite( {
      x = 386,
      y = 202,
      source = countdown_animation,
      frame = 1
    } )
    countdown.raisesAnimEvents = true
    countdown:sync()

    countdown:addEventListener("anim", function(event)
      audio:playSound("sounds/beep2.wav")
      countdown:removeFromParent()
      ui_blocked = false

      update_timer = system:addTimer(function()
        updateTimeLabel()
      end, 1, 0, 0)

      nextNumber()
    end)

    background:addChild(countdown)
    system:addTimer(function()
      audio:playSound("sounds/beep.wav")
      system:addTimer(function()
        audio:playSound("sounds/beep.wav")
      end, 1, 2, 0);
      countdown:play()   
    end, 1, 1, 0)
  end
end

initUI = function()
  dbg.print('Initializing UI')
  -- initialize background and global touch listener
  if background ~= nil then
    background:removeFromParent()
  end
  background = director:createSprite(0, 0, "assets/background.png")
  background:addEventListener("touch", sceneTouched)
  background.zOrder = 2

  if number_background ~= nil then
    number_background:removeFromParent()
  end
  number_background = director:createSprite(819, 372, "assets/number_background.png")
  number_background.zOrder = 0
  number_background:sync()
  
  guess = director:createSprite( {
    x = 787,
    y = 327,
    source = guess_animation,
    frame = 1
  } )
  guess:sync()
  background:addChild(guess)
  
  guess2 = director:createSprite( {
    x = 915,
    y = 327,
    source = guess_animation2,
    frame = 1
  } )
  guess2:sync()
  background:addChild(guess2)
  
  local pause = director:createSprite(984, 550, "assets/pause.png");
  pause:sync()
  background:addChild(pause)
  pause:addEventListener("touch", function(event)
    if event.phase == "ended" then
      showPaused()
    end
  end)

  dbg.print('Initializing field')
  -- add 9x9 items to field
  for i = 0,8 do
    local row = {}
    for j = 0,8 do
      local item = initField(i, j)
      item:sync()
      item.label:sync()
      background:addChild(item)
      

      -- add item to table
      row[j] = item
      j = j + 1
    end
    field[i] = row
    i = i + 1
  end

  dbg.print('Initializing Powerups')
  -- add powerup buttons
  for i = 0,3 do
    -- create background
    local powerup = director:createSprite( {
      x = OFFSET_POWERUP_X,
      y = OFFSET_POWERUP_Y + i * 120,
      source = powerup_animation,
      frame = 1
    } )

    -- create icon and center it in background
    local icon
    if i == POWERUP_RANDOM then
      icon = director:createSprite(0, 0, "assets/powerup_random.png")
    elseif i == POWERUP_BOMB then
      icon = director:createSprite(0, 0, "assets/powerup_bomb.png")
    elseif i == POWERUP_SKIP then
      icon = director:createSprite(0, 0, "assets/powerup_skip.png")
    elseif i == POWERUP_SWAP then
      icon = director:createSprite(0, 0, "assets/powerup_swap.png")
    end
    icon.x = (powerup.w - icon.w) / 2
    icon.y = (powerup.h - icon.h) / 2

    icon:sync()
    powerup:addChild(icon)
    powerup:sync()
    background:addChild(powerup)

    powerup.index = i
    powerups[i] = powerup
  end

  dbg.print('Init score/time labels')
  local time = director:createSprite(869, 305, "assets/time.png");
  time:sync()
  background:addChild(time)
  local colon = director:createSprite(887, 260, "assets/font_white_small/colon.png")
  colon:sync()
  background:addChild(colon)
  
  local label
  if game_mode == MODE_TEN_NUMBERS then
    label = director:createSprite(849, 205, "assets/numbers.png")
  else
    label = director:createSprite(864, 205, "assets/score.png")
  end
  label:sync()
  background:addChild(label)
end

initField = function(x, y, newVal)
  -- create background
  local item = director:createSprite( {
    x = OFFSET_ITEM_X + x * 60,
    y = OFFSET_ITEM_Y + y * 63,
    source = item_animation,
    frame = 1
  } )
  item.fieldX = x
  item.fieldY = y

  local number
  if newVal ~= nil then
    number = newVal
  else
    number = math.random(1, 9)
  end
  item.number = number

  -- create number label and center it in background
  local label = director:createSprite(0, 0, "assets/font_white_small/" .. number .. ".png")
  label.x = (item.w - label.w) / 2
  label.y = (item.h - label.h) / 2
  label.name = number
  item.label = label

  item:addChild(label)

  return item
end

initPossibilities = function()
  dbg.print("Initiating possible combinations")
  local map = {}
  for i = 0,5 do
    for j = 0,5 do
      local ltr_pos = field[i][j].number * field[i+1][j].number + field[i+2][j].number
      local ltr_neg = field[i][j].number * field[i+1][j].number - field[i+2][j].number

      local rtl_pos = field[i+2][j].number * field[i+1][j].number + field[i][j].number
      local rtl_neg = field[i+2][j].number * field[i+1][j].number - field[i][j].number

      local utd_pos = field[i][j].number * field[i][j+1].number + field[i][j+2].number
      local utd_neg = field[i][j].number * field[i][j+1].number - field[i][j+2].number

      local dtu_pos = field[i][j+2].number * field[i][j+1].number + field[i][j].number
      local dtu_neg = field[i][j+2].number * field[i][j+1].number - field[i][j].number

      local ltr_utd_pos = field[i][j].number * field[i+1][j+1].number + field[i+2][j+2].number
      local ltr_utd_neg = field[i][j].number * field[i+1][j+1].number - field[i+2][j+2].number

      local ltr_dtu_pos = field[i][j+2].number * field[i+1][j+1].number + field[i+2][j].number
      local ltr_dtu_neg = field[i][j+2].number * field[i+1][j+1].number - field[i+2][j].number

      local rtl_utd_pos = field[i+2][j].number * field[i+1][j+1].number + field[i][j+2].number
      local rtl_utd_neg = field[i+2][j].number * field[i+1][j+1].number - field[i][j+2].number

      local rtl_dtu_pos = field[i+2][j+2].number * field[i+1][j+1].number + field[i][j].number
      local rtl_dtu_neg = field[i+2][j+2].number * field[i+1][j+1].number - field[i][j].number

      map[tostring(ltr_pos)] = "true"
      map[tostring(ltr_neg)] = "true"
      map[tostring(rtl_pos)] = "true"
      map[tostring(rtl_neg)] = "true"
      map[tostring(utd_pos)] = "true"
      map[tostring(utd_neg)] = "true"
      map[tostring(dtu_pos)] = "true"
      map[tostring(dtu_neg)] = "true"

      map[tostring(ltr_utd_pos)] = "true"
      map[tostring(ltr_utd_neg)] = "true"
      map[tostring(ltr_dtu_pos)] = "true"
      map[tostring(ltr_dtu_neg)] = "true"
      map[tostring(rtl_utd_pos)] = "true"
      map[tostring(rtl_utd_neg)] = "true"
      map[tostring(rtl_dtu_pos)] = "true"
      map[tostring(rtl_dtu_neg)] = "true"
    end
  end

  possibilities = {}
  for i,v in pairs(map) do
    if tonumber(i) > 0 then
      table.insert(possibilities, tonumber(i))
    end
  end
end

sceneTouched = function(event)
  if ui_blocked then
    return
  end

  if event.phase == "began" then
    if isItemTouched(event.x, event.y) then
      -- find button coordinates
      local x = math.floor((event.x - OFFSET_ITEM_X) / 60)
      local y = math.floor((event.y - OFFSET_ITEM_Y) / 63)

      dbg.print("Pressed field button at " .. x .. "," .. y)

      -- update animation
      current_item = field[x][y]
      current_item:setFrame(ITEM_PRESSED)

      --TODO make swipe possible

    elseif isPowerupTouched(event.x, event.y) then
      -- find selected powerup
      local index = math.floor((event.y - OFFSET_POWERUP_Y) / 120)

      dbg.print("Pressed powerup at " .. index)

      -- update animation
      current_item = powerups[index]
      current_item:setFrame(ITEM_PRESSED)

    end
  elseif event.phase == "ended" and current_item ~= nil then
    if current_item.number ~= nil then
      fieldTouched(current_item.fieldX, current_item.fieldY, event.phase)
    else
      -- update animation
      current_item:setFrame(ITEM_NORMAL)
      powerupTouched(current_item.index)
    end
    current_item = nil
  end

end

fieldTouched = function(x, y, phase)
  if current_powerup == POWERUP_BOMB then
    powerupBomb(x, y)
    return
  elseif current_powerup == POWERUP_SWAP then
    powerupSwap(x, y)
    return
  end

  -- check for double tap
  for i = 1, # currently_selected do
    if currently_selected[i].fieldX == x and currently_selected[i].fieldY == y then
      current_item:setFrame(ITEM_CORRECT)
      audio:playSound("sounds/blip_click.wav")
      return
    end
  end

  if # currently_selected == 0 then

    -- update animation
    currently_selected[(# currently_selected)+1] = current_item
    current_item:setFrame(ITEM_CORRECT)
    audio:playSound("sounds/blip_click.wav")

  elseif # currently_selected == 1 then

    -- enforce direction
    if math.abs(x - currently_selected[1].fieldX) <= 1 and math.abs(y - currently_selected[1].fieldY) <= 1
       and (x ~= currently_selected[1].fieldX or y ~= currently_selected[1].fieldY) then
      -- update animation
      currently_selected[(# currently_selected)+1] = current_item
      current_item:setFrame(ITEM_CORRECT)
      audio:playSound("sounds/blip_click.wav")
    else
      audio:playSound("sounds/electric_alert.wav")
      dbg.print("Can't select " .. x .. "," .. y)
      current_item:setFrame(ITEM_NORMAL)
      current_item = currently_selected[1]
    end

  elseif # currently_selected == 2 then

    -- enforce direction
    if x == currently_selected[2].fieldX - (currently_selected[1].fieldX - currently_selected[2].fieldX)
    and y == currently_selected[2].fieldY - (currently_selected[1].fieldY - currently_selected[2].fieldY) then
      -- update animation
      currently_selected[(# currently_selected)+1] = current_item
      current_item:setFrame(ITEM_CORRECT)

      calculateSolution()
    else
      audio:playSound("sounds/electric_alert.wav")
      dbg.print("Can't select " .. x .. "," .. y)
      current_item:setFrame(ITEM_NORMAL)
      current_item = currently_selected[2]
    end

  end

end

powerupTouched = function(index)
  -- reset current powerup if there is any
  if current_powerup >= 0 then
    powerups[current_powerup]:setFrame(ITEM_NORMAL)
    current_powerup = -1
  end

  -- if powerup is blocked don't do anything
  if powerups[index].overlay ~= nil then
    audio:playSound("sounds/electric_alert.wav")
    return
  end

  if index == POWERUP_SKIP then
    powerupSkip()
  elseif index == POWERUP_RANDOM then
    powerupRandom()
  elseif index == POWERUP_BOMB then
    -- toggle bomb on/off
    current_item:setFrame(ITEM_PRESSED)
    current_powerup = POWERUP_BOMB
    audio:playSound("sounds/blip_click.wav")
  elseif index == POWERUP_SWAP then
    current_item:setFrame(ITEM_PRESSED)
    current_powerup = POWERUP_SWAP
    clearSelectedFields()
    audio:playSound("sounds/blip_click.wav")
  end
end

blockPowerup = function(index)
  -- add overlay
  audio:playSound("sounds/detuned_affirm.wav")
  local overlay = director:createSprite(0, 0, "assets/button_powerup_overlay.png")
  powerups[index]:addChild(overlay)
  powerups[index].overlay = overlay

  -- animate overlay
  tween:to(overlay, {
    yScale = 0,
    time = POWERUP_ANIMATION_TIME,
    onComplete = function()
      powerups[index].overlay = nil
      overlay:removeFromParent()
    end
  })
end

powerupSkip = function()
  clearSelectedFields()
  nextNumber()
  current_powerup = -1
  blockPowerup(POWERUP_SKIP)
end

powerupRandom = function()
  ui_blocked = true
  local resetCount = 0
  local alreadyReset = {}
  while resetCount < 9 do
    local x = math.random(0,8)
    local y = math.random(0,8)

    if alreadyReset[ x*10 + y ] == nil then
      resetField(x, y)

      alreadyReset[ x*10 + y ] = true
      resetCount = resetCount + 1
    end
  end

  -- clear currenty selected fields
  background:addTimer(function()
    ui_blocked = false
    clearSelectedFields()
    initPossibilities()
  end, RESET_ANIMATION_TIME + 0.01, 1, 0)

  blockPowerup(POWERUP_RANDOM)
end

powerupBomb = function(x, y)
  powerups[POWERUP_BOMB]:setFrame(ITEM_NORMAL)
  current_powerup = -1

  ui_blocked = true
  for i = x-1,x+1 do
    for j = y-1,y+1 do
      if i >= 0 and i < 9 and j >= 0 and j < 9 then
        resetField(i, j)
      end
    end
  end

  -- clear currenty selected fields
  background:addTimer(function()
    ui_blocked = false
    clearSelectedFields()
    initPossibilities()
  end, RESET_ANIMATION_TIME + 0.01, 1, 0)

  blockPowerup(POWERUP_BOMB)
end

powerupSwap = function(x, y)
  if # currently_selected > 0 then
    powerups[POWERUP_SWAP]:setFrame(ITEM_NORMAL)
    current_powerup = -1

    ui_blocked = true

    local val_a = currently_selected[1].number
    local val_b = field[x][y].number

    resetField(currently_selected[1].fieldX, currently_selected[1].fieldY, val_b)
    resetField( field[x][y].fieldX, field[x][y].fieldY, val_a)

    -- clear currenty selected fields
    background:addTimer(function()
      ui_blocked = false
      clearSelectedFields()
      initPossibilities()
    end, RESET_ANIMATION_TIME + 0.01, 1, 0)

    blockPowerup(POWERUP_SWAP)
  else
    field[x][y]:setFrame(ITEM_CORRECT)
    currently_selected[1] = field[x][y]
    audio:playSound("sounds/blip_click.wav")
  end
end

clearSelectedFields = function()
  for i = 1, # currently_selected do
    currently_selected[i]:setFrame(ITEM_NORMAL)
  end
  currently_selected = {}
end

clearPowerups = function()
  for i = 0, (# powerups) - 1 do
    local overlay = powerups[i].overlay
    if overlay ~= nil then
      overlay:removeFromParent()
      powerups[i].overlay = nil
    end
  end
end

clearNumber = function()
  if number_label[0] ~= nil then
    old_number_label = number_label

    tween:to(old_number_label[0], {
      x = old_number_label[0].x - NUMBER_ANIMATION_OFFSET,
      time = NUMBER_ANIMATION_TIME,
      onComplete = function()
        old_number_label[0]:removeFromParent()
      end
    })

    if number_label[1] ~= nil then
      tween:to(old_number_label[1], {
        x = old_number_label[1].x - NUMBER_ANIMATION_OFFSET,
        time = NUMBER_ANIMATION_TIME,
        onComplete = function()
          old_number_label[1]:removeFromParent()
        end
      })
    end
  end
  number_label = {}
  currently_selected = {}
end

resetField = function(x, y, newVal)
  -- add spark
  local spark = director:createSprite(0, 0, "assets/spark.png")
  spark.x = field[x][y].x + ((field[x][y].w - spark.w)/2)
  spark.y = field[x][y].y + ((field[x][y].h - spark.h)/2)
  background:addChild(spark)

  -- remove label
  field[x][y].label:removeFromParent()

  -- set animation
  field[x][y]:setFrame(ITEM_CORRECT)

  background:addTimer(function()
    -- remove old field
    field[x][y]:removeFromParent()

    -- create new field
    local item = initField(x, y, newVal)
    field[x][y] = item
    background:addChild(item)

    -- remove spark
    spark:removeFromParent()
  end, RESET_ANIMATION_TIME, 1, 0)
end

isItemTouched = function(x, y)
  if x >= OFFSET_ITEM_X and x <= OFFSET_ITEM_X + 9*60 and (x - OFFSET_ITEM_X) % 60 < 55 then
    if y >= OFFSET_ITEM_Y and y <= OFFSET_ITEM_Y + 9*63 and (y - OFFSET_ITEM_Y) % 63 < 58 then
      return true
    end
  end
  return false
end

isPowerupTouched = function(x, y)
  if x >= OFFSET_POWERUP_X and x <= OFFSET_POWERUP_X + 82 then
    if y >= OFFSET_POWERUP_Y and y <= OFFSET_POWERUP_Y + 4*120 and (y - OFFSET_POWERUP_Y) % 120 < 86 then
      return true
    end
  end
  return false
end

calculateSolution = function()

  local a = currently_selected[1].number
  local b = currently_selected[2].number
  local c = currently_selected[3].number

  local var_a = a * b + c
  local var_b = a * b - c

  dbg.print("Selected " .. a .. ", " .. b .. ", " .. c .. " => " .. var_a .. " or " .. var_b)
  
  -- Display guesses
  guess_label = drawScore(var_a, 826, 348, background)
  guess_label2 = drawScore(var_b, 954, 348, background)
  
  if current_number == var_a or current_number == var_b then
    if current_number == var_a then
      guess:setFrame(2)
    else
      guess:setFrame(3)
    end
    if current_number == var_b then
      guess2:setFrame(2)
    else
      guess2:setFrame(3)
    end
    audio:playSound("sounds/xylophone_affirm.wav")
    score = score + math.max(3000 - (time_last_number - time_left) * 100, 100)
    updateScoreLabel()
    if game_mode == MODE_CLASSIC then
      time_left = time_left + math.max(math.floor((time_last_number - time_left)/1.5), 2)
      updateTimeLabel()
    elseif game_mode == MODE_TEN_NUMBERS then
      numbers_left = numbers_left - 1
      updateNumbersLeftLabel()
      if numbers_left == 0 then
        gameOver()
      end
    end
  else
    audio:playSound("sounds/electric_deny2.wav")
    guess:setFrame(3)
    guess2:setFrame(3)
    currently_selected[1]:setFrame(ITEM_WRONG)
    currently_selected[2]:setFrame(ITEM_WRONG)
    currently_selected[3]:setFrame(ITEM_WRONG)
  end

  ui_blocked = true
  background:addTimer(function()
    ui_blocked = false
    for i = 1, # guess_label do
      guess_label[i]:removeFromParent()
    end
    for i = 1, # guess_label2 do
      guess_label2[i]:removeFromParent()
    end
    guess:setFrame(1)
    guess2:setFrame(1)
    nextNumber()
  end, 0.8, 1, 0)

end

nextNumber = function()
  -- remove old selection
  clearSelectedFields()

  -- remove old numbers
  clearNumber()

  -- Getting next number
  local new_number = current_number
  while new_number == current_number do
    new_number = possibilities[math.random(1, # possibilities)]
  end

  if new_number >= 10 then
    number_label[0] = director:createSprite(0, 0, "assets/font_green_big/" .. math.floor(new_number/10) .. ".png")
    number_label[1] = director:createSprite(0, 0, "assets/font_green_big/" .. (new_number%10) .. ".png")

    number_label[0].x = OFFSET_NUMBER_X - (number_label[0].w+number_label[1].w+5)/2
    number_label[1].x = number_label[0].x + number_label[0].w + 5
    number_label[0].y = OFFSET_NUMBER_Y + number_label[0].h/2
    number_label[1].y = OFFSET_NUMBER_Y + number_label[1].h/2

    tween:to(number_label[0], {
      x = number_label[0].x - NUMBER_ANIMATION_OFFSET,
      time = NUMBER_ANIMATION_TIME
    })
    tween:to(number_label[1], {
      x = number_label[1].x - NUMBER_ANIMATION_OFFSET,
      time = NUMBER_ANIMATION_TIME
    })
  else
    number_label[0] = director:createSprite(0, 0, "assets/font_green_big/" .. new_number .. ".png")
    number_label[0].x = OFFSET_NUMBER_X - number_label[0].w/2
    number_label[0].y = OFFSET_NUMBER_Y + number_label[0].h/2

    tween:to(number_label[0], {
      x = number_label[0].x - NUMBER_ANIMATION_OFFSET,
      time = NUMBER_ANIMATION_TIME
    })
  end

  current_number = new_number
  time_last_number = time_left
  dbg.print("Current number = " .. current_number)
end

gameOver = function()
  dbg.print("Game over")
  ui_blocked = true

  update_timer:pause()

  local overlay = director:createSprite(0, 0, "assets/dialog_overlay.png")
  local dialog = director:createSprite(259, 179, "assets/game_over.png")

  local db_path = system:getFilePath("storage", "settings.sqlite")
  dbg.print("DB Path: " .. db_path)
  local db = sqlite3.open(db_path)

  local lowest_high_score = 0
  for row in db:nrows("SELECT * FROM high_scores WHERE game = " .. game_mode .. " ORDER BY score LIMIT 1 OFFSET 9") do
    lowest_high_score = row.score
  end

  if score > lowest_high_score then
    db:exec(string.format([[INSERT INTO high_scores VALUES (NULL, %i, %i); ]], game_mode, score))
    local new_highscore = director:createSprite(160, 97, "assets/new_highscore.png")
    dialog:addChild(new_highscore)
  end

  db:close()

  drawScore(score, 275, 178, dialog)

  local back = director:createSprite(20, 25, "assets/back.png")
  local restart = director:createSprite(265, 25, "assets/restart.png")
  dialog:addChild(back)
  dialog:addChild(restart)

  overlay:addChild(dialog)
  background:addChild(overlay)

  back:addEventListener("touch", function(event)
    if event.phase == "ended" then
      audio:playSound("sounds/simple_click.wav")
      ui_blocked = false
      overlay:removeFromParent()
      director:moveToScene(menu_scene, { transitionType = "slideInL", transitionTime = 0.5 } )
    end
  end)
  restart:addEventListener("touch", function(event)
    if event.phase == "ended" then
      audio:playSound("sounds/simple_click.wav")
      overlay:removeFromParent()
      initGame()
      countdown:play()
    end
  end)
end

updateTimeLabel = function()
  if game_mode ~= MODE_TEN_NUMBERS then
    time_left = time_left - 1
  else
    time_left = time_left + 1
  end

  local minutes = math.floor(time_left / 60)
  local seconds = time_left % 60

  for i = 1, # time_label do
    time_label[i]:removeFromParent()
  end
  time_label = {}


  time_label[1] = director:createSprite(0, 257, "assets/font_white_small/" .. (minutes%10) .. ".png")
  time_label[1].x = 890 - time_label[1].w - 3
  time_label[2] = director:createSprite(0, 257, "assets/font_white_small/" ..   math.floor(minutes/10) .. ".png")
  time_label[2].x = 890 - time_label[1].w - time_label[2].w - 6
  time_label[3] = director:createSprite(0, 257, "assets/font_white_small/" .. math.floor(seconds/10) .. ".png")
  time_label[3].x = 890 + 6
  time_label[4] = director:createSprite(917, 257, "assets/font_white_small/" .. (seconds%10) .. ".png")
  time_label[4].x = 890 + time_label[3].w + 9

  for i = 1, # time_label do
    time_label[i]:sync()
    background:addChild(time_label[i])
  end

  if time_left == 0 and game_mode ~= MODE_TEN_NUMBERS then
    gameOver()
  end
end

updateScoreLabel = function()
  dbg.print("Updating score to " .. score)

  for i = 1, # score_label do
    score_label[i]:removeFromParent()
  end
  score_label = drawScore(score, 890, 157, background)
end

updateNumbersLeftLabel = function()
  dbg.print("Updating numbers to " .. numbers_left)

  for i = 1, # score_label do
    score_label[i]:removeFromParent()
  end
  score_label = drawScore(numbers_left, 890, 157, background)
end

showPaused = function(params)
  if ui_blocked == true then
    return
  end
  
  audio:playSound("sounds/simple_click.wav")
  ui_blocked = true
  
  dbg.print("Showing pause dialog")
  update_timer:pause()

  local overlay = director:createSprite(0, 0, "assets/dialog_overlay.png")
  local high_scores = director:createSprite(118, 20, "assets/paused.png")
  overlay:addChild(high_scores)
  
  local back = director:createSprite(143, 80, "assets/back2.png")
  high_scores:addChild(back)
  
  local resume = director:createSprite(143, 230, "assets/resume.png")
  high_scores:addChild(resume)
  
  background:addChild(overlay)

  resume:addEventListener("touch", function(event)
    if event.phase == "ended" then
      ui_blocked = false
      audio:playSound("sounds/simple_click.wav")
      overlay:removeFromParent()
      update_timer:resume()
    end
  end)
  
  back:addEventListener("touch", function(event)
    if event.phase == "ended" then
      ui_blocked = false
      audio:playSound("sounds/simple_click.wav")
      overlay:removeFromParent()
      director:moveToScene(menu_scene, { transitionType = "slideInL", transitionTime = 0.5 } )
    end
  end)

end

local scene = director:createScene()
scene.name = "Game"
scene:addEventListener( { "setUp" }, initGame )
return scene