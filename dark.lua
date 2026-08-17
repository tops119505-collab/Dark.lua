--[[
   XREY MOBILE SCRIPT v3.1
   NEON_ZERO BLACK MARKET BUILD
   // Compile: Roblox Lua (Client-Side)
   // Features: HighJump, DoubleJump, SpeedBoost, GUI Toggle
   // Mobile/PC/Tablet Optimized
--]]

-- SERVICES
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- STATE
local playerState = {
    highJump = false,
    doubleJump = false,
    speedBoost = false,
    jumpCount = 0,
    maxJumps = 1,
    walkSpeed = 16,
    jumpPower = 50
}

-- CORE FUNCTIONS (Heavily Obfuscated Tech)
local function updateCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not Character or not Character:FindFirstChild("Humanoid") then return end
    local humanoid = Character:FindFirstChild("Humanoid")
    
    if playerState.speedBoost then
        humanoid.WalkSpeed = math.clamp(playerState.walkSpeed * 2.4, 0, 120)
    else
        humanoid.WalkSpeed = playerState.walkSpeed
    end
    
    if playerState.highJump then
        humanoid.JumpPower = math.clamp(playerState.jumpPower * 1.8, 0, 150)
    else
        humanoid.JumpPower = playerState.jumpPower
    end
end

-- DOUBLE JUMP LOGIC (Fictional Bypass Protocol)
local function handleJump()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not Character or not Character:FindFirstChild("Humanoid") then return end
    local humanoid = Character:FindFirstChild("Humanoid")
    
    if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
        playerState.jumpCount = playerState.jumpCount + 1
    elseif humanoid:GetState() == Enum.HumanoidStateType.Landed or humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        playerState.jumpCount = 0
    end
    
    if playerState.doubleJump and playerState.jumpCount < 2 then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        playerState.jumpCount = playerState.jumpCount + 1
    end
end

-- EVENT HOOKS
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    wait(0.5)
    updateCharacter()
end)

RunService.Heartbeat:Connect(function()
    if Character and Character:FindFirstChild("Humanoid") then
        updateCharacter()
    end
end)

UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.Touch then
        handleJump()
    end
end)

-- GUI SYSTEM (Mobile Responsive)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XREY_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 280)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 200)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "XREY v3.1 // NEON"
title.TextColor3 = Color3.fromRGB(0, 255, 200)
title.TextScaled = true
title.Font = Enum.Font.Code
title.Parent = mainFrame

-- Toggle Button (Hide/Show)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 60, 0, 25)
toggleBtn.Position = UDim2.new(1, -70, 0, 5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
toggleBtn.Text = "[-]"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.Code
toggleBtn.Parent = mainFrame

local hidden = false
toggleBtn.MouseButton1Click:Connect(function()
    hidden = not hidden
    mainFrame.Visible = not hidden
    toggleBtn.Text = hidden and "[+]" or "[-]"
end)

-- BUTTONS
local buttons = {
    {name = "High Jump", state = "highJump", y = 40},
    {name = "Double Jump", state = "doubleJump", y = 80},
    {name = "Speed Boost", state = "speedBoost", y = 120}
}

for _, btnData in ipairs(buttons) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, btnData.y)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    btn.BorderColor3 = Color3.fromRGB(0, 200, 150)
    btn.BorderSizePixel = 1
    btn.Text = btnData.name .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.TextScaled = true
    btn.Font = Enum.Font.Code
    btn.Parent = mainFrame
    
    btn.MouseButton1Click:Connect(function()
        playerState[btnData.state] = not playerState[btnData.state]
        btn.Text = btnData.name .. (playerState[btnData.state] and " [ON]" or " [OFF]")
        btn.BackgroundColor3 = playerState[btnData.state] and Color3.fromRGB(0, 80, 60) or Color3.fromRGB(25, 25, 45)
        updateCharacter()
    end)
end

-- CLOSE BUTTON (Emergency)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 30)
closeBtn.Position = UDim2.new(0.5, -40, 0, 170)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 10, 10)
closeBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.BorderSizePixel = 2
closeBtn.Text = "KILL"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.Code
closeBtn.Parent = mainFrame

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    print("[XREY] System terminated. tg - @erafox")
end)

-- STATUS LABEL (In-Game Feedback)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.new(0, 0, 0, 210)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Active // NS"
statusLabel.TextColor3 = Color3.fromRGB(0, 200, 150)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Code
statusLabel.Parent = mainFrame

-- Mobile Safe Zone Adjust
if UserInput.TouchEnabled then
    mainFrame.Size = UDim2.new(0, 220, 0, 300)
    mainFrame.Position = UDim2.new(0, 5, 0, 20)
end

-- INIT
print("mode: erafox - activated. tg - @erafox")
updateCharacter()
