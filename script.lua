-- ============================================================
-- CELESTIAL v6.1 (Full Working: UI, Piano, Ghost, Fling, Wallhop)
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

    FlyEnabled = false, FlySpeed = 60,
    NoclipEnabled = false, SpeedEnabled = false, WalkSpeed = 50,
    AutoWallhop = false,

    AimbotEnabled = true, AimFOV = 200, AimSmooth = 0.35,
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
    Cosmetics = {}, StandTarget = nil, menuFrame = nil, 
    PlayingSong = false, WallhopCooldown = 0
}

local function Track(c) table.insert(State.Connections, c) end
local function TrackD(d) table.insert(State.Drawings, d) return d end

local Draw = Drawing.new
local FOVCircle = TrackD(Draw("Circle"))
FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 64
FOVCircle.Color = CONFIG.Accent; FOVCircle.Transparency = 0.9; FOVCircle.Radius = CONFIG.AimFOV

-- ============================================================
-- CORE HELPERS
-- ============================================================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if children then for _, child in ipairs(children) do child.Parent = inst end end
    return inst
end
local function CreateCorner(r) return Create("UICorner", { CornerRadius = UDim.new(0, r) }) end

local function ApplyGhostMode()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then v.Transparency = 1; v.CanCollide = false
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.NameDisplayDistance = 0; hum.HealthDisplayDistance = 0
    end
end
local function RestoreVisibility()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then v.Transparency = 0; v.CanCollide = true
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 0 end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        hum.NameDisplayDistance = 100; hum.HealthDisplayDistance = 100
    end
end
local function ApplyChams(character)
    if not character then return end
    local hl = character:FindFirstChild("CelestialChams") or Instance.new("Highlight")
    hl.Name = "CelestialChams"; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    hl.FillColor = CONFIG.Chams_Rainbow and Color3.fromHSV(tick() % 1, 1, 1) or CONFIG.Chams_Color
    hl.OutlineColor = hl.FillColor; hl.Parent = character
end
local function RemoveChams(character)
    if character and character:FindFirstChild("CelestialChams") then character.CelestialChams:Destroy() end
end
local function ForceFling(targetChar)
    local hrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    local hum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    pcall(function()
        hrp:SetNetworkOwner(LocalPlayer)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        hrp.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5)
        hrp.AssemblyAngularVelocity = Vector3.new(1e5, 1e5, 1e5)
    end)
end

-- ============================================================
-- COSMETICS
-- ============================================================
local function CreateCosmetics()
    local char = LocalPlayer.Character
    if not char then return end
    local haloModel = Instance.new("Model", Workspace); haloModel.Name = "CelestialHalo"
    for i = 1, 16 do
        local ball = Instance.new("Part", haloModel)
        ball.Shape = Enum.PartType.Ball; ball.Size = Vector3.new(0.3, 0.3, 0.3)
        ball.Material = Enum.Material.Neon; ball.Color = CONFIG.Accent
        ball.Transparency = 0.1; ball.CanCollide = false; ball.Anchored = true
    end
    State.Cosmetics.Halo = haloModel

    local crownPart = Instance.new("Part", Workspace); crownPart.Name = "CelestialCrown"
    crownPart.Size = Vector3.new(1, 1, 1); crownPart.Transparency = 1; crownPart.CanCollide = false; crownPart.Anchored = true
    local mesh = Instance.new("SpecialMesh", crownPart); mesh.MeshType = Enum.MeshType.FileMesh; mesh.MeshId = "rbxassetid://176213013"; mesh.Scale = Vector3.new(0.8, 0.8, 0.8)
    State.Cosmetics.Crown = crownPart

    local wingModel = Instance.new("Model", Workspace); wingModel.Name = "CelestialWings"
    local leftWing = Instance.new("Part", wingModel); leftWing.Size = Vector3.new(5, 5, 1)
    leftWing.Transparency = 0.2; leftWing.CanCollide = false; leftWing.Anchored = true
    leftWing.Material = Enum.Material.Neon; leftWing.Color = CONFIG.Accent
    local meshL = Instance.new("SpecialMesh", leftWing); meshL.MeshType = Enum.MeshType.FileMesh; meshL.MeshId = "rbxassetid://101952033"; meshL.Scale = Vector3.new(1.5, 1.5, 1.5)
    local rightWing = leftWing:Clone(); rightWing.Parent = wingModel
    State.Cosmetics.Wings = wingModel
end

local function UpdateCosmetics()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if State.Cosmetics.Halo and head then
        State.Cosmetics.Halo.Parent = CONFIG.HaloEnabled and Workspace or nil
        if CONFIG.HaloEnabled then
            for i, ball in ipairs(State.Cosmetics.Halo:GetChildren()) do
                local angle = (i / 16) * math.pi * 2 + tick() * 2
                ball.CFrame = head.CFrame * CFrame.new(math.cos(angle) * 1.5, 1.2, math.sin(angle) * 1.5)
                ball.Color = CONFIG.Accent
            end
        end
    end
    if State.Cosmetics.Crown and head then
        State.Cosmetics.Crown.Parent = CONFIG.CrownEnabled and Workspace or nil
        if CONFIG.CrownEnabled then
            State.Cosmetics.Crown.CFrame = head.CFrame * CFrame.new(0, 0.6, 0)
            for _, v in ipairs(State.Cosmetics.Crown:GetChildren()) do if v:IsA("Mesh") then v.VertexColor = CONFIG.Accent end end
        end
    end
    if State.Cosmetics.Wings and hrp then
        State.Cosmetics.Wings.Parent = CONFIG.WingsEnabled and Workspace or nil
        if CONFIG.WingsEnabled then
            local L, R = State.Cosmetics.Wings:FindFirstChild("LeftWing"), State.Cosmetics.Wings:FindFirstChild("RightWing")
            if L and R then
                L.CFrame = hrp.CFrame * CFrame.new(-1, 1, 0.5) * CFrame.Angles(0, math.rad(-20), math.rad(20))
                R.CFrame = hrp.CFrame * CFrame.new(1, 1, 0.5) * CFrame.Angles(0, math.rad(20), math.rad(-20))
                L.Color = CONFIG.Accent; R.Color = CONFIG.Accent
            end
        end
    end
end

-- ============================================================
-- PREMIUM UI & PIANO
-- ============================================================
local function PlaySong(notes)
    if State.PlayingSong then return end
    State.PlayingSong = true
    task.spawn(function()
        for _, note in ipairs(notes) do
            if not State.PlayingSong then break end
            local key = Enum.KeyCode[note.n]
            if typeof(keypress) == "function" then
                pcall(function() keypress(key); task.wait(0.02); keyrelease(key) end)
            else
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendKeyEvent(true, key, false, game); task.wait(0.02); vim:SendKeyEvent(false, key, false, game)
                end)
            end
            task.wait(note.d)
        end
        State.PlayingSong = false
    end)
end

local function BuildMainUI()
    local blur = Instance.new("BlurEffect"); blur.Size = 0; blur.Parent = Lighting
    local mainGui = Create("ScreenGui", { Name = "CelestialUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, Parent = LocalPlayer:WaitForChild("PlayerGui") })
    
    local menuFrame = Create("Frame", { Parent = mainGui, Size = UDim2.new(0, 620, 0, 440), Position = UDim2.new(0.5, -310, 0.5, -220), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.1, BorderSizePixel = 0 }, { CreateCorner(14) })
    State.menuFrame = menuFrame

    local border = Create("UIStroke", { Parent = menuFrame, Thickness = 2, Transparency = 0.4 })
    Create("UIGradient", { Parent = border, Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2), Rotation = 45 })

    local header = Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1 })
    local logo = Create("ImageLabel", { Parent = header, Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 20, 0.5, -16), BackgroundTransparency = 1, Image = CELESTIAL_ASSET, ScaleType = Enum.ScaleType.Crop }, { CreateCorner(16) })
    Create("UIStroke", { Parent = logo, Color = CONFIG.Accent, Thickness = 1.5 })
    
    Create("TextLabel", { Parent = header, Size = UDim2.new(0, 200, 0, 22), Position = UDim2.new(0, 62, 0, 12), BackgroundTransparency = 1, Text = "Celestial", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left })
    Create("TextLabel", { Parent = header, Size = UDim2.new(0, 250, 0, 14), Position = UDim2.new(0, 62, 0, 34), BackgroundTransparency = 1, Text = "v6.1 | Premium", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left })

    local closeBtn = Create("TextButton", { Parent = header, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -45, 0.5, -15), BackgroundColor3 = Color3.fromRGB(30, 30, 35), Text = "×", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = CONFIG.TextDark }, { CreateCorner(8) })
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(menuFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -310, 1, 500)}):Play()
        TweenService:Create(blur, TweenInfo.new(0.3), {Size = 0}):Play()
        task.wait(0.3); menuFrame.Visible = false 
    end)

    Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, -40, 0, 1), Position = UDim2.new(0, 20, 0, 60), BackgroundColor3 = Color3.fromRGB(40, 40, 45), BorderSizePixel = 0 })

    local sidebar = Create("Frame", { Parent = menuFrame, Size = UDim2.new(0, 150, 1, -80), Position = UDim2.new(0, 20, 0, 70), BackgroundTransparency = 1 })
    Create("UIListLayout", { Parent = sidebar, Padding = UDim.new(0, 6) })
    local content = Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, -190, 1, -80), Position = UDim2.new(0, 170, 0, 70), BackgroundTransparency = 1 })
    local Pages = {}
    
    local function CreateTab(name, icon, order)
        local btn = Create("TextButton", { Parent = sidebar, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(25, 25, 30), BackgroundTransparency = 0.5, Text = "  " .. icon .. "  " .. name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order }, { CreateCorner(8) })
        Create("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0, 12) })
        local stroke = Create("UIStroke", { Parent = btn, Color = CONFIG.Accent, Thickness = 1.5, Transparency = 1 })
        local page = Create("ScrollingFrame", { Parent = content, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0) })
        Create("UIListLayout", { Parent = page, Padding = UDim.new(0, 12) })
        Pages[name] = page
        btn.MouseButton1Click:Connect(function()
            for _, p in pairs(Pages) do p.Visible = false end
            page.Visible = true
            for _, b in ipairs(sidebar:GetChildren()) do if b:IsA("TextButton") then TweenService:Create(b, TweenInfo.new(0.2), {TextColor3 = CONFIG.TextDark, BackgroundTransparency = 0.5}):Play(); if b:FindFirstChild("UIStroke") then TweenService:Create(b.UIStroke, TweenInfo.new(0.2), {Transparency = 1}):Play() end end end
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
        if titleText then Create("TextLabel", { Parent = card, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = titleText:upper(), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left }) end
        return card
    end

    local function CreateToggle(parent, text, default, cb)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
        Create("TextLabel", { Parent = row, Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left })
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
        Create("TextLabel", { Parent = row, Size = UDim2.new(1, -50, 0, 18), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left })
        local valLabel = Create("TextLabel", { Parent = row, Size = UDim2.new(0, 50, 0, 18), Position = UDim2.new(1, -50, 0, 0), BackgroundTransparency = 1, Text = tostring(default), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Right })
        local track = Create("Frame", { Parent = row, Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = Color3.fromRGB(30, 30, 35) }, { CreateCorner(2) })
        local fill = Create("Frame", { Parent = track, Size = UDim2.new((default-min)/(max-min), 0, 1, 0), BackgroundColor3 = CONFIG.Accent }, { CreateCorner(2) })
        Create("UIGradient", { Parent = fill, Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2) })
        local hitbox = Create("TextButton", { Parent = row, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -18), BackgroundTransparency = 1, Text = "" })
        local dragging = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0); valLabel.Text = tostring(val); cb(val)
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

    local infoCard = CreateCard(homePage, "Player Profile")
    Create("TextLabel", { Parent = infoCard, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "User: " .. LocalPlayer.Name, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left })

    local combatCard = CreateCard(combatPage, "Aimbot")
    CreateToggle(combatCard, "Enable Aimbot (RMB)", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end)
    CreateSlider(combatCard, "FOV Radius", 50, 500, CONFIG.AimFOV, function(v) CONFIG.AimFOV = v; FOVCircle.Radius = v end)
    CreateSlider(combatCard, "Smoothness", 1, 100, CONFIG.AimSmooth * 100, function(v) CONFIG.AimSmooth = v / 100 end)

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

    local trollCard = CreateCard(trollPage, "Trolling")
    CreateToggle(trollCard, "Auto Fling", CONFIG.FlingEnabled, function(v) CONFIG.FlingEnabled = v end)
    CreateToggle(trollCard, "Stand (Follow)", CONFIG.StandEnabled, function(v) CONFIG.StandEnabled = v end)
    CreateToggle(trollCard, "Ghost Invisible", CONFIG.InvisibleEnabled, function(v) CONFIG.InvisibleEnabled = v; if v then ApplyGhostMode() else RestoreVisibility() end end)
    CreateToggle(trollCard, "Click TP", CONFIG.ClickTPEnabled, function(v) CONFIG.ClickTPEnabled = v end)

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

    local moveCard = CreateCard(movePage, "Movement")
    CreateToggle(moveCard, "Fly", CONFIG.FlyEnabled, function(v) CONFIG.FlyEnabled = v; if not v then StopFly() end end)
    CreateToggle(moveCard, "Noclip", CONFIG.NoclipEnabled, function(v) CONFIG.NoclipEnabled = v end)
    CreateToggle(moveCard, "Auto Wallhop", CONFIG.AutoWallhop, function(v) CONFIG.AutoWallhop = v end)
    CreateSlider(moveCard, "WalkSpeed", 16, 150, CONFIG.WalkSpeed, function(v) CONFIG.WalkSpeed = v; CONFIG.SpeedEnabled = true end)

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

    menuFrame.Position = UDim2.new(0.5, -310, 1, 500)
    menuFrame.Visible = true
    Pages["Home"].Visible = true
    TweenService:Create(blur, TweenInfo.new(0.4), {Size = 15}):Play()
    TweenService:Create(menuFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -310, 0.5, -220)}):Play()
end

-- ============================================================
-- MAIN LOGIC & LOOPS
-- ============================================================
function StopFly()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp then for _, c in ipairs(hrp:GetChildren()) do if c.Name == "FlyBV" or c.Name == "FlyBG" then c:Destroy() end end end
        if hum then hum.PlatformStand = false end
    end
end

-- Wallhop (Fixed: No Space Launch)
Track(RunService.Stepped:Connect(function(_, dt)
    if not State.Running then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    if CONFIG.SpeedEnabled then hum.WalkSpeed = CONFIG.WalkSpeed else hum.WalkSpeed = 16 end
    if CONFIG.NoclipEnabled then for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
    if CONFIG.InvisibleEnabled then ApplyGhostMode() end

    -- Wallhop Logic
    if CONFIG.AutoWallhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        if tick() - State.WallhopCooldown > 0.1 then -- Cooldown to prevent infinite stacking
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {char}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local ray = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 3.5, params)
            if ray then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                -- Set Y velocity to 55 (max jump height), keep X and Z
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 55, hrp.AssemblyLinearVelocity.Z)
                State.WallhopCooldown = tick()
            end
        end
    end

    -- Fly
    if CONFIG.FlyEnabled then
        local bv = hrp:FindFirstChild("FlyBV")
        local bg = hrp:FindFirstChild("FlyBG")
        local cam = Workspace.CurrentCamera
        if not bv or not bg then
            StopFly()
            local bvN = Instance.new("BodyVelocity", hrp); bvN.Name = "FlyBV"; bvN.MaxForce = Vector3.new(1e5,1e5,1e5); bvN.P = 2000
            local bgN = Instance.new("BodyGyro", hrp); bgN.Name = "FlyBG"; bgN.MaxTorque = Vector3.new(1e5,1e5,1e5); bgN.P = 3000
            hum.PlatformStand = true
        else
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            local vel = move.Magnitude > 0 and move.Unit * CONFIG.FlySpeed or Vector3.zero
            bv.Velocity = bv.Velocity:Lerp(vel, math.min(dt * 10, 1))
            bg.CFrame = cam.CFrame
        end
    end

    -- Fling
    if CONFIG.FlingEnabled then
        local myRoot = hrp
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if tHrp and (tHrp.Position - myRoot.Position).Magnitude < 25 then
                    ForceFling(p.Character)
                end
            end
        end
    end

    if CONFIG.StandEnabled and State.StandTarget and State.StandTarget.Parent then
        local tHrp = State.StandTarget:FindFirstChild("HumanoidRootPart")
        if tHrp then hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3) end
    end
end))

-- Cosmetics & Aim
local frameTick = 0
Track(RunService.RenderStepped:Connect(function()
    if not State.Running then return end
    frameTick = frameTick + 1
    local cam = Workspace.CurrentCamera
    local m = UserInputService:GetMouseLocation()

    FOVCircle.Position = m
    FOVCircle.Visible = CONFIG.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if CONFIG.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local best, bestD = nil, CONFIG.AimFOV
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local head = p.Character:FindFirstChild("Head")
                if hum and hum.Health > 0 and head then
                    local sp, on = cam:WorldToViewportPoint(head.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - m).Magnitude
                        if d < bestD then bestD = d; best = head end
                    end
                end
            end
        end
        if best then
            local sp = cam:WorldToViewportPoint(best.Position)
            if typeof(mousemoverel) == "function" then mousemoverel((sp.X - m.X) * CONFIG.AimSmooth, (sp.Y - m.Y) * CONFIG.AimSmooth) end
        end
    end

    if frameTick % 3 == 0 then
        UpdateCosmetics()
        if CONFIG.Chams_Self then ApplyChams(LocalPlayer.Character) else RemoveChams(LocalPlayer.Character) end
    end
end))

-- ESP
local espTick = 0
Track(RunService.Heartbeat:Connect(function()
    if not State.Running then return end
    espTick = espTick + 1
    if espTick % 2 ~= 0 then return end
    if not CONFIG.ESPEnabled then
        for _, t in pairs(State.ESPCache) do t.box.Visible = false; t.name.Visible = false; t.healthBg.Visible = false; t.healthBar.Visible = false; t.dist.Visible = false end
        return
    end
    local active = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character.Parent then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            local head = char:FindFirstChild("Head")
            if hum and hum.Health > 0 and hrp and head and char.Parent == Workspace then
                active[p] = true
                if CONFIG.Chams_Enemy then ApplyChams(char) else RemoveChams(char) end
                if not State.ESPCache[p] then
                    State.ESPCache[p] = { box = TrackD(Draw("Square")), name = TrackD(Draw("Text")), healthBg = TrackD(Draw("Square")), healthBar = TrackD(Draw("Square")), dist = TrackD(Draw("Text")) }
                end
                local t = State.ESPCache[p]
                local hSp, hOn = Workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
                local rSp, rOn = Workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                if hOn and rOn then
                    local h = math.abs(rSp.Y - hSp.Y); local w = h * 0.55
                    local dist = (hrp.Position - Workspace.CurrentCamera.CFrame.Position).Magnitude
                    t.box.Visible = CONFIG.ESP_Box; t.box.Position = Vector2.new(hSp.X - w/2, hSp.Y); t.box.Size = Vector2.new(w, h); t.box.Color = CONFIG.Accent; t.box.Thickness = 1
                    t.name.Visible = true; t.name.Text = p.Name; t.name.Position = Vector2.new(hSp.X, hSp.Y - 15); t.name.Color = Color3.new(1,1,1); t.name.Size = 13; t.name.Center = true; t.name.Outline = true; t.name.Font = CONFIG.ESP_Font
                    t.dist.Visible = true; t.dist.Text = math.floor(dist).."m"; t.dist.Position = Vector2.new(hSp.X, hSp.Y + h + 2); t.dist.Color = Color3.fromRGB(200,200,200); t.dist.Size = 11; t.dist.Center = true; t.dist.Outline = true; t.dist.Font = CONFIG.ESP_Font
                    if CONFIG.ESP_Health then
                        local r = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        t.healthBg.Visible = true; t.healthBg.Position = Vector2.new(hSp.X - w/2 - 5, hSp.Y); t.healthBg.Size = Vector2.new(3, h); t.healthBg.Color = Color3.fromRGB(30,30,30); t.healthBg.Filled = true
                        t.healthBar.Visible = true; t.healthBar.Position = Vector2.new(hSp.X - w/2 - 5, hSp.Y + h*(1-r)); t.healthBar.Size = Vector2.new(3, h*r); t.healthBar.Color = Color3.fromRGB(255*(1-r), 255*r, 80); t.healthBar.Filled = true
                    else t.healthBg.Visible = false; t.healthBar.Visible = false end
                else
                    t.box.Visible = false; t.name.Visible = false; t.healthBg.Visible = false; t.healthBar.Visible = false; t.dist.Visible = false
                end
            end
        end
    end
    for p, t in pairs(State.ESPCache) do
        if not active[p] then
            t.box:Remove(); t.name:Remove(); t.healthBg:Remove(); t.healthBar:Remove(); t.dist:Remove()
            State.ESPCache[p] = nil; RemoveChams(p.Character)
        end
    end
end))

function UNLOAD()
    State.Running = false
    State.PlayingSong = false
    if State.menuFrame then State.menuFrame:Destroy() end
    StopFly()
    RestoreVisibility()
    for _, d in ipairs(State.Drawings) do pcall(function() d:Remove() end) end
    for _, c in ipairs(State.Connections) do pcall(function() c:Disconnect() end) end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then RemoveChams(p.Character) end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:find("Celestial") then obj:Destroy() end
    end
    print("[Celestial] Unloaded.")
end

Track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Keybinds.ToggleMenu and State.menuFrame then
        State.menuFrame.Visible = not State.menuFrame.Visible
    elseif input.KeyCode == Keybinds.Fly then
        CONFIG.FlyEnabled = not CONFIG.FlyEnabled; if not CONFIG.FlyEnabled then StopFly() end
    elseif input.KeyCode == Keybinds.Noclip then
        CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled
    elseif input.KeyCode == Keybinds.Fling then
        CONFIG.FlingEnabled = not CONFIG.FlingEnabled
    elseif input.KeyCode == Keybinds.Stand then
        CONFIG.StandEnabled = not CONFIG.StandEnabled
    elseif input.KeyCode == Keybinds.Invisible then
        CONFIG.InvisibleEnabled = not CONFIG.InvisibleEnabled
        if CONFIG.InvisibleEnabled then ApplyGhostMode() else RestoreVisibility() end
    elseif input.KeyCode == Keybinds.ClickTP then
        CONFIG.ClickTPEnabled = not CONFIG.ClickTPEnabled
    elseif input.KeyCode == Keybinds.Unload then
        UNLOAD()
    end
end))

-- ============================================================
-- INIT
-- ============================================================
task.spawn(function()
    pcall(CreateCosmetics)
    pcall(BuildMainUI)
    print("[Celestial] v6.1 Loaded Successfully.")
end)
