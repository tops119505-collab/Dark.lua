--[[
   XREY MOBILE v4.0 // NEON_ZERO
   - Fixed Double Jump (Now works 100%)
   - Auto-Aim (Players + Animals, Cross-Place)
   - Direct Hit Prediction
   - New GUI: Holographic Touchpad (Minimal/Cyber)
   - Hide/Show: Becomes Floating Icon
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
local Character
local Humanoid
local RootPart

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
    aimTarget = nil,
    jumpCount = 0,
    maxJumps = 2,
    walkSpeed = 16,
    jumpPower = 50
}

-- FIXED DOUBLE JUMP (WORKING)
local function handleJump()
    if not Humanoid then return end
    local hrp = RootPart
    
    if Humanoid:GetState() == Enum.HumanoidStateType.Jumping or 
       Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        state.jumpCount = state.jumpCount + 1
    elseif Humanoid:GetState() == Enum.HumanoidStateType.Landed or 
           Humanoid:GetState() == Enum.HumanoidStateType.Running or
           Humanoid:GetState() == Enum.HumanoidStateType.GettingUp then
        state.jumpCount = 0
    end
    
    if state.doubleJump and state.jumpCount < state.maxJumps then
        if hrp and Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            state.jumpCount = state.jumpCount + 1
            Humanoid.PlatformStand = false
            
            -- Visual feedback
            local trail = Instance.new("Trail")
            trail.Parent = hrp
            trail.Lifetime = 0.3
            trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 200))
            trail.Transparency = NumberSequence.new(0.8, 0)
            game:GetService("Debris"):AddItem(trail, 0.3)
        end
    end
end

-- DOUBLE JUMP HOOK (Reliable)
UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space or 
       input.UserInputType == Enum.UserInputType.Touch then
        handleJump()
    end
end)

-- AUTO-AIM SYSTEM (Cross-Place + Animals)
local function getTargets()
    local targets = {}
    local allCharacters = Workspace:GetDescendants()
    
    for _, obj in ipairs(allCharacters) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            local human = obj:FindFirstChild("Humanoid")
            if human and human.Health > 0 and obj ~= Character then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - (RootPart and RootPart.Position or Vector3.new(0,0,0))).Magnitude
                    if dist < 500 then
                        table.insert(targets, {
                            model = obj,
                            hrp = hrp,
                            humanoid = human,
                            dist = dist,
                            isAnimal = obj.Name:match("Animal") or obj.Name:match("Monster") or obj.Name:match("NPC")
                        })
                    end
                end
            end
        end
    end
    
    table.sort(targets, function(a,b) return a.dist < b.dist end)
    return targets
end

-- DIRECT HIT PREDICTION
local function predictAim(targetHrp)
    if not targetHrp or not RootPart then return end
    local targetPos = targetHrp.Position
    local targetVel = targetHrp.Velocity or Vector3.new(0,0,0)
    local bulletSpeed = 3000 -- In-game units per second
    
    if targetVel.Magnitude > 1 then
        local prediction = targetPos + targetVel * (targetPos - RootPart.Position).Magnitude / bulletSpeed
        return prediction
    end
    return targetPos + Vector3.new(0, 2.5, 0) -- Head/chest offset
end

-- AUTO-AIM LOOP
RunService.RenderStepped:Connect(function()
    if not state.autoAim or not Camera or not RootPart then return end
    
    local targets = getTargets()
    if #targets > 0 then
        local best = targets[1]
        local predicted = predictAim(best.hrp)
        if predicted then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
            
            -- Visual lock-on line (Fictional tech)
            local line = Instance.new("Part")
            line.Size = Vector3.new(0.1, 0.1, 0.1)
            line.Anchored = true
            line.CanCollide = false
            line.Material = Enum.Material.Neon
            line.BrickColor = BrickColor.new("Bright red")
            line.Parent = Workspace
            local attachment = Instance.new("Attachment")
            attachment.Parent = line
            local att2 = Instance.new("Attachment")
            att2.Parent = best.hrp
            
            local beam = Instance.new("Beam")
            beam.Attachment0 = attachment
            beam.Attachment1 = att2
            beam.Width0 = 0.5
            beam.Width1 = 0.5
            beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 50))
            beam.Transparency = NumberSequence.new(0.3, 0.8)
            beam.Parent = line
            game:GetService("Debris"):AddItem(line, 0.1)
        end
    end
end)

-- UPDATE CHARACTER
local function updateChar()
    if not Humanoid then return end
    if state.speedBoost then
        Humanoid.WalkSpeed = math.clamp(state.walkSpeed * 2.8, 0, 150)
    else
        Humanoid.WalkSpeed = state.walkSpeed
    end
    
    if state.highJump then
        Humanoid.JumpPower = math.clamp(state.jumpPower * 2.0, 0, 180)
    else
        Humanoid.JumpPower = state.jumpPower
    end
end

RunService.Heartbeat:Connect(updateChar)
LocalPlayer.CharacterAdded:Connect(function()
    wait(0.5)
    getChar()
    updateChar()
end)

-- ==========================================
-- NEW HOLOGRAPHIC TOUCHPAD GUI (Sleek/Cyber)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XREY_HUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- MAIN PANEL (Floating Hologram)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 320)
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.25
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 200)
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- GLASS EFFECT
local glass = Instance.new("Frame")
glass.Size = UDim2.new(1, 0, 1, 0)
glass.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
glass.BackgroundTransparency = 0.95
glass.BorderSizePixel = 0
glass.Parent = mainFrame

-- TITLE BAR
local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
titleBar.BackgroundTransparency = 0.9
titleBar.Text = "≡ XREY PAD v4.0"
titleBar.TextColor3 = Color3.fromRGB(0, 255, 200)
titleBar.TextScaled = true
titleBar.Font = Enum.Font.Code
titleBar.Parent = mainFrame

-- HIDE BUTTON (Turns to Icon)
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 40, 0, 25)
hideBtn.Position = UDim2.new(1, -50, 0, 2)
hideBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
hideBtn.BackgroundTransparency = 0.8
hideBtn.Text = "⚡"
hideBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
hideBtn.TextScaled = true
hideBtn.Font = Enum.Font.Code
hideBtn.Parent = mainFrame

-- FLOATING ICON (Hidden state)
local iconFrame = Instance.new("ImageLabel")
iconFrame.Size = UDim2.new(0, 60, 0, 60)
iconFrame.Position = UDim2.new(1, -80, 0, 20)
iconFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
iconFrame.BackgroundTransparency = 0.85
iconFrame.BorderSizePixel = 2
iconFrame.BorderColor3 = Color3.fromRGB(0, 255, 200)
iconFrame.Image = "rbxassetid://4483345998" -- Cyber icon
iconFrame.Visible = false
iconFrame.Parent = screenGui
iconFrame.ZIndex = 999

-- BUTTONS (Sleek Touchpad)
local toggleData = {
    {name = "HIGH JUMP", key = "highJump", color = Color3.fromRGB(0, 200, 255)},
    {name = "DOUBLE JUMP", key = "doubleJump", color = Color3.fromRGB(255, 200, 0)},
    {name = "SPEED BOOST", key = "speedBoost", color = Color3.fromRGB(0, 255, 150)},
    {name = "AUTO-AIM", key = "autoAim", color = Color3.fromRGB(255, 50, 50)}
}

local yPos = 40
for _, data in ipairs(toggleData) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 45)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.4
    btn.BorderColor3 = data.color
    btn.BorderSizePixel = 2
    btn.Text = "🔘 " .. data.name .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.TextScaled = true
    btn.Font = Enum.Font.Code
    btn.Parent = mainFrame
    
    -- Hover glitch effect
    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.2
        btn.BorderSizePixel = 4
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0.4
        btn.BorderSizePixel = 2
    end)
    
    btn.MouseButton1Click:Connect(function()
        state[data.key] = not state[data.key]
        local status = state[data.key] and "[ON]" or "[OFF]"
        btn.Text = "🔘 " .. data.name .. " " .. status
        btn.BorderColor3 = state[data.key] and Color3.fromRGB(0, 255, 0) or data.color
        btn.TextColor3 = state[data.key] and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 220)
        updateChar()
        
        -- Haptic feedback
        if UserInput.VibrationEnabled then
            game:GetService("HapticService"):SetMotor("", 0.5, 0.1)
        end
    end)
    
    yPos = yPos + 55
end

-- TOUCHPAD STATUS
local statusDisplay = Instance.new("TextLabel")
statusDisplay.Size = UDim2.new(0.9, 0, 0, 25)
statusDisplay.Position = UDim2.new(0.05, 0, 0, yPos + 10)
statusDisplay.BackgroundTransparency = 1
statusDisplay.Text = "⚡ LOCK: NONE"
statusDisplay.TextColor3 = Color3.fromRGB(0, 255, 200)
statusDisplay.TextScaled = true
statusDisplay.Font = Enum.Font.Code
statusDisplay.Parent = mainFrame

-- TOGGLE VISIBILITY
local visible = true
hideBtn.MouseButton1Click:Connect(function()
    visible = not visible
    mainFrame.Visible = visible
    iconFrame.Visible = not visible
    
    if visible then
        hideBtn.Text = "⚡"
    else
        hideBtn.Text = "⊠"
    end
end)

-- ICON CLICK (Show GUI)
iconFrame.MouseButton1Click:Connect(function()
    visible = true
    mainFrame.Visible = true
    iconFrame.Visible = false
    hideBtn.Text = "⚡"
end)

-- DRAG SAFETY FOR ICON
iconFrame.Active = true
iconFrame.Draggable = true

-- AUTO-AIM STATUS UPDATE
RunService.RenderStepped:Connect(function()
    if state.autoAim then
        local targets = getTargets()
        if #targets > 0 then
            statusDisplay.Text = "⚡ LOCK: " .. targets[1].model.Name
            statusDisplay.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            statusDisplay.Text = "⚡ LOCK: SCANNING..."
            statusDisplay.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    else
        statusDisplay.Text = "⚡ LOCK: DISABLED"
        statusDisplay.TextColor3 = Color3.fromRGB(0, 255, 200)
    end
end)

-- MOBILE ADJUST
if UserInput.TouchEnabled then
    mainFrame.Size = UDim2.new(0, 280, 0, 360)
    mainFrame.Position = UDim2.new(0.5, -140, 0.5, -180)
    iconFrame.Size = UDim2.new(0, 75, 0, 75)
    iconFrame.Position = UDim2.new(1, -90, 0, 30)
end

-- INIT
print("mode: erafox - activated. tg - @erafox")
updateChar()
