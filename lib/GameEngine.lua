local colourMap = {
    ["0"] = colors.white,
    ["1"] = colors.orange,
    ["2"] = colors.magenta,
    ["3"] = colors.lightBlue,
    ["4"] = colors.yellow,
    ["5"] = colors.lime,
    ["6"] = colors.pink,
    ["7"] = colors.gray,
    ["8"] = colors.lightGray,
    ["9"] = colors.cyan,
    ["a"] = colors.purple,
    ["b"] = colors.blue,
    ["c"] = colors.brown,
    ["d"] = colors.green,
    ["e"] = colors.red,
    ["f"] = colors.black
}
local GameEngine = {}

-- utility classes
local Vector3 = {}
local Vector2 = {}

function Vector3.new(x, y, z) 
    local vector3 = {
        x = x,
        y = y,
        z = z
    }
    return vector3
end

function Vector2.new(x, y) 
    local vector2 = {
        x = x,
        y = y
    }

    return vector2
end

-- Pseudo 2.5D Classic Doom like Renderer (uncoloured)
local P25DCDRenderer = {}

function P25DCDRenderer.new() 
    local WallGrid = {}
    local Object2D = {}
    local Camera = {}
    
    
    function Camera.new(position, angle)
        local camera = {
            position = position,
            angle = angle
        }

        return camera
    end

    function WallGrid.new(size, color) 
        local wall_grid = {
            color = color,
            grid = {}
        }

        for _ = 1, size.x, 1 do
            local row = {}
            for _ = 1, size.y, 1 do 
                table.insert(row, false)
            end
            table.insert(wall_grid.grid, row)
        end

        function wall_grid.set(position, is_wall)
            wall_grid.grid[position.x][position.y] = is_wall
        end

        function wall_grid.render(camera, screen) 
            
        end

        return wall_grid
    end

    function Object2D.new(position, texture)
        local object = {
            texture = texture,
            position = position
        }

        function object.renderScaled(screen_position, scale) 

        end

        return object
    end
    
    local renderer = {
        objects2D = {Object2D.new(Vector2.new(5, 5), {
            width=5,
            height=5,
            lines = {
                "-545-",
                "54445",
                "44444",
                "54445",
                "-545-"
            }
        })},
        wall_grid = WallGrid.new(Vector2.new(10, 10), "5"),
        RenderObject = {
            WallGrid = WallGrid,
            Object2D = Object2D,
            Camera = Camera
        }
    }

    function renderer.render(camera, screen) 
        renderer.wall_grid.render()
    end


    return renderer
end

function GameEngine.new()
    local game = {
        updateFunctions = {},
        drawFunctions = {},
        eventFunctions = {},
        startupFunctions = {},
        endFunctions = {},
        gameData = {},
        monitor = nil,
        speaker = nil,
        running = true
    }
    function game.importDrawing(filePath)
        local file = fs.open(filePath, "r")
        if not file then
            error("Could not open file: " .. filePath)
        end

        local lines = {}
        local width = 0
        local height = 0

        while true do
            local line = file.readLine()
            if not line then break end

            local convertedLine = ""
            for i = 1, #line do
                local c = line:sub(i, i)
                if c == " " then
                    convertedLine = convertedLine .. "-"  -- Convert spaces to dashes for empty pixels
                elseif colourMap[c] then
                    convertedLine = convertedLine .. c  -- Keep color codes as they are
                else
                    convertedLine = convertedLine .. "-"  -- If it's an invalid color, treat it as empty
                end
            end

            table.insert(lines, convertedLine)
            width = math.max(width, #convertedLine)  -- Ensure width is the longest line
            height = height + 1
        end

        file.close()

        -- Create the image data structure
        local image = {
            width = width,
            height = height,
            lines = lines
        }

        return image
    end


    function game.registerStartup(func) 
        table.insert(game.startupFunctions, func)
    end

    function game.registerEnd(func)
        table.insert(game.endFunctions, func)
    end

    function game.registerUpdate(func)
        table.insert(game.updateFunctions, func)
    end

    function game.registerDraw(func)
        table.insert(game.drawFunctions, func)
    end

    function game.registerEvent(func)
        table.insert(game.eventFunctions, func)
    end

    function game.setMonitor(side)
        game.monitor = peripheral.wrap(side)
        term.redirect(game.monitor)
    end

    function game.setSpeaker(side)
        game.speaker = peripheral.wrap(side)
    end

    function game.handleEvents()
        while game.running do
            local event = {os.pullEvent()}
            for _, eventFunc in ipairs(game.eventFunctions) do
                eventFunc(event)
            end
        end
    end

    function game.loop()
        while game.running do 
            for _, updateFunc in ipairs(game.updateFunctions) do 
                updateFunc()
            end

            for _, drawFunc in ipairs(game.drawFunctions) do 
                drawFunc()
            end

            sleep(0.1)
        end
    end

    function game.run()
        local eventCoroutine = coroutine.create(game.handleEvents)
        for _, startUpFunc in ipairs(game.startupFunctions) do 
            startUpFunc()
        end

        parallel.waitForAll(game.loop, game.handleEvents)
        
        for _, endFunc in ipairs(game.endFunctions) do 
            endFunc()
        end
    end

    function game.makeImgFromText(text)
        local lines = {}
        local height = 0
        local width = 0
        for s in text:gmatch("[^\r\n]+") do
            table.insert(lines, s)
            width = string.len(s)
            height = height + 1
        end
        local image = {
            width = width,
            height = height,
            lines = lines
        }
        return image
    end

    function game.drawSprite(x, y, imgData)
        local yOff = 0
        local termWidth, termHeight = term.getSize()
        for _, line in ipairs(imgData.lines) do
            for i = 1, #line do
                local c = line:sub(i, i)
                local rx = x + i - 1
                local ry = y + yOff
                if rx < termWidth + 1 and ry < termHeight + 1 and rx > 0 and ry > 0 and c ~= "-" then
                    paintutils.drawPixel(rx, ry, colourMap[c])
                end
            end
            yOff = yOff + 1
        end
    end

    return game
end

return {
    Version =  "1.0",
    GameEngine = GameEngine,
    Renderers = {
        P25DCDRenderer = P25DCDRenderer
    }
}
