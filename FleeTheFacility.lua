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
	ScreenNormal = {
		r = 13,
		g = 105,
		b = 172
	},
	ScreenTolerance = 5
}

local L_1_ = _G.BeastESPConfig
local L_2_ = workspace.CurrentCamera

-- ========================================
-- CACHE CONSTANTS
-- ========================================

local L_3_ = {
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

local L_4_ = {
	Screens = {},
	LastCheck = 0
}

-- ========================================
-- TEXT POOLING SYSTEM
-- ========================================

local L_5_ = {}
local L_6_ = 0

local function L_7_func()
	if L_6_ > 0 then
		local L_25_ = L_5_[L_6_]
		L_5_[L_6_] = nil
		TextPoolSize -= 1
		return L_25_
	end
	local L_24_ = Drawing.new("Text")
	L_24_.Size = L_1_.TextSize
	L_24_.Font = L_1_.TextFont
	L_24_.Center = true
	L_24_.Outline = true
	L_24_.OutlineColor = L_1_.OutlineColor
	L_24_.Visible = false
	return L_24_
end

local function L_8_func(L_26_arg0)
	L_26_arg0.Visible = false
	TextPoolSize += 1
	L_5_[L_6_] = L_26_arg0
end

-- ========================================
-- BEAST DETECTION
-- ========================================

local L_9_ = {}

local function L_10_func(L_27_arg0)
	local L_28_ = workspace:FindFirstChild(L_27_arg0)
	if not L_28_ then
		return false
	end
	local L_29_ = L_28_:FindFirstChild(L_3_.BeastPowers)
	if not L_29_ then
		return false
	end
	local L_30_ = L_29_:FindFirstChild(L_3_.PowerProgressPercent)
	return L_30_ ~= nil
end

-- ========================================
-- SCREEN DETECTION
-- ========================================

local function L_11_func(L_31_arg0, L_32_arg1, L_33_arg2)
	if not L_31_arg0 or not L_32_arg1 then
		return false
	end
	local L_34_ = math.abs(L_31_arg0.r - L_32_arg1.r)
	local L_35_ = math.abs(L_31_arg0.g - L_32_arg1.g)
	local L_36_ = math.abs(L_31_arg0.b - L_32_arg1.b)
	return L_34_ <= L_33_arg2 and L_35_ <= L_33_arg2 and L_36_ <= L_33_arg2
end

local function L_12_func(L_37_arg0)
	local L_38_, L_39_ = pcall(function()
		return L_37_arg0.Description
	end)
	if not L_38_ or not L_39_ or type(L_39_) ~= "table" then
		return nil
	end
	local L_40_ = L_39_.Color3
	if not L_40_ or typeof(L_40_) ~= "vector" then
		return nil
	end
	return {
		r = math.floor(L_40_.X),
		g = math.floor(L_40_.Y),
		b = math.floor(L_40_.Z)
	}
end

local function L_13_func()
	local L_41_ = tick()
	if L_41_ - L_4_.LastCheck < L_1_.ScreenCheckRate then
		return
	end
	L_4_.LastCheck = L_41_
	table.clear(L_4_.Screens)
	local L_42_ = workspace:GetChildren()
	for L_43_forvar0 = 1, #L_42_ do
		local L_44_ = L_42_[L_43_forvar0]
		local L_45_ = L_44_:FindFirstChild(L_3_.ComputerTable)
		if L_45_ then
			local L_47_ = L_45_:FindFirstChild(L_3_.Screen)
			if L_47_ then
				local L_48_ = L_12_func(L_47_)
				if L_48_ then
					local L_49_ = L_11_func(L_48_, L_1_.ScreenNormal, L_1_.ScreenTolerance)
					table.insert(L_4_.Screens, {
						Part = L_47_,
						IsHacked = not L_49_
					})
				end
			end
		end
		local L_46_ = L_44_:GetChildren()
		for L_50_forvar0 = 1, #L_46_ do
			local L_51_ = L_46_[L_50_forvar0]
			if L_51_.Name == L_3_.ComputerTable then
				local L_52_ = L_51_:FindFirstChild(L_3_.Screen)
				if L_52_ then
					local L_53_ = L_12_func(L_52_)
					if L_53_ then
						local L_54_ = L_11_func(L_53_, L_1_.ScreenNormal, L_1_.ScreenTolerance)
						table.insert(L_4_.Screens, {
							Part = L_52_,
							IsHacked = not L_54_
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

local function L_14_func(L_55_arg0, L_56_arg1)
	local L_57_ = L_55_arg0.X - L_56_arg1.X
	local L_58_ = L_55_arg0.Y - L_56_arg1.Y
	local L_59_ = L_55_arg0.Z - L_56_arg1.Z
	return L_57_ * L_57_ + L_58_ * L_58_ + L_59_ * L_59_
end

local function L_15_func(L_60_arg0)
	if not L_60_arg0 then
		return nil
	end
	local L_61_ = L_60_arg0:FindFirstChild(L_3_.HumanoidRootPart)
	if L_61_ then
		return L_61_.Position
	end
	local L_62_ = L_60_arg0:FindFirstChild(L_3_.Humanoid)
	if L_62_ and L_62_.RootPart then
		return L_62_.RootPart.Position
	end
	if L_60_arg0.PrimaryPart then
		return L_60_arg0.PrimaryPart.Position
	end
	return nil
end

local function L_16_func()
	local L_63_ = {}
	local L_64_ = workspace:GetChildren()
	for L_65_forvar0 = 1, #L_64_ do
		local L_66_ = L_64_[L_65_forvar0]
		if typeof(L_66_) == "Instance" and L_66_.ClassName == "Model" then
			local L_67_ = L_66_:FindFirstChild(L_3_.HumanoidRootPart)
			local L_68_ = L_66_:FindFirstChild(L_3_.Humanoid)
			if L_67_ and L_68_ then
				table.insert(L_63_, {
					Name = L_66_.Name,
					Character = L_66_,
					Humanoid = L_68_
				})
			end
		end
	end
	return L_63_
end

-- ========================================
-- LABEL MANAGEMENT
-- ========================================

local L_17_ = {}
local L_18_ = {}

local function L_19_func(L_69_arg0)
	if not L_17_[L_69_arg0] then
		L_17_[L_69_arg0] = L_7_func()
	end
	return L_17_[L_69_arg0]
end

local function L_20_func(L_70_arg0)
	if L_17_[L_70_arg0] then
		L_8_func(L_17_[L_70_arg0])
		L_17_[L_70_arg0] = nil
	end
end

local function L_21_func(L_71_arg0)
	if not L_18_[L_71_arg0] then
		L_18_[L_71_arg0] = L_7_func()
	end
	return L_18_[L_71_arg0]
end

-- ========================================
-- TOGGLE FUNCTIONALITY
-- ========================================

local function L_22_func()
	L_1_.Enabled = not L_1_.Enabled
	if L_1_.Enabled then
		print("[Beast ESP] Enabled")
	else
		print("[Beast ESP] Disabled")
		for L_72_forvar0, L_73_forvar1 in pairs(L_17_) do
			L_73_forvar1.Visible = false
		end
		for L_74_forvar0, L_75_forvar1 in pairs(L_18_) do
			L_75_forvar1.Visible = false
		end
	end
end

task.spawn(function()
	while true do
		local L_76_ = getpressedkeys()
		for L_77_forvar0, L_78_forvar1 in ipairs(L_76_) do
			if L_78_forvar1 == L_1_.ToggleKey then
				L_22_func()
				task.wait(0.3)
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
		if L_1_.Enabled then
			local L_79_ = L_16_func()
			for L_80_forvar0 = 1, #L_79_ do
				local L_81_ = L_79_[L_80_forvar0]
				L_9_[L_81_.Name] = L_10_func(L_81_.Name)
			end
		end
		task.wait(L_1_.CheckRate)
	end
end)

-- ========================================
-- MAIN RENDER LOOP
-- ========================================

task.spawn(function()
	while true do
		if not L_1_.Enabled then
			task.wait(L_1_.RenderRate)
			continue
		end
		if not L_2_ then
			task.wait(L_1_.RenderRate)
			continue
		end
		local L_82_ = L_2_.CFrame.Position
		local L_83_ = L_1_.MaxDistance * L_1_.MaxDistance
		L_13_func()
		local L_84_ = L_16_func()
		local L_85_ = {}
		for L_86_forvar0 = 1, #L_84_ do
			local L_87_ = L_84_[L_86_forvar0]
			local L_88_ = L_87_.Name
			local L_89_ = L_87_.Character
			local L_90_ = L_87_.Humanoid
			L_85_[L_88_] = true
			if not L_90_ or L_90_.Health <= 0 then
				local L_97_ = L_17_[L_88_]
				if L_97_ then
					L_97_.Visible = false
				end
				continue
			end
			local L_91_ = L_15_func(L_89_)
			if not L_91_ then
				local L_98_ = L_17_[L_88_]
				if L_98_ then
					L_98_.Visible = false
				end
				continue
			end
			local L_92_ = L_14_func(L_91_, L_82_)
			if L_92_ > L_83_ then
				local L_99_ = L_17_[L_88_]
				if L_99_ then
					L_99_.Visible = false
				end
				continue
			end
			local L_93_, L_94_ = L_2_:WorldToScreenPoint(L_91_)
			if not L_94_ then
				local L_100_ = L_17_[L_88_]
				if L_100_ then
					L_100_.Visible = false
				end
				continue
			end
			local L_95_ = L_19_func(L_88_)
			local L_96_ = L_9_[L_88_] or false
			if L_96_ then
				L_95_.Text = L_3_.BeastText
				L_95_.Color = L_1_.BeastColor
			else
				L_95_.Text = L_3_.HumanText
				L_95_.Color = L_1_.HumanColor
			end
			L_95_.Position = Vector2.new(L_93_.X, L_93_.Y + L_1_.TextOffsetY)
			L_95_.Visible = true
		end
		for L_101_forvar0 in pairs(L_17_) do
			if not L_85_[L_101_forvar0] then
				L_20_func(L_101_forvar0)
				L_9_[L_101_forvar0] = nil
			end
		end
		for L_102_forvar0 = 1, #L_4_.Screens do
			local L_103_ = L_4_.Screens[L_102_forvar0]
			if L_103_.Part then
				local L_104_, L_105_ = L_2_:WorldToScreenPoint(L_103_.Part.Position)
				if L_105_ then
					local L_106_ = L_21_func(L_102_forvar0)
					if L_103_.IsHacked then
						L_106_.Text = L_3_.ScreenHackedText
						L_106_.Color = L_1_.ScreenHackedColor
					else
						L_106_.Text = L_3_.ScreenOKText
						L_106_.Color = L_1_.ScreenOKColor
					end
					L_106_.Position = Vector2.new(L_104_.X, L_104_.Y + L_1_.TextOffsetY)
					L_106_.Visible = true
				else
					if L_18_[L_102_forvar0] then
						L_18_[L_102_forvar0].Visible = false
					end
				end
			end
		end
		for L_107_forvar0 = #L_4_.Screens + 1, #L_18_ do
			if L_18_[L_107_forvar0] then
				L_18_[L_107_forvar0].Visible = false
			end
		end
		task.wait(L_1_.RenderRate)
	end
end)

-- ========================================
-- CLEANUP FUNCTION
-- ========================================
local function L_23_func()
	for L_108_forvar0, L_109_forvar1 in pairs(L_17_) do
		L_8_func(L_109_forvar1)
	end
	L_17_ = {}
	L_9_ = {}
	for L_110_forvar0, L_111_forvar1 in pairs(L_18_) do
		L_8_func(L_111_forvar1)
	end
	L_18_ = {}
	table.clear(L_4_.Screens)
	for L_112_forvar0 = 1, #L_5_ do
		if L_5_[L_112_forvar0] then
			pcall(function()
				L_5_[L_112_forvar0]:Remove()
			end)
		end
	end
	L_5_ = {}
end

_G.BeastESPCleanup = L_23_func

print("[Beast ESP] Loaded successfully")
print("[Beast ESP] Toggle key: " .. L_1_.ToggleKey)
print("[Beast ESP] Status: " .. (L_1_.Enabled and "Enabled" or "Disabled"))
