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

local pal = {
    bg = Color3.fromRGB(12, 12, 18),
    title = Color3.fromRGB(160, 32, 240),
    accent = Color3.fromRGB(46, 204, 113),
    btn = Color3.fromRGB(35, 35, 48),
    btnActive = Color3.fromRGB(160, 32, 240),
    stop = Color3.fromRGB(255, 0, 85),
    save = Color3.fromRGB(255, 215, 0),
    card = Color3.fromRGB(22, 22, 32),
    text = Color3.fromRGB(255, 255, 255),
    sub = Color3.fromRGB(160, 160, 180),
}

local savedEmotes = {}
local SAVE_FILE = "EmoteScript_Saved.json"

local function loadSaved()
    local ok, data = pcall(function()
        if isfile and isfile(SAVE_FILE) then
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end
        return {}
    end)
    savedEmotes = (ok and type(data) == "table") and data or {}
end

local function saveToDisk()
    pcall(function()
        if writefile then writefile(SAVE_FILE, HttpService:JSONEncode(savedEmotes)) end
    end)
end

loadSaved()

local Settings = {
    FadeIn = 0.1, FadeOut = 0.1,
    Weight = 1, Speed = 1,
    Looped = true,
    StopOthers = true,
    StopOnMove = false,
}

local CurrentTrack = nil
local lastId = nil
local lastName = nil
local activeCard = nil -- tracks which card is currently playing

-- notifs
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "EmoteNotifs"
notifGui.Parent = CoreGui
notifGui.DisplayOrder = 9999
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
notifGui.ResetOnSpawn = false
notifGui.IgnoreGuiInset = true
local activeNotifs = {}

local function notify(txt, color)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 230, 0, 40)
    f.Position = UDim2.new(1, 20, 0.88, -(#activeNotifs * 46))
    f.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel = 0
    f.ZIndex = 9999
    f.Parent = notifGui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = color or pal.accent
    stroke.Thickness = 1.2
    stroke.Transparency = 0.3
    stroke.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = color or pal.accent
    bar.BorderSizePixel = 0
    bar.Parent = f
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = txt
    label.TextColor3 = pal.text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 9999
    label.Parent = f

    table.insert(activeNotifs, f)
    local ty = 0.88 - ((#activeNotifs - 1) * 0.055)
    f:TweenPosition(UDim2.new(1, -242, ty, 0), "Out", "Back", 0.35, true)

    task.delay(2.5, function()
        f:TweenPosition(UDim2.new(1, 20, ty, 0), "In", "Sine", 0.3, true, function()
            for i, v in ipairs(activeNotifs) do
                if v == f then table.remove(activeNotifs, i) break end
            end
            f:Destroy()
        end)
    end)
end

local function resetCardButtons(card)
    if not card then return end
    local playBtn = card:FindFirstChild("PlayBtn")
    local stopBtn = card:FindFirstChild("StopBtn")
    if playBtn then
        playBtn.BackgroundColor3 = pal.accent
        playBtn.Text = "Play"
        playBtn.Visible = true
    end
    if stopBtn then stopBtn.Visible = false end
end

local function StopEmote()
    if CurrentTrack and CurrentTrack.IsPlaying then
        CurrentTrack:Stop(Settings.FadeOut)
        CurrentTrack = nil
        lastId = nil lastName = nil
        notify("emote stopped", pal.stop)
    end
    resetCardButtons(activeCard)
    activeCard = nil
end

local function LoadTrack(id, name, card)
    lastId = id
    lastName = name or tostring(id)

    if CurrentTrack then CurrentTrack:Stop(Settings.FadeOut) end
    resetCardButtons(activeCard)

    local animId
    local ok, result = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(id)) end)
    if ok and result and #result > 0 and result[1]:IsA("Animation") then
        animId = result[1].AnimationId
    else
        animId = "rbxassetid://" .. tostring(id)
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animId

    local track = humanoid:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4

    if Settings.StopOthers then
        for _, t in humanoid.Animator:GetPlayingAnimationTracks() do
            if t.Priority ~= Enum.AnimationPriority.Action4 then t:Stop() end
        end
    end

    local w = Settings.Weight == 0 and 0.001 or Settings.Weight
    track:Play(Settings.FadeIn, w, Settings.Speed)
    track.Looped = Settings.Looped
    CurrentTrack = track
    activeCard = card

    -- update card buttons to show stop
    if card then
        local playBtn = card:FindFirstChild("PlayBtn")
        local stopBtn = card:FindFirstChild("StopBtn")
        if playBtn then playBtn.Visible = false end
        if stopBtn then stopBtn.Visible = true end
    end
end

RunService.RenderStepped:Connect(function()
    if Settings.StopOnMove and CurrentTrack and CurrentTrack.IsPlaying then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            local moved = (root.Position - lastPosition).Magnitude > 0.1
            local jumped = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Jumping
            if moved or jumped then
                CurrentTrack:Stop(Settings.FadeOut)
                CurrentTrack = nil
                resetCardButtons(activeCard)
                activeCard = nil
            end
            lastPosition = root.Position
        end
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()
    if lastId then
        task.wait(0.5)
        LoadTrack(lastId, lastName, nil)
        notify("emote reapplied", pal.accent)
    end
end)

-- gui
local gui = Instance.new("ScreenGui")
gui.Name = "EmoteGUI"
gui.Parent = CoreGui
gui.Enabled = false
gui.DisplayOrder = 9999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 420, 0, 400)
main.Position = UDim2.new(0.5, -210, 0.5, -200)
main.BackgroundColor3 = pal.bg
main.Active = true
main.Draggable = true
main.ZIndex = 9999
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = pal.title
stroke.Thickness = 1.5
stroke.Transparency = 0.5
stroke.Parent = main

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = pal.title
titleBar.ZIndex = 9999
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = pal.title
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 9998
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "emote player  •  g to toggle"
titleLabel.TextColor3 = pal.text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 9999
titleLabel.Parent = titleBar

-- tabs
local function makeTab(text, xScale, xOffset)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -8, 0, 28)
    btn.Position = UDim2.new(xScale, xOffset, 0, 44)
    btn.BackgroundColor3 = pal.btn
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = pal.text
    btn.ZIndex = 9999
    btn.Parent = main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local searchTab = makeTab("search", 0, 4)
local savedTab = makeTab("saved", 0.5, 4)
searchTab.BackgroundColor3 = pal.btnActive

-- search frame
local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, -16, 1, -82)
searchFrame.Position = UDim2.new(0, 8, 0, 78)
searchFrame.BackgroundTransparency = 1
searchFrame.Visible = true
searchFrame.ZIndex = 9999
searchFrame.Parent = main

local function makeInput(placeholder, yPos)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -78, 0, 30)
    box.Position = UDim2.new(0, 0, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    box.TextColor3 = pal.text
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = pal.sub
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Text = ""
    box.ZIndex = 9999
    box.Parent = searchFrame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke")
    s.Color = pal.btn
    s.Thickness = 1
    s.Parent = box
    return box
end

local function makeSmallBtn(text, color, xOff, yPos, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 68, 0, 30)
    btn.Position = UDim2.new(1, xOff, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = pal.text
    btn.ZIndex = 9999
    btn.Parent = parent or searchFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local searchBox = makeInput("search ugc emotes...", 0)
local searchBtn = makeSmallBtn("search", pal.btnActive, -68, 0)
local idBox = makeInput("paste animation id...", 38)
local playIdBtn = makeSmallBtn("play", pal.accent, -68, 38)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -76)
scroll.Position = UDim2.new(0, 0, 0, 76)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = pal.title
scroll.ZIndex = 9999
scroll.Parent = searchFrame

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

-- saved frame
local savedFrame = Instance.new("Frame")
savedFrame.Size = UDim2.new(1, -16, 1, -82)
savedFrame.Position = UDim2.new(0, 8, 0, 78)
savedFrame.BackgroundTransparency = 1
savedFrame.Visible = false
savedFrame.ZIndex = 9999
savedFrame.Parent = main

local savedScroll = Instance.new("ScrollingFrame")
savedScroll.Size = UDim2.new(1, 0, 1, 0)
savedScroll.BackgroundTransparency = 1
savedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
savedScroll.ScrollBarThickness = 3
savedScroll.ScrollBarImageColor3 = pal.title
savedScroll.ZIndex = 9999
savedScroll.Parent = savedFrame

local savedList = Instance.new("UIListLayout", savedScroll)
savedList.Padding = UDim.new(0, 5)
savedList.SortOrder = Enum.SortOrder.LayoutOrder
savedList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    savedScroll.CanvasSize = UDim2.new(0, 0, 0, savedList.AbsoluteContentSize.Y + 8)
end)

-- card maker
local function makeCard(parent, item, isSaved, index)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 44)
    card.BackgroundColor3 = pal.card
    card.ZIndex = 9999
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local cs = Instance.new("UIStroke")
    cs.Color = pal.btn
    cs.Thickness = 1
    cs.Transparency = 0.5
    cs.Parent = card

    local nameL = Instance.new("TextLabel")
    nameL.Size = UDim2.new(1, -200, 1, 0)
    nameL.Position = UDim2.new(0, 10, 0, 0)
    nameL.BackgroundTransparency = 1
    nameL.Text = item.Name or "unknown"
    nameL.Font = Enum.Font.GothamBold
    nameL.TextSize = 12
    nameL.TextColor3 = pal.text
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.TextTruncate = Enum.TextTruncate.AtEnd
    nameL.ZIndex = 9999
    nameL.Parent = card

    -- play button
    local playBtn = Instance.new("TextButton")
    playBtn.Name = "PlayBtn"
    playBtn.Size = UDim2.new(0, 52, 0, 28)
    playBtn.Position = UDim2.new(1, -190, 0.5, -14)
    playBtn.BackgroundColor3 = pal.accent
    playBtn.Text = "play"
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 11
    playBtn.TextColor3 = pal.text
    playBtn.ZIndex = 9999
    playBtn.Parent = card
    Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 6)

    -- inline stop button (hidden by default)
    local inlineStop = Instance.new("TextButton")
    inlineStop.Name = "StopBtn"
    inlineStop.Size = UDim2.new(0, 52, 0, 28)
    inlineStop.Position = UDim2.new(1, -190, 0.5, -14)
    inlineStop.BackgroundColor3 = pal.stop
    inlineStop.Text = "stop"
    inlineStop.Font = Enum.Font.GothamBold
    inlineStop.TextSize = 11
    inlineStop.TextColor3 = pal.text
    inlineStop.Visible = false
    inlineStop.ZIndex = 9999
    inlineStop.Parent = card
    Instance.new("UICorner", inlineStop).CornerRadius = UDim.new(0, 6)

    -- save or remove button
    local actionBtn = Instance.new("TextButton")
    actionBtn.Size = UDim2.new(0, 62, 0, 28)
    actionBtn.Position = UDim2.new(1, -130, 0.5, -14)
    actionBtn.BackgroundColor3 = isSaved and pal.stop or pal.save
    actionBtn.Text = isSaved and "remove" or "save"
    actionBtn.Font = Enum.Font.GothamBold
    actionBtn.TextSize = 11
    actionBtn.TextColor3 = isSaved and pal.text or Color3.fromRGB(15, 15, 20)
    actionBtn.ZIndex = 9999
    actionBtn.Parent = card
    Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 6)

    local id = item.AssetId or item.Id

    playBtn.MouseButton1Click:Connect(function()
        LoadTrack(id, item.Name, card)
        notify("playing: " .. (item.Name or "emote"), pal.accent)
    end)

    inlineStop.MouseButton1Click:Connect(function()
        StopEmote()
    end)

    if isSaved then
        actionBtn.MouseButton1Click:Connect(function()
            table.remove(savedEmotes, index)
            saveToDisk()
            card:Destroy()
            notify("removed: " .. (item.Name or "emote"), pal.stop)
        end)
    else
        actionBtn.MouseButton1Click:Connect(function()
            local already = false
            for _, s in savedEmotes do if s.Id == id then already = true break end end
            if not already then
                table.insert(savedEmotes, {Id = id, Name = item.Name or "unknown"})
                saveToDisk()
                actionBtn.Text = "saved!"
                task.wait(1)
                actionBtn.Text = "save"
                notify("saved: " .. (item.Name or "emote"), pal.save)
            else
                actionBtn.Text = "already!"
                task.wait(0.7)
                actionBtn.Text = "save"
                notify("already saved", pal.stop)
            end
        end)
    end

    return card
end

local function refreshSaved()
    for _, c in savedScroll:GetChildren() do
        if c:IsA("Frame") then c:Destroy() end
    end
    if #savedEmotes == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 40)
        empty.BackgroundTransparency = 1
        empty.Text = "no saved emotes yet"
        empty.TextColor3 = pal.sub
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.ZIndex = 9999
        empty.Parent = savedScroll
        return
    end
    for i, item in ipairs(savedEmotes) do
        makeCard(savedScroll, item, true, i)
    end
end

local function doSearch(keyword)
    for _, c in scroll:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
    notify("searching...", pal.save)
    local params = CatalogSearchParams.new()
    params.SearchKeyword = keyword or ""
    params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
    params.IncludeOffSale = true
    params.SortType = Enum.CatalogSortType.Relevance
    local ok, pages = pcall(function() return AvatarEditorService:SearchCatalog(params) end)
    if not ok or not pages then notify("search failed", pal.stop) return end
    local ok2, results = pcall(function() return pages:GetCurrentPage() end)
    if not ok2 or not results or #results == 0 then notify("no results", pal.stop) return end
    for _, item in results do makeCard(scroll, item, false, nil) end
    notify("found " .. #results .. " emotes", pal.btnActive)
end

-- connections
searchBtn.MouseButton1Click:Connect(function() doSearch(searchBox.Text) end)
searchBox.FocusLost:Connect(function(enter) if enter then doSearch(searchBox.Text) end end)

playIdBtn.MouseButton1Click:Connect(function()
    local id = tonumber(idBox.Text)
    if id then
        LoadTrack(id, "id: " .. tostring(id), nil)
        notify("playing id: " .. tostring(id), pal.accent)
    else
        notify("invalid id", pal.stop)
    end
end)

searchTab.MouseButton1Click:Connect(function()
    searchFrame.Visible = true
    savedFrame.Visible = false
    searchTab.BackgroundColor3 = pal.btnActive
    savedTab.BackgroundColor3 = pal.btn
end)

savedTab.MouseButton1Click:Connect(function()
    searchFrame.Visible = false
    savedFrame.Visible = true
    searchTab.BackgroundColor3 = pal.btn
    savedTab.BackgroundColor3 = pal.btnActive
    refreshSaved()
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.G then
        gui.Enabled = not gui.Enabled
        notify("emote menu " .. (gui.Enabled and "open" or "closed"), pal.accent)
    end
end)

notify("emote script loaded  •  g to open", pal.accent)
