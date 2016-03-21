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
  
  if lastMove ~= nil and lastMove ~= "pass" then
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
  randomMove() -- for now, start dumb
  checkEnd()
end

function randomMove()
  local col = getCurrentColor()
  local freePoints = getFreePoints()
  while #freePoints > 0 do
    print ("Free points to check: " .. #freePoints)
    local p = love.math.random(1,#freePoints)
    local point = freePoints[p]
    if isLegal(point.x, point.y, col) then
      placeStone(point.x, point.y, col)
      return
    else
      table.remove(freePoints,p)
    end
  end

  -- no legal free point found
  pass()
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
  
  -- only remove enemies, no suicide allowed
  removeDeadGroups(otherColor(col))
end

function otherColor(col)
  if col == BLACK then
    return WHITE
  elseif col == WHITE then
    return BLACK
  else
    return col
  end
end

function pass()
  -- if second consecutive pass, end game and start calculating
  if lastMove == "pass" then
    endGame()
  else
    lastMove = "pass"
  end
end

function removeDeadGroups(col)
  -- TODO make less crude
  for i = 1,boardsize do
    for j = 1,boardsize do
      if not col or col == board[i][j] then
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
    endGame()
  end
end

function endGame()
  -- TODO calculate points
  os.exit() -- TEMP
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

function getNumLibertiesAt(i, j)
  local libs = {}
  collectLiberties(i, j, libs)
  return #libs
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

function getSurroundingEnemies(stones)
  if #stones == 0 then return {} end
  
  surroundingStones = {}
  enemyColor = otherColor(stones[1].color)

  for _,stone in pairs(stones) do
    collectSurroundingEnemies(stone, surroundingStones, enemyColor)
  end

  return surroundingStones
end

function collectSurroundingEnemies(stone, surroundingStones, enemyColor)
  for _,position in pairs(getSurroundingPositions(stone.x, stone.y)) do
    if board[position[1]][position[2]] == enemyColor
    and not isStoneInTable(position[1], position[2], surroundingStones) then
      table.insert(surroundingStones, makeStone(position[1], position[2], enemyColor))
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

function isLegal(i, j, color)
  if board[i][j] ~= EMPTY then
    return false
  else
    -- place temp stone
    board[i][j] = color
    local con = getConnectedStones(i, j)
    local numlib = getNumLiberties(con)
    local killingSurrounders = false
    if numlib == 0 then
      surroundingEnemies = getSurroundingEnemies(con)
      for _,stone in pairs(surroundingEnemies) do
        if getNumLiberties(getConnectedStones(stone.x, stone.y)) == 0 then
	  killingSurrounders = true
	  break
	end
      end
    end
    board[i][j] = EMPTY
    
    if numlib == 0 and not killingSurrounders then
      return false
    -- TODO other cases (ko) -- cache board positions?
    else
      return true
    end
  end
end

