import "CoreLibs/crank"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics

local PLAYDATE_SCREEN_WIDTH <const> = 400;
local PLAYDATE_SCREEN_HEIGHT <const> = 240;

-- Player.
local playerImage
local playerSadImage
local playerImageCurrent

local playerSprite
local playerSpriteIsFlipped
local playerWidth
local playerHeight
local playerX
local playerY
local playerVelocityX
local playerVelocityY
local playerThrust
local playerFriction
local playerMaxRotation

local crankPos
local crankEnabled

local blockImage
local blockData
local blockSpeed

local soundDrop1, soundDrop2, soundDrop3, soundBlast

function initGame()

    -- Set maximum refresh rate.
    playdate.display.setRefreshRate(50)

    -- Disable crank sounds since there's a custom one.
    playdate.setCrankSoundsDisabled(true)

    -- Prepare player images.
    playerImage = gfx.image.new("images/pockety")
    playerSadImage = gfx.image.new("images/pockety-sad")
    
    -- Check initial crank state.
    crankEnabled = not playdate.isCrankDocked()
    if crankEnabled then
        playerImageCurrent = playerSadImage
    else
        playerImageCurrent = playerImage
    end
    
    -- Add player sprite.
    playerSprite = gfx.sprite.new( playerImageCurrent )
    playerSprite:setZIndex(10)
    playerSprite:add()
    playerSpriteIsFlipped = false
    
    -- Set up sounds.
    soundDrop1 = playdate.sound.sampleplayer.new("sounds/drop1")
    soundDrop2 = playdate.sound.sampleplayer.new("sounds/drop2")
    soundDrop3 = playdate.sound.sampleplayer.new("sounds/drop3")
    soundBlast = playdate.sound.sampleplayer.new("sounds/blast")

    -- Prepare block.
    blockImage = gfx.image.new("images/ball")
    blockData = {}
    blockSpeed = 16
    
    -- Initial game reset.
    resetGame()
end

function resetGame()

    -- Init or reset player vars.
    playerWidth = 80
    playerHeight = 96
    
    playerX = 50
    playerY = PLAYDATE_SCREEN_HEIGHT - 20
    
    playerVelocityX = 0
    playerVelocityY = 0
    
    playerThrust = 0.4
    playerFriction = 0.9
    playerMaxRotation = 8

end

initGame()

function playdate.update()

    -- Player movement.
    if playdate.buttonIsPressed( playdate.kButtonRight ) then
        playerVelocityX = playerVelocityX + playerThrust
    end
    if playdate.buttonIsPressed( playdate.kButtonLeft ) then
        playerVelocityX = playerVelocityX - playerThrust
    end
    if playdate.buttonIsPressed( playdate.kButtonUp ) then
        playerVelocityY = playerVelocityY - playerThrust
    end
    if playdate.buttonIsPressed( playdate.kButtonDown ) then
        playerVelocityY = playerVelocityY + playerThrust
    end

    -- Reset button.
    if playdate.buttonIsPressed( playdate.kButtonA ) then
        resetGame()
    end

    -- Apply friction.
    playerVelocityX = playerVelocityX * playerFriction
    playerVelocityY = playerVelocityY * playerFriction
    
    -- Flip player sprite as needed.
    if playerVelocityX < 0 then
        playerSpriteIsFlipped = true
        setPlayerImage()
    elseif playerVelocityX > 0 then
        playerSpriteIsFlipped = false
        setPlayerImage()
    end
    
    -- Apply velocity.
    playerX = playerX + playerVelocityX
    playerY = playerY + playerVelocityY

    -- Limit player to screen bounds.
    if playerX < playerWidth then
        playerX = playerWidth
        playerVelocityX = 0
    elseif playerX > PLAYDATE_SCREEN_WIDTH then
        playerX = PLAYDATE_SCREEN_WIDTH
        playerVelocityX = 0
    end
    if playerY < (playerHeight) then
        playerY = playerHeight
        playerVelocityY = 0
    elseif playerY > PLAYDATE_SCREEN_HEIGHT then
        playerY = PLAYDATE_SCREEN_HEIGHT
        playerVelocityY = 0
    end

    -- Crank it.
    crankPos = playdate.getCrankPosition()
    local ticks = playdate.getCrankTicks(math.random(8,30))
    if crankEnabled and ticks ~= 0 then
        
        -- Play a random crank sound.
        local soundNum = math.random(1, 3)
        if soundNum == 1 then
            soundDrop1:play(1)
        elseif soundNum == 2 then
            soundDrop2:play(1)
        elseif soundNum == 3 then
            soundDrop3:play(1)
        end

        -- Create new block.
        local newBlockSprite = gfx.sprite.new( blockImage )
        newBlockSprite:setScale((math.random() * 2.5) + 0.5)
        newBlockSprite:add()
        newBlockSprite:moveTo(playerX - (playerWidth / 2), playerY - (playerHeight / 2))
        
        -- Determine block vector.
        local adjustedCrankPos = crankPos - 90;
        local angle = math.rad(adjustedCrankPos)
        table.insert(blockData, { newBlockSprite,  {math.cos(angle), math.sin(angle), newBlockSprite:getScale()}})
    end

    -- Block movement.
    local toRemove = {}
    for i, block in ipairs(blockData) do
        block[1]:moveBy(blockSpeed * block[2][1], blockSpeed * block[2][2])
        
        -- Half of the scaled sprite size. 
        local buffer = (16 * block[2][3]) / 2
        
        -- Mark blocks for removal if outside the screen bounds.
        if block[1].x < -buffer or block[1].x > PLAYDATE_SCREEN_WIDTH + buffer then
            table.insert(toRemove, i)
        elseif block[1].y < -buffer or block[1].y > PLAYDATE_SCREEN_HEIGHT + buffer then
            table.insert(toRemove, i)
        end
    end
    
    -- Remove any off-screen blocks.
    for i = #toRemove,1,-1 do
        blockData[toRemove[i]][1]:remove()
        table.remove(blockData, toRemove[i])
    end
    
    -- Draw and rotate sprites.
    playerSprite:moveTo( playerX - (playerWidth / 2), playerY - (playerHeight / 2) )
    if playerSpriteIsFlipped then
        playerSprite:setRotation(-crankPos)
    else
        playerSprite:setRotation(crankPos)
    end

    -- Apply some rotation while moving, unless cranking.
    if playdate.isCrankDocked() then
        playerSprite:setRotation(-math.abs((playerVelocityX / 1) * playerMaxRotation))
    end
    
    -- Update sprites.
    gfx.sprite.update()
    
    -- Update timers.
    playdate.timer.updateTimers()
    
end

function playdate.crankUndocked()
    soundBlast:play(1);
    playerImageCurrent = playerSadImage

    setPlayerImage()
    
    -- Apply crank rotation after a delay, for presentation purposes.
    playdate.timer.performAfterDelay(500, function()
        if not playdate.isCrankDocked() then
            crankEnabled = true
        end
    end)
end

function playdate.crankDocked()
    playerImageCurrent = playerImage
    setPlayerImage()

    crankEnabled = false
end

-- Apply new player image without changing flipped state.
function setPlayerImage()
    if playerSpriteIsFlipped then
        playerSprite:setImage(playerImageCurrent, "flipX")
    else
        playerSprite:setImage(playerImageCurrent)
    end
end