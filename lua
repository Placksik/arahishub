local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "Fling things and people", 
    HidePremium = false,
    KeyToOpenWindow = 'Delete',
    IntroEnabled = false,
	FreeMouse = true,
    SaveConfig = true, 
    ConfigFolder = "OrionTest"
})

--[[
Name = <string> - The name of the UI.
HidePremium = <bool> - Whether or not the user details shows Premium status or not.
SaveConfig = <bool> - Toggles the config saving in the UI.
ConfigFolder = <string> - The name of the folder where the configs are saved.
IntroEnabled = <bool> - Whether or not to show the intro animation.
IntroText = <string> - Text to show in the intro animation.
IntroIcon = <string> - URL to the image you want to use in the intro animation.
Icon = <string> - URL to the image you want displayed on the window.
CloseCallback = <function> - Function to execute when the window is closed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents")
local MenuToys = ReplicatedStorage:WaitForChild("MenuToys")
local CharacterEvents = ReplicatedStorage:WaitForChild("CharacterEvents")
local SetNetworkOwner = GrabEvents:WaitForChild("SetNetworkOwner")
local Struggle = CharacterEvents:WaitForChild("Struggle")
local DestroyToy = MenuToys:WaitForChild("DestroyToy")

local localPlayer = Players.LocalPlayer
local playerCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
localPlayer.CharacterAdded:Connect(function(character)
    playerCharacter = character
end)

local AutoRecoverDroppedPartsCoroutine
local connectionBombReload
local reloadBombCoroutine
local antiExplosionConnection
local characterAddedConn
local strengthConnection
local autoStruggleCoroutine
local autoDefendCoroutine
local fireAllCoroutine
local ragdollAllCoroutine
local crouchJumpCoroutine
local crouchSpeedCoroutine
local anchorGrabCoroutine
local anchorKickCoroutine
local poisonGrabCoroutine
local ufoGrabCoroutine
local fireGrabCoroutine
local noclipGrabCoroutine
local antiKickCoroutine
local blobmanCoroutine

local anchoredParts = {}
local anchoredConnections = {}
local compiledGroups = {}
local compileConnections = {}
local renderSteppedConnections = {}
local connections = {}
local kickGrabConnections = {}
local bombList = {}
local ownedToys = {}

local burnPart
local blobman
local skolko = "" 
local decoyOffset = 15
local stopDistance = 5
local circleRadius = 10
local followMode = true

local crouchWalkSpeed = 50
local crouchJumpPower = 50
local blobalter = 1

_G.strength = 400
_G.ToyToLoad = "BombMissile"
_G.MaxMissiles = 9
_G.BlobmanDelay = 0.005

for i, v in pairs(localPlayer:WaitForChild("PlayerGui"):WaitForChild("MenuGui"):WaitForChild("Menu"):WaitForChild("TabContents"):WaitForChild("Toys"):WaitForChild("Contents"):GetChildren()) do
    if v.Name ~= "UIGridLayout" then
        ownedToys[v.Name] = true
    end
end

local toysFolder = workspace:FindFirstChild(localPlayer.Name.."SpawnedInToys")

local function isDescendantOf(target, other)
    local currentParent = target.Parent
    while currentParent do
        if currentParent == other then
            return true
        end
        currentParent = currentParent.Parent
    end
    return false
end

local function DestroyT(toy)
    local toy = toy or toysFolder:FindFirstChildWhichIsA("Model")
    DestroyToy:FireServer(toy)
end

local function getDescendantParts(descendantName)
    local parts = {}
    for _, descendant in ipairs(workspace.Map:GetDescendants()) do
        if descendant:IsA("Part") and descendant.Name == descendantName then
            table.insert(parts, descendant)
        end
    end
    return parts
end

local poisonHurtParts = getDescendantParts("PoisonHurtPart")
local paintPlayerParts = getDescendantParts("PaintPlayerPart")

local function getNearestPlayer()
    local nearestPlayer
    local nearestDistance = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (playerCharacter.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
            end
        end
    end
    return nearestPlayer
end

local function cleanupConnections(connectionTable)
    for _, connection in ipairs(connectionTable) do
        connection:Disconnect()
    end
    connectionTable = {}
end

local function spawnItemCf(itemName, cframe)
    task.spawn(function()
        local rotation = Vector3.new(0, 0, 0)
        ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer(itemName, cframe, rotation)
    end)
end

local function spawnItem(itemName, position)
    task.spawn(function()
        local cframe = CFrame.new(position)
        local rotation = Vector3.new(0, 90, 0)
        ReplicatedStorage.MenuToys.SpawnToyRemoteFunction:InvokeServer(itemName, cframe, rotation)
    end)
end

local function arson(part)
    if not toysFolder:FindFirstChild("Campfire") then
        spawnItem("Campfire", Vector3.new(-72.9304581, -5.96906614, -265.543732))
    end
    local campfire = toysFolder:FindFirstChild("Campfire")
    burnPart = campfire:FindFirstChild("FirePlayerPart") or campfire.FirePlayerPart
    burnPart.Size = Vector3.new(7, 7, 7)
    burnPart.Position = part.Position
    task.wait(0.3)
    burnPart.Position = Vector3.new(0, -50, 0)
end

local function handleCharacterAdded(player)
    local characterAddedConnection = player.CharacterAdded:Connect(function(character)
        local hrp = character:WaitForChild("HumanoidRootPart")
        local fpp = hrp:WaitForChild("FirePlayerPart")
        fpp.Size = Vector3.new(4.5, 5, 4.5)
        fpp.CollisionGroup = "1"
        fpp.CanQuery = true
    end)
    table.insert(kickGrabConnections, characterAddedConnection)
end

local function kickGrab()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            if hrp:FindFirstChild("FirePlayerPart") then
                local fpp = hrp.FirePlayerPart
                fpp.Size = Vector3.new(4.5, 5.5, 4.5)
                fpp.CollisionGroup = "1"
                fpp.CanQuery = true
            end
        end
        handleCharacterAdded(player)
    end
    local playerAddedConnection = Players.PlayerAdded:Connect(handleCharacterAdded)
    table.insert(kickGrabConnections, playerAddedConnection)
end

local function grabHandler(grabType)
    while true do
        pcall(function()
            local child = workspace:FindFirstChild("GrabParts")
            if child and child.Name == "GrabParts" then
                local grabPart = child:FindFirstChild("GrabPart")
                local grabbedPart = grabPart:FindFirstChild("WeldConstraint").Part1
                local head = grabbedPart.Parent:FindFirstChild("Head")
                if head then
                    while workspace:FindFirstChild("GrabParts") do
                        local partsTable = grabType == "poison" and poisonHurtParts or paintPlayerParts
                        for _, part in pairs(partsTable) do
                            part.Size = Vector3.new(2, 2, 2)
                            part.Transparency = 1
                            part.Position = head.Position
                        end
                        wait()
                        for _, part in pairs(partsTable) do
                            part.Position = Vector3.new(0, -200, 0)
                        end
                    end
                    for _, part in pairs(partsTable) do
                        part.Position = Vector3.new(0, -200, 0)
                    end
                end
            end
        end)
        wait()
    end
end

local function fireGrab()
    while true do
        pcall(function()
            local child = workspace:FindFirstChild("GrabParts")
            if child and child.Name == "GrabParts" then
                local grabPart = child:FindFirstChild("GrabPart")
                local grabbedPart = grabPart:FindFirstChild("WeldConstraint").Part1
                local head = grabbedPart.Parent:FindFirstChild("Head")
                if head then
                    arson(head)
                end
            end
        end)
        wait()
    end
end

local function noclipGrab()
    while true do
        pcall(function()
            local child = workspace:FindFirstChild("GrabParts")
            if child and child.Name == "GrabParts" then
                local grabPart = child:FindFirstChild("GrabPart")
                local grabbedPart = grabPart:FindFirstChild("WeldConstraint").Part1
                local character = grabbedPart.Parent
                if character.HumanoidRootPart then
                    while workspace:FindFirstChild("GrabParts") do
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                        wait()
                    end
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end)
        wait()
    end
end

local function fireAll()
    while true do
        pcall(function()
            if toysFolder:FindFirstChild("Campfire") then
                DestroyT(toysFolder:FindFirstChild("Campfire"))
                wait(0.5)
            end
            spawnItemCf("Campfire", playerCharacter.Head.CFrame)
            local campfire = toysFolder:WaitForChild("Campfire")
            local firePlayerPart
            for _, part in pairs(campfire:GetChildren()) do
                if part.Name == "FirePlayerPart" then
                    part.Size = Vector3.new(10, 10, 10)
                    firePlayerPart = part
                    break
                end
            end
            local originalPosition = playerCharacter.Torso.Position
            SetNetworkOwner:FireServer(firePlayerPart, firePlayerPart.CFrame)
            playerCharacter:MoveTo(firePlayerPart.Position)
            wait(0.3)
            playerCharacter:MoveTo(originalPosition)
            local bodyPosition = Instance.new("BodyPosition")
            bodyPosition.P = 20000
            bodyPosition.Position = playerCharacter.Head.Position + Vector3.new(0, 600, 0)
            bodyPosition.Parent = campfire.Main
            while true do
                for _, player in pairs(Players:GetChildren()) do
                    pcall(function()
                        bodyPosition.Position = playerCharacter.Head.Position + Vector3.new(0, 600, 0)
                        if player.Character and player.Character.HumanoidRootPart and player.Character ~= playerCharacter then
                            firePlayerPart.Position = player.Character.HumanoidRootPart.Position or player.Character.Head.Position
                            wait()
                        end
                    end)
                end  
                wait()
            end
        end)
        wait()
    end
end

local function createHighlight(parent)
    local highlight = Instance.new("Highlight")
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillTransparency = 1
    highlight.Name = "Highlight"
    highlight.OutlineColor = Color3.new(0, 0, 1)
    highlight.OutlineTransparency = 0.5
    highlight.Parent = parent
    return highlight
end

local function createBodyMovers(part, position, rotation)
    local bodyPosition = Instance.new("BodyPosition")
    local bodyGyro = Instance.new("BodyGyro")
    bodyPosition.P = 15000
    bodyPosition.D = 200
    bodyPosition.MaxForce = Vector3.new(5000000, 5000000, 5000000)
    bodyPosition.Position = position
    bodyPosition.Parent = part
    bodyGyro.P = 15000
    bodyGyro.D = 200
    bodyGyro.MaxTorque = Vector3.new(5000000, 5000000, 5000000)
    bodyGyro.CFrame = rotation
    bodyGyro.Parent = part
end

local function anchorGrab()
    while true do
        pcall(function()
            local grabParts = workspace:FindFirstChild("GrabParts")
            if not grabParts then return end
            local grabPart = grabParts:FindFirstChild("GrabPart")
            if not grabPart then return end
            local weldConstraint = grabPart:FindFirstChild("WeldConstraint")
            if not weldConstraint or not weldConstraint.Part1 then return end
            local primaryPart = weldConstraint.Part1.Name == "SoundPart" and weldConstraint.Part1 or weldConstraint.Part1.Parent.SoundPart or weldConstraint.Part1.Parent.PrimaryPart or weldConstraint.Part1
            if not primaryPart or primaryPart.Anchored then return end
            if isDescendantOf(primaryPart, workspace.Map) then return end
            for _, player in pairs(Players:GetChildren()) do
                if isDescendantOf(primaryPart, player.Character) then return end
            end
            local t = true
            for _, v in pairs(primaryPart:GetDescendants()) do
                if table.find(anchoredParts, v) then t = false end
            end
            if t and not table.find(anchoredParts, primaryPart) then
                local target = (primaryPart.Parent:IsA("Model") and primaryPart.Parent ~= workspace) and primaryPart.Parent or primaryPart
                createHighlight(target)
                table.insert(anchoredParts, primaryPart)
            end
            local cleaners = (primaryPart.Parent:IsA("Model") and primaryPart.Parent ~= workspace) and primaryPart.Parent:GetDescendants() or primaryPart:GetChildren()
            for _, child in ipairs(cleaners) do
                if child:IsA("BodyPosition") or child:IsA("BodyGyro") then child:Destroy() end
            end
            while workspace:FindFirstChild("GrabParts") do wait() end
            createBodyMovers(primaryPart, primaryPart.Position, primaryPart.CFrame)
        end)
        wait()
    end
end

local function anchorKickGrab()
    while true do
        pcall(function()
            local grabParts = workspace:FindFirstChild("GrabParts")
            if not grabParts then return end
            local grabPart = grabParts:FindFirstChild("GrabPart")
            if not grabPart then return end
            local weldConstraint = grabPart:FindFirstChild("WeldConstraint")
            if not weldConstraint or not weldConstraint.Part1 then return end
            local primaryPart = weldConstraint.Part1
            if not primaryPart or isDescendantOf(primaryPart, workspace.Map) or primaryPart.Name ~= "FirePlayerPart" then return end
            for _, child in ipairs(primaryPart:GetChildren()) do
                if child:IsA("BodyPosition") or child:IsA("BodyGyro") then child:Destroy() end
            end
            while workspace:FindFirstChild("GrabParts") do wait() end
            createBodyMovers(primaryPart, primaryPart.Position, primaryPart.CFrame)
        end)
        wait()
    end
end

local function cleanupAnchoredParts()
    for _, part in ipairs(anchoredParts) do
        if part then
            if part:FindFirstChild("BodyPosition") then part.BodyPosition:Destroy() end
            if part:FindFirstChild("BodyGyro") then part.BodyGyro:Destroy() end
            local highlight = part:FindFirstChild("Highlight") or (part.Parent and part.Parent:FindFirstChild("Highlight"))
            if highlight then highlight:Destroy() end
        end
    end
    cleanupConnections(anchoredConnections)
    anchoredParts = {}
end

local function updateBodyMovers(primaryPart)
    for _, group in ipairs(compiledGroups) do
        if group.primaryPart and group.primaryPart == primaryPart then
            for _, data in ipairs(group.group) do
                local bodyPosition = data.part:FindFirstChild("BodyPosition")
                local bodyGyro = data.part:FindFirstChild("BodyGyro")
                if bodyPosition then bodyPosition.Position = (primaryPart.CFrame * data.offset).Position end
                if bodyGyro then bodyGyro.CFrame = primaryPart.CFrame * data.offset end
            end
        end
    end
end

local function cleanupCompiledGroups()
    for _, groupData in ipairs(compiledGroups) do
        for _, data in ipairs(groupData.group) do
            if data.part then
                if data.part:FindFirstChild("BodyPosition") then data.part.BodyPosition:Destroy() end
                if data.part:FindFirstChild("BodyGyro") then data.part.BodyGyro:Destroy() end
            end
        end
        if groupData.primaryPart and groupData.primaryPart.Parent then
            local highlight = groupData.primaryPart:FindFirstChild("Highlight") or groupData.primaryPart.Parent:FindFirstChild("Highlight")
            if highlight then highlight:Destroy() end
        end
    end
    cleanupConnections(compileConnections)
    cleanupConnections(renderSteppedConnections)
    compiledGroups = {}
end

local function unanchorPrimaryPart()
    local primaryPart = anchoredParts
    if not primaryPart then return end
    if primaryPart:FindFirstChild("BodyPosition") then primaryPart.BodyPosition:Destroy() end
    if primaryPart:FindFirstChild("BodyGyro") then primaryPart.BodyGyro:Destroy() end
    local highlight = primaryPart.Parent:FindFirstChild("Highlight") or primaryPart:FindFirstChild("Highlight")
    if highlight then highlight:Destroy() end
end

local function recoverParts()
    while true do
        pcall(function()
            local character = localPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local humanoidRootPart = character.HumanoidRootPart
                for _, partModel in pairs(anchoredParts) do
                    coroutine.wrap(function()
                        if partModel and (partModel.Position - humanoidRootPart.Position).Magnitude <= 30 then
                            local highlight = partModel:FindFirstChild("Highlight") or partModel.Parent:FindFirstChild("Highlight")
                            if highlight and highlight.OutlineColor == Color3.new(1, 0, 0) then
                                SetNetworkOwner:FireServer(partModel, partModel.CFrame)
                            end
                        end
                    end)()
                end
            end
        end)
        wait(0.02)
    end
end

local function setupAntiExplosion(character)
    local partOwner = character:WaitForChild("Humanoid"):FindFirstChild("Ragdolled")
    if partOwner then
        antiExplosionConnection = partOwner:GetPropertyChangedSignal("Value"):Connect(function()
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") then part.Anchored = partOwner.Value end
            end
        end)
    end
end

local function blobGrabPlayer(player, blobman)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    if blobalter == 1 then
        local args = {
            [1] = blobman:FindFirstChild("LeftDetector"),
            [2] = player.Character:FindFirstChild("HumanoidRootPart"),
            [3] = blobman:FindFirstChild("LeftDetector"):FindFirstChild("LeftWeld")
        }
        blobman:WaitForChild("BlobmanSeatAndOwnerScript"):WaitForChild("CreatureGrab"):FireServer(unpack(args))
        blobalter = 2
    else
        local args = {
            [1] = blobman:FindFirstChild("RightDetector"),
            [2] = player.Character:FindFirstChild("HumanoidRootPart"),
            [3] = blobman:FindFirstChild("RightDetector"):FindFirstChild("RightWeld")
        }
        blobman:WaitForChild("BlobmanSeatAndOwnerScript"):WaitForChild("CreatureGrab"):FireServer(unpack(args))
        blobalter = 1
    end
end

local _G = _G or {}
_G.AntiAFK = true
_G.WalkAntiAFK = false

local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

if CoreGui:FindFirstChild("ArahisWatermark") then
    CoreGui.ArahisWatermark:Destroy()
end

local WatermarkGui = Instance.new("ScreenGui")
WatermarkGui.Name = "ArahisWatermark"
WatermarkGui.Parent = CoreGui
WatermarkGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = WatermarkGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25) 
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0, 20, 0, 20) 
MainFrame.Size = UDim2.new(0, 310, 0, 30) 

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 5)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(45, 45, 45)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

local function createTextLabel(name, text, color, order)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color
    label.TextSize = 13
    label.AutomaticSize = Enum.AutomaticSize.X 
    label.Size = UDim2.new(0, 0, 1, 0)
    label.LayoutOrder = order
    label.Parent = MainFrame
    return label
end

local HubTitle = createTextLabel("HubTitle", "Arahis Hub", Color3.fromRGB(160, 130, 255), 1)

local Sep1 = createTextLabel("Sep1", "|", Color3.fromRGB(60, 60, 60), 2)
local UserLabel = createTextLabel("UserLabel", Players.LocalPlayer.Name, Color3.fromRGB(200, 200, 200), 3)

local Sep2 = createTextLabel("Sep2", "|", Color3.fromRGB(60, 60, 60), 4)
local FpsLabel = createTextLabel("FpsLabel", "FPS: --", Color3.fromRGB(200, 200, 200), 5)

local Sep3 = createTextLabel("Sep3", "|", Color3.fromRGB(60, 60, 60), 6)
local PingLabel = createTextLabel("PingLabel", "Ping: -- ms", Color3.fromRGB(200, 200, 200), 7)

local fpsCount = 0
local lastUpdate = os.clock()

RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    local now = os.clock()
    
    if now - lastUpdate >= 0.5 then
        local currentFps = math.floor(fpsCount / (now - lastUpdate))
        FpsLabel.Text = "FPS: " .. tostring(currentFps)
        
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        PingLabel.Text = "Ping: " .. tostring(ping) .. " ms"

        fpsCount = 0
        lastUpdate = now
    end
end)

local HomeTab = Window:MakeTab({Name = "Home", Icon = "rbxassetid://10723407389", PremiumOnly = false})
HomeTab:AddParagraph("UI / Orion Lib", "Interface written to Orion Library")
HomeTab:AddParagraph("Welcome!", "Welcome to Arahis hub, " .. localPlayer.Name .. "! Thanks for using the script.")

HomeTab:AddToggle({
    Name = "Anti AFK",
    Default = true,
    Callback = function(Value)
        _G.AntiAFK = Value
    end
})

HomeTab:AddToggle({
    Name = "Walk AFK",
    Default = false,
    Callback = function(Value)
        _G.WalkAntiAFK = Value

        task.spawn(function()
            while _G.WalkAntiAFK do
                local player = game.Players.LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                
                if humanoid then
                    humanoid:Move(Vector3.new(0, 0, 0.1))
                    task.wait(0.2)
                    humanoid:Move(Vector3.new(0, 0, -0.1))
                end
                task.wait(10)
            end
        end)
    end
})

local CombatTab = Window:MakeTab({Name = "Combat", Icon = "rbxassetid://10723404472", PremiumOnly = false})
CombatTab:AddParagraph("Combat Settings", "Adjust throwing force and extra effects")

CombatTab:AddSlider({
    Name = "Strength Power",
    Min = 300, Max = 10000, Default = 300, Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "",
    Callback = function(Value) _G.strength = Value end    
})

CombatTab:AddToggle({
    Name = "Strength",
    Default = false,
    Callback = function(enabled)
        if enabled then
            strengthConnection = workspace.ChildAdded:Connect(function(model)
                if model.Name == "GrabParts" then
                    local partToImpulse = model.GrabPart.WeldConstraint.Part1
                    if partToImpulse then
                        local velocityObj = Instance.new("BodyVelocity", partToImpulse)
                        model:GetPropertyChangedSignal("Parent"):Connect(function()
                            if not model.Parent then
                                if UserInputService:GetLastInputType() == Enum.UserInputType.MouseButton2 then
                                    velocityObj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                    velocityObj.Velocity = workspace.CurrentCamera.CFrame.LookVector * _G.strength
                                    Debris:AddItem(velocityObj, 1)
                                else
                                    velocityObj:Destroy()
                                end
                            end
                        end)
                    end
                end
            end)
        elseif strengthConnection then
            strengthConnection:Disconnect()
        end
    end
})

CombatTab:AddToggle({
    Name = "Poison Grab", Default = false,
    Callback = function(enabled)
        if enabled then
            poisonGrabCoroutine = coroutine.create(function() grabHandler("poison") end)
            coroutine.resume(poisonGrabCoroutine)
        else
            if poisonGrabCoroutine then
                coroutine.close(poisonGrabCoroutine)
                poisonGrabCoroutine = nil
                for _, part in pairs(poisonHurtParts) do part.Position = Vector3.new(0, -200, 0) end
            end
        end
    end
})

CombatTab:AddToggle({
    Name = "Radioactive Grab", Default = false,
    Callback = function(enabled)
        if enabled then
            ufoGrabCoroutine = coroutine.create(function() grabHandler("radioactive") end)
            coroutine.resume(ufoGrabCoroutine)
        else
            if ufoGrabCoroutine then
                coroutine.close(ufoGrabCoroutine)
                ufoGrabCoroutine = nil
                for _, part in pairs(paintPlayerParts) do part.Position = Vector3.new(0, -200, 0) end
            end
        end
    end
})

CombatTab:AddToggle({
    Name = "Fire Grab", Default = false,
    Callback = function(enabled)
        if enabled then
            fireGrabCoroutine = coroutine.create(fireGrab)
            coroutine.resume(fireGrabCoroutine)
        else
            if fireGrabCoroutine then coroutine.close(fireGrabCoroutine) fireGrabCoroutine = nil end
        end
    end
})

CombatTab:AddToggle({
    Name = "Noclip Grab", Default = false,
    Callback = function(enabled)
        if enabled then
            noclipGrabCoroutine = coroutine.create(noclipGrab)
            coroutine.resume(noclipGrabCoroutine)
        else
            if noclipGrabCoroutine then coroutine.close(noclipGrabCoroutine) noclipGrabCoroutine = nil end
        end
    end
})

CombatTab:AddToggle({
    Name = "Kick Grab", Default = false,
    Callback = function(enabled)
        if enabled then
            kickGrab()
        else
            for _, connection in pairs(kickGrabConnections) do connection:Disconnect() end
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    if hrp:FindFirstChild("FirePlayerPart") then
                        local fpp = hrp.FirePlayerPart
                        fpp.Size = Vector3.new(2.5, 5.5, 2.5)
                        fpp.CollisionGroup = "Default"
                        fpp.CanQuery = false
                    end
                end
            end
            kickGrabConnections = {}
        end
    end
})

CombatTab:AddToggle({
    Name = "Kick Grab Anchor", Default = false,
    Callback = function(enabled)
        if enabled then
            if not anchorKickCoroutine or coroutine.status(anchorKickCoroutine) == "dead" then
                anchorKickCoroutine = coroutine.create(anchorKickGrab)
                coroutine.resume(anchorKickCoroutine)
            end
        else
            if anchorKickCoroutine and coroutine.status(anchorKickCoroutine) ~= "dead" then
                coroutine.close(anchorKickCoroutine)
                anchorKickCoroutine = nil
            end
        end
    end
})

CombatTab:AddToggle({
    Name = "Fire All", Default = false,
    Callback = function(enabled)
        if enabled then
            fireAllCoroutine = coroutine.create(fireAll)
            coroutine.resume(fireAllCoroutine)
        else
            if fireAllCoroutine then coroutine.close(fireAllCoroutine) fireAllCoroutine = nil end
        end
    end
})

local PlayerTab = Window:MakeTab({Name = "Local Player", Icon = "rbxassetid://10747373176", PremiumOnly = false})

PlayerTab:AddToggle({
    Name = "Crouch Speed", Default = false,
    Callback = function(enabled)
        if enabled then
            crouchSpeedCoroutine = coroutine.create(function()
                while true do
                    pcall(function()
                        if not playerCharacter.Humanoid then return end
                        if playerCharacter.Humanoid.WalkSpeed == 5 then
                            playerCharacter.Humanoid.WalkSpeed = crouchWalkSpeed
                        end
                    end)
                    wait()
                end
            end)
            coroutine.resume(crouchSpeedCoroutine)
        else
            if crouchSpeedCoroutine then
                coroutine.close(crouchSpeedCoroutine)
                crouchSpeedCoroutine = nil
                if playerCharacter.Humanoid then playerCharacter.Humanoid.WalkSpeed = 16 end
            end
        end
    end
})

PlayerTab:AddSlider({
    Name = "Set Crouch Speed", Min = 6, Max = 1000, Default = 300, Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "",
    Callback = function(Value) crouchWalkSpeed = Value end
})

PlayerTab:AddToggle({
    Name = "Crouch Jump Power", Default = false,
    Callback = function(enabled)
        if enabled then
            crouchJumpCoroutine = coroutine.create(function()
                while true do
                    pcall(function()
                        if not playerCharacter.Humanoid then return end
                        if playerCharacter.Humanoid.JumpPower == 12 then
                            playerCharacter.Humanoid.JumpPower = crouchJumpPower
                        end
                    end)
                    wait()
                end
            end)
            coroutine.resume(crouchJumpCoroutine)
        else
            if crouchJumpCoroutine then
                coroutine.close(crouchJumpCoroutine)
                crouchJumpCoroutine = nil
                if playerCharacter.Humanoid then playerCharacter.Humanoid.JumpPower = 24 end
            end
        end
    end
})

PlayerTab:AddSlider({
    Name = "Set Crouch Jump Power", Min = 6, Max = 1000, Default = 300, Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "",
    Callback = function(Value) crouchJumpPower = Value end
})

local ObjectGrabTab = Window:MakeTab({Name = "Object Grab", Icon = "rbxassetid://10709782497", PremiumOnly = false})

ObjectGrabTab:AddToggle({
    Name = "Anchor Grab", Default = false,
    Callback = function(enabled)
        if enabled then
            if not anchorGrabCoroutine or coroutine.status(anchorGrabCoroutine) == "dead" then
                anchorGrabCoroutine = coroutine.create(anchorGrab)
                coroutine.resume(anchorGrabCoroutine)
            end
        else
            if anchorGrabCoroutine and coroutine.status(anchorGrabCoroutine) ~= "dead" then
                coroutine.close(anchorGrabCoroutine)
                anchorGrabCoroutine = nil
            end
        end
    end
})

ObjectGrabTab:AddButton({Name = "Unanchor Parts", Callback = cleanupAnchoredParts})
ObjectGrabTab:AddButton({
    Name = "Disassemble Parts",
    Callback = function()
        cleanupCompiledGroups()
        cleanupAnchoredParts()
        if compileCoroutine and coroutine.status(compileCoroutine) ~= "dead" then
            coroutine.close(compileCoroutine)
            compileCoroutine = nil
        end
    end
})

ObjectGrabTab:AddToggle({
    Name = "Auto Recover Dropped Parts", Default = false,
    Callback = function(enabled)
        if enabled then
            if not AutoRecoverDroppedPartsCoroutine or coroutine.status(AutoRecoverDroppedPartsCoroutine) == "dead" then
                AutoRecoverDroppedPartsCoroutine = coroutine.create(recoverParts)
                coroutine.resume(AutoRecoverDroppedPartsCoroutine)
            end
        else
            if AutoRecoverDroppedPartsCoroutine and coroutine.status(AutoRecoverDroppedPartsCoroutine) ~= "dead" then
                coroutine.close(AutoRecoverDroppedPartsCoroutine)
                AutoRecoverDroppedPartsCoroutine = nil
            end
        end
    end
})
ObjectGrabTab:AddButton({Name = "Unanchor Header Part", Callback = unanchorPrimaryPart})

local DefanseTab = Window:MakeTab({Name = "Anti Grab", Icon = "rbxassetid://10734951847", PremiumOnly = false})

DefanseTab:AddToggle({
    Name = "Anti Grab", Default = false,
    Callback = function(enabled)
        if enabled then
            autoStruggleCoroutine = RunService.Heartbeat:Connect(function()
                local character = localPlayer.Character
                if character and character:FindFirstChild("Head") then
                    local head = character.Head
                    local partOwner = head:FindFirstChild("PartOwner")
                    if partOwner then
                        Struggle:FireServer()
                        ReplicatedStorage.GameCorrectionEvents.StopAllVelocity:FireServer()
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then part.Anchored = true end
                        end
                        while localPlayer.IsHeld.Value do wait() end
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then part.Anchored = false end
                        end
                    end
                end
            end)
        else
            if autoStruggleCoroutine then autoStruggleCoroutine:Disconnect() autoStruggleCoroutine = nil end
        end
    end
})

DefanseTab:AddToggle({
    Name = "Anti Kick Grab", Default = false,
    Callback = function(enabled)
        if enabled then
            antiKickCoroutine = RunService.Heartbeat:Connect(function()
                local character = localPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart:FindFirstChild("FirePlayerPart") then
                    local partOwner = character.HumanoidRootPart.FirePlayerPart:FindFirstChild("PartOwner")
                    if partOwner and partOwner.Value ~= localPlayer.Name then
                        local args = {
                            [1] = character:WaitForChild("HumanoidRootPart"), 
                            [2] = 0
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("CharacterEvents"):WaitForChild("RagdollRemote"):FireServer(unpack(args))
                        wait(0.1)
                        Struggle:FireServer()
                    end
                end
            end)
        else
            if antiKickCoroutine then antiKickCoroutine:Disconnect() antiKickCoroutine = nil end
        end
    end
})

DefanseTab:AddToggle({
    Name = "Anti Explosion", Default = false,
    Callback = function(enabled)
        if enabled then
            if localPlayer.Character then setupAntiExplosion(localPlayer.Character) end
            characterAddedConn = localPlayer.CharacterAdded:Connect(function(character)
                if antiExplosionConnection then antiExplosionConnection:Disconnect() end
                setupAntiExplosion(character)
            end)
        else
            if antiExplosionConnection then antiExplosionConnection:Disconnect() antiExplosionConnection = nil end
            if characterAddedConn then characterAddedConn:Disconnect() characterAddedConn = nil end
        end
    end
})

DefanseTab:AddToggle({
    Name = "Self Defense / Air Suspend", Default = false,
    Callback = function(enabled)
        if enabled then
            autoDefendCoroutine = coroutine.create(function()
                while wait(0.02) do
                    local character = localPlayer.Character
                    if character and character:FindFirstChild("Head") then
                        local head = character.Head
                        local partOwner = head:FindFirstChild("PartOwner")
                        if partOwner then
                            local attacker = Players:FindFirstChild(partOwner.Value)
                            if attacker and attacker.Character then
                                Struggle:FireServer()
                                SetNetworkOwner:FireServer(attacker.Character.Head or attacker.Character.Torso, attacker.Character.HumanoidRootPart.FirePlayerPart.CFrame)
                                task.wait(0.1)
                                local target = attacker.Character:FindFirstChild("Torso")
                                if target then
                                    local velocity = target:FindFirstChild("l") or Instance.new("BodyVelocity")
                                    velocity.Name = "l"
                                    velocity.Parent = target
                                    velocity.Velocity = Vector3.new(0, 50, 0)
                                    velocity.MaxForce = Vector3.new(0, math.huge, 0)
                                    Debris:AddItem(velocity, 100)
                                end
                            end
                        end
                    end
                end
            end)
            coroutine.resume(autoDefendCoroutine)
        else
            if autoDefendCoroutine then coroutine.close(autoDefendCoroutine) autoDefendCoroutine = nil end
        end
    end
})

local BlobmanTab = Window:MakeTab({Name = "Blob Man", Icon = "rbxassetid://10709782230", PremiumOnly = false})
local blobmanToggle

blobmanToggle = BlobmanTab:AddToggle({
    Name = "Destroy Server", Default = false,
    Callback = function(enabled)
        if enabled then
            blobmanCoroutine = coroutine.create(function()
                local foundBlobman = false
                for i, v in pairs(game.Workspace:GetDescendants()) do
                    if v.Name == "CreatureBlobman" then
                        if v:FindFirstChild("VehicleSeat") and v.VehicleSeat:FindFirstChild("SeatWeld") and isDescendantOf(v.VehicleSeat.SeatWeld.Part1, localPlayer.Character) then
                            blobman = v
                            foundBlobman = true
                            break
                        end
                    end
                end
                if not foundBlobman then
                    OrionLib:MakeNotification({Name = "Error", Content = "You must be mounted upon a blobman! Toggling off.", Time = 4})
                    blobmanToggle:Set(false)
                    blobman = nil
                    coroutine.close(blobmanCoroutine)
                    blobmanCoroutine = nil
                    return
                end
                while true do
                    pcall(function()
                        while wait() do
                            for i, v in pairs(Players:GetChildren()) do
                                if blobman and v ~= localPlayer then
                                    blobGrabPlayer(v, blobman)
                                    wait(_G.BlobmanDelay)
                                end
                            end
                        end
                    end)
                    wait(0.02)
                end
            end)
            coroutine.resume(blobmanCoroutine)
        else
            if blobmanCoroutine then coroutine.close(blobmanCoroutine) blobmanCoroutine = nil blobman = nil end
        end
    end
})

BlobmanTab:AddSlider({
    Name = "Destroy Server Speed", Min = 0.05, Max = 1, Default = 0.5, Color = Color3.fromRGB(255,255,255), Increment = 0.01, ValueName = "",
    Callback = function(Value) _G.BlobmanDelay = Value end
})

local FunTab = Window:MakeTab({Name = "Fun / Troll", Icon = "rbxassetid://10734964441", PremiumOnly = false})

FunTab:AddTextbox({
    Name = "Number of coins", Default = "", TextDisappear = false,
    Callback = function(Text) skolko = Text end
})

FunTab:AddButton({
    Name = "Get Coin",
    Callback = function()
        local coinAmount = tonumber(skolko) or 0 
        pcall(function()
            localPlayer.PlayerGui.MenuGui.TopRight.CoinsFrame.CoinsDisplay.Coins.Text = tostring(coinAmount)
        end)
    end
})

FunTab:AddSlider({
    Name = "Offset", Min = 1, Max = 10, Default = 10, Color = Color3.fromRGB(255,255,255), Increment = 5, ValueName = "",
    Callback = function(Value) decoyOffset = Value end
})

FunTab:AddTextbox({
    Name = "Circle Radius", Default = "", TextDisappear = false,
    Callback = function(Value) circleRadius = tonumber(Value) or 10 end
})

FunTab:AddButton({
    Name = "Decoy Follow",
    Callback = function()
        local decoys = {}
        for _, descendant in pairs(workspace:GetDescendants()) do
            if descendant:IsA("Model") and descendant.Name == "YouDecoy" then table.insert(decoys, descendant) end
        end
        local numDecoys = #decoys
        local midPoint = math.ceil(numDecoys / 2)

        local function updateDecoyPositions()
            for index, decoy in pairs(decoys) do
                local torso = decoy:FindFirstChild("Torso")
                if torso then
                    local bodyPosition = torso:FindFirstChild("BodyPosition")
                    local bodyGyro = torso:FindFirstChild("BodyGyro")
                    if bodyPosition and bodyGyro then
                        local targetPosition
                        if followMode then
                            if playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart") then
                                targetPosition = playerCharacter.HumanoidRootPart.Position
                                local offset = (index - midPoint) * decoyOffset
                                local forward = playerCharacter.HumanoidRootPart.CFrame.LookVector
                                local right = playerCharacter.HumanoidRootPart.CFrame.RightVector
                                targetPosition = targetPosition - forward * decoyOffset + right * offset
                            end
                        else
                            local nearestPlayer = getNearestPlayer()
                            if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                local angle = math.rad((index - 1) * (360 / numDecoys))
                                targetPosition = nearestPlayer.Character.HumanoidRootPart.Position + Vector3.new(math.cos(angle) * circleRadius, 0, math.sin(angle) * circleRadius)
                                bodyGyro.CFrame = CFrame.new(torso.Position, nearestPlayer.Character.HumanoidRootPart.Position)
                            end
                        end
                        if targetPosition then
                            local distance = (targetPosition - torso.Position).Magnitude
                            if distance > stopDistance then
                                bodyPosition.Position = targetPosition
                                if followMode then bodyGyro.CFrame = CFrame.new(torso.Position, targetPosition) end
                            else
                                bodyPosition.Position = torso.Position
                                bodyGyro.CFrame = torso.CFrame
                            end
                        end
                    end
                end
            end
        end

        for _, decoy in pairs(decoys) do
            local torso = decoy:FindFirstChild("Torso")
            if torso then
                local bodyPosition = Instance.new("BodyPosition")
                local bodyGyro = Instance.new("BodyGyro")
                bodyPosition.Parent = torso
                bodyGyro.Parent = torso
                bodyPosition.MaxForce = Vector3.new(40000, 40000, 40000)
                bodyPosition.D = 100
                bodyPosition.P = 100
                bodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
                bodyGyro.D = 100
                bodyGyro.P = 20000
                local connection = RunService.Heartbeat:Connect(updateDecoyPositions)
                table.insert(connections, connection)
                SetNetworkOwner:FireServer(torso, playerCharacter.Head.CFrame)
            end
        end
        OrionLib:MakeNotification({Name = "Units Info", Content = "Got " .. numDecoys .. " units.", Time = 4})
    end
})

FunTab:AddButton({Name = "Toggle Mode", Callback = function() followMode = not followMode end})
FunTab:AddButton({Name = "Disconnect Clones", Callback = function() cleanupConnections(connections) end})

OrionLib:Init()
