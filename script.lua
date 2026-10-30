-- ============================================================
-- CELESTIAL v4.6 (Legit Fly, Legit Aim, Troll Emotes)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

local CELESTIAL_ASSET = "rbxassetid://94872985442978"

-- ==================== CONFIG ====================
local CONFIG = {
    Accent = Color3.fromRGB(160, 100, 255),
    Bg = Color3.fromRGB(0, 0, 0),
    CardBg = Color3.fromRGB(15, 15, 18),
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(150, 150, 160),

    -- Movement (Обход античита)
    FlyEnabled = false, FlySpeed = 60, LegitFlyEnabled = false,
    NoclipEnabled = false, SpeedEnabled = false, WalkSpeed = 50,

    -- Combat
    AimbotEnabled = true, AimFOV = 200, AimSmooth = 0.35, AimPart = "Head",
    AimAutoFire = false, LegitAimEnabled = false,

    -- Visuals
    ESPEnabled = true, ESP_Box = true, ESP_Health = true, ESP_Font = Drawing.Fonts.Plex, 
    Chams_Enemy = false, Chams_Self = false, Chams_Rainbow = false, Chams_Color = Color3.fromRGB(160, 100, 255),
    WingsEnabled = false, CrownEnabled = false, HaloEnabled = false,

    -- Troll
    FlingEnabled = false,

    GUIFont = Enum.Font.Gotham,
}

local Keybinds = {
    ToggleMenu = Enum.KeyCode.H, Fly = Enum.KeyCode.F,
    Noclip = Enum.KeyCode.G, Unload = Enum.KeyCode.Delete, Fling = Enum.KeyCode.V,
}

local State = {
    Running = true, Connections = {}, Drawings = {},
    ESPCache = {}, ThemeObjects = {}, FontObjects = {},
    ListeningBind = nil, Cosmetics = {},
    LegitFlyPart = nil
}

local function Track(c) table.insert(State.Connections, c) end
local function TrackD(d) table.insert(State.Drawings, d) return d end

-- ==================== DRAWINGS ====================
local Draw = Drawing.new
local FOVCircle = TrackD(Draw("Circle"))
FOVCircle.Thickness = 1; FOVCircle.NumSides = 64
FOVCircle.Color = CONFIG.Accent; FOVCircle.Transparency = 0.8; FOVCircle.Radius = CONFIG.AimFOV

-- ==================== UI BUILDER ====================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if children then for _, child in ipairs(children) do child.Parent = inst end end
    return inst
end
local function CreateCorner(radius) return Create("UICorner", { CornerRadius = UDim.new(0, radius) }) end
local function RegisterTheme(obj, type) table.insert(State.ThemeObjects, {obj = obj, type = type}); return obj end
local function RegisterFont(obj) table.insert(State.FontObjects, obj); return obj end

-- ============================================================
-- 1. SPLASH SCREEN
-- ============================================================
local splashGui = Create("ScreenGui", { Name = "CelestialSplash", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000, Parent = LocalPlayer:WaitForChild("PlayerGui") })
local splashBg = Create("Frame", { Parent = splashGui, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = CONFIG.Bg, BorderSizePixel = 0 })

local ringFrame = Create("Frame", { Parent = splashBg, Size = UDim2.new(0, 300, 0, 300), Position = UDim2.new(0.5, -150, 0.5, -150), BackgroundTransparency = 1 })
local particles = {}
for i = 1, 36 do
    local angle = (i / 36) * math.pi * 2
    local p = Create("Frame", { Parent = ringFrame, Size = UDim2.new(0, 4, 0, 4), Position = UDim2.new(0.5, math.cos(angle) * 140, 0.5, math.sin(angle) * 140), BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0 }, { CreateCorner(2) })
    particles[i] = p
end

local splashImg = Create("ImageLabel", { Parent = splashBg, Size = UDim2.new(0, 150, 0, 150), Position = UDim2.new(0.5, -75, 0.5, -130), BackgroundTransparency = 1, Image = CELESTIAL_ASSET, ScaleType = Enum.ScaleType.Crop }, { CreateCorner(75) })
Create("UIStroke", { Parent = splashImg, Color = CONFIG.Accent, Thickness = 2, Transparency = 0.5 })

local splashTitle = RegisterFont(Create("TextLabel", { Parent = splashBg, Size = UDim2.new(0, 400, 0, 40), Position = UDim2.new(0.5, -200, 0.5, 40), BackgroundTransparency = 1, Text = "CELESTIAL", Font = CONFIG.GUIFont, TextSize = 28, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Center }))
local splashSub = RegisterFont(Create("TextLabel", { Parent = splashBg, Size = UDim2.new(0, 400, 0, 20), Position = UDim2.new(0.5, -200, 0.5, 80), BackgroundTransparency = 1, Text = "LOADING INTERFACE...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Center }))

local barBg = Create("Frame", { Parent = splashBg, Size = UDim2.new(0, 300, 0, 6), Position = UDim2.new(0.5, -150, 0.5, 120), BackgroundColor3 = Color3.fromRGB(40, 40, 50), BorderSizePixel = 0 }, { CreateCorner(3) })
local barFill = Create("Frame", { Parent = barBg, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0 }, { CreateCorner(3) })
local percentText = Create("TextLabel", { Parent = splashBg, Size = UDim2.new(0, 100, 0, 20), Position = UDim2.new(0.5, -50, 0.5, 135), BackgroundTransparency = 1, Text = "0%", Font = Enum.Font.Code, TextSize = 14, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Center })

local function PlaySplash(callback)
    local progress = 0; local ringRotation = 0
    local connection
    connection = RunService.RenderStepped:Connect(function()
        progress = math.min(progress + 0.006, 1) 
        barFill.Size = UDim2.new(progress, 0, 1, 0)
        percentText.Text = math.floor(progress * 100) .. "%"
        ringRotation = ringRotation + 0.02
        for i, p in ipairs(particles) do
            local angle = (i / 36) * math.pi * 2 + ringRotation
            local alpha = math.sin(angle) * 0.5 + 0.5
            p.BackgroundTransparency = 1 - alpha
            p.Position = UDim2.new(0.5, math.cos(angle) * 140, 0.5, math.sin(angle) * 140)
        end
        if progress >= 1 then
            connection:Disconnect(); task.wait(0.3)
            local fade = TweenService:Create(splashBg, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
            fade:Play()
            fade.Completed:Connect(function() splashGui:Destroy(); callback() end)
        end
    end)
end

-- ============================================================
-- 2. TROLL EMOTES LOGIC
-- ============================================================
local function PlayEmote(target, animId)
    if not target or not target:FindFirstChildOfClass("Humanoid") then return end
    local hum = target:FindFirstChildOfClass("Humanoid")
    local animator = hum:FindFirstChildOfClass("Animator") or hum
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. animId
    local track = animator:LoadAnimation(anim)
    track:Play()
end

-- ============================================================
-- 3. COSMETICS & CHAMS
-- ============================================================
local function ApplyChams(character)
    if not character then return end
    local hl = character:FindFirstChild("CelestialChams") or Instance.new("Highlight")
    hl.Name = "CelestialChams"; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    hl.FillColor = CONFIG.Chams_Rainbow and Color3.fromHSV(tick() % 1, 1, 1) or CONFIG.Chams_Color
    hl.OutlineColor = hl.FillColor
    hl.Parent = character
end

local function RemoveChams(character)
    if character and character:FindFirstChild("CelestialChams") then character.CelestialChams:Destroy() end
end

local function CreateCosmetics()
    local char = LocalPlayer.Character
    if not char then return end

    local haloModel = Instance.new("Model", Workspace)
    haloModel.Name = "CelestialHalo"
    for i = 1, 16 do
        local ball = Instance.new("Part", haloModel)
        ball.Shape = Enum.PartType.Ball; ball.Size = Vector3.new(0.3, 0.3, 0.3)
        ball.Material = Enum.Material.Neon; ball.Color = CONFIG.Accent
        ball.Transparency = 0.1; ball.CanCollide = false; ball.Anchored = true
    end
    State.Cosmetics.Halo = haloModel

    local crownPart = Instance.new("Part", Workspace)
    crownPart.Name = "CelestialCrown"; crownPart.Size = Vector3.new(1, 1, 1)
    crownPart.Transparency = 1; crownPart.CanCollide = false; crownPart.Anchored = true
    local mesh = Instance.new("SpecialMesh", crownPart)
    mesh.MeshType = Enum.MeshType.FileMesh; mesh.MeshId = "rbxassetid://1323306"; mesh.Scale = Vector3.new(1.5, 1.5, 1.5)
    State.Cosmetics.Crown = crownPart

    local wingModel = Instance.new("Model", Workspace)
    wingModel.Name = "CelestialWings"
    local wingRoot = Instance.new("Part", wingModel)
    wingRoot.Name = "WingRoot"; wingRoot.Size = Vector3.new(0.1,0.1,0.1)
    wingRoot.Transparency = 1; wingRoot.CanCollide = false; wingRoot.Anchored = true
    
    local rootAttL = Instance.new("Attachment", wingRoot); rootAttL.Position = Vector3.new(-0.5, 1, 0)
    local rootAttR = Instance.new("Attachment", wingRoot); rootAttR.Position = Vector3.new(0.5, 1, 0)
    
    for i = 1, 6 do
        local attL = Instance.new("Attachment", wingRoot); attL.Position = Vector3.new(-1.5 - i * 0.8, 1 + i * 0.4, -1 - i * 0.5)
        local attR = Instance.new("Attachment", wingRoot); attR.Position = Vector3.new(1.5 + i * 0.8, 1 + i * 0.4, -1 - i * 0.5)
        
        local beamR = Instance.new("Beam", wingRoot); beamR.Attachment0 = rootAttR; beamR.Attachment1 = attR
        beamR.Color = ColorSequence.new(CONFIG.Accent, Color3.new(1,1,1)); beamR.Transparency = NumberSequence.new(0.2)
        beamR.Width0 = 2; beamR.Width1 = 0.1; beamR.CurveSize0 = 2; beamR.CurveSize1 = -2
        beamR.FaceCamera = true; beamR.LightEmission = 1; beamR.Texture = "rbxassetid://4966571357"
        
        local beamL = Instance.new("Beam", wingRoot); beamL.Attachment0 = rootAttL; beamL.Attachment1 = attL
        beamL.Color = ColorSequence.new(CONFIG.Accent, Color3.new(1,1,1)); beamL.Transparency = NumberSequence.new(0.2)
        beamL.Width0 = 2; beamL.Width1 = 0.1; beamL.CurveSize0 = -2; beamL.CurveSize1 = 2
        beamL.FaceCamera = true; beamL.LightEmission = 1; beamL.Texture = "rbxassetid://4966571357"
    end
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
                if ball.Name == "HaloBall" or ball:IsA("Part") then
                    local angle = (i / 16) * math.pi * 2 + tick() * 2
                    ball.CFrame = head.CFrame * CFrame.new(math.cos(angle) * 1.5, 1.2, math.sin(angle) * 1.5)
                    ball.Color = CONFIG.Accent
                end
            end
        end
    end

    if State.Cosmetics.Crown and head then
        State.Cosmetics.Crown.Transparency = CONFIG.CrownEnabled and 0 or 1
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
            local root = State.Cosmetics.Wings:FindFirstChild("WingRoot")
            if root then
                root.CFrame = hrp.CFrame * CFrame.new(0, 1.5, 0.5) * CFrame.Angles(math.rad(-15), 0, 0)
                for _, beam in ipairs(root:GetChildren()) do
                    if beam:IsA("Beam") then beam.Color = ColorSequence.new(CONFIG.Accent, Color3.new(1,1,1)) end
                end
            end
        end
    end
end

-- ============================================================
-- 4. MAIN UI
-- ============================================================
local mainGui, menuFrame

local function BuildMainUI()
    mainGui = Create("ScreenGui", { Name = "CelestialUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, Parent = LocalPlayer:WaitForChild("PlayerGui") })

    local keybindsFrame = Create("Frame", { Parent = mainGui, Size = UDim2.new(0, 180, 0, 320), Position = UDim2.new(0, 20, 0, 100), BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.1, BorderSizePixel = 0 }, { CreateCorner(8) })
    RegisterTheme(Create("UIStroke", { Parent = keybindsFrame, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.8 }), "stroke")

    local kbTitle = RegisterFont(Create("TextLabel", { Parent = keybindsFrame, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "Active Keybinds", Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12) }) }))
    RegisterTheme(kbTitle, "text")

    local kbList = Create("ScrollingFrame", { Parent = keybindsFrame, Size = UDim2.new(1, -20, 1, -35), Position = UDim2.new(0, 10, 0, 30), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y })
    Create("UIListLayout", { Parent = kbList, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })

    local function AddKeybindRow(name)
        local row = Create("Frame", { Parent = kbList, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
        RegisterFont(Create("TextLabel", { Parent = row, Size = UDim2.new(0.7, 0, 1, 0), BackgroundTransparency = 1, Text = name, Font = CONFIG.GUIFont, TextSize = 11, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left }))
        Create("TextLabel", { Parent = row, Size = UDim2.new(0, 30, 0, 18), Position = UDim2.new(1, -30, 0.5, -9), BackgroundColor3 = CONFIG.Bg, Text = "None", Font = Enum.Font.Code, TextSize = 10, TextColor3 = CONFIG.Accent }, { CreateCorner(4) })
    end
    AddKeybindRow("Toggle Menu"); AddKeybindRow("Fly"); AddKeybindRow("Noclip"); AddKeybindRow("Fling")

    menuFrame = Create("Frame", { Parent = mainGui, Size = UDim2.new(0, 560, 0, 400), Position = UDim2.new(0.5, -280, 0.5, -200), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.05, BorderSizePixel = 0 }, { CreateCorner(12) })
    RegisterTheme(Create("UIStroke", { Parent = menuFrame, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.6 }), "stroke")

    local header = Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1 })
    Create("ImageLabel", { Parent = header, Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 16, 0.5, -14), BackgroundTransparency = 1, Image = CELESTIAL_ASSET, ScaleType = Enum.ScaleType.Crop }, { CreateCorner(14) })
    
    RegisterFont(Create("TextLabel", { Parent = header, Size = UDim2.new(0, 200, 0, 20), Position = UDim2.new(0, 54, 0, 10), BackgroundTransparency = 1, Text = "Celestial", Font = CONFIG.GUIFont, TextSize = 16, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
    local subLbl = RegisterFont(Create("TextLabel", { Parent = header, Size = UDim2.new(0, 200, 0, 14), Position = UDim2.new(0, 54, 0, 28), BackgroundTransparency = 1, Text = "v4.6 | Legit & Troll", Font = CONFIG.GUIFont, TextSize = 11, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left }))
    RegisterTheme(subLbl, "text")

    Create("TextButton", { Parent = header, Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -36, 0.5, -12), BackgroundTransparency = 1, Text = "×", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = CONFIG.TextDark }).MouseButton1Click:Connect(function() menuFrame.Visible = false end)

    local sidebar = Create("Frame", { Parent = menuFrame, Size = UDim2.new(0, 140, 1, -50), Position = UDim2.new(0, 0, 0, 50), BackgroundTransparency = 1 })
    Create("UIListLayout", { Parent = sidebar, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center })
    Create("UIPadding", { Parent = sidebar, PaddingTop = UDim.new(0, 10) })

    local content = Create("Frame", { Parent = menuFrame, Size = UDim2.new(1, -160, 1, -70), Position = UDim2.new(0, 150, 0, 60), BackgroundTransparency = 1 })

    local Pages = {}
    local function CreateTab(name, order)
        local btn = Create("TextButton", { Parent = sidebar, Size = UDim2.new(0, 120, 0, 32), BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.5, Text = "  " .. name, Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order }, { CreateCorner(6) })
        Create("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0, 10) })
        RegisterFont(btn)
        
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
    end

    local homePage = CreateTab("Home", 1); local combatPage = CreateTab("Combat", 2)
    local visPage = CreateTab("Visuals", 3); local trollPage = CreateTab("Troll", 4)
    local movePage = CreateTab("Movement", 5); local settingsPage = CreateTab("Settings", 6)

    -- HOME
    local infoCard = CreateCard(homePage, "Player Profile")
    RegisterFont(Create("TextLabel", { Parent = infoCard, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "User: " .. LocalPlayer.Name, Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left }))
    
    -- COMBAT
    local combatCard = CreateCard(combatPage, "Aimbot Settings")
    CreateToggle(combatCard, "Enable Aimbot (RMB)", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end)
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
    local trollCard = CreateCard(trollPage, "Trolling")
    CreateToggle(trollCard, "Auto Fling Nearby", CONFIG.FlingEnabled, function(v) CONFIG.FlingEnabled = v end)
    local flingBtn = Create("TextButton", { Parent = trollCard, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = CONFIG.Accent, Text = "Fling Everyone", Font = CONFIG.GUIFont, TextSize = 12, TextColor3 = CONFIG.Text }, { CreateCorner(6) })
    flingBtn.MouseButton1Click:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bv = Instance.new("BodyVelocity", hrp); bv.Velocity = Vector3.new(1e5, 1e5, 1e5); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); Debris:AddItem(bv, 0.5)
                    local bav = Instance.new("BodyAngularVelocity", hrp); bav.AngularVelocity = Vector3.new(1e5, 1e5, 1e5); bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); Debris:AddItem(bav, 0.5)
                end
            end
        end
    end)
    
    -- ЭМОЦИИ
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
            if closest then PlayEmote(closest, animId) end
        end)
    end
    AddEmoteBtn("Bang", "5269855227")
    AddEmoteBtn("Dance", "507771019")
    AddEmoteBtn("Laugh", "507770818")

    -- MOVEMENT
    local moveCard = CreateCard(movePage, "Movement (Anti-Cheat Safe)")
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
        {Name = "Purple", Color = Color3.fromRGB(160, 100, 255)}, {Name = "Blue", Color = Color3.fromRGB(100, 150, 255)},
        {Name = "Green", Color = Color3.fromRGB(100, 255, 150)}, {Name = "Red", Color = Color3.fromRGB(255, 100, 100)},
        {Name = "Pink", Color = Color3.fromRGB(255, 100, 200)}, {Name = "White", Color = Color3.fromRGB(240, 240, 240)},
        {Name = "Orange", Color = Color3.fromRGB(255, 180, 100)}, {Name = "Cyan", Color = Color3.fromRGB(100, 255, 255)},
    }

    for _, c in ipairs(colors) do
        local btn = Create("TextButton", { Parent = paletteFrame, Size = UDim2.new(0, 28, 0, 28), BackgroundColor3 = c.Color, Text = "" }, { CreateCorner(14) })
        Create("UIStroke", { Parent = btn, Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.5 })
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
    unloadBtn.MouseButton1Click:Connect(function() 
        State.Running = false
        if mainGui then mainGui:Destroy() end
        StopFly()
        StopLegitFly()
        for _, d in ipairs(State.Drawings) do pcall(function() d:Remove() end) end
        for _, c in ipairs(State.Connections) do pcall(function() c:Disconnect() end) end
    end)

    local quickFrame = Create("Frame", { Parent = mainGui, Size = UDim2.new(0, 100, 0, 300), Position = UDim2.new(1, -120, 0.5, -150), BackgroundTransparency = 1 })
    Create("UIListLayout", { Parent = quickFrame, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Right })

    local function AddQuickBtn(text, cb)
        local btn = Create("TextButton", { Parent = quickFrame, Size = UDim2.new(0, 50, 0, 50), BackgroundColor3 = CONFIG.CardBg, Text = text, Font = CONFIG.GUIFont, TextSize = 10, TextColor3 = CONFIG.TextDark }, { CreateCorner(25) })
        RegisterTheme(Create("UIStroke", { Parent = btn, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.8 }), "stroke")
        btn.MouseButton1Click:Connect(cb)
    end
    AddQuickBtn("FLY", function() CONFIG.FlyEnabled = not CONFIG.FlyEnabled; if not CONFIG.FlyEnabled then StopFly() end end)
    AddQuickBtn("NOCLIP", function() CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled end)
    AddQuickBtn("ESP", function() CONFIG.ESPEnabled = not CONFIG.ESPEnabled end)

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
-- 5. MOVEMENT & LOGIC (Anti-Cheat Bypass)
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
    if State.LegitFlyPart then State.LegitFlyPart:Destroy(); State.LegitFlyPart = nil end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local align = hrp:FindFirstChild("LegitAlign")
            if align then align:Destroy() end
            local orient = hrp:FindFirstChild("LegitOrient")
            if orient then orient:Destroy() end
        end
    end
end

local function StartLegitFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    StopLegitFly()
    
    local align = Instance.new("AlignPosition", hrp)
    align.Name = "LegitAlign"
    align.Mode = Enum.PositionAlignmentMode.OneAttachment
    align.Attachment0 = Instance.new("Attachment", hrp)
    align.MaxForce = 25000
    align.Responsiveness = 10
    
    local orient = Instance.new("AlignOrientation", hrp)
    orient.Name = "LegitOrient"
    orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
    orient.Attachment0 = Instance.new("Attachment", hrp)
    orient.MaxTorque = 25000
    orient.Responsiveness = 10
end

Track(RunService.Stepped:Connect(function(_, dt)
    if not State.Running then return end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and CONFIG.SpeedEnabled then hum.WalkSpeed = CONFIG.WalkSpeed elseif hum then hum.WalkSpeed = 16 end
        if CONFIG.NoclipEnabled then for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
    end

    -- Legit Fly (Плавный обход античита)
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
            
            if move.Magnitude > 0 then
                align.Position = hrp.Position + move.Unit * CONFIG.FlySpeed * dt
            else
                align.Position = hrp.Position
            end
        end
    end

    -- Fast Fly (Обычный)
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

    -- Fling
    if CONFIG.FlingEnabled then
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if myRoot then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - myRoot.Position).Magnitude < 25 then
                        local bv = Instance.new("BodyVelocity", hrp); bv.Velocity = Vector3.new(1e5, 1e5, 1e5); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); Debris:AddItem(bv, 0.5)
                        local bav = Instance.new("BodyAngularVelocity", hrp); bav.AngularVelocity = Vector3.new(1e5, 1e5, 1e5); bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); Debris:AddItem(bav, 0.5)
                    end
                end
            end
        end
    end
end))

-- ============================================================
-- 6. AIMBOT (Legit Mode)
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
    local mouse = UserInputService:GetMouseLocation()

    FOVCircle.Position = mouse
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
                        local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                        if d < bestD then bestD = d; best = part end
                    end
                end
            end
        end
        if best then
            local sp = cam:WorldToViewportPoint(best.Position)
            local smooth = CONFIG.LegitAimEnabled and (CONFIG.AimSmooth * 0.5) or CONFIG.AimSmooth
            if typeof(mousemoverel) == "function" then
                mousemoverel((sp.X - mouse.X) * smooth, (sp.Y - mouse.Y) * smooth)
            end
            if CONFIG.AimAutoFire and tick() % 0.1 < 0.02 then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then pcall(function() tool:Activate() end) end
            end
        end
    end
    
    if frameTick % 3 == 0 then
        UpdateCosmetics()
        if CONFIG.Chams_Self then ApplyChams(LocalPlayer.Character) else RemoveChams(LocalPlayer.Character) end
    end
end))

-- ============================================================
-- 7. ESP
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
                    local h = math.abs(rSp.Y - hSp.Y)
                    local w = h * 0.55
                    local dist = (hrp.Position - Workspace.CurrentCamera.CFrame.Position).Magnitude
                    
                    t.box.Visible = CONFIG.ESP_Box
                    t.box.Position = Vector2.new(hSp.X - w/2, hSp.Y); t.box.Size = Vector2.new(w, h); t.box.Color = CONFIG.Accent; t.box.Thickness = 1
                    t.name.Visible = true; t.name.Text = p.Name; t.name.Position = Vector2.new(hSp.X, hSp.Y - 15); t.name.Color = Color3.new(1,1,1); t.name.Size = 13; t.name.Center = true; t.name.Outline = true; t.name.Font = CONFIG.ESP_Font
                    t.dist.Visible = true; t.dist.Text = math.floor(dist).."m"; t.dist.Position = Vector2.new(hSp.X, hSp.Y + h + 2); t.dist.Color = Color3.fromRGB(200,200,200); t.dist.Size = 11; t.dist.Center = true; t.dist.Outline = true; t.dist.Font = CONFIG.ESP_Font

                    if CONFIG.ESP_Health then
                        local r = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        t.healthBg.Visible = true; t.healthBg.Position = Vector2.new(hSp.X - w/2 - 5, hSp.Y); t.healthBg.Size = Vector2.new(3, h); t.healthBg.Color = Color3.fromRGB(30,30,30); t.healthBg.Filled = true
                        t.healthBar.Visible = true; t.healthBar.Position = Vector2.new(hSp.X - w/2 - 5, hSp.Y + h*(1-r)); t.healthBar.Size = Vector2.new(3, h*r); t.healthBar.Color = Color3.fromRGB(255*(1-r), 255*r, 80); t.healthBar.Filled = true
                    else
                        t.healthBg.Visible = false; t.healthBar.Visible = false
                    end
                else
                    t.box.Visible = false; t.name.Visible = false; t.healthBg.Visible = false; t.healthBar.Visible = false; t.dist.Visible = false
                end
            end
        end
    end

    for p, t in pairs(State.ESPCache) do
        if not active[p] then
            t.box:Remove(); t.name:Remove(); t.healthBg:Remove(); t.healthBar:Remove(); t.dist:Remove()
            State.ESPCache[p] = nil
            RemoveChams(p.Character)
        end
    end
end))

-- ============================================================
-- 8. HOTKEYS
-- ============================================================
Track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Keybinds.ToggleMenu then
        if menuFrame then menuFrame.Visible = not menuFrame.Visible end
    elseif input.KeyCode == Keybinds.Fly then
        CONFIG.FlyEnabled = not CONFIG.FlyEnabled; if not CONFIG.FlyEnabled then StopFly() end
    elseif input.KeyCode == Keybinds.Noclip then
        CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled
        if not CONFIG.NoclipEnabled and LocalPlayer.Character then
            for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end
        end
    elseif input.KeyCode == Keybinds.Fling then
        CONFIG.FlingEnabled = not CONFIG.FlingEnabled
    elseif input.KeyCode == Keybinds.Unload then
        State.Running = false; StopFly(); StopLegitFly(); if mainGui then mainGui:Destroy() end
        for _, d in ipairs(State.Drawings) do pcall(function() d:Remove() end) end
        for _, c in ipairs(State.Connections) do pcall(function() c:Disconnect() end) end
    end
end))

-- ============================================================
-- 9. INIT
-- ============================================================
PlaySplash(function()
    pcall(CreateCosmetics)
    pcall(BuildMainUI)
    print("[Celestial] v4.6 Loaded. Legit Modes & Troll Emotes added.")
end)
