-- Run and Check each Created Creature as PANDA_AI
-- Stored inside PANDA_AI.Creature_Object 
PANDA_AI = {
    Creature_Object = {},
    ACTION = {},
    Counter = {},
    MEMORY = {}
}

function PANDA_AI:ISVALID(id)
    -- check if id has MEMORY defined if not then create new
    if PANDA_AI.MEMORY[id] == nil then
        PANDA_AI.MEMORY[id] = {}
        return true;
    else 
        return true;
    end 
end

function PANDA_AI:SET_MEMORY(id,NAME,DURATION,DATA)
    -- update the memory as Duration
    if PANDA_AI:ISVALID(id) then 
        PANDA_AI.MEMORY[id][NAME] = {DURATION = DURATION, DATA = DATA};
    end 
end

function PANDA_AI:GET_MEMORY(id,NAME)
    -- return the memory as Duration
    if PANDA_AI:ISVALID(id) then 
        return PANDA_AI.MEMORY[id][NAME] or {DURATION = 0 , DATA = {}};
    end 
end

function PANDA_AI:RUN_MEMORY(id,NAME)
    -- decrease the Memory by one 
    if PANDA_AI:ISVALID(id) then 
        local Memory = PANDA_AI:GET_MEMORY(id,NAME);
        if  Memory.DURATION > 0 then 
            PANDA_AI.MEMORY[id][NAME].DURATION = Memory.DURATION - 1; 
            return true;
        else
            if PANDA_AI.MEMORY[id][NAME] then 
                PANDA_AI.MEMORY[id][NAME].DURATION = 0;
            end 
            return false;
        end 
    end 
end

GET_LENGTH = function (t)      local c = 0 ; for i in pairs(t) do c = i; end return c; end ;

function PANDA_AI:NEW(id,x,y,z,data)
    local r,obj = World:spawnCreature(x,y,z,id,1);
    if r == 0 then
        PANDA_AI.Creature_Object[obj[1]] = data;
    end 
end

ScriptSupportEvent:registerEvent("Game.RunTime",function(e)
    for id,data in pairs(PANDA_AI.Creature_Object) do 
        for _, action in ipairs(data) do 
            if type(action) == "function" then 
                local code,error = pcall(function()
                    action(id);
                end);

                if not code then 
                    print("Error : ",error);
                end    
            end 
        end
    end 
end)

PANDA_AI.PATROL_DATA = {}; -- Store patrol data here

function PANDA_AI:TRY_PATROL(id, blockid)
    local offset_y = -1;
    local range = 10; -- Search in a radius of 10 blocks
    local max_recent_positions = 4; -- Max number of recent positions to track

    -- Initialize patrol data for the AI if not already set
    if PANDA_AI.PATROL_DATA[id] == nil then
        PANDA_AI.PATROL_DATA[id] = {recent_positions = {}};
    end

    -- Current position of the AI
    local x, y, z = MYTOOL.GET_POS(id);

    -- Store valid blocks with their distances
    local validBlocks = {};

    -- Search for a new patrol block
    for dx = -range, range do
        for dz = -range, range do
            local tx, ty, tz = x + dx, y + offset_y, z + dz;
            local result, foundBlockID = Block:getBlockID(tx, ty, tz);

            -- If block retrieval is successful and block matches the target block ID
            if result == 0 and foundBlockID == blockid then
                local positionKey = string.format("%d,%d,%d", tx, ty, tz);

                -- Check if the position is not in the recent positions
                local isRecent = false;
                for _, recentKey in ipairs(PANDA_AI.PATROL_DATA[id].recent_positions) do
                    if recentKey == positionKey then
                        isRecent = true;
                        break;
                    end
                end

                -- If not recent, calculate the distance and store the block
                if not isRecent then
                    local distance = math.sqrt((tx - x)^2 + (tz - z)^2);
                    table.insert(validBlocks, {x = tx, y = ty, z = tz, key = positionKey, distance = distance});
                end
            end
        end
    end

    -- Sort valid blocks by distance
    table.sort(validBlocks, function(a, b) return a.distance < b.distance end);

    -- Select the closest block
    if #validBlocks > 0 then
        local closestBlock = validBlocks[1];

        -- Save the position to recent positions
        table.insert(PANDA_AI.PATROL_DATA[id].recent_positions, closestBlock.key);

        -- Ensure only the last 3 positions are kept
        if #PANDA_AI.PATROL_DATA[id].recent_positions > max_recent_positions then
            table.remove(PANDA_AI.PATROL_DATA[id].recent_positions, 1);
        end

        return closestBlock.x, closestBlock.y, closestBlock.z; -- Return the closest patrol position
    end

    -- If no new patrol block is found, clean the oldest patrol position
    if #PANDA_AI.PATROL_DATA[id].recent_positions > 0 then
        table.remove(PANDA_AI.PATROL_DATA[id].recent_positions, 1);
    end
    return nil;
end

function PANDA_AI:INCREASE_COUNTER(id)
    if PANDA_AI.Counter[id] == nil then 
        PANDA_AI.Counter[id] = 0;
    end 
    PANDA_AI.Counter[id] = PANDA_AI.Counter[id] + 1;
end

function PANDA_AI:FACE_TO(NPC,playerid)

    local result, px, py, pz = Actor:getPosition(NPC)
    local result, xa, ya, za = Actor:getPosition(playerid)
    local dx, dy, dz = xa - px, ya - py, za - pz
    local length = math.sqrt(dx * dx + dy * dy + dz * dz)
    if length ~= 0 then
    dx, dy, dz = dx / length, dy / length, dz / length
    end
    local yaw = math.atan2(-dx, -dz)
    yaw = yaw * 180 / math.pi
    -- Actor:setFaceYaw(playerid,yaw)
    Actor:setFaceYaw(NPC,yaw);
end

PANDA_AI.ACTION.MOVE_AND_MELEE_ATTACK = {
    function(id)
        local x,y,z = MYTOOL.GET_POS(id);
        local dx,dy,dz = MYTOOL.GET_DIR_ACTOR(id);
        local playerfound = {}; --simpan Player yang ditemukan 
        for range = 3 , 13 , 3 do --jarak deteksi  13 blok 
            local tx,ty,tz = x+(dx*range),y,z+(dz*range);
            local OBJECT_FOUND = MYTOOL.getObj_Area(tx,ty,tz,3,3,3);
            for i,playerid in ipairs(MYTOOL.filterObj("Player",OBJECT_FOUND)) do 
                local px, py, pz = MYTOOL.GET_POS(playerid);
                local blocked = false;
        
                -- Check blocks between AI and player
                local distance = MYTOOL.calculate_distance(px,py,pz,x,y,z)
                local steps = math.floor(distance); -- Number of steps to interpolate between points
                for step = 1, steps do
                    local interpX = x + ((px - x) / steps) * step;
                    local interpY = y + ((py - y) / steps) * step;
                    local interpZ = z + ((pz - z) / steps) * step;
        
                    if Block:isSolidBlock(interpX, interpY, interpZ) == 0 then
                        blocked = true;
                        break;
                    end
                end
        
                -- Add player ID if not blocked
                if not blocked then

                    -- check if player is alive 
                    local r,HP = Player:getAttr(playerid,2)
                    if r == 0 then 
                        if HP > 0 then 
                            table.insert(playerfound, playerid);
                        end 
                    end 
                end
            end 
        end 
        
        if GET_LENGTH(playerfound)>0 then 
            -- Chat:sendSystemMsg("Player is Found");
            local target = playerfound[1];
            if target then 
                local px,py,pz = MYTOOL.GET_POS(target);
                local distance = MYTOOL.calculate_distance(px,py,pz,x,y,z)
                if distance > 3 then 
                    Actor:tryMoveToPos(id,px,py,pz,2);
                else
                    PANDA_AI:INCREASE_COUNTER(id);
                    PANDA_AI:FACE_TO(id,target);
                    if PANDA_AI.Counter[id] > 17 then
                        if MYTOOL.ActorDmg2Player(id,target,10,1) then 
                            -- Chat:sendSystemMsg("Successfully Attack");
                            Actor:tryMoveToPos(id,x,y,z,1);
                        end 
                        Actor:playAct(id,16);
                        PANDA_AI.Counter[id] = 0;
                    end 
                end 

                -- update the Memory Duration 
                PANDA_AI:SET_MEMORY(id,"ATTACKING",200,{target = target,pos={x=px,y=py,z=pz}});
            end 
        else
            -- if not chasing player    
            -- before proceeding check ATTACKING memory 
            if not PANDA_AI:RUN_MEMORY(id,"ATTACKING") then 

                PANDA_AI:INCREASE_COUNTER(id);
                if PANDA_AI.Counter[id] > 40 then 
                    local lx,ly,lz = PANDA_AI:TRY_PATROL(id,685);
                    if lx~=nil and ly~=nil and lz~=nil then 
                        Actor:tryMoveToPos(id,lx,ly,lz,1);
                        PANDA_AI.Counter[id] = 0;
                    end 
                end 
            else
                -- get Memory Data
                local DATA =  PANDA_AI:GET_MEMORY(id,"ATTACKING").DATA
                local target = DATA.target;
                local pos = DATA.pos;
                Actor:tryMoveToPos(id,pos.x,pos.y,pos.z,2);
                PANDA_AI:FACE_TO(id,target);
            end 
        end 
    end
}

PANDA_AI.ACTION.MOVE_AND_MELEE_ATTACK_2 = {
    function(id)
        local x,y,z = MYTOOL.GET_POS(id);
        local dx,dy,dz = MYTOOL.GET_DIR_ACTOR(id);
        local playerfound = {}; --simpan Player yang ditemukan 
        for range = 3 , 13 , 3 do --jarak deteksi  13 blok 
            local tx,ty,tz = x+(dx*range),y,z+(dz*range);
            local OBJECT_FOUND = MYTOOL.getObj_Area(tx,ty,tz,3,3,3);
            for i,playerid in ipairs(MYTOOL.filterObj("Player",OBJECT_FOUND)) do 
                local px, py, pz = MYTOOL.GET_POS(playerid);
                local blocked = false;
        
                -- Check blocks between AI and player
                local distance = MYTOOL.calculate_distance(px,py,pz,x,y,z)
                local steps = math.floor(distance); -- Number of steps to interpolate between points
                for step = 1, steps do
                    local interpX = x + ((px - x) / steps) * step;
                    local interpY = y + ((py - y) / steps) * step;
                    local interpZ = z + ((pz - z) / steps) * step;
        
                    if Block:isSolidBlock(interpX, interpY, interpZ) == 0 then
                        blocked = true;
                        break;
                    end
                end
        
                -- Add player ID if not blocked
                if not blocked then

                    -- check if player is alive 
                    local r,HP = Player:getAttr(playerid,2)
                    if r == 0 then 
                        if HP > 0 then 
                            table.insert(playerfound, playerid);
                        end 
                    end 
                end
            end 
        end 
        
        if GET_LENGTH(playerfound)>0 then 
            -- Chat:sendSystemMsg("Player is Found");
            local target = playerfound[1];
            if target then 
                local px,py,pz = MYTOOL.GET_POS(target);
                local distance = MYTOOL.calculate_distance(px,py,pz,x,y,z)
                if distance > 3 then 
                    Actor:tryMoveToPos(id,px,py,pz,2);
                else
                    PANDA_AI:INCREASE_COUNTER(id);
                    PANDA_AI:FACE_TO(id,target);
                    if PANDA_AI.Counter[id] > 17 then
                        if MYTOOL.ActorDmg2Player(id,target,10,1) then 
                            -- Chat:sendSystemMsg("Successfully Attack");
                            Actor:tryMoveToPos(id,x,y,z,1);
                        end 
                        Actor:playAct(id,16);
                        PANDA_AI.Counter[id] = 0;
                    end 
                end 

                -- update the Memory Duration 
                PANDA_AI:SET_MEMORY(id,"ATTACKING",200,{target = target,pos={x=px,y=py,z=pz}});
            end 
        else
            -- if not chasing player    
            -- before proceeding check ATTACKING memory 
            if not PANDA_AI:RUN_MEMORY(id,"ATTACKING") then 

                PANDA_AI:INCREASE_COUNTER(id);
                if PANDA_AI.Counter[id] > 40 then 
                    local lx,ly,lz = PANDA_AI:TRY_PATROL(id,981);
                    if lx~=nil and ly~=nil and lz~=nil then 
                        Actor:tryMoveToPos(id,lx,ly,lz,1);
                        PANDA_AI.Counter[id] = 0;
                    end 
                end 
            else
                -- get Memory Data
                local DATA =  PANDA_AI:GET_MEMORY(id,"ATTACKING").DATA
                local target = DATA.target;
                local pos = DATA.pos;
                Actor:tryMoveToPos(id,pos.x,pos.y,pos.z,2);
                PANDA_AI:FACE_TO(id,target);
            end 
        end 
    end
}


ScriptSupportEvent:registerEvent("Game.Start",function(e)
    PANDA_AI:NEW(2,58,8,-40,PANDA_AI.ACTION.MOVE_AND_MELEE_ATTACK_2);    
    PANDA_AI:NEW(3,27,8,-11,PANDA_AI.ACTION.MOVE_AND_MELEE_ATTACK);    
end)

