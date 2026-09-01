local MainFolder = "Ethereal"
local ConfigFolder = MainFolder .. "/Configs"
local AssetsFolder = MainFolder .. "/Assets"
local ExecutionsFile = ConfigFolder .. "/Executions.txt"

if not isfolder(MainFolder) then
    makefolder(MainFolder)
end

if not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

if not isfolder(AssetsFolder) then
    makefolder(AssetsFolder)
end

local totalExecutions = 0
local speedBypassState = "Idle"

if isfile(ExecutionsFile) then
    totalExecutions = tonumber(readfile(ExecutionsFile)) or 0
end

totalExecutions = totalExecutions + 1
writefile(ExecutionsFile, tostring(totalExecutions))

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RemotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder") or ReplicatedStorage:FindFirstChild("EntityInfo") or ReplicatedStorage:FindFirstChild("Bricks")
local LiveModifiers = ReplicatedStorage:FindFirstChild("LiveModifiers") or Instance.new("Folder")
local Character = LocalPlayer.Character
local Humanoid = Character and Character:FindFirstChild("Humanoid")

local ItemNames = {
    ["PaperPlane"] = "Paper Plane",
    ["WaterCup"] = "Water Cup",
    ["GoldPile"] = "Gold",
    ["StardustPickup"] = "Stardust",
    ["LaserPointer"] = "Laser Pointer",
    ["Shakelight"] = "Shakelight",
    ["FihFlakes"] = "Fih Flakes",
    ["Pizza"] = "Pizza",
    ["HoneyPot"] = "Honey Pot",
    ["Bandage"] = "Bandage",
    ["GlitchCube"] = "Glitch Fragment",
}

local AutoIgnorePrompts = {
    ["ArchivesKeyboard"],
    ["ArchivesOfficeChair"],
    ["HidingSpot1"],
    ["HidingSpot2"],
    ["HidingSpot3"],
    ["HidingSpot4"],
    ["ArchivesTrashcan"],
    ["ArchivesWaitingSeats"],
    ["ArchivesLargePrinter"],
    ["ArchivesWaterCooler"],
    ["PrincipalChair"],
    ["Vendor_ShakelightVendingMachine"],
    ["ArchivesHandDryer"],
    ["ArchivesBathroomStall"],
    ["Toilet"],
    ["ArchivesTerminal"],
    ["ArchivesFihTank"],
    ["ArchivesWhiteboard_Wall"],
    ["ForgetMeNotVineDoors"],
    ["ArchivesFireExit"]
}

local Floor = "Hotel"
local CurrentRooms = game:GetService("Workspace"):FindFirstChild("CurrentRooms")

local function GetFloor()
    local GameData = ReplicatedStorage:FindFirstChild("GameData")
    if GameData and GameData:FindFirstChild("Floor") then
        local FloorValue = GameData.Floor.Value
        if FloorValue == "Archives" then
            return "OldHotel"
        end
        return FloorValue
    end
    return "Hotel"
end

local Functions = {}

local function GetCollisionPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("CollisionPart") or char:FindFirstChild("Collision")
end

Functions.IsCrouching = function()
    local floor = GetFloor()
    if floor == "Fools" or floor == "OldHotel" then
        return Character and Character:GetAttribute("Crouching") or false
    end
    local collision = GetCollisionPart()
    if collision then
        return collision.CollisionGroup == "PlayerCrouching"
    end
    return Character and Character:GetAttribute("Crouching") or false
end

Functions.GetInjuriesSpeed = function()
    if Humanoid and Humanoid.MaxHealth > 0 then
        return 0.075 * (Humanoid.MaxHealth - Humanoid.Health)
    end
    return 0
end

Functions.GetCurrentSpeed = function()
    local Speed = 15
    if Character then
        Speed = Speed + (Character:GetAttribute("SpeedBoost") or 0)
        Speed = Speed + (Character:GetAttribute("SpeedBoostBehind") or 0)
        Speed = Speed + (Character:GetAttribute("SpeedBoostExtra") or 0)
    end
    local floor = GetFloor()
    Speed = Speed + (floor == "Party" and 10 or 0)
    if LiveModifiers then
        Speed = Speed + (LiveModifiers:FindFirstChild("PlayerFast") and 3 or 0)
        Speed = Speed + (LiveModifiers:FindFirstChild("PlayerFaster") and 6 or 0)
        Speed = Speed + (LiveModifiers:FindFirstChild("PlayerFastest") and 20 or 0)
        Speed = Speed - (LiveModifiers:FindFirstChild("PlayerSlow") and 3 or 0)
        Speed = Speed - (LiveModifiers:FindFirstChild("PlayerSlowHealth") and Functions.GetInjuriesSpeed() or 0)
    end
    if Functions.IsCrouching() then
        if LiveModifiers and LiveModifiers:FindFirstChild("PlayerCrouchSlow") then
            Speed = Speed - 8
        elseif LiveModifiers and LiveModifiers:FindFirstChild("PlayerSlow") then
            Speed = Speed - 8
        else
            Speed = Speed - 5
        end
    end
    return Speed
end

local FlyBody = Instance.new("BodyVelocity")
FlyBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)
local CachedCollisionPart = nil
local LastNoclipState = false
local DoorConnection = nil
local LastDoorFire = 0
local AntiAFKConnection = nil
local JumpButton = nil
local PromptOldValues = {}
local PromptConnections = {}
local CachedPrompts = {}

local function GetFlyVelocity()
    if Humanoid and Humanoid.MoveDirection == Vector3.zero then
        return Vector3.zero
    end
    if not Camera or not Humanoid then return Vector3.zero end
    local LookFlat = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
    local FlatFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + LookFlat)
    local Velocity = (Camera.CFrame * CFrame.new(FlatFrame:VectorToObjectSpace(Humanoid.MoveDirection))).Position - Camera.CFrame.Position
    if Velocity == Vector3.zero then
        return Vector3.zero
    end
    return Velocity.Unit
end

local Environment = {}
local Log = {}
local Tested = 0
local Failed = 0
local Passed = 0

local RootEnv = getfenv(0)

local function GetGlobal(Path)
    local Value = RootEnv
    while Value ~= nil and Path ~= "" do
        local Name, NextPath = string.match(Path, "^([^.]+)%.?(.*)$")
        Value = Value[Name]
        Path = NextPath
    end
    return Value
end

local Global = setmetatable({}, {
    __index = function(Self, Name)
        return GetGlobal(Name)
    end,
})

local Services = setmetatable({}, {
    __index = function(Self, Name)
        return game:GetService(Name)
    end,
})

local Results = {}

local function AddResult(Name, Text, DidPass)
    table.insert(Results, Text)
    Log[Name] = {
        Passed = DidPass,
        Reason = Text,
    }
end

Environment.Results = Results
Environment.PrintResults = function()
    local Executor = Environment.identifyexecutor and Environment.identifyexecutor() or "Unknown"
    print("Test Result")
    for _, Result in ipairs(Results) do
        print(Result)
        task.wait()
    end
    print("Executor - " .. Executor)
    print("Tests Passed: " .. Passed .. "/" .. Tested)
    print("Test Score: " .. math.floor((Passed / Tested) * 100 + 0.5) .. "%")
end

local function RunTest(Name, Test, InternalName)
    local TimedOut = false
    Tested = Tested + 1

    local TargetGlobal = Global[Name]
    if not TargetGlobal then
        AddResult(Name, "❌ " .. Name .. " failed: function is nil", false)
        Failed = Failed + 1
        return
    end

    local Time = 0
    local Finished = false

    task.spawn(function()
        local Success, Result = pcall(Test)
        if not TimedOut then
            if Success then
                local Key = InternalName or Name
                Environment[Key] = TargetGlobal
                AddResult(Name, "✅ " .. Name, true)
                Passed = Passed + 1
            else
                AddResult(Name, "❌ " .. Name .. " failed: " .. tostring(Result), false)
                Failed = Failed + 1
            end
        end
        Finished = true
    end)

    while not Finished do
        Time = Time + 1
        if Time > 100 then
            AddResult(Name, "❌ " .. Name .. " failed: test timed out", false)
            Failed = Failed + 1
            TimedOut = true
            break
        end
        task.wait(0.1)
    end
end

RunTest("getgenv", function()
    assert(typeof(Global.getgenv()) == "table", "Did not return a table")
    Global.getgenv().Example = "Test"
    assert(Example == "Test", "Failed to set a global variable")
    Global.getgenv().Example = nil
end)

RunTest("getrenv", function()
    assert(Environment.getgenv, "getgenv is required to test")
    local Env = Global.getrenv()
    assert(typeof(Env) == "table", "Did not return a table")
    assert(typeof(Env.print) == "function", "Did not return an environment table")
    assert(Global.getrenv ~= Global.getgenv, "getrenv is an alias of getgenv")
    assert(Global.getgenv() ~= Global.getrenv(), "Returned executor environment")
    local Success = pcall(function()
        return Env.loadstring([[return 10]])()
    end)
    assert(Success == false, "Should error when calling loadstring from roblox environment")
end)

RunTest("getgc", function()
    local TestFunction = function()
        return 10
    end
    local TestTable = { Value = 10 }
    local YesTables = Global.getgc(true)
    local NoTables = Global.getgc(false)
    assert(table.find(YesTables, TestTable), "Failed to find a table")
    assert(table.find(YesTables, TestFunction), "Failed to find a function")
    assert(not table.find(NoTables, TestTable), "Should not return a table when called with false")
    assert(table.find(NoTables, TestFunction), "Failed to find a function")
end)

RunTest("identifyexecutor", function()
    assert(typeof(Global.identifyexecutor()) == "string", "Did not return a string")
end)

RunTest("request", function()
    local Response = Global.request({
        Url = "https://example.com/test",
        Method = "GET",
    })
    assert(Response.StatusCode == 200, "Status code should be 200")
    assert(typeof(Response.Body) == "string", "Body should be a string")
end)

RunTest("cloneref", function()
    local TestPart = Instance.new("Part")
    local Clone = Global.cloneref(TestPart)
    assert(typeof(Clone) == "Instance", "Should return an Instance")
    assert(TestPart ~= Clone, "Clone should not be equal to original")
    TestPart.Name = "Test"
    assert(Clone.Name == "Test", "Changing the original did not change the clone")
    TestPart:Destroy()
end)

RunTest("gethui", function()
    local Hui = Global.gethui()
    assert(typeof(Hui) == "Instance", "Should return an instance")
    local ValidClasses = { "ScreenGui", "Folder", "BasePlayerGui", "CoreGui" }
    if not Hui:IsDescendantOf(Services.CoreGui) and Hui.ClassName ~= "CoreGui" or not table.find(ValidClasses, Hui.ClassName) then
        error("Did not return a valid gui container")
    end
end)

RunTest("getcallbackvalue", function()
    local TestBindable = Instance.new("BindableFunction")
    TestBindable.OnInvoke = function(Value)
        return Value * 10
    end
    local Callback = Global.getcallbackvalue(TestBindable, "OnInvoke")
    local Success, Result = pcall(function()
        assert(typeof(Callback) == "function", "Did not return a function")
        assert(Callback(5) == 50, "Did not return the callback value")
    end)
    TestBindable:Destroy()
    assert(Success, Result)
end)

RunTest("getinstances", function()
    local TestPart1 = Instance.new("Part")
    local TestPart2 = Instance.new("Part", Services.Workspace)
    local InstanceList = Global.getinstances()
    local Found1 = table.find(InstanceList, TestPart1)
    local Found2 = table.find(InstanceList, TestPart2)
    TestPart1:Destroy()
    TestPart2:Destroy()
    assert(Found2, "Did not return an instance")
    assert(Found1, "Did not return an instance parented to nil")
end)

RunTest("getnilinstances", function()
    local TestPart1 = Instance.new("Part")
    local TestPart2 = Instance.new("Part", Services.Workspace)
    local InstanceList = Global.getnilinstances()
    local FoundNil = table.find(InstanceList, TestPart1)
    local FoundParented = table.find(InstanceList, TestPart2)
    TestPart1:Destroy()
    TestPart2:Destroy()
    assert(not FoundParented, "Returned an instance not parented to nil")
    assert(FoundNil, "Did not return an instance parented to nil")
end)

RunTest("fireproximityprompt", function()
    local TestPart = Instance.new("Part", Services.Workspace)
    local TestPrompt = Instance.new("ProximityPrompt", TestPart)
    local Fired = false
    local Connection = TestPrompt.Triggered:Connect(function()
        Fired = true
    end)
    Global.fireproximityprompt(TestPrompt)
    local Tries = 0
    while not Fired and Tries < 10 do
        Tries = Tries + 1
        task.wait(0.1)
    end
    Connection:Disconnect()
    TestPart:Destroy()
    assert(Fired == true, "Failed to fire a proximity prompt")
end)

RunTest("fireclickdetector", function()
    local TestPart = Instance.new("Part", Services.Workspace)
    local TestClick = Instance.new("ClickDetector", TestPart)
    local Fired = false
    local Connection = TestClick.MouseClick:Connect(function()
        Fired = true
    end)
    Global.fireclickdetector(TestClick)
    local Tries = 0
    while not Fired and Tries < 10 do
        Tries = Tries + 1
        task.wait(0.1)
    end
    Connection:Disconnect()
    TestPart:Destroy()
    assert(Fired == true, "Failed to fire a click detector")
end)

RunTest("firetouchinterest", function()
    local TestPart1 = Instance.new("Part", Services.Workspace)
    TestPart1.Position = Vector3.new(0, 1000, 0)
    local TestPart2 = Instance.new("Part", Services.Workspace)
    TestPart2.Position = Vector3.new(0, 1000, 0)
    local Fired = false
    local Connection = TestPart1.Touched:Connect(function(Child)
        if Child == TestPart2 then
            Fired = true
        end
    end)
    Global.firetouchinterest(TestPart1, TestPart2, 0)
    task.wait()
    Global.firetouchinterest(TestPart1, TestPart2, 1)
    local Tries = 0
    while not Fired and Tries < 10 do
        Tries = Tries + 1
        task.wait(0.1)
    end
    Connection:Disconnect()
    TestPart1:Destroy()
    TestPart2:Destroy()
    assert(Fired == true, "Failed to fire a touch interest")
end)

RunTest("clonefunction", function()
    local TestFunction = function()
        return 10
    end
    local TestClone = Global.clonefunction(TestFunction)
    assert(TestFunction ~= TestClone, "Returned the original function")
    assert(TestFunction() == TestClone(), "Clone did not return the same as the original")
end)

RunTest("newcclosure", function()
    local TestFunction = function()
        return 10
    end
    local TestC = Global.newcclosure(TestFunction)
    assert(TestFunction ~= TestC, "Returned the original function")
    assert(TestFunction() == TestC(), "Did not return the same value as the original")
    assert(TestC() == 10, "Did not return the correct value")
    assert(debug.info(TestC, "s") == "[C]", "Did not return a C function")
end)

RunTest("hookfunction", function()
    local TestFunction = function()
        return 10
    end
    local TestC = Global.newcclosure(function()
        return 25
    end)
    local TestHook = function()
        return 100
    end
    local Old = Global.hookfunction(TestFunction, TestHook)
    local OldC = Global.hookfunction(TestC, TestHook)
    assert(TestFunction ~= TestHook, "Original and hook are the same function")
    assert(debug.info(TestC, "s") == "[C]", "Hooked C function is no longer in C")
    assert(TestFunction() == 100, "Did not change the return value")
    assert(Old() == 10, "Did not return the original function")
    assert(OldC() == 25, "Did not return the original C function")
end)

RunTest("restorefunction", function()
    assert(Environment.hookfunction, "hookfunction is required to test")
    local TestFunction = function()
        return 10
    end
    local TestHook = function()
        return 100
    end
    Global.hookfunction(TestFunction, TestHook)
    Global.restorefunction(TestFunction)
    assert(TestFunction() == 10, "Failed to unhook a function")
end)

RunTest("isfunctionhooked", function()
    assert(Environment.hookfunction, "hookfunction is required to test")
    assert(Environment.restorefunction, "restorefunction is required to test")
    local TestFunction = function()
        return 10
    end
    local TestHook = function()
        return 100
    end
    Global.hookfunction(TestFunction, TestHook)
    assert(Global.isfunctionhooked(TestFunction) == true, "Did not return true for a hooked function")
    Global.restorefunction(TestFunction)
    assert(Global.isfunctionhooked(TestFunction) == false, "Did not return false for an unhooked function")
end)

RunTest("isexecutorclosure", function()
    assert(Environment.newcclosure, "newcclosure is required to test")
    local TestFunction = function()
        return 10
    end
    local TestC = Global.newcclosure(TestFunction)
    assert(Global.isexecutorclosure(TestFunction) == true, "Did not return true for an executor function")
    assert(Global.isexecutorclosure(Global.newcclosure) == true, "Did not return true for an executor global")
    assert(Global.isexecutorclosure(warn) == false, "Did not return false for a Roblox global")
    assert(Global.isexecutorclosure(TestC) == true, "Did not return true for an executor C function")
end)

RunTest("getnamecallmethod", function()
    pcall(function()
        game:ExampleNamecall()
    end)
    assert(typeof(Global.getnamecallmethod()) == "string", "Did not return a string")
    assert(Global.getnamecallmethod() == "ExampleNamecall", "Did not return the correct method")
end)

RunTest("hookmetamethod", function()
    assert(Environment.getnamecallmethod, "getnamecallmethod is required to test")
    assert(Environment.newcclosure, "newcclosure is required to test")
    local TestTable = setmetatable({}, {
        __index = Global.newcclosure(function()
            return "normal"
        end),
    })
    Global.hookmetamethod(TestTable, "__index", Global.newcclosure(function()
        return "hooked"
    end))
    assert(TestTable.Example == "hooked", "Failed to hook a metamethod")
end)

RunTest("getrawmetatable", function()
    local TestTable = { __metatable = "Locked!" }
    local TestObject = setmetatable({}, TestTable)
    assert(Global.getrawmetatable(TestObject) == TestTable, "Did not return the metatable")
end)

RunTest("setrawmetatable", function()
    assert(Environment.getrawmetatable, "getrawmetatable is required to test")
    local TestTable = { __metatable = "Locked!" }
    local TestObject = setmetatable({}, TestTable)
    Global.setrawmetatable(TestObject, {
        __index = function()
            return "Edited!"
        end,
    })
    assert(TestObject.Example == "Edited!", "Failed to set the metatable")
end)

RunTest("isreadonly", function()
    local TestTable = {}
    local FrozenTable = table.freeze({})
    assert(Global.isreadonly(TestTable) == false, "Did not return false for a writeable table")
    assert(Global.isreadonly(FrozenTable) == true, "Did not return true for a readonly table")
end)

RunTest("setreadonly", function()
    assert(Environment.isreadonly, "isreadonly is required to test")
    local TestTable = { Value = 10 }
    table.freeze(TestTable)
    Global.setreadonly(TestTable, false)
    TestTable.Value = 100
    assert(Global.isreadonly(TestTable) == false, "Failed to set readonly")
end)

RunTest("writefile", function()
    Global.writefile("_Ethereal_test_file_", "example")
    assert(Global.isfile("_Ethereal_test_file_") == true, "Failed to create a file")
    assert(Global.readfile("_Ethereal_test_file_") == "example", "File does not contain expected data")
end)

RunTest("isfile", function()
    assert(Global.isfile("_Ethereal_test_file_") == true, "Did not return true for a valid file")
end)

RunTest("readfile", function()
    assert(Global.readfile("_Ethereal_test_file_") == "example", "Did not return the expected data")
end)

RunTest("appendfile", function()
    Global.appendfile("_Ethereal_test_file_", "_appended")
    assert(Global.readfile("_Ethereal_test_file_") == "example_appended", "Failed to append content to a file")
end)

RunTest("loadfile", function()
    Global.writefile("_Ethereal_test_file_", [[return 25]])
    assert(Global.loadfile("_Ethereal_test_file_")() == 25, "Failed to load and execute a file")
end)

RunTest("delfile", function()
    Global.delfile("_Ethereal_test_file_")
    Global.delfile("_Ethereal_test_file_")
    assert(Global.isfile("_Ethereal_test_file_") == false, "Failed to delete a file")
end)

RunTest("makefolder", function()
    Global.makefolder("_Ethereal_test_folder_")
    assert(Global.isfolder("_Ethereal_test_folder_") == true, "Failed to create a folder")
end)

RunTest("delfolder", function()
    Global.delfolder("_Ethereal_test_folder_")
    assert(Global.isfolder("_Ethereal_test_folder_") == false, "Failed to delete a folder")
end)

RunTest("listfiles", function()
    Global.makefolder("_Ethereal_listfiles_test_")
    Global.writefile("_Ethereal_listfiles_test_/test1", "test 1")
    Global.writefile("_Ethereal_listfiles_test_/test2", "test 2")
    local FilesList = Global.listfiles("_Ethereal_listfiles_test_")
    local Found1 = false
    local Found2 = false
    assert(#FilesList == 2, "Did not return the correct number of files")
    for _, File in ipairs(FilesList) do
        local Content = Global.readfile(File)
        if Content == "test 1" then
            Found1 = true
        elseif Content == "test 2" then
            Found2 = true
        end
    end
    Global.delfolder("_Ethereal_listfiles_test_")
    assert(Found1 == true, "Did not return the first file")
    assert(Found2 == true, "Did not return the second file")
end)

RunTest("gethiddenproperty", function()
    local TestPart = Instance.new("Part")
    local Value = Global.gethiddenproperty(TestPart, "NetworkIsSleeping")
    TestPart:Destroy()
    assert(Value == false, "Did not return the correct property value")
end)

RunTest("sethiddenproperty", function()
    assert(Environment.gethiddenproperty, "gethiddenproperty is required to test")
    local TestPart = Instance.new("Part")
    Global.sethiddenproperty(TestPart, "NetworkIsSleeping", true)
    local Value = Global.gethiddenproperty(TestPart, "NetworkIsSleeping")
    TestPart:Destroy()
    assert(Value == true, "Failed to set a hidden property")
end)

RunTest("getthreadidentity", function()
    local Identity = Global.getthreadidentity()
    assert(typeof(Identity) == "number", "Did not return a number")
    assert(Identity > 0, "Returned an invalid identity")
    assert(Identity < 9, "Returned an invalid identity")
end)

RunTest("setthreadidentity", function()
    assert(Environment.getthreadidentity, "getthreadidentity is needed to test")
    local Old = Global.getthreadidentity()
    Global.setthreadidentity(2)
    assert(Services.CoreGui == nil, "Capabilities do not match set identity")
    Global.setthreadidentity(Old)
end)

RunTest("firesignal", function()
    local TestEvent = Instance.new("RemoteEvent")
    local Fired = false
    local Value1, Value2, Value3
    local Connection = TestEvent.OnClientEvent:Connect(function(Arg1, Arg2, Arg3)
        Fired = true
        Value1 = Arg1
        Value2 = Arg2
        Value3 = Arg3
    end)
    Global.firesignal(TestEvent.OnClientEvent, "Example", 10, true)
    local Tries = 0
    while not Fired and Tries < 10 do
        Tries = Tries + 1
        task.wait(0.1)
    end
    Connection:Disconnect()
    TestEvent:Destroy()
    assert(Fired == true, "Failed to fire a signal")
    assert(Value1 == "Example", "Fired signal with incorrect data")
    assert(Value2 == 10, "Fired signal with incorrect data")
    assert(Value3 == true, "Fired signal with incorrect data")
end)

RunTest("replicatesignal", function()
    local TestButton = Instance.new("Frame")
    Global.replicatesignal(TestButton.MouseWheelForward, 69, 420)
    local Success = pcall(function()
        Global.replicatesignal(TestButton.MouseWheelForward)
        Global.replicatesignal(TestButton.MouseWheelForward, 69)
    end)
    TestButton:Destroy()
    assert(Success == false, "Did not throw an error with invalid arguments")
end)

RunTest("getconnections", function()
    local Fired = false
    local Connection = game.ChildAdded:Connect(function(Child)
        if Child == "Example" then
            Fired = true
        end
    end)
    for _, Conn in ipairs(getconnections(game.ChildAdded)) do
        Conn:Fire("Example")
    end
    local Tries = 0
    while not Fired and Tries < 10 do
        Tries = Tries + 1
        task.wait(0.1)
    end
    Connection:Disconnect()
    assert(Fired == true, "Failed to fire a connection's signals")
end)

local ExecutorName = identifyexecutor() or "Unknown"
local ResultsText = "Executor: " .. ExecutorName .. "\n"

local Window = Library:CreateWindow({
    Title = "Ethereal.cc",
    Footer = "Ethereal.cc v1.0.0 | [BETA] | [ARCHIVES] Doors",
    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true
    },
    Icon = 121042488065207,
    IconSize = UDim2.fromOffset(50, 50),
    NotifySide = "Right",
})

local Tabs = {
    Home = Window:AddTab("Home", "door-open", "Home page for Ethereal.cc"),
    Main = Window:AddTab("Main", "house", "Main Features"),
    Exploits = Window:AddTab("Exploits", "bug", "Game Exploits"),
    Visuals = Window:AddTab("Visuals", "eye", "Visual Tweaks & ESP"),
    Floor = Window:AddTab("Floor", "sparkles", "Main floor Features"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings", "Menu and Ethereal.cc Settings"),
}

Tabs.Home:UpdateWarningBox({
    Title = "<b>Latest Changelog</b>",
    Text = '[<font color="rgb(73, 230, 133)">Ethereal.cc</font>]\n<font color="rgb(90, 224, 215)">[!] Script are now in BETA</font>\n\n[<font color="rgb(150, 95, 0)">Doors</font>]\n<font color="rgb(155, 224, 90)">[+] Added real nothing</font>\n<font color="rgb(155, 224, 90)">[+] Added support for Archives</font>',
    IsNormal = true,
    Visible = true,
    LockSize = true,
})

local AccountGroup = Tabs.Home:AddLeftGroupbox("Account", "user")
local MainTabs = Tabs.Home:AddRightTabbox()
local GamesTab = MainTabs:AddTab("", "text-align-start")
local KeyTab = MainTabs:AddTab("", "key")
local TestTab = MainTabs:AddTab("", "info")
local PlayerTabs = Tabs.Main:AddLeftTabbox()
local CharacterTab = PlayerTabs:AddTab("Character", "sliders-horizontal")
local PlayerTab = PlayerTabs:AddTab("Player", "user-pen")
local PromptsGroup = Tabs.Main:AddLeftGroupbox("Prompts", "mouse-pointer-2")

AccountGroup:AddImage("PlayerImage", {
    Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420),
    Height = 200,
})
AccountGroup:AddLabel("Good afternoon, <b>Player</b>! Welcome to Ethereal.cc.", true)
AccountGroup:AddDivider()
AccountGroup:AddButton({
    Text = "Nothing...",
    DoubleClick = true,
    Func = function()
        Library:Notify({
            Title = "Ethereal.cc",
            Description = "It's really do nothing...",
            SoundId = 140207837688369,
        })
    end
})
GamesTab:AddLabel("🟢 <font color='rgb(73, 230, 133)'>Doors</font>\n⚪ <font color='rgb(214, 214, 214)'>Nothing</font>", true)
GamesTab:AddDivider()
GamesTab:AddLabel("You cannot right now report bugs or suggest features", true)
GamesTab:AddButton({
    Text = "Idi nahui",
    Func = function()
        Library:Notify({
            Title = "Ethereal.cc",
            Description = "Ya skazal idi nahui",
            SoundId = 107965930411767,
        })
    end
})
KeyTab:AddLabel("This script are keyless right now! I don't want to make a key. :D", true)
KeyTab:AddDivider()
KeyTab:AddLabel("Key time: ∞ days")
local ExecutionsLabel = KeyTab:AddLabel("Total executions: " .. totalExecutions)
local ResultsLabel = TestTab:AddLabel("", true)
local SpeedBypass = CharacterTab:AddLabel("Speed Bypass: <font color=\"rgb(214, 214, 214)\">Idle</font>")
local SpeedHackToggle = CharacterTab:AddToggle("SpeedHackToggle", {
    Text = "Enable Speed Hack",
})
local CrouchDelaySlider = CharacterTab:AddSlider("CrouchDelaySlider", {
    Text = "Bypass Delay",
    Default = 0.05,
    Min = 0,
    Max = 0.1,
    Rounding = 2,
    Compact = true
})
local WalkingSpeedSlider = CharacterTab:AddSlider("WalkingSpeedSlider", {
    Text = "Walking Speed",
    Default = 16,
    Min = 0,
    Max = 75,
})
CharacterTab:AddDivider()
local EnableJumpToggle = CharacterTab:AddToggle("EnableJumpToggle", {
    Text = "Enable Jump",
})
local InfiniteJumpsToggle = CharacterTab:AddToggle("InfiniteJumpsToggle", {
    Text = "Infinite Jumps",
})
CharacterTab:AddDivider()
local EnableSlidingToggle = CharacterTab:AddToggle("EnableSlidingToggle", {
    Text = "Enable Sliding",
})
local NoAccelerationToggle = CharacterTab:AddToggle("NoAccelerationToggle", {
    Text = "No Acceleration",
})
CharacterTab:AddDivider()
local NoclipToggle = CharacterTab:AddToggle("NoclipToggle", {
    Text = "Noclip",
})
local FlyToggle = CharacterTab:AddToggle("FlyToggle", {
    Text = "Fly",
})
local FlySpeedSlider = CharacterTab:AddSlider("FlySpeedSlider", {
    Text = "Fly Speed",
    Default = 15,
    Min = 0,
    Max = 75,
    Rounding = 1,
})
local DoorReachToggle = PlayerTab:AddToggle("DoorReachToggle", {
    Text = "Door Reach",
})
local FastClosetExitToggle = PlayerTab:AddToggle("FastClosetExitToggle", {
    Text = "Fast Closet Exit",
})
local AntiAFKToggle = PlayerTab:AddToggle("AntiAFKToggle", {
    Text = "Anti AFK",
})
local AutoInteractToggle = PromptsGroup:AddToggle("AutoInteractToggle", {
    Text = "Auto Interact",
})
local IgnoreInteractListDropdown = PromptsGroup:AddDropdown("IgnoreInteractListDropdown", {
    Text = "Ignore List",
    Values = { "Gold", "Bandage", "Stardust", "Glitch Fragment", "Paper Plane", "Fih Flakes", "Pizza", "Honey Pot", "Shakelight", "Laser Pointer" },
    Default = { "Glitch Fragment" },
    Multi = true,
})
local InstantInteractToggle = PromptsGroup:AddToggle("InstantInteractToggle", {
    Text = "Instant Interact",
})
local PromptClipToggle = PromptsGroup:AddToggle("PromptClipToggle", {
    Text = "Prompt Clip",
})
local PromptReachSlider = PromptsGroup:AddSlider("PromptReachSlider", {
    Text = "Prompt Reach",
    Default = 1,
    Min = 1,
    Max = 2,
    Rounding = 1,
    Compact = true
})

task.spawn(function()
    local passed = 0
    local total = #Environment.Results
    local NewText = "Executor: " .. ExecutorName .. "\n\n"
    
    for _, Result in ipairs(Environment.Results) do
        NewText = NewText .. Result .. "\n"
        if string.find(Result, "✅") then
            passed = passed + 1
        end
    end
    
    NewText = NewText .. "\n🛠️ Total working: " .. passed .. "/" .. total
    ResultsLabel:SetText(NewText)
end)

local lastCrouchFire = tick()
local OldJump = false
local OldSlide = false
local lastAnimCheck = tick()
local isSliding = false

Toggles.SpeedHackToggle:OnChanged(function(Value)
    if Humanoid then
        Humanoid.WalkSpeed = Value and Options.WalkingSpeedSlider.Value or Functions.GetCurrentSpeed()
    end
    if Value and Options.WalkingSpeedSlider.Value > 19 then
        SpeedBypass:SetText("Speed Bypass: <font color=\"rgb(73, 230, 133)\">Active</font>")
    else
        SpeedBypass:SetText("Speed Bypass: <font color=\"rgb(214, 214, 214)\">Idle</font>")
    end
end)
Options.WalkingSpeedSlider:OnChanged(function(Value)
    if RemotesFolder and RemotesFolder:FindFirstChild("Crouch") then
        RemotesFolder.Crouch:FireServer(Functions.IsCrouching(), true)
    end
    if Toggles.SpeedHackToggle.Value and Value > 19 then
        SpeedBypass:SetText("Speed Bypass: <font color=\"rgb(73, 230, 133)\">Active</font>")
    else
        SpeedBypass:SetText("Speed Bypass: <font color=\"rgb(214, 214, 214)\">Idle</font>")
    end
end)
Toggles.EnableJumpToggle:OnChanged(function(Value)
    if Character then
        Character:SetAttribute("CanJump", Value and true or OldJump)
    end
end)
Toggles.EnableSlidingToggle:OnChanged(function(Value)
    if Character then
        Character:SetAttribute("CanSlide", Value and true or OldSlide)
    end
end)

local PartProperties = {}
local CustomPhysics = nil

local RootPart = Character:WaitForChild("HumanoidRootPart")
CustomPhysics = PhysicalProperties.new(
    100,
    RootPart.CustomPhysicalProperties.Friction,
    RootPart.CustomPhysicalProperties.Elasticity,
    RootPart.CustomPhysicalProperties.FrictionWeight,
    RootPart.CustomPhysicalProperties.ElasticityWeight
)
for _, Part in Character:GetDescendants() do
    if Part:IsA("BasePart") then
        PartProperties[Part] = Part.CustomPhysicalProperties
    end
end

Toggles.NoAccelerationToggle:OnChanged(function(Value)
    for Part, Old in PartProperties do
        Part.CustomPhysicalProperties = Value and CustomPhysics or Old
    end
end)

DoorReachToggle:OnChanged(function(Value)
    if not Value then
        LastDoorFire = 0
    end
end)

AntiAFKToggle:OnChanged(function(Value)
    if Value then
        if not AntiAFKConnection then
            AntiAFKConnection = LocalPlayer.Idled:Connect(function()
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

local function FindJumpButton()
    if JumpButton and JumpButton.Parent then return end
    local main = LocalPlayer.PlayerGui:FindFirstChild("MainUI")
    if main and main:FindFirstChild("MainFrame") and main.MainFrame:FindFirstChild("MobileButtons") then
        JumpButton = main.MainFrame.MobileButtons:FindFirstChild("JumpButton")
        if JumpButton then
            JumpButton.MouseButton1Down:Connect(function()
                if Toggles.InfiniteJumpsToggle.Value then
                    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end
end

FindJumpButton()
LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "MainUI" then
        FindJumpButton()
    end
end)

OldJump = Character:GetAttribute("CanJump")
OldSlide = Character:GetAttribute("CanSlide")

Character:GetAttributeChangedSignal("CanJump"):Connect(function()
    local Val = Character:GetAttribute("CanJump")
    if Toggles.EnableJumpToggle.Value and Val ~= true or not Toggles.EnableJumpToggle.Value then
        OldJump = Val
    end
    if Toggles.EnableJumpToggle.Value then Character:SetAttribute("CanJump", true) end
end)
Character:GetAttributeChangedSignal("CanSlide"):Connect(function()
    local Val = Character:GetAttribute("CanSlide")
    if Toggles.EnableSlidingToggle.Value and Val ~= true or not Toggles.EnableSlidingToggle.Value then
        OldSlide = Val
    end
    if Toggles.EnableSlidingToggle.Value then Character:SetAttribute("CanSlide", true) end
end)

InstantInteractToggle:OnChanged(function(Value)
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if Value then
                if not PromptOldValues[prompt] then
                    PromptOldValues[prompt] = {HoldDuration = prompt.HoldDuration}
                end
                prompt.HoldDuration = 0
            else
                if PromptOldValues[prompt] then
                    prompt.HoldDuration = PromptOldValues[prompt].HoldDuration
                    PromptOldValues[prompt] = nil
                end
            end
        end
    end
end)

PromptClipToggle:OnChanged(function(Value)
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if Value then
                if not PromptOldValues[prompt] then
                    PromptOldValues[prompt] = {RequiresLineOfSight = prompt.RequiresLineOfSight}
                end
                prompt.RequiresLineOfSight = false
            else
                if PromptOldValues[prompt] then
                    prompt.RequiresLineOfSight = PromptOldValues[prompt].RequiresLineOfSight
                end
            end
        end
    end
end)

PromptReachSlider:OnChanged(function(Value)
    for _, prompt in ipairs(CachedPrompts) do
        if prompt and prompt.Parent and PromptOldValues[prompt] then
            prompt.MaxActivationDistance = PromptOldValues[prompt].MaxActivationDistance * Value
        end
    end
end)

workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("ProximityPrompt") then
        if not PromptOldValues[desc] then
            PromptOldValues[desc] = {
                MaxActivationDistance = desc.MaxActivationDistance,
                HoldDuration = desc.HoldDuration,
                RequiresLineOfSight = desc.RequiresLineOfSight
            }
            table.insert(CachedPrompts, desc)
        end
        if InstantInteractToggle.Value then
            desc.HoldDuration = 0
        end
        if PromptClipToggle.Value then
            desc.RequiresLineOfSight = false
        end
        if PromptReachSlider.Value ~= 1 then
            desc.MaxActivationDistance = desc.MaxActivationDistance * PromptReachSlider.Value
        end
    end
end)

local function UpdatePromptCache()
    CachedPrompts = {}
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            table.insert(CachedPrompts, prompt)
            if not PromptOldValues[prompt] then
                PromptOldValues[prompt] = {
                    MaxActivationDistance = prompt.MaxActivationDistance,
                    HoldDuration = prompt.HoldDuration,
                    RequiresLineOfSight = prompt.RequiresLineOfSight
                }
            end
        end
    end
end
UpdatePromptCache()

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
    
    if not Character or not Character.Parent then
        Character = LocalPlayer.Character
        if Character then
            RootPart = Character:FindFirstChild("HumanoidRootPart")
            Humanoid = Character:FindFirstChild("Humanoid")
            CachedCollisionPart = nil
            LastNoclipState = false
        end
    end
    
    if not RootPart or not RootPart.Parent then
        if Character then
            RootPart = Character:FindFirstChild("HumanoidRootPart")
        end
    end
    
    if not Humanoid or not Humanoid.Parent then
        if Character then
            Humanoid = Character:FindFirstChild("Humanoid")
        end
    end
    
    if Character and Humanoid then
        if Toggles.EnableSlidingToggle.Value and tick() - lastAnimCheck > 0.1 then
            isSliding = false
            for _, Anim in Humanoid:GetPlayingAnimationTracks() do
                if Anim.Name == "Slide" then isSliding = true break end
            end
            lastAnimCheck = tick()
        end
        if Toggles.EnableSlidingToggle.Value then
            Character:SetAttribute("Sliding", isSliding)
        end
        
        CachedCollisionPart = CachedCollisionPart or GetCollisionPart()
        local collisionPart = CachedCollisionPart
        local actualCrouch
        if collisionPart then
            actualCrouch = collisionPart.CollisionGroup == "PlayerCrouching"
        else
            actualCrouch = Character:GetAttribute("Crouching") or false
        end
        if Character:GetAttribute("Crouching") ~= actualCrouch then
            Character:SetAttribute("Crouching", actualCrouch)
        end
    end

    if Toggles.SpeedHackToggle.Value and Humanoid then
        Humanoid.WalkSpeed = Options.WalkingSpeedSlider.Value
    end

    local shouldSendCrouch = Toggles.SpeedHackToggle.Value or Toggles.FlyToggle.Value
    if RemotesFolder and RemotesFolder:FindFirstChild("Crouch") and shouldSendCrouch and tick() - lastCrouchFire > Options.CrouchDelaySlider.Value then
        local isCrouch = Functions.IsCrouching()
        RemotesFolder.Crouch:FireServer(isCrouch, true)
        lastCrouchFire = tick()
    end

    if Toggles.NoclipToggle.Value ~= LastNoclipState then
        LastNoclipState = Toggles.NoclipToggle.Value
        for _, Part in Character:GetChildren() do
            if Part:IsA("BasePart") then
                Part.CanCollide = not LastNoclipState
            end
        end
    end

    if Toggles.FlyToggle.Value and RootPart and Humanoid and Camera then
        FlyBody.Parent = RootPart
        FlyBody.Velocity = GetFlyVelocity() * Options.FlySpeedSlider.Value
    else
        FlyBody.Parent = nil
    end

    if DoorReachToggle.Value then
        local roomNum = LocalPlayer:GetAttribute("CurrentRoom")
        if roomNum then
            local room = CurrentRooms:FindFirstChild(tostring(roomNum))
            if room then
                local door = room:FindFirstChild("Door")
                if door and door:FindFirstChild("ClientOpen") then
                    if DoorConnection and DoorConnection[1] ~= door then
                        DoorConnection[2]:Disconnect()
                        DoorConnection = nil
                    end
                    if not DoorConnection then
                        local conn
                        conn = RunService.Heartbeat:Connect(function()
                            if not DoorReachToggle.Value then
                                conn:Disconnect()
                                DoorConnection = nil
                                return
                            end
                            local doorPart = door:FindFirstChild("Door")
                            if doorPart and doorPart:IsA("BasePart") and RootPart then
                                local dist = (RootPart.Position - doorPart.Position).Magnitude
                                if dist < 75 and tick() - LastDoorFire > 0.15 then
                                    door.ClientOpen:FireServer()
                                    LastDoorFire = tick()
                                end
                            end
                        end)
                        DoorConnection = {door, conn}
                    end
                else
                    if DoorConnection then
                        DoorConnection[2]:Disconnect()
                        DoorConnection = nil
                    end
                end
            else
                if DoorConnection then
                    DoorConnection[2]:Disconnect()
                    DoorConnection = nil
                end
            end
        end
    else
        if DoorConnection then
            DoorConnection[2]:Disconnect()
            DoorConnection = nil
        end
    end

    if FastClosetExitToggle.Value and Character and Humanoid and Humanoid.MoveDirection ~= Vector3.zero then
        if Character:GetAttribute("Hiding") == true then
            if RemotesFolder and RemotesFolder:FindFirstChild("CamLock") then
                RemotesFolder.CamLock:FireServer()
            end
        end
    end
    
    if AutoInteractToggle.Value and Character and RootPart then
        local ignoreList = IgnoreInteractListDropdown.Value
        local nearestPrompt = nil
        local nearestDist = math.huge
    
        for _, prompt in ipairs(CachedPrompts) do
            if prompt and prompt.Parent and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local parent = prompt.Parent
                if parent then
                    local shouldIgnore = false
                
                    for _, ignoreName in ipairs(AutoIgnorePrompts) do
                        if parent.Name == ignoreName then
                            shouldIgnore = true
                            break
                        end
                    end
                    if shouldIgnore then continue end
                
                    for _, ignore in ipairs(ignoreList) do
                        if parent.Name == ignore then
                            shouldIgnore = true
                            break
                        end
                    end
                    if shouldIgnore then continue end
                
                    local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (RootPart.Position - part.Position).Magnitude
                        if dist < prompt.MaxActivationDistance and dist < nearestDist then
                            nearestDist = dist
                            nearestPrompt = prompt
                        end
                    end
                end
            end
        end
    
        if nearestPrompt then
            nearestPrompt:InputHoldBegin()
            nearestPrompt:InputHoldEnd()
        end
    end
end)