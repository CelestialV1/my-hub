-- ============================================================
-- CELESTIAL v10.5 — HUD + QUICK ACTIONS RESTORED
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local CELESTIAL_ASSET = "rbxassetid://94872985442978"
local VERSION = "10.5"
local CONFIG_FOLDER = "CelestialConfigs"

local CONFIG = {
    Accent = Color3.fromRGB(160, 110, 255), Accent2 = Color3.fromRGB(255, 100, 200),
    Bg = Color3.fromRGB(8, 8, 12), CardBg = Color3.fromRGB(18, 18, 24),
    Text = Color3.fromRGB(240, 240, 250), TextDark = Color3.fromRGB(140, 140, 160),

    AimbotEnabled = false, AimbotFOV = 200, AimbotSmooth = 0.35,
    KillAuraEnabled = false, KillAuraRange = 25,
    
    ESPEnabled = true, ESPBox = true, ESPHealth = true, ESPName = true, ESPDistance = true, 
    ESPSkeleton = true, ESPWeapon = true, ESPTracer = true, ESPHeadDot = true, ESPMaxDist = 1500,
    TargetHUD = true,

    ChamsEnemy = false, ChamsRainbow = false,

    WingsEnabled = false, CrownEnabled = false, HaloEnabled = false,
    OrbitEnabled = false, GroundCircle = false,

    Fullbright = false, NoFog = false,

    FlyEnabled = false, FlySpeed = 60, NoclipEnabled = false,
    SpeedEnabled = false, WalkSpeed = 50, JumpPower = 50, InfiniteJump = false,
    
    FlingEnabled = false, FlingRange = 25, InvisibleEnabled = false,
    
    ShowHUD = true, ShowQuickButtons = true,
}

local BINDS = {
    ToggleMenu = Enum.KeyCode.H, Fly = Enum.KeyCode.Unknown, Noclip = Enum.KeyCode.Unknown,
    Speed = Enum.KeyCode.Unknown, Aimbot = Enum.KeyCode.Unknown, KillAura = Enum.KeyCode.Unknown,
    Fling = Enum.KeyCode.Unknown, Invisible = Enum.KeyCode.Unknown,
}

local State = {
    Running = true, Connections = {}, Drawings = {}, ESPCache = {}, ChamsCache = {},
    ThemeObjects = {}, SearchWidgets = {}, Cosmetics = {}, menuFrame = nil, mainGui = nil,
    KillAuraCooldown = 0, WaitingForBind = nil,
    OriginalLighting = { Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient },
}

local function Track(c) if State.Running and c then table.insert(State.Connections, c) end return c end
local function TrackD(d) if State.Running and d then table.insert(State.Drawings, d) end return d end
local function RegisterSearch(w) if State.Running then table.insert(State.SearchWidgets, w) end end

local Draw = Drawing.new
local FOVCircle = TrackD(Draw("Circle"))
FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 64; FOVCircle.Color = CONFIG.Accent; FOVCircle.Transparency = 0.9; FOVCircle.Radius = CONFIG.AimbotFOV; FOVCircle.Visible = false

local function Create(c, p, ch)
    local i = Instance.new(c)
    for k, v in pairs(p) do i[k] = v end
    if ch then for _, c2 in ipairs(ch) do c2.Parent = i end end
    return i
end
local function Corner(r) return Create("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function ApplyGradient(stroke) local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2); g.Rotation = 45; g.Parent = stroke end

-- NOTIFICATIONS
local notifGui = Create("ScreenGui", { Name = "CelestialNotifs", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1002, Parent = LocalPlayer:WaitForChild("PlayerGui") })
local notifFrame = Create("Frame", { Parent = notifGui, Size = UDim2.new(0, 320, 1, 0), Position = UDim2.new(1, -340, 0, 100), BackgroundTransparency = 1, ZIndex = 5 })
Create("UIListLayout", { Parent = notifFrame, Padding = UDim.new(0, 6) })
local function Notify(text, duration)
    duration = duration or 2.5
    local card = Create("Frame", { Parent = notifFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 6 }, { Corner(8) })
    local s = Create("UIStroke", { Parent = card, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.3 }); ApplyGradient(s)
    Create("Frame", { Parent = card, Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0, ZIndex = 7 }, { Corner(2) })
    Create("TextLabel", { Parent = card, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 })
    card.Position = UDim2.new(1, 20, 0, 0); TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    task.delay(duration, function() TweenService:Create(card, TweenInfo.new(0.25), { Position = UDim2.new(1, 20, 0, 0) }):Play(); task.delay(0.25, function() card:Destroy() end) end)
end

-- ============================================================
-- COSMETICS
-- ============================================================
local function BuildCosmetics()
    if not State.Cosmetics.Halo then
        local m = Instance.new("Model", Workspace); m.Name = "Celestial_Halo"
        for i = 1, 20 do local b = Instance.new("Part", m); b.Name = "HaloBall"; b.Shape = Enum.PartType.Ball; b.Size = Vector3.new(0.28,0.28,0.28); b.Material = Enum.Material.Neon; b.Color = CONFIG.Accent; b.Transparency = 0.1; b.CanCollide = false; b.CanQuery = false; b.Anchored = true end
        State.Cosmetics.Halo = m
    end
    if not State.Cosmetics.Crown then
        local c = Instance.new("Part", Workspace); c.Name = "Celestial_Crown"; c.Size = Vector3.new(1.5,1,1.5); c.Transparency = 1; c.CanCollide = false; c.CanQuery = false; c.Anchored = true
        local mesh = Instance.new("SpecialMesh", c); mesh.MeshType = Enum.MeshType.FileMesh; mesh.MeshId = "rbxassetid://176213013"; mesh.Scale = Vector3.new(0.9,0.9,0.9)
        State.Cosmetics.Crown = c
    end
    if not State.Cosmetics.Wings then
        local m = Instance.new("Model", Workspace); m.Name = "Celestial_Wings"
        local left = Instance.new("Part", m); left.Name = "LeftWing"; left.Size = Vector3.new(4, 1, 2); left.Transparency = 0; left.CanCollide = false; left.CanQuery = false; left.Anchored = false; left.Material = Enum.Material.Neon
        local lm = Instance.new("SpecialMesh", left); lm.MeshType = Enum.MeshType.FileMesh; lm.MeshId = "rbxassetid://1553468234"; lm.Scale = Vector3.new(0.048, 0.048, 0.048)
        local right = Instance.new("Part", m); right.Name = "RightWing"; right.Size = Vector3.new(4, 1, 2); right.Transparency = 0; right.CanCollide = false; right.CanQuery = false; right.Anchored = false; right.Material = Enum.Material.Neon
        local rm = Instance.new("SpecialMesh", right); rm.MeshType = Enum.MeshType.FileMesh; rm.MeshId = "rbxassetid://1553468709"; rm.Scale = Vector3.new(0.048, 0.048, 0.048)
        State.Cosmetics.Wings = { Left = left, Right = right, Model = m }
    end
    if not State.Cosmetics.Orbit then
        local m = Instance.new("Model", Workspace); m.Name = "Celestial_Orbit"
        for i = 1, 6 do local b = Instance.new("Part", m); b.Name = "OrbitBall"; b.Shape = Enum.PartType.Ball; b.Size = Vector3.new(0.4,0.4,0.4); b.Material = Enum.Material.Neon; b.Color = CONFIG.Accent; b.Transparency = 0.2; b.CanCollide = false; b.CanQuery = false; b.Anchored = true end
        State.Cosmetics.Orbit = m
    end
    if not State.Cosmetics.GroundCircle then
        local gc = Instance.new("Part", Workspace); gc.Name = "Celestial_GroundCircle"; gc.Shape = Enum.PartType.Cylinder; gc.Size = Vector3.new(0.1,10,10); gc.Material = Enum.Material.Neon; gc.Color = CONFIG.Accent; gc.Transparency = 0.5; gc.CanCollide = false; gc.CanQuery = false; gc.Anchored = true
        State.Cosmetics.GroundCircle = gc
    end
end

local function UpdateCosmetics()
    local char = LocalPlayer.Character; if not char then return end
    local head = char:FindFirstChild("Head"); local hrp = char:FindFirstChild("HumanoidRootPart"); local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local t = tick()

    if State.Cosmetics.Halo and head then
        State.Cosmetics.Halo.Parent = CONFIG.HaloEnabled and Workspace or nil
        if CONFIG.HaloEnabled then for i, b in ipairs(State.Cosmetics.Halo:GetChildren()) do if b.Name == "HaloBall" then local a = (i/20) * math.pi * 2 + t*2; b.CFrame = head.CFrame * CFrame.new(math.cos(a)*1.6, 1.3, math.sin(a)*1.6); b.Color = Color3.fromHSV((t*0.2 + i/20) % 1, 0.8, 1) end end end
    end
    if State.Cosmetics.Crown and head then
        State.Cosmetics.Crown.Parent = CONFIG.CrownEnabled and Workspace or nil
        if CONFIG.CrownEnabled then State.Cosmetics.Crown.CFrame = head.CFrame * CFrame.new(0,0.75,0); State.Cosmetics.Crown.Color = CONFIG.Accent end
    end
    if State.Cosmetics.Wings and torso then
        local w = State.Cosmetics.Wings
        w.Model.Parent = CONFIG.WingsEnabled and Workspace or nil
        if CONFIG.WingsEnabled then
            local lw, rw = w.Left, w.Right
            if not lw:FindFirstChild("Weld") then
                lw.CFrame = torso.CFrame * CFrame.new(-1.2, 0.5, 0.5) * CFrame.Angles(0, math.rad(90), math.rad(-15))
                local weld = Instance.new("WeldConstraint", lw); weld.Name = "Weld"; weld.Part0 = torso; weld.Part1 = lw
            end
            if not rw:FindFirstChild("Weld") then
                rw.CFrame = torso.CFrame * CFrame.new(1.2, 0.5, 0.5) * CFrame.Angles(0, math.rad(-90), math.rad(15))
                local weld = Instance.new("WeldConstraint", rw); weld.Name = "Weld"; weld.Part0 = torso; weld.Part1 = rw
            end
            lw.Color = Color3.fromHSV(t % 1, 0.9, 1); rw.Color = Color3.fromHSV((t+0.5) % 1, 0.9, 1)
        else
            for _, p in ipairs({w.Left, w.Right}) do local wc = p:FindFirstChild("Weld"); if wc then wc:Destroy() end end
        end
    end
    if State.Cosmetics.Orbit and hrp then
        State.Cosmetics.Orbit.Parent = CONFIG.OrbitEnabled and Workspace or nil
        if CONFIG.OrbitEnabled then
            for i, b in ipairs(State.Cosmetics.Orbit:GetChildren()) do if b.Name == "OrbitBall" then local a = t*2 + (i * math.pi / 3); b.CFrame = hrp.CFrame * CFrame.new(math.cos(a)*3, 0, math.sin(a)*3); b.Color = Color3.fromHSV((t*0.2 + i*0.1) % 1, 0.8, 1) end end
        end
    end
    if State.Cosmetics.GroundCircle and hrp then
        State.Cosmetics.GroundCircle.Parent = CONFIG.GroundCircle and Workspace or nil
        if CONFIG.GroundCircle then State.Cosmetics.GroundCircle.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)); State.Cosmetics.GroundCircle.Color = CONFIG.Accent; State.Cosmetics.GroundCircle.Transparency = 0.5 + math.sin(t*3)*0.1 end
    end
end

local function ApplyChams(char)
    if not char or char == LocalPlayer.Character then return end
    local hl = char:FindFirstChild("Celestial_Chams")
    if not hl then hl = Instance.new("Highlight", char); hl.Name = "Celestial_Chams"; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0 end
    hl.FillColor = CONFIG.ChamsRainbow and Color3.fromHSV(tick() % 1, 1, 1) or CONFIG.Accent; hl.OutlineColor = hl.FillColor; State.ChamsCache[char] = hl
end
local function RemoveChams(char) if char then local hl = char:FindFirstChild("Celestial_Chams"); if hl then hl:Destroy() end; State.ChamsCache[char] = nil end end

local function StopFly()
    local char = LocalPlayer.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp then for _, c in ipairs(hrp:GetChildren()) do if c.Name == "Celestial_FlyBV" or c.Name == "Celestial_FlyBG" then c:Destroy() end end end
    local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand = false end
end

local function FlingMethod1(hrp) local bv = Instance.new("BodyVelocity", hrp); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.Velocity = Vector3.new(1e5, 1e5, 1e5); Debris:AddItem(bv, 0.4); local bav = Instance.new("BodyAngularVelocity", hrp); bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); bav.AngularVelocity = Vector3.new(1e5, 1e5, 1e5); Debris:AddItem(bav, 0.4) end
local function FlingMethod2(char) local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart"); if hum and hrp then hum:ChangeState(Enum.HumanoidStateType.Physics); hrp.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5); hrp.AssemblyAngularVelocity = Vector3.new(1e5, 1e5, 1e5) end end
local function FlingMethod3(char) local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end; pcall(function() hrp:SetNetworkOwner(LocalPlayer); hrp.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5) end) end
local function ForceFling(char, method) if not char then return end; local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end; if method == 1 then FlingMethod1(hrp) elseif method == 2 then FlingMethod2(char) elseif method == 3 then FlingMethod3(char) end end

local function ApplyGhost()
    local char = LocalPlayer.Character; if not char then return end
    for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.Transparency = 1; v.LocalTransparencyModifier = 1; if v.Name ~= "HumanoidRootPart" then v.CanCollide = false end elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end end
    local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.NameDisplayDistance = 0; hum.HealthDisplayDistance = 0 end
end
local function RestoreVis()
    local char = LocalPlayer.Character; if not char then return end
    for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.Transparency = 0; v.LocalTransparencyModifier = 0; if v.Name ~= "HumanoidRootPart" then v.CanCollide = true end elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 0 end end
    local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer; hum.NameDisplayDistance = 100; hum.HealthDisplayDistance = 100 end
end

-- ============================================================
-- TOP WATERMARK HUD
-- ============================================================
local wmGui = Create("ScreenGui", { Name = "CelestialWM", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 998, Parent = LocalPlayer:WaitForChild("PlayerGui") })
local wmFrame = Create("Frame", { Parent = wmGui, Size = UDim2.new(0, 560, 0, 30), Position = UDim2.new(0.5, -280, 0, 12), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 3, Visible = CONFIG.ShowHUD }, { Corner(8) })
local wmStroke = Create("UIStroke", { Parent = wmFrame, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.4 }); ApplyGradient(wmStroke)
local wmText = Create("TextLabel", { Parent = wmFrame, Size = UDim2.new(1,-20,1,0), Position = UDim2.new(0,10,0,0), BackgroundTransparency = 1, Text = "Loading...", Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = CONFIG.Text, ZIndex = 4 })

local fps, acc = 0, 0
Track(RunService.Heartbeat:Connect(function(dt)
    if not State.Running then return end
    if CONFIG.ShowHUD then
        fps += 1; acc += dt
        if acc >= 1 then
            local ping = "N/A"
            pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end)
            local time = os.date("!%H:%M:%S", os.time() + (3*3600))
            wmText.Text = string.format("✦ CELESTIAL v%s  |  %s  |  %d FPS  |  %s  |  %s", VERSION, LocalPlayer.Name, fps, ping, time)
            fps = 0; acc = 0
        end
    end
end))

-- ============================================================
-- QUICK ACTIONS (RIGHT SIDE FLOATING BUTTONS)
-- ============================================================
local qaGui = Create("ScreenGui", { Name = "CelestialQA", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 997, Parent = LocalPlayer:WaitForChild("PlayerGui") })
local qaFrame = Create("Frame", { Parent = qaGui, Size = UDim2.new(0, 110, 0, 400), Position = UDim2.new(1, -130, 0.5, -200), BackgroundTransparency = 1, Visible = CONFIG.ShowQuickButtons })
local qaList = Create("UIListLayout", { Parent = qaFrame, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right })

local function CreateQAButton(name, icon, cb)
    local btn = Create("TextButton", { Parent = qaFrame, Size = UDim2.new(0, 50, 0, 50), BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.15, Text = "", BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 3 }, { Corner(25) })
    local stroke = Create("UIStroke", { Parent = btn, Color = CONFIG.Accent, Thickness = 1.5, Transparency = 0.4 }); ApplyGradient(stroke)
    Create("TextLabel", { Parent = btn, Size = UDim2.new(1,0,0,20), Position = UDim2.new(0,0,0.3,0), BackgroundTransparency = 1, Text = icon, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = CONFIG.Text, ZIndex = 4 })
    Create("TextLabel", { Parent = btn, Size = UDim2.new(1,0,0,10), Position = UDim2.new(0,0,0.6,0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.Gotham, TextSize = 8, TextColor3 = CONFIG.TextDark, ZIndex = 4 })
    btn.MouseEnter:Connect(function() TweenService:Create(stroke, TweenInfo.new(0.15), { Transparency = 0 }):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(stroke, TweenInfo.new(0.15), { Transparency = 0.4 }):Play() end)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local flyQA, speedQA, noclipQA, espQA, flingQA

flyQA = CreateQAButton("FLY", "✈", function() CONFIG.FlyEnabled = not CONFIG.FlyEnabled; if not CONFIG.FlyEnabled then StopFly() end; Notify("Fly: "..(CONFIG.FlyEnabled and "ON" or "OFF"), 1.5) end)
speedQA = CreateQAButton("SPEED", "⚡", function() CONFIG.SpeedEnabled = not CONFIG.SpeedEnabled; Notify("Speed: "..(CONFIG.SpeedEnabled and "ON" or "OFF"), 1.5) end)
noclipQA = CreateQAButton("NOCLIP", "👻", function() CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled; Notify("Noclip: "..(CONFIG.NoclipEnabled and "ON" or "OFF"), 1.5) end)
espQA = CreateQAButton("ESP", "👁", function() CONFIG.ESPEnabled = not CONFIG.ESPEnabled; Notify("ESP: "..(CONFIG.ESPEnabled and "ON" or "OFF"), 1.5) end)
flingQA = CreateQAButton("FLING", "🌀", function() CONFIG.FlingEnabled = not CONFIG.FlingEnabled; Notify("Fling: "..(CONFIG.FlingEnabled and "ON" or "OFF"), 1.5) end)

-- ============================================================
-- TARGET HUD
-- ============================================================
local targetGui = Create("ScreenGui", { Name = "CelestialTarget", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000, Parent = LocalPlayer:WaitForChild("PlayerGui") })
local targetFrame = Create("Frame", { Parent = targetGui, Size = UDim2.new(0, 250, 0, 80), Position = UDim2.new(0.5, -125, 0.5, 100), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.2, BorderSizePixel = 0, Visible = false }, { Corner(8) })
local targetStroke = Create("UIStroke", { Parent = targetFrame, Color = CONFIG.Accent, Thickness = 1 }); ApplyGradient(targetStroke)
local headImg = Create("ImageLabel", { Parent = targetFrame, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 10, 0.5, -25), BackgroundTransparency = 1, Image = "" }, { Corner(25) })
local nameLbl = Create("TextLabel", { Parent = targetFrame, Size = UDim2.new(1, -70, 0, 20), Position = UDim2.new(0, 70, 0, 10), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left })
local hpBarBg = Create("Frame", { Parent = targetFrame, Size = UDim2.new(1, -80, 0, 8), Position = UDim2.new(0, 70, 0, 35), BackgroundColor3 = Color3.fromRGB(30,30,40), BorderSizePixel = 0 }, { Corner(4) })
local hpBarFill = Create("Frame", { Parent = hpBarBg, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(100, 255, 100), BorderSizePixel = 0 }, { Corner(4) })
local wepLbl = Create("TextLabel", { Parent = targetFrame, Size = UDim2.new(1, -70, 0, 20), Position = UDim2.new(0, 70, 0, 48), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left })

-- ============================================================
-- UI BUILD
-- ============================================================
local function BuildUI()
    local gui = Create("ScreenGui", { Name = "CelestialUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, Parent = LocalPlayer:WaitForChild("PlayerGui") })
    State.mainGui = gui

    local menu = Create("Frame", { Parent = gui, Size = UDim2.new(0, 640, 0, 460), Position = UDim2.new(0.5, -320, 1, 500), BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.02, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2 }, { Corner(14) })
    State.menuFrame = menu
    local ms = Create("UIStroke", { Parent = menu, Thickness = 1.5, Transparency = 0.2, Color = CONFIG.Accent }); ApplyGradient(ms)

    local header = Create("Frame", { Parent = menu, Size = UDim2.new(1,0,0,62), BackgroundTransparency = 1, ZIndex = 3 })
    Create("TextLabel", { Parent = header, Size = UDim2.new(0,200,0,22), Position = UDim2.new(0,20,0,12), BackgroundTransparency = 1, Text = "Celestial", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
    Create("TextLabel", { Parent = header, Size = UDim2.new(0,260,0,16), Position = UDim2.new(0,20,0,34), BackgroundTransparency = 1, Text = "v"..VERSION.." | Premium", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })

    local closeBtn = Create("TextButton", { Parent = header, Size = UDim2.new(0,32,0,32), Position = UDim2.new(1,-46,0.5,-16), BackgroundColor3 = Color3.fromRGB(35,35,45), Text = "×", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = CONFIG.TextDark, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 4 }, { Corner(10) })
    closeBtn.MouseButton1Click:Connect(function() TweenService:Create(menu, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -320, 1, 500) }):Play(); task.wait(0.3); menu.Visible = false end)

    local sidebar = Create("Frame", { Parent = menu, Size = UDim2.new(0,160,1,-80), Position = UDim2.new(0,20,0,72), BackgroundTransparency = 1, ZIndex = 3 })
    Create("UIListLayout", { Parent = sidebar, Padding = UDim.new(0,6) })
    local content = Create("Frame", { Parent = menu, Size = UDim2.new(1,-200,1,-80), Position = UDim2.new(0,180,0,72), BackgroundTransparency = 1, ZIndex = 3 })

    local Pages = {}; local Tabs = {}
    local function CreateTab(name, icon, order)
        local btn = Create("TextButton", { Parent = sidebar, Size = UDim2.new(1,0,0,36), BackgroundColor3 = Color3.fromRGB(24,24,32), BackgroundTransparency = 0.4, Text = "  " .. icon .. "   " .. name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, LayoutOrder = order, AutoButtonColor = false, ZIndex = 4 }, { Corner(8) })
        local stroke = Create("UIStroke", { Parent = btn, Color = CONFIG.Accent, Thickness = 1, Transparency = 1 })
        local page = Create("ScrollingFrame", { Parent = content, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), BorderSizePixel = 0, ZIndex = 3 })
        Create("UIListLayout", { Parent = page, Padding = UDim.new(0,10) })
        Pages[name] = page; Tabs[name] = { btn = btn, stroke = stroke }
        btn.MouseButton1Click:Connect(function() for n, p in pairs(Pages) do p.Visible = (n == name) end; for n, t2 in pairs(Tabs) do TweenService:Create(t2.btn, TweenInfo.new(0.2), { TextColor3 = (n == name) and CONFIG.Accent or CONFIG.TextDark, BackgroundTransparency = (n == name) and 0.15 or 0.4 }):Play(); TweenService:Create(t2.stroke, TweenInfo.new(0.2), { Transparency = (n == name) and 0.4 or 1 }):Play() end end)
        return page
    end

    local function CreateCard(parent, title)
        local card = Create("Frame", { Parent = parent, Size = UDim2.new(1,-8,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 4 }, { Corner(10) })
        Create("UIStroke", { Parent = card, Color = Color3.fromRGB(50,50,65), Thickness = 1, Transparency = 0.4 })
        Create("UIPadding", { Parent = card, PaddingTop = UDim.new(0,14), PaddingBottom = UDim.new(0,14), PaddingLeft = UDim.new(0,14), PaddingRight = UDim.new(0,14) })
        Create("UIListLayout", { Parent = card, Padding = UDim.new(0,10) })
        if title then Create("TextLabel", { Parent = card, Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1, Text = title:upper(), Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }) end
        return card
    end

    local function CreateToggle(parent, text, bindKey, default, cb, order)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1, LayoutOrder = order or 1 })
        local bindBtn = Create("TextButton", { Parent = row, Size = UDim2.new(0,50,0,20), Position = UDim2.new(1,-70,0.5,-10), BackgroundColor3 = Color3.fromRGB(35,35,45), Text = BINDS[bindKey] and BINDS[bindKey].Name or "None", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = CONFIG.TextDark, BorderSizePixel = 0, ZIndex = 6 }, { Corner(4) })
        bindBtn.MouseButton1Click:Connect(function() end)
        bindBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton3 then if State.WaitingForBind then return end; bindBtn.Text = "..."; State.WaitingForBind = function(kc) BINDS[bindKey] = kc; bindBtn.Text = kc.Name; State.WaitingForBind = nil; Notify("Binded "..text.." to "..kc.Name, 1.5) end end end)
        Create("TextLabel", { Parent = row, Size = UDim2.new(1,-120,1,0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
        local sw = Create("Frame", { Parent = row, Size = UDim2.new(0,28,0,14), Position = UDim2.new(1,-28,0.5,-7), BackgroundColor3 = default and CONFIG.Accent or Color3.fromRGB(40,40,50), BorderSizePixel = 0, ZIndex = 5 }, { Corner(7) })
        local kn = Create("Frame", { Parent = sw, Size = UDim2.new(0,10,0,10), Position = default and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 6 }, { Corner(5) })
        local state = default
        local click = Create("TextButton", { Parent = row, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 7 })
        click.MouseButton1Click:Connect(function() state = not state; TweenService:Create(sw, TweenInfo.new(0.2), { BackgroundColor3 = state and CONFIG.Accent or Color3.fromRGB(40,40,50) }):Play(); TweenService:Create(kn, TweenInfo.new(0.2), { Position = state and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5) }):Play(); cb(state) end)
        RegisterSearch({ row = row, text = text:lower() })
    end

    local function CreateSlider(parent, text, min, max, default, suffix, cb, order)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1,0,0,44), BackgroundTransparency = 1, LayoutOrder = order or 1 })
        Create("TextLabel", { Parent = row, Size = UDim2.new(1,-60,0,18), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
        local val = Create("TextLabel", { Parent = row, Size = UDim2.new(0,60,0,18), Position = UDim2.new(1,-60,0,0), BackgroundTransparency = 1, Text = tostring(default) .. (suffix or ""), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5 })
        local track = Create("Frame", { Parent = row, Size = UDim2.new(1,0,0,3), Position = UDim2.new(0,0,1,-10), BackgroundColor3 = Color3.fromRGB(30,30,40), BorderSizePixel = 0, ZIndex = 5 }, { Corner(2) })
        local fill = Create("Frame", { Parent = track, Size = UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0, ZIndex = 6 }, { Corner(2) })
        local knob = Create("Frame", { Parent = track, Size = UDim2.new(0,10,0,10), Position = UDim2.new((default-min)/(max-min),-5,0.5,-5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 7 }, { Corner(5) })
        local hit = Create("TextButton", { Parent = row, Size = UDim2.new(1,0,0,18), Position = UDim2.new(0,0,1,-16), BackgroundTransparency = 1, Text = "", ZIndex = 8 })
        local drag = false
        local function update(x) local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); local v = math.floor(min + (max - min) * rel); fill.Size = UDim2.new(rel,0,1,0); knob.Position = UDim2.new(rel,-5,0.5,-5); val.Text = tostring(v) .. (suffix or ""); cb(v) end
        hit.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; update(i.Position.X) end end)
        Track(UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end end))
        Track(UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
        RegisterSearch({ row = row, text = text:lower() })
    end
    
    local function CreateButton(parent, text, callback, order)
        local btn = Create("TextButton", { Parent = parent, Size = UDim2.new(1,0,0,32), BackgroundColor3 = Color3.fromRGB(30,30,40), Text = text, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = CONFIG.Text, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = order or 1, ZIndex = 5 }, { Corner(6) })
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = CONFIG.Accent, TextColor3 = Color3.new(0,0,0) }):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(30,30,40), TextColor3 = CONFIG.Text }):Play() end)
        btn.MouseButton1Click:Connect(callback)
        RegisterSearch({ row = btn, text = text:lower() })
    end

    local HomeTab = CreateTab("Home", "🏠", 1); local CombatTab = CreateTab("Combat", "⚔️", 2); local VisualsTab = CreateTab("Visuals", "👁️", 3)
    local CosmeticsTab = CreateTab("Cosmetics", "✨", 4); local MovementTab = CreateTab("Movement", "🏃", 5); local TrollTab = CreateTab("Troll", "😈", 6); local SettingsTab = CreateTab("Configs", "⚙️", 7)

    -- HOME
    local pCard = CreateCard(HomeTab, "Player")
    Create("TextLabel", { Parent = pCard, Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1, Text = "User: " .. LocalPlayer.Name, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
    Create("TextLabel", { Parent = pCard, Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1, Text = "ID: " .. LocalPlayer.UserId, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })

    -- COMBAT
    local aimCard = CreateCard(CombatTab, "Aimbot")
    CreateToggle(aimCard, "Enable Aimbot", "Aimbot", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end, 1)
    CreateSlider(aimCard, "FOV", 20, 600, CONFIG.AimbotFOV, "px", function(v) CONFIG.AimbotFOV = v; FOVCircle.Radius = v end, 2)
    CreateSlider(aimCard, "Smoothness", 5, 100, math.floor(CONFIG.AimbotSmooth * 100), "%", function(v) CONFIG.AimbotSmooth = v/100 end, 3)
    local kaCard = CreateCard(CombatTab, "Kill Aura")
    CreateToggle(kaCard, "Enable Kill Aura", "KillAura", CONFIG.KillAuraEnabled, function(v) CONFIG.KillAuraEnabled = v end, 1)
    CreateSlider(kaCard, "Range", 5, 100, CONFIG.KillAuraRange, "s", function(v) CONFIG.KillAuraRange = v end, 2)

    -- VISUALS
    local espCard = CreateCard(VisualsTab, "ESP & HUD")
    CreateToggle(espCard, "Enable ESP", "ESP", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end, 1)
    CreateToggle(espCard, "Target HUD", "TargetHUD", CONFIG.TargetHUD, function(v) CONFIG.TargetHUD = v; if not v then targetFrame.Visible = false end end, 2)
    CreateToggle(espCard, "Box", "ESPBox", CONFIG.ESPBox, function(v) CONFIG.ESPBox = v end, 3)
    CreateToggle(espCard, "Name", "ESPName", CONFIG.ESPName, function(v) CONFIG.ESPName = v end, 4)
    CreateToggle(espCard, "Health", "ESPHealth", CONFIG.ESPHealth, function(v) CONFIG.ESPHealth = v end, 5)
    
    local chamsCard = CreateCard(VisualsTab, "Chams")
    CreateToggle(chamsCard, "Enemy Chams", "ChamsEnemy", CONFIG.ChamsEnemy, function(v) CONFIG.ChamsEnemy = v end, 1)
    CreateToggle(chamsCard, "Rainbow", "ChamsRainbow", CONFIG.ChamsRainbow, function(v) CONFIG.ChamsRainbow = v end, 2)

    -- COSMETICS
    local cosCard = CreateCard(CosmeticsTab, "Cosmetics")
    CreateToggle(cosCard, "Halo", "Halo", CONFIG.HaloEnabled, function(v) CONFIG.HaloEnabled = v end, 1)
    CreateToggle(cosCard, "Wings", "Wings", CONFIG.WingsEnabled, function(v) CONFIG.WingsEnabled = v end, 2)
    CreateToggle(cosCard, "Crown", "Crown", CONFIG.CrownEnabled, function(v) CONFIG.CrownEnabled = v end, 3)
    CreateToggle(cosCard, "Orbit", "Orbit", CONFIG.OrbitEnabled, function(v) CONFIG.OrbitEnabled = v end, 4)
    CreateToggle(cosCard, "Ground Circle", "Circle", CONFIG.GroundCircle, function(v) CONFIG.GroundCircle = v end, 5)

    -- MOVEMENT
    local flyCard = CreateCard(MovementTab, "Flight")
    CreateToggle(flyCard, "Fly", "Fly", CONFIG.FlyEnabled, function(v) CONFIG.FlyEnabled = v; if not v then StopFly() end end, 1)
    CreateSlider(flyCard, "Fly Speed", 20, 300, CONFIG.FlySpeed, "", function(v) CONFIG.FlySpeed = v end, 2)
    CreateToggle(flyCard, "Noclip", "Noclip", CONFIG.NoclipEnabled, function(v) CONFIG.NoclipEnabled = v end, 3)
    CreateToggle(flyCard, "Speed", "Speed", CONFIG.SpeedEnabled, function(v) CONFIG.SpeedEnabled = v end, 4)
    CreateToggle(flyCard, "Infinite Jump", "InfJump", CONFIG.InfiniteJump, function(v) CONFIG.InfiniteJump = v end, 5)

    -- TROLL
    local flingCard = CreateCard(TrollTab, "Targeted Fling")
    local flingList = Create("ScrollingFrame", { Parent = flingCard, Size = UDim2.new(1,0,0,150), BackgroundTransparency = 1, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y })
    Create("UIListLayout", { Parent = flingList, Padding = UDim.new(0, 4) })
    local flingMethods = { "Velocity", "Physics", "Network" }
    local function refreshFlingList()
        for _, v in ipairs(flingList:GetChildren()) do if v:IsA("Frame") or v:IsA("TextButton") then v:Destroy() end end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local row = Create("Frame", { Parent = flingList, Size = UDim2.new(1,0,0,28), BackgroundColor3 = Color3.fromRGB(30,30,40), BorderSizePixel = 0 }, { Corner(4) })
                Create("TextLabel", { Parent = row, Size = UDim2.new(1,-100,1,0), Position = UDim2.new(0,5,0,0), BackgroundTransparency = 1, Text = p.Name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left })
                local mBtn = Create("TextButton", { Parent = row, Size = UDim2.new(0,60,1,0), Position = UDim2.new(1,-65,0,0), BackgroundColor3 = Color3.fromRGB(45,45,55), Text = "Velocity", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = CONFIG.Accent, BorderSizePixel = 0 }, { Corner(4) })
                mBtn.MouseButton1Click:Connect(function() local m = table.find(flingMethods, mBtn.Text) or 1; if p.Character then ForceFling(p.Character, m); Notify("Flung "..p.Name.." ("..mBtn.Text..")", 2) end end)
                mBtn.MouseButton2Click:Connect(function() local current = table.find(flingMethods, mBtn.Text) or 1; current = current % #flingMethods + 1; mBtn.Text = flingMethods[current] end)
            end
        end
    end
    CreateButton(flingCard, "Refresh List", refreshFlingList, 1)

    local emoteCard = CreateCard(TrollTab, "Emotes")
    local function PlayEmoteNearest(emote, name)
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
        local closest, minD = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then local hrp = p.Character:FindFirstChild("HumanoidRootPart"); if hrp then local d = (hrp.Position - myRoot.Position).Magnitude; if d < minD then minD = d; closest = p.Character end end end end
        if closest then local hum = closest:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:PlayEmote(emote) end); Notify(name.." on "..closest.Name, 2) end end
    end
    CreateButton(emoteCard, "Dance Nearest", function() PlayEmoteNearest("dance", "Dance") end, 1)
    CreateButton(emoteCard, "Laugh Nearest", function() PlayEmoteNearest("laugh", "Laugh") end, 2)
    CreateButton(emoteCard, "Wave Nearest", function() PlayEmoteNearest("wave", "Wave") end, 3)
    CreateButton(emoteCard, "Point Nearest", function() PlayEmoteNearest("point", "Point") end, 4)

    -- CONFIGS
    local confCard = CreateCard(SettingsTab, "Config System")
    if makefolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    local nameBox = Create("TextBox", { Parent = confCard, Size = UDim2.new(1,0,0,30), BackgroundColor3 = Color3.fromRGB(30,30,40), Text = "default", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, BorderSizePixel = 0, PlaceholderText = "Config name..." }, { Corner(6) })
    local listFrame = Create("Frame", { Parent = confCard, Size = UDim2.new(1,0,0,120), BackgroundColor3 = Color3.fromRGB(22,22,28), BorderSizePixel = 0 }, { Corner(6) })
    Create("UIListLayout", { Parent = listFrame, Padding = UDim.new(0,4) })

    local function refreshConfigList()
        for _, v in ipairs(listFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        if listfiles and isfolder(CONFIG_FOLDER) then
            for _, file in ipairs(listfiles(CONFIG_FOLDER)) do
                local name = file:gsub(CONFIG_FOLDER.."/", ""):gsub("%.json", "")
                local btn = Create("TextButton", { Parent = listFrame, Size = UDim2.new(1,0,0,24), BackgroundColor3 = Color3.fromRGB(35,35,45), Text = name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = CONFIG.Text, BorderSizePixel = 0, LayoutOrder = 1 }, { Corner(4) })
                btn.MouseButton1Click:Connect(function() nameBox.Text = name end)
            end
        end
    end

    CreateButton(confCard, "Refresh Configs", refreshConfigList, 1)
    CreateButton(confCard, "Save Config", function()
        if writefile then local data = HttpService:JSONEncode({CONFIG = CONFIG, BINDS = BINDS}); writefile(CONFIG_FOLDER.."/"..nameBox.Text..".json", data); Notify("Saved: "..nameBox.Text, 2); refreshConfigList() else Notify("writefile not supported", 2) end
    end, 2)
    CreateButton(confCard, "Load Config", function()
        local path = CONFIG_FOLDER.."/"..nameBox.Text..".json"
        if readfile and isfile and isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            if data.CONFIG then for k, v in pairs(data.CONFIG) do if CONFIG[k] ~= nil then CONFIG[k] = v end end end
            if data.BINDS then for k, v in pairs(data.BINDS) do if BINDS[k] ~= nil then BINDS[k] = v end end end
            Notify("Loaded: "..nameBox.Text, 3)
        else Notify("Config not found", 2) end
    end, 3)
    refreshConfigList()

    Pages["Home"].Visible = true; Tabs["Home"].btn.TextColor3 = CONFIG.Accent; Tabs["Home"].btn.BackgroundTransparency = 0.15; Tabs["Home"].stroke.Transparency = 0.4
    menu.Visible = true; TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -320, 0.5, -230) }):Play()

    local drag, dragStart, startPos
    header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; dragStart = i.Position; startPos = menu.Position end end)
    Track(UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local d = i.Position - dragStart; menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y) end end))
    Track(UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
end

-- HOTKEYS
Track(UserInputService.InputBegan:Connect(function(input, gp)
    if State.WaitingForBind then State.WaitingForBind(input.KeyCode); return end
    if gp or UserInputService:GetFocusedTextBox() then return end
    local k = input.KeyCode; if k == Enum.KeyCode.Unknown then return end
    if k == BINDS.ToggleMenu and State.menuFrame then
        local m = State.menuFrame
        if m.Visible then TweenService:Create(m, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -320, 1, 500) }):Play(); task.wait(0.3); m.Visible = false
        else m.Visible = true; TweenService:Create(m, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -320, 0.5, -230) }):Play() end
    elseif k == BINDS.Fly then CONFIG.FlyEnabled = not CONFIG.FlyEnabled; if not CONFIG.FlyEnabled then StopFly() end; Notify("Fly: "..(CONFIG.FlyEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.Noclip then CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled; Notify("Noclip: "..(CONFIG.NoclipEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.Speed then CONFIG.SpeedEnabled = not CONFIG.SpeedEnabled; Notify("Speed: "..(CONFIG.SpeedEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.Aimbot then CONFIG.AimbotEnabled = not CONFIG.AimbotEnabled; Notify("Aimbot: "..(CONFIG.AimbotEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.KillAura then CONFIG.KillAuraEnabled = not CONFIG.KillAuraEnabled; Notify("KillAura: "..(CONFIG.KillAuraEnabled and "ON" or "OFF"), 1.5) end
end))

Track(RunService.Stepped:Connect(function(_, dt)
    if not State.Running then return end
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart"); if not hum or not hrp then return end

    hum.WalkSpeed = CONFIG.SpeedEnabled and CONFIG.WalkSpeed or 16; hum.JumpPower = CONFIG.JumpPower
    if CONFIG.NoclipEnabled then for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
    if CONFIG.InvisibleEnabled then ApplyGhost() end
    if CONFIG.InfiniteJump and UserInputService:IsKeyDown(Enum.KeyCode.Space) then hum:ChangeState(Enum.HumanoidStateType.Jumping) end

    if CONFIG.FlyEnabled then
        local cam = Workspace.CurrentCamera; local bv = hrp:FindFirstChild("Celestial_FlyBV"); local bg = hrp:FindFirstChild("Celestial_FlyBG")
        if not bv or not bg then StopFly(); local n = Instance.new("BodyVelocity", hrp); n.Name = "Celestial_FlyBV"; n.MaxForce = Vector3.new(1e5,1e5,1e5); n.P = 2000; local g = Instance.new("BodyGyro", hrp); g.Name = "Celestial_FlyBG"; g.MaxTorque = Vector3.new(1e5,1e5,1e5); g.P = 3000; hum.PlatformStand = true
        else
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end; if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end; if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end; if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end; if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end; if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            bv.Velocity = move.Magnitude > 0 and move.Unit * CONFIG.FlySpeed or Vector3.zero; bg.CFrame = cam.CFrame
        end
    end

    if CONFIG.KillAuraEnabled and tick() - State.KillAuraCooldown > 0.1 then
        State.KillAuraCooldown = tick()
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then local tHrp = p.Character:FindFirstChild("HumanoidRootPart"); if tHrp and (tHrp.Position - hrp.Position).Magnitude < CONFIG.KillAuraRange then local tool = char:FindFirstChildOfClass("Tool"); if tool then pcall(function() tool:Activate() end) end; local tHum = p.Character:FindFirstChildOfClass("Humanoid"); if tHum then pcall(function() tHum.Health = 0 end) end end end end
    end
end))

-- RENDER
local espTick = 0
Track(RunService.RenderStepped:Connect(function()
    if not State.Running then return end
    espTick += 1
    
    -- Target HUD
    if CONFIG.TargetHUD then
        local cam = Workspace.CurrentCamera
        local center = cam.ViewportSize / 2
        local bestTarget, bestDist = nil, 300
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local sp, on = cam:WorldToViewportPoint(head.Position)
                    if on then
                        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if dist < bestDist then bestDist = dist; bestTarget = p end
                    end
                end
            end
        end
        if bestTarget then
            local hum = bestTarget.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                targetFrame.Visible = true
                nameLbl.Text = bestTarget.Name
                headImg.Image = "rbxthumb://type=AvatarHeadShot&id="..bestTarget.UserId.."&w=150&h=150"
                hpBarFill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
                local tool = bestTarget.Character:FindFirstChildOfClass("Tool")
                wepLbl.Text = tool and tool.Name or "None"
            end
        else targetFrame.Visible = false end
    else targetFrame.Visible = false end

    if espTick % 2 == 0 then
        UpdateCosmetics()
        if not CONFIG.ESPEnabled then return end
        local cam = Workspace.CurrentCamera; if not cam then return end
        local myChar = LocalPlayer.Character; local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart"); local active = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character.Parent then
                local char = p.Character; local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"); local head = char:FindFirstChild("Head")
                if hum and hum.Health > 0 and hrp and head then
                    local dist = myRoot and (hrp.Position - myRoot.Position).Magnitude or 0
                    if dist <= CONFIG.ESPMaxDist then
                        active[p] = true; local t = State.ESPCache[p]
                        if not t then t = { box = TrackD(Draw("Square")), name = TrackD(Draw("Text")), dist = TrackD(Draw("Text")), hpBg = TrackD(Draw("Square")), hpBar = TrackD(Draw("Square")), tracer = TrackD(Draw("Line")), headDot = TrackD(Draw("Circle")), weapon = TrackD(Draw("Text")), skel = {} }; for i = 1, 6 do t.skel[i] = TrackD(Draw("Line")) end; State.ESPCache[p] = t end
                        local hSp, hOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)); local rSp, rOn = cam:WorldToViewportPoint(hrp.Position)
                        if hOn and rOn then
                            local h = math.abs(rSp.Y - hSp.Y); local w = h * 0.55; local bx = hSp.X - w/2; local by = hSp.Y
                            t.box.Visible = CONFIG.ESPBox; t.box.Position = Vector2.new(bx, by); t.box.Size = Vector2.new(w, h); t.box.Color = CONFIG.Accent; t.box.Thickness = 1; t.box.Filled = false
                            if CONFIG.ESPHealth then local r = math.clamp(hum.Health / hum.MaxHealth, 0, 1); t.hpBg.Visible = true; t.hpBg.Position = Vector2.new(bx - 6, by); t.hpBg.Size = Vector2.new(3, h); t.hpBg.Color = Color3.fromRGB(25, 25, 30); t.hpBg.Filled = true; t.hpBar.Visible = true; t.hpBar.Position = Vector2.new(bx - 6, by + h * (1 - r)); t.hpBar.Size = Vector2.new(3, h * r); t.hpBar.Color = Color3.fromRGB(255 * (1 - r), 255 * r, 80); t.hpBar.Filled = true else t.hpBg.Visible = false; t.hpBar.Visible = false end
                            if CONFIG.ESPName then t.name.Visible = true; t.name.Text = p.Name; t.name.Position = Vector2.new(bx + w/2, by - 16); t.name.Size = 13; t.name.Color = CONFIG.Accent; t.name.Center = true; t.name.Outline = true else t.name.Visible = false end
                            if CONFIG.ESPDistance then t.dist.Visible = true; t.dist.Text = math.floor(dist) .. "m"; t.dist.Position = Vector2.new(bx + w/2, by + h + 2); t.dist.Size = 11; t.dist.Color = Color3.fromRGB(200,200,210); t.dist.Center = true; t.dist.Outline = true else t.dist.Visible = false end
                            if CONFIG.ESPTracer then t.tracer.Visible = true; t.tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y); t.tracer.To = Vector2.new(rSp.X, rSp.Y); t.tracer.Color = CONFIG.Accent; t.tracer.Thickness = 1 else t.tracer.Visible = false end
                            if CONFIG.ESPHeadDot then t.headDot.Visible = true; t.headDot.Position = Vector2.new(hSp.X, hSp.Y); t.headDot.Radius = 3; t.headDot.Color = CONFIG.Accent2 else t.headDot.Visible = false end
                            if CONFIG.ESPWeapon then local tool = char:FindFirstChildOfClass("Tool"); if tool then t.weapon.Visible = true; t.weapon.Text = tool.Name; t.weapon.Position = Vector2.new(bx + w/2, by + h + 16); t.weapon.Size = 10; t.weapon.Color = Color3.fromRGB(180,180,190); t.weapon.Center = true; t.weapon.Outline = true else t.weapon.Visible = false end else t.weapon.Visible = false end
                            if CONFIG.ESPSkeleton then local bones = { {head, char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")}, {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso")}, {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")}, {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")}, {char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")}, {char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")} }; for i, pair in ipairs(bones) do local line = t.skel[i]; local a, b = pair[1], pair[2]; if a and b and a.Parent and b.Parent then local sa, oa = cam:WorldToViewportPoint(a.Position); local sb, ob = cam:WorldToViewportPoint(b.Position); if oa and ob then line.Visible = true; line.From = Vector2.new(sa.X, sa.Y); line.To = Vector2.new(sb.X, sb.Y); line.Color = Color3.fromRGB(255,255,255); line.Thickness = 1 else line.Visible = false end else line.Visible = false end end else for i = 1, 6 do t.skel[i].Visible = false end end
                            if CONFIG.ChamsEnemy then ApplyChams(char) else RemoveChams(char) end
                        else for _, v in pairs(t) do if typeof(v) == "table" then for _, l in pairs(v) do pcall(function() l.Visible = false end) end else pcall(function() v.Visible = false end) end end end
                    end
                end
            end
        end
        for p, t in pairs(State.ESPCache) do if not active[p] then for _, v in pairs(t) do if typeof(v) == "table" then for _, l in pairs(v) do pcall(function() l:Remove() end) end else pcall(function() v:Remove() end) end end; State.ESPCache[p] = nil; if p.Character then RemoveChams(p.Character) end end end
    end
end))

Track(LocalPlayer.CharacterAdded:Connect(function() task.wait(1); if not State.Running then return end; pcall(BuildCosmetics); if CONFIG.InvisibleEnabled then ApplyGhost() end end))

task.spawn(function()
    pcall(BuildCosmetics)
    pcall(BuildUI)
    print("[Celestial] v"..VERSION.." Loaded. HUD & Quick Actions active.")
end)
