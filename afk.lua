local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- ค่าตั้งต้น (ผู้ใช้ตั้งเองได้ด้วย getgenv() ก่อนโหลด)
local env = (getgenv and getgenv()) or _G
local delay = tonumber(env.Delay) or 1             -- เวลาห่างระหว่างคลิก (วินาที)
local keepAliveTime = tonumber(env.KeepAlive) or 60 -- ส่งอินพุตกันหลุดทุกกี่วินาที
local autoJump = env.AutoJump ~= false             -- กระโดดตอนกันหลุด (ค่าเริ่มต้น เปิด)
local clicking = env.AutoStart == true             -- เริ่มคลิกทันทีหรือไม่ (ค่าเริ่มต้น ปิด)
local count = 0
local alive = true

-- ปิดตัวเก่าถ้าเคยรันไว้แล้ว (กันรันซ้อน)
if env.AfkStop then pcall(env.AfkStop) end

-- เลือกที่วาง GUI
local ok, parent = pcall(function()
    return (gethui and gethui()) or game:GetService("CoreGui")
end)
if not ok or not parent then parent = player:WaitForChild("PlayerGui") end
if parent:FindFirstChild("AfkConsole") then parent.AfkConsole:Destroy() end

local function make(class, props, par)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = par
    return o
end

local gui = make("ScreenGui", {Name = "AfkConsole", ResetOnSpawn = false}, parent)
local main = make("Frame", {
    Size = UDim2.new(0, 250, 0, 230),
    Position = UDim2.new(0.5, -125, 0.3, 0),
    BackgroundColor3 = Color3.fromRGB(25, 25, 30),
    BorderSizePixel = 0,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, main)

-- แถบหัว (ลากได้)
local title = make("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(40, 40, 50),
    BorderSizePixel = 0,
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, title)
make("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "Anti-AFK Console",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
    TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, title)
local minBtn = make("TextButton", {
    Size = UDim2.new(0, 28, 0, 22), Position = UDim2.new(1, -62, 0, 4),
    BackgroundColor3 = Color3.fromRGB(70, 70, 85), Text = "-",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 16,
}, title)
local closeBtn = make("TextButton", {
    Size = UDim2.new(0, 28, 0, 22), Position = UDim2.new(1, -32, 0, 4),
    BackgroundColor3 = Color3.fromRGB(170, 60, 60), Text = "X",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14,
}, title)
make("UICorner", {}, minBtn)
make("UICorner", {}, closeBtn)

-- ส่วนเนื้อหา
local body = make("Frame", {
    Size = UDim2.new(1, 0, 1, -30), Position = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1,
}, main)

local status = make("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 6),
    BackgroundTransparency = 1, Text = "Status: OFF  |  Clicks: 0",
    TextColor3 = Color3.fromRGB(220, 220, 220), Font = Enum.Font.Gotham,
    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, body)

local toggle = make("TextButton", {
    Size = UDim2.new(1, -20, 0, 36), Position = UDim2.new(0, 10, 0, 32),
    BackgroundColor3 = Color3.fromRGB(50, 150, 80), Text = "START",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 16,
}, body)
make("UICorner", {}, toggle)

local minus = make("TextButton", {
    Size = UDim2.new(0, 40, 0, 28), Position = UDim2.new(0, 10, 0, 76),
    BackgroundColor3 = Color3.fromRGB(70, 70, 85), Text = "-",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18,
}, body)
local plus = make("TextButton", {
    Size = UDim2.new(0, 40, 0, 28), Position = UDim2.new(1, -50, 0, 76),
    BackgroundColor3 = Color3.fromRGB(70, 70, 85), Text = "+",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18,
}, body)
make("UICorner", {}, minus)
make("UICorner", {}, plus)
local delayLabel = make("TextLabel", {
    Size = UDim2.new(1, -110, 0, 28), Position = UDim2.new(0, 55, 0, 76),
    BackgroundTransparency = 1, Text = "Delay: 1.0 s",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 14,
}, body)

local logBox = make("TextLabel", {
    Size = UDim2.new(1, -20, 0, 76), Position = UDim2.new(0, 10, 0, 112),
    BackgroundColor3 = Color3.fromRGB(15, 15, 18), BorderSizePixel = 0,
    Text = "", TextColor3 = Color3.fromRGB(120, 255, 150),
    Font = Enum.Font.Code, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
}, body)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, logBox)

-- log
local lines = {}
local function log(msg)
    table.insert(lines, os.date("%H:%M:%S") .. " " .. msg)
    if #lines > 5 then table.remove(lines, 1) end
    logBox.Text = table.concat(lines, "\n")
end

local function refresh()
    status.Text = ("Status: %s  |  Clicks: %d"):format(clicking and "ON" or "OFF", count)
    delayLabel.Text = ("Delay: %.1f s"):format(delay)
    toggle.Text = clicking and "STOP" or "START"
    toggle.BackgroundColor3 = clicking and Color3.fromRGB(170, 60, 60) or Color3.fromRGB(50, 150, 80)
end

-- ปุ่มต่างๆ
toggle.MouseButton1Click:Connect(function()
    clicking = not clicking
    log(clicking and "Auto click ON" or "Auto click OFF")
    refresh()
end)
minus.MouseButton1Click:Connect(function()
    delay = math.max(0.1, delay - 0.1)
    refresh()
end)
plus.MouseButton1Click:Connect(function()
    delay = delay + 0.1
    refresh()
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized and UDim2.new(0, 250, 0, 30) or UDim2.new(0, 250, 0, 230)
end)

local function stopAll()
    alive = false
    clicking = false
    if gui then gui:Destroy() end
end
env.AfkStop = stopAll
closeBtn.MouseButton1Click:Connect(stopAll)

-- ลากหน้าต่าง
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, i.Position, main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ปิดตัวตรวจ idle ของ Roblox (ถ้า Delta รองรับ) ต้องทำก่อนผูกตัวของเรา
pcall(function()
    for _, c in ipairs(getconnections(player.Idled)) do
        c:Disable()
    end
end)

-- กันหลุดชั้นที่ 1: จำลองคลิกเมื่อ idle
player.Idled:Connect(function()
    if not alive then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    log("Anti-AFK triggered")
end)

-- กันหลุดชั้นที่ 2: ส่งอินพุตจริงเป็นระยะ
task.spawn(function()
    while alive do
        task.wait(keepAliveTime)
        if not alive then break end
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end)
        if autoJump then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Jump = true end
        end
        log("Keep-alive sent")
    end
end)

-- ลูปคลิกอัตโนมัติ
task.spawn(function()
    while alive do
        if clicking then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
            count += 1
            refresh()
        end
        task.wait(delay)
    end
end)

log("Anti-AFK ready")
refresh()
