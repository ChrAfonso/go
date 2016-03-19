EMPTY = 0
BLACK = 1
WHITE = 2

drawLastMoveLiberties = true
drawLastMoveConnectedStones = true

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
  for i = 1,boardsize do
    for j = 1,boardsize do
      if board[i][j] ~= EMPTY then drawStone(makeStone(i, j, board[i][j])) end
    end
  end
  
  if lastMove ~= nil then
    drawLastMove()
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

function drawLastMove()
  if lastMove == nil then return end

  love.graphics.setColor(255, 0, 0)
  love.graphics.circle("line", x(lastMove.stone.x), y(lastMove.stone.y), padding/3)

  if drawLastMoveLiberties then
    love.graphics.setColor(255, 255, 0)
    for _,liberty in pairs(lastMove.liberties) do
      love.graphics.circle("fill", x(liberty.x), y(liberty.y), padding/4)
    end
  end

  if drawLastMoveConnectedStones then
    love.graphics.setColor(255, 255, 0)
    for _,stone in pairs(lastMove.connectedStones) do
      love.graphics.circle("line", x(stone.x), y(stone.y), padding/2)
    end
  end
end

function x(i)
  return 2*padding + (i-1)*padding
end

function y(j)
  return 2*padding + (j-1)*padding
end

function love.keypressed(k,s,r)
  step()
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
  local s = makeStone(i, j, col)
  table.insert(moves, s)
  board[i][j] = col
  move = move + 1
  
  local connectedStones = getConnectedStones(i, j)
  local liberties = getLiberties(connectedStones)
  lastMove = {
    stone = s,
    liberties = liberties,
    connectedStones = connectedStones
  }
  
  removeDeadGroups()
end

function removeDeadGroups()
  -- TODO make less crude
  for i = 1,boardsize do
    for j = 1,boardsize do
      local connectStones = getConnectedStones(i, j)
      if getNumLiberties(connectStones) == 0 then
        local color = board[i][j] -- TODO for counting
        for _,stone in pairs(connectStones) do
          board[stone.x][stone.y] = EMPTY
        end
      end
    end
  end
end

function getCurrentColor()
  if move % 2 == 1 then
    return BLACK
  else
    return WHITE
  end
end

function getFreePositions()
  local positions = getFreePoints()
  return #positions
end

function checkEnd()
  if getFreePoints() == 0 then
    os.exit()
  end
end

function getConnectedStones(i, j)
  if board[i][j] == EMPTY then return {} end
  
  local stones = {makeStone(i, j, board[i][j])}
  getConnectedStonesR(i, j, stones)
  return stones
end

function getConnectedStonesR(i, j, stones)
  for _,position in pairs(getSurroundingPositions(i, j)) do
    local m,n = position[1], position[2]
    if board[i][j] == board[m][n] and not isStoneInTable(m, n, stones) then
      table.insert(stones, makeStone(m, n, board[m][n]))
      getConnectedStonesR(m, n, stones)
    end
  end
end

function getSurroundingPositions(i, j)
  local positions = {}
  for _,position in pairs({{i-1,j},{i+1,j},{i,j-1},{i,j+1}}) do
    if isPositionOnBoard(position[1], position[2]) then
      table.insert(positions, position)
    end
  end
  return positions 
end

function getNumLiberties(stones)
  local liberties = getLiberties(stones)
  return #liberties
end

function getLiberties(stones)
  local liberties = {}
  for _,stone in pairs(stones) do
    collectLiberties(stone.x, stone.y, liberties)
  end
  return liberties
end

function collectLiberties(i, j, liberties)
  for _,position in pairs(getSurroundingPositions(i, j)) do
    if board[position[1]][position[2]] == EMPTY
    and not isStoneInTable(position[1], position[2], liberties) then
      table.insert(liberties, {x=position[1], y=position[2]})
    end
  end
end

function makeStone(i, j, col)
  return {x=i, y=j, color=col}
end

function isStoneInTable(i, j, t)
  for _,s in pairs(t) do
    if s.x == i and s.y == j then
      return true
    end
  end
  return false
end

function isPositionOnBoard(i, j)
  if (i >= 1) and (i <= boardsize) and (j >= 1) and (j <= boardsize) then
    return true
  else
    return false
  end
end
