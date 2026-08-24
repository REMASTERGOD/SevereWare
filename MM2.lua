local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

local CFG = {
    textSize      = 14,
    offsetY       = -44,
    maxDist       = 300,
    colorGun      = Color3.fromRGB(30,  144, 255),
    colorKnife    = Color3.fromRGB(255,  50,  50),
    colorInnocent = Color3.fromRGB(50,  200,  50),
    colorGunDrop  = Color3.fromRGB(255, 215,   0),
    outlineClr    = Vector3.new(0, 0, 0),
    outline       = true,
    zIndex        = 10,
}

local localPlayer = Players.LocalPlayer
local labels      = {}
local playerCache = {}

local cachedGunDrop = nil
local gunDropTimer  = 0

local gunDropLabel        = Drawing.new("Text")
gunDropLabel.Text         = "Gun Drop"
gunDropLabel.Size         = CFG.textSize
gunDropLabel.Center       = true
gunDropLabel.Outline      = CFG.outline
gunDropLabel.OutlineColor = CFG.outlineClr
gunDropLabel.Color        = CFG.colorGunDrop
gunDropLabel.ZIndex       = CFG.zIndex
gunDropLabel.Visible      = false


local function dist3(a, b)
    local dx = a.X - b.X
    local dy = a.Y - b.Y
    local dz = a.Z - b.Z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function getOrCreateLabel(player)
    if not labels[player] then
        local t        = Drawing.new("Text")
        t.Size         = CFG.textSize
        t.Center       = true
        t.Outline      = CFG.outline
        t.OutlineColor = CFG.outlineClr
        t.ZIndex       = CFG.zIndex
        t.Visible      = false
        labels[player] = t
    end
    return labels[player]
end

local function hideLabel(player)
    if labels[player] then labels[player].Visible = false end
end

local function getHeadPos(cache, model)
    if not cache.head or not cache.head.Parent then
        cache.head = model:FindFirstChild("Head")
    end
    if cache.head then
        return cache.head.Position + Vector3.new(0, 0.6, 0)
    end
    if not cache.root or not cache.root.Parent then
        cache.root = model:FindFirstChild("HumanoidRootPart")
    end
    if cache.root then
        return cache.root.Position + Vector3.new(0, 3.5, 0)
    end
    return nil
end

local function getLocalPos()
    local lm = Workspace:FindFirstChild(localPlayer.Name)
    if not lm then return nil end
    local root = lm:FindFirstChild("HumanoidRootPart")
    return root and root.Position or nil
end

local function detectRole(model)
    local hasWeapon = model:GetAttribute("HasWeapon")
    if not hasWeapon then
        return "innocent"
    end
    if model:FindFirstChildOfClass("Folder") then
        return "knife"
    end
    return "gun"
end

RunService.Render:Connect(function()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local now      = os.clock()
    local localPos = getLocalPos()

    -- Refresca GunDrop cada 2 segundos
    if now - gunDropTimer >= 2 then
        gunDropTimer  = now
        cachedGunDrop = Workspace:FindFirstDescendant("GunDrop")
        if not cachedGunDrop then
            gunDropLabel.Visible = false
        end
    end

    if cachedGunDrop and cachedGunDrop.Parent then
        local dropPos = cachedGunDrop.Position
        local tooFar  = localPos and dist3(dropPos, localPos) > CFG.maxDist
        if tooFar then
            gunDropLabel.Visible = false
        else
            local sv, vis = camera:WorldToScreenPoint(dropPos)
            gunDropLabel.Visible = vis
            if vis then
                gunDropLabel.Position = Vector2.new(sv.X, sv.Y + CFG.offsetY)
            end
        end
    else
        gunDropLabel.Visible = false
    end

    local activePlayers = {}

    for _, player in ipairs(Players:GetChildren()) do
        if player == localPlayer then continue end
        activePlayers[player] = true

        local cache = playerCache[player]
        local model = cache and cache.model

        if not model or not model.Parent then
            model = Workspace:FindFirstChild(player.Name)
            if not model then hideLabel(player); continue end
            playerCache[player] = { model = model, head = nil, root = nil }
            cache = playerCache[player]
        end

        local worldPos = getHeadPos(cache, model)
        if not worldPos then hideLabel(player); continue end

        if localPos and dist3(worldPos, localPos) > CFG.maxDist then
            hideLabel(player)
            continue
        end

        local sv, vis = camera:WorldToScreenPoint(worldPos)
        if not vis then hideLabel(player); continue end

        local role  = detectRole(model)
        local label = getOrCreateLabel(player)
        label.Visible  = true
        label.Position = Vector2.new(sv.X, sv.Y + CFG.offsetY)

        if role == "gun" then
            label.Text  = player.Name .. " [Sheriff]"
            label.Color = CFG.colorGun
        elseif role == "knife" then
            label.Text  = player.Name .. " [Murder]"
            label.Color = CFG.colorKnife
        else
            label.Text  = player.Name .. " [Innocent]"
            label.Color = CFG.colorInnocent
        end
    end

    for player, label in pairs(labels) do
        if not activePlayers[player] then
            label:Remove()
            labels[player]      = nil
            playerCache[player] = nil
        end
    end
end)