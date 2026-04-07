local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()
--themses now orks
local Themes = {
    ["Purple"] = {
        MainBG = Color3.fromRGB(15, 15, 20),
        TitleBar = Color3.fromRGB(160, 32, 240),
        Accent = Color3.fromRGB(46, 204, 113),
        ButtonActive = Color3.fromRGB(160, 32, 240),
        ButtonInactive = Color3.fromRGB(40, 40, 55),
        StopBtn = Color3.fromRGB(255, 0, 85),
        SaveBtn = Color3.fromRGB(255, 215, 0),
        DeepAbyss = Color3.fromRGB(5, 0, 10),
        Text = Color3.fromRGB(255, 255, 255)
    },
    ["Red"] = {
        MainBG = Color3.fromRGB(20, 10, 10),
        TitleBar = Color3.fromRGB(220, 30, 60),
        Accent = Color3.fromRGB(0, 255, 170),
        ButtonActive = Color3.fromRGB(220, 30, 60),
        ButtonInactive = Color3.fromRGB(45, 20, 20),
        StopBtn = Color3.fromRGB(255, 70, 90),
        SaveBtn = Color3.fromRGB(255, 200, 50),
        DeepAbyss = Color3.fromRGB(12, 5, 5),
        Text = Color3.fromRGB(255, 240, 240)
    },
    ["Blue"] = {
        MainBG = Color3.fromRGB(10, 15, 28),
        TitleBar = Color3.fromRGB(30, 160, 255),
        Accent = Color3.fromRGB(100, 255, 220),
        ButtonActive = Color3.fromRGB(30, 160, 255),
        ButtonInactive = Color3.fromRGB(20, 30, 50),
        StopBtn = Color3.fromRGB(255, 90, 110),
        SaveBtn = Color3.fromRGB(120, 255, 200),
        DeepAbyss = Color3.fromRGB(5, 8, 20),
        Text = Color3.fromRGB(230, 245, 255)
    },
    ["Crimson"] = {
        MainBG = Color3.fromRGB(22, 8, 8),
        TitleBar = Color3.fromRGB(190, 20, 45),
        Accent = Color3.fromRGB(255, 110, 90),
        ButtonActive = Color3.fromRGB(190, 20, 45),
        ButtonInactive = Color3.fromRGB(50, 15, 15),
        StopBtn = Color3.fromRGB(255, 110, 120),
        SaveBtn = Color3.fromRGB(255, 180, 70),
        DeepAbyss = Color3.fromRGB(13, 4, 4),
        Text = Color3.fromRGB(255, 230, 230)
    },
    ["Cyan"] = {
        MainBG = Color3.fromRGB(8, 18, 28),
        TitleBar = Color3.fromRGB(70, 220, 255),
        Accent = Color3.fromRGB(130, 255, 240),
        ButtonActive = Color3.fromRGB(70, 220, 255),
        ButtonInactive = Color3.fromRGB(20, 35, 50),
        StopBtn = Color3.fromRGB(255, 95, 125),
        SaveBtn = Color3.fromRGB(170, 255, 230),
        DeepAbyss = Color3.fromRGB(4, 10, 18),
        Text = Color3.fromRGB(240, 250, 255)
    }
}

local CurrentThemeName = "Purple"
local THEME_SAVE_FILE = "EmoteScript_Theme.json"

local function loadTheme()
    local success, data = pcall(function()
        if isfile and isfile(THEME_SAVE_FILE) then
            return HttpService:JSONDecode(readfile(THEME_SAVE_FILE))
        end
        return nil
    end)
    if success and data and Themes[data] then
        CurrentThemeName = data
    end
end

local function saveTheme()
    pcall(function()
        if writefile then
            writefile(THEME_SAVE_FILE, HttpService:JSONEncode(CurrentThemeName))
        end
    end)
end

loadTheme()
local Palette = Themes[CurrentThemeName]

local Notifications = {}
local ScreenGuiNotif = Instance.new("ScreenGui", CoreGui)
ScreenGuiNotif.Name = "EmoteNotifs"
ScreenGuiNotif.DisplayOrder = 9999
ScreenGuiNotif.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGuiNotif.ResetOnSpawn = false
ScreenGuiNotif.IgnoreGuiInset = true
local activeNotifs = {}

function Notifications:Notify(text, color)
    local frame  = Instance.new("Frame")
    local label  = Instance.new("TextLabel")
    local accent = Instance.new("Frame")
    local corner = Instance.new("UICorner", frame)

    frame.Size = UDim2.new(0, 220, 0, 40)
    frame.Position = UDim2.new(1, 20, 0.9, -(#activeNotifs * 45))
    frame.BackgroundColor3 = Palette.DeepAbyss
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.ZIndex = 9999
    frame.Parent = ScreenGuiNotif
    corner.CornerRadius = UDim.new(0, 6)

    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
    accent.ZIndex = 9999
    accent.Parent = frame
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 6)

    label.Size = UDim2.new(1, -15, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text:upper()
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 9999
    label.Parent = frame

    table.insert(activeNotifs, frame)
    local targetY = 0.9 - ((#activeNotifs - 1) * 0.05)
    frame:TweenPosition(UDim2.new(1, -230, targetY, -50), "Out", "Back", 0.4, true)

    task.delay(2.5, function()
        frame:TweenPosition(UDim2.new(1, 20, targetY, -50), "In", "Sine", 0.4, true, function()
            for i, v in ipairs(activeNotifs) do
                if v == frame then table.remove(activeNotifs, i) break end
            end
            frame:Destroy()
        end)
    end)
end

local savedEmotes = {}
local SAVE_FILE = "EmoteScript_Saved.json"

local function loadSavedEmotes()
    local success, data = pcall(function()
        if readfile and isfile and isfile(SAVE_FILE) then
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end
        return {}
    end)
    if success and type(data) == "table" then
        savedEmotes = data
    else
        savedEmotes = {}
    end
end

local function saveEmotesToFile()
    pcall(function()
        if writefile then
            writefile(SAVE_FILE, HttpService:JSONEncode(savedEmotes))
        end
    end)
end

loadSavedEmotes()

local Settings = {}
Settings["Fade In"]    = 0.1
Settings["Fade Out"]   = 0.1
Settings["Weight"]     = 1
Settings["Speed"]      = 1
Settings["Looped"]     = true
Settings["Stop Other Animations On Play"] = true
Settings["Stop Emote When Moving"] = false

local CurrentTrack = nil
local lastPlayedId = nil
local lastPlayedName = nil

local function LoadTrack(id, name)
    lastPlayedId = id
    lastPlayedName = name or tostring(id)

    if CurrentTrack then
        CurrentTrack:Stop(Settings["Fade Out"])
    end

    local animId
    local ok, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)
    if ok and result and #result > 0 then
        local anim = result[1]
        if anim:IsA("Animation") then
            animId = anim.AnimationId
        else
            animId = "rbxassetid://" .. tostring(id)
        end
    else
        animId = "rbxassetid://" .. tostring(id)
    end

    local newAnim = Instance.new("Animation")
    newAnim.AnimationId = animId

    local newTrack = humanoid:LoadAnimation(newAnim)
    newTrack.Priority = Enum.AnimationPriority.Action4

    local weight = Settings["Weight"]
    if weight == 0 then weight = 0.001 end

    if Settings["Stop Other Animations On Play"] then
        for _, t in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
            if t.Priority ~= Enum.AnimationPriority.Action4 then
                t:Stop()
            end
        end
    end

    newTrack:Play(Settings["Fade In"], weight, Settings["Speed"])
    newTrack.Looped = Settings["Looped"]
    CurrentTrack = newTrack
    return newTrack
end

local function StopEmote()
    if CurrentTrack and CurrentTrack.IsPlaying then
        CurrentTrack:Stop(Settings["Fade Out"])
        CurrentTrack = nil
        lastPlayedId = nil
        lastPlayedName = nil
        Notifications:Notify("Emote Stopped", Palette.StopBtn)
    end
end

RunService.RenderStepped:Connect(function()
    if Settings["Stop Emote When Moving"] and CurrentTrack and CurrentTrack.IsPlaying then
        if character:FindFirstChild("HumanoidRootPart") then
            local root = character.HumanoidRootPart
            local moved = (root.Position - lastPosition).Magnitude > 0.1
            local jumped = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Jumping
            if moved or jumped then
                CurrentTrack:Stop(Settings["Fade Out"])
                CurrentTrack = nil
            end
            lastPosition = root.Position
        end
    end
end)

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()

    if lastPlayedId then
        task.wait(0.5)
        LoadTrack(lastPlayedId, lastPlayedName)
        Notifications:Notify("Emote Reapplied", Palette.Accent)
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "EmoteGUI"
gui.Parent = CoreGui
gui.Enabled = false
gui.DisplayOrder = 9999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 440, 0, 380)
main.Position = UDim2.new(0.5, -220, 0.5, -190)
main.BackgroundColor3 = Palette.MainBG
main.Active = true
main.Draggable = true
main.ZIndex = 9999
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Palette.TitleBar
titleBar.ZIndex = 9999
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "UGC Emote Player  •  Press . to toggle"
titleLabel.TextColor3 = Palette.Text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 9999
titleLabel.Parent = titleBar

local searchTabBtn = Instance.new("TextButton")
searchTabBtn.Size = UDim2.new(0.33, -6, 0, 28)
searchTabBtn.Position = UDim2.new(0, 4, 0, 42)
searchTabBtn.BackgroundColor3 = Palette.ButtonActive
searchTabBtn.Text = "Search"
searchTabBtn.Font = Enum.Font.GothamBold
searchTabBtn.TextSize = 12
searchTabBtn.TextColor3 = Palette.Text
searchTabBtn.ZIndex = 9999
searchTabBtn.Parent = main
Instance.new("UICorner", searchTabBtn).CornerRadius = UDim.new(0, 6)

local savedTabBtn = Instance.new("TextButton")
savedTabBtn.Size = UDim2.new(0.33, -6, 0, 28)
savedTabBtn.Position = UDim2.new(0.33, 2, 0, 42)
savedTabBtn.BackgroundColor3 = Palette.ButtonInactive
savedTabBtn.Text = "Saved"
savedTabBtn.Font = Enum.Font.GothamBold
savedTabBtn.TextSize = 12
savedTabBtn.TextColor3 = Palette.Text
savedTabBtn.ZIndex = 9999
savedTabBtn.Parent = main
Instance.new("UICorner", savedTabBtn).CornerRadius = UDim.new(0, 6)

local themesTabBtn = Instance.new("TextButton")
themesTabBtn.Size = UDim2.new(0.33, -6, 0, 28)
themesTabBtn.Position = UDim2.new(0.66, 4, 0, 42)
themesTabBtn.BackgroundColor3 = Palette.ButtonInactive
themesTabBtn.Text = "Themes"
themesTabBtn.Font = Enum.Font.GothamBold
themesTabBtn.TextSize = 12
themesTabBtn.TextColor3 = Palette.Text
themesTabBtn.ZIndex = 9999
themesTabBtn.Parent = main
Instance.new("UICorner", themesTabBtn).CornerRadius = UDim.new(0, 6)

local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, -20, 1, -80)
searchFrame.Position = UDim2.new(0, 10, 0, 76)
searchFrame.BackgroundTransparency = 1
searchFrame.Visible = true
searchFrame.ZIndex = 9999
searchFrame.Parent = main

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -80, 0, 30)
searchBox.Position = UDim2.new(0, 0, 0, 0)
searchBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.PlaceholderText = "Search UGC emotes..."
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.ClearTextOnFocus = false
searchBox.Text = ""
searchBox.ZIndex = 9999
searchBox.Parent = searchFrame
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)

local searchBtn = Instance.new("TextButton")
searchBtn.Size = UDim2.new(0, 70, 0, 30)
searchBtn.Position = UDim2.new(1, -70, 0, 0)
searchBtn.BackgroundColor3 = Palette.ButtonActive
searchBtn.Text = "Search"
searchBtn.Font = Enum.Font.GothamBold
searchBtn.TextSize = 12
searchBtn.TextColor3 = Color3.new(1, 1, 1)
searchBtn.ZIndex = 9999
searchBtn.Parent = searchFrame
Instance.new("UICorner", searchBtn).CornerRadius = UDim.new(0, 6)

local idBox = Instance.new("TextBox")
idBox.Size = UDim2.new(1, -80, 0, 30)
idBox.Position = UDim2.new(0, 0, 0, 38)
idBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
idBox.TextColor3 = Color3.new(1, 1, 1)
idBox.PlaceholderText = "Or paste Animation ID..."
idBox.Font = Enum.Font.Gotham
idBox.TextSize = 12
idBox.ClearTextOnFocus = false
idBox.Text = ""
idBox.ZIndex = 9999
idBox.Parent = searchFrame
Instance.new("UICorner", idBox).CornerRadius = UDim.new(0, 6)

local playIdBtn = Instance.new("TextButton")
playIdBtn.Size = UDim2.new(0, 70, 0, 30)
playIdBtn.Position = UDim2.new(1, -70, 0, 38)
playIdBtn.BackgroundColor3 = Palette.Accent
playIdBtn.Text = "Play"
playIdBtn.Font = Enum.Font.GothamBold
playIdBtn.TextSize = 12
playIdBtn.TextColor3 = Color3.new(1, 1, 1)
playIdBtn.ZIndex = 9999
playIdBtn.Parent = searchFrame
Instance.new("UICorner", playIdBtn).CornerRadius = UDim.new(0, 6)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, 0, 0, 26)
stopBtn.Position = UDim2.new(0, 0, 0, 76)
stopBtn.BackgroundColor3 = Palette.StopBtn
stopBtn.Text = "Stop Emote"
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 12
stopBtn.TextColor3 = Color3.new(1, 1, 1)
stopBtn.ZIndex = 9999
stopBtn.Parent = searchFrame
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -110)
scroll.Position = UDim2.new(0, 0, 0, 110)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4
scroll.ZIndex = 9999
scroll.Parent = searchFrame

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

local savedFrame = Instance.new("Frame")
savedFrame.Size = UDim2.new(1, -20, 1, -80)
savedFrame.Position = UDim2.new(0, 10, 0, 76)
savedFrame.BackgroundTransparency = 1
savedFrame.Visible = false
savedFrame.ZIndex = 9999
savedFrame.Parent = main

local savedScroll = Instance.new("ScrollingFrame")
savedScroll.Size = UDim2.new(1, 0, 1, 0)
savedScroll.BackgroundTransparency = 1
savedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
savedScroll.ScrollBarThickness = 4
savedScroll.ZIndex = 9999
savedScroll.Parent = savedFrame

local savedList = Instance.new("UIListLayout", savedScroll)
savedList.Padding = UDim.new(0, 6)
savedList.SortOrder = Enum.SortOrder.LayoutOrder
savedList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    savedScroll.CanvasSize = UDim2.new(0, 0, 0, savedList.AbsoluteContentSize.Y + 8)
end)

local themesFrame = Instance.new("Frame")
themesFrame.Size = UDim2.new(1, -20, 1, -80)
themesFrame.Position = UDim2.new(0, 10, 0, 76)
themesFrame.BackgroundTransparency = 1
themesFrame.Visible = false
themesFrame.ZIndex = 9999
themesFrame.Parent = main

local themesScroll = Instance.new("ScrollingFrame")
themesScroll.Size = UDim2.new(1, 0, 1, 0)
themesScroll.BackgroundTransparency = 1
themesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
themesScroll.ScrollBarThickness = 4
themesScroll.Parent = themesFrame

local themesLayout = Instance.new("UIListLayout", themesScroll)
themesLayout.Padding = UDim.new(0, 8)
themesLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createResultCard(item)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 44)
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    card.ZIndex = 9999
    card.Parent = scroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -150, 1, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.Name or "Unknown"
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 12
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 9999
    nameLabel.Parent = card

    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0, 54, 0, 28)
    playBtn.Position = UDim2.new(1, -140, 0.5, -14)
    playBtn.BackgroundColor3 = Palette.Accent
    playBtn.Text = "Play"
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 11
    playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.ZIndex = 9999
    playBtn.Parent = card
    Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 6)

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0, 54, 0, 28)
    saveBtn.Position = UDim2.new(1, -78, 0.5, -14)
    saveBtn.BackgroundColor3 = Palette.SaveBtn
    saveBtn.Text = "Save"
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 11
    saveBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
    saveBtn.ZIndex = 9999
    saveBtn.Parent = card
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

    playBtn.MouseButton1Click:Connect(function()
        local id = item.AssetId or item.Id
        LoadTrack(id, item.Name)
        Notifications:Notify("Playing: " .. (item.Name or "Emote"), Palette.Accent)
    end)

    saveBtn.MouseButton1Click:Connect(function()
        local alreadySaved = false
        for _, saved in ipairs(savedEmotes) do
            if saved.Id == item.Id then alreadySaved = true break end
        end
        if not alreadySaved then
            table.insert(savedEmotes, { Id = item.AssetId or item.Id, Name = item.Name or "Unknown" })
            saveEmotesToFile()
            saveBtn.Text = "Saved!"
            saveBtn.BackgroundColor3 = Palette.Accent
            task.wait(1)
            saveBtn.Text = "Save"
            saveBtn.BackgroundColor3 = Palette.SaveBtn
            Notifications:Notify("Saved: " .. (item.Name or "Emote"), Palette.SaveBtn)
        else
            saveBtn.Text = "Already!"
            task.wait(0.7)
            saveBtn.Text = "Save"
            Notifications:Notify("Already Saved", Palette.StopBtn)
        end
    end)

    return card
end

local function refreshSaved()
    for _, child in ipairs(savedScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if #savedEmotes == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 40)
        empty.BackgroundTransparency = 1
        empty.Text = "No saved emotes yet"
        empty.TextColor3 = Color3.fromRGB(150, 150, 150)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.ZIndex = 9999
        empty.Parent = savedScroll
        return
    end

    for i, item in ipairs(savedEmotes) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 44)
        card.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        card.ZIndex = 9999
        card.Parent = savedScroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -150, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.Name or "Unknown"
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.ZIndex = 9999
        nameLabel.Parent = card

        local playBtn = Instance.new("TextButton")
        playBtn.Size = UDim2.new(0, 54, 0, 28)
        playBtn.Position = UDim2.new(1, -140, 0.5, -14)
        playBtn.BackgroundColor3 = Palette.Accent
        playBtn.Text = "Play"
        playBtn.Font = Enum.Font.GothamBold
        playBtn.TextSize = 11
        playBtn.TextColor3 = Color3.new(1, 1, 1)
        playBtn.ZIndex = 9999
        playBtn.Parent = card
        Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 6)

        local removeBtn = Instance.new("TextButton")
        removeBtn.Size = UDim2.new(0, 70, 0, 28)
        removeBtn.Position = UDim2.new(1, -78, 0.5, -14)
        removeBtn.BackgroundColor3 = Palette.StopBtn
        removeBtn.Text = "Remove"
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.TextSize = 11
        removeBtn.TextColor3 = Color3.new(1, 1, 1)
        removeBtn.ZIndex = 9999
        removeBtn.Parent = card
        Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 6)

        local capturedItem = item
        local capturedIndex = i
        playBtn.MouseButton1Click:Connect(function()
            LoadTrack(capturedItem.Id, capturedItem.Name)
            Notifications:Notify("Playing: " .. (capturedItem.Name or "Emote"), Palette.Accent)
        end)

        removeBtn.MouseButton1Click:Connect(function()
            table.remove(savedEmotes, capturedIndex)
            saveEmotesToFile()
            refreshSaved()
            Notifications:Notify("Removed: " .. (capturedItem.Name or "Emote"), Palette.StopBtn)
        end)
    end
end

local function doSearch(keyword)
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    Notifications:Notify("Searching...", Palette.SaveBtn)
    local params = CatalogSearchParams.new()
    params.SearchKeyword = keyword or ""
    params.AssetTypes = { Enum.AvatarAssetType.EmoteAnimation }
    params.IncludeOffSale = true
    params.SortType = Enum.CatalogSortType.Relevance
    local ok, pages = pcall(function() return AvatarEditorService:SearchCatalog(params) end)
    if not ok or not pages then Notifications:Notify("Search Failed", Palette.StopBtn) return end
    local ok2, results = pcall(function() return pages:GetCurrentPage() end)
    if not ok2 or not results or #results == 0 then Notifications:Notify("No Results Found", Palette.StopBtn) return end
    for _, item in ipairs(results) do createResultCard(item) end
    Notifications:Notify("Found " .. #results .. " emotes", Palette.ButtonActive)
end

local function applyTheme(themeName)
    if not Themes[themeName] then return end
    CurrentThemeName = themeName
    Palette = Themes[themeName]
    saveTheme()

    main.BackgroundColor3 = Palette.MainBG
    titleBar.BackgroundColor3 = Palette.TitleBar
    searchTabBtn.BackgroundColor3 = searchFrame.Visible and Palette.ButtonActive or Palette.ButtonInactive
    savedTabBtn.BackgroundColor3 = savedFrame.Visible and Palette.ButtonActive or Palette.ButtonInactive
    themesTabBtn.BackgroundColor3 = themesFrame.Visible and Palette.ButtonActive or Palette.ButtonInactive

    Notifications:Notify("Theme changed to " .. themeName, Palette.Accent)
end

local function refreshThemes()
    for _, child in ipairs(themesScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for name, _ in pairs(Themes) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -8, 0, 50)
        card.BackgroundColor3 = Palette.MainBG
        card.ZIndex = 9999
        card.Parent = themesScroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -120, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Palette.Text
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        local selectBtn = Instance.new("TextButton")
        selectBtn.Size = UDim2.new(0, 100, 0, 32)
        selectBtn.Position = UDim2.new(1, -110, 0.5, -16)
        selectBtn.BackgroundColor3 = (name == CurrentThemeName) and Palette.Accent or Palette.ButtonActive
        selectBtn.Text = (name == CurrentThemeName) and "Active" or "Select"
        selectBtn.TextColor3 = Color3.new(1,1,1)
        selectBtn.Font = Enum.Font.GothamBold
        selectBtn.TextSize = 12
        selectBtn.Parent = card
        Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)

        selectBtn.MouseButton1Click:Connect(function()
            applyTheme(name)
            refreshThemes()
        end)
    end
    themesScroll.CanvasSize = UDim2.new(0, 0, 0, themesLayout.AbsoluteContentSize.Y + 20)
end

-- Connections
searchBtn.MouseButton1Click:Connect(function() doSearch(searchBox.Text) end)
searchBox.FocusLost:Connect(function(enterPressed) if enterPressed then doSearch(searchBox.Text) end end)

playIdBtn.MouseButton1Click:Connect(function()
    local id = tonumber(idBox.Text)
    if id then
        LoadTrack(id, "ID: " .. tostring(id))
        Notifications:Notify("Playing ID: " .. tostring(id), Palette.Accent)
    else
        Notifications:Notify("Invalid ID", Palette.StopBtn)
    end
end)

stopBtn.MouseButton1Click:Connect(function() StopEmote() end)

searchTabBtn.MouseButton1Click:Connect(function()
    searchFrame.Visible = true
    savedFrame.Visible = false
    themesFrame.Visible = false
    searchTabBtn.BackgroundColor3 = Palette.ButtonActive
    savedTabBtn.BackgroundColor3 = Palette.ButtonInactive
    themesTabBtn.BackgroundColor3 = Palette.ButtonInactive
end)

savedTabBtn.MouseButton1Click:Connect(function()
    searchFrame.Visible = false
    savedFrame.Visible = true
    themesFrame.Visible = false
    searchTabBtn.BackgroundColor3 = Palette.ButtonInactive
    savedTabBtn.BackgroundColor3 = Palette.ButtonActive
    themesTabBtn.BackgroundColor3 = Palette.ButtonInactive
    refreshSaved()
end)

themesTabBtn.MouseButton1Click:Connect(function()
    searchFrame.Visible = false
    savedFrame.Visible = false
    themesFrame.Visible = true
    searchTabBtn.BackgroundColor3 = Palette.ButtonInactive
    savedTabBtn.BackgroundColor3 = Palette.ButtonInactive
    themesTabBtn.BackgroundColor3 = Palette.ButtonActive
    refreshThemes()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        gui.Enabled = not gui.Enabled
        Notifications:Notify("Emote Menu: " .. (gui.Enabled and "Open" or "Closed"), Palette.Accent)
    end
end)

Notifications:Notify("Emote Script Loaded  •  Press . to open", Palette.Accent)
task.wait(0.6)
Notifications:Notify("Made by tdx | Credits to tdx", Palette.TitleBar)
