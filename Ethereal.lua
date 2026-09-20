local folderName = "Ethereal/Doors"
if not isfolder("Ethereal") then
    makefolder("Ethereal")
end
if not isfolder(folderName) then
    makefolder(folderName)
end

local backgroundPath = folderName .. "/background.png"
local iconPath = folderName .. "/icon.png"
local mascotPath = folderName .. "/mascot.png"

local backgroundUrl = "https://raw.githubusercontent.com/jonixeverua/Ethereal.cc/main/Assets/background.png"
local iconUrl = "https://raw.githubusercontent.com/jonixeverua/Ethereal.cc/main/Assets/icon.png"
local mascotUrl = "https://raw.githubusercontent.com/jonixeverua/Ethereal.cc/main/Assets/Mascots/mascot_1.png"
local ESPLib = "https://raw.githubusercontent.com/jonixeverua/Ethereal.cc/main/Assets/ESPLibrary.lua"

if not isfile(backgroundPath) then
    writefile(backgroundPath, game:HttpGet(backgroundUrl))
end
if not isfile(iconPath) then
    writefile(iconPath, game:HttpGet(iconUrl))
end
if not isfile(mascotPath) then
    writefile(mascotPath, game:HttpGet(mascotUrl))
end

local backgroundAsset = getcustomasset(backgroundPath)
local iconAsset = getcustomasset(iconPath)
local mascotAsset = getcustomasset(mascotPath)

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    VirtualUser = game:GetService("VirtualUser"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    SoundService = game:GetService("SoundService"),
    CoreGui = game:GetService("CoreGui"),
    Debris = game:GetService("Debris"),
}

local Refs = {
    LocalPlayer = Services.Players.LocalPlayer,
    Camera = Services.Workspace.CurrentCamera,
    RemotesFolder = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
        or Services.ReplicatedStorage:FindFirstChild("EntityInfo")
        or Services.ReplicatedStorage:FindFirstChild("Bricks"),
    Character = Services.Players.LocalPlayer.Character or Services.Players.LocalPlayer.CharacterAdded:Wait(),
    CurrentRooms = Services.Workspace:FindFirstChild("CurrentRooms"),
}
Refs.Humanoid = Refs.Character and Refs.Character:FindFirstChild("Humanoid")
Refs.RootPart = Refs.Character:WaitForChild("HumanoidRootPart")
Refs.CrouchRemote = Refs.RemotesFolder and Refs.RemotesFolder:FindFirstChild("Crouch")

local Options = Library.Options
local Toggles = Library.Toggles

local Func = {}

local CONST = {
    TRACK_INTERVAL = 0.05,
    AUTO_INTERACT_INTERVAL = 0.15,
    AUTO_PADLOCK_INTERVAL = 0.5,
    BRUTE_FORCE_INTERVAL = 1,
    NOTIFICATION_INTERVAL = 0.5,
    RENDER_CHECK_INTERVAL = 0.1,
    LABEL_UPDATE_INTERVAL = 0.2,
    NOCLIP_FORCE_INTERVAL = 0.1,
    SPAWN_RADIUS = 30,
    HIDE_SEARCH_RADIUS = 30,
    STOP_VELOCITY = 5,
    MAX_ACTIVATION_DIST = 18,
    PROMPT_HOLD_DEFAULT = 0.08,
    DOOR_REACH_DIST = 75,
    DOOR_FIRE_COOLDOWN = 0.15,
    PROMPT_FIRE_COOLDOWN = 0.15,
    PADLOCK_WAIT = 5,
    BREAKER_WAIT = 0.2,
}

local Loops = {}

function Func.RegisterLoop(name, interval, fn)
    table.insert(Loops, {name = name, interval = interval, last = 0, fn = fn})
end

local unloaded = false

task.spawn(function()
    while not unloaded do
        local now = tick()
        for _, loop in ipairs(Loops) do
            if now - loop.last >= loop.interval then
                loop.last = now
                local ok, err = pcall(loop.fn)
                if not ok then
                    warn("[Loop " .. loop.name .. "] " .. tostring(err))
                end
            end
        end
        task.wait(0.03)
    end
end)

local Cache = {
    paperUI = nil,
    collisionPart = nil,
    floor = "Hotel",
    floorLastUpdate = 0,
}

function Func.ClearCache()
    Cache.paperUI = nil
    Cache.collisionPart = nil
end

Refs.LocalPlayer.CharacterAdded:Connect(Func.ClearCache)

Library.Scheme.AccentColor = Color3.fromRGB(59, 59, 59)
Library.Scheme.BackgroundColor = Color3.fromRGB(38, 38, 38)
Library.Scheme.MainColor = Color3.fromRGB(125, 125, 125)
Library.Scheme.OutlineColor = Color3.fromRGB(66, 66, 66)
Library.Scheme.FontColor = Color3.fromRGB(255, 255, 255)

local Window = Library:CreateWindow({
    Title = "Ethereal.cc",
    Footer = "Ethereal.cc v0.0.1 | [BETA] | Doors",
    Icon = iconAsset,
    IconSize = UDim2.fromOffset(50, 50),
    CornerRadius = 10,
    BackgroundImage = backgroundAsset,
    Size = UDim2.fromOffset(500, 375),
    EnableSidebarResize = false,
    EnableCompacting = true,
    SidebarCompacted = true,
    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true
    }
})

if Library.ScreenGui then
    Library.ScreenGui.Name = "EtherealUI"
end

local UI = {
    Tabs = {},
    Tabboxes = {},
    Tabgroups = {},
    Groups = {},
}

UI.Tabs.Home = Window:AddTab("Home", "door-open", "Home page for Ethereal")
UI.Tabs.Main = Window:AddTab("Main", "house", "Main features")
UI.Tabs.Exploits = Window:AddTab("Exploits", "bug", "Game exploits")
UI.Tabs.Visuals = Window:AddTab("Visuals", "eye", "Visual Tweaks & ESP")
UI.Tabs.Floor = Window:AddTab("Floor", "sparkles", "Floor-based features")
UI.Tabs.UISettings = Window:AddTab("UI Settings", "menu", "Menu and Ethereal Settings")

UI.Tabboxes.CharacterPlayer = UI.Tabs.Main:AddTabbox({
    Side = "Left",
    Name = "Character & Player",
})
UI.Tabgroups.Character = UI.Tabboxes.CharacterPlayer:AddTab("Character", "sliders-horizontal")
UI.Tabgroups.Player = UI.Tabboxes.CharacterPlayer:AddTab("Player", "user-pen")
UI.Groups.GameManagement = UI.Tabs.Main:AddGroupbox({
    Side = "Right",
    Name = "Game Management",
    IconName = "list",
})
UI.Groups.Automation = UI.Tabs.Main:AddGroupbox({
    Side = "Right",
    Name = "Automation",
    IconName = "refresh-cw",
})
UI.Groups.Prompts = UI.Tabs.Main:AddGroupbox({
    Side = "Left",
    Name = "Prompts",
    IconName = "mouse-pointer-click",
})
UI.Groups.FloorAutomation = UI.Tabs.Floor:AddGroupbox({
    Side = "Right",
    Name = "Automation",
    IconName = "refresh-cw",
})
UI.Groups.Modifiers = UI.Tabs.Floor:AddGroupbox({
    Side = "Left",
    Name = "Modifiers",
    IconName = "text-align-start",
})
UI.Tabboxes.ESPSettings = UI.Tabs.Visuals:AddTabbox({
    Side = "Left",
    Name = "ESP & Settings",
})
UI.Tabgroups.ESP = UI.Tabboxes.ESPSettings:AddTab("ESP", "eye-dashed")
UI.Tabgroups.ESPSettings = UI.Tabboxes.ESPSettings:AddTab("Settings", "settings")
UI.Groups.Ambient = UI.Tabs.Visuals:AddGroupbox({
    Side = "Left",
    Name = "Ambient",
    IconName = "leaf",
})

SpeedBypassLabel = UI.Tabgroups.Character:AddLabel("Speed Bypass: <font color=\"rgb(214, 214, 214)\">Idle</font>", false)
UI.Tabgroups.Character:AddToggle("SpeedHackToggle", {
    Text = "Enable Speed Hack",
})
UI.Tabgroups.Character:AddSlider("CrouchDelaySlider", {
    Text = "Bypass Delay",
    Default = 0,
    Min = 0,
    Max = 0.2,
    Rounding = 2,
    Compact = true
})
UI.Tabgroups.Character:AddSlider("WalkingSpeedSlider", {
    Text = "Walking Speed",
    Default = 16,
    Min = 0,
    Max = 75,
})
UI.Tabgroups.Character:AddDivider()
UI.Tabgroups.Character:AddToggle("EnableJumpToggle", {
    Text = "Enable Jump",
})
UI.Tabgroups.Character:AddToggle("InfiniteJumpsToggle", {
    Text = "Infinite Jumps",
})
UI.Tabgroups.Character:AddDivider()
UI.Tabgroups.Character:AddToggle("EnableSlidingToggle", {
    Text = "Enable Sliding",
})
UI.Tabgroups.Character:AddToggle("NoAccelerationToggle", {
    Text = "No Acceleration",
})
UI.Tabgroups.Character:AddDivider()
UI.Tabgroups.Character:AddToggle("NoclipToggle", {
    Text = "Noclip",
})
UI.Tabgroups.Character:AddToggle("FlyToggle", {
    Text = "Fly",
})
UI.Tabgroups.Character:AddSlider("FlySpeedSlider", {
    Text = "Fly Speed",
    Default = 15,
    Min = 0,
    Max = 75,
    Rounding = 1,
})
UI.Tabgroups.Player:AddToggle("DoorReachToggle", {
    Text = "Door Reach",
})
UI.Tabgroups.Player:AddToggle("FastClosetExitToggle", {
    Text = "Fast Closet Exit",
})
UI.Tabgroups.Player:AddToggle("AntiAFKToggle", {
    Text = "Anti AFK",
})
UI.Groups.GameManagement:AddButton({
    Text = "Reset Character",
    DoubleClick = true,
    Func = function()
        local ok = pcall(function()
            replicatesignal(Refs.LocalPlayer.Kill)
        end)
        if ok then return end
        if Refs.RemotesFolder:FindFirstChild("Underwater") then
            Refs.RemotesFolder.Underwater:FireServer(true)
        else
            Refs.Humanoid.Health = 0
        end
    end
})
UI.Groups.GameManagement:AddButton({
    Text = "Revive",
    DoubleClick = true,
    Func = function()
        Refs.RemotesFolder.Revive:FireServer()
    end
})
UI.Groups.GameManagement:AddButton({
    Text = "Play Again",
    DoubleClick = true,
    Func = function()
        Refs.RemotesFolder.PlayAgain:FireServer()
    end
})
UI.Groups.GameManagement:AddButton({
    Text = "Return to Lobby",
    DoubleClick = true,
    Func = function()
        Refs.RemotesFolder.Lobby:FireServer()
    end
})
UI.Groups.Automation:AddToggle("AutoHeartbeatToggle", {
    Text = "Auto Heartbeat Minigame",
})
UI.Groups.Automation:AddDivider()
UI.Groups.Automation:AddToggle("AutoHidingToggle", {
    Text = "Auto Hiding Spot v2",
})
UI.Groups.Prompts:AddToggle("AutoInteractToggle", {
    Text = "Auto Interact",
})
UI.Groups.Prompts:AddDropdown("InteractIgnoreListDropdown", {
    Text = "Ignore List",
    Values = { "Jeff Items", "Dropped Items", "Currency", "Glitch Fragment", "Paintings", "Unlock Prompts", "Skull Prompt" },
    Default = { "Jeff Items", "Glitch Fragment" },
    Multi = true
})
UI.Groups.Prompts:AddDivider()
UI.Groups.Prompts:AddToggle("InstantInteractToggle", {
    Text = "Instant Interact",
})
UI.Groups.Prompts:AddToggle("PromptClipToggle", {
    Text = "Prompt Clip",
})
UI.Groups.Prompts:AddSlider("PromptReachMultiplierSlider", {
    Text = "Prompt Reach Multiplier",
    Default = 1,
    Min = 1,
    Max = 2,
    Rounding = 1
})
UI.Tabgroups.ESP:AddDropdown("EntitiesForESPDropdown", {
    Text = "Entities for ESP",
    Values = { "Rush", "RNIUSHCG==", "Ambush", "AR0XMBUSH", "Blitz", "Eyes", "Lookman", "Snare", "Giggle", "Screech", "Sally", "A60", "A120", "Gloombat Pile", "Glitch Fragment" },
    Default = { "Rush", "RNIUSHCG==", "Ambush", "AR0XMBUSH", "Blitz", "Eyes", "Lookman", "Snare", "Giggle", "Screech", "Sally", "A60", "A120", "Gloombat Pile", "Glitch Fragment" },
    Multi = true
})
UI.Tabgroups.ESP:AddToggle("EntityESPToggle", {
    Text = "Entity",
}):AddColorPicker("EntityESPColorPicker", {
    Default = Color3.fromRGB(255, 0, 0),
})
UI.Tabgroups.ESP:AddDivider()
UI.Tabgroups.ESP:AddToggle("PlayerESPToggle", {
    Text = "Player",
}):AddColorPicker("PlayerESPColorPicker", {
    Default = Color3.fromRGB(255, 255, 255),
})
UI.Tabgroups.ESP:AddToggle("DoorESPToggle", {
    Text = "Door",
}):AddColorPicker("DoorESPColorPicker", {
    Default = Color3.fromRGB(0, 200, 255),
})
UI.Tabgroups.ESP:AddToggle("ObjectiveESPToggle", {
    Text = "Objective",
}):AddColorPicker("ObjectiveESPColorPicker", {
    Default = Color3.fromRGB(0, 255, 0),
})
UI.Tabgroups.ESP:AddDivider()
UI.Tabgroups.ESP:AddToggle("GoldESPToggle", {
    Text = "Gold",
}):AddColorPicker("GoldESPColorPicker", {
    Default = Color3.fromRGB(255, 255, 0),
})
UI.Tabgroups.ESP:AddToggle("StardustESPToggle", {
    Text = "Stardust",
}):AddColorPicker("StardustESPColorPicker", {
    Default = Color3.fromRGB(225, 150, 120),
})
UI.Tabgroups.ESP:AddToggle("ItemESPToggle", {
    Text = "Item",
}):AddColorPicker("ItemESPColorPicker", {
    Default = Color3.fromRGB(255, 0, 255),
})
UI.Tabgroups.ESP:AddToggle("ChestESPToggle", {
    Text = "Chest",
}):AddColorPicker("ChestESPColorPicker", {
    Default = Color3.fromRGB(255, 255, 0),
})
UI.Tabgroups.ESP:AddToggle("ToolboxESPToggle", {
    Text = "Toolbox",
}):AddColorPicker("ToolboxESPColorPicker", {
    Default = Color3.fromRGB(255, 255, 0),
})
UI.Tabgroups.ESP:AddDivider()
UI.Tabgroups.ESP:AddToggle("ClosetESPToggle", {
    Text = "Closet",
}):AddColorPicker("ClosetESPColorPicker", {
    Default = Color3.fromRGB(35, 130, 0),
})
UI.Tabgroups.ESP:AddToggle("GuidingLightESPToggle", {
    Text = "Guiding Light",
}):AddColorPicker("GuidingLightESPColorPicker", {
    Default = Color3.fromRGB(0, 115, 255),
})
UI.Tabgroups.ESPSettings:AddDropdown("ESPTypeDropdown", {
    Text = "ESP Type",
    Values = { "Highlight", "Selection Box", "Adornment" },
    Default = 1
})
UI.Tabgroups.ESPSettings:AddDivider("Render Settings")
UI.Tabgroups.ESPSettings:AddDropdown("ESPComponentsDropdown", {
    Text = "ESP Components",
    Values = { "Text", "Highlight", "Tracer", "Arrow", "Box 2D", "Box 3D", "Skeleton" },
    Default = { "Text", "Highlight" },
    Mult i= true
})
UI.Tabgroups.ESPSettings:AddDropdown("TracersOriginDropdown", {
    Text = "Tracers Origin",
    Values = { "Bottom", "Center", "Top" },
    Default = 1,
})
UI.Tabgroups.ESPSettings:AddToggle("RainbowESPToggle", {
    Text = "Rainbow ESP",
})
UI.Tabgroups.ESPSettings:AddDivider("Text Settings")
UI.Tabgroups.ESPSettings:AddToggle("ShowDistanceESPToggle", {
    Text = "Show Distance",
})
UI.Tabgroups.ESPSettings:AddToggle("ShowNameESPToggle", {
    Text = "Show Name",
})
UI.Tabgroups.ESPSettings:AddDropdown("ESPTextFontDropdown", {
    Text = "Text Font",
    Values = {
        "Legacy", "SourceSans", "SourceSansBold", "SourceSansLight", "SourceSansItalic",
        "Bodoni", "Garamond", "Cartoon", "Code", "Highway", "SciFi", "Arcade", "Fantasy",
        "Antique", "SourceSansSemibold", "AmaticSC", "Bangers", "Creepster", "DenkOne",
        "Fondamento", "FredokaOne", "GrenzeGotisch", "IndieFlower", "JosefinSans", "Jura",
        "Kalam", "LuckiestGuy", "Merriweather", "Michroma", "Nunito", "Oswald", "PatrickHand",
        "PermanentMarker", "Roboto", "RobotoCondensed", "RobotoMono", "Sarpanch",
        "SpecialElite", "TitilliumWeb", "Ubuntu", "BuilderSans", "BuilderSansMedium",
        "BuilderSansBold", "BuilderSansExtraBold", "Arimo", "ArimoBold",
    },
    Default = 1
})
UI.Tabgroups.ESPSettings:AddSlider("ESPTextSizeSlider", {
    Text = "Text Size",
    Default = 22,
    Min = 8,
    Max = 26,
    Compact = true
})
UI.Tabgroups.ESPSettings:AddDivider("Highlight Settings")
UI.Tabgroups.ESPSettings:AddSlider("ESPFillTransparencySlider", {
    Text = "Fill Transparency",
    Default = 0.75,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = true
})
UI.Tabgroups.ESPSettings:AddSlider("ESPOutlineTransparencySlider", {
    Text = "Outline Transparency",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = true
})
UI.Groups.Ambient:AddSlider("BrightnessSlider", {
    Text = "Brightness",
    Default = 0,
    Min = 0,
    Max = 3
})
UI.Groups.Ambient:AddToggle("FullbrightToggle", {
    Text = "Fullbright",
})
UI.Groups.Ambient:AddToggle("NoFogToggle", {
    Text = "No Fog",
})
UI.Groups.Ambient:AddToggle("AntiLagToggle", {
    Text = "Anti-Lag",
})
UI.Groups.FloorAutomation:AddToggle("AutoBreakerBoxToggle", {
    Text = "Auto Breaker Box",
})
UI.Groups.FloorAutomation:AddDropdown("AutoBreakerResolverModeDropdown", {
    Text = "Auto Breaker Resolver Mode",
    Values = { "Legit", "Exploit" },
    Default = 1
})
UI.Groups.FloorAutomation:AddDivider()
UI.Groups.FloorAutomation:AddToggle("AutoPadlockToggle", {
    Text = "Auto Padlock",
})
UI.Groups.FloorAutomation:AddDropdown("AutoPadlockModeDropdown", {
    Text = "Auto Padlock Mode",
    Values = { "Unlock", "Notify" },
    Default = 1
})
UI.Groups.FloorAutomation:AddSlider("AutoPadlockDistanceSlider", {
    Text = "Unlock Distance",
    Default = 25,
    Min = 1,
    Max = 100,
    Compact = true,
    Visible = true
})
UI.Groups.FloorAutomation:AddToggle("BruteForcePadlockToggle", {
    Text = "Bruteforce Padlock",
    Visible = true
})
BruteForcePadlockLabel = UI.Groups.FloorAutomation:AddLabel("The brute-force method cycles through many code variations to find the correct one. It is recommended to collect three correct books.", true)
NoFunctionsModifiersLabel = UI.Groups.Modifiers:AddLabel("There are no functions for this category.", true)

local function GetEtherealFolder()
    for _, child in ipairs(game:GetService("CoreGui"):GetChildren()) do
        local ethereal = child:FindFirstChild("EtherealUI") or (child.Name == "EtherealUI" and child)
        if ethereal then
            return ethereal
        end
    end
    return nil
end

task.spawn(function()
    local etherealUI
    repeat
        etherealUI = GetEtherealFolder()
        task.wait(0.1)
    until etherealUI

    local backgroundLabel = etherealUI:FindFirstChildOfClass("ImageLabel") or etherealUI:FindFirstChild("ImageLabel", true)

    if backgroundLabel and mascotAsset ~= "" then
        backgroundLabel.ClipsDescendants = false
        
        local mainFrame = etherealUI:FindFirstChild("Main", true) or backgroundLabel.Parent

        if mainFrame and mainFrame:IsA("GuiObject") then
            mainFrame.ClipsDescendants = false
        end

        local Mascot = Instance.new("ImageLabel")
        Mascot.Name = "EtherealMascot"
        Mascot.Parent = backgroundLabel
        Mascot.BackgroundTransparency = 1
        Mascot.Image = mascotAsset
        Mascot.Size = UDim2.fromOffset(80, 80)        
        Mascot.Position = UDim2.new(0, 120, 0, -65)
        Mascot.ZIndex = 999999

        local function SyncWithMain()
            if mainFrame then
                Mascot.ImageTransparency = mainFrame.BackgroundTransparency
                
                Mascot.Visible = mainFrame.Visible and mainFrame.BackgroundTransparency < 0.95
            end
        end

        SyncWithMain()

        if mainFrame then
            mainFrame:GetPropertyChangedSignal("BackgroundTransparency"):Connect(SyncWithMain)
            mainFrame:GetPropertyChangedSignal("Visible"):Connect(SyncWithMain)
        end
    end
end)

local FlyBody = Instance.new("BodyVelocity")
FlyBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)
local CachedCollisionPart = nil
local LastNoclipState = false
local noclipConnection = nil
local lastNoclipForce = 0
local DoorConnection = nil
local LastDoorFire = 0
local AntiAFKConnection = nil
local JumpButton = nil
local targetWalkSpeed = Options.WalkingSpeedSlider.Value
local crouchSpamInterval = 0
local crouchingAtribute = "Crouching"
local pendingOwn = 0
local lastCrouchFire = tick()
local OldJump = false
local OldSlide = false
local lastAnimCheck = tick()
local isSliding = false
local lastLabelUpdate = 0
local PartProperties = {}
local CustomPhysics = nil

local dangerEntities = {
    Figure = true, FigureRig = true, FigureRagdoll = true,
}

function Func.GetFloor()
    local now = tick()
    if now - Cache.floorLastUpdate < 2 then
        return Cache.floor
    end
    Cache.floorLastUpdate = now

    local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
    if GameData and GameData:FindFirstChild("Floor") then
        local FloorValue = GameData.Floor.Value
        if FloorValue == "Archives" then
            Cache.floor = "OldHotel"
        else
            Cache.floor = FloorValue
        end
    end
    return Cache.floor
end

function Func.GetCollisionPart()
    if Cache.collisionPart and Cache.collisionPart.Parent then
        return Cache.collisionPart
    end
    local char = Refs.LocalPlayer.Character
    if not char then return nil end
    Cache.collisionPart = char:FindFirstChild("CollisionPart") or char:FindFirstChild("Collision")
    return Cache.collisionPart
end

function Func.GetFlyVelocity()
    if Refs.Humanoid and Refs.Humanoid.MoveDirection == Vector3.zero then
        return Vector3.zero
    end
    if not Refs.Camera or not Refs.Humanoid then return Vector3.zero end
    local LookFlat = Vector3.new(Refs.Camera.CFrame.LookVector.X, 0, Refs.Camera.CFrame.LookVector.Z)
    local FlatFrame = CFrame.new(Refs.Camera.CFrame.Position, Refs.Camera.CFrame.Position + LookFlat)
    local Velocity = (Refs.Camera.CFrame * CFrame.new(FlatFrame:VectorToObjectSpace(Refs.Humanoid.MoveDirection))).Position - Refs.Camera.CFrame.Position
    if Velocity == Vector3.zero then
        return Vector3.zero
    end
    return Velocity.Unit
end

local originalNamecall = nil
local nameCallHandlers = {}
local nameCallInstalled = false

function Func.InstallNameCallHandler()
    if nameCallInstalled then return end
    if not getrawmetatable or not newcclosure or not getnamecallmethod then
        warn("[F]ella: executor не поддерживает хуки __namecall")
        return
    end

    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    originalNamecall = oldNamecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = { ... }
        for _, handler in ipairs(nameCallHandlers) do
            local result = handler(self, method, args)
            if result == "BLOCK" then
                return
            elseif type(result) == "table" then
                args = result
            end
        end
        return oldNamecall(self, table.unpack(args))
    end)
    setreadonly(mt, true)
    nameCallInstalled = true
end

function Func.AddNameCallHandler(fn)
    table.insert(nameCallHandlers, fn)
end

Func.InstallNameCallHandler()

Func.AddNameCallHandler(function(self, method, args)
    if self == Refs.CrouchRemote then
        if pendingOwn > 0 then
            pendingOwn -= 1
        else
            if Refs.Character and args[1] ~= nil then
                Refs.Character:SetAttribute(crouchingAtribute, args[1])
            end
        end
    end
end)

Func.AddNameCallHandler(function(self, method, args)
    if method == "FireServer" and self and self.Name == "ClutchHeartbeat" and Toggles.AutoHeartbeatToggle.Value then
        return "BLOCK"
    end
end)

Options.WalkingSpeedSlider:OnChanged(function(Value)
    targetWalkSpeed = Value
    if Refs.Humanoid and Toggles.SpeedHackToggle.Value then
        Refs.Humanoid.WalkSpeed = Value
    end
end)

targetWalkSpeed = Options.WalkingSpeedSlider.Value

function Func.UpdateSpeedLabel()
    local active = Toggles.SpeedHackToggle.Value and Options.WalkingSpeedSlider.Value > 19
    if active then
        SpeedBypassLabel:SetText("Speed Bypass: <font color=\"rgb(73, 230, 133)\">Active</font>")
    else
        SpeedBypassLabel:SetText("Speed Bypass: <font color=\"rgb(214, 214, 214)\">Idle</font>")
    end
end

Toggles.EnableJumpToggle:OnChanged(function(Value)
    if Refs.Character then
        Refs.Character:SetAttribute("CanJump", Value and true or OldJump)
    end
end)
Toggles.EnableSlidingToggle:OnChanged(function(Value)
    if Refs.Character then
        Refs.Character:SetAttribute("CanSlide", Value and true or OldSlide)
    end
end)

local props = Refs.RootPart.CustomPhysicalProperties
if props then
    CustomPhysics = PhysicalProperties.new(100, props.Friction, props.Elasticity, props.FrictionWeight, props.ElasticityWeight)
end
for _, Part in Refs.Character:GetDescendants() do
    if Part:IsA("BasePart") then
        PartProperties[Part] = Part.CustomPhysicalProperties
    end
end

Toggles.NoAccelerationToggle:OnChanged(function(Value)
    for Part, Old in PartProperties do
        Part.CustomPhysicalProperties = Value and CustomPhysics or Old
    end
end)

Toggles.DoorReachToggle:OnChanged(function(Value)
    if not Value then
        LastDoorFire = 0
    end
end)

Toggles.AntiAFKToggle:OnChanged(function(Value)
    if Value then
        if not AntiAFKConnection then
            AntiAFKConnection = Refs.LocalPlayer.Idled:Connect(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
        end
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil
        end
    end
end)

function Func.FindJumpButton()
    if JumpButton and JumpButton.Parent then return end
    local main = Refs.LocalPlayer.PlayerGui:FindFirstChild("MainUI")
    if main and main:FindFirstChild("MainFrame") and main.MainFrame:FindFirstChild("MobileButtons") then
        JumpButton = main.MainFrame.MobileButtons:FindFirstChild("JumpButton")
        if JumpButton then
            JumpButton.MouseButton1Down:Connect(function()
                if Toggles.InfiniteJumpsToggle.Value then
                    Refs.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end
end

Func.FindJumpButton()
Refs.LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "MainUI" then
        Func.FindJumpButton()
    end
end)

OldJump = Refs.Character:GetAttribute("CanJump")
OldSlide = Refs.Character:GetAttribute("CanSlide")

Refs.Character:GetAttributeChangedSignal("CanJump"):Connect(function()
    local Val = Refs.Character:GetAttribute("CanJump")
    if Toggles.EnableJumpToggle.Value and Val ~= true or not Toggles.EnableJumpToggle.Value then
        OldJump = Val
    end
    if Toggles.EnableJumpToggle.Value then Refs.Character:SetAttribute("CanJump", true) end
end)
Refs.Character:GetAttributeChangedSignal("CanSlide"):Connect(function()
    local Val = Refs.Character:GetAttribute("CanSlide")
    if Toggles.EnableSlidingToggle.Value and Val ~= true or not Toggles.EnableSlidingToggle.Value then
        OldSlide = Val
    end
    if Toggles.EnableSlidingToggle.Value then Refs.Character:SetAttribute("CanSlide", true) end
end)

function Func.ApplyNoclip(char, on)
    for _, Part in char:GetDescendants() do
        if Part:IsA("BasePart") then
            Part.CanCollide = not on
        end
    end
end

Toggles.NoclipToggle:OnChanged(function(Value)
    if Value and Refs.Character then
        Func.ApplyNoclip(Refs.Character, true)
        noclipConnection = Refs.Character.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") and Toggles.NoclipToggle.Value then
                task.defer(function() d.CanCollide = false end)
            end
        end)
    elseif noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
        if Refs.Character then Func.ApplyNoclip(Refs.Character, false) end
    end
end)

Refs.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    task.wait(0.5)
    if not Toggles.NoclipToggle.Value then return end
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    Func.ApplyNoclip(newCharacter, true)
    noclipConnection = newCharacter.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") and Toggles.NoclipToggle.Value then
            task.defer(function() d.CanCollide = false end)
        end
    end)
end)

local EntityDistances = {
    ["RushMoving"] = 85,
    ["AmbushMoving"] = 150,
    ["A60"] = 125,
    ["A120"] = 85,
    ["GlitchRush"] = 90,
    ["GlitchAmbush"] = 175,
    ["BackdoorRush"] = 85,
    ["CustomEntity"] = 85,
}

local HidingSpotNames = {
    Wardrobe = true, ["Wardrobe-FOOLS26"] = true, Backdoor_Wardrobe = true,
    RetroWardrobe = true, Toolshed = true, Bed = true, Double_Bed = true,
    Rooms_Locker = true, Rooms_Locker_Fridge = true, Locker_Large = true,
    CircularVent = true, Dumpster = true, SquareGrate = true,
}

function Func.IsHidePersistent()
    local floor = Func.GetFloor()
    return floor == "Mines" or floor == "Ripple" or floor == "Party"
end

function Func.GetNearestEntity()
    local nearest, nearestDist = nil, math.huge
    for _, entity in ipairs(Services.Workspace:GetChildren()) do
        local limit = EntityDistances[entity.Name]
        if limit and entity.PrimaryPart and entity:GetAttribute("Inactive") ~= true then
            local dist = Refs.LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
            if dist < limit and dist < nearestDist then
                nearest, nearestDist = entity, dist
            end
        end
    end
    return nearest
end

local hidingSpotCache = {}
local hidingSpotCacheRoom = nil

function Func.RefreshHidingSpotCache()
    hidingSpotCache = {}
    if not Refs.CurrentRooms then return end
    local roomNum = Refs.LocalPlayer:GetAttribute("CurrentRoom")
    if not roomNum then return end
    local room = Refs.CurrentRooms:FindFirstChild(tostring(roomNum))
    if not room then return end
    hidingSpotCacheRoom = tostring(roomNum)

    for _, spot in ipairs(room:GetDescendants()) do
        if HidingSpotNames[spot.Name] and spot:IsA("Model") then
            local prompt = spot:FindFirstChild("HidePrompt", true)
            if prompt and prompt:IsA("ProximityPrompt") then
                table.insert(hidingSpotCache, { spot = spot, prompt = prompt })
            end
        end
    end
end

function Func.GetNearestHidingSpot()
    if not Refs.Character or not Refs.Character.PrimaryPart then return nil end
    if not Refs.CurrentRooms then return nil end

    local roomNum = Refs.LocalPlayer:GetAttribute("CurrentRoom")
    if not roomNum then return nil end
    if hidingSpotCacheRoom ~= tostring(roomNum) then
        Func.RefreshHidingSpotCache()
    end

    local myPos = Refs.Character.PrimaryPart.Position
    local nearest, nearestDist = nil, math.huge
    local lastHideSpot = Refs.Character:FindFirstChild("LastHideSpot")
    local SEARCH_RADIUS = 30
    local persistent = Func.IsHidePersistent()

    for _, entry in ipairs(hidingSpotCache) do
        local spot, prompt = entry.spot, entry.prompt
        if spot.Parent and prompt.Parent then
            local root = spot.PrimaryPart or spot:FindFirstChildWhichIsA("BasePart")
            if root then
                local dist = (root.Position - myPos).Magnitude
                if dist < SEARCH_RADIUS and dist < nearestDist then
                    local canUse = not persistent or not lastHideSpot or lastHideSpot.Value ~= spot
                    if canUse then
                        nearest, nearestDist = { spot = spot, prompt = prompt, dist = dist }, dist
                    end
                end
            end
        end
    end

    return nearest
end

function Func.EnterHidingSpot(spot)
    local prompt = spot.prompt
    local oldLOS = prompt.RequiresLineOfSight
    local oldDist = prompt.MaxActivationDistance
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 99999
    prompt:InputHoldBegin()
    task.wait(prompt.HoldDuration + 0.05)
    prompt:InputHoldEnd()
    prompt.RequiresLineOfSight = oldLOS
    prompt.MaxActivationDistance = oldDist
end

function Func.IsFigureRoom()
    if not Refs.CurrentRooms then return false end
    local roomNum = Refs.LocalPlayer:GetAttribute("CurrentRoom")
    if not roomNum then return false end
    local room = Refs.CurrentRooms:FindFirstChild(tostring(roomNum))
    if not room then return false end
    local setup = room:FindFirstChild("FigureSetup")
    if not setup then return false end
    return setup:FindFirstChild("FigureRig") ~= nil
end

local TRACK_INTERVAL = 0.05

local tracker = {}

local RUSH_LIKE = {
    RushMoving = "rush",
    AmbushMoving = "ambush",
    BackdoorRush = "blitz",
    A60 = "torpedo",
    A120 = "persistent",
    GlitchRush = "rush",
    GlitchAmbush = "ambush",
    CustomEntity = "rush",
}

local RADIUS_CONFIG = {
    rush = {
        enter = 100,
        exit = 250,
        cooldown = 0.5,
    },
    ambush = {
        enter = 150,
        exit = 400,
        cooldown = 1,
    },
    blitz = {
        enter = 200,
        exit = math.huge,
        cooldown = 3,
    },
    persistent = {
        enter = 200,
        exit = math.huge,
        cooldown = 2,
    },
    torpedo = {
        enter = 300,
        exit = 500,
        cooldown = 0.5,
    },
}
local GONE_COOLDOWN = {
    rush = 0.5,
    ambush = 1,
    blitz = 3,
    persistent = 2,
    torpedo = 0.5,
}
local SPAWN_RADIUS = 30
local STOP_VELOCITY = 5

function Func.GetEntityPos(entity)
    if not entity then return nil end
    if entity.PrimaryPart then return entity.PrimaryPart.Position end
    local root = entity:FindFirstChild("HumanoidRootPart")
    if root then return root.Position end
    for _, c in ipairs(entity:GetChildren()) do
        if c:IsA("BasePart") then return c.Position end
    end
    return nil
end

function Func.UpdateTracker()
    local now = tick()
    local seen = {}

    for _, entity in ipairs(Services.Workspace:GetChildren()) do
        local kind = RUSH_LIKE[entity.Name]
        if kind then
            local pos = Func.GetEntityPos(entity)
            if pos then
                seen[entity.Name] = true
                local rec = tracker[entity.Name]

                if rec and rec.goneAt then
                    tracker[entity.Name] = nil
                    rec = nil
                end

                if not rec then
                    rec = {
                        kind = kind,
                        firstPos = pos,
                        firstSeen = now,
                        lastPos = pos,
                        lastSeen = now,
                        velocity = Vector3.zero,
                        engaged = false,
                    }
                    tracker[entity.Name] = rec
                end

                if rec.lastPos then
                    local delta = pos - rec.lastPos
                    local dt = math.max(now - rec.lastSeen, 0.001)
                    rec.velocity = delta / dt
                end

                rec.lastPos = pos
                rec.lastSeen = now
            end
        end
    end

    for name, rec in pairs(tracker) do
        if not seen[name] then
            rec.goneAt = rec.goneAt or now
        else
            rec.goneAt = nil
        end
    end
end

function Func.IsAtSpawn(rec)
    if not rec.firstPos or not rec.lastPos then return false end
    local atSpawn = (rec.lastPos - rec.firstPos).Magnitude < SPAWN_RADIUS
    local stopped = rec.velocity.Magnitude < STOP_VELOCITY
    if not (atSpawn and stopped) then return false end
    if Refs.Character and Refs.Character.PrimaryPart then
        local toUs = (Refs.Character.PrimaryPart.Position - rec.lastPos).Magnitude
        if toUs < 50 then return false end
    end
    return true
end

function Func.ShouldStayHidden()
    local now = tick()
    local myPos = Refs.Character and Refs.Character.PrimaryPart and Refs.Character.PrimaryPart.Position or nil
    if not myPos then return false, nil, nil end

    local result = false
    local resultName, resultReason = nil, nil

    for name, rec in pairs(tracker) do
        local cfg = RADIUS_CONFIG[rec.kind]
        if cfg and rec.lastPos then
            if rec.goneAt then
                rec.engaged = false
                local goneTime = now - rec.goneAt
                if goneTime < cfg.cooldown then
                    result = true
                    resultName, resultReason = name, rec.kind .. "-just-gone"
                end
            else
                local dist = (myPos - rec.lastPos).Magnitude

                if rec.engaged then
                    if dist > cfg.exit then
                        rec.engaged = false
                    else
                        result = true
                        resultName, resultReason = name, rec.kind .. "-engaged"
                    end
                else
                    if dist < cfg.enter then
                        rec.engaged = true
                        result = true
                        resultName, resultReason = name, rec.kind .. "-engaged"
                    end
                end
            end
        end
    end

    return result, resultName, resultReason
end

function Func.GetPaperUI()
    if Cache.paperUI and Cache.paperUI.Parent then
        return Cache.paperUI
    end
    Cache.paperUI = nil

    local char = Refs.LocalPlayer.Character
    if char then
        local p = char:FindFirstChild("LibraryHintPaper") or char:FindFirstChild("LibraryHintPaperHard")
        if p then
            local ui = p:FindFirstChild("UI")
            if ui then
                Cache.paperUI = ui
                return ui
            end
        end
    end
    local bp = Refs.LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local p = bp:FindFirstChild("LibraryHintPaper") or bp:FindFirstChild("LibraryHintPaperHard")
        if p then
            local ui = p:FindFirstChild("UI")
            if ui then
                Cache.paperUI = ui
                return ui
            end
        end
    end
    return nil
end

local padlockNotification = nil
local padlockLastCode = nil

function Func.FormatPadlockCode(code)
    return "Code: " .. code
end

function Func.UpdatePadlockNotification(code)
    if padlockLastCode == code and padlockNotification then return end
    padlockLastCode = code

    local text = Func.FormatPadlockCode(code)

    if padlockNotification then
        padlockNotification:ChangeDescription(text)
    else
        padlockNotification = Library:Notify({
            Title = "Auto Padlock",
            Description = text,
            Persist = true,
        })
    end
end

function Func.ClearPadlockNotification()
    if padlockNotification then
        padlockNotification:Destroy()
        padlockNotification = nil
    end
    padlockLastCode = nil
end

local breakerWarning = nil

function Func.ShowBreakerWarning()
    if breakerWarning then return end
    breakerWarning = Library:Notify({
        Title = "Auto Breaker Box",
        Description = "Hide all UI that may block your view",
        Persist = true,
    })
end

function Func.HideBreakerWarning()
    if breakerWarning then
        breakerWarning:Destroy()
        breakerWarning = nil
    end
end

local padlockSolved = false
local padlockWatchConn = nil

function Func.StopWatchPadlock()
    if padlockWatchConn then
        padlockWatchConn:Disconnect()
        padlockWatchConn = nil
    end
end

function Func.WatchPadlockSolved(expectedCode)
    Func.StopWatchPadlock()
    local remote = Services.ReplicatedStorage.RemotesFolder and Services.ReplicatedStorage.RemotesFolder:FindFirstChild("PL")
    if not remote then return end

    padlockWatchConn = remote.OnClientEvent:Connect(function(receivedCode)
        if tostring(receivedCode) == tostring(expectedCode) then
            padlockSolved = true
            Func.ClearPadlockNotification()
            Func.StopWatchPadlock()
        end
    end)
end

function Func.GetHintMap()
    local perm = Refs.LocalPlayer.PlayerGui:FindFirstChild("PermUI")
    if not perm then return {} end
    local hints = perm:FindFirstChild("Hints")
    if not hints then return {} end

    local map = {}
    for _, child in ipairs(hints:GetChildren()) do
        if child.Name == "Icon" and child:IsA("ImageLabel") then
            local offsetX = child.ImageRectOffset.X
            local numLabel = child:FindFirstChild("TextLabel")
            if numLabel and numLabel.Text ~= "" then
                local num = tonumber(numLabel.Text)
                if num then
                    map[offsetX] = num
                end
            end
        end
    end
    return map
end

function Func.GetPadlockCode()
    local paper = Func.GetPaperUI()
    if not paper then return nil end

    local hintMap = Func.GetHintMap()
    if next(hintMap) == nil then return nil end

    local code = {}
    local complete = true
    for i = 1, 5 do
        local slot = paper:FindFirstChild(tostring(i))
        if slot then
            local num = hintMap[slot.ImageRectOffset.X]
            if num then
                code[i] = tostring(num)
            else
                code[i] = "_"
                complete = false
            end
        else
            code[i] = "_"
            complete = false
        end
    end

    return table.concat(code), complete
end

local cachedPadlock = nil

function Func.GetPadlockObject()
    if cachedPadlock and cachedPadlock.Parent then
        local pos
        if cachedPadlock:IsA("Model") then
            pos = cachedPadlock:GetPivot().Position
        elseif cachedPadlock:IsA("BasePart") then
            pos = cachedPadlock.Position
        end
        return cachedPadlock, pos
    end

    cachedPadlock = Services.Workspace:FindFirstChild("Padlock", true)
    if not cachedPadlock then return nil end

    local pos
    if cachedPadlock:IsA("Model") then
        pos = cachedPadlock:GetPivot().Position
    elseif cachedPadlock:IsA("BasePart") then
        pos = cachedPadlock.Position
    end
    return cachedPadlock, pos
end

local promptList = {}

local AutoInteractBlacklist = {
    HidePrompt = true, RiftPrompt = true, StarRiftPrompt = true,
    InteractPrompt = true, ClimbPrompt = true, DonatePrompt = true,
    DialoguePrompt = true, RevivePrompt = true, EnterPrompt = true,
    AnimatePrompt = true, ToolEventPrompt = true, Prompt = true,
    PropPrompt = true, SeatPrompt = true,
}

local LockPromptNames = {
    UnlockPrompt = true, SkullPrompt = true, LockPrompt = true,
    ThingToEnable = true, FusesPrompt = true,
}

local KeyItems = { "Key", "GeneratorFuse", "KeyBackdoor", "KeyElectrical", "KeyIron", "Lockpick", "SkeletonKey", "Shears", "Multitool" }
local OffhandKeyItems = { "Key", "GeneratorFuse", "KeyElectrical", "KeyIron" }

function Func.HasItem(name, onlyChar)
    local char = Refs.LocalPlayer.Character
    local bp = Refs.LocalPlayer:FindFirstChild("Backpack")
    if char and char:FindFirstChild(name) then return char:FindFirstChild(name) end
    if not onlyChar and bp and bp:FindFirstChild(name) then return bp:FindFirstChild(name) end
    return nil
end

function Func.GetPromptCategory(prompt)
    if not prompt or not prompt.Parent then return nil end
    local parent = prompt.Parent

    if parent:GetAttribute("JeffShop") then return "Jeff Items" end

    local drops = Services.Workspace:FindFirstChild("Drops")
    if drops and parent:IsDescendantOf(drops) then return "Dropped Items" end

    if parent.Name == "GoldPile" or parent.Name == "StardustPickup" then return "Currency" end

    if parent.Name == "GlitchCube" then return "Glitch Fragment" end

    if parent:GetAttribute("InteractionClass") == "Painting" then return "Paintings" end

    if prompt.Name == "UnlockPrompt" then return "Unlock Prompts" end
    if parent.Name:lower():find("locked") then return "Unlock Prompts" end

    if prompt.Name == "SkullPrompt" then return "Skull Prompt" end

    return nil
end

function Func.IsPromptIgnored(prompt)
    local cat = Func.GetPromptCategory(prompt)
    if cat then
        return Options.InteractIgnoreListDropdown.Value[cat] == true
    end
    if AutoInteractBlacklist[prompt.Name] then return true end
    return false
end

function Func.TriggerPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    if Func.IsPromptIgnored(prompt) then return end

    local parent = prompt.Parent
    local isLockPrompt = LockPromptNames[prompt.Name]
        or (parent and parent:GetAttribute("Locked") == true)
        or (parent and parent.Parent and parent.Parent.Name == "Locker_Small_Locked" and prompt.Name == "ActivateEventPrompt")

    if isLockPrompt then
        if Options.InteractIgnoreListDropdown.Value["Unlock Prompts"] then return end
        local hasKey = false
        for _, k in ipairs(KeyItems) do if Func.HasItem(k, true) then hasKey = true break end end
        for _, k in ipairs(OffhandKeyItems) do if Func.HasItem(k) then hasKey = true break end end
        if not hasKey then return end
    end

    if parent.Name == "CuttableVines" and not Func.HasItem("Shears", true) and not Func.HasItem("Multitool", true) then return end
    if parent.Name == "Chest_Vine" and not Func.HasItem("Shears", true) and not Func.HasItem("Multitool", true) then return end
    if parent.Name == "Cellar" and not Func.HasItem("Shears", true) and not Func.HasItem("Multitool", true) then return end
    if parent.Name == "SkullLock" and not Func.HasItem("SkeletonKey", true) then return end
    if parent.Name == "Lock1" and not Func.HasItem("Lockpick", true) and not Func.HasItem("Multitool", true) then return end
    if parent.Name == "Lock2" and not Func.HasItem("Lockpick", true) and not Func.HasItem("Multitool", true) then return end

    if prompt.Parent.Name == "GlitchCube" and Options.InteractIgnoreListDropdown.Value["Glitch Fragment"] then return end

    if (parent.Name == "KeyObtain" and (Func.HasItem("Key") or Func.HasItem("KeyBackdoor")))
        or (parent.Name == "ElectricalKeyObtain" and Func.HasItem("KeyElectrical")) then return end

    if parent.Name == "TrackLever" then return end

    if prompt.Name == "ActivateEventPrompt" and (prompt.ActionText == "Close"
        or parent.Name == "ElevatorBreaker"
        or (parent.Parent and parent.Parent.Name == "IndustrialGate")) then return end

    if prompt.Name == "ActivateEventPrompt" and (parent.Name == "Padlock" or parent.Name == "MinesAnchor") then return end

    if parent.Name == "LeverForGate" and prompt:GetAttribute("Interactions") then return end

    if parent.Parent and (parent.Parent.Name == "DoorFake" or parent.Parent.Name == "FakeDoor") then return end

    if parent.Name == "PushPrompt" and Options.InteractIgnoreListDropdown.Value["Minecarts"] then return end

    if (parent.Name == "GoldPile" or parent.Name == "StardustPickup") and Options.InteractIgnoreListDropdown.Value["Currency"] then return end

    if parent.Name == "Bandage" then
        local BPack = Func.HasItem("BandagePack")
        local hum = Refs.Character and Refs.Character:FindFirstChild("Humanoid")
        if hum and hum.Health >= hum.MaxHealth and not BPack then return end
        if BPack and BPack:GetAttribute("Durability") >= BPack:GetAttribute("DurabilityMax") then return end
    end

    if parent.Name == "Battery" then
        local tool = Refs.Character and Refs.Character:FindFirstChildOfClass("Tool")
        local BPack = Func.HasItem("BatteryPack")
        if not tool and not BPack then return end
    end

    if (parent.Name == "LibraryHintPaper" or parent.Name == "PickupItem") and (Func.HasItem("LibraryHintPaper") or Func.HasItem("LibraryHintPaperHard")) then return end
    if parent.Name == "AlarmClock" and Func.HasItem("AlarmClock") then return end
    if parent.Name == "KeyObtainFake" or parent.Name == "TithingPlate" then return end

    local oldLOS = prompt.RequiresLineOfSight
    local oldDist = prompt.MaxActivationDistance
    local oldHold = prompt.HoldDuration

    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = math.min((prompt:GetAttribute("MaxActivationDistance_Old") or 9) * Options.PromptReachMultiplierSlider.Value, 18)
    prompt.HoldDuration = 0

    local p = prompt
    task.spawn(function()
        local ok = pcall(function()
            fireproximityprompt(p)
        end)

        if not ok then
            pcall(function()
                p:InputHoldBegin()
                task.wait(0.08)
                p:InputHoldEnd()
            end)
        end

        task.wait(0.08)
        if p and p.Parent then
            pcall(function()
                p.RequiresLineOfSight = oldLOS
                p.MaxActivationDistance = oldDist
                p.HoldDuration = oldHold
            end)
        end
    end)
end

function Func.ApplyPromptTweaks(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    if prompt:GetAttribute("EtherealProcessed") then return end
    prompt:SetAttribute("EtherealProcessed", true)
    prompt:SetAttribute("HoldDuration_Old", prompt.HoldDuration)
    prompt:SetAttribute("RequiresLineOfSight_Old", prompt.RequiresLineOfSight)
    prompt:SetAttribute("MaxActivationDistance_Old", prompt.MaxActivationDistance)

    if Toggles.InstantInteractToggle.Value then
        prompt.HoldDuration = 0
    end
    if Toggles.PromptClipToggle.Value then
        prompt.RequiresLineOfSight = false
    end
    prompt.MaxActivationDistance = math.min(prompt:GetAttribute("MaxActivationDistance_Old") * Options.PromptReachMultiplierSlider.Value, 18)

    if prompt:HasTag("DisableWhenEnabledOnClient") then
        prompt:RemoveTag("DisableWhenEnabledOnClient")
    end

    table.insert(promptList, prompt)
end

function Func.RefreshPromptTweaks()
    local i = #promptList
    while i >= 1 do
        local prompt = promptList[i]
        if prompt and prompt.Parent then
            prompt.HoldDuration = Toggles.InstantInteractToggle.Value and 0 or prompt:GetAttribute("HoldDuration_Old")
            prompt.RequiresLineOfSight = Toggles.PromptClipToggle.Value and false or prompt:GetAttribute("RequiresLineOfSight_Old")
            prompt.MaxActivationDistance = math.min(prompt:GetAttribute("MaxActivationDistance_Old") * Options.PromptReachMultiplierSlider.Value, 18)
        else
            table.remove(promptList, i)
        end
        i -= 1
    end
end

function Func.ScanWorkspacePrompts()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and not obj:GetAttribute("EtherealProcessed") then
            Func.ApplyPromptTweaks(obj)
        end
    end
end

Func.ScanWorkspacePrompts()

local promptDescAddedConn = Services.Workspace.DescendantAdded:Connect(function(obj)
    if unloaded then return end
    if obj:IsA("ProximityPrompt") then
        task.defer(function()
            Func.ApplyPromptTweaks(obj)
        end)
    end
end)

Toggles.InstantInteractToggle:OnChanged(function()
    Func.RefreshPromptTweaks()
end)
Toggles.PromptClipToggle:OnChanged(function()
    Func.RefreshPromptTweaks()
end)
Options.PromptReachMultiplierSlider:OnChanged(function()
    Func.RefreshPromptTweaks()
end)

local triggerDebounce = false

Func.RegisterLoop("AutoInteract", CONST.AUTO_INTERACT_INTERVAL, function()
    if not Toggles.AutoInteractToggle.Value then return end
    if not Refs.Character or not Refs.Character.PrimaryPart then return end
    if triggerDebounce then return end

    local myPos = Refs.Character.PrimaryPart.Position
    local bestPrompt, bestDist = nil, math.huge
    local i = #promptList

    while i >= 1 do
        local prompt = promptList[i]
        if not prompt or not prompt.Parent then
            table.remove(promptList, i)
        else
            local obj = prompt.Parent
            local pos
            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") then
                pos = obj:GetPivot().Position
            elseif obj:IsA("Attachment") then
                pos = obj.WorldPosition
            end

            if pos then
                local d = (pos - myPos).Magnitude
                if d <= prompt.MaxActivationDistance and prompt.Enabled and d < bestDist then
                    bestPrompt = prompt
                    bestDist = d
                end
            end
        end
        i -= 1
    end

    if bestPrompt then
        triggerDebounce = true
        Func.TriggerPrompt(bestPrompt)
        task.delay(0.15, function()
            triggerDebounce = false
        end)
    end
end)

local wasHiding = false

function Func.SetBruteForceVisible(visible)
    Toggles.BruteForcePadlockToggle:SetVisible(visible)
    BruteForcePadlockLabel:SetVisible(visible)
    Options.AutoPadlockDistanceSlider:SetVisible(visible)
end

Options.AutoPadlockModeDropdown:OnChanged(function(value)
    if value == "Notify" then
        Func.SetBruteForceVisible(false)
    elseif value == "Unlock" then
        Func.SetBruteForceVisible(true)
    end
end)

Func.SetBruteForceVisible(Options.AutoPadlockModeDropdown.Value == "Unlock")

Func.RegisterLoop("AutoHiding", CONST.TRACK_INTERVAL, function()
    if not Toggles.AutoHidingToggle.Value then
        tracker = {}
        wasHiding = false
        return
    end
    if not Refs.Character or not Refs.Character.PrimaryPart then return end
    if Func.IsFigureRoom() then
        tracker = {}
        wasHiding = false
        return
    end

    local hiding = Refs.Character:GetAttribute("Hiding") == true

    if wasHiding and not hiding then
        tracker = {}
    end
    wasHiding = hiding

    Func.UpdateTracker()

    local hide = Func.ShouldStayHidden()

    if hide then
        if not hiding then
            local spot = Func.GetNearestHidingSpot()
            if spot then
                Func.EnterHidingSpot(spot)
            end
        end
    else
        if hiding then
            Refs.Character:SetAttribute("Hiding", false)
        end
    end
end)

Func.RegisterLoop("AutoPadlock", CONST.AUTO_PADLOCK_INTERVAL, function()
    if not Toggles.AutoPadlockToggle.Value then
        Func.ClearPadlockNotification()
        padlockSolved = false
        return
    end

    local myChar = Refs.LocalPlayer.Character
    if not myChar or not myChar.PrimaryPart then return end

    local padlock, padlockPos = Func.GetPadlockObject()
    if not padlock or not padlockPos then
        Func.ClearPadlockNotification()
        return
    end

    local mode = Options.AutoPadlockModeDropdown.Value
    local dist = (myChar.PrimaryPart.Position - padlockPos).Magnitude
    local maxDist = Options.AutoPadlockDistanceSlider.Value

    if mode == "Unlock" and dist > maxDist then
        Func.ClearPadlockNotification()
        return
    end

    local paper = Func.GetPaperUI()
    if not paper then
        Func.ClearPadlockNotification()
        padlockSolved = false
        return
    end

    if padlockSolved then return end

    local code, complete = Func.GetPadlockCode()
    if not code then return end

    if mode == "Notify" then
        Func.UpdatePadlockNotification(code)
    elseif mode == "Unlock" then
        Func.ClearPadlockNotification()
        if complete then
            local remote = Services.ReplicatedStorage.RemotesFolder:FindFirstChild("PL")
            if remote then
                remote:FireServer(code)
                Func.WatchPadlockSolved(code)
            end
        end
    end
end)

Func.RegisterLoop("BruteForce", CONST.BRUTE_FORCE_INTERVAL, function()
    if not Toggles.BruteForcePadlockToggle.Value then return end

    local myChar = Refs.LocalPlayer.Character
    if not myChar or not myChar.PrimaryPart then return end

    local padlock, padlockPos = Func.GetPadlockObject()
    if not padlock or not padlockPos then return end

    local dist = (myChar.PrimaryPart.Position - padlockPos).Magnitude
    if dist > Options.AutoPadlockDistanceSlider.Value then return end

    local paper = Func.GetPaperUI()
    if not paper then return end

    local hintMap = Func.GetHintMap()
    if next(hintMap) == nil then return end

    local code, unknown = {}, {}
    for i = 1, 5 do
        local slot = paper:FindFirstChild(tostring(i))
        if slot then
            local num = hintMap[slot.ImageRectOffset.X]
            if num then
                code[i] = tostring(num)
            else
                code[i] = "?"
                table.insert(unknown, i)
            end
        else
            code[i] = "?"
            table.insert(unknown, i)
        end
    end

    local knownCount = 5 - #unknown
    if knownCount < 1 then return end

    if #unknown == 0 then
        local remote = Services.ReplicatedStorage.RemotesFolder:FindFirstChild("PL")
        if remote then
            remote:FireServer(table.concat(code))
        end
        return
    end

    local totalCombinations = 10 ^ #unknown
    local remote = Services.ReplicatedStorage.RemotesFolder:FindFirstChild("PL")
    if not remote then return end

    for combo = 0, totalCombinations - 1 do
        if unloaded or not Toggles.BruteForcePadlockToggle.Value then break end

        local digits = tostring(combo)
        while #digits < #unknown do
            digits = "0" .. digits
        end

        local testCode = table.concat(code)
        for idx, pos in ipairs(unknown) do
            local d = digits:sub(idx, idx)
            testCode = testCode:sub(1, pos - 1) .. d .. testCode:sub(pos + 1)
        end

        pcall(function()
            remote:FireServer(testCode)
        end)

        if combo % 10 == 0 then
            task.wait()
        end
    end
end)

local lastExploitFire = 0
local lastExploitCode = nil

function Func.ExploitBreakerBox(breaker)
    local surface = breaker:FindFirstChild("SurfaceGui")
    if not surface then return end
    local frame = surface:FindFirstChild("Frame")
    if not frame then return end
    local code = frame:FindFirstChild("Code")
    if not code then return end

    local currentCode = code.Text
    if currentCode == lastExploitCode then return end

    local now = tick()
    if now - lastExploitFire < 0.15 then return end

    lastExploitFire = now
    lastExploitCode = currentCode

    local ebf = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
    if ebf then
        ebf = ebf:FindFirstChild("EBF")
    end
    if not ebf then return end

    pcall(function()
        ebf:FireServer()
    end)
end

function Func.GetBreaker()
    local roomNum = Refs.LocalPlayer:GetAttribute("CurrentRoom")
    if not roomNum then return nil end
    local rooms = Services.Workspace:FindFirstChild("CurrentRooms")
    if not rooms then return nil end
    local room = rooms:FindFirstChild(tostring(roomNum))
    if not room then return nil end
    return room:FindFirstChild("ElevatorBreaker")
end

function Func.GetBreakerTarget(breaker)
    local surface = breaker:FindFirstChild("SurfaceGui")
    if not surface then return nil, nil end
    local frame = surface:FindFirstChild("Frame")
    if not frame then return nil, nil end
    local code = frame:FindFirstChild("Code")
    if not code then return nil, nil end

    local text = code.Text
    local id = tonumber(text)
    if not id then
        if text == "?" then
            id = -1
        else
            return nil, nil
        end
    end

    local indicator = code:FindFirstChild("Frame")
    if not indicator then return nil, nil end
    return id, indicator.BackgroundTransparency < 0.5
end

function Func.GetBreakerSwitch(breaker, id)
    for _, child in ipairs(breaker:GetChildren()) do
        if child.Name == "BreakerSwitch" and child:GetAttribute("ID") == id then
            return child
        end
    end
    return nil
end

function Func.ToggleBreakerSwitch(switch, shouldBeOn)
    switch:SetAttribute("Enabled", shouldBeOn)

    for _, c in ipairs(switch:GetDescendants()) do
        if c:IsA("PrismaticConstraint") then
            c.TargetPosition = shouldBeOn and -0.20000000298023224 or 0.20000000298023224

        elseif c:IsA("BasePart") and c.Name == "Light" then
            c.Material = shouldBeOn and Enum.Material.Neon or Enum.Material.Glass

        elseif c:IsA("Sound") then
            c:Play()

        elseif c:IsA("ParticleEmitter") and c.Name == "Spark" then
            local oldRate = c.Rate
            c.Rate = 500
            c.Enabled = true
            task.delay(0.15, function()
                if c and c.Parent then
                    c.Enabled = false
                    c.Rate = oldRate
                end
            end)

        elseif c:IsA("Attachment") and c.Name == "Spark" then
            for _, pe in ipairs(c:GetChildren()) do
                if pe:IsA("ParticleEmitter") then
                    local oldRate = pe.Rate
                    pe.Rate = 500
                    pe.Enabled = true
                    task.delay(0.1, function()
                        if pe and pe.Parent then
                            pe.Enabled = false
                            pe.Rate = oldRate
                        end
                    end)
                end
            end
        end
    end
end

local breakerInteractNotify = nil
local breakerStartNotify = nil

function Func.ShowInteractNotify()
    if breakerInteractNotify then return end
    breakerInteractNotify = Library:Notify({
        Title = "Auto Breaker Box",
        Description = "Interact with the breaker box to automatically solve it.",
        Persist = true,
    })
end

function Func.HideInteractNotify()
    if breakerInteractNotify then
        breakerInteractNotify:Destroy()
        breakerInteractNotify = nil
    end
end

function Func.ShowStartNotify(mode)
    if breakerStartNotify then
        breakerStartNotify:Destroy()
        breakerStartNotify = nil
    end
    local desc
    if mode == "Legit" then
        desc = "Automatic resolve using, wait until script finish."
    elseif mode == "Exploit" then
        desc = "Trying to use exploit method."
    else
        return
    end
    breakerStartNotify = Library:Notify({
        Title = "Auto Breaker Box",
        Description = desc,
        Persist = true,
    })
end

function Func.HideStartNotify()
    if breakerStartNotify then
        breakerStartNotify:Destroy()
        breakerStartNotify = nil
    end
end

local breakerInteractShown = false
local breakerStartShown = false
local lastProcessedId = nil
local breakerSeenIds = {}
local breakerSeenSession = nil

function Func.ResetBreakerState()
    Func.HideInteractNotify()
    Func.HideStartNotify()
    breakerInteractShown = false
    breakerStartShown = false
    lastProcessedId = nil
    lastExploitCode = nil
    breakerSeenIds = {}
    breakerSeenSession = nil
end

Func.RegisterLoop("BreakerBox", CONST.BREAKER_WAIT, function()
    if not Toggles.AutoBreakerBoxToggle.Value then
        Func.ResetBreakerState()
        return
    end

    local breaker = Func.GetBreaker()
    if not breaker then
        Func.ResetBreakerState()
        return
    end

    if breakerSeenSession ~= breaker then
        breakerSeenSession = breaker
        breakerSeenIds = {}
    end

    if not breakerInteractShown then
        Func.ShowInteractNotify()
        breakerInteractShown = true
    end

    local mode = Options.AutoBreakerResolverModeDropdown.Value

    if mode == "Exploit" then
        if not breakerStartShown then
            Func.HideInteractNotify()
            Func.ShowStartNotify("Exploit")
            breakerStartShown = true
        end
        Func.ExploitBreakerBox(breaker)
        return
    end

    local id, shouldBeOn = Func.GetBreakerTarget(breaker)
    if not id then return end

    local realId = id

    if id == -1 then
        local allIds = {}
        for i = 1, 10 do allIds[i] = true end
        for seenId in pairs(breakerSeenIds) do
            allIds[seenId] = nil
        end
        local missingId = nil
        for i = 1, 10 do
            if allIds[i] then
                missingId = i
                break
            end
        end
        if missingId then
            realId = missingId
        else
            return
        end
    else
        breakerSeenIds[realId] = true
    end

    local switch = Func.GetBreakerSwitch(breaker, realId)
    if not switch then return end

    local currentState = switch:GetAttribute("Enabled") == true
    if currentState == shouldBeOn then
        lastProcessedId = nil
        return
    end

    if not breakerStartShown then
        Func.HideInteractNotify()
        Func.ShowStartNotify("Legit")
        breakerStartShown = true
    end

    if lastProcessedId == realId then return end
    lastProcessedId = realId

    Func.ToggleBreakerSwitch(switch, shouldBeOn)
end)

function Func.UpdateCharacterRefs()
    Refs.Camera = Services.Workspace.CurrentCamera
    if not Refs.CurrentRooms or not Refs.CurrentRooms.Parent then
        Refs.CurrentRooms = Services.Workspace:FindFirstChild("CurrentRooms")
    end
    
    if not Refs.CrouchRemote or not Refs.CrouchRemote.Parent then
        Refs.CrouchRemote = Refs.RemotesFolder and Refs.RemotesFolder:FindFirstChild("Crouch")
    end

    if not Refs.Character or not Refs.Character.Parent then
        Refs.Character = Refs.LocalPlayer.Character
        if Refs.Character then
            Refs.RootPart = Refs.Character:FindFirstChild("HumanoidRootPart")
            Refs.Humanoid = Refs.Character:FindFirstChild("Humanoid")
            CachedCollisionPart = nil
            LastNoclipState = false
        end
    end

    if not Refs.RootPart or not Refs.RootPart.Parent then
        if Refs.Character then
            Refs.RootPart = Refs.Character:FindFirstChild("HumanoidRootPart")
        end
    end

    if not Refs.Humanoid or not Refs.Humanoid.Parent then
        if Refs.Character then
            Refs.Humanoid = Refs.Character:FindFirstChild("Humanoid")
        end
    end
end

function Func.CheckSlideAndCrouch()
    if not Refs.Character or not Refs.Humanoid then return end

    if Toggles.EnableSlidingToggle.Value and tick() - lastAnimCheck > CONST.RENDER_CHECK_INTERVAL then
        isSliding = false
        for _, Anim in Refs.Humanoid:GetPlayingAnimationTracks() do
            if Anim.Name == "Slide" then
                isSliding = true
                break
            end
        end
        lastAnimCheck = tick()
    end
    if Toggles.EnableSlidingToggle.Value then
        Refs.Character:SetAttribute("Sliding", isSliding)
    end

    local collisionPart = Func.GetCollisionPart()
    local actualCrouch
    if collisionPart then
        actualCrouch = collisionPart.CollisionGroup == "PlayerCrouching"
    else
        actualCrouch = Refs.Character:GetAttribute("Crouching") or false
    end
    if Refs.Character:GetAttribute("Crouching") ~= actualCrouch then
        Refs.Character:SetAttribute("Crouching", actualCrouch)
    end
end

function Func.ApplySpeedAndFly()
    if not Refs.Character or not Refs.Humanoid or not Refs.Character.Parent then return end

    local shouldCrouch = false

    if Toggles.SpeedHackToggle.Value then
        if Refs.Humanoid.WalkSpeed < targetWalkSpeed then
            Refs.Humanoid.WalkSpeed = targetWalkSpeed
        end
        shouldCrouch = true
    end

    if Toggles.FlyToggle.Value and Refs.RootPart and Refs.Camera then
        FlyBody.Parent = Refs.RootPart
        FlyBody.Velocity = Func.GetFlyVelocity() * Options.FlySpeedSlider.Value
        shouldCrouch = true
    else
        if FlyBody.Parent then
            FlyBody.Parent = nil
        end
    end

    if shouldCrouch and tick() - lastCrouchFire > Options.CrouchDelaySlider.Value then
        pendingOwn += 1
        pcall(function()
            if Refs.RemotesFolder and Refs.RemotesFolder:FindFirstChild("Crouch") then
                Refs.RemotesFolder.Crouch:FireServer(true, true)
            end
        end)
        lastCrouchFire = tick()
    end
end

function Func.ForceNoclip()
    if not Toggles.NoclipToggle.Value or not Refs.Character then return end
    if tick() - (lastNoclipForce or 0) < CONST.NOCLIP_FORCE_INTERVAL then return end
    lastNoclipForce = tick()

    for _, Part in Refs.Character:GetDescendants() do
        if Part:IsA("BasePart") and Part.CanCollide then
            Part.CanCollide = false
        end
    end
end

function Func.UpdateDoorReach()
    if not Toggles.DoorReachToggle.Value or not Refs.CurrentRooms then
        if DoorConnection then
            DoorConnection[2]:Disconnect()
            DoorConnection = nil
        end
        return
    end

    local roomNum = Refs.LocalPlayer:GetAttribute("CurrentRoom")
    if not roomNum then return end

    local room = Refs.CurrentRooms:FindFirstChild(tostring(roomNum))
    if not room then return end

    local door = room:FindFirstChild("Door")
    if not door or not door:FindFirstChild("ClientOpen") then return end

    if DoorConnection and DoorConnection[1] ~= door then
        DoorConnection[2]:Disconnect()
        DoorConnection = nil
    end

    if not DoorConnection then
        local conn
        conn = Services.RunService.Heartbeat:Connect(function()
            if not Toggles.DoorReachToggle.Value then
                conn:Disconnect()
                DoorConnection = nil
                return
            end
            local doorPart = door:FindFirstChild("Door")
            if doorPart and doorPart:IsA("BasePart") and Refs.RootPart then
                local dist = (Refs.RootPart.Position - doorPart.Position).Magnitude
                if dist < CONST.DOOR_REACH_DIST and tick() - LastDoorFire > CONST.DOOR_FIRE_COOLDOWN then
                    door.ClientOpen:FireServer()
                    LastDoorFire = tick()
                end
            end
        end)
        DoorConnection = {door, conn}
    end
end

function Func.UpdateFastClosetExit()
    if not Toggles.FastClosetExitToggle.Value or not Refs.Character or not Refs.Humanoid then return end
    if Refs.Humanoid.MoveDirection == Vector3.zero then return end
    if Refs.Character:GetAttribute("Hiding") ~= true then return end
    if Refs.RemotesFolder and Refs.RemotesFolder:FindFirstChild("CamLock") then
        Refs.RemotesFolder.CamLock:FireServer()
    end
end

Func.RegisterLoop("CharRefs", 0, Func.UpdateCharacterRefs)
Func.RegisterLoop("SlideCrouch", CONST.RENDER_CHECK_INTERVAL, Func.CheckSlideAndCrouch)
Func.RegisterLoop("SpeedFly", 0, Func.ApplySpeedAndFly)
Func.RegisterLoop("NoclipForce", CONST.NOCLIP_FORCE_INTERVAL, Func.ForceNoclip)
Func.RegisterLoop("DoorReach", 0.1, Func.UpdateDoorReach)
Func.RegisterLoop("FastCloset", 0.1, Func.UpdateFastClosetExit)
Func.RegisterLoop("LabelUpdate", CONST.LABEL_UPDATE_INTERVAL, Func.UpdateSpeedLabel)

local ESPConnections = {}
local ESPBlacklist = {}

local function SyncESPSettings()
    ESPLib:SetShowDistance(Toggles.ShowDistanceESPToggle.Value)
    ESPLib:SetRainbow(Toggles.RainbowESPToggle.Value)
    ESPLib:SetFillTransparency(Options.ESPFillTransparencySlider.Value)
    ESPLib:SetOutlineTransparency(Options.ESPOutlineTransparencySlider.Value)
    ESPLib:SetTextSize(Options.ESPTextSizeSlider.Value)

    local fontName = Options.ESPTextFontDropdown.Value
    local ok, font = pcall(function()
        return Enum.Font[fontName]
    end)
    ESPLib:SetFont(ok and font or Enum.Font.RobotoCondensed)

    local comps = Options.ESPComponentsDropdown.Value
    ESPLib:SetTracers(comps["Tracer"] == true)
    ESPLib:SetArrows(comps["Arrow"] == true)
end

Toggles.ShowDistanceESPToggle:OnChanged(SyncESPSettings)
Toggles.RainbowESPToggle:OnChanged(SyncESPSettings)
Options.ESPFillTransparencySlider:OnChanged(SyncESPSettings)
Options.ESPOutlineTransparencySlider:OnChanged(SyncESPSettings)
Options.ESPTextSizeSlider:OnChanged(SyncESPSettings)
Options.ESPTextFontDropdown:OnChanged(SyncESPSettings)
Options.ESPComponentsDropdown:OnChanged(SyncESPSettings)

SyncESPSettings()

local function AddESP(object, text, color)
    if not object or table.find(ESPBlacklist, object) then return end
    ESPLib:AddESP({ Object = object, Text = text, Color = color })
end

local function RemoveESP(object)
    ESPLib:RemoveESP(object)
    local conn = ESPConnections[object]
    if conn then
        conn:Disconnect()
        ESPConnections[object] = nil
    end
end

local function TrackObject(object, text, colorKey)
    local conn = object.Destroying:Connect(function()
        RemoveESP(object)
    end)
    ESPConnections[object] = conn
    AddESP(object, text, Options[colorKey].Value)
end

local EntityAliases = {
    Rush = "Rush",
    RNIUSHCG = "RNIUSHCG==",
    Ambush = "Ambush",
    AR0XMBUSH = "AR0XMBUSH",
    Blitz = "Blitz",
    Eyes = "Eyes",
    Lookman = "Lookman",
    Snare = "Snare",
    Giggle = "Giggle",
    Screech = "Screech",
    Sally = "Sally",
    A60 = "A-60",
    A120 = "A-120",
    ["Gloombat Pile"] = "Gloombat Pile",
    ["Glitch Fragment"] = "Glitch Fragment",
}

local EntityModelNames = {
    RushMoving = "Rush",
    AmbushMoving = "Ambush",
    BackdoorRush = "Blitz",
    Eyes = "Eyes",
    Lookman = "Lookman",
    A60 = "A-60",
    A120 = "A-120",
    GlitchRush = "RNIUSHCG==",
    GlitchAmbush = "AR0XMBUSH",
    GloombatPile = "Gloombat Pile",
    GlitchCube = "Glitch Fragment",
    Snare = "Snare",
    Giggle = "Giggle",
    Screech = "Screech",
    SallyMoving = "Sally",
    CustomEntity = "Custom Entity",
}

local function IsEntitySelected(alias)
    local sel = Options.EntitiesForESPDropdown.Value
    for _, v in ipairs(sel) do
        if v == alias then return true end
    end
    return false
end

local function RefreshEntityESP()
    if not Toggles.EntityESPToggle.Value then
        for _, obj in ipairs(Services.Workspace:GetChildren()) do
            if EntityModelNames[obj.Name] then
                RemoveESP(obj)
            end
        end
        return
    end
    for _, obj in ipairs(Services.Workspace:GetChildren()) do
        local alias = EntityModelNames[obj.Name]
        if alias and IsEntitySelected(alias) then
            if not ESPLib.ElementsEnabled[obj] then
                TrackObject(obj, alias, "EntityESPColorPicker")
            end
        end
    end
end

Toggles.EntityESPToggle:OnChanged(RefreshEntityESP)
Options.EntitiesForESPDropdown:OnChanged(function()
    RefreshEntityESP()
end)
Options.EntityESPColorPicker:OnChanged(function(v)
    for obj in pairs(ESPLib.ElementsEnabled) do
        if EntityModelNames[obj.Name] then
            ESPLib:UpdateObjectColor(obj, v)
        end
    end
end)

Services.Workspace.ChildAdded:Connect(function(child)
    if not Toggles.EntityESPToggle.Value then return end
    local alias = EntityModelNames[child.Name]
    if alias and IsEntitySelected(alias) then
        task.defer(function()
            TrackObject(child, alias, "EntityESPColorPicker")
        end)
    end
end)

local function AddPlayerESP(player)
    if player == Refs.LocalPlayer then return end
    local char = player.Character
    if char then AddESP(char, player.Name, Options.PlayerESPColorPicker.Value) end
    player.CharacterAdded:Connect(function(newChar)
        if Toggles.PlayerESPToggle.Value then
            task.wait(0.5)
            AddESP(newChar, player.Name, Options.PlayerESPColorPicker.Value)
        end
    end)
    player.CharacterRemoving:Connect(function(oldChar)
        RemoveESP(oldChar)
    end)
end

Toggles.PlayerESPToggle:OnChanged(function(value)
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Refs.LocalPlayer then
            if value then
                AddPlayerESP(player)
            else
                if player.Character then RemoveESP(player.Character) end
            end
        end
    end
end)
Options.PlayerESPColorPicker:OnChanged(function(v)
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player.Character then
            ESPLib:UpdateObjectColor(player.Character, v)
        end
    end
end)
Services.Players.PlayerAdded:Connect(function(player)
    if Toggles.PlayerESPToggle.Value then AddPlayerESP(player) end
end)

local trackedDoors = {}

local function TrackDoor(door, room)
    trackedDoors[door] = true
    AddESP(door, "Door " .. (tonumber(room.Name) or 0), Options.DoorESPColorPicker.Value)
    door.Destroying:Connect(function()
        RemoveESP(door)
        trackedDoors[door] = nil
    end)
end

local function ScanDoors()
    if not Refs.CurrentRooms then return end
    for _, room in ipairs(Refs.CurrentRooms:GetChildren()) do
        local door = room:FindFirstChild("Door")
        if door and not trackedDoors[door] then
            TrackDoor(door, room)
        end
    end
end

Toggles.DoorESPToggle:OnChanged(function(value)
    if value then
        ScanDoors()
        if Refs.CurrentRooms then
            Refs.CurrentRooms.ChildAdded:Connect(function(room)
                if not Toggles.DoorESPToggle.Value then return end
                task.defer(function()
                    local door = room:FindFirstChild("Door")
                    if door and not trackedDoors[door] then
                        TrackDoor(door, room)
                    end
                end)
            end)
        end
    else
        for door in pairs(trackedDoors) do
            RemoveESP(door)
        end
        trackedDoors = {}
    end
end)
Options.DoorESPColorPicker:OnChanged(function(v)
    for door in pairs(trackedDoors) do
        ESPLib:UpdateObjectColor(door, v)
    end
end)

local trackedGold = {}

local function TrackGold(obj)
    trackedGold[obj] = true
    AddESP(obj, "Gold", Options.GoldESPColorPicker.Value)
    obj.Destroying:Connect(function()
        RemoveESP(obj)
        trackedGold[obj] = nil
    end)
end

local function ScanGold()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj.Name == "GoldPile" and obj:IsA("Model") and not trackedGold[obj] then
            TrackGold(obj)
        end
    end
end

Toggles.GoldESPToggle:OnChanged(function(v)
    if v then
        ScanGold()
        Services.Workspace.DescendantAdded:Connect(function(obj)
            if not Toggles.GoldESPToggle.Value then return end
            if obj.Name == "GoldPile" and obj:IsA("Model") and not trackedGold[obj] then
                TrackGold(obj)
            end
        end)
    else
        for obj in pairs(trackedGold) do RemoveESP(obj) end
        trackedGold = {}
    end
end)
Options.GoldESPColorPicker:OnChanged(function(v)
    for obj in pairs(trackedGold) do
        ESPLib:UpdateObjectColor(obj, v)
    end
end)

local trackedStardust = {}

local function TrackStardust(obj)
    trackedStardust[obj] = true
    AddESP(obj, "Stardust", Options.StardustESPColorPicker.Value)
    obj.Destroying:Connect(function()
        RemoveESP(obj)
        trackedStardust[obj] = nil
    end)
end

local function ScanStardust()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj.Name == "StardustPickup" and obj:IsA("Model") and not trackedStardust[obj] then
            TrackStardust(obj)
        end
    end
end

Toggles.StardustESPToggle:OnChanged(function(v)
    if v then
        ScanStardust()
        Services.Workspace.DescendantAdded:Connect(function(obj)
            if not Toggles.StardustESPToggle.Value then return end
            if obj.Name == "StardustPickup" and obj:IsA("Model") and not trackedStardust[obj] then
                TrackStardust(obj)
            end
        end)
    else
        for obj in pairs(trackedStardust) do RemoveESP(obj) end
        trackedStardust = {}
    end
end)
Options.StardustESPColorPicker:OnChanged(function(v)
    for obj in pairs(trackedStardust) do
        ESPLib:UpdateObjectColor(obj, v)
    end
end)

local ItemNames = {
    Flashlight = true, Lighter = true, Lockpick = true, Vitamins = true,
    Bandage = true, Crucifix = true, Candle = true, Battery = true,
    Glowsticks = true, SkeletonKey = true, Shears = true, Multitool = true,
    AlarmClock = true, Scanner = true, Bomb = true, Knockbomb = true,
    BigBomb = true, SnakeBox = true, GoldGun = true, Lantern = true,
    Compass = true, HolyGrenade = true, Smoothie = true, Cheese = true,
    Bread = true, Candy = true, ShieldMini = true, ShieldBig = true,
    BandagePack = true, BatteryPack = true, StarVial = true, StarBottle = true,
    StarJug = true, Shakelight = true, Straplight = true, Bulklight = true,
    RiftCandle = true, LaserPointer = true, Nanner = true, DonutItem = true,
}

local trackedItems = {}

local function TrackItem(obj)
    trackedItems[obj] = true
    AddESP(obj, obj.Name, Options.ItemESPColorPicker.Value)
    obj.Destroying:Connect(function()
        RemoveESP(obj)
        trackedItems[obj] = nil
    end)
end

local function ScanItems()
    local drops = Services.Workspace:FindFirstChild("Drops")
    if not drops then return end
    for _, obj in ipairs(drops:GetChildren()) do
        if obj:IsA("Model") and ItemNames[obj.Name] and not trackedItems[obj] then
            TrackItem(obj)
        end
    end
end

Toggles.ItemESPToggle:OnChanged(function(v)
    if v then
        ScanItems()
        local drops = Services.Workspace:FindFirstChild("Drops")
        if drops then
            drops.ChildAdded:Connect(function(obj)
                if not Toggles.ItemESPToggle.Value then return end
                if obj:IsA("Model") and ItemNames[obj.Name] and not trackedItems[obj] then
                    TrackItem(obj)
                end
            end)
        end
    else
        for obj in pairs(trackedItems) do RemoveESP(obj) end
        trackedItems = {}
    end
end)
Options.ItemESPColorPicker:OnChanged(function(v)
    for obj in pairs(trackedItems) do
        ESPLib:UpdateObjectColor(obj, v)
    end
end)

local ChestNames = { Chest = true, Chest_Vine = true, Chest_Locked = true, ToolboxSmall = true, ToolboxLarge = true }
local trackedChests = {}

local function TrackChest(obj)
    trackedChests[obj] = true
    AddESP(obj, obj.Name, Options.ChestESPColorPicker.Value)
    obj.Destroying:Connect(function()
        RemoveESP(obj)
        trackedChests[obj] = nil
    end)
end

local function ScanChests()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and ChestNames[obj.Name] and not trackedChests[obj] then
            TrackChest(obj)
        end
    end
end

Toggles.ChestESPToggle:OnChanged(function(v)
    if v then
        ScanChests()
    else
        for obj in pairs(trackedChests) do RemoveESP(obj) end
        trackedChests = {}
    end
end)
Options.ChestESPColorPicker:OnChanged(function(v)
    for obj in pairs(trackedChests) do
        ESPLib:UpdateObjectColor(obj, v)
    end
end)

local trackedToolboxes = {}

local function TrackToolbox(obj)
    trackedToolboxes[obj] = true
    AddESP(obj, "Toolbox", Options.ToolboxESPColorPicker.Value)
    obj.Destroying:Connect(function()
        RemoveESP(obj)
        trackedToolboxes[obj] = nil
    end)
end

local function ScanToolboxes()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name == "ToolboxSmall" or obj.Name == "ToolboxLarge") and not trackedToolboxes[obj] then
            TrackToolbox(obj)
        end
    end
end

Toggles.ToolboxESPToggle:OnChanged(function(v)
    if v then
        ScanToolboxes()
    else
        for obj in pairs(trackedToolboxes) do RemoveESP(obj) end
        trackedToolboxes = {}
    end
end)
Options.ToolboxESPColorPicker:OnChanged(function(v)
    for obj in pairs(trackedToolboxes) do
        ESPLib:UpdateObjectColor(obj, v)
    end
end)

local ClosetNames = {
    Wardrobe = true, Backdoor_Wardrobe = true, RetroWardrobe = true,
    Toolshed = true, Bed = true, Double_Bed = true, Rooms_Locker = true,
    Locker_Large = true, CircularVent = true, Dumpster = true,
}

local trackedClosets = {}

local function TrackCloset(obj)
    trackedClosets[obj] = true
    AddESP(obj, obj.Name, Options.ClosetESPColorPicker.Value)
    obj.Destroying:Connect(function()
        RemoveESP(obj)
        trackedClosets[obj] = nil
    end)
end

local function ScanClosets()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and ClosetNames[obj.Name] and not trackedClosets[obj] then
            TrackCloset(obj)
        end
    end
end

Toggles.ClosetESPToggle:OnChanged(function(v)
    if v then
        ScanClosets()
    else
        for obj in pairs(trackedClosets) do RemoveESP(obj) end
        trackedClosets = {}
    end
end)
Options.ClosetESPColorPicker:OnChanged(function(v)
    for obj in pairs(trackedClosets) do
        ESPLib:UpdateObjectColor(obj, v)
    end
end)

local trackedGuiding = {}

local function TrackGuiding(obj)
    trackedGuiding[obj] = true
    AddESP(obj, "Guiding Light", Options.GuidingLightESPColorPicker.Value)
    obj.Destroying:Connect(function()
        RemoveESP(obj)
        trackedGuiding[obj] = nil
    end)
end

local function ScanGuidingLight()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if (obj.Name == "GuidingLight" or obj.Name == "GuidingLightPart") and obj:IsA("BasePart") and not trackedGuiding[obj] then
            TrackGuiding(obj)
        end
    end
end

Toggles.GuidingLightESPToggle:OnChanged(function(v)
    if v then
        ScanGuidingLight()
    else
        for obj in pairs(trackedGuiding) do RemoveESP(obj) end
        trackedGuiding = {}
    end
end)
Options.GuidingLightESPColorPicker:OnChanged(function(v)
    for obj in pairs(trackedGuiding) do
        ESPLib:UpdateObjectColor(obj, v)
    end
end)

local ObjectiveNames = {
    Generator = true, FuseBox = true, ElevatorButton = true,
    Switch = true, WaterPump = true, VineLever = true,
}

local trackedObjectives = {}

local function TrackObjective(obj)
    trackedObjectives[obj] = true
    AddESP(obj, obj.Name, Options.ObjectiveESPColorPicker.Value)
    obj.Destroying:Connect(function()
        RemoveESP(obj)
        trackedObjectives[obj] = nil
    end)
end

local function ScanObjectives()
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") and ObjectiveNames[obj.Name] and not trackedObjectives[obj] then
            TrackObjective(obj)
        end
    end
end

Toggles.ObjectiveESPToggle:OnChanged(function(v)
    if v then
        ScanObjectives()
    else
        for obj in pairs(trackedObjectives) do RemoveESP(obj) end
        trackedObjectives = {}
    end
end)
Options.ObjectiveESPColorPicker:OnChanged(function(v)
    for obj in pairs(trackedObjectives) do
        ESPLib:UpdateObjectColor(obj, v)
    end
end)

function Func.DoUnload()
    unloaded = true

    nameCallHandlers = {}

    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    if DoorConnection then DoorConnection[2]:Disconnect() DoorConnection = nil end
    if AntiAFKConnection then AntiAFKConnection:Disconnect() AntiAFKConnection = nil end
    if FlyBody and FlyBody.Parent then FlyBody.Parent = nil end
    if promptDescAddedConn then promptDescAddedConn:Disconnect() promptDescAddedConn = nil end

    tracker = {}

    for _, prompt in ipairs(promptList) do
        if prompt and prompt.Parent then
            local oldHold = prompt:GetAttribute("HoldDuration_Old")
            local oldLOS = prompt:GetAttribute("RequiresLineOfSight_Old")
            local oldDist = prompt:GetAttribute("MaxActivationDistance_Old")
            if oldHold ~= nil then prompt.HoldDuration = oldHold end
            if oldLOS ~= nil then prompt.RequiresLineOfSight = oldLOS end
            if oldDist ~= nil then prompt.MaxActivationDistance = oldDist end
            prompt:SetAttribute("HoldDuration_Old", nil)
            prompt:SetAttribute("RequiresLineOfSight_Old", nil)
            prompt:SetAttribute("MaxActivationDistance_Old", nil)
            prompt:SetAttribute("EtherealProcessed", nil)
            prompt:SetAttribute("EtherealFired", nil)
        end
    end
    promptList = {}
    
    if ESPLib and ESPLib.Unload then
        ESPLib:Unload()
    end

    task.spawn(function()
        task.wait(0.1)
        if originalNamecall then
            pcall(function()
                local mt = getrawmetatable(game)
                setreadonly(mt, false)
                mt.__namecall = originalNamecall
                setreadonly(mt, true)
            end)
        end
    end)

    Library:Unload()
end

UI.Groups.GameManagement:AddButton({
    Text = "Unload Ethereal",
    DoubleClick = true,
    Func = function()
        Func.DoUnload()
    end
})