-- Configuración del Webhook de Discord
local webhookUrl = "https://discord.com/api/webhooks/1431764048059433134/ldNhxq20Fs4d0C8O5ZjposZnkGm9rwnrNpG8lGc2gL1XFIE6b5M378byeunfzI5vjEBB"

-- Crear el hub con un fondo transparente y bordes celeste mar
local hub = Instance.new("ScreenGui")
hub.Name = "PetFinderHub"
hub.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundTransparency = 1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = hub

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.Position = UDim2.new(0, 0, 0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = mainFrame

-- Función para crear cada entrada de Brainrot
local function createBrainrotEntry(name, rarity, valuePerSecond, serverId)
    print("Creando entrada para: " .. name) -- Mensaje de depuración
    local entryFrame = Instance.new("Frame")
    entryFrame.Size = UDim2.new(1, 0, 0, 50)
    entryFrame.BackgroundTransparency = 1
    entryFrame.BorderSizePixel = 0
    entryFrame.Parent = scrollFrame

    -- Nombre del Brainrot
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.new(1, 1, 1) -- Blanco
    nameLabel.BackgroundTransparency = 1
    nameLabel.BorderSizePixel = 0
    nameLabel.Parent = entryFrame

    -- Rareza del Brainrot
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.3, 0)
    rarityLabel.Text = "Rareza: " .. rarity
    rarityLabel.TextColor3 = Color3.new(0.5, 0, 0.5) -- Violeta claro
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.BorderSizePixel = 0
    rarityLabel.Parent = entryFrame

    -- Valor por segundo
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, 0, 0.4, 0)
    valueLabel.Position = UDim2.new(0, 0, 0.6, 0)
    valueLabel.Text = "Valor por segundo: " .. valuePerSecond
    valueLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5) -- Gris claro
    valueLabel.BackgroundTransparency = 1
    valueLabel.BorderSizePixel = 0
    valueLabel.Parent = entryFrame

    -- Botón "Unirse"
    local joinButton = Instance.new("TextButton")
    joinButton.Size = UDim2.new(0.3, 0, 0.8, 0)
    joinButton.Position = UDim2.new(0.7, 0, 0.1, 0)
    joinButton.Text = "Unirse"
    joinButton.TextColor3 = Color3.new(1, 1, 1) -- Blanco
    joinButton.BackgroundColor3 = Color3.new(0, 0.75, 1) -- Celeste mar
    joinButton.BorderSizePixel = 0
    joinButton.Parent = entryFrame

    joinButton.MouseButton1Click:Connect(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(serverId, game.PlaceId, game.JobId)
    end)
end

-- Función para detectar Brainrots en servidores externos
local function detectBrainrots()
    print("Detectando Brainrots...") -- Mensaje de depuración
    local brainrotModels = ReplicatedStorage:WaitForChild("Models"):WaitForChild("Animals")
    local brainrotNames = {}
    for _, model in pairs(brainrotModels:GetChildren()) do
        table.insert(brainrotNames, model.Name)
    end

    local plots = Workspace:WaitForChild("Plots")
    local brainrotData = {}

    for _, plot in pairs(plots:GetChildren()) do
        local brainrot = plot:FindFirstChild("Brainrot")
        if brainrot then
            local brainrotName = brainrot.Name
            local valuePerSecond = brainrot.ValuePerSecond.Value
            if valuePerSecond > 5e6 then -- 5M/s
                local rarity = "Común" -- Puedes ajustar esto según la lógica de rareza de tu juego
                table.insert(brainrotData, {name = brainrotName, rarity = rarity, valuePerSecond = valuePerSecond, serverId = game.JobId})
            end
        end
    end

    return brainrotData
end

-- Detectar Brainrots y crear entradas en el hub
local brainrotData = detectBrainrots()
print("Brainrots detectados: " .. #brainrotData) -- Mensaje de depuración
for _, data in ipairs(brainrotData) do
    createBrainrotEntry(data.name, data.rarity, data.valuePerSecond, data.serverId)
end

-- Ajustar el tamaño del CanvasSize del ScrollingFrame
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #brainrotData * 50)
