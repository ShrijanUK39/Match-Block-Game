Board = Class{}

function Board:init(x, y, level) 
    self.colorCount = 6
    self.varietyCount = 5
    self.tilesInPlay = {}
    self.x = x
    self.y = y
    self.level = level
    self.matches = {}


    self:initializeTiles()
end


function Board:tileCreator(xposition, yposition)
    local colorsPossible = {4, 9, 11, 12, 17, 18}
    local color = colorsPossible[math.floor(math.random(self.colorCount))]

    local variety = math.random(math.min(math.random(self.level) / 1, self.varietyCount))
    local shiny = (math.random(122) <= 32)
    local tile = Tile(xposition, yposition, color, variety, shiny)

    
    if self.tilesInPlay[color] ==  nil then
        self.tilesInPlay[color] = {}
        for i=1, self.varietyCount do
            self.tilesInPlay[color][i] = 0
        end
    end

    self.tilesInPlay[color][variety] = self.tilesInPlay[color][variety] + 1
    return tile
end

function Board:initializeTiles()
    self.tiles = {}

    for tileY = 1, 8 do

        
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            local tile = self:tileCreator(tileX, tileY)
            table.insert(self.tiles[tileY], tile)
        end
    end

    self:eraseBoard()
    self:getFallingTiles()
    self:tileCascade(1, 8)

    while self:calculateMatches() do
        self:initializeTiles()
    end
end



function Board:calculateMatches()

    local matches = {}

   
    local matchNum = 1

    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1

        for x = 2, 8 do

            
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else

               
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for x2 = x - 1, x - matchNum, -1 do
                        if self.tiles[y][x2].shiny then
                            for x3 = 1, 8 do
                                table.insert(match, self.tiles[y][x3])
                            end
                            break
                        else
                            table.insert(match, self.tiles[y][x2])
                        end
                    end

                    
                    table.insert(matches, match)
                end

                matchNum = 1

        
                if x >= 7 then
                    break
                end
            end
        end

        
        if matchNum >= 3 then
            local match = {}

           
            for x = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end
    end

   
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                  
                    for y2 = y - 1, y - matchNum, -1 do
                        if self.tiles[y2][x].shiny then
                            for y3 = 1, 8 do
                                table.insert(match, self.tiles[y3][x])
                            end
                            break
                        else
                            table.insert(match, self.tiles[y2][x])
                        end
                    end

                    table.insert(matches, match)
                end

                matchNum = 1

                
                if y >= 7 then
                    break
                end
            end
        end

        
        if matchNum >= 3 then
            local match = {}

            
            for y = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end
    end

   
    self.matches = matches

    
    return #self.matches > 0 and self.matches or false
end



function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
           
            self.tilesInPlay[tile.color][tile.variety] = self.tilesInPlay[tile.color][tile.variety] - 1
           
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end
    self.matches = nil
end


function Board:tileCascade(x, y)
    self:tileFall(x, y)
    Timer.after(0.025, function()
        if x < 8 then
            x = x + 1
        elseif x == 8 and y >= 1 then
            y = y - 1
            x = 1
        end
        if y > 0 then
            self:tileCascade(x, y)
        end
    end)
end

--Only allow swapping when it results in a match.
function Board:tileFall(gridX, gridY)
    local destination = self.tiles[gridY][gridX].y + gridY * 32 + 32
    Timer.tween(0.1, { [self.tiles[gridY][gridX]] = {y = destination} })
end

--Only allow swapping when it results in a match.
function Board:eraseBoard()
    for y=1, 8 do
        for x=1, 8 do
            tile = self.tiles[y][x]
            --Only allow swapping when it results in a match.
            self.tilesInPlay[tile.color][tile.variety] = self.tilesInPlay[tile.color][tile.variety] - 1
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end
end


function Board:getFallingTiles()
    local tweens = {}

    local tileCount = 0

    
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do

            local tile = self.tiles[y][x]

            if space then

               
                if tile then

                    
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    
                    self.tiles[y][x] = nil

                    
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                  
                    space = false
                    y = spaceY

                    
                    spaceY = 0
                end
            elseif tile == nil then
                space = true

                
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

           
            if not tile then
                tileCount =  tileCount + 1

               
                local tile = self:tileCreator(x, y)
                tile.y = -64
                self.tiles[y][x] = tile

                
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens, tileCount
end


function Board:checkIfStuck()
    for y=1,8 do
        for x=1,8 do
            local selectTile = self.tiles[y][x]
            if self.tilesInPlay[selectTile.color][selectTile.variety] >= 3 then
                local adjacentTiles = {}
                if y < 8 then
                    table.insert(adjacentTiles, self.tiles[y + 1][x])
                end
                if x < 8 then
                    table.insert(adjacentTiles, self.tiles[y][x + 1])
                end
                for k, adjTile in pairs(adjacentTiles) do
                    -- Swapping tiles
                    local tempX = selectTile.gridX
                    local tempY = selectTile.gridY

                    selectTile.gridX = adjTile.gridX
                    selectTile.gridY = adjTile.gridY
                    adjTile.gridX = tempX
                    adjTile.gridY = tempY

                   
                    self.tiles[selectTile.gridY][selectTile.gridX] =
                        selectTile

                    self.tiles[adjTile.gridY][adjTile.gridX] = adjTile

                   
                    if self:calculateMatches() ~= false then
                        
                        local tempX = selectTile.gridX
                        local tempY = selectTile.gridY

                        selectTile.gridX = adjTile.gridX
                        selectTile.gridY = adjTile.gridY
                        adjTile.gridX = tempX
                        adjTile.gridY = tempY

                        
                        self.tiles[selectTile.gridY][selectTile.gridX] =
                            selectTile

                        self.tiles[adjTile.gridY][adjTile.gridX] = adjTile
                        return false
                    else
                        
                        local tempX = selectTile.gridX
                        local tempY = selectTile.gridY

                        selectTile.gridX = adjTile.gridX
                        selectTile.gridY = adjTile.gridY
                        adjTile.gridX = tempX
                        adjTile.gridY = tempY

                        
                        self.tiles[selectTile.gridY][selectTile.gridX] =
                            selectTile

                        self.tiles[adjTile.gridY][adjTile.gridX] = adjTile
                    end
                end
            end
        end
    end
    return true
end


function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end

function Board:update(dt)
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:update(dt)
        end
    end
end


