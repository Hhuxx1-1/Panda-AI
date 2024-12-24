-- Define the MAZE module
MAZE = {}
MAZE.__index = MAZE

-- Create a new maze object
function MAZE:NEW()
    local maze = {}
    setmetatable(maze, MAZE)
    maze.structure = {} -- Stores the maze structure as a table
    return maze
end

-- Helper function to check if a position is within bounds
local function isInBounds(x, z, startX, startZ, dimX, dimZ)
    return x >= startX and x < startX + dimX and z >= startZ and z < startZ + dimZ
end

-- Helper function to calculate distance between two points
local function distance(x1, z1, x2, z2)
    return math.sqrt((x2 - x1)^2 + (z2 - z1)^2)
end

-- Helper function to calculate the length of a table
local function getLength(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Generate the base maze
function MAZE:GenerateBase(startPosition, dimensions, endPosition)
    local startX, startZ = startPosition[1], startPosition[2]
    local dimX, dimZ = dimensions[1], dimensions[2]
    local endX, endZ = endPosition[1], endPosition[2]

    -- Initialize the maze structure
    self.structure = {}

    -- Mark all cells as walls initially
    local mazeGrid = {}
    for x = startX, startX + dimX - 1 do
        mazeGrid[x] = {}
        for z = startZ, startZ + dimZ - 1 do
            mazeGrid[x][z] = "wall"
        end
    end

    -- Generate random key points for the path
    local keyPoints = {{x = startX, z = startZ}}
    local numPoints = math.floor(dimX * dimZ / 10) -- Choose a number of random points proportional to the maze size

    for _ = 1, numPoints do
        local randX = math.random(startX + 1, startX + dimX - 2)
        local randZ = math.random(startZ + 1, startZ + dimZ - 2)

        -- Ensure spacing between points
        if mazeGrid[randX][randZ] == "wall" then
            table.insert(keyPoints, {x = randX, z = randZ})
        end
    end

    table.insert(keyPoints, {x = endX, z = endZ})

    -- Connect key points to form a path
    local connectedPoints = {keyPoints[1]}
    table.remove(keyPoints, 1)

    for _ = 1, getLength(keyPoints) do
        local lastPoint = connectedPoints[#connectedPoints]
        local closestIndex = nil
        local closestDistance = math.huge

        for i, point in pairs(keyPoints) do
            local d = distance(lastPoint.x, lastPoint.z, point.x, point.z)
            if d < closestDistance then
                closestDistance = d
                closestIndex = i
            end
        end

        if closestIndex then
            local nextPoint = keyPoints[closestIndex]
            table.remove(keyPoints, closestIndex)

            -- Create a smooth path
            local cx, cz = lastPoint.x, lastPoint.z
            while cx ~= nextPoint.x or cz ~= nextPoint.z do
                mazeGrid[cx][cz] = "path"

                if cx < nextPoint.x then cx = cx + 1 elseif cx > nextPoint.x then cx = cx - 1 end
                if cz < nextPoint.z then cz = cz + 1 elseif cz > nextPoint.z then cz = cz - 1 end
            end

            mazeGrid[nextPoint.x][nextPoint.z] = "path"
            table.insert(connectedPoints, nextPoint)
        end
    end

    -- Fill the fake paths, maintaining gaps
    for x = startX + 1, startX + dimX - 2 do
        for z = startZ + 1, startZ + dimZ - 2 do
            if mazeGrid[x][z] == "wall" and math.random() < 0.3 then -- 30% chance to create a fake path
                if mazeGrid[x - 1][z] == "wall" and mazeGrid[x + 1][z] == "wall" and
                   mazeGrid[x][z - 1] == "wall" and mazeGrid[x][z + 1] == "wall" then
                    mazeGrid[x][z] = "path"
                end
            end
        end
    end

    -- Convert maze grid to structure format
    for x = startX, startX + dimX - 1 do
        for z = startZ, startZ + dimZ - 1 do
            table.insert(self.structure, {
                x = x,
                z = z,
                t = mazeGrid[x][z]
            })
        end
    end

    return self.structure
end

-- Create the maze in the world using an API
function MAZE:Create(blockAPI, blockID, facing)
    for _, cell in ipairs(self.structure) do
        if cell.t == "wall" then
            blockAPI:placeBlock(blockID, cell.x, 10, cell.z, facing) -- Assume y = 0 for all cells
        end
    end
end

-- Example script to demonstrate usage
ScriptSupportEvent:registerEvent("Game.Start", function()
    local Maze1 = MAZE:NEW()
    Maze1:GenerateBase({0, 0}, {40, 40}, {39, 9}) -- Y parameter removed, 2D maze
    Maze1:Create(Block, 501, 1)
end)
