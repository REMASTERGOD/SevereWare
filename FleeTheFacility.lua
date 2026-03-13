-- ========================================
-- CONFIGURATION
-- ========================================
_G.BeastESPConfig = _G.BeastESPConfig or {
    Enabled         = true,
    MaxDistance     = 300,
    CheckRate       = 0.1,
    ScreenCheckRate = 2.0,
    TextSize        = 14,
    TextOffsetY     = 16,
    BeastColor        = Color3.fromRGB(255, 50,  50),
    HumanColor        = Color3.fromRGB(100, 150, 255),
    ScreenOKColor     = Color3.fromRGB(50,  150, 255),
    ScreenHackedColor = Color3.fromRGB(50,  255, 100),
    ToggleKey       = "X",
    ScreenNormal    = {r = 13, g = 105, b = 172},
    ScreenTolerance = 5,
}

local CONFIG     = _G.BeastESPConfig
local Camera     = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local V2  = Vector2.new
local W2S = function(pos) return Camera:WorldToScreenPoint(pos) end

-- ========================================
-- CACHE CONSTANTS
-- ========================================
local CACHE = {
    BeastText            = "Beast",
    HumanText            = "Human",
    ScreenOKText         = "OK",
    ScreenHackedText     = "HACKED",
    BeastPowers          = "BeastPowers",
    PowerProgressPercent = "PowerProgressPercent",
    HumanoidRootPart     = "HumanoidRootPart",
    ComputerTable        = "ComputerTable",
    Screen               = "Screen",
}

-- ========================================
-- BEAST DETECTION
-- ========================================
local function CheckBeastPowers(name)
    local model = workspace:FindFirstChild(name)
    if not model then return false end
    local folder = model:FindFirstChild(CACHE.BeastPowers)
    if not folder then return false end
    return folder:FindFirstChild(CACHE.PowerProgressPercent) ~= nil
end

-- ========================================
-- PLAYER CACHE + BEAST DETECTION LOOP
-- ========================================
local PlayerCache = {}
local BeastCache  = {}

local beastThread = task.spawn(function()
    while true do
        if CONFIG.Enabled then
            local fresh = {}

            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.ClassName == "Model" then
                    local hrp      = obj:FindFirstChild(CACHE.HumanoidRootPart)
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    if hrp and humanoid then
                        local name       = obj.Name
                        fresh[name]      = { Humanoid = humanoid, HRP = hrp }
                        BeastCache[name] = CheckBeastPowers(name)
                    end
                end
            end

            for name in pairs(PlayerCache) do
                if not fresh[name] then
                    BeastCache[name] = nil
                end
            end

            PlayerCache = fresh
        end
        task.wait(CONFIG.CheckRate or 0.1)
    end
end)

-- ========================================
-- SCREEN DETECTION
-- ========================================
local ScreensCache = { Screens = {}, LastCheck = 0 }

local function ColoresIguales(c1, c2, tol)
    if not c1 or not c2 then return false end
    return math.abs(c1.r - c2.r) <= tol
       and math.abs(c1.g - c2.g) <= tol
       and math.abs(c1.b - c2.b) <= tol
end

local function GetScreenColor(screen)
    local ok, desc = pcall(function() return screen.Description end)
    if not ok or not desc or type(desc) ~= "table" then return nil end
    local cv = desc.Color3
    if not cv or typeof(cv) ~= "vector" then return nil end
    return { r = math.floor(cv.X), g = math.floor(cv.Y), b = math.floor(cv.Z) }
end

local function UpdateScreensCache()
    local now = tick()
    if now - ScreensCache.LastCheck < (CONFIG.ScreenCheckRate or 2.0) then return end
    ScreensCache.LastCheck = now
    table.clear(ScreensCache.Screens)

    local normalColor = CONFIG.ScreenNormal    or {r = 13, g = 105, b = 172}
    local tolerance   = CONFIG.ScreenTolerance or 5

    local function TryComputerTable(ct)
        local screen = ct:FindFirstChild(CACHE.Screen)
        if not screen then return end
        local color = GetScreenColor(screen)
        if color then
            table.insert(ScreensCache.Screens, {
                Part     = screen,
                IsHacked = not ColoresIguales(color, normalColor, tolerance),
            })
        end
    end

    for _, model in ipairs(workspace:GetChildren()) do
        local ct = model:FindFirstChild(CACHE.ComputerTable)
        if ct then TryComputerTable(ct) end
        for _, child in ipairs(model:GetChildren()) do
            if child.Name == CACHE.ComputerTable then
                TryComputerTable(child)
            end
        end
    end
end

-- ========================================
-- UTILITY
-- ========================================
local function DistanceSquared(p1, p2)
    local dx, dy, dz = p1.X - p2.X, p1.Y - p2.Y, p1.Z - p2.Z
    return dx*dx + dy*dy + dz*dz
end

-- ========================================
-- TOGGLE
-- ========================================
local function ToggleESP()
    CONFIG.Enabled = not CONFIG.Enabled
    print("[Beast ESP] " .. (CONFIG.Enabled and "Activado" or "Desactivado"))
end

local toggleThread = task.spawn(function()
    while true do
        for _, key in ipairs(getpressedkeys()) do
            if key == (CONFIG.ToggleKey or "X") then
                ToggleESP()
                task.wait(0.3)
                break
            end
        end
        task.wait(0.1)
    end
end)

-- ========================================
-- MAIN RENDER LOOP
-- ========================================
local renderConnection = RunService.Render:Connect(function()
    if not CONFIG.Enabled then return end

    local cameraPos = Camera.Position
    local maxDistSq = (CONFIG.MaxDistance or 300) ^ 2
    local tSize     = CONFIG.TextSize    or 14
    local offsetY   = CONFIG.TextOffsetY or 16

    UpdateScreensCache()

    -- Jugadores
    for name, data in pairs(PlayerCache) do
        if not data.Humanoid or data.Humanoid.Health <= 0 then continue end

        local hrpPos = data.HRP.Position
        if DistanceSquared(hrpPos, cameraPos) > maxDistSq then continue end

        local screenPos, onScreen = W2S(hrpPos)
        if not onScreen then continue end

        local isBeast = BeastCache[name] or false

        DrawingImmediate.OutlinedText(
            V2(screenPos.X, screenPos.Y + offsetY),
            tSize,
            isBeast and CONFIG.BeastColor or CONFIG.HumanColor,
            1,
            isBeast and CACHE.BeastText or CACHE.HumanText,
            true
        )
    end

    -- Pantallas / Computadoras
    for _, sd in ipairs(ScreensCache.Screens) do
        if not sd.Part then continue end
        local screenPos, onScreen = W2S(sd.Part.Position)
        if not onScreen then continue end

        DrawingImmediate.OutlinedText(
            V2(screenPos.X, screenPos.Y + offsetY),
            tSize,
            sd.IsHacked and CONFIG.ScreenHackedColor or CONFIG.ScreenOKColor,
            1,
            sd.IsHacked and CACHE.ScreenHackedText or CACHE.ScreenOKText,
            true
        )
    end
end)

-- ========================================
-- CLEANUP
-- ========================================
local function Cleanup()
    renderConnection:Disconnect()
    task.cancel(toggleThread)
    task.cancel(beastThread)
    PlayerCache = {}
    BeastCache  = {}
    table.clear(ScreensCache.Screens)
    print("[Beast ESP] Descargado")
end

_G.BeastESPCleanup = Cleanup

print("[Beast ESP] Cargado | Toggle: " .. (CONFIG.ToggleKey or "X"))
