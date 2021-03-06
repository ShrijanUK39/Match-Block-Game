PlayState = Class{__includes = BaseState}

function PlayState:init()

    
    self.boardCursorX = 0
    self.boardCursorY = 0

    
    self.cursorX = 0
    self.cursorY = 0
    self.score = 0
    self.timer = 60
    self.cursorBoundLow = 0
    self.cursorBoundHigh = 256

    
    self.rectHighlighted = false

    self.canInput = true

    self.highlightedTile = nil

    self.matches = {}

    


    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    
    Timer.every(1, function()
        self.timer = self.timer - 1

        
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)
end

function PlayState:enter(params)

    
    self.level = params.level

    
    self.board = params.board or Board(GRID_START_X, GRID_START_Y, self.level)

    
    self.score = params.score or 0

    
    self.scoreGoal = self.level * 1.5 * 500

    
    self.transitionAlpha = params.alpha
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    self.board:update(dt)
    if self.board:checkIfStuck() then
        gStateMachine:change('reset', {
            score = self.score,
            timer = self.timer,
            level = self.level,
            goal = self.scoreGoal
        })
    end




    
    self.cursorX, self.cursorY = love.mouseCoordinates()
    if self.cursorX == nil then
        self.cursorX = VIRTUAL_WIDTH + 272
    end
    if self.cursorY == nil then
        self.cursorY = GRID_START_Y
    end
    
    self.cursorX = self.cursorX - VIRTUAL_WIDTH + 272
    self.cursorY = self.cursorY - GRID_START_Y

    
    if self.timer <= 0 then

        
        Timer.clear()

        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    
    if self.score >= self.scoreGoal then

        
        Timer.clear()

        gSounds['next-level']:play()

        
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput and self:mouseInBounds() then
        
        self.boardCursorX = math.floor(self.cursorX / 32)
        self.boardCursorY = math.floor(self.cursorY / 32)

        
        if love.mouse.wasPressed(1) then

            
            local x = math.min(math.max(0, self.boardCursorX) + 1, 8)
            local y = math.min(math.max(0, self.boardCursorY) + 1, 8)

            
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]
                gSounds['select']:stop()
                gSounds['select']:play()

            
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:stop()
                gSounds['error']:play()
                self.highlightedTile = nil
            else

                
                local tempX = self.highlightedTile.gridX
                local tempY = self.highlightedTile.gridY

                local newTile = self.board.tiles[y][x]

                self.highlightedTile.gridX = newTile.gridX
                self.highlightedTile.gridY = newTile.gridY
                newTile.gridX = tempX
                newTile.gridY = tempY

                
                self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                    self.highlightedTile

                self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                local match = self.board:calculateMatches()

              
                Timer.tween(0.1, {
                    [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                    [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                }):finish(function()
                   
                    if match == false then
                        Timer.tween(0.1, {
                            [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                            [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                        })
                        tempX = self.highlightedTile.gridX
                        tempY = self.highlightedTile.gridY

                        self.highlightedTile.gridX = newTile.gridX
                        self.highlightedTile.gridY = newTile.gridY

                        newTile.gridX = tempX
                        newTile.gridY = tempY

                        self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                            self.highlightedTile
                        self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                        gSounds['error']:stop()
                        gSounds['error']:play()

                        self.highlightedTile = nil
                    else
                        self.matches = match
                        self:calculateMatches()
                    end
                end)
            end
        end
    end
    
    Timer.update(dt)
    end


function PlayState:calculateMatches()
    self.highlightedTile = nil

    
    if self.matches == nil then
        self.matches = self.board:calculateMatches()
    end

    if self.matches then
        gSounds['match']:stop()
        gSounds['match']:play()

        
        for k, match in pairs(self.matches) do
            self.score = self.score + #match * 50
             
            for i, tile in pairs(match) do
                self.score = self.score + tile.variety * 10 - 10
            
            self.timer = self.timer + 1
        end
    end

        
        self.board:removeMatches()
        self.matches = nil

        
        local tilesToFall = nil
        local tileCount = 0
        tilesToFall, tileCount = self.board:getFallingTiles()
        tileCount = math.max(tileCount, 7)

      

        Timer.tween(0.07 * tileCount, tilesToFall):finish(function()

            self:calculateMatches()
        end)

    
    else
        self.canInput = true
    end
end

function PlayState:mouseInBounds()
    if (self.cursorX >= self.cursorBoundLow) and
       (self.cursorY >= self.cursorBoundLow) and
       (self.cursorX <= self.cursorBoundHigh) and
       (self.cursorY <= self.cursorBoundHigh) then
        return true
    else
        return false
    end
end

function PlayState:render()
    self.board:render()

    
    if self.highlightedTile then

        love.graphics.setBlendMode('add')

        love.graphics.setColor(255/255, 255/255, 255/255, 96/255)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (GRID_START_X),
            (self.highlightedTile.gridY - 1) * 32 + GRID_START_Y, 32, 32, 4)

        
        love.graphics.setBlendMode('alpha')
    end

    
    if self.rectHighlighted then
        love.graphics.setColor(217/255, 87/255, 99/255, 255/255)
    else
        love.graphics.setColor(172/255, 50/255, 50/255, 255/255)
    end

  
    if self:mouseInBounds() then
        love.graphics.setLineWidth(4)
        love.graphics.rectangle('line', self.boardCursorX * 32 + (GRID_START_X),
            self.boardCursorY * 32 + GRID_START_Y, 32, 32, 4)
    end

   
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)

    love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99/255, 155/255, 255/255, 255/255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')
end
