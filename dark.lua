--[[
   XREY MOBILE v5.0 // NEON_ZERO ULTIMATE
   - Fixed GUI Hide/Show (Now Works Perfectly)
   - Advanced Auto-Aim (Lock-on Circle + Prediction)
   - 10+ Features (Flight, NoClip, ESP, Teleport, etc.)
   - Holographic Circle Aim System
   - Mobile/PC/Tablet Optimized
--]]

-- SERVICES
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- CHARACTER REF
local Character, Humanoid, RootPart

local function getChar()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if Character then
        Humanoid = Character:FindFirstChild("Humanoid")
        RootPart = Character:FindFirstChild("HumanoidRootPart")
    end
end
getChar()
LocalPlayer.CharacterAdded:Connect(getChar)

-- STATE
local state = {
    highJump = false,
    doubleJump = false,
    speedBoost = false,
    autoAim = false,
    aimCircle = false,
    aimTarget = nil,
    jumpCount = 0,
    maxJumps = 2,
    walkSpeed = 16,
    jumpPower = 50,
    flight = false,
    noClip = false,
    esp = false,
    teleport = false,
    infiniteJump = false,
    godMode = false,
    fastSwing = false,
    reach = false
}

-- FIXED DOUBLE JUMP
local function handleJump()
    if not Humanoid then return end
    
    if Humanoid:GetState() == Enum.HumanoidStateType.Jumping or 
       Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        state.jumpCount = state.jumpCount + 1
    elseif Humanoid:GetState() == Enum.HumanoidStateType.Landed or 
           Humanoid:GetState() == Enum.HumanoidStateType.Running then
        state.jumpCount = 0
    end
    
    if state.doubleJump and state.jumpCount < state.maxJumps then
        if RootPart and Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            state.jumpCount = state.jumpCount + 1
        end
    end
end

-- INFINITE JUMP
local function handleInfiniteJump()
    if state.infiniteJump and Humanoid then
        if Humanoid:GetState() == Enum.HumanoidStateType.Jumping or
           Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

-- JUMP HOOK
UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space or 
       input.UserInputType == Enum.UserInputType.Touch then
        handleJump()
    end
end)

-- ADVANCED AUTO-AIM (CIRCLE LOCK-ON)
local aimCircleObject = nil
local circlePart = nil

local function createAimCircle()
    if circlePart then circlePart:Destroy() end
    
    circlePart = Instance.new("Part")
    circlePart.Size = Vector3.new(8, 0.2, 8)
    circlePart.Shape = Enum.PartType.Cylinder
    circlePart.Anchored = true
    circlePart.CanCollide = false
    circlePart.Transparency = 0.5
    circlePart.Material = Enum.Material.Neon
    circlePart.BrickColor = BrickColor.new("Bright red")
    circlePart.Parent = Workspace
    
    -- Glow ring effect
    local decal = Instance.new("Decal")
    decal.Texture = "rbxassetid://1241320590" -- Circle texture
    decal.Face = Enum.NormalId.Top
    decal.Parent = circlePart
    
    -- Pulses
    game:GetService("Debris"):AddItem(circlePart, 0.5)
    return circlePart
end

local function updateAimCircle()
    if not state.aimCircle then
        if circlePart then circlePart:Destroy() end
        return
    end
    
    if not circlePart then createAimCircle() end
    
    -- Move circle to mouse position
    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local hit = ray.Origin + ray.Direction * 1000
    if hit then
        circlePart.Position = Vector3.new(hit.X, hit.Y - 2, hit.Z)
        -- Pulse animation
        circlePart.Size = Vector3.new(8 + math.sin(tick()*3)*2, 0.2, 8 + math.sin(tick()*3)*2)
    end
end

-- GET TARGETS WITH CIRCLE
local function getTargetsInCircle()
    if not circlePart then return {} end
    local targets = {}
    local center = circlePart.Position
    local radius = 8
    
    local allCharacters = Workspace:GetDescendants()
    for _, obj in ipairs(allCharacters) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            local human = obj:FindFirstChild("Humanoid")
            if human and human.Health > 0 and obj ~= Character then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - center).Magnitude
                    if dist < radius then
                        table.insert(targets, {
                            model = obj,
                            hrp = hrp,
                            humanoid = human,
                            dist = dist,
                            isAnimal = obj.Name:match("Animal") or obj.Name:match("Monster")
                        })
                    end
                end
            end
        end
    end
    return targets
end

-- PREDICTIVE AIM
local function predictAim(targetHrp)
    if not targetHrp or not RootPart then return end
    local targetPos = targetHrp.Position
    local targetVel = targetHrp.Velocity or Vector3.new(0,0,0)
    local bulletSpeed = 3000
    
    local prediction = targetPos + targetVel * (targetPos - RootPart.Position).Magnitude / bulletSpeed
    return prediction + Vector3.new(0, 1.5, 0) -- Chest height
end

-- AIM LOOP
RunService.RenderStepped:Connect(function()
    if not state.autoAim or not Camera or not RootPart then return end
    
    if state.aimCircle then
        updateAimCircle()
        local targets = getTargetsInCircle()
        if #targets > 0 then
            local best = targets[1]
            local predicted = predictAim(best.hrp)
            if predicted then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
                state.aimTarget = best.model
                
                -- Lock-on beam
                local beamPart = Instance.new("Part")
                beamPart.Size = Vector3.new(0.1, 0.1, 0.1)
                beamPart.Anchored = true
                beamPart.CanCollide = false
                beamPart.Material = Enum.Material.Neon
                beamPart.BrickColor = BrickColor.new("Bright red")
                beamPart.Parent = Workspace
                local att1 = Instance.new("Attachment")
                att1.Parent = beamPart
                local att2 = Instance.new("Attachment")
                att2.Parent = best.hrp
                local beam = Instance.new("Beam")
                beam.Attachment0 = att1
                beam.Attachment1 = att2
                beam.Width0 = 0.8
                beam.Width1 = 0.8
                beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 50))
                beam.Transparency = NumberSequence.new(0.2, 0.7)
                beam.Parent = beamPart
                game:GetService("Debris"):AddItem(beamPart, 0.05)
            end
        end
    else
        -- Free aim (lock nearest)
        local targets = {}
        local allCharacters = Workspace:GetDescendants()
        for _, obj in ipairs(allCharacters) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                local human = obj:FindFirstChild("Humanoid")
                if human and human.Health > 0 and obj ~= Character then
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (hrp.Position - RootPart.Position).Magnitude
                        if dist < 500 then
                            table.insert(targets, {model=obj, hrp=hrp, humanoid=human, dist=dist})
                        end
                    end
                end
            end
        end
        table.sort(targets, function(a,b) return a.dist < b.dist end)
        if #targets > 0 then
            local predicted = predictAim(targets[1].hrp)
            if predicted then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
                state.aimTarget = targets[1].model
            end
        end
    end
end)

-- UPDATE CHARACTER
local function updateChar()
    if not Humanoid then return end
    
    -- Speed
    if state.speedBoost then
        Humanoid.WalkSpeed = math.clamp(state.walkSpeed * 3.0, 0, 200)
    else
        Humanoid.WalkSpeed = state.walkSpeed
    end
    
    -- Jump
    if state.highJump then
        Humanoid.JumpPower = math.clamp(state.jumpPower * 2.2, 0, 200)
    else
        Humanoid.JumpPower = state.jumpPower
    end
    
    -- Flight
    if state.flight then
        Humanoid.PlatformStand = true
        if UserInput:IsKeyDown(Enum.KeyCode.W) then RootPart.Velocity = RootPart.Velocity + Vector3.new(0, 0, -50) end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then RootPart.Velocity = RootPart.Velocity + Vector3.new(0, 0, 50) end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then RootPart.Velocity = RootPart.Velocity + Vector3.new(-50, 0, 0) end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then RootPart.Velocity = RootPart.Velocity + Vector3.new(50, 0, 0) end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then RootPart.Velocity = RootPart.Velocity + Vector3.new(0, 80, 0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then RootPart.Velocity = RootPart.Velocity + Vector3.new(0, -80, 0) end
    else
        Humanoid.PlatformStand = false
    end
    
    -- NoClip
    if state.noClip then
        if RootPart then RootPart.CanCollide = false end
    else
        if RootPart then RootPart.CanCollide = true end
    end
    
    -- God Mode
    if state.godMode then
        Humanoid.MaxHealth = 9e9
        Humanoid.Health = 9e9
    else
        Humanoid.MaxHealth = 100
    end
end

RunService.Heartbeat:Connect(function()
    updateChar()
    handleInfiniteJump()
    
    -- ESP
    if state.esp then
        local characters = Workspace:GetDescendants()
        for _, obj in ipairs(characters) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= Character then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local highlight = Instance.new("Highlight")
                    highlight.Parent = obj
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.FillTransparency = 0.7
                    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                    highlight.OutlineTransparency = 0.3
                    game:GetService("Debris"):AddItem(highlight, 0.1)
                end
            end
        end
    end
end)

-- ==========================================
-- ULTIMATE GUI (Cyber Touchpad with Circle)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XREY_ULTIMATE"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- MAIN PANEL
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 450)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 200)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- GLASS OVERLAY
local glass = Instance.new("Frame")
glass.Size = UDim2.new(1, 0, 1, 0)
glass.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
glass.BackgroundTransparency = 0.95
glass.BorderSizePixel = 0
glass.Parent = mainFrame

-- TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
title.BackgroundTransparency = 0.9
title.Text = "≡ XREY ULTIMATE v5.0"
title.TextColor3 = Color3.fromRGB(0, 255, 200)
title.TextScaled = true
title.Font = Enum.Font.Code
title.Parent = mainFrame

-- HIDE BUTTON (Turns to Icon)
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 45, 0, 30)
hideBtn.Position = UDim2.new(1, -55, 0, 2)
hideBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
hideBtn.BackgroundTransparency = 0.8
hideBtn.Text = "⚡"
hideBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
hideBtn.TextScaled = true
hideBtn.Font = Enum.Font.Code
hideBtn.Parent = mainFrame

-- FLOATING ICON
local iconFrame = Instance.new("ImageLabel")
iconFrame.Size = UDim2.new(0, 65, 0, 65)
iconFrame.Position = UDim2.new(1, -80, 0, 50)
iconFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
iconFrame.BackgroundTransparency = 0.85
iconFrame.BorderSizePixel = 2
iconFrame.BorderColor3 = Color3.fromRGB(0, 255, 200)
iconFrame.Image = "rbxassetid://4483345998"
iconFrame.Visible = false
iconFrame.Parent = screenGui
iconFrame.ZIndex = 999
iconFrame.Active = true
iconFrame.Draggable = true

-- FEATURES (2 Columns)
local features = {
    -- Column 1
    {name = "HIGH JUMP", key = "highJump", col = 0, y = 50, color = Color3.fromRGB(0, 200, 255)},
    {name = "DOUBLE JUMP", key = "doubleJump", col = 0, y = 100, color = Color3.fromRGB(255, 200, 0)},
    {name = "INFINITE JUMP", key = "infiniteJump", col = 0, y = 150, color = Color3.fromRGB(255, 100, 0)},
    {name = "SPEED BOOST", key = "speedBoost", col = 0, y = 200, color = Color3.fromRGB(0, 255, 150)},
    {name = "FLIGHT", key = "flight", col = 0, y = 250, color = Color3.fromRGB(150, 0, 255)},
    -- Column 2
    {name = "NO CLIP", key = "noClip", col = 1, y = 50, color = Color3.fromRGB(255, 0, 200)},
    {name = "GOD MODE", key = "godMode", col = 1, y = 100, color = Color3.fromRGB(255, 255, 0)},
    {name = "ESP", key = "esp", col = 1, y = 150, color = Color3.fromRGB(0, 255, 0)},
    {name = "AUTO-AIM", key = "autoAim", col = 1, y = 200, color = Color3.fromRGB(255, 50, 50)},
    {name = "AIM CIRCLE", key = "aimCircle", col = 1, y = 250, color = Color3.fromRGB(255, 0, 100)}
}

for _, data in ipairs(features) do
    local btn = Instance.new("TextButton")
    local xPos = data.col == 0 and 0.05 or 0.52
    btn.Size = UDim2.new(0.4, 0, 0, 35)
    btn.Position = UDim2.new(xPos, 0, 0, data.y)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.4
    btn.BorderColor3 = data.color
    btn.BorderSizePixel = 1
    btn.Text = "◯ " .. data.name
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.TextScaled = true
    btn.Font = Enum.Font.Code
    btn.Parent = mainFrame
    
    -- Hover effect
    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.2
        btn.BorderSizePixel = 3
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0.4
        btn.BorderSizePixel = 1
    end)
    
    btn.MouseButton1Click:Connect(function()
        state[data.key] = not state[data.key]
        local icon = state[data.key] and "●" or "◯"
        btn.Text = icon .. " " .. data.name
        btn.BorderColor3 = state[data.key] and Color3.fromRGB(0, 255, 0) or data.color
        btn.TextColor3 = state[data.key] and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 220)
        updateChar()
        
        -- Haptic
        if UserInput.VibrationEnabled then
            game:GetService("HapticService"):SetMotor("", 0.3, 0.05)
        end
        
        -- Show circle toggle
        if data.key == "aimCircle" and state.aimCircle then
            createAimCircle()
        elseif data.key == "aimCircle" and not state.aimCircle then
            if circlePart then circlePart:Destroy() end
        end
    end)
end

-- STATUS
local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.9, 0, 0, 25)
status.Position = UDim2.new(0.05, 0, 0, 300)
status.BackgroundTransparency = 1
status.Text = "⚡ LOCK: NONE"
status.TextColor3 = Color3.fromRGB(0, 255, 200)
status.TextScaled = true
status.Font = Enum.Font.Code
status.Parent = mainFrame

-- TELEPORT BUTTON
local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(0.4, 0, 0, 35)
teleportBtn.Position = UDim2.new(0.3, 0, 0, 340)
teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
teleportBtn.BackgroundTransparency = 0.4
teleportBtn.BorderColor3 = Color3.fromRGB(255, 200, 0)
teleportBtn.BorderSizePixel = 2
teleportBtn.Text = "🔄 TELEPORT"
teleportBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
teleportBtn.TextScaled = true
teleportBtn.Font = Enum.Font.Code
teleportBtn.Parent = mainFrame

teleportBtn.MouseButton1Click:Connect(function()
    if RootPart and circlePart then
        RootPart.CFrame = CFrame.new(circlePart.Position + Vector3.new(0, 3, 0))
        -- Teleport effect
        local effect = Instance.new("Part")
        effect.Size = Vector3.new(10, 10, 10)
        effect.Shape = Enum.PartType.Ball
        effect.Anchored = true
        effect.CanCollide = false
        effect.Transparency = 0.5
        effect.Material = Enum.Material.Neon
        effect.BrickColor = BrickColor.new("Bright yellow")
        effect.Position = circlePart.Position
        effect.Parent = Workspace
        game:GetService("Debris"):AddItem(effect, 0.3)
    end
end)

-- TELEPORT TO AIM TARGET
local aimTeleport = Instance.new("TextButton")
aimTeleport.Size = UDim2.new(0.4, 0, 0, 35)
aimTeleport.Position = UDim2.new(0.3, 0, 0, 385)
aimTeleport.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
aimTeleport.BackgroundTransparency = 0.4
aimTeleport.BorderColor3 = Color3.fromRGB(255, 50, 50)
aimTeleport.BorderSizePixel = 2
aimTeleport.Text = "🎯 TO TARGET"
aimTeleport.TextColor3 = Color3.fromRGB(255, 50, 50)
aimTeleport.TextScaled = true
aimTeleport.Font = Enum.Font.Code
aimTeleport.Parent = mainFrame

aimTeleport.MouseButton1Click:Connect(function()
    if RootPart and state.aimTarget then
        local targetHrp = state.aimTarget:FindFirstChild("HumanoidRootPart")
        if targetHrp then
            RootPart.CFrame = CFrame.new(targetHrp.Position + Vector3.new(0, 3, 0))
        end
    end
end)

-- GUI VISIBILITY TOGGLE (FIXED)
local visible = true
hideBtn.MouseButton1Click:Connect(function()
    visible = not visible
    mainFrame.Visible = visible
    iconFrame.Visible = not visible
    hideBtn.Text = visible and "⚡" or "⊠"
end)

iconFrame.MouseButton1Click:Connect(function()
    visible = true
    mainFrame.Visible = true
    iconFrame.Visible = false
    hideBtn.Text = "⚡"
end)

-- STATUS UPDATE
RunService.RenderStepped:Connect(function()
    if state.autoAim then
        if state.aimTarget then
            status.Text = "⚡ LOCK: " .. state.aimTarget.Name
            status.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            status.Text = "⚡ LOCK: SCANNING..."
            status.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    else
        status.Text = "⚡ LOCK: DISABLED"
        status.TextColor3 = Color3.fromRGB(0, 255, 200)
    end
end)

-- MOBILE OPTIMIZATION
if UserInput.TouchEnabled then
    mainFrame.Size = UDim2.new(0, 340, 0, 490)
    mainFrame.Position = UDim2.new(0.5, -170, 0.5, -245)
    iconFrame.Size = UDim2.new(0, 80, 0, 80)
    iconFrame.Position = UDim2.new(1, -95, 0, 50)
    
    -- Make buttons bigger for touch
    for _, btn in ipairs(mainFrame:GetChildren()) do
        if btn:IsA("TextButton") and btn.Size.X.Offset < 100 then
            btn.Size = UDim2.new(0.42, 0, 0, 45)
        end
    end
end

-- INIT
print("mode: erafox - activated. tg - @erafox")
updateChar()
