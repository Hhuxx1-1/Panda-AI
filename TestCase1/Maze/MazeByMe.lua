-- Define the MAZE Global Module Variable
MAZE = {}
MAZE.__index = MAZE

-- Create a new maze object
function MAZE:NEW()
    local maze = {}
    setmetatable(maze, MAZE)
    maze.structure = {} -- Stores the maze structure as a table
    return maze
end

-- Get Distance between Map Point
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


function MAZE:Ensort()
    local uniqueStructure = {}
    local seenPositions = {}

    -- Remove duplicates
    for _, cell in ipairs(self.structure) do
        local key = cell.x .. "," .. cell.z -- Create a unique key for each (x, z) coordinate
        if not seenPositions[key] then
            seenPositions[key] = true
            table.insert(uniqueStructure, cell)
        end
    end

-- Sort the unique structure by x first, then by z
-- table.sort(uniqueStructure, function(a, b)
--     if a.x == b.x then
--         return a.z < b.z -- Sort by z if x values are equal
--     else
--         return a.x < b.x -- Otherwise, sort by x
--     end
-- end)
table.sort(uniqueStructure, function(a, b)
    if a.z == b.z then
        -- Alternate between ascending and descending x based on z
        if a.z % 2 == 0 then
            return a.x < b.x -- Even rows: ascending x
        else
            return a.x > b.x -- Odd rows: descending x
        end
    else
        return a.z < b.z -- Sort by z coordinate first
    end
end)


self.structure = uniqueStructure
end

-- Visualize 2D Map
function MAZE:Create2DMap(startPoint, endPoint)
    local start = {x = startPoint.x, z = startPoint.z}
    local finish = {x = endPoint.x, z = endPoint.z}

    -- Initialize the maze structure
    self.structure = {};

    -- Dimension is everything between start and finish
    local dimension_size = {x = math.abs(start.x - finish.x), z = math.abs(start.z - finish.z)}

    -- Generate random points inside the dimension
    local pointWay = {}
    local backupPointWay = {};
    local substracter = math.random(3,8) * 4;
    local pointmax = math.max(math.floor(dimension_size.x * dimension_size.z / substracter), 4) 
    -- Make sure pointmax is odd
    if pointmax % 2 == 0 then
        pointmax = pointmax + 1
    end

    for i = 1, pointmax do
        pointWay[i] = {
            x = math.random(start.x, start.x + dimension_size.x),
            z = math.random(start.z, start.z + dimension_size.z)
        }
        backupPointWay[i] = {
            x = math.random(start.x, start.x + dimension_size.x),
            z = math.random(start.z, start.z + dimension_size.z)
        }
    end
    
    -- Function to draw a line between two points
    local function drawLine(x1, z1, x2, z2)
        -- Draw horizontal and then vertical (or vice versa)
        if x1 ~= x2 then
            local step = x1 < x2 and 1 or -1
            for x = x1, x2, step do
                table.insert(self.structure, {x = x, z = z1, t = "path"})
            end
        end
        if z1 ~= z2 then
            local step = z1 < z2 and 1 or -1
            for z = z1, z2, step do
                table.insert(self.structure, {x = x2, z = z, t = "path"})
            end
        end
    end

    -- for _, a in ipairs(backupPointWay) do
    --     table.insert(self.structure, {x = a.x, z = a.z, t = "Ppath"})
    -- end
    

    -- Create paths connecting points
    while getLength(pointWay) > 0 do
        local closestPoint = nil
        local closestDistance = math.huge
        local closestIndex = nil

        for i, point in ipairs(pointWay) do
            local d = distance(start.x, start.z, point.x, point.z)
            if d < closestDistance then
                closestDistance = d
                closestPoint = point
                closestIndex = i
            end
        end

        if closestPoint then
            drawLine(start.x, start.z, closestPoint.x, closestPoint.z)
            start = closestPoint -- Update starting point
            table.remove(pointWay, closestIndex)
        end
    end

    -- Draw a line from the endpoint to the closest point in backupPointWay
    local closestToEnd = nil
    local closestDistanceToEnd = math.huge
    for _, point in ipairs(backupPointWay) do
        local d = distance(finish.x, finish.z, point.x, point.z)
        if d < closestDistanceToEnd then
            closestDistanceToEnd = d
            closestToEnd = point
        end
    end
    if closestToEnd then
        drawLine(finish.x, finish.z, closestToEnd.x, closestToEnd.z)
    end

    -- Create a fake path connecting backupPointWay points
    while getLength(backupPointWay) > 1 do
        local current = table.remove(backupPointWay, 1)
        local closest = nil
        local closestIndex = nil
        local closestDistance = math.huge

        for i, point in ipairs(backupPointWay) do
            local d = distance(current.x, current.z, point.x, point.z)
            if d < closestDistance then
                closestDistance = d
                closest = point
                closestIndex = i
            end
        end

        if closest then
            drawLine(current.x, current.z, closest.x, closest.z)
            table.remove(backupPointWay, closestIndex)
        end
    end
    
-- Mark the outer region as walls and special paths
for x = startPoint.x - 1, endPoint.x + 1 do
        for z = startPoint.z - 1, endPoint.z + 1 do
            local isPath = false
            for _, cell in ipairs(self.structure) do
                if cell.x == x and cell.z == z then
                    isPath = true
                    break
                end
            end

            if not isPath then
                table.insert(self.structure, {x = x, z = z, t = "wall"})
            end
        end
    end

    -- Mark starting point as "Spath"
    table.insert(self.structure, {x = startPoint.x, z = startPoint.z, t = "Spath"})

    -- Mark end point as "Epath"
    table.insert(self.structure, {x = endPoint.x, z = endPoint.z, t = "Epath"})
end

local function renderMap(x,y,z,p,s)
    if s == nil then 
        s = 0
    end 
    Player:setPosition(0,x,y+12,z);
    Player:SetCameraRotTransformTo(0, {x=0,y=180}, 1, 0.1);
    -- Chat:sendSystemMsg("Proggress "..math.floor(p*100).."%")
    if s == 0 then 
        threadpool:wait(0.01);
    end 
end

function MAZE:MarkRooms()
    local roomThreshold = 4 -- Minimum number of connected path cells to form a room

    -- Helper function to check adjacent cells
    local function getAdjacentPaths(x, z)
        local adjacent = {}
        for _, cell in ipairs(self.structure) do
            if cell.t == "path" then
                if (math.abs(cell.x - x) <= 1 and cell.z == z) or (cell.x == x and math.abs(cell.z - z) <= 1) then
                    table.insert(adjacent, cell)
                end
            end
        end
        return adjacent
    end

    -- Iterate over the maze structure
    for _, cell in ipairs(self.structure) do
        if cell.t == "path" then
            local adjacentPaths = getAdjacentPaths(cell.x, cell.z)

            -- If the number of adjacent paths exceeds the threshold, mark as a room
            if #adjacentPaths >= roomThreshold then
                cell.t = "room"
                -- Optionally, mark all adjacent paths as part of the room
                for _, adjacentCell in ipairs(adjacentPaths) do
                    adjacentCell.t = "room"
                end
            end
        end
    end
end

function MAZE:MPathS()
    -- Helper function to check the type of a specific cell
    local function getCellType(x, z)
        for _, cell in ipairs(self.structure) do
            if cell.x == x and cell.z == z then
                return cell.t
            end
        end
        return nil -- Return nil if the cell doesn't exist
    end

    -- Helper function to count surrounding room cells
    local function countSurroundingRooms(x, z)
        local roomCount = 0
        local directions = {
            {dx = 1, dz = 0},  -- Right
            {dx = -1, dz = 0}, -- Left
            {dx = 0, dz = 1},  -- Down
            {dx = 0, dz = -1}  -- Up
        }
        for _, dir in ipairs(directions) do
            if getCellType(x + dir.dx, z + dir.dz) == "room" then
                roomCount = roomCount + 1
            end
        end
        return roomCount
    end

    -- Iterate over the maze structure
    for _, cell in ipairs(self.structure) do
        if cell.t == "path" then
            -- Check if the path is squeezed by counting surrounding room cells
            local surroundingRooms = countSurroundingRooms(cell.x, cell.z)
            if surroundingRooms >= 2 then -- Adjust this threshold as needed
                cell.t = "pathS" -- Mark as a squeezed path
            end
        end
    end
end


-- Create the maze in the world using an API
function MAZE:Create(blockAPI, blockID, facing)
    local y = 7;
    local dim = 2; -- dimension 
    local fullLength = getLength(self.structure);
    Chat:sendSystemMsg("Full Length : "..fullLength);
    for s, cell in ipairs(self.structure) do
        -- make the host render the map 
        local x , z = 2 + cell.x * (dim * 2.5), 2 + cell.z * (dim * 2.5);
        renderMap(x+0.5,y+2,z+0.5,s/fullLength,math.fmod(s,3));
        if cell.t == "wall" then
            for wallhigh = 1 , 10 do 
                for offsetx = -dim , dim do 
                    for offsetz = -dim , dim do
                        blockAPI:placeBlock(blockID, x + offsetx, y + wallhigh, z + offsetz);
                    end 
                end 
            end 
        elseif cell.t == "Spath" then 
            blockAPI:placeBlock(123, x, y, z, facing)
        elseif cell.t == "Epath" then 
            blockAPI:placeBlock(8, x, y, z, facing)
        elseif cell.t == "Ppath" then 
            blockAPI:placeBlock(687, x, y, z, facing)
        elseif cell.t == "room" then
            if math.fmod(s,10) == 0 then 
                threadpool:wait(0.1);
            end 
            for offsetx = -dim , dim do 
                for offsetz = -dim , dim do
                    blockAPI:placeBlock(29, x + offsetx, y , z + offsetz);
                end 
            end 
        elseif cell.t == "pathS" then
            for offsetx = -dim , dim do 
                for offsetz = -dim , dim do
                    blockAPI:placeBlock(233, x + offsetx, y , z + offsetz);
                end 
            end 
        else
            if math.fmod(s,10) == 0 then 
                threadpool:wait(0.1);
            end 
            for offsetx = -dim , dim do 
                for offsetz = -dim , dim do
                    blockAPI:placeBlock(667, x + offsetx, y , z + offsetz);
                end 
            end 
        end
    end
end

-- Example script to demonstrate usage
ScriptSupportEvent:registerEvent("Game.Start", function()
    local Maze1 = MAZE:NEW()
    Maze1:Create2DMap({x = 0, z = 0}, {x = 64, z = 64}) -- Generate the maze
    Maze1:Ensort() -- Sort in a render able pattern
    Maze1:MarkRooms();
    Maze1:MPathS();
    Maze1:Create(Block, 501, 1) -- Place the blocks
end)
