EMPTY = 0
BLACK = 1
WHITE = 2

function love.load()
  -- init
  boardsize = 5
  padding = 30
  
  love.window.setMode(padding*(boardsize+3), padding*(boardsize+3))
  
  board = {}
  for i = 1,boardsize do
    board[i] = {}
    for j = 1,boardsize do
      board[i][j] = EMPTY
    end
  end

  move = 1

  moves = {}
end

function love.draw()
  love.graphics.clear()

  -- background
  love.graphics.setColor(63, 63, 63)
  love.graphics.rectangle("fill", 0, 0, 600, 600)

  -- board
  love.graphics.setColor(255, 127, 0)
  love.graphics.rectangle("fill", padding, padding, padding*(boardsize+1), padding*(boardsize+1))

  -- grid
  love.graphics.setColor(0, 0, 0)
  for i = 0,boardsize-1 do
    love.graphics.line(2*padding,2*padding+i*padding,2*padding+padding*(boardsize-1),2*padding+i*padding)
    love.graphics.line(2*padding+i*padding,2*padding,2*padding+i*padding,2*padding+padding*(boardsize-1))
  end

  -- stones
  for stone = 1,move-1 do
    drawStone(moves[stone])
  end
end

function drawStone(stone)
  if stone.color == BLACK then
    love.graphics.setColor(0, 0, 0)
  else
    love.graphics.setColor(255, 255, 255)
  end

  love.graphics.circle("fill", x(stone.x), y(stone.y), padding/2)
end

function x(i)
  return 2*padding + (i-1)*padding
end

function y(j)
  return 2*padding + (j-1)*padding
end

function love.keypressed(k,s,r)
  if k == "space" then
    step()
  end
end

function step()
  randomMove() -- starting point
  checkEnd()
end

function randomMove()
  local freePoints = getFreePoints()
  local n = #freePoints
  if n > 0 then
    local p = love.math.random(1,n)
    local point = freePoints[p]
    placeStone(point.x, point.y, getCurrentColor())
  end
end

function getFreePoints()
  local freePoints = {}
  for i = 1,boardsize do
    for j = 1,boardsize do
      if board[i][j] == EMPTY then
        table.insert(freePoints,{x=i,y=j})
      end
    end
  end

  return freePoints
end

function placeStone(i, j, col)
  table.insert(moves, {x=i,y=j,color=col})
  board[i][j] = color
  move = move + 1
end

function getCurrentColor()
  if move % 2 == 1 then
    return BLACK
  else
    return WHITE
  end
end

function checkEnd()
  if move > (boardsize*boardsize + 1) then
    os.exit()
  end
end

