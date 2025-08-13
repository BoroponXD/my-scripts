local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
game:GetService("TextChatService").ChatWindowConfiguration.Enabled = true

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SETTINGS_FILE = "esp_settings.json"

local TRACKED_OBJECTS = {
    ["Red Crate"] = { enabled = true, color = Color3.fromRGB(255, 0, 0), objects = {}, hasValues = false },
    ["Yellow Crate"] = { enabled = true, color = Color3.fromRGB(255, 0, 255), objects = {}, hasValues = false },
    ["Small Safe"] = { enabled = true, color = Color3.fromRGB(255, 255, 0), objects = {}, hasValues = true },
    ["Medium Safe"] = { enabled = true, color = Color3.fromRGB(255, 165, 0), objects = {}, hasValues = true },
    ["Register"] = { enabled = true, color = Color3.fromRGB(0, 255, 0), objects = {}, hasValues = true },
    ["Trash"] = { enabled = true, color = Color3.fromRGB(255, 255, 255), objects = {}, hasValues = false },
}

local PLAYER_ESP_SETTINGS = {
    enabled = true,
    name = true,
    highlight = true,
    health = true,
    distance = true,
    distanceValue = 300,
    players = {},
    friends = {},
    enemies = {}
}

local DEALER_ESP_SETTINGS = {
    enabled = false,
    selectedValue = "",
    billboards = {}
}

local TOOL_ESP_SETTINGS = {
    selectedTool = "",
    playersWithTool = {}
}

local OBJECT_ESP_SETTINGS = {
    enabled = true,
    distance = true,
    distanceValue = 400
}

local MISC_SETTINGS = {
    noCooldowns = false,
    autoSafeHack = false
}

local connections = {}
local noCooldownsConnection = nil
local autoSafeHackConnection = nil

local activeSetupCoroutines = {}

local function loadSettings()
    if isfile(SETTINGS_FILE) then
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(SETTINGS_FILE))
        if success and typeof(decoded) == "table" then
            for key, value in pairs(decoded.PLAYER_ESP_SETTINGS or {}) do
                if PLAYER_ESP_SETTINGS[key] ~= nil then
                    PLAYER_ESP_SETTINGS[key] = value
                end
            end
            for key, value in pairs(decoded.OBJECT_ESP_SETTINGS or {}) do
                if OBJECT_ESP_SETTINGS[key] ~= nil then
                    OBJECT_ESP_SETTINGS[key] = value
                end
            end
            for key, value in pairs(decoded.MISC_SETTINGS or {}) do
                if MISC_SETTINGS[key] ~= nil then
                    MISC_SETTINGS[key] = value
                end
            end
            for key, value in pairs(decoded.DEALER_ESP_SETTINGS or {}) do
                if DEALER_ESP_SETTINGS[key] ~= nil then
                    DEALER_ESP_SETTINGS[key] = value
                end
            end
            if decoded.TOOL_ESP_SETTINGS and decoded.TOOL_ESP_SETTINGS.selectedTool then
                TOOL_ESP_SETTINGS.selectedTool = decoded.TOOL_ESP_SETTINGS.selectedTool
            end
            for name, data in pairs(decoded.TRACKED_OBJECTS or {}) do
                if TRACKED_OBJECTS[name] and typeof(data) == "table" then
                    if typeof(data.enabled) == "boolean" then
                        TRACKED_OBJECTS[name].enabled = data.enabled
                    end
                end
            end
        end
    end
end

loadSettings()

local function saveSettings()
    local settings = {
        TRACKED_OBJECTS = {},
        PLAYER_ESP_SETTINGS = {
            enabled = PLAYER_ESP_SETTINGS.enabled,
            name = PLAYER_ESP_SETTINGS.name,
            highlight = PLAYER_ESP_SETTINGS.highlight,
            health = PLAYER_ESP_SETTINGS.health,
            distance = PLAYER_ESP_SETTINGS.distance,
            distanceValue = PLAYER_ESP_SETTINGS.distanceValue,
            friends = PLAYER_ESP_SETTINGS.friends,
            enemies = PLAYER_ESP_SETTINGS.enemies
        },
        OBJECT_ESP_SETTINGS = OBJECT_ESP_SETTINGS,
        MISC_SETTINGS = MISC_SETTINGS,
        DEALER_ESP_SETTINGS = {
            enabled = DEALER_ESP_SETTINGS.enabled,
            selectedValue = DEALER_ESP_SETTINGS.selectedValue
        },
        TOOL_ESP_SETTINGS = {
            selectedTool = TOOL_ESP_SETTINGS.selectedTool
        }
    }
    for name, data in pairs(TRACKED_OBJECTS) do
        settings.TRACKED_OBJECTS[name] = { enabled = data.enabled }
    end
    writefile(SETTINGS_FILE, HttpService:JSONEncode(settings))
end

local gui = Instance.new("ScreenGui")
gui.Name = "ESP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

local menu = Instance.new("Frame")
menu.LayoutOrder = 10
menu.Name = "ESPMenu"
menu.Size = UDim2.new(0.14, 0, 0.32, 0)
menu.Position = UDim2.new(0, 100, 0, 100)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menu.BackgroundTransparency = 0.1
menu.BorderSizePixel = 0
menu.Active = true
menu.Draggable = true
menu.Parent = gui

local corner = Instance.new("UIStroke")
corner.Color = Color3.fromRGB(244, 73, 255)
corner.Thickness = 2
corner.Parent = menu

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.FillDirection = Enum.FillDirection.Vertical
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Parent = menu

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 10)
padding.Parent = menu

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 30)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = menu

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabFrame

local function createTabButton(name, isActive)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.33, 0, 1, 0)
    button.BackgroundColor3 = isActive and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(20, 20, 20)
    button.Text = name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = tabFrame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(244, 73, 255)
    stroke.Thickness = 1
    stroke.Parent = button
    return button
end

local playerTabButton = createTabButton("Player ESP", true)
local objectTabButton = createTabButton("Object ESP", false)
local miscTabButton = createTabButton("Misc", false)

local playerEspFrame = Instance.new("Frame")
playerEspFrame.Size = UDim2.new(1, 0, 1, -40)
playerEspFrame.BackgroundTransparency = 1
playerEspFrame.Visible = true
playerEspFrame.Parent = menu

local objectEspFrame = Instance.new("Frame")
objectEspFrame.Size = UDim2.new(1, 0, 1, -40)
objectEspFrame.BackgroundTransparency = 1
objectEspFrame.Visible = false
objectEspFrame.Parent = menu

local miscFrame = Instance.new("Frame")
miscFrame.Size = UDim2.new(1, 0, 1, -40)
miscFrame.BackgroundTransparency = 1
miscFrame.Visible = false
miscFrame.Parent = menu

local function createToggleButton(name, enabled, callback, parent)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 24)
    container.BackgroundTransparency = 1
    container.Parent = parent
    if name == "Dealer ESP" then
        container.LayoutOrder = 2
    end

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = container

    local label = Instance.new("TextLabel")
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.LayoutOrder = 1
    label.Parent = container

    local button = Instance.new("TextButton")
    button.Text = enabled and "On" or "Off"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Size = UDim2.new(0.3, 0, 0, 18)
    button.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.LayoutOrder = 2
    button.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(244, 73, 255)
    stroke.Thickness = 1
    stroke.Parent = button

    local buttonConn = button.MouseButton1Click:Connect(function()
        enabled = not enabled
        button.Text = enabled and "On" or "Off"
        button.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        callback(enabled)
    end)
    table.insert(connections, buttonConn)

    return container, button
end

local function createButton(name, callback, parent)
    local button = Instance.new("TextButton")
    button.Size = name == "Remove Script" and UDim2.new(0.98, 0, 0, 24) or UDim2.new(0.48, 0, 0, 24)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.Text = name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Parent = parent
    if name == "Remove Script" then
        button.LayoutOrder = 6
    end

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(244, 73, 255)
    stroke.Thickness = 1
    stroke.Parent = button

    local buttonConn = button.MouseButton1Click:Connect(callback)
    table.insert(connections, buttonConn)

    return button
end

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 5)
playerListLayout.FillDirection = Enum.FillDirection.Vertical
playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerListLayout.Parent = playerEspFrame

createToggleButton("Player ESP", PLAYER_ESP_SETTINGS.enabled, function(state)
    PLAYER_ESP_SETTINGS.enabled = state
    saveSettings()
end, playerEspFrame)

createToggleButton("Name", PLAYER_ESP_SETTINGS.name, function(state)
    PLAYER_ESP_SETTINGS.name = state
    saveSettings()
end, playerEspFrame)

createToggleButton("Highlight", PLAYER_ESP_SETTINGS.highlight, function(state)
    PLAYER_ESP_SETTINGS.highlight = state
    saveSettings()
end, playerEspFrame)

createToggleButton("Health", PLAYER_ESP_SETTINGS.health, function(state)
    PLAYER_ESP_SETTINGS.health = state
    saveSettings()
end, playerEspFrame)

createToggleButton("Distance", PLAYER_ESP_SETTINGS.distance, function(state)
    PLAYER_ESP_SETTINGS.distance = state
    saveSettings()
end, playerEspFrame)

local textBoxFrame = Instance.new("Frame")
textBoxFrame.Size = UDim2.new(1, 0, 0, 24)
textBoxFrame.BackgroundTransparency = 1
textBoxFrame.Parent = playerEspFrame

local textBoxLabel = Instance.new("TextLabel")
textBoxLabel.Size = UDim2.new(0.65, 0, 1, 0)
textBoxLabel.BackgroundTransparency = 1
textBoxLabel.Text = "Player Name:"
textBoxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textBoxLabel.Font = Enum.Font.Gotham
textBoxLabel.TextSize = 14
textBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
textBoxLabel.Parent = textBoxFrame

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0.295, 0, 0, 18)
textBox.Position = UDim2.new(0.685, 0, 0, 3)
textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.Font = Enum.Font.Gotham
textBox.TextSize = 12
textBox.PlaceholderText = "Enter name"
textBox.Text = ""
textBox.Parent = textBoxFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(244, 73, 255)
stroke.Thickness = 1
stroke.Parent = textBox

local dropdownFrame = Instance.new("Frame")
dropdownFrame.ZIndex = 2
dropdownFrame.Size = UDim2.new(0.3, 0, 0, 0)
dropdownFrame.Position = UDim2.new(1, 0, 0.15, 0)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dropdownFrame.BackgroundTransparency = 0.1
dropdownFrame.Visible = false
dropdownFrame.Parent = textBoxFrame

local dropdownStroke = Instance.new("UIStroke")
dropdownStroke.Color = Color3.fromRGB(244, 73, 255)
dropdownStroke.Thickness = 1
dropdownStroke.Parent = dropdownFrame

local dropdownLayout = Instance.new("UIListLayout")
dropdownLayout.FillDirection = Enum.FillDirection.Vertical
dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropdownLayout.Padding = UDim.new(0, 2)
dropdownLayout.Parent = dropdownFrame

local dropdownPadding = Instance.new("UIPadding")
dropdownPadding.PaddingTop = UDim.new(0, 1)
dropdownPadding.PaddingLeft = UDim.new(0, 2)
dropdownPadding.PaddingBottom = UDim.new(0, 2)
dropdownPadding.Parent = dropdownFrame

local function updateAutocomplete(input)
    for _, child in ipairs(dropdownFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    dropdownFrame.Size = UDim2.new(0.3, 0, 0, 0)
    dropdownFrame.ZIndex = 4

    local suggestions = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if input == "" or string.match(player.Name:lower(), "^" .. input:lower()) then
                table.insert(suggestions, player.Name)
            end
        end
    end
    table.sort(suggestions, function(a, b) return a:lower() < b:lower() end)

    local height = 0
    for i, name in ipairs(suggestions) do
        local suggestionButton = Instance.new("TextButton")
        suggestionButton.ZIndex = 4
        suggestionButton.Size = UDim2.new(0.95, 0, 0, 20)
        suggestionButton.BackgroundColor3 = i == 1 and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(30, 30, 30)
        suggestionButton.Text = name
        suggestionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        suggestionButton.Font = Enum.Font.Gotham
        suggestionButton.TextSize = 12
        suggestionButton.TextXAlignment = Enum.TextXAlignment.Left
        suggestionButton.Parent = dropdownFrame

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Color3.fromRGB(244, 73, 255)
        buttonStroke.Thickness = 1
        buttonStroke.Parent = suggestionButton

        local conn = suggestionButton.MouseButton1Click:Connect(function()
            if textBox then
                textBox.Text = name
                dropdownFrame.Visible = false
            end
        end)
        table.insert(connections, conn)
        height = height + 22
    end
    dropdownFrame.Size = UDim2.new(0.3, 0, 0, height)
    dropdownFrame.Visible = #suggestions > 0
end

table.insert(connections, textBox.Focused:Connect(function()
    updateAutocomplete(textBox.Text)
end))

table.insert(connections, textBox.FocusLost:Connect(function()
    wait(0.1)
    dropdownFrame.Visible = false
end))

table.insert(connections, textBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateAutocomplete(textBox.Text)
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= Enum.KeyCode.Tab then return end
    if dropdownFrame.Visible and #dropdownFrame:GetChildren() > 2 then
        local firstSuggestion = dropdownFrame:GetChildren()[3]
        if firstSuggestion:IsA("TextButton") then
            textBox.Text = firstSuggestion.Text
            dropdownFrame.Visible = false
        end
    end
end))

local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, 0, 0, 54)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = playerEspFrame

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Vertical
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.Padding = UDim.new(0, 5)
buttonLayout.Parent = buttonContainer

local topButtonRow = Instance.new("Frame")
topButtonRow.Size = UDim2.new(1, 0, 0, 24)
topButtonRow.BackgroundTransparency = 1
topButtonRow.Parent = buttonContainer

local topButtonLayout = Instance.new("UIListLayout")
topButtonLayout.FillDirection = Enum.FillDirection.Horizontal
topButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder
topButtonLayout.Padding = UDim.new(0, 5)
topButtonLayout.Parent = topButtonRow

local bottomButtonRow = Instance.new("Frame")
bottomButtonRow.Size = UDim2.new(1, 0, 0, 24)
bottomButtonRow.BackgroundTransparency = 1
bottomButtonRow.Parent = buttonContainer

local bottomButtonLayout = Instance.new("UIListLayout")
bottomButtonLayout.FillDirection = Enum.FillDirection.Horizontal
bottomButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder
bottomButtonLayout.Padding = UDim.new(0, 5)
bottomButtonLayout.Parent = bottomButtonRow

local activeListFrames = {}

local function updateESPForPlayer(name, color)
    local data = PLAYER_ESP_SETTINGS.players[name]
    if data and data.billboard then
        data.billboard.Frame.TextLabel.TextColor3 = color
        if color == Color3.fromRGB(255, 0, 0) then
            data.billboard.ExtentsOffset = Vector3.new(0, 1, 0)
            data.billboard.Size = UDim2.new(3, 60, 1.5, 60)
        else
            data.billboard.ExtentsOffset = Vector3.new(0, 0, 0)
            data.billboard.Size = UDim2.new(3, 0, 1.5, 0)
        end
        if data.highlight then
            data.highlight.FillColor = color
            data.highlight.OutlineColor = color
        end
    end
end

local function updateAllLists()
    for frameId, frameData in pairs(activeListFrames) do
        if frameData.updateFunc then
            frameData.updateFunc()
        end
    end
end

createButton("Add Friend", function()
    local name = textBox.Text
    if name ~= "" then
        if not table.find(PLAYER_ESP_SETTINGS.friends, name) and not table.find(PLAYER_ESP_SETTINGS.enemies, name) then
            table.insert(PLAYER_ESP_SETTINGS.friends, name)
            saveSettings()
            updateESPForPlayer(name, Color3.fromRGB(0, 255, 0))
            updateAllLists()
        end
    end
end, topButtonRow)

createButton("Add Enemy", function()
    local name = textBox.Text
    if name ~= "" then
        if not table.find(PLAYER_ESP_SETTINGS.enemies, name) and not table.find(PLAYER_ESP_SETTINGS.friends, name) then
            table.insert(PLAYER_ESP_SETTINGS.enemies, name)
            saveSettings()
            updateESPForPlayer(name, Color3.fromRGB(255, 0, 0))
            updateAllLists()
        end
    end
end, topButtonRow)

createButton("Remove Friend", function()
    local name = textBox.Text
    if name ~= "" then
        local index = table.find(PLAYER_ESP_SETTINGS.friends, name)
        if index then
            table.remove(PLAYER_ESP_SETTINGS.friends, index)
            saveSettings()
            updateESPForPlayer(name, Color3.fromRGB(255, 255, 255))
            updateAllLists()
        end
    end
end, bottomButtonRow)

createButton("Remove Enemy", function()
    local name = textBox.Text
    if name ~= "" then
        local index = table.find(PLAYER_ESP_SETTINGS.enemies, name)
        if index then
            table.remove(PLAYER_ESP_SETTINGS.enemies, index)
            saveSettings()
            updateESPForPlayer(name, Color3.fromRGB(255, 255, 255))
            updateAllLists()
        end
    end
end, bottomButtonRow)

local showButtonContainer = Instance.new("Frame")
showButtonContainer.Size = UDim2.new(1, 0, 0, 24)
showButtonContainer.BackgroundTransparency = 1
showButtonContainer.Parent = playerEspFrame

local showButtonLayout = Instance.new("UIListLayout")
showButtonLayout.FillDirection = Enum.FillDirection.Horizontal
showButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder
showButtonLayout.Padding = UDim.new(0, 5)
showButtonLayout.Parent = showButtonContainer

local function showList(list, title, listType)
    for frameId, frameData in pairs(activeListFrames) do
        if frameData.type == listType then
            if frameData.frame then
                frameData.frame:Destroy()
            end
            activeListFrames[frameId] = nil
        end
    end

    local sortedList = {table.unpack(list)}
    table.sort(sortedList, function(a, b) return a:lower() < b:lower() end)

    local outerFrame = Instance.new("Frame")
    local frameId = HttpService:GenerateGUID(false)
    outerFrame.Name = "LIST_" .. listType
    outerFrame.Size = UDim2.new(0.125, 0, 0.25, 0)
    outerFrame.Position = UDim2.new(0.7, 0, 0.7, 0)
    outerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    outerFrame.BackgroundTransparency = 0.1
    outerFrame.Active = true
    outerFrame.Draggable = true
    outerFrame.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(244, 73, 255)
    stroke.Thickness = 2
    stroke.Parent = outerFrame

    local outerLayout = Instance.new("UIListLayout")
    outerLayout.FillDirection = Enum.FillDirection.Vertical
    outerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    outerLayout.Padding = UDim.new(0, 5)
    outerLayout.Parent = outerFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = outerFrame

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    listFrame.BackgroundTransparency = 1
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.ScrollBarThickness = 6
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(244, 73, 255)
    listFrame.Parent = outerFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = listFrame

    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingTop = UDim.new(0, 5)
    scrollPadding.PaddingLeft = UDim.new(0, 5)
    scrollPadding.PaddingRight = UDim.new(0, 5)
    scrollPadding.Parent = listFrame

    local function updateList()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
                child:Destroy()
            end
        end

        sortedList = {table.unpack(list)}
        table.sort(sortedList, function(a, b) return a:lower() < b:lower() end)

        local height = 30

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 20)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 14
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = listFrame

        for i, name in ipairs(sortedList) do
            local entryFrame = Instance.new("Frame")
            entryFrame.Size = UDim2.new(0.95, 0, 0, 20)
            entryFrame.BackgroundTransparency = 1
            entryFrame.Parent = listFrame

            local entryLayout = Instance.new("UIListLayout")
            entryLayout.FillDirection = Enum.FillDirection.Horizontal
            entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
            entryLayout.Padding = UDim.new(0, 5)
            entryLayout.Parent = entryFrame

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = tostring(i) .. ". " .. name
            nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = entryFrame

            local removeButton = Instance.new("TextButton")
            removeButton.Size = UDim2.new(0.3, -5, 0, 18)
            removeButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            removeButton.Text = "Remove"
            removeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            removeButton.Font = Enum.Font.GothamBold
            removeButton.TextSize = 10
            removeButton.Parent = entryFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(244, 73, 255)
            stroke.Thickness = 1
            stroke.Parent = removeButton

            local conn = removeButton.MouseButton1Click:Connect(function()
                local index = table.find(list, name)
                if index then
                    table.remove(list, index)
                    saveSettings()
                    updateESPForPlayer(name, Color3.fromRGB(255, 255, 255))
                    updateAllLists()
                end
            end)
            table.insert(connections, conn)
            height = height + 25
        end

        listFrame.CanvasSize = UDim2.new(0, 0, 0, height)
    end

    local okButton = Instance.new("TextButton")
    okButton.Size = UDim2.new(0.2, 0, 0.075, 0)
    okButton.Position = UDim2.new(0.1, 0, 0.9, 0)
    okButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    okButton.Text = "OK"
    okButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    okButton.Font = Enum.Font.GothamBold
    okButton.TextSize = 12
    okButton.Parent = outerFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(244, 73, 255)
    stroke.Thickness = 1
    stroke.Parent = okButton

    local conn = okButton.MouseButton1Click:Connect(function()
        outerFrame:Destroy()
        activeListFrames[frameId] = nil
    end)
    table.insert(connections, conn)

    updateList()
    activeListFrames[frameId] = { type = listType, frame = outerFrame, updateFunc = updateList }
end

createButton("Show Friends", function()
    showList(PLAYER_ESP_SETTINGS.friends, "Friends", "Friends")
end, showButtonContainer)

createButton("Show Enemies", function()
    showList(PLAYER_ESP_SETTINGS.enemies, "Enemies", "Enemies")
end, showButtonContainer)

local function createSlider(parent, labelText, maxValue, defaultValue, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 40)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = parent

    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, 0, 0, 16)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = labelText .. ": " .. tostring(defaultValue)
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextSize = 14
    sliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame

    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, 0, 0, 8)
    sliderBar.Position = UDim2.new(0, 0, 0, 20)
    sliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderBar.Parent = sliderFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(244, 73, 255)
    stroke.Thickness = 1
    stroke.Parent = sliderBar

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(defaultValue / maxValue, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    sliderFill.Parent = sliderBar

    local fillStroke = Instance.new("UIStroke")
    fillStroke.Color = Color3.fromRGB(244, 73, 255)
    fillStroke.Thickness = 1
    fillStroke.Parent = sliderFill

    local dragging = false
    local inputBeganConn = sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            menu.Active = false
            local mouse = LocalPlayer:GetMouse()
            local function updateSlider()
                local relativeX = math.clamp(mouse.X - sliderBar.AbsolutePosition.X, 0, sliderBar.AbsoluteSize.X)
                local percent = relativeX / sliderBar.AbsoluteSize.X
                local value = math.floor(50 + percent * (maxValue - 50))
                sliderLabel.Text = labelText .. ": " .. tostring(value)
                sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                callback(value)
            end
            updateSlider()
            local moveConn
            moveConn = mouse.Move:Connect(function()
                if dragging then
                    updateSlider()
                else
                    moveConn:Disconnect()
                end
            end)
            local upConn
            upConn = UserInputService.InputEnded:Connect(function(inputEnded)
                if inputEnded.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    menu.Active = true
                    moveConn:Disconnect()
                    upConn:Disconnect()
                end
            end)
            table.insert(connections, moveConn)
            table.insert(connections, upConn)
        end
    end)
    table.insert(connections, inputBeganConn)
    return sliderFrame
end

createSlider(playerEspFrame, "Radius", 1500, PLAYER_ESP_SETTINGS.distanceValue, function(value)
    PLAYER_ESP_SETTINGS.distanceValue = value
    saveSettings()
end)

local objectListLayout = Instance.new("UIListLayout")
objectListLayout.Padding = UDim.new(0, 5)
objectListLayout.FillDirection = Enum.FillDirection.Vertical
objectListLayout.SortOrder = Enum.SortOrder.LayoutOrder
objectListLayout.Parent = objectEspFrame

createToggleButton("Object ESP", OBJECT_ESP_SETTINGS.enabled, function(state)
    OBJECT_ESP_SETTINGS.enabled = state
    saveSettings()
end, objectEspFrame)

for name, data in pairs(TRACKED_OBJECTS) do
    createToggleButton(name, data.enabled, function(state)
        data.enabled = state
        saveSettings()
    end, objectEspFrame)
end

createToggleButton("Distance", OBJECT_ESP_SETTINGS.distance, function(state)
    OBJECT_ESP_SETTINGS.distance = state
    saveSettings()
end, objectEspFrame)

createSlider(objectEspFrame, "Radius", 1500, OBJECT_ESP_SETTINGS.distanceValue, function(value)
    OBJECT_ESP_SETTINGS.distanceValue = value
    saveSettings()
end)

local miscListLayout = Instance.new("UIListLayout")
miscListLayout.Padding = UDim.new(0, 5)
miscListLayout.FillDirection = Enum.FillDirection.Vertical
miscListLayout.SortOrder = Enum.SortOrder.LayoutOrder
miscListLayout.Parent = miscFrame

local function toggleNoCooldowns(state)
    MISC_SETTINGS.noCooldowns = state
    saveSettings()

    -- Disconnect existing connection if it exists
    if noCooldownsConnection then
        noCooldownsConnection:Disconnect()
        noCooldownsConnection = nil
    end

    if not state then return end

    local MAX_DISTANCE = 20 -- Maximum distance in studs (20 meters)
    local MAX_PROMPTS = 5 -- Maximum number of prompts to process per frame
    local SCAN_INTERVAL = 0.1 -- Seconds between full scans for new prompts

    local cachedPrompts = {} -- Cache of prompts with their positions
    local lastScanTime = 0

    noCooldownsConnection = RunService.Heartbeat:Connect(function()
        local player = Players.LocalPlayer
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local rootPart = character.HumanoidRootPart
        local cameraPos = rootPart.CFrame.Position
        local currentTime = tick()

        -- Periodically scan for new prompts
        if currentTime - lastScanTime >= SCAN_INTERVAL then
            local filter = Workspace:FindFirstChild("Filter")
            if filter then
                local folders = {
                    filter:FindFirstChild("SpawnedPiles"),
                    filter:FindFirstChild("SpawnedBread"),
                    filter:FindFirstChild("SpawnedTools")
                }

                -- Clear invalid prompts from cache
                for i = #cachedPrompts, 1, -1 do
                    local promptData = cachedPrompts[i]
                    if not promptData.prompt:IsDescendantOf(Workspace) or not promptData.prompt.Parent or not promptData.prompt.Parent:IsA("BasePart") then
                        table.remove(cachedPrompts, i)
                    end
                end

                -- Collect new prompts
                for _, folder in ipairs(folders) do
                    if folder then
                        for _, obj in ipairs(folder:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.Parent and obj.Parent:IsA("BasePart") then
                                -- Check if prompt is already cached
                                local alreadyCached = false
                                for _, cachedData in ipairs(cachedPrompts) do
                                    if cachedData.prompt == obj then
                                        alreadyCached = true
                                        break
                                    end
                                end
                                if not alreadyCached then
                                    table.insert(cachedPrompts, { prompt = obj, position = obj.Parent.Position })
                                end
                            end
                        end
                    end
                end
                lastScanTime = currentTime
            end
        end

        -- Filter prompts within 20 meters and sort by distance
        local validPrompts = {}
        for _, promptData in ipairs(cachedPrompts) do
            local distance = (cameraPos - promptData.position).Magnitude
            if distance <= MAX_DISTANCE then
                table.insert(validPrompts, { prompt = promptData.prompt, distance = distance })
            end
        end

        -- Sort by distance to prioritize closest prompts
        table.sort(validPrompts, function(a, b) return a.distance < b.distance end)

        -- Process up to MAX_PROMPTS
        for i = 1, math.min(#validPrompts, MAX_PROMPTS) do
            local prompt = validPrompts[i].prompt
            if prompt:IsDescendantOf(Workspace) then
                prompt.HoldDuration = 0
            end
        end
    end)
    table.insert(connections, noCooldownsConnection)
end

local function toggleAutoSafeHack(state)
    MISC_SETTINGS.autoSafeHack = state
    if autoSafeHackConnection then
        autoSafeHackConnection:Disconnect()
        autoSafeHackConnection = nil
    end
    if state then
        local currentFrameIndex = 1
        local lastClickTime = 0
        local TIMEOUT_DURATION = 0.01
        autoSafeHackConnection = RunService.Heartbeat:Connect(function()
            local lockpickGui = PlayerGui:FindFirstChild("LockpickGUI")
            if not lockpickGui or not lockpickGui.MF or not lockpickGui.MF.LP_Frame or not lockpickGui.MF.LP_Frame.Frames then
                currentFrameIndex = 1
                return
            end
            local frameName = "B" .. currentFrameIndex
            local currentFrame = lockpickGui.MF.LP_Frame.Frames:FindFirstChild(frameName)
            if not currentFrame then
                currentFrameIndex = 1
                return
            end
            local bar = currentFrame:FindFirstChild("Bar")
            if bar and bar:IsA("ImageLabel") then
                local pos = bar.Position
                bar.Size = UDim2.new(0, 35, 0, 350)
                if pos.Y.Offset >= -100 and pos.Y.Offset <= 100 then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
                    task.wait(0.25)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
                    currentFrameIndex += 1
                    lastClickTime = tick()
                end
            elseif tick() - lastClickTime > TIMEOUT_DURATION then
                currentFrameIndex += 1
                lastClickTime = tick()
            end
        end)
        table.insert(connections, autoSafeHackConnection)
    end
    saveSettings()
end

createToggleButton("No Cooldowns", MISC_SETTINGS.noCooldowns, toggleNoCooldowns, miscFrame)
createToggleButton("Auto Safe Hack", MISC_SETTINGS.autoSafeHack, toggleAutoSafeHack, miscFrame)

local function createDealerBillboard(model, valueName)
    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then 
        return nil 
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DealerESP_" .. valueName
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(3, 0, 1.5, 0)
    billboard.Adornee = primaryPart
    billboard.Parent = primaryPart

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.ZIndex = 2
    frame.Parent = billboard

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 0, 255)
    label.TextStrokeTransparency = 0.5
    label.Text = "Dealer: " .. valueName
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Size = UDim2.new(1, 0, 1, 0)
    label.ZIndex = 3
    label.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = frame

    return billboard
end

local function getValueNames()
    local valueNames = {}
    local shopz = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Shopz")
    if not shopz then
        return valueNames 
    end

    for _, shop in ipairs(shopz:GetChildren()) do
        if shop:IsA("Model") then
            local currentStocks = shop:FindFirstChild("CurrentStocks")
            if currentStocks then
                for _, value in ipairs(currentStocks:GetChildren()) do
                    if value:IsA("IntConstrainedValue") or value:IsA("IntValue") or value:IsA("NumberValue") then
                        if not table.find(valueNames, value.Name) then
                            table.insert(valueNames, value.Name)
                        end
                    end
                end
            end
        end
    end
    table.sort(valueNames, function(a, b) return a:lower() < b:lower() end)
    return valueNames
end

local function updateDealerBillboards()
    for _, data in ipairs(DEALER_ESP_SETTINGS.billboards) do
        if data.billboard then
            data.billboard:Destroy()
        end
    end
    DEALER_ESP_SETTINGS.billboards = {}

    if not DEALER_ESP_SETTINGS.enabled or DEALER_ESP_SETTINGS.selectedValue == "" then
        return
    end

    local shopz = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Shopz")
    if not shopz then return end

    for _, shop in ipairs(shopz:GetChildren()) do
        if shop:IsA("Model") then
            local currentStocks = shop:FindFirstChild("CurrentStocks")
            if currentStocks then
                local value = currentStocks:FindFirstChild(DEALER_ESP_SETTINGS.selectedValue)
                if value and (value:IsA("IntValue") or value:IsA("IntConstrainedValue") or value:IsA("NumberValue")) and value.Value > 0 then
                    for _, da in pairs(shop:GetChildren()) do
                        if da:IsA("Model") then
                            local billboard = createDealerBillboard(da, DEALER_ESP_SETTINGS.selectedValue)
                            if billboard then
                                table.insert(DEALER_ESP_SETTINGS.billboards, { model = da, billboard = billboard })
                            end
                        end
                    end
                end
            end
        end
    end
end

createToggleButton("Dealer ESP", DEALER_ESP_SETTINGS.enabled, function(state)
    DEALER_ESP_SETTINGS.enabled = state
    updateDealerBillboards()
    saveSettings()
end, miscFrame)

local dealerDropdownContainer = Instance.new("Frame")
dealerDropdownContainer.Size = UDim2.new(1, 0, 0, 18)
dealerDropdownContainer.BackgroundTransparency = 1
dealerDropdownContainer.Parent = miscFrame

local dealerDropdownButton = Instance.new("TextButton")
dealerDropdownButton.LayoutOrder = 1
dealerDropdownButton.Position = UDim2.new(0, 0, 0, 4)
dealerDropdownButton.Size = UDim2.new(0.98, 0, 0, 18)
dealerDropdownButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dealerDropdownButton.Text = DEALER_ESP_SETTINGS.selectedValue == "" and "Select Weapon" or DEALER_ESP_SETTINGS.selectedValue
dealerDropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dealerDropdownButton.Font = Enum.Font.GothamBold
dealerDropdownButton.TextSize = 12
dealerDropdownButton.Parent = dealerDropdownContainer

local dealerStroke = Instance.new("UIStroke")
dealerStroke.Color = Color3.fromRGB(244, 73, 255)
dealerStroke.Thickness = 1
dealerStroke.Parent = dealerDropdownButton

local dealerDropdownFrame = Instance.new("ScrollingFrame")
dealerDropdownFrame.ZIndex = 2
dealerDropdownFrame.Size = UDim2.new(1, 0, 0, 150)
dealerDropdownFrame.Position = UDim2.new(0, 0, 1, 5)
dealerDropdownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dealerDropdownFrame.BackgroundTransparency = 0.1
dealerDropdownFrame.Visible = false
dealerDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
dealerDropdownFrame.ScrollBarThickness = 6
dealerDropdownFrame.ScrollBarImageColor3 = Color3.fromRGB(244, 73, 255)
dealerDropdownFrame.Parent = dealerDropdownContainer

local dealerDropdownStroke = Instance.new("UIStroke")
dealerDropdownStroke.Color = Color3.fromRGB(244, 73, 255)
dealerDropdownStroke.Thickness = 1
dealerDropdownStroke.Parent = dealerDropdownFrame

local dealerDropdownLayout = Instance.new("UIListLayout")
dealerDropdownLayout.FillDirection = Enum.FillDirection.Vertical
dealerDropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
dealerDropdownLayout.Padding = UDim.new(0, 2)
dealerDropdownLayout.Parent = dealerDropdownFrame

local dealerDropdownPadding = Instance.new("UIPadding")
dealerDropdownPadding.PaddingTop = UDim.new(0, 2)
dealerDropdownPadding.PaddingLeft = UDim.new(0, 2)
dealerDropdownPadding.PaddingBottom = UDim.new(0, 2)
dealerDropdownPadding.Parent = dealerDropdownFrame

local toolDropdownContainer = Instance.new("Frame")
toolDropdownContainer.Size = UDim2.new(1, 0, 0, 18)
toolDropdownContainer.BackgroundTransparency = 1
toolDropdownContainer.LayoutOrder = 3
toolDropdownContainer.Parent = miscFrame

local toolDropdownButton = Instance.new("TextButton")
toolDropdownButton.Position = UDim2.new(0, 0, 0, 2)
toolDropdownButton.Size = UDim2.new(0.98, 0, 0, 18)
toolDropdownButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toolDropdownButton.Text = TOOL_ESP_SETTINGS.selectedTool == "" and "Select Tool" or TOOL_ESP_SETTINGS.selectedTool .. " - Tool to search"
toolDropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toolDropdownButton.Font = Enum.Font.GothamBold
toolDropdownButton.TextSize = 12
toolDropdownButton.Parent = toolDropdownContainer

local toolDropdownStroke = Instance.new("UIStroke")
toolDropdownStroke.Color = Color3.fromRGB(244, 73, 255)
toolDropdownStroke.Thickness = 1
toolDropdownStroke.Parent = toolDropdownButton

local toolDropdownFrame = Instance.new("ScrollingFrame")
toolDropdownFrame.ZIndex = 2
toolDropdownFrame.Size = UDim2.new(1, 0, 0, 150)
toolDropdownFrame.Position = UDim2.new(0, 0, 1, 5)
toolDropdownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
toolDropdownFrame.BackgroundTransparency = 0.1
toolDropdownFrame.Visible = false
toolDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
toolDropdownFrame.ScrollBarThickness = 6
toolDropdownFrame.ScrollBarImageColor3 = Color3.fromRGB(244, 73, 255)
toolDropdownFrame.Parent = toolDropdownContainer

local toolDropdownLayout = Instance.new("UIListLayout")
toolDropdownLayout.FillDirection = Enum.FillDirection.Vertical
toolDropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
toolDropdownLayout.Padding = UDim.new(0, 2)
toolDropdownLayout.Parent = toolDropdownFrame

local toolDropdownPadding = Instance.new("UIPadding")
toolDropdownPadding.PaddingTop = UDim.new(0, 2)
toolDropdownPadding.PaddingLeft = UDim.new(0, 2)
toolDropdownPadding.PaddingBottom = UDim.new(0, 2)
toolDropdownPadding.Parent = toolDropdownFrame

local playersScrollFrame = Instance.new("ScrollingFrame")
playersScrollFrame.Name = "PlayersScrollFrame"
playersScrollFrame.LayoutOrder = 4
playersScrollFrame.Size = UDim2.new(0.98, 0, 0, 120)
playersScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
playersScrollFrame.BackgroundTransparency = 0.1
playersScrollFrame.ScrollBarThickness = 6
playersScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(244, 73, 255)
playersScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playersScrollFrame.Parent = miscFrame

local playersScrollStroke = Instance.new("UIStroke")
playersScrollStroke.Color = Color3.fromRGB(244, 73, 255)
playersScrollStroke.Thickness = 1
playersScrollStroke.Parent = playersScrollFrame

local playersScrollLayout = Instance.new("UIListLayout")
playersScrollLayout.FillDirection = Enum.FillDirection.Vertical
playersScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersScrollLayout.Padding = UDim.new(0, 2)
playersScrollLayout.Parent = playersScrollFrame

local playersTitleLabel = Instance.new("TextLabel")
playersTitleLabel.Name = "PlayersTitleLabel"
playersTitleLabel.Size = UDim2.new(1, 0, 0, 16)
playersTitleLabel.BackgroundTransparency = 1
playersTitleLabel.Text = "Players with Tool:"
playersTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
playersTitleLabel.Font = Enum.Font.GothamBold
playersTitleLabel.TextSize = 14
playersTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
playersTitleLabel.Parent = playersScrollFrame

local function updateDealerDropdown()
    for _, child in ipairs(dealerDropdownFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    dealerDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

    local valueNames = getValueNames()
    local height = 0
    for i, name in ipairs(valueNames) do
        local suggestionButton = Instance.new("TextButton")
        suggestionButton.ZIndex = 2
        suggestionButton.Size = UDim2.new(0.95, 0, 0, 20)
        suggestionButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        suggestionButton.Text = name
        suggestionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        suggestionButton.Font = Enum.Font.Gotham
        suggestionButton.TextSize = 12
        suggestionButton.TextXAlignment = Enum.TextXAlignment.Left
        suggestionButton.Parent = dealerDropdownFrame

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Color3.fromRGB(244, 73, 255)
        buttonStroke.Thickness = 1
        buttonStroke.Parent = suggestionButton

        local conn = suggestionButton.MouseButton1Click:Connect(function()
            DEALER_ESP_SETTINGS.selectedValue = name
            dealerDropdownButton.Text = name
            dealerDropdownFrame.Visible = false
            updateDealerBillboards()
            saveSettings()
        end)
        table.insert(connections, conn)
        height = height + 22
    end
    dealerDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, height)
end

table.insert(connections, dealerDropdownButton.MouseButton1Click:Connect(function()
    dealerDropdownFrame.Visible = not dealerDropdownFrame.Visible
    if dealerDropdownFrame.Visible then
        updateDealerDropdown()
    end
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local mouse = LocalPlayer:GetMouse()
    local dropdownPos = dealerDropdownFrame.AbsolutePosition
    local dropdownSize = dealerDropdownFrame.AbsoluteSize
    local buttonPos = dealerDropdownButton.AbsolutePosition
    local buttonSize = dealerDropdownButton.AbsoluteSize
    local mouseX, mouseY = mouse.X, mouse.Y
    if mouseX < dropdownPos.X or mouseX > dropdownPos.X + dropdownSize.X or
       mouseY < dropdownPos.Y or mouseY > dropdownPos.Y + dropdownSize.Y then
        if mouseX < buttonPos.X or mouseX > buttonPos.X + buttonSize.X or
           mouseY < buttonPos.Y or mouseY > buttonPos.Y + buttonSize.Y then
            dealerDropdownFrame.Visible = false
        end
    end
end))

local function getToolNames()
    local toolNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local backpack = player:FindFirstChild("Backpack")
            local character = player.Character
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and not table.find(toolNames, tool.Name) then
                        table.insert(toolNames, tool.Name)
                    end
                end
            end
            if character then
                for _, tool in ipairs(character:GetChildren()) do
                    if tool:IsA("Tool") and not table.find(toolNames, tool.Name) then
                        table.insert(toolNames, tool.Name)
                    end
                end
            end
        end
    end
    table.sort(toolNames, function(a, b) return a:lower() < b:lower() end)
    return toolNames
end

local function updatePlayersLabel()
    for _, child in ipairs(playersScrollFrame:GetChildren()) do
        if child:IsA("TextLabel") and child.Name ~= "PlayersTitleLabel" then
            child:Destroy()
        end
    end
    playersScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

    local playersWithTool = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local hasTool = false
            local backpack = player:FindFirstChild("Backpack")
            local character = player.Character
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == TOOL_ESP_SETTINGS.selectedTool then
                        hasTool = true
                        break
                    end
                end
            end
            if character and not hasTool then
                for _, tool in ipairs(character:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == TOOL_ESP_SETTINGS.selectedTool then
                        hasTool = true
                        break
                    end
                end
            end
            if hasTool then
                table.insert(playersWithTool, {DisplayName = player.DisplayName, Name = player.Name})
            end
        end
    end
    table.sort(playersWithTool, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)

    local height = 16 -- Height of title label
    if #playersWithTool == 0 or TOOL_ESP_SETTINGS.selectedTool == "" then
        local noneLabel = Instance.new("TextLabel")
        noneLabel.Name = "NoneLabel"
        noneLabel.Size = UDim2.new(1, 0, 0, 16)
        noneLabel.BackgroundTransparency = 1
        noneLabel.Text = "(None)"
        noneLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        noneLabel.Font = Enum.Font.Gotham
        noneLabel.TextSize = 12
        noneLabel.TextXAlignment = Enum.TextXAlignment.Left
        noneLabel.Parent = playersScrollFrame
        height = height + 18
    else
        for _, player in ipairs(playersWithTool) do
            local playerLabel = Instance.new("TextLabel")
            playerLabel.Name = "PlayerLabel"
            playerLabel.Size = UDim2.new(1, 0, 0, 16)
            playerLabel.BackgroundTransparency = 1
            playerLabel.Text = player.DisplayName .. " (" .. player.Name .. ")"
            playerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            playerLabel.Font = Enum.Font.Gotham
            playerLabel.TextSize = 12
            playerLabel.TextXAlignment = Enum.TextXAlignment.Left
            playerLabel.Parent = playersScrollFrame
            height = height + 18
        end
    end
    playersScrollFrame.CanvasSize = UDim2.new(0, 0, 0, height)
    TOOL_ESP_SETTINGS.playersWithTool = playersWithTool
end

local function updateToolDropdown()
    for _, child in ipairs(toolDropdownFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    toolDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

    local toolNames = getToolNames()
    local height = 0
    for _, name in ipairs(toolNames) do
        local suggestionButton = Instance.new("TextButton")
        suggestionButton.ZIndex = 2
        suggestionButton.Size = UDim2.new(0.95, 0, 0, 20)
        suggestionButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        suggestionButton.Text = name
        suggestionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        suggestionButton.Font = Enum.Font.Gotham
        suggestionButton.TextSize = 12
        suggestionButton.TextXAlignment = Enum.TextXAlignment.Left
        suggestionButton.Parent = toolDropdownFrame

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Color3.fromRGB(244, 73, 255)
        buttonStroke.Thickness = 1
        buttonStroke.Parent = suggestionButton

        local conn = suggestionButton.MouseButton1Click:Connect(function()
            TOOL_ESP_SETTINGS.selectedTool = name
            toolDropdownButton.Text = name .. " - Tool to search"
            toolDropdownFrame.Visible = false
            updatePlayersLabel()
            saveSettings()
        end)
        table.insert(connections, conn)
        height = height + 22
    end
    toolDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, height)
end

table.insert(connections, toolDropdownButton.MouseButton1Click:Connect(function()
    toolDropdownFrame.Visible = not toolDropdownFrame.Visible
    if toolDropdownFrame.Visible then
        updateToolDropdown()
    end
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local mouse = LocalPlayer:GetMouse()
    local dropdownPos = toolDropdownFrame.AbsolutePosition
    local dropdownSize = toolDropdownFrame.AbsoluteSize
    local buttonPos = toolDropdownButton.AbsolutePosition
    local buttonSize = toolDropdownButton.AbsoluteSize
    if mouse.X < dropdownPos.X or mouse.X > dropdownPos.X + dropdownSize.X or
       mouse.Y < dropdownPos.Y or mouse.Y > dropdownPos.Y + dropdownSize.Y then
        if mouse.X < buttonPos.X or mouse.X > buttonPos.X + buttonSize.X or
           mouse.Y < buttonPos.Y or mouse.Y > buttonPos.Y + buttonSize.Y then
            toolDropdownFrame.Visible = false
        end
    end
end))

local function setTab(tab)
    playerEspFrame.Visible = tab == "player"
    objectEspFrame.Visible = tab == "object"
    miscFrame.Visible = tab == "misc"
    playerTabButton.BackgroundColor3 = tab == "player" and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(20, 20, 20)
    objectTabButton.BackgroundColor3 = tab == "object" and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(20, 20, 20)
    miscTabButton.BackgroundColor3 = tab == "misc" and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(20, 20, 20)
end

table.insert(connections, playerTabButton.MouseButton1Click:Connect(function()
    setTab("player")
end))

table.insert(connections, objectTabButton.MouseButton1Click:Connect(function()
    setTab("object")
end))

table.insert(connections, miscTabButton.MouseButton1Click:Connect(function()
    setTab("misc")
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.U then
        menu.Visible = not menu.Visible
    end
end))

local function getFixedBillboardSize(labelName)
    if labelName == "Register" then
        return UDim2.new(2, 0, 2, 0)
    elseif labelName == "Medium Safe" then
        return UDim2.new(3, 0, 4, 0)
    elseif labelName == "Small Safe" then
        return UDim2.new(2.5, 0, 2.5, 0)
    elseif labelName == "Trash" then
        return UDim2.new(3, 0, 1.5, 0)
    elseif labelName == "Red Crate" or labelName == "Yellow Crate" then
        return UDim2.new(4.5, 0, 2.5, 0)
    end
    return UDim2.new(1, 0, 1, 0)
end

local function isYellowColor(color)
    local h, s, v = Color3.toHSV(color)
    return h >= 40/360 and h <= 60/360 and s > 0.2 and v > 0.3
end

local function isRedColor(color)
    local h, s, v = Color3.toHSV(color)
    return (h <= 10/360 or h >= 350/360) and s > 0.2 and v > 0.3
end

local function createESPBox(name, color, isPlayer, parentPart, labelName)
    if isPlayer then
        local highlightId = HttpService:GenerateGUID(false)
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_" .. name .. "_" .. highlightId
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0.7
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false
        highlight.Parent = gui

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_UI_" .. name .. "_" .. highlightId
        billboard.ResetOnSpawn = false
        billboard.AlwaysOnTop = true
        if color == Color3.fromRGB(255, 0, 0) then
            billboard.ExtentsOffset = Vector3.new(0, 1, 0)
            billboard.Size = UDim2.new(3, 60, 1.5, 60)
        else
            billboard.ExtentsOffset = Vector3.new(0, 0, 0)
            billboard.Size = UDim2.new(3, 0, 1.5, 0)
        end
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = parentPart
        billboard.Parent = parentPart
        billboard.Enabled = false

        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.ZIndex = 2
        frame.Parent = billboard

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.TextStrokeTransparency = 0.5
        label.Text = name
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.ZIndex = 3
        label.Parent = frame

        local healthBillboard = Instance.new("BillboardGui")
        healthBillboard.Name = "ESP_Health_" .. name .. "_" .. highlightId
        healthBillboard.AlwaysOnTop = true
        healthBillboard.ResetOnSpawn = false
        healthBillboard.Size = UDim2.new(0.2, 0, 5, 0)
        healthBillboard.StudsOffset = Vector3.new(-2, 0, 0)
        healthBillboard.Adornee = parentPart
        healthBillboard.Parent = parentPart
        healthBillboard.Enabled = false

        local healthBack = Instance.new("Frame")
        healthBack.BorderColor3 = Color3.fromRGB(100, 0, 100)
        healthBack.Size = UDim2.new(1.1, 0, 1.005, 0)
        healthBack.Position = UDim2.new(-0.05, 0, -0.0025, 0)
        healthBack.BackgroundColor3 = Color3.fromRGB(0, 0, 35)
        healthBack.BackgroundTransparency = 0.5
        healthBack.ZIndex = 2
        healthBack.Parent = healthBillboard

        local healthFrame = Instance.new("Frame")
        healthFrame.Size = UDim2.new(1, 0, 1, 0)
        healthFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFrame.BackgroundTransparency = 0.5
        healthFrame.ZIndex = 2
        healthFrame.Parent = healthBillboard

        return billboard, label, healthFrame, highlight, highlightId, healthBillboard
    else
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_" .. name
        billboard.AlwaysOnTop = true
        billboard.ResetOnSpawn = false
        billboard.Size = getFixedBillboardSize(labelName)
        billboard.Adornee = parentPart
        billboard.Parent = parentPart
        billboard.Enabled = false

        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.ZIndex = 2
        frame.Parent = billboard

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.TextStrokeTransparency = 0.5
        label.Text = OBJECT_ESP_SETTINGS.distance and name .. " [0m]" or name
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.ZIndex = 3
        label.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Thickness = 2
        stroke.Transparency = 0.2
        stroke.Parent = frame

        return billboard, label
    end
end

local function getColor(plr)
    if table.find(PLAYER_ESP_SETTINGS.friends, plr.Name) then
        return Color3.fromRGB(0, 255, 0)
    elseif table.find(PLAYER_ESP_SETTINGS.enemies, plr.Name) then
        return Color3.fromRGB(255, 0, 0)
    else
        if plr.TeamColor.Color then
            return plr.TeamColor.Color
        else
            return Color3.fromRGB(255, 255, 255)
        end
    end
end

local function cleanupPlayerESP(name)
    local data = PLAYER_ESP_SETTINGS.players[name]
    if data then
        if data.billboard then
            data.billboard:Destroy()
        end
        if data.healthBillboard then
            data.healthBillboard:Destroy()
        end
        if data.highlight then
            data.highlight:Destroy()
        end
        PLAYER_ESP_SETTINGS.players[name] = nil
    end
end

local function addObject(model, labelName, color)
    for _, objData in ipairs(TRACKED_OBJECTS[labelName].objects) do
        if objData.model == model then return end
    end
    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return end
    local billboard, label = createESPBox(labelName, color, false, primaryPart, labelName)
    table.insert(TRACKED_OBJECTS[labelName].objects, { model = model, billboard = billboard, label = label })
end

local function addPlayer(player)
    if player == LocalPlayer then return end
    cleanupPlayerESP(player.Name)
    local function setupPlayerESP(character)
        if not character then return end
        if activeSetupCoroutines[player.Name] then return end
        activeSetupCoroutines[player.Name] = true

        local success, err = pcall(function()
            local charactersFolder = Workspace:WaitForChild("Characters")
            local characterInFolder = charactersFolder:WaitForChild(player.Name, 5)
            if not characterInFolder then
                warn("Character for player " .. player.Name .. " not found in Workspace.Characters")
                return
            end
            local humanoid = character:WaitForChild("Humanoid", 5)
            local rootPart = character:WaitForChild("HumanoidRootPart", 5)
            if not humanoid or not rootPart then
                warn("Humanoid or HumanoidRootPart not found for player " .. player.Name)
                return
            end
            cleanupPlayerESP(player.Name)
            local billboard, label, healthFrame, highlight, highlightId, healthBillboard = createESPBox(player.Name, getColor(player), true, rootPart)
            highlight.Adornee = character
            PLAYER_ESP_SETTINGS.players[player.Name] = {
                player = player,
                billboard = billboard,
                label = label,
                healthFrame = healthFrame,
                highlight = highlight,
                highlightId = highlightId,
                character = character,
                healthBillboard = healthBillboard
            }
        end)
        activeSetupCoroutines[player.Name] = nil
        if not success then
            warn("Error setting up ESP for player " .. player.Name .. ": " .. tostring(err))
        end
    end
    if player.Character then
        setupPlayerESP(player.Character)
    end
    local characterConn = player.CharacterAdded:Connect(function(newCharacter)
        cleanupPlayerESP(player.Name)
        setupPlayerESP(newCharacter)
    end)
    table.insert(connections, characterConn)
end

local function detectRedCratesAndTrash()
    local pileRoot = Workspace.Filter and Workspace.Filter.SpawnedPiles
    if not pileRoot then return end
    for _, model in ipairs(pileRoot:GetChildren()) do
        if not model:IsA("Model") then continue end
        local name = model.Name
        if name == "S1" or name == "S2" then
            addObject(model, "Trash", TRACKED_OBJECTS["Trash"].color)
        else
            for _, part in ipairs(model:GetChildren()) do
                if part:IsA("MeshPart") then
                    local emitter = part:FindFirstChildOfClass("ParticleEmitter")
                    if emitter then
                        local color = emitter.Color.Keypoints[1].Value
                        if isYellowColor(color) then
                            addObject(model, "Yellow Crate", TRACKED_OBJECTS["Yellow Crate"].color)
                        elseif isRedColor(color) then
                            addObject(model, "Red Crate", TRACKED_OBJECTS["Red Crate"].color)
                        end
                        break
                    end
                end
            end
        end
    end
end

local function detectSafes()
    local mapRoot = Workspace.Map and Workspace.Map.BredMakurz
    if not mapRoot then return end
    for _, obj in ipairs(mapRoot:GetChildren()) do
        if not obj:IsA("Model") then continue end
        local values = obj.Values
        local broken = values and values.Broken
        if broken and broken:IsA("BoolValue") and not broken.Value then
            local name = obj.Name
            local labelName = name:match("^SmallSafe") and "Small Safe" or
                             name:match("^MediumSafe") and "Medium Safe" or
                             name:match("^Register") and "Register" or nil
            if labelName then
                addObject(obj, labelName, TRACKED_OBJECTS[labelName].color)
            end
        end
    end
end

local function cleanObjects()
    for labelName, data in pairs(TRACKED_OBJECTS) do
        for i = #data.objects, 1, -1 do
            local objData = data.objects[i]
            if not objData.model or not objData.model:IsDescendantOf(Workspace) or
               (data.hasValues and objData.model.Values and objData.model.Values.Broken and objData.model.Values.Broken.Value) then
                if objData.billboard then
                    objData.billboard:Destroy()
                end
                table.remove(data.objects, i)
            end
        end
    end
end

local function cleanPlayers()
    for name, data in pairs(PLAYER_ESP_SETTINGS.players) do
        if not data.player or not data.player.Parent or not data.player.Character then
            cleanupPlayerESP(name)
        end
    end
end

local function cleanAll()
    cleanObjects()
    cleanPlayers()
end

local function updateESP()
    local cameraPos = LocalPlayer.Character.HumanoidRootPart.CFrame.Position
    if OBJECT_ESP_SETTINGS.enabled then
        for labelName, data in pairs(TRACKED_OBJECTS) do
            if not data.enabled then
                for _, item in ipairs(data.objects) do
                    item.billboard.Enabled = false
                end
                continue
            end
            for _, objData in ipairs(data.objects) do
                local model = objData.model
                if not model or not model:IsDescendantOf(Workspace) or not model.PrimaryPart then
                    objData.billboard.Enabled = false
                    continue
                end
                local dist = (cameraPos - model.PrimaryPart.Position).Magnitude
                if dist > OBJECT_ESP_SETTINGS.distanceValue then
                    objData.billboard.Enabled = false
                    continue
                end
                objData.billboard.Enabled = true
                if OBJECT_ESP_SETTINGS.distance then
                    local baseText = objData.label.Text:match("^(.-)%s*%[.*$") or objData.label.Text
                    objData.label.Text = baseText .. " [" .. math.floor(dist) .. "m]"
                else
                    objData.label.Text = objData.label.Text:match("^(.-)%s*%[.*$") or objData.label.Text
                end
            end
        end
    else
        for _, data in pairs(TRACKED_OBJECTS) do
            for _, item in ipairs(data.objects) do
                item.billboard.Enabled = false
            end
        end
    end
    if PLAYER_ESP_SETTINGS.enabled then
        for name, data in pairs(PLAYER_ESP_SETTINGS.players) do
            data.billboard.Frame.TextLabel.TextColor3 = getColor(data.player)
            data.highlight.FillColor = getColor(data.player)
            data.highlight.OutlineColor = getColor(data.player)
            local character = data.player and data.player.Character
            if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
                if data.billboard then
                    data.billboard.Enabled = false
                end
                if data.healthBillboard then
                    data.healthBillboard.Enabled = false
                end
                if data.highlight then
                    data.highlight.Enabled = false
                end
                continue
            end
            local humanoid = character.Humanoid
            local rootPart = character.HumanoidRootPart
            local dist = (cameraPos - rootPart.Position).Magnitude
            if dist > PLAYER_ESP_SETTINGS.distanceValue then
                data.billboard.Enabled = false
                data.healthBillboard.Enabled = false
                data.highlight.Enabled = false
                continue
            end
            if data.highlight and data.highlight.Adornee ~= character then
                data.highlight.Adornee = character
            end
            data.billboard.Enabled = PLAYER_ESP_SETTINGS.name
            data.healthBillboard.Enabled = PLAYER_ESP_SETTINGS.health
            data.label.Visible = PLAYER_ESP_SETTINGS.name
            data.highlight.Enabled = PLAYER_ESP_SETTINGS.highlight
            if PLAYER_ESP_SETTINGS.health and humanoid and humanoid.Health and humanoid.MaxHealth then
                data.healthFrame.Size = UDim2.new(1, 0, humanoid.Health / humanoid.MaxHealth, 0)
                data.healthFrame.BackgroundColor3 = Color3.fromRGB(
                    255 * (1 - humanoid.Health / humanoid.MaxHealth),
                    255 * (humanoid.Health / humanoid.MaxHealth),
                    0
                )
            end
            data.label.Text = PLAYER_ESP_SETTINGS.distance and name .. " [" .. math.floor(dist) .. "m]" or name
        end
    else
        for _, data in pairs(PLAYER_ESP_SETTINGS.players) do
            if data.billboard then
                data.billboard.Enabled = false
            end
            if data.healthBillboard then
                data.healthBillboard.Enabled = false
            end
            if data.highlight then
                data.highlight.Enabled = false
            end
        end
    end
end

createButton("Remove Script", function()
    if noCooldownsConnection then
        noCooldownsConnection:Disconnect()
        noCooldownsConnection = nil
    end
    if autoSafeHackConnection then
        autoSafeHackConnection:Disconnect()
        autoSafeHackConnection = nil
    end
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    for _, data in pairs(TRACKED_OBJECTS) do
        for _, item in ipairs(data.objects) do
            if item.billboard then
                item.billboard:Destroy()
            end
        end
        data.objects = {}
    end
    for _, data in pairs(PLAYER_ESP_SETTINGS.players) do
        if data.billboard then
            data.billboard:Destroy()
        end
        if data.healthBillboard then
            data.healthBillboard:Destroy()
        end
        if data.highlight then
            data.highlight:Destroy()
        end
    end
    PLAYER_ESP_SETTINGS.players = {}
    for _, data in ipairs(DEALER_ESP_SETTINGS.billboards) do
        if data.billboard then
            data.billboard:Destroy()
        end
    end
    DEALER_ESP_SETTINGS.billboards = {}
    for _, frameData in pairs(activeListFrames) do
        if frameData.frame then
            frameData.frame:Destroy()
        end
    end
    activeListFrames = {}
    if gui then
        gui:Destroy()
    end
end, miscFrame)

toggleAutoSafeHack(MISC_SETTINGS.autoSafeHack)
toggleNoCooldowns(MISC_SETTINGS.noCooldowns)

for _, player in ipairs(Players:GetPlayers()) do
    addPlayer(player)
end
table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
table.insert(connections, Players.PlayerRemoving:Connect(function(player)
    cleanupPlayerESP(player.Name)
end))

local lastDetection = 0
local DETECTION_INTERVAL = 3
local lastESPUpdate = 0
local ESP_UPDATE_INTERVAL = 0.5

table.insert(connections, RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastDetection >= DETECTION_INTERVAL then
        detectRedCratesAndTrash()
        detectSafes()
        cleanAll()
        updateDealerBillboards()
        updateToolDropdown()
        updatePlayersLabel()
        lastDetection = currentTime
    end
    if currentTime - lastESPUpdate >= ESP_UPDATE_INTERVAL then
        updateESP()
        lastESPUpdate = currentTime
    end
end))
