Class = require 'lib/class'

push = require 'lib/push'


Timer = require 'lib/knife.timer'




require 'src/StateMachine'
require 'src/Util'

require 'src/states/ResetState'


require 'src/Board'
require 'src/Tile'

require 'src/states/BaseState'
require 'src/states/BeginGameState'
require 'src/states/GameOverState'
require 'src/states/PlayState'
require 'src/states/StartState'



gSounds = {
    ['music'] = love.audio.newSource('sounds/match3music.mp3','static'),
    ['select'] = love.audio.newSource('sounds/select.wav','static'),
    ['error'] = love.audio.newSource('sounds/error.wav','static'),
    ['match'] = love.audio.newSource('sounds/match.wav','static'),
    ['clock'] = love.audio.newSource('sounds/clock.wav','static'),
    ['game-over'] = love.audio.newSource('sounds/game-over.wav','static'),
    ['next-level'] = love.audio.newSource('sounds/teleport.mp3','static')
}

gTextures = { 
    ['shiny'] = love.graphics.newImage('graphics/shiny.png'),
    ['main'] = love.graphics.newImage('graphics/match3.png'),
    ['background'] = love.graphics.newImage('graphics/background.png')  
}

gFrames = {

    ['tiles'] = GenerateTileQuads(gTextures['main'])
}

gFonts = {
    ['small'] = love.graphics.newFont('fonts/font.ttf', 8),
    ['medium'] = love.graphics.newFont('fonts/font.ttf', 16),
    ['large'] = love.graphics.newFont('fonts/font.ttf', 32),
    ['max'] = love.graphics.newFont('fonts/font.ttf', 48)
}
