-- Pet Finder / Brainrot Finder Hub para Roblox Studio
-- Debe colocarse como LocalScript dentro de StarterGui o ScreenGui

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local MIN_VALUE_PER_SEC = 5_000_000
local UI_NAME = "DantePetFinderHub"
local HUB_WIDTH = 420
local HUB_HEIGHT = 380
local SCAN_INTERVAL = 3 -- segundos entre escaneos
-- END CONFIG

-- Evitar duplicados
for _,v in pairs(game:GetService("CoreGui"):GetChildren()) do
    if v.Name == UI_NAME then v:Destroy() end
end

-- Crear ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = UI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

-- Contenedor principal
local main = Instance.new("Frame")
main.Size = UDim2.new(0, HUB_WIDTH, 0, HUB_HEIGHT)
main.Position = UDim2.new(0.5, -HUB_WIDTH/2, 0.5, -HUB_HEIGHT/2)
main.AnchorPoint = Vector2.new(0.5,0.5)
main.BackgroundTransparency = 0.7
main.BackgroundColor3 = Color3.fromRGB(20,20,25)
main.BorderSizePixel = 0
main.Parent = screenGui

-- Borde celeste mar
local border = Instance.new("Frame", main)
border.Size = UDim2.new(1, 6, 1, 6)
border.Position = UDim2.new(0, -3, 0, -3)
border.BackgroundColor3 = Color3.fromRGB(102,204,204)
border.BorderSizePixel = 0
border.ZIndex = 0

-- Título
local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1,0,0,36)
titleBar.BackgroundTransparency = 1
local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -10, 1, 0)
titleText.Position = UDim2.new(0, 8, 0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "Dante Pet Finder"
titleText.TextColor3 = Color3.new(1,1,1)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left

-- Botón cerrar
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0,28,0,24)
closeBtn.Position = UDim2.new(1, -36, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,45)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.BorderSizePixel = 0
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- ScrollFrame para lista
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, -16, 1, -56)
scroll.Position = UDim2.new(0,8,0,44)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 8
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0,8)

-- Crear item de lista
local function createListItem(info)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,-6,0,70)
    container.BackgroundTransparency = 0.9
    container.BackgroundColor3 = Color3.fromRGB(10,10,12)
    container.BorderSizePixel = 0

    local left = Instance.new("Frame", container)
    left.Size = UDim2.new(0.64,0,1,0)
    left.BackgroundTransparency = 1

    local nameLbl = Instance.new("TextLabel", left)
    nameLbl.Size = UDim2.new(1,-6,0,28)
    nameLbl.Position = UDim2.new(0,6,0,4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = info.name
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 15
    nameLbl.TextColor3 = Color3.new(1,1,1)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left

    local rarityLbl = Instance.new("TextLabel", left)
    rarityLbl.Size = UDim2.new(1,-6,0,18)
    rarityLbl.Position = UDim2.new(0,6,0,34)
    rarityLbl.BackgroundTransparency = 1
    rarityLbl.Text = info.rarity
    rarityLbl.Font = Enum.Font.Gotham
    rarityLbl.TextSize = 13
    rarityLbl.TextColor3 = Color3.fromRGB(200,170,255)
    rarityLbl.TextXAlignment = Enum.TextXAlignment.Left

    local vpsLbl = Instance.new("TextLabel", left)
    vpsLbl.Size = UDim2.new(1,-6,0,14)
    vpsLbl.Position = UDim2.new(0,6,0,52)
    vpsLbl.BackgroundTransparency = 1
    vpsLbl.Text = "Valor/s: "..tostring(info.vps)
    vpsLbl.Font = Enum.Font.Gotham
    vpsLbl.TextSize = 12
    vpsLbl.TextColor3 = Color3.fromRGB(220,220,220)
    vpsLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Botón unirse
    local joinBtn = Instance.new("TextButton", container)
    joinBtn.Size = UDim2.new(0.32,-10,0.8,0)
    joinBtn.Position = UDim2.new(0.66,6,0.1,0)
    joinBtn.BackgroundColor3 = Color3.fromRGB(102,204,204)
    joinBtn.BorderSizePixel = 0
    joinBtn.Text = "Unirse"
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.TextSize = 16
    joinBtn.TextColor3 = Color3.fromRGB(255,255,255)
    joinBtn.MouseButton1Click:Connect(function()
        if info.owner then
            -- Teletransportar al jugador a la base
            local targetPlot = workspace.Plots:FindFirstChild(info.owner)
            if targetPlot then
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlot.PrimaryPart.CFrame + Vector3.new(0,5,0)
            end
        end
    end)

    return container
end

-- Actualizar la lista de Brainrots
local function updateList()
    -- Limpiar lista
    for _,c in pairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    -- Recorrer todas las bases
    for _, plot in pairs(workspace.Plots:GetChildren()) do
        local ownerId = plot.Name
        for _, pet in pairs(plot:GetChildren()) do
            if pet:IsA("Model") and workspace.Animals:FindFirstChild(pet.Name) then
                local animalData = workspace.Animals:FindFirstChild(pet.Name)
                local vps = animalData:FindFirstChild("ValuePerSecond") and animalData.ValuePerSecond.Value or 0
                local rarity = animalData:FindFirstChild("Rarity") and animalData.Rarity.Value or "Desconocida"
                if vps >= MIN_VALUE_PER_SEC then
                    local info = {name = pet.Name, rarity = rarity, vps = vps, owner = ownerId}
                    local item = createListItem(info)
                    item.Parent = scroll
                end
            end
        end
    end

    -- Ajustar tamaño del scroll
    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 12)
end

-- Loop de actualización periódica
RunService.Heartbeat:Connect(function()
    updateList()
end)

-- Drag del hub
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                              startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
    if input.UserInputType == Enum.UserInputType.MouseMovement
