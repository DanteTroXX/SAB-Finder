-- ModuleScript: ReplicatedStorage.DantePetFinder
-- Uso:
--  require(game.ReplicatedStorage.DantePetFinder)  -- desde Script (ServerScriptService)
--  require(game.ReplicatedStorage.DantePetFinder)  -- desde LocalScript (StarterGui)
-- El servidor debe llamar _G.OnBrainrotPlaced(info) al colocar/comprar un brainrot en una base.
-- CONFIG -----------------------------------------
local REMOTE_NAME = "BrainrotDetectedEvent"
local MIN_VPS = 5_000_000
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1431764048059433134/ldNhxq20Fs4d0C8O5ZjposZnkGm9rwnrNpG8lGc2gL1XFIE6b5M378byeunfzI5vjEBB"
local UI_NAME = "DantePetFinderHub"
local HUB_WIDTH = 420
local HUB_HEIGHT = 380
-- END CONFIG -------------------------------------

local Module = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- asegurar RemoteEvent (servidor crea si falta)
local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote and RunService:IsServer() then
    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
end

-- -------------------------
-- Parte SERVIDOR
-- -------------------------
local function server_init()
    if not remote then
        remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)
    end

    local function sendDiscord(content)
        if not DISCORD_WEBHOOK or DISCORD_WEBHOOK == "" then return end
        local ok, err = pcall(function()
            local payload = { content = content }
            HttpService:PostAsync(DISCORD_WEBHOOK, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
        end)
        if not ok then warn("[DantePetFinder] Webhook failed:", err) end
    end

    -- Función que el juego debe llamar cuando un brainrot se coloque en la base
    -- info = { name=string, rarity=string, vps=number, ownerId=string }
    local function onBrainrotPlaced(info)
        if type(info) ~= "table" or not info.name then return end

        local serverId = tostring(game.JobId or "")
        local payload = {
            name = info.name,
            rarity = info.rarity or "Desconocida",
            vps = info.vps or 0,
            owner = info.ownerId or "Unknown",
            placeId = tostring(game.PlaceId),
            serverId = serverId,
            time = os.time()
        }

        -- enviar a discord (no rompe si falla)
        pcall(function()
            sendDiscord(string.format("Detected: %s | Rarity: %s | VPS: %s | Owner: %s | Server: %s",
                payload.name, payload.rarity, tostring(payload.vps), tostring(payload.owner), tostring(payload.serverId)))
        end)

        -- notificar clientes
        remote:FireAllClients(payload)
        print("[DantePetFinder] Notificado:", payload.name, payload.vps, payload.owner, payload.serverId)
    end

    -- Exponer para que otros scripts lo llamen
    _G.OnBrainrotPlaced = onBrainrotPlaced
    print("[DantePetFinder] Server initialized. Call _G.OnBrainrotPlaced(info) when a brainrot is placed.")
end

-- -------------------------
-- Parte CLIENTE (UI)
-- -------------------------
local function client_createUI(localPlayer)
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild(UI_NAME) then
        playerGui[UI_NAME]:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = UI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- main frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, HUB_WIDTH, 0, HUB_HEIGHT)
    main.Position = UDim2.new(0.5, -HUB_WIDTH/2, 0.5, -HUB_HEIGHT/2)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundTransparency = 0.7
    main.BackgroundColor3 = Color3.fromRGB(20,20,25)
    main.BorderSizePixel = 0
    main.Parent = screenGui

    -- borde celeste mar
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.Parent = main
    border.Size = UDim2.new(1, 6, 1, 6)
    border.Position = UDim2.new(0, -3, 0, -3)
    border.BackgroundColor3 = Color3.fromRGB(102,204,204)
    border.BorderSizePixel = 0
    border.ZIndex = 0

    -- title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = main

    local titleText = Instance.new("TextLabel", titleBar)
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.Position = UDim2.new(0, 8, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Dante Pet Finder"
    titleText.TextColor3 = Color3.new(1,1,1)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0,28,0,24)
    closeBtn.Position = UDim2.new(1, -36, 0.5, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,45)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

    -- ScrollFrame
    local scroll = Instance.new("ScrollingFrame", main)
    scroll.Name = "List"
    scroll.Size = UDim2.new(1, -16, 1, -56)
    scroll.Position = UDim2.new(0,8,0,44)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 8
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0

    local uiListLayout = Instance.new("UIListLayout", scroll)
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0,8)

    -- crear item helper
    local function createListItem(info)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -6, 0, 70)
        container.BackgroundTransparency = 0.9
        container.BackgroundColor3 = Color3.fromRGB(10,10,12)
        container.BorderSizePixel = 0
        container.Parent = scroll

        local left = Instance.new("Frame", container)
        left.Size = UDim2.new(0.64, 0, 1, 0)
        left.BackgroundTransparency = 1

        local nameLbl = Instance.new("TextLabel", left)
        nameLbl.Size = UDim2.new(1, -6, 0, 28)
        nameLbl.Position = UDim2.new(0,6,0,4)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = info.name or "Unknown"
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 15
        nameLbl.TextColor3 = Color3.new(1,1,1)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local rarityLbl = Instance.new("TextLabel", left)
        rarityLbl.Size = UDim2.new(1, -6, 0, 18)
        rarityLbl.Position = UDim2.new(0,6,0,34)
        rarityLbl.BackgroundTransparency = 1
        rarityLbl.Text = info.rarity or "Desconocida"
        rarityLbl.Font = Enum.Font.Gotham
        rarityLbl.TextSize = 13
        rarityLbl.TextColor3 = Color3.fromRGB(200,170,255)
        rarityLbl.TextXAlignment = Enum.TextXAlignment.Left

        local vpsLbl = Instance.new("TextLabel", left)
        vpsLbl.Size = UDim2.new(1, -6, 0, 14)
        vpsLbl.Position = UDim2.new(0,6,0,52)
        vpsLbl.BackgroundTransparency = 1
        vpsLbl.Text = "Valor/s: " .. tostring(info.vps or "N/A")
        vpsLbl.Font = Enum.Font.Gotham
        vpsLbl.TextSize = 12
        vpsLbl.TextColor3 = Color3.fromRGB(220,220,220)
        vpsLbl.TextXAlignment = Enum.TextXAlignment.Left

        local joinBtn = Instance.new("TextButton", container)
        joinBtn.Size = UDim2.new(0.32, -10, 0.8, 0)
        joinBtn.Position = UDim2.new(0.66, 6, 0.1, 0)
        joinBtn.BackgroundColor3 = Color3.fromRGB(102,204,204)
        joinBtn.BorderSizePixel = 0
        joinBtn.Text = "Unirse"
        joinBtn.Font = Enum.Font.GothamBold
        joinBtn.TextSize = 16
        joinBtn.TextColor3 = Color3.fromRGB(255,255,255)
        joinBtn.Parent = container

        joinBtn.MouseButton1Click:Connect(function()
            if info.serverId and info.serverId ~= "" then
                -- intentar teleport a ese server (serverId es string)
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(tonumber(info.placeId) or game.PlaceId, info.serverId, localPlayer)
                end)
            else
                -- fallback: intentar mover dentro del mismo servidor a la base si existe
                if info.owner and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(info.owner) then
                    local targetPlot = workspace.Plots[info.owner]
                    if targetPlot.PrimaryPart and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        localPlayer.Character.HumanoidRootPart.CFrame = targetPlot.PrimaryPart.CFrame + Vector3.new(0,5,0)
                    end
                end
            end
        end)
    end

    -- drag (PC + táctil)
    local dragging, dragInput, dragStart, startPos
    local function updateDrag(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then updateDrag(input) end
    end)

    -- devolver referencias útiles
    return {
        screenGui = screenGui,
        scroll = scroll,
        uiListLayout = uiListLayout,
        createListItem = createListItem
    }
end

local function client_init()
    -- asegurar local player
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        localPlayer = Players.LocalPlayer
    end

    -- crear UI
    local ui = client_createUI(localPlayer)
    local found = {} -- evitar duplicados

    -- asegurar RemoteEvent
    remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME) or remote
    if not remote then
        remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)
    end

    -- manejar detecciones del servidor
    remote.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" or not payload.name then return end
        if tonumber(payload.vps) and tonumber(payload.vps) >= MIN_VPS then
            local key = tostring(payload.name) .. "|" .. tostring(payload.serverId)
            if not found[key] then
                found[key] = payload
                ui.createListItem(payload)
                -- ajustar CanvasSize
                ui.scroll.CanvasSize = UDim2.new(0,0,0, ui.uiListLayout.AbsoluteContentSize.Y + 12)
            end
        end
    end)

    print("[DantePetFinder] Client initialized and waiting for detections.")
end

-- -------------------------
-- Auto-init on require()
-- -------------------------
local function auto_init()
    if RunService:IsServer() then
        server_init()
    else
        client_init()
    end
end

auto_init()

-- Expose internals optionally
Module._server_init = server_init
Module._client_init = client_init

return Module
