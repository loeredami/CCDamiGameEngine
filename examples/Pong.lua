local GameEngine = require("/lib/GameEngine").GameEngine

local pongGame = GameEngine.new()

pongGame.setMonitor("left")
pongGame.setSpeaker("top") 

-- Ball and paddle settings
local ball_velocity = 0.5 
local paddle_velocity = 2 
local winning_score = 10 

local button_sprite_up = pongGame.makeImgFromText(

[[-d-
d-d]])
local button_sprite_down = pongGame.makeImgFromText(

[[d-d
-d-]])
local ball = {
    sprite = pongGame.makeImgFromText(
[[9]]
    ),
    x = 5,
    y = 5,
    vx = ball_velocity,
    vy = ball_velocity
}

local paddle1 = {
    score = 0,
    y = 3,
    sprite = pongGame.makeImgFromText(
[[e
1
e
1
e]]
    )
}

local paddle2 = {
    score = 0,
    y = 3,
    sprite = pongGame.makeImgFromText(
[[b
3
b
3
b]]
    )
}

local function movePaddle(paddle, direction)
    local termW, termH = term.getSize()
    if direction == "up" and paddle.y > 1 then
        paddle.y = paddle.y - paddle_velocity
    elseif direction == "down" and paddle.y < termH-1 then
        paddle.y = paddle.y + paddle_velocity
    end
end

local function resetGame()
    local termW, termH = term.getSize()
    ball.x = termW/2
    ball.y = termH/2
    ball.vx = ball_velocity * (math.random(2) == 1 and 1 or -1) -- Randomize initial ball direction
    ball.vy = ball_velocity * (math.random(2) == 1 and 1 or -1)
    paddle1.score = 0
    paddle2.score = 0
end

local function displayWinner(winner)
    local termW, termH = term.getSize()
    paintutils.drawFilledBox(1, 1, termW, termH, colors.black)
    term.setCursorPos((termW / 2) - 5, (termH / 2) - 1)
    term.write(winner .. " Wins!")
    pongGame.speaker.playNote("harp", 1, 2) -- Change to desired sound
	sleep(1)    
	pongGame.speaker.playNote("harp", 1, 5) -- Change to desired sound
    sleep(1)
    pongGame.speaker.playNote("harp", 1, 9) -- Change to desired sound
    sleep(3)
end

local function playSoundScore()
    if pongGame.speaker then
        pongGame.speaker.playNote("harp", 1, 5) -- Change to desired sound
    end
end


local function playSoundCollide()
    if pongGame.speaker then
        pongGame.speaker.playNote("harp", 1, 0) -- Change to desired sound
    end
end

local function playSoundCollidePlayer()
    if pongGame.speaker then
        pongGame.speaker.playNote("harp", 1, 1) -- Change to desired sound
    end
end

pongGame.registerStartup(function()
    local termW, termH = term.getSize()
    ball.x = termW/2
    ball.y = termH/2
end)

pongGame.registerEvent(function(event)
    if event[1] == "monitor_touch" then
        local x, y = event[3], event[4]
        local termW, termH = term.getSize()

        -- Left paddle buttons
        if x >= 3 and x <= 6 then
            if y >= termH - 6 and y <= termH - 4 then
                movePaddle(paddle1, "up")
            elseif y >= termH - 3 and y <= termH - 1 then
                movePaddle(paddle1, "down")
            end
        end

        -- Right paddle buttons
        if x >= termW - 4 and x <= termW - 1 then
            if y >= termH - 6 and y <= termH - 4 then
                movePaddle(paddle2, "up")
            elseif y >= termH - 3 and y <= termH - 1 then
                movePaddle(paddle2, "down")
            end
        end
    end
end)

pongGame.registerUpdate(function()
    -- Check for winning condition
    if paddle1.score >= winning_score then
        displayWinner("Player 1")
        pongGame.running = false
        return
    elseif paddle2.score >= winning_score then
        displayWinner("Player 2")
        pongGame.running = false
        return
    end

    ball.x = ball.x + ball.vx
    ball.y = ball.y + ball.vy

    local termW, termH = term.getSize()

    -- Ball collision with walls
    if ball.x > termW then
        ball.vx = -ball_velocity
        paddle1.score = paddle1.score + 1
        ball.vy = ball_velocity
        playSoundScore() -- Play sound when player 1 scores
    end
    if ball.x <= 1 then
        ball.vx = ball_velocity
        paddle2.score = paddle2.score + 1
        ball.vy = ball_velocity
        playSoundScore() -- Play sound when player 2 scores
    end
    if ball.y > termH then
        ball.vy = -ball_velocity*1.01
        playSoundCollide()
    end
    if ball.y < 1 then
        ball.vy = ball_velocity*1.01
        playSoundCollide()
    end

    -- Ball collision with paddles
    if ball.x == 2 and ball.y >= paddle1.y and ball.y <= paddle1.y + 5 then
        ball.vx = ball_velocity
        playSoundCollidePlayer() -- Play sound when ball hits paddle 1
    end
    if ball.x == termW and ball.y >= paddle2.y and ball.y <= paddle2.y + 5 then
        ball.vx = -ball_velocity
        playSoundCollidePlayer() -- Play sound when ball hits paddle 2
    end
end)

pongGame.registerDraw(function()
    local termW, termH = term.getSize()
    paintutils.drawFilledBox(1, 1, termW, termH, colors.black)
    pongGame.drawSprite(ball.x - 1, ball.y - 1, ball.sprite)

    -- Draw paddles
    pongGame.drawSprite(1, paddle1.y, paddle1.sprite)
    pongGame.drawSprite(termW, paddle2.y, paddle2.sprite)

    -- Draw scores
    term.setBackgroundColor(colors.black)

    term.setCursorPos(2, 1)
    term.write("Score: " .. paddle1.score)

    term.setCursorPos(termW - 9, 1)
    term.write("Score: " .. paddle2.score)
end)

pongGame.registerDraw(function()
    local termW, termH = term.getSize()
    pongGame.drawSprite(3, termH - 6, button_sprite_up)
    pongGame.drawSprite(3, termH - 3, button_sprite_down)
    pongGame.drawSprite(termW - 4, termH - 6, button_sprite_up)
    pongGame.drawSprite(termW - 4, termH - 3, button_sprite_down)
end)

resetGame() -- Initialize the game state
pongGame.run()
