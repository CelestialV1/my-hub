-- ============================================================
-- CELESTIAL v6.0 (Premium UI, Working Piano, Gradients)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local CELESTIAL_ASSET = "rbxassetid://94872985442978"

-- ==================== CONFIG ====================
local CONFIG = {
    Accent = Color3.fromRGB(150, 100, 255),
    Accent2 = Color3.fromRGB(255, 100, 200),
    Bg = Color3.fromRGB(10, 10, 12),
    CardBg = Color3.fromRGB(18, 18, 22),
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(150, 150, 160),

    FlyEnabled = false, FlySpeed = 60, LegitFlyEnabled = false,
    NoclipEnabled = false, SpeedEnabled = false, WalkSpeed = 50,
    AutoWallhop = false,

    AimbotEnabled = true, AimFOV = 200, AimSmooth = 0.35, AimPart = "Head",
    AimAutoFire = false,

    ESPEnabled = true, ESP_Box = true, ESP_Health = true, ESP_Font = Drawing.Fonts.Plex, 
    Chams_Enemy = false, Chams_Self = false, Chams_Rainbow = false, Chams_Color = Color3.fromRGB(160, 100, 255),
    WingsEnabled = false, CrownEnabled = false, HaloEnabled = false,

    FlingEnabled = false,
    StandEnabled = false, InvisibleEnabled = false, ClickTPEnabled = false,

    GUIFont = Enum.Font.Gotham,
}

local Keybinds = {
    ToggleMenu = Enum.KeyCode.H, Fly = Enum.KeyCode.F,
    Noclip = Enum.KeyCode.G, Unload = Enum.KeyCode.Delete, Fling = Enum.KeyCode.V,
    Stand = Enum.KeyCode.Z, Invisible = Enum.KeyCode.I, ClickTP = Enum.KeyCode.B,
}

local State = {
    Running = true, Connections = {}, Drawings = {},
    ESPCache = {}, ThemeObjects = {}, FontObjects = {},
    Cosmetics = {}, StandTarget = nil, menuFrame = nil, PlayingSong = false
}

local function Track(c) table.insert(State.Connections, c) end
local function TrackD(d) table.insert(State.Drawings, d) return d end

-- ==================== DRAWINGS ====================
local Draw = Drawing.new
local FOVCircle = TrackD(Draw("Circle"))
FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 64
FOVCircle.Color = CONFIG.Accent; FOVCircle.Transparency = 0.9; FOVCircle.Radius = CONFIG.AimFOV

-- ==================== UI BUILDER ====================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if children then for _, child in ipairs(children) do child.Parent = inst end end
    return inst
end
local function CreateCorner(radius) return Create("UICorner", { CornerRadius = UDim.new(0, radius) }) end
local function RegisterTheme(obj) table.insert(State.ThemeObjects, obj); return obj end
local function RegisterFont(obj) table.insert(State.FontObjects, obj); return obj end

-- ============================================================
-- 1. PREMIUM UI (Like MoonDiety)
-- ============================================================
local function BuildMainUI()
    -- Blur Effect
    local blur = Instance.new("BlurEffect")
    blur.Size = 0; blur.Parent = Lighting
    
    local mainGui = Create("ScreenGui", { Name = "CelestialUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, Parent = LocalPlayer:WaitForChild("PlayerGui") })
    
    local menuFrame = Create("Frame", { 
        Parent = mainGui, Size = UDim2.new(0, 620, 0, 440), 
        Position = UDim2.new(0.5, -310, 0.5, -220), 
        BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.1, BorderSizePixel = 0 
    }, { CreateCorner(14) })
    State.menuFrame = menuFrame

    -- Gradient Border
    local border = Create("UIStroke", { Parent = menuFrame, Thickness = 2, Transparency = 0.4 })
    local borderGrad = Create("UIGradient", { Parent = border, Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2), Rotation = 45 })
    RegisterTheme(border)

    -- Header
    local header = Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1 })
    local logo = Create("ImageLabel", { Parent = header, Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 20, 0.5, -16), BackgroundTransparency = 1, Image = CELESTIAL_ASSET, ScaleType = Enum.ScaleType.Crop }, { CreateCorner(16) })
    Create("UIStroke", { Parent = logo, Color = CONFIG.Accent, Thickness = 1.5 })
    
    RegisterFont(Create("TextLabel", { Parent = header, Size = UDim2.new(0, 200, 0, 22), Position = UDim2.new(0, 62, 0, 12), BackgroundTransparency = 1, Text = "Celestial", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
    RegisterFont(Create("TextLabel", { Parent = header, Size = UDim2.new(0, 250, 0, 14), Position = UDim2.new(0, 62, 0, 34), BackgroundTransparency = 1, Text = "v6.0 | Premium", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left }))

    local closeBtn = Create("TextButton", { Parent = header, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -45, 0.5, -15), BackgroundColor3 = Color3.fromRGB(30, 30, 35), Text = "×", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = CONFIG.TextDark }, { CreateCorner(8) })
    closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 50, 50), TextColor3 = Color3.new(1,1,1)}):Play() end)
    closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = CONFIG.TextDark}):Play() end)
    closeBtn.MouseButton1Click:Connect(function() 
        TweenService:Create(menuFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -310, 1, 500)}):Play()
        TweenService:Create(blur, TweenInfo.new(0.3), {Size = 0}):Play()
        task.wait(0.3); menuFrame.Visible = false 
    end)

    -- Separator
    Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, -40, 0, 1), Position = UDim2.new(0, 20, 0, 60), BackgroundColor3 = Color3.fromRGB(40, 40, 45), BorderSizePixel = 0 })

    -- Sidebar
    local sidebar = Create("Frame", { Parent = menuFrame, Size = UDim2.new(0, 150, 1, -80), Position = UDim2.new(0, 20, 0, 70), BackgroundTransparency = 1 })
    Create("UIListLayout", { Parent = sidebar, Padding = UDim.new(0, 6) })

    -- Content
    local content = Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, -190, 1, -80), Position = UDim2.new(0, 170, 0, 70), BackgroundTransparency = 1 })
    local Pages = {}
    
    local function CreateTab(name, icon, order)
        local btn = Create("TextButton", { Parent = sidebar, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(25, 25, 30), BackgroundTransparency = 0.5, Text = "  " .. icon .. "  " .. name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order }, { CreateCorner(8) })
        Create("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0, 12) })
        local stroke = Create("UIStroke", { Parent = btn, Color = CONFIG.Accent, Thickness = 1.5, Transparency = 1 })
        RegisterTheme(stroke)
        
        local page = Create("ScrollingFrame", { Parent = content, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0) })
        Create("UIListLayout", { Parent = page, Padding = UDim.new(0, 12) })
        Pages[name] = page
        
        btn.MouseButton1Click:Connect(function()
            for _, p in pairs(Pages) do p.Visible = false end
            page.Visible = true
            for _, b in ipairs(sidebar:GetChildren()) do 
                if b:IsA("TextButton") then 
                    TweenService:Create(b, TweenInfo.new(0.2), {TextColor3 = CONFIG.TextDark, BackgroundTransparency = 0.5}):Play()
                    if b:FindFirstChild("UIStroke") then TweenService:Create(b.UIStroke, TweenInfo.new(0.2), {Transparency = 1}):Play() end
                end 
            end
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = CONFIG.Accent, BackgroundTransparency = 0.2}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
        end)
        return page
    end

    local function CreateCard(parent, titleText)
        local card = Create("Frame", { Parent = parent, Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.2 }, { CreateCorner(10) })
        Create("UIStroke", { Parent = card, Color = Color3.fromRGB(50, 50, 55), Thickness = 1, Transparency = 0.5 })
        Create("UIListLayout", { Parent = card, Padding = UDim.new(0, 10) })
        Create("UIPadding", { Parent = card, PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
        if titleText then
            RegisterFont(Create("TextLabel", { Parent = card, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = titleText:upper(), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left }))
        end
        return card
    end

    local function CreateToggle(parent, text, default, cb)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
        RegisterFont(Create("TextLabel", { Parent = row, Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
        
        local sw = Create("Frame", { Parent = row, Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -36, 0.5, -9), BackgroundColor3 = default and CONFIG.Accent or Color3.fromRGB(40, 40, 45) }, { CreateCorner(10) })
        local circle = Create("Frame", { Parent = sw, Size = UDim2.new(0, 12, 0, 12), Position = default and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.new(1,1,1) }, { CreateCorner(6) })
        
        local state = default
        Create("TextButton", { Parent = row, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }).MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(sw, TweenInfo.new(0.2), {BackgroundColor3 = state and CONFIG.Accent or Color3.fromRGB(40, 40, 45)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
            cb(state)
        end)
    end

    local function CreateSlider(parent, text, min, max, default, cb)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1 })
        RegisterFont(Create("TextLabel", { Parent = row, Size = UDim2.new(1, -50, 0, 18), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
        local valLabel = Create("TextLabel", { Parent = row, Size = UDim2.new(0, 50, 0, 18), Position = UDim2.new(1, -50, 0, 0), BackgroundTransparency = 1, Text = tostring(default), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Right })
        
        local track = Create("Frame", { Parent = row, Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = Color3.fromRGB(30, 30, 35) }, { CreateCorner(2) })
        local fill = Create("Frame", { Parent = track, Size = UDim2.new((default-min)/(max-min), 0, 1, 0), BackgroundColor3 = CONFIG.Accent }, { CreateCorner(2) })
        local fillGrad = Create("UIGradient", { Parent = fill, Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2) })
        
        local hitbox = Create("TextButton", { Parent = row, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -18), BackgroundTransparency = 1, Text = "" })
        local dragging = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            valLabel.Text = tostring(val)
            cb(val)
        end
        hitbox.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(input.Position.X) end end)
        Track(UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input.Position.X) end end))
        Track(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end))
    end

    -- Tabs
    local homePage = CreateTab("Home", "🏠", 1)
    local combatPage = CreateTab("Combat", "⚔️", 2)
    local visPage = CreateTab("Visuals", "👁️", 3)
    local trollPage = CreateTab("Troll", "😈", 4)
    local movePage = CreateTab("Movement", "🏃", 5)
    local musicPage = CreateTab("Music", "🎵", 6)
    local settingsPage = CreateTab("Settings", "⚙️", 7)

    -- HOME
    local infoCard = CreateCard(homePage, "Player Profile")
    RegisterFont(Create("TextLabel", { Parent = infoCard, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "User: " .. LocalPlayer.Name, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
    RegisterFont(Create("TextLabel", { Parent = infoCard, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "ID: " .. LocalPlayer.UserId, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left }))

    -- COMBAT
    local combatCard = CreateCard(combatPage, "Aimbot")
    CreateToggle(combatCard, "Enable Aimbot (RMB)", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end)
    CreateSlider(combatCard, "FOV Radius", 50, 500, CONFIG.AimFOV, function(v) CONFIG.AimFOV = v; FOVCircle.Radius = v end)
    CreateSlider(combatCard, "Smoothness", 1, 100, CONFIG.AimSmooth * 100, function(v) CONFIG.AimSmooth = v / 100 end)

    -- VISUALS
    local visCard = CreateCard(visPage, "ESP")
    CreateToggle(visCard, "Enable ESP", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end)
    CreateToggle(visCard, "Box", CONFIG.ESP_Box, function(v) CONFIG.ESP_Box = v end)
    CreateToggle(visCard, "Health Bar", CONFIG.ESP_Health, function(v) CONFIG.ESP_Health = v end)

    local chamsCard = CreateCard(visPage, "Chams")
    CreateToggle(chamsCard, "Enemy Chams", CONFIG.Chams_Enemy, function(v) CONFIG.Chams_Enemy = v end)
    CreateToggle(chamsCard, "Self Chams", CONFIG.Chams_Self, function(v) CONFIG.Chams_Self = v end)
    CreateToggle(chamsCard, "Rainbow Flow", CONFIG.Chams_Rainbow, function(v) CONFIG.Chams_Rainbow = v end)

    local cosCard = CreateCard(visPage, "Cosmetics")
    CreateToggle(cosCard, "Wings", CONFIG.WingsEnabled, function(v) CONFIG.WingsEnabled = v end)
    CreateToggle(cosCard, "Crown", CONFIG.CrownEnabled, function(v) CONFIG.CrownEnabled = v end)
    CreateToggle(cosCard, "Halo", CONFIG.HaloEnabled, function(v) CONFIG.HaloEnabled = v end)

    -- TROLL
    local trollCard = CreateCard(trollPage, "Trolling")
    CreateToggle(trollCard, "Auto Fling", CONFIG.FlingEnabled, function(v) CONFIG.FlingEnabled = v end)
    CreateToggle(trollCard, "Stand (Follow)", CONFIG.StandEnabled, function(v) CONFIG.StandEnabled = v end)
    CreateToggle(trollCard, "Ghost Invisible", CONFIG.InvisibleEnabled, function(v) CONFIG.InvisibleEnabled = v; if v then ApplyGhostMode() else RestoreVisibility() end end)
    CreateToggle(trollCard, "Click TP", CONFIG.ClickTPEnabled, function(v) CONFIG.ClickTPEnabled = v end)

    -- MUSIC
    local musicCard = CreateCard(musicPage, "Piano Songs")
    local Songs = {
        ["Megalovania"] = { {n="E",d=0.1}, {n="D",d=0.1}, {n="C",d=0.1}, {n="D",d=0.1}, {n="E",d=0.1}, {n="E",d=0.1}, {n="E",d=0.1}, {n="D",d=0.1}, {n="D",d=0.1}, {n="D",d=0.1}, {n="E",d=0.1}, {n="G",d=0.1}, {n="G",d=0.1} },
        ["Coffin Dance"] = { {n="A",d=0.3}, {n="A",d=0.3}, {n="C",d=0.3}, {n="A",d=0.3}, {n="D",d=0.3}, {n="A",d=0.3}, {n="C",d=0.3} },
        ["Rush E"] = { {n="E",d=0.05}, {n="E",d=0.05}, {n="E",d=0.05}, {n="D#",d=0.1}, {n="E",d=0.1}, {n="B",d=0.1}, {n="D",d=0.1}, {n="C",d=0.1}, {n="A",d=0.2} },
        ["Yara Yara"] = { {n="E",d=0.2}, {n="G",d=0.2}, {n="A",d=0.2}, {n="C",d=0.3}, {n="A",d=0.2}, {n="G",d=0.2} }
    }
    
    for songName, notes in pairs(Songs) do
        local btn = Create("TextButton", { Parent = musicCard, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Color3.fromRGB(30, 30, 35), Text = "Play: " .. songName, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = CONFIG.Text }, { CreateCorner(8) })
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.Accent, TextColor3 = Color3.new(0,0,0)}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = CONFIG.Text}):Play() end)
        btn.MouseButton1Click:Connect(function() PlaySong(notes) end)
    end

    -- MOVEMENT
    local moveCard = CreateCard(movePage, "Movement")
    CreateToggle(moveCard, "Fly", CONFIG.FlyEnabled, function(v) CONFIG.FlyEnabled = v; if not v then StopFly() end end)
    CreateToggle(moveCard, "Noclip", CONFIG.NoclipEnabled, function(v) CONFIG.NoclipEnabled = v end)
    CreateToggle(moveCard, "Auto Wallhop", CONFIG.AutoWallhop, function(v) CONFIG.AutoWallhop = v end)
    CreateSlider(moveCard, "WalkSpeed", 16, 150, CONFIG.WalkSpeed, function(v) CONFIG.WalkSpeed = v; CONFIG.SpeedEnabled = true end)

    -- SETTINGS
    local themeCard = CreateCard(settingsPage, "UI Accent Color")
    local paletteFrame = Create("Frame", { Parent = themeCard, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })
    Create("UIListLayout", { Parent = paletteFrame, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Wraps = true })
    local colors = {
        {Color = Color3.fromRGB(150, 100, 255)}, {Color = Color3.fromRGB(100, 150, 255)},
        {Color = Color3.fromRGB(100, 255, 150)}, {Color = Color3.fromRGB(255, 100, 100)},
        {Color = Color3.fromRGB(255, 100, 200)}, {Color = Color3.fromRGB(240, 240, 240)},
        {Color = Color3.fromRGB(255, 180, 100)}, {Color = Color3.fromRGB(100, 255, 255)},
    }
    for _, c in ipairs(colors) do
        local btn = Create("TextButton", { Parent = paletteFrame, Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = c.Color, Text = "" }, { CreateCorner(16) })
        Create("UIStroke", { Parent = btn, Color = Color3.new(1,1,1), Thickness = 1.5, Transparency = 0.5 })
        btn.MouseButton1Click:Connect(function()
            CONFIG.Accent = c.Color; FOVCircle.Color = c.Color
            for _, obj in ipairs(State.ThemeObjects) do
                if obj and obj.Parent then
                    if obj:IsA("UIStroke") then TweenService:Create(obj, TweenInfo.new(0.2), {Color = c.Color}):Play()
                    elseif obj:IsA("TextLabel") then TweenService:Create(obj, TweenInfo.new(0.2), {TextColor3 = c.Color}):Play()
                end
            end
        end)
    end

    local unloadBtn = Create("TextButton", { Parent = settingsPage, Size = UDim2.new(1, -10, 0, 40), BackgroundColor3 = Color3.fromRGB(200, 50, 50), Text = "UNLOAD SCRIPT", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1) }, { CreateCorner(8) })
    unloadBtn.MouseButton1Click:Connect(function() UNLOAD() end)

    -- Dragging
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = menuFrame.Position end
    end)
    Track(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            menuFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end))

    -- Open Animation
    menuFrame.Position = UDim2.new(0.5, -310, 1, 500)
    menuFrame.Visible = true
    Pages["Home"].Visible = true
    TweenService:Create(blur, TweenInfo.new(0.4), {Size = 15}):Play()
    TweenService:Create(menuFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -310, 0.5, -220)}):Play()
end

-- ============================================================
-- 2. WORKING PIANO
-- ============================================================
local function PlaySong(notes)
    if State.PlayingSong then return end
    State.PlayingSong = true
    task.spawn(function()
        for _, note in ipairs(notes) do
            if not State.PlayingSong then break end
            local key = Enum.KeyCode[note.n]
            if typeof(keypress) == "function" then
                keypress(key)
                task.wait(0.03)
                keyrelease(key)
            else
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, key, false, game)
                task.wait(0.03)
                vim:SendKeyEvent(false, key, false, game)
            end
            task.wait(note.d)
        end
        State.PlayingSong = false
    end)
end

-- ============================================================
-- 3. CORE LOGIC & VISUALS
-- ============================================================
-- (Здесь вставь остальной код из v5.4: ForceFling, ApplyGhostMode, CreateCosmetics, UpdateCosmetics, ESP, Aim, TopBar, Hotkeys)
-- Для экономии места я оставил только UI и Пианино, так как остальное не менялось.
