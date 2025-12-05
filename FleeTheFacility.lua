-- ========================================
-- CONFIGURATION
-- ========================================
_G.BeastESPConfig = _G.BeastESPConfig or {
    -- ESP Settings
    Enabled = true,
    MaxDistance = 300,
    RenderRate = 0.016,
    CheckRate = 0.1,
    ScreenCheckRate = 2.0,
    
    -- Visual Settings
    TextSize = 14,
    TextFont = 1,
    TextOffsetY = 16,
    BeastColor = Color3.fromRGB(255, 50, 50),
    HumanColor = Color3.fromRGB(100, 150, 255),
    ScreenOKColor = Color3.fromRGB(50, 150, 255),
    ScreenHackedColor = Color3.fromRGB(50, 255, 100),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    
    -- Toggle Key
    ToggleKey = "X",
    
    -- Screen Detection
    ScreenNormal = {r = 13, g = 105, b = 172},
    ScreenTolerance = 5
}

local CONFIG = _G.BeastESPConfig
local Camera = workspace.CurrentCamera

-- ========================================
-- CACHE CONSTANTS
-- ========================================
local CACHE = {
    BeastText = "Beast",
    HumanText = "Human",
    ScreenOKText = "OK",
    ScreenHackedText = "HACKED",
    BeastPowers = "BeastPowers",
    PowerProgressPercent = "PowerProgressPercent",
    HumanoidRootPart = "HumanoidRootPart",
    Humanoid = "Humanoid",
    ComputerTable = "ComputerTable",
    Screen = "Screen"
}

local ScreensCache = {
    Screens = {},
    LastCheck = 0
}

-- ========================================
-- TEXT POOLING SYSTEM
-- ========================================
local TextPool = {}
local TextPoolSize = 0

local function AcquireText()
    if TextPoolSize > 0 then
        local text = TextPool[TextPoolSize]
        TextPool[TextPoolSize] = nil
        TextPoolSize -= 1
        return text
    end
    
    local text = Drawing.new("Text")
    text.Size = CONFIG.TextSize or 14
    text.Font = CONFIG.TextFont or 1
    text.Center = true
    text.Outline = true
    text.OutlineColor = CONFIG.OutlineColor or Color3.fromRGB(0, 0, 0)
    text.Visible = false
    return text
end

local function ReleaseText(text)
    text.Visible = false
    TextPoolSize += 1
    TextPool[TextPoolSize] = text
end

-- ========================================
-- BEAST DETECTION
-- ========================================
local BeastCache = {}

local function CheckBeastPowers(playerName)
    local playerModel = workspace:FindFirstChild(playerName)
    if not playerModel then return false end
    
    local beastFolder = playerModel:FindFirstChild(CACHE.BeastPowers)
    if not beastFolder then return false end
    
    local powerValue = beastFolder:FindFirstChild(CACHE.PowerProgressPercent)
    return powerValue ~= nil
end

-- ========================================
-- SCREEN DETECTION
-- ========================================
local function ColoresIguales(c1, c2, tol)
    if not c1 or not c2 then return false end
    local dr = math.abs(c1.r - c2.r)
    local dg = math.abs(c1.g - c2.g)
    local db = math.abs(c1.b - c2.b)
    return dr <= tol and dg <= tol and db <= tol
end

local function GetScreenColor(screen)
    local success, description = pcall(function()
        return screen.Description
    end)
    
    if not success or not description or type(description) ~= "table" then
        return nil
    end
    
    local colorVec = description.Color3
    if not colorVec or typeof(colorVec) ~= "vector" then
        return nil
    end
    
    return {
        r = math.floor(colorVec.X),
        g = math.floor(colorVec.Y),
        b = math.floor(colorVec.Z)
    }
end

local function UpdateScreensCache()
    local currentTime = tick()
    local checkRate = CONFIG.ScreenCheckRate or 2.0
    
    if currentTime - ScreensCache.LastCheck < checkRate then
        return
    end
    
    ScreensCache.LastCheck = currentTime
    table.clear(ScreensCache.Screens)
    
    local workspaceChildren = workspace:GetChildren()
    for i = 1, #workspaceChildren do
        local model = workspaceChildren[i]
        
        local computerTable = model:FindFirstChild(CACHE.ComputerTable)
        if computerTable then
            local screen = computerTable:FindFirstChild(CACHE.Screen)
            if screen then
                local color = GetScreenColor(screen)
                if color then
                    local isNormal = ColoresIguales(color, CONFIG.ScreenNormal or {r = 13, g = 105, b = 172}, CONFIG.ScreenTolerance or 5)
                    table.insert(ScreensCache.Screens, {
                        Part = screen,
                        IsHacked = not isNormal
                    })
                end
            end
        end
        
        local modelChildren = model:GetChildren()
        for j = 1, #modelChildren do
            local child = modelChildren[j]
            if child.Name == CACHE.ComputerTable then
                local screen = child:FindFirstChild(CACHE.Screen)
                if screen then
                    local color = GetScreenColor(screen)
                    if color then
                        local isNormal = ColoresIguales(color, CONFIG.ScreenNormal or {r = 13, g = 105, b = 172}, CONFIG.ScreenTolerance or 5)
                        table.insert(ScreensCache.Screens, {
                            Part = screen,
                            IsHacked = not isNormal
                        })
                    end
                end
            end
        end
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================
local function DistanceSquared(pos1, pos2)
    local dx = pos1.X - pos2.X
    local dy = pos1.Y - pos2.Y
    local dz = pos1.Z - pos2.Z
    return dx * dx + dy * dy + dz * dz
end

local function GetPlayerRootPosition(character)
    if not character then return nil end
    
    local hrp = character:FindFirstChild(CACHE.HumanoidRootPart)
    if hrp then return hrp.Position end
    
    local humanoid = character:FindFirstChild(CACHE.Humanoid)
    if humanoid and humanoid.RootPart then
        return humanoid.RootPart.Position
    end
    
    if character.PrimaryPart then
        return character.PrimaryPart.Position
    end
    
    return nil
end

local function GetPlayersInWorkspace()
    local players = {}
    local workspaceChildren = workspace:GetChildren()
    
    for i = 1, #workspaceChildren do
        local obj = workspaceChildren[i]
        if typeof(obj) == "Instance" and obj.ClassName == "Model" then
            local hrp = obj:FindFirstChild(CACHE.HumanoidRootPart)
            local humanoid = obj:FindFirstChild(CACHE.Humanoid)
            if hrp and humanoid then
                table.insert(players, {
                    Name = obj.Name,
                    Character = obj,
                    Humanoid = humanoid
                })
            end
        end
    end
    
    return players
end

-- ========================================
-- LABEL MANAGEMENT
-- ========================================
local PlayerLabels = {}
local ScreenLabels = {}

local function GetOrCreatePlayerLabel(playerName)
    if not PlayerLabels[playerName] then
        PlayerLabels[playerName] = AcquireText()
    end
    return PlayerLabels[playerName]
end

local function DestroyPlayerLabel(playerName)
    if PlayerLabels[playerName] then
        ReleaseText(PlayerLabels[playerName])
        PlayerLabels[playerName] = nil
    end
end

local function GetOrCreateScreenLabel(screenIndex)
    if not ScreenLabels[screenIndex] then
        ScreenLabels[screenIndex] = AcquireText()
    end
    return ScreenLabels[screenIndex]
end

-- ========================================
-- TOGGLE FUNCTIONALITY
-- ========================================
local function ToggleESP()
    CONFIG.Enabled = not CONFIG.Enabled
    
    if CONFIG.Enabled then
        print("[Beast ESP] Enabled")
    else
        print("[Beast ESP] Disabled")
        -- Hide all labels when disabled
        for _, label in pairs(PlayerLabels) do
            label.Visible = false
        end
        for _, label in pairs(ScreenLabels) do
            label.Visible = false
        end
    end
end

-- Key handler for toggle
task.spawn(function()
    while true do
        local pressedKeys = getpressedkeys()
        for _, key in ipairs(pressedKeys) do
            if key == (CONFIG.ToggleKey or "X") then
                ToggleESP()
                task.wait(0.3) -- Debounce
                break
            end
        end
        task.wait(0.1)
    end
end)

-- ========================================
-- BEAST DETECTION LOOP
-- ========================================
task.spawn(function()
    while true do
        if CONFIG.Enabled then
            local players = GetPlayersInWorkspace()
            for i = 1, #players do
                local playerData = players[i]
                BeastCache[playerData.Name] = CheckBeastPowers(playerData.Name)
            end
        end
        task.wait(CONFIG.CheckRate or 0.1)
    end
end)

-- ========================================
-- MAIN RENDER LOOP
-- ========================================
task.spawn(function()
    while true do
        if not CONFIG.Enabled then
            task.wait(CONFIG.RenderRate or 0.016)
            continue
        end
        
        if not Camera then
            task.wait(CONFIG.RenderRate or 0.016)
            continue
        end
        
        local cameraPos = Camera.CFrame.Position
        local maxDistance = CONFIG.MaxDistance or 300
        local maxDistSq = maxDistance * maxDistance
        
        UpdateScreensCache()
        
        local players = GetPlayersInWorkspace()
        local activePlayers = {}
        
        -- Render player labels
        for i = 1, #players do
            local playerData = players[i]
            local playerName = playerData.Name
            local character = playerData.Character
            local humanoid = playerData.Humanoid
            
            activePlayers[playerName] = true
            
            if not humanoid or humanoid.Health <= 0 then
                local label = PlayerLabels[playerName]
                if label then label.Visible = false end
                continue
            end
            
            local playerPos = GetPlayerRootPosition(character)
            if not playerPos then
                local label = PlayerLabels[playerName]
                if label then label.Visible = false end
                continue
            end
            
            local distSq = DistanceSquared(playerPos, cameraPos)
            if distSq > maxDistSq then
                local label = PlayerLabels[playerName]
                if label then label.Visible = false end
                continue
            end
            
            local screenPos, onScreen = Camera:WorldToScreenPoint(playerPos)
            if not onScreen then
                local label = PlayerLabels[playerName]
                if label then label.Visible = false end
                continue
            end
            
            local label = GetOrCreatePlayerLabel(playerName)
            local isBeast = BeastCache[playerName] or false
            
            if isBeast then
                label.Text = CACHE.BeastText
                label.Color = CONFIG.BeastColor or Color3.fromRGB(255, 50, 50)
            else
                label.Text = CACHE.HumanText
                label.Color = CONFIG.HumanColor or Color3.fromRGB(100, 150, 255)
            end
            
            label.Position = Vector2.new(screenPos.X, screenPos.Y + (CONFIG.TextOffsetY or 16))
            label.Visible = true
        end
        
        -- Clean up disconnected players
        for playerName in pairs(PlayerLabels) do
            if not activePlayers[playerName] then
                DestroyPlayerLabel(playerName)
                BeastCache[playerName] = nil
            end
        end
        
        -- Render screen labels
        for i = 1, #ScreensCache.Screens do
            local screenData = ScreensCache.Screens[i]
            if screenData.Part then
                local screenPos, onScreen = Camera:WorldToScreenPoint(screenData.Part.Position)
                if onScreen then
                    local label = GetOrCreateScreenLabel(i)
                    
                    if screenData.IsHacked then
                        label.Text = CACHE.ScreenHackedText
                        label.Color = CONFIG.ScreenHackedColor or Color3.fromRGB(50, 255, 100)
                    else
                        label.Text = CACHE.ScreenOKText
                        label.Color = CONFIG.ScreenOKColor or Color3.fromRGB(50, 150, 255)
                    end
                    
                    label.Position = Vector2.new(screenPos.X, screenPos.Y + (CONFIG.TextOffsetY or 16))
                    label.Visible = true
                else
                    if ScreenLabels[i] then
                        ScreenLabels[i].Visible = false
                    end
                end
            end
        end
        
        -- Hide extra screen labels
        for i = #ScreensCache.Screens + 1, #ScreenLabels do
            if ScreenLabels[i] then
                ScreenLabels[i].Visible = false
            end
        end
        
        task.wait(CONFIG.RenderRate or 0.016)
    end
end)

-- ========================================
-- CLEANUP FUNCTION
-- ========================================
local function Cleanup()
    for playerName, label in pairs(PlayerLabels) do
        ReleaseText(label)
    end
    PlayerLabels = {}
    BeastCache = {}
    
    for i, label in pairs(ScreenLabels) do
        ReleaseText(label)
    end
    ScreenLabels = {}
    
    table.clear(ScreensCache.Screens)
    
    for i = 1, #TextPool do
        if TextPool[i] then
            pcall(function()
                TextPool[i]:Remove()
            end)
        end
    end
    TextPool = {}
end

_G.BeastESPCleanup = Cleanup

print("[Beast ESP] Loaded successfully")
print("[Beast ESP] Toggle key: " .. (CONFIG.ToggleKey or "X"))
print("[Beast ESP] Status: " .. (CONFIG.Enabled and "Enabled" or "Disabled"))

