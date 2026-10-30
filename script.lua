-- ============================================================
-- CELESTIAL v5.1 (Invisible, Click TP, Player Search, Func Search)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local CELESTIAL_ASSET = "rbxassetid://94872985442978"

local CONFIG = {
    Accent = Color3.fromRGB(160, 100, 255),
    Bg = Color3.fromRGB(0, 0, 0),
    CardBg = Color3.fromRGB(15, 15, 18),
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(150, 150, 160),

    FlyEnabled = false, FlySpeed = 60, LegitFlyEnabled = false,
    NoclipEnabled = false, SpeedEnabled = false, WalkSpeed = 50,

    AimbotEnabled = true, AimFOV = 200, AimSmooth = 0.35, AimPart = "Head",
    AimAutoFire = false, LegitAimEnabled = false,

    ESPEnabled = true, ESP_Box = true, ESP_Health = true, ESP_Font = Drawing.Fonts.Plex, 
    Chams_Enemy = false, Chams_Self = false, Chams_Rainbow = false, Chams_Color = Color3.fromRGB(160, 100, 255),
    WingsEnabled = false, CrownEnabled = false, HaloEnabled = false,

    FlingEnabled = false, FlingMode = "Assembly",
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
    ESPCache = {}, ThemeObjects = {}, FontObjects = {}, SearchableWidgets = {},
    ListeningBind = nil, Cosmetics = {}, StandTarget = nil,
    InvisibleBackup = {}, menuFrame = nil
}

local function Track(c) table.insert(State.Connections, c) end
local function TrackD(d) table.insert(State.Drawings, d) return d end

local Draw = Drawing.new
local FOVCircle = TrackD(Draw("Circle"))
FOVCircle.Thickness = 1; FOVCircle.NumSides = 64
FOVCircle.Color = CONFIG.Accent; FOVCircle.Transparency = 0.8; FOVCircle.Radius = CONFIG.AimFOV

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if children then for _, child in ipairs(children) do child.Parent = inst end end
    return inst
end
local function CreateCorner(radius) return Create("UICorner", { CornerRadius = UDim.new(0, radius) }) end
local function RegisterTheme(obj, type) table.insert(State.ThemeObjects, {obj = obj, type = type}); return obj end
local function RegisterFont(obj) table.insert(State.FontObjects, obj); return obj end
local function RegisterSearch(row, text, card, page) table.insert(State.SearchableWidgets, {row = row, text = text:lower(), card = card, page = page}) end

-- ============================================================
-- 1. INVISIBLE LOGIC
-- ============================================================
local function SetInvisible(on)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if on then
        State.InvisibleBackup = {}
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                State.InvisibleBackup[v] = v.Transparency
                v.Transparency = 1
            elseif v:IsA("Decal") or v:IsA("Texture") then
                State.InvisibleBackup[v] = v.Transparency
                v.Transparency = 1
            end
        end
        if hum then
            State.InvisibleBackup["DisplayDistance"] = hum.DisplayDistanceType
            State.InvisibleBackup["NameDist"] = hum.NameDisplayDistance
            State.InvisibleBackup["HealthDist"] = hum.HealthDisplayDistance
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hum.NameDisplayDistance = 0
            hum.HealthDisplayDistance = 0
        end
    else
        for obj, trans in pairs(State.InvisibleBackup) do
            if type(obj) == "userdata" and obj.Parent then
                pcall(function() obj.Transparency = trans end)
            end
        end
        if hum then
            hum.DisplayDistanceType = State.InvisibleBackup["DisplayDistance"] or Enum.HumanoidDisplayDistanceType.Viewer
            hum.NameDisplayDistance = State.InvisibleBackup["NameDist"] or 100
            hum.HealthDisplayDistance = State.InvisibleBackup["HealthDist"] or 100
        end
        State.InvisibleBackup = {}
    end
end

-- ============================================================
-- 2. SPLASH
-- ============================================================
local splashGui = Create("ScreenGui", { Name = "CelestialSplash", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1001, Parent = LocalPlayer:WaitForChild("PlayerGui") })
local splashBg = Create("Frame", { Parent = splashGui, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = CONFIG.Bg, BorderSizePixel = 0 })
local ringFrame = Create("Frame", { Parent = splashBg, Size = UDim2.new(0, 300, 0, 300), Position = UDim2.new(0.5, -150, 0.5, -150), BackgroundTransparency = 1 })
local particles = {}
for i = 1, 36 do
    local angle = (i / 36) * math.pi * 2
    particles[i] = Create("Frame", { Parent = ringFrame, Size = UDim2.new(0, 4, 0, 4), Position = UDim2.new(0.5, math.cos(angle) * 140, 0.5, math.sin(angle) * 140), BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0 }, { CreateCorner(2) })
end
local splashImg = Create("ImageLabel", { Parent = splashBg, Size = UDim2.new(0, 150, 0, 150), Position = UDim2.new(0.5, -75, 0.5, -130), BackgroundTransparency = 1, Image = CELESTIAL_ASSET, ScaleType = Enum.ScaleType.Crop }, { CreateCorner(75) })
Create("UIStroke", { Parent = splashImg, Color = CONFIG.Accent, Thickness = 2, Transparency = 0.5 })
Create("TextLabel", { Parent = splashBg, Size = UDim2.new(0, 400, 0, 40), Position = UDim2.new(0.5, -200, 0.5, 40), BackgroundTransparency = 1, Text = "CELESTIAL", Font = Enum.Font.GothamBold, TextSize = 28, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Center })
local barBg = Create("Frame", { Parent = splashBg, Size = UDim2.new(0, 300, 0, 6), Position = UDim2.new(0.5, -150, 0.5, 120), BackgroundColor3 = Color3.fromRGB(40, 40, 50), BorderSizePixel = 0 }, { CreateCorner(3) })
local barFill = Create("Frame", { Parent = barBg, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0 }, { CreateCorner(3) })

local function PlaySplash(callback)
    local progress = 0; local rr = 0
    local conn
    conn = RunService.RenderStepped:Connect(function()
        progress = math.min(progress + 0.006, 1)
        barFill.Size = UDim2.new(progress, 0, 1, 0)
        rr = rr + 0.02
        for i, p in ipairs(particles) do
            local angle = (i / 36) * math.pi * 2 + rr
            p.BackgroundTransparency = 1 - (math.sin(angle) * 0.5 + 0.5)
            p.Position = UDim2.new(0.5, math.cos(angle) * 140, 0.5, math.sin(angle) * 140)
        end
        if progress >= 1 then
            conn:Disconnect(); task.wait(0.3)
            TweenService:Create(splashBg, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
            task.wait(0.5); splashGui:Destroy(); callback()
        end
    end)
end

-- ============================================================
-- 3. TOP BAR
-- ============================================================
local topBarGui = Create("ScreenGui", { Name = "CelestialTopBar", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000, Parent = LocalPlayer:WaitForChild("PlayerGui") })
local topBar = Create("Frame", { Parent = topBarGui, Size = UDim2.new(0, 520, 0, 30), Position = UDim2.new(0.5, -260, 0, 10), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.3 }, { CreateCorner(8) })
RegisterTheme(Create("UIStroke", { Parent = topBar, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.5 }), "stroke")
local topText = RegisterFont(Create("TextLabel", { Parent = topBar, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Loading...", Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text }))

-- ============================================================
-- 4. CHAMS
-- ============================================================
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

-- ============================================================
-- 5. COSMETICS
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
    local mesh = Instance.new("SpecialMesh", crownPart)
    mesh.MeshType = Enum.MeshType.FileMesh; mesh.MeshId = "rbxassetid://176213013"; mesh.Scale = Vector3.new(0.8, 0.8, 0.8)
    State.Cosmetics.Crown = crownPart

    local wingModel = Instance.new("Model", Workspace); wingModel.Name = "CelestialWings"
    local leftWing = Instance.new("Part", wingModel); leftWing.Size = Vector3.new(5, 5, 1)
    leftWing.Transparency = 0.2; leftWing.CanCollide = false; leftWing.Anchored = true
    leftWing.Material = Enum.Material.Neon; leftWing.Color = CONFIG.Accent
    local meshL = Instance.new("SpecialMesh", leftWing)
    meshL.MeshType = Enum.MeshType.FileMesh; meshL.MeshId = "rbxassetid://101952033"; meshL.Scale = Vector3.new(1.5, 1.5, 1.5)
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
            for _, v in ipairs(State.Cosmetics.Crown:GetChildren()) do
                if v:IsA("Mesh") then v.VertexColor = CONFIG.Accent end
            end
        end
    end
    if State.Cosmetics.Wings and hrp then
        State.Cosmetics.Wings.Parent = CONFIG.WingsEnabled and Workspace or nil
        if CONFIG.WingsEnabled then
            local L = State.Cosmetics.Wings:FindFirstChild("LeftWing")
            local R = State.Cosmetics.Wings:FindFirstChild("RightWing")
            if L and R then
                L.CFrame = hrp.CFrame * CFrame.new(-1, 1, 0.5) * CFrame.Angles(0, math.rad(-20), math.rad(20))
                R.CFrame = hrp.CFrame * CFrame.new(1, 1, 0.5) * CFrame.Angles(0, math.rad(20), math.rad(-20))
                L.Color = CONFIG.Accent; R.Color = CONFIG.Accent
            end
        end
    end
end

-- ============================================================
-- 6. MAIN UI
-- ============================================================
local mainGui
local function BuildMainUI()
    mainGui = Create("ScreenGui", { Name = "CelestialUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, Parent = LocalPlayer:WaitForChild("PlayerGui") })

    local menuFrame = Create("Frame", { Parent = mainGui, Size = UDim2.new(0, 580, 0, 440), Position = UDim2.new(0.5, -290, 0.5, -220), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.05, BorderSizePixel = 0 }, { CreateCorner(12) })
    State.menuFrame = menuFrame
    RegisterTheme(Create("UIStroke", { Parent = menuFrame, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.6 }), "stroke")

    local header = Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1 })
    Create("ImageLabel", { Parent = header, Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 16, 0.5, -14), BackgroundTransparency = 1, Image = CELESTIAL_ASSET, ScaleType = Enum.ScaleType.Crop }, { CreateCorner(14) })
    RegisterFont(Create("TextLabel", { Parent = header, Size = UDim2.new(0, 200, 0, 20), Position = UDim2.new(0, 54, 0, 10), BackgroundTransparency = 1, Text = "Celestial", Font = CONFIG.GUIFont, TextSize = 16, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
    local subLbl = RegisterFont(Create("TextLabel", { Parent = header, Size = UDim2.new(0, 250, 0, 14), Position = UDim2.new(0, 54, 0, 28), BackgroundTransparency = 1, Text = "v5.1 | Invisible + Click TP", Font = CONFIG.GUIFont, TextSize = 11, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left }))
    RegisterTheme(subLbl, "text")
    Create("TextButton", { Parent = header, Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -36, 0.5, -12), BackgroundTransparency = 1, Text = "×", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = CONFIG.TextDark }).MouseButton1Click:Connect(function() menuFrame.Visible = false end)

    -- SEARCH BAR
    local searchBar = Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, -160, 0, 30), Position = UDim2.new(0, 150, 0, 54), BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.3, BorderSizePixel = 0 }, { CreateCorner(6) })
    RegisterTheme(Create("UIStroke", { Parent = searchBar, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.8 }), "stroke")
    local searchIcon = Create("TextLabel", { Parent = searchBar, Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(0, 4, 0, 0), BackgroundTransparency = 1, Text = "🔍", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = CONFIG.TextDark })
    local searchBox = Create("TextBox", { Parent = searchBar, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 26, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search functions...", Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text, PlaceholderColor3 = CONFIG.TextDark, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        if query == "" then
            for _, w in ipairs(State.SearchableWidgets) do
                if w.row and w.row.Parent then w.row.Visible = true end
            end
            return
        end
        for _, w in ipairs(State.SearchableWidgets) do
            if w.row and w.row.Parent then
                w.row.Visible = w.text:find(query) ~= nil
            end
        end
    end)

    local sidebar = Create("Frame", { Parent = menuFrame, Size = UDim2.new(0, 140, 1, -90), Position = UDim2.new(0, 0, 0, 90), BackgroundTransparency = 1 })
    Create("UIListLayout", { Parent = sidebar, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center })
    Create("UIPadding", { Parent = sidebar, PaddingTop = UDim.new(0, 4) })

    local content = Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, -160, 1, -100), Position = UDim2.new(0, 150, 0, 90), BackgroundTransparency = 1 })

    local Pages = {}
    local function CreateTab(name, order)
        local btn = Create("TextButton", { Parent = sidebar, Size = UDim2.new(0, 120, 0, 32), BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.5, Text = "  " .. name, Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order }, { CreateCorner(6) })
        Create("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0, 10) })
        local page = Create("ScrollingFrame", { Parent = content, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0) })
        Create("UIListLayout", { Parent = page, Padding = UDim.new(0, 10) })
        Pages[name] = page
        btn.MouseButton1Click:Connect(function()
            for _, p in pairs(Pages) do p.Visible = false end
            page.Visible = true
            for _, b in ipairs(sidebar:GetChildren()) do if b:IsA("TextButton") then b.TextColor3 = CONFIG.TextDark; b.BackgroundTransparency = 0.5 end end
            btn.TextColor3 = CONFIG.Text; btn.BackgroundTransparency = 0.2
        end)
        return page
    end

    local currentPage = nil
    local function CreateCard(parent, titleText)
        local card = Create("Frame", { Parent = parent, Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.1 }, { CreateCorner(8) })
        Create("UIListLayout", { Parent = card, Padding = UDim.new(0, 8) })
        Create("UIPadding", { Parent = card, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
        if titleText then RegisterTheme(RegisterFont(Create("TextLabel", { Parent = card, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = titleText:upper(), Font = CONFIG.GUIFont, TextSize = 10, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left })), "text") end
        return card
    end

    local function CreateToggle(parent, text, default, cb)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
        RegisterFont(Create("TextLabel", { Parent = row, Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, Text = text, Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
        local sw = Create("Frame", { Parent = row, Size = UDim2.new(0, 30, 0, 14), Position = UDim2.new(1, -30, 0.5, -7), BackgroundColor3 = default and CONFIG.Accent or CONFIG.Bg }, { CreateCorner(10) })
        local circle = Create("Frame", { Parent = sw, Size = UDim2.new(0, 10, 0, 10), Position = default and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = CONFIG.Text }, { CreateCorner(5) })
        local state = default
        Create("TextButton", { Parent = row, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }).MouseButton1Click:Connect(function()
            state = not state
            sw.BackgroundColor3 = state and CONFIG.Accent or CONFIG.Bg
            circle.Position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
            cb(state)
        end)
        RegisterSearch(row, text, parent, nil)
    end

    local function CreateSlider(parent, text, min, max, default, cb)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })
        RegisterFont(Create("TextLabel", { Parent = row, Size = UDim2.new(1, -40, 0, 16), BackgroundTransparency = 1, Text = text, Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
        local valLabel = Create("TextLabel", { Parent = row, Size = UDim2.new(0, 40, 0, 16), Position = UDim2.new(1, -40, 0, 0), BackgroundTransparency = 1, Text = tostring(default), Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Right })
        local track = Create("Frame", { Parent = row, Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = CONFIG.Bg }, { CreateCorner(2) })
        local fill = Create("Frame", { Parent = track, Size = UDim2.new((default-min)/(max-min), 0, 1, 0), BackgroundColor3 = CONFIG.Accent }, { CreateCorner(2) })
        local hitbox = Create("TextButton", { Parent = row, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -15), BackgroundTransparency = 1, Text = "" })
        local dragging = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0); valLabel.Text = tostring(val); cb(val)
        end
        hitbox.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(input.Position.X) end end)
        Track(UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input.Position.X) end end))
        Track(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end))
        RegisterSearch(row, text, parent, nil)
    end

    local function CreateDropdown(parent, text, options, default, cb)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
        RegisterFont(Create("TextLabel", { Parent = row, Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = text, Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
        local btn = Create("TextButton", { Parent = row, Size = UDim2.new(0, 80, 0, 20), Position = UDim2.new(1, -80, 0.5, -10), BackgroundColor3 = CONFIG.Bg, Text = tostring(default), Font = CONFIG.GUIFont, TextSize = 11, TextColor3 = CONFIG.Accent }, { CreateCorner(4) })
        local idx = 1; for i, v in ipairs(options) do if v == default or tostring(v) == tostring(default) then idx = i end end
        btn.MouseButton1Click:Connect(function()
            idx = idx + 1; if idx > #options then idx = 1 end
            btn.Text = tostring(options[idx]); cb(options[idx])
        end)
        RegisterSearch(row, text, parent, nil)
    end

    local homePage = CreateTab("Home", 1)
    local combatPage = CreateTab("Combat", 2)
    local visPage = CreateTab("Visuals", 3)
    local trollPage = CreateTab("Troll", 4)
    local movePage = CreateTab("Movement", 5)
    local settingsPage = CreateTab("Settings", 6)

    -- HOME
    local infoCard = CreateCard(homePage, "Player Profile")
    RegisterFont(Create("TextLabel", { Parent = infoCard, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "User: " .. LocalPlayer.Name, Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))

    -- COMBAT
    local combatCard = CreateCard(combatPage, "Aimbot Settings")
    CreateToggle(combatCard, "Aimbot (RMB)", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end)
    CreateToggle(combatCard, "Legit Aim (Smooth)", CONFIG.LegitAimEnabled, function(v) CONFIG.LegitAimEnabled = v end)
    CreateSlider(combatCard, "FOV Radius", 50, 500, CONFIG.AimFOV, function(v) CONFIG.AimFOV = v; FOVCircle.Radius = v end)
    CreateSlider(combatCard, "Smoothness", 1, 100, CONFIG.AimSmooth * 100, function(v) CONFIG.AimSmooth = v / 100 end)
    CreateToggle(combatCard, "Auto Fire", CONFIG.AimAutoFire, function(v) CONFIG.AimAutoFire = v end)

    -- VISUALS
    local visCard = CreateCard(visPage, "ESP Settings")
    CreateToggle(visCard, "Enable ESP", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end)
    CreateToggle(visCard, "Box", CONFIG.ESP_Box, function(v) CONFIG.ESP_Box = v end)
    CreateToggle(visCard, "Health Bar", CONFIG.ESP_Health, function(v) CONFIG.ESP_Health = v end)

    local chamsCard = CreateCard(visPage, "Chams Settings")
    CreateToggle(chamsCard, "Enemy Chams", CONFIG.Chams_Enemy, function(v) CONFIG.Chams_Enemy = v end)
    CreateToggle(chamsCard, "Self Chams", CONFIG.Chams_Self, function(v) CONFIG.Chams_Self = v end)
    CreateToggle(chamsCard, "Rainbow Flow", CONFIG.Chams_Rainbow, function(v) CONFIG.Chams_Rainbow = v end)

    local cosCard = CreateCard(visPage, "Cosmetics")
    CreateToggle(cosCard, "Wings", CONFIG.WingsEnabled, function(v) CONFIG.WingsEnabled = v end)
    CreateToggle(cosCard, "Crown", CONFIG.CrownEnabled, function(v) CONFIG.CrownEnabled = v end)
    CreateToggle(cosCard, "Halo", CONFIG.HaloEnabled, function(v) CONFIG.HaloEnabled = v end)

    -- TROLL
    local trollCard = CreateCard(trollPage, "Fling & Stand")
    CreateToggle(trollCard, "Auto Fling Nearby", CONFIG.FlingEnabled, function(v) CONFIG.FlingEnabled = v end)
    CreateDropdown(trollCard, "Fling Mode", {"Assembly", "BodyVel", "CFrame"}, "Assembly", function(v) CONFIG.FlingMode = v end)
    CreateToggle(trollCard, "Stand (Follow Player)", CONFIG.StandEnabled, function(v) CONFIG.StandEnabled = v end)
    CreateToggle(trollCard, "Invisible (No Name)", CONFIG.InvisibleEnabled, function(v)
        CONFIG.InvisibleEnabled = v
        SetInvisible(v)
    end)
    CreateToggle(trollCard, "Click TP", CONFIG.ClickTPEnabled, function(v) CONFIG.ClickTPEnabled = v end)

    local flingAllBtn = Create("TextButton", { Parent = trollCard, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(200,50,50), Text = "Fling Everyone", Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text }, { CreateCorner(6) })
    flingAllBtn.MouseButton1Click:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if CONFIG.FlingMode == "Assembly" then
                        hrp.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5)
                        hrp.AssemblyAngularVelocity = Vector3.new(1e5, 1e5, 1e5)
                    elseif CONFIG.FlingMode == "BodyVel" then
                        local bv = Instance.new("BodyVelocity", hrp); bv.Velocity = Vector3.new(1e5, 1e5, 1e5); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); Debris:AddItem(bv, 0.5)
                    elseif CONFIG.FlingMode == "CFrame" then
                        hrp.CFrame = hrp.CFrame * CFrame.new(0, 1e3, 0)
                    end
                end
            end
        end
    end)
    RegisterSearch(flingAllBtn, "Fling Everyone", trollCard, nil)

    -- PLAYER SEARCH
    local playerCard = CreateCard(trollPage, "Find Player")
    local playerSearchFrame = Create("Frame", { Parent = playerCard, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.3 }, { CreateCorner(5) })
    local playerSearchBox = Create("TextBox", { Parent = playerSearchFrame, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search player...", Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text, PlaceholderColor3 = CONFIG.TextDark, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
    local playerList = Create("ScrollingFrame", { Parent = playerCard, Size = UDim2.new(1, 0, 0, 150), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y })
    Create("UIListLayout", { Parent = playerList, Padding = UDim.new(0, 4) })

    local function refreshPlayerList(query)
        query = (query or ""):lower()
        for _, child in ipairs(playerList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Name:lower():find(query, 1, true) then
                local btn = Create("TextButton", { Parent = playerList, Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.3, Text = "  " .. p.Name, Font = CONFIG.GUIFont, TextSize = 11, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }, { CreateCorner(4) })
                btn.MouseButton1Click:Connect(function()
                    if p.Character then
                        State.StandTarget = p.Character
                        CONFIG.StandEnabled = true
                    end
                end)
            end
        end
    end
    refreshPlayerList("")
    playerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        refreshPlayerList(playerSearchBox.Text)
    end)
    Track(Players.PlayerAdded:Connect(function() refreshPlayerList(playerSearchBox.Text) end))
    Track(Players.PlayerRemoving:Connect(function() task.wait(0.1); refreshPlayerList(playerSearchBox.Text) end))

    -- EMOTES
    local emotesCard = CreateCard(trollPage, "Troll Emotes")
    local function AddEmoteBtn(text, animId)
        local btn = Create("TextButton", { Parent = emotesCard, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = CONFIG.CardBg, Text = text .. " Nearest Player", Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text }, { CreateCorner(6) })
        btn.MouseButton1Click:Connect(function()
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local closest, minD = nil, math.huge
            if myRoot then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                        if d < minD then minD = d; closest = p.Character end
                    end
                end
            end
            if closest and closest:FindFirstChildOfClass("Humanoid") then
                local hum = closest:FindFirstChildOfClass("Humanoid")
                local animator = hum:FindFirstChildOfClass("Animator") or hum
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. animId
                animator:LoadAnimation(anim):Play()
            end
        end)
        RegisterSearch(btn, text, emotesCard, nil)
    end
    AddEmoteBtn("Bang", "5269855227")
    AddEmoteBtn("Dance", "507771019")
    AddEmoteBtn("Laugh", "507770818")

    -- MOVEMENT
    local moveCard = CreateCard(movePage, "Movement")
    CreateToggle(moveCard, "Fly (Fast)", CONFIG.FlyEnabled, function(v) CONFIG.FlyEnabled = v; if not v then StopFly() end end)
    CreateToggle(moveCard, "Legit Fly (Safe)", CONFIG.LegitFlyEnabled, function(v) CONFIG.LegitFlyEnabled = v; if not v then StopLegitFly() end end)
    CreateSlider(moveCard, "Fly Speed", 20, 200, CONFIG.FlySpeed, function(v) CONFIG.FlySpeed = v end)
    CreateToggle(moveCard, "Noclip", CONFIG.NoclipEnabled, function(v) CONFIG.NoclipEnabled = v end)
    CreateToggle(moveCard, "Speed Hack", CONFIG.SpeedEnabled, function(v) CONFIG.SpeedEnabled = v end)
    CreateSlider(moveCard, "WalkSpeed", 16, 150, CONFIG.WalkSpeed, function(v) CONFIG.WalkSpeed = v end)

    -- SETTINGS
    local themeCard = CreateCard(settingsPage, "UI Accent Color")
    local paletteFrame = Create("Frame", { Parent = themeCard, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })
    Create("UIListLayout", { Parent = paletteFrame, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Wraps = true })
    local colors = {
        {Color = Color3.fromRGB(160, 100, 255)}, {Color = Color3.fromRGB(100, 150, 255)},
        {Color = Color3.fromRGB(100, 255, 150)}, {Color = Color3.fromRGB(255, 100, 100)},
        {Color = Color3.fromRGB(255, 100, 200)}, {Color = Color3.fromRGB(240, 240, 240)},
        {Color = Color3.fromRGB(255, 180, 100)}, {Color = Color3.fromRGB(100, 255, 255)},
    }
    for _, c in ipairs(colors) do
        local btn = Create("TextButton", { Parent = paletteFrame, Size = UDim2.new(0, 28, 0, 28), BackgroundColor3 = c.Color, Text = "" }, { CreateCorner(14) })
        btn.MouseButton1Click:Connect(function()
            CONFIG.Accent = c.Color; FOVCircle.Color = c.Color
            for _, obj in ipairs(State.ThemeObjects) do
                if obj.obj and obj.obj.Parent then
                    if obj.type == "stroke" then TweenService:Create(obj.obj, TweenInfo.new(0.2), {Color = c.Color}):Play()
                    elseif obj.type == "text" then TweenService:Create(obj.obj, TweenInfo.new(0.2), {TextColor3 = c.Color}):Play() end
                end
            end
        end)
    end

    local miscCard = CreateCard(settingsPage, "Misc")
    local unloadBtn = Create("TextButton", { Parent = miscCard, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(200, 50, 50), Text = "UNLOAD SCRIPT", Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text }, { CreateCorner(6) })
    unloadBtn.MouseButton1Click:Connect(function() UNLOAD() end)
    RegisterSearch(unloadBtn, "Unload Script", miscCard, nil)

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

    menuFrame.Visible = true
    Pages["Home"].Visible = true
end

-- ============================================================
-- 7. MOVEMENT LOGIC
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
function StopLegitFly()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp:FindFirstChild("LegitAlign") then hrp.LegitAlign:Destroy() end
            if hrp:FindFirstChild("LegitOrient") then hrp.LegitOrient:Destroy() end
        end
    end
end
local function StartLegitFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    StopLegitFly()
    local align = Instance.new("AlignPosition", hrp); align.Name = "LegitAlign"
    align.Mode = Enum.PositionAlignmentMode.OneAttachment
    align.Attachment0 = Instance.new("Attachment", hrp)
    align.MaxForce = 25000; align.Responsiveness = 10
    local orient = Instance.new("AlignOrientation", hrp); orient.Name = "LegitOrient"
    orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
    orient.Attachment0 = Instance.new("Attachment", hrp)
    orient.MaxTorque = 25000; orient.Responsiveness = 10
end

-- ============================================================
-- 8. TOP BAR LOOP
-- ============================================================
local fpsCount, fpsAccum = 0, 0
Track(RunService.Heartbeat:Connect(function(dt)
    if not State.Running then return end
    fpsCount = fpsCount + 1; fpsAccum = fpsAccum + dt
    if fpsAccum >= 1 then
        local ping = "N/A"
        pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end)
        local time = os.date("!%H:%M:%S", os.time() + (4 * 3600))
        topText.Text = string.format("%s | %d FPS | %s | %s (Samara)", LocalPlayer.Name, fpsCount, ping, time)
        fpsCount = 0; fpsAccum = 0
    end
end))

-- ============================================================
-- 9. MAIN LOGIC
-- ============================================================
Track(RunService.Stepped:Connect(function(_, dt)
    if not State.Running then return end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and CONFIG.SpeedEnabled then hum.WalkSpeed = CONFIG.WalkSpeed elseif hum then hum.WalkSpeed = 16 end
        if CONFIG.NoclipEnabled then for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
    end

    if CONFIG.StandEnabled and State.StandTarget and State.StandTarget.Parent then
        local tHrp = State.StandTarget:FindFirstChild("HumanoidRootPart")
        local myHrp = char and char:FindFirstChild("HumanoidRootPart")
        if tHrp and myHrp then myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3) end
    end

    if CONFIG.LegitFlyEnabled then
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local cam = Workspace.CurrentCamera
        if hrp then
            local align = hrp:FindFirstChild("LegitAlign")
            if not align then StartLegitFly(); return end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            if move.Magnitude > 0 then align.Position = hrp.Position + move.Unit * CONFIG.FlySpeed * dt
            else align.Position = hrp.Position end
        end
    end

    if CONFIG.FlyEnabled then
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local bv = hrp and hrp:FindFirstChild("FlyBV")
        local bg = hrp and hrp:FindFirstChild("FlyBG")
        local cam = Workspace.CurrentCamera
        if not bv or not bg then
            StopFly()
            local bvN = Instance.new("BodyVelocity", hrp); bvN.Name = "FlyBV"; bvN.MaxForce = Vector3.new(1e5,1e5,1e5); bvN.P = 2000
            local bgN = Instance.new("BodyGyro", hrp); bgN.Name = "FlyBG"; bgN.MaxTorque = Vector3.new(1e5,1e5,1e5); bgN.P = 3000
            char.Humanoid.PlatformStand = true
            return
        end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
        local vel = move.Magnitude > 0 and move.Unit * CONFIG.FlySpeed or Vector3.zero
        bv.Velocity = bv.Velocity:Lerp(vel, math.min(dt * 10, 1)); bg.CFrame = cam.CFrame
    end

    if CONFIG.FlingEnabled then
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if myRoot then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - myRoot.Position).Magnitude < 25 then
                        if CONFIG.FlingMode == "Assembly" then
                            hrp.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5)
                            hrp.AssemblyAngularVelocity = Vector3.new(1e5, 1e5, 1e5)
                        elseif CONFIG.FlingMode == "BodyVel" then
                            local bv = Instance.new("BodyVelocity", hrp); bv.Velocity = Vector3.new(1e5, 1e5, 1e5); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); Debris:AddItem(bv, 0.5)
                        elseif CONFIG.FlingMode == "CFrame" then
                            hrp.CFrame = hrp.CFrame * CFrame.new(0, 1e3, 0)
                        end
                    end
                end
            end
        end
    end
end))

-- ============================================================
-- 10. CLICK TP
-- ============================================================
local mouse = LocalPlayer:GetMouse()
Track(UserInputService.InputBegan:Connect(function(input, gp)
    if CONFIG.ClickTPEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and not gp then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and mouse.Hit then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end))

-- ============================================================
-- 11. AIM & COSMETICS
-- ============================================================
local function getPart(char)
    if CONFIG.AimPart == "Head" then return char:FindFirstChild("Head") end
    if CONFIG.AimPart == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
    return char:FindFirstChild("HumanoidRootPart")
end

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
                local part = getPart(p.Character)
                if hum and hum.Health > 0 and part then
                    local sp, on = cam:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - m).Magnitude
                        if d < bestD then bestD = d; best = part end
                    end
                end
            end
        end
        if best then
            local sp = cam:WorldToViewportPoint(best.Position)
            local smooth = CONFIG.LegitAimEnabled and (CONFIG.AimSmooth * 0.5) or CONFIG.AimSmooth
            if typeof(mousemoverel) == "function" then mousemoverel((sp.X - m.X) * smooth, (sp.Y - m.Y) * smooth) end
        end
    end

    if frameTick % 3 == 0 then
        UpdateCosmetics()
        if CONFIG.Chams_Self then ApplyChams(LocalPlayer.Character) else RemoveChams(LocalPlayer.Character) end
        if CONFIG.InvisibleEnabled then SetInvisible(true) end
    end
end))

-- ============================================================
-- 12. ESP
-- ============================================================
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

-- ============================================================
-- 13. UNLOAD + HOTKEYS
-- ============================================================
function UNLOAD()
    State.Running = false
    if mainGui then mainGui:Destroy() end
    if topBarGui then topBarGui:Destroy() end
    StopFly(); StopLegitFly()
    if CONFIG.InvisibleEnabled then SetInvisible(false) end
    for _, d in ipairs(State.Drawings) do pcall(function() d:Remove() end) end
    for _, c in ipairs(State.Connections) do pcall(function() c:Disconnect() end) end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then RemoveChams(p.Character) end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:find("Celestial") then obj:Destroy() end
    end
end

Track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Keybinds.ToggleMenu and State.menuFrame then
        State.menuFrame.Visible = not State.menuFrame.Visible
    elseif input.KeyCode == Keybinds.Fly then
        CONFIG.FlyEnabled = not CONFIG.FlyEnabled; if not CONFIG.FlyEnabled then StopFly() end
    elseif input.KeyCode == Keybinds.Noclip then
        CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled
        if not CONFIG.NoclipEnabled and LocalPlayer.Character then
            for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end
        end
    elseif input.KeyCode == Keybinds.Fling then
        CONFIG.FlingEnabled = not CONFIG.FlingEnabled
    elseif input.KeyCode == Keybinds.Stand then
        CONFIG.StandEnabled = not CONFIG.StandEnabled
    elseif input.KeyCode == Keybinds.Invisible then
        CONFIG.InvisibleEnabled = not CONFIG.InvisibleEnabled
        SetInvisible(CONFIG.InvisibleEnabled)
    elseif input.KeyCode == Keybinds.ClickTP then
        CONFIG.ClickTPEnabled = not CONFIG.ClickTPEnabled
    elseif input.KeyCode == Keybinds.Unload then
        UNLOAD()
    end
end))

PlaySplash(function()
    pcall(CreateCosmetics)
    pcall(BuildMainUI)
    print("[Celestial] v5.1 Loaded.")
end)
