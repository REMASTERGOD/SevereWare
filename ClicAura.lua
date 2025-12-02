--!optimize 2
--!strict

local CPS = 20
local ActivationDistance = 5
local TeamCheck = false
local ToggleKey = "V"

local Enabled, MasterToggle, LastKeyState = false, false, false
local Players, LocalPlayer = game:GetService("Players"), game:GetService("Players").LocalPlayer

local GamePaths = {
    [34068311] = {
        GetHRP = function(player)
            local playerModel = game.Workspace:FindFirstChild(player.Name)
            if playerModel and playerModel.ClassName == "Model" then
                return playerModel:FindFirstChild("HumanoidRootPart")
            end
            return nil
        end,
        GetHumanoid = function(player)
            local playerModel = game.Workspace:FindFirstChild(player.Name)
            if playerModel and playerModel.ClassName == "Model" then
                return playerModel:FindFirstChild("Humanoid")
            end
            return nil
        end
    },
}

local CurrentGameID = game.GameId
local CustomPathEnabled = GamePaths[CurrentGameID] ~= nil

local function g()
    if CustomPathEnabled then
        return GamePaths[CurrentGameID].GetHRP(LocalPlayer)
    else
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
end

local function GetPlayerHRP(player)
    if CustomPathEnabled then
        return GamePaths[CurrentGameID].GetHRP(player)
    else
        local c = player.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
end

local function GetPlayerHumanoid(player)
    if CustomPathEnabled then
        return GamePaths[CurrentGameID].GetHumanoid(player)
    else
        local c = player.Character
        return c and c:FindFirstChild("Humanoid")
    end
end

local function m(a, b)
    local x, y, z = a.X - b.X, a.Y - b.Y, a.Z - b.Z
    return math.sqrt(x * x + y * y + z * z)
end

local function f()
    local r = g()
    if not r then return math.huge end
    
    local p, d = r.Position, math.huge
    
    for _, v in Players:GetChildren() do
        if v ~= LocalPlayer and (not TeamCheck or v.Team ~= LocalPlayer.Team) then
            local t = GetPlayerHRP(v)
            local h = GetPlayerHumanoid(v)
            
            if h and h.Health > 0 and t then
                local dist = m(p, t.Position)
                if dist < d then d = dist end
            end
        end
    end
    
    return d
end

task.spawn(function()
    while true do
        local k = getpressedkeys()
        local p = false
        
        for _, v in ipairs(k) do
            if tostring(v) == ToggleKey then
                p = true
                break
            end
        end
        
        if p and not LastKeyState then
            MasterToggle = not MasterToggle
            print("" .. (MasterToggle and "True" or "False"))
        end
        
        LastKeyState = p
        task.wait(0.05)
    end
end)

task.spawn(function()
    while true do
        Enabled = MasterToggle and f() <= ActivationDistance
        task.wait(0.1)
    end
end)

task.spawn(function()
    local w = 1 / CPS
    while true do
        if Enabled then
            mouse1press()
            task.wait(w)
            mouse1release()
            task.wait(w)
        else
            task.wait(0.05)
        end
    end
end)
