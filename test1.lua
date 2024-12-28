local UI = "7452602660065843442";

local function updateForAllPlayer(players,arg)
    for i,playerid in ipairs(players) do 
        local r,err = pcall( function()
            if arg then 
                if not arg.inx then return end
                if arg.status == "hide" then 
                    Customui:hideElement(playerid,UI,UI.."_"..arg.inx);
                elseif arg.status == "show" then 
                    local r,_,_,z = Player:getPosition(playerid)
                    if r == 0 then 
                        Customui:showElement(playerid,UI,UI.."_"..arg.inx);
                        Customui:setPosition(playerid,UI,UI.."_"..arg.inx,(z/2025*600)-20,10)
                        Customui:setSize(playerid,UI,UI.."_"..arg.inx,45,45)
                        local result,iconid = Customui:getRoleIcon(playerid)
                        if result == 0 then 
                            Customui:setTexture(playerid,UI,UI.."_"..arg.inx,iconid)
                        end 
                    else 
                        Customui:hideElement(playerid,UI,UI.."_"..arg.inx);    
                    end 
                    
                end 
            end 
        end)
        if not r then 
            print("Error Updating : "..err);
        end 
    end 
end 

local timerDoll = 0;
local typeDuration = {2,4,5,8};
local counter = 0;
local UiElement = {Container = 23 , RedLamp = 24 , GreenLamp = 25, TextLamp = 26};
local state = {
    red = function(players)
        for i,playerid in ipairs(players) do
            Customui:setColor(playerid,UI,UI.."_"..UiElement.RedLamp,0xff0000);
            Customui:setColor(playerid,UI,UI.."_"..UiElement.GreenLamp,0x135630);
        end 
    end,
    green = function(players)
        for i,playerid in ipairs(players) do
            Customui:setColor(playerid,UI,UI.."_"..UiElement.RedLamp,0x8c1717);
            Customui:setColor(playerid,UI,UI.."_"..UiElement.GreenLamp,0x04ff00);
        end 
    end
}

local lastPosition = {};

local function updateDollGame(players)
    local DollActive = false;
    local maxDoll_Life = 60;
    if timerDoll < maxDoll_Life then 
        if timerDoll > 20 and timerDoll < maxDoll_Life then 
            DollActive = true; 
        end 
    else 
        timerDoll =  0;    
        counter = 0;
        state.green(players);
    end 
    
    timerDoll = timerDoll + 1;    
    
    if DollActive then 
        local redLightDuration = 3.2;
        for i,playerid in ipairs(players) do
            Customui:showElement(playerid,UI,UI.."_"..UiElement.Container);
            Customui:hideElement(playerid,UI,UI.."_"..UiElement.TextLamp);
        end
        if counter <= 0 then 
            local pick = math.random(1,4);
            if VarLib2:setGlobalVarByName(3, "Doll" ,pick) == 0 then 
                counter = typeDuration[pick] + redLightDuration;
            end 
            for i,playerid in ipairs(players) do
                Actor:addBuff(playerid,50000001 ,1,20)
            end 
        else
            if counter <= redLightDuration then 
                -- this is red light and every player that move will DIE!
                state.red(players);
                for i,playerid in ipairs(players) do
                    local r,x,y,z = Actor:getPosition(playerid)
                    if r == 0 then 
                        if  lastPosition[playerid] == nil then
                            lastPosition[playerid] = {x=x,y=y,z=z};
                        else 
                            if lastPosition[playerid].x ~= x or lastPosition[playerid].y ~= y or lastPosition[playerid].z ~= z then 
                                -- player moved 
                                if  lastPosition[playerid] ~= nil then
                                    lastPosition[playerid] = nil;
                                end 
                                threadpool:wait(0.1);
                                -- Actor:killSelf(playerid);
                                Actor:playerHurt(playerid, playerid, 70, 1);
                                Actor:playSoundEffectById(playerid, 10631 , 100, 1, false)
                            end 
                        end 
                    end 
                end 
            else
                state.green(players);
                for i,playerid in ipairs(players) do
                    if  lastPosition[playerid] ~= nil then
                        lastPosition[playerid] = nil;
                    end 
                end 
            end 
            counter = counter - 1;
        end 
    else 
        for i,playerid in ipairs(players) do
            Customui:hideElement(playerid,UI,UI.."_"..UiElement.Container);
            Customui:showElement(playerid,UI,UI.."_"..UiElement.TextLamp);
            Customui:setText(playerid,UI,UI.."_"..UiElement.TextLamp,"The Light is Malfunction for "..math.floor(21-timerDoll).." seconds");
        end 
    end 

end 

ScriptSupportEvent:registerEvent("Game.RunTime",function(e) 
    local r,num,players = World:getAllPlayers(-1);
    if r == 0 then 
        for i = 1 , 10 do 
            if players[i] then 
                updateForAllPlayer(players,{status="show",inx = i});
            else
                updateForAllPlayer(players,{status="hide",inx = i});
            end 
        end 
    else 
        for i = 1 , 10 do 
            updateForAllPlayer(players,{status="hide",inx = i});
        end 
    end 
    
    if e.second then 
        updateDollGame(players)
    end 
end)