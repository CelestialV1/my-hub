-- ============================================================
-- CELESTIAL v11.0 — ULTIMATE UPDATE
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
local VERSION = "11.0"
local CONFIG_FOLDER = "CelestialConfigs"

local CONFIG = {
    Accent = Color3.fromRGB(160, 110, 255), Accent2 = Color3.fromRGB(255, 100, 200),
    Bg = Color3.fromRGB(8, 8, 12), CardBg = Color3.fromRGB(18, 18, 24),
    Text = Color3.fromRGB(240, 240, 250), TextDark = Color3.fromRGB(140, 140, 160),

    AimbotEnabled = false, AimbotKey = Enum.KeyCode.E, AimbotRMB = true,
    SilentAim = false, AimbotFOV = 200, AimbotSmooth = 0.35,
    KillAuraEnabled = false, KillAuraRange = 25,
    
    ESPEnabled = true, ESPBox = true, ESPHealth = true, ESPName = true, ESPDistance = true, 
    ESPSkeleton = true, ESPWeapon = true, ESPTracer = true, ESPHeadDot = true, ESPMaxDist = 1500,
    TargetHUD = true,

    ChamsEnemy = false, ChamsSelf = false, ChamsRainbow = false,

    WingsEnabled = false, CrownEnabled = false, HaloEnabled = false,
    OrbitEnabled = false, PentagramEnabled = false,
    HaloCount = 20, OrbitCount = 6,

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

-- COSMETICS
local function BuildCosmetics()
    if not State.Cosmetics.Halo then
        State.Cosmetics.Halo = Instance.new("Model", Workspace); State.Cosmetics.Halo.Name = "Celestial_Halo"
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
        local rm = Instance.new("SpecialMesh", right); rm.MeshType = Enum.MeshType.FileMesh; rm.MeshId = "rbxassetid://1553468709"; rm.Scale = Vector3.new(-0.048, 0.048, 0.048) -- Исправил кривое крыло
        State.Cosmetics.Wings = { Left = left, Right = right, Model = m }
    end
    if not State.Cosmetics.Orbit then
        State.Cosmetics.Orbit = Instance.new("Model", Workspace); State.Cosmetics.Orbit.Name = "Celestial_Orbit"
    end
    if not State.Cosmetics.Pentagram then
        State.Cosmetics.Pentagram = Instance.new("Model", Workspace); State.Cosmetics.Pentagram.Name = "Celestial_Pentagram"
        for i = 1, 5 do
            local p = Instance.new("Part", State.Cosmetics.Pentagram)
            p.Name = "PentagramBeam"; p.Shape = Enum.PartType.Cylinder; p.Size = Vector3.new(0.1, 0.1, 5.2)
            p.Material = Enum.Material.Neon; p.Color = CONFIG.Accent; p.Transparency = 0.3
            p.CanCollide = false; p.CanQuery = false; p.Anchored = true
        end
    end
end

local function UpdateCosmetics()
    local char = LocalPlayer.Character; if not char then return end
    local head = char:FindFirstChild("Head"); local hrp = char:FindFirstChild("HumanoidRootPart"); local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local t = tick()

    -- Halo
    if State.Cosmetics.Halo and head then
        State.Cosmetics.Halo.Parent = CONFIG.HaloEnabled and Workspace or nil
        if CONFIG.HaloEnabled then
            local children = State.Cosmetics.Halo:GetChildren()
            if #children ~= CONFIG.HaloCount then
                for _, c in ipairs(children) do c:Destroy() end
                for i = 1, CONFIG.HaloCount do
                    local b = Instance.new("Part", State.Cosmetics.Halo); b.Name = "HaloBall"; b.Shape = Enum.PartType.Ball; b.Size = Vector3.new(0.25,0.25,0.25); b.Material = Enum.Material.Neon; b.CanCollide = false; b.CanQuery = false; b.Anchored = true
                end
            end
            local count = CONFIG.HaloCount
            for i, b in ipairs(State.Cosmetics.Halo:GetChildren()) do
                local a = (i/count) * math.pi * 2 + t*2
                b.CFrame = head.CFrame * CFrame.new(math.cos(a)*1.6, 1.3, math.sin(a)*1.6)
                b.Color = Color3.fromHSV((t*0.2 + i/count) % 1, 0.8, 1)
            end
        end
    end

    -- Crown
    if State.Cosmetics.Crown and head then
        State.Cosmetics.Crown.Parent = CONFIG.CrownEnabled and Workspace or nil
        if CONFIG.CrownEnabled then State.Cosmetics.Crown.CFrame = head.CFrame * CFrame.new(0,0.75,0); State.Cosmetics.Crown.Color = CONFIG.Accent end
    end

    -- Wings
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

    -- Orbit (Figure-8 Loop)
    if State.Cosmetics.Orbit and hrp then
        State.Cosmetics.Orbit.Parent = CONFIG.OrbitEnabled and Workspace or nil
        if CONFIG.OrbitEnabled then
            local children = State.Cosmetics.Orbit:GetChildren()
            if #children ~= CONFIG.OrbitCount then
                for _, c in ipairs(children) do c:Destroy() end
                for i = 1, CONFIG.OrbitCount do
                    local b = Instance.new("Part", State.Cosmetics.Orbit); b.Name = "OrbitBall"; b.Shape = Enum.PartType.Ball; b.Size = Vector3.new(0.4,0.4,0.4); b.Material = Enum.Material.Neon; b.CanCollide = false; b.CanQuery = false; b.Anchored = true
                end
            end
            local count = CONFIG.OrbitCount
            for i, b in ipairs(State.Cosmetics.Orbit:GetChildren()) do
                local a = t * 2 + (i * math.pi * 2 / count)
                local x = math.cos(a) * 3
                local y = math.sin(a * 2) * 3 -- Figure 8 vertical loop
                local z = math.sin(a) * 3
                b.CFrame = hrp.CFrame * CFrame.new(x, y, z)
                b.Color = Color3.fromHSV((t*0.2 + i/count) % 1, 0.8, 1)
            end
        end
    end

    -- Pentagram
    if State.Cosmetics.Pentagram and hrp then
        State.Cosmetics.Pentagram.Parent = CONFIG.PentagramEnabled and Workspace or nil
        if CONFIG.PentagramEnabled then
            local center = hrp.Position - Vector3.new(0, 3, 0)
            local radius = 4
            local points = {}
            for i = 1, 5 do
