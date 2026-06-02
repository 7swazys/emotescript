local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()

local cfg = {
    transparent = true, looped = true, stopothers = true,
    fadein = 0.1, fadeout = 0.1, weight = 1, speed = 1,
    openkey = "G"
}
local CFG_FILE = "EmoteScript_Config.json"

local function loadCfg()
    local ok, data = pcall(function()
        if isfile and isfile(CFG_FILE) then return HttpService:JSONDecode(readfile(CFG_FILE)) end
        return {}
    end)
    if ok and type(data) == "table" then
        for k, v in data do cfg[k] = v end
    end
end

local function saveCfg()
    pcall(function() if writefile then writefile(CFG_FILE, HttpService:JSONEncode(cfg)) end end)
end

loadCfg()

local pal = {
    bg = Color3.fromRGB(8, 8, 10),
    bgTrans = 0.25,
    panel = Color3.fromRGB(14, 14, 18),
    panelTrans = 0.3,
    card = Color3.fromRGB(20, 20, 26),
    cardTrans = 0.2,
    border = Color3.fromRGB(55, 55, 65),
    borderBright = Color3.fromRGB(90, 90, 105),
    accent = Color3.fromRGB(200, 200, 210),
    accentDim = Color3.fromRGB(120, 120, 135),
    text = Color3.fromRGB(240, 240, 245),
    sub = Color3.fromRGB(130, 130, 145),
    stop = Color3.fromRGB(200, 60, 60),
    save = Color3.fromRGB(180, 180, 190),
    btnActive = Color3.fromRGB(50, 50, 62),
    btnHover = Color3.fromRGB(35, 35, 45),
    gradient1 = Color3.fromRGB(30, 30, 38),
    gradient2 = Color3.fromRGB(12, 12, 16),
}

local function getTrans(base)
    return cfg.transparent and base or 0
end

local savedEmotes = {}
local SAVE_FILE = "EmoteScript_Saved.json"

local function loadSaved()
    local ok, data = pcall(function()
        if isfile and isfile(SAVE_FILE) then return HttpService:JSONDecode(readfile(SAVE_FILE)) end
        return {}
    end)
    savedEmotes = (ok and type(data) == "table") and data or {}
end

local function saveToDisk()
    pcall(function() if writefile then writefile(SAVE_FILE, HttpService:JSONEncode(savedEmotes)) end end)
end

loadSaved()

local Settings = {
    FadeIn = cfg.fadein,
    FadeOut = cfg.fadeout,
    Weight = cfg.weight,
    Speed = cfg.speed,
    Looped = cfg.looped,
    StopOthers = cfg.stopothers,
}

local CurrentTrack = nil
local lastId = nil
local lastName = nil
local activeCard = nil
local openKey = Enum.KeyCode[cfg.openkey] or Enum.KeyCode.G
local bindingKey = false

local notifGui = Instance.new("ScreenGui")
notifGui.Name = "EmoteNotifs"
notifGui.Parent = CoreGui
notifGui.DisplayOrder = 9999
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
notifGui.ResetOnSpawn = false
notifGui.IgnoreGuiInset = true
local activeNotifs = {}

local function notify(txt, color)
    color = color or pal.accent
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 240, 0, 38)
    f.Position = UDim2.new(1, 20, 0.88, -(#activeNotifs * 44))
    f.BackgroundColor3 = pal.bg
    f.BackgroundTransparency = getTrans(0.15)
    f.BorderSizePixel = 0
    f.ZIndex = 9999
    f.Parent = notifGui

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color),
        ColorSequenceKeypoint.new(0.015, color),
        ColorSequenceKeypoint.new(0.016, pal.panel),
        ColorSequenceKeypoint.new(1, pal.panel),
    })
    grad.Parent = f

    local stroke = Instance.new("UIStroke")
    stroke.Color = pal.border stroke.Thickness = 1 stroke.Transparency = 0.5 stroke.Parent = f

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = txt
    label.TextColor3 = pal.text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 9999
    label.Parent = f

    table.insert(activeNotifs, f)
    local ty = 0.88 - ((#activeNotifs - 1) * 0.052)
    f:TweenPosition(UDim2.new(1, -252, ty, 0), "Out", "Quint", 0.3, true)
    task.delay(2.5, function()
        f:TweenPosition(UDim2.new(1, 20, ty, 0), "In", "Quint", 0.25, true, function()
            for i, v in ipairs(activeNotifs) do if v == f then table.remove(activeNotifs, i) break end end
            f:Destroy()
        end)
    end)
end

local function resetCardButtons(card)
    if not card then return end
    local pb = card:FindFirstChild("PlayBtn")
    local sb = card:FindFirstChild("StopBtn")
    if pb then pb.Visible = true end
    if sb then sb.Visible = false end
end

local function StopEmote()
    if CurrentTrack and CurrentTrack.IsPlaying then
        CurrentTrack:Stop(Settings.FadeOut)
        CurrentTrack = nil lastId = nil lastName = nil
        notify("stopped", pal.stop)
    end
    resetCardButtons(activeCard)
    activeCard = nil
end

local function LoadTrack(id, name, card)
    lastId = id lastName = name or tostring(id)
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
        for _, t in animator:GetPlayingAnimationTracks() do
            if t.Priority ~= Enum.AnimationPriority.Action4 then t:Stop() end
        end
    end
    local w = Settings.Weight == 0 and 0.001 or Settings.Weight
    track:Play(Settings.FadeIn, w, Settings.Speed)
    track.Looped = Settings.Looped
    CurrentTrack = track
    activeCard = card
    if card then
        local pb = card:FindFirstChild("PlayBtn")
        local sb = card:FindFirstChild("StopBtn")
        if pb then pb.Visible = false end
        if sb then sb.Visible = true end
    end
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    animator = humanoid:WaitForChild("Animator")
    lastPosition = character.PrimaryPart and character.PrimaryPart.Position or Vector3.new()
    if lastId then
        task.wait(0.5)
        LoadTrack(lastId, lastName, nil)
        notify("emote reapplied", pal.accent)
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
main.Size = UDim2.new(0, 460, 0, 440)
main.Position = UDim2.new(0.5, -230, 0.5, -220)
main.BackgroundColor3 = pal.bg
main.BackgroundTransparency = getTrans(pal.bgTrans)
main.Active = true
main.Draggable = true
main.ZIndex = 9999
main.Parent = gui

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = pal.border mainStroke.Thickness = 1 mainStroke.Parent = main

local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, pal.gradient1),
    ColorSequenceKeypoint.new(1, pal.gradient2),
})
mainGrad.Rotation = 135
mainGrad.Parent = main

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = pal.panel
titleBar.BackgroundTransparency = getTrans(pal.panelTrans)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 9999
titleBar.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, pal.borderBright),
    ColorSequenceKeypoint.new(0.4, pal.panel),
    ColorSequenceKeypoint.new(1, pal.gradient2),
})
titleGrad.Rotation = 90
titleGrad.Parent = titleBar

local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(0, 2, 1, 0)
accentLine.BackgroundColor3 = pal.borderBright
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 9999
accentLine.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "EMOTE PLAYER"
titleLabel.TextColor3 = pal.text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.LetterSpacing = 3
titleLabel.ZIndex = 9999
titleLabel.Parent = titleBar

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(0, 120, 1, 0)
subtitleLabel.Position = UDim2.new(1, -124, 0, 0)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = cfg.openkey .. " TO TOGGLE"
subtitleLabel.TextColor3 = pal.sub
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextSize = 10
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Right
subtitleLabel.LetterSpacing = 2
subtitleLabel.ZIndex = 9999
subtitleLabel.Parent = titleBar

local titleBottomLine = Instance.new("Frame")
titleBottomLine.Size = UDim2.new(1, 0, 0, 1)
titleBottomLine.Position = UDim2.new(0, 0, 1, -1)
titleBottomLine.BackgroundColor3 = pal.border
titleBottomLine.BorderSizePixel = 0
titleBottomLine.ZIndex = 9999
titleBottomLine.Parent = titleBar

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 32)
tabBar.Position = UDim2.new(0, 0, 0, 36)
tabBar.BackgroundColor3 = pal.panel
tabBar.BackgroundTransparency = getTrans(0.5)
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 9999
tabBar.Parent = main

local tabBottomLine = Instance.new("Frame")
tabBottomLine.Size = UDim2.new(1, 0, 0, 1)
tabBottomLine.Position = UDim2.new(0, 0, 1, -1)
tabBottomLine.BackgroundColor3 = pal.border
tabBottomLine.BorderSizePixel = 0
tabBottomLine.ZIndex = 9999
tabBottomLine.Parent = tabBar

local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.new(0.33, 0, 0, 1)
tabIndicator.Position = UDim2.new(0, 0, 1, -1)
tabIndicator.BackgroundColor3 = pal.text
tabIndicator.BorderSizePixel = 0
tabIndicator.ZIndex = 10000
tabIndicator.Parent = tabBar

local function makeTab(text, idx, total)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/total, 0, 1, 0)
    btn.Position = UDim2.new((idx-1)/total, 0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text:upper()
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = pal.sub
    btn.LetterSpacing = 2
    btn.ZIndex = 9999
    btn.Parent = tabBar
    if idx > 1 then
        local div = Instance.new("Frame")
        div.Size = UDim2.new(0, 1, 0.5, 0)
        div.Position = UDim2.new(0, 0, 0.25, 0)
        div.BackgroundColor3 = pal.border
        div.BorderSizePixel = 0
        div.ZIndex = 9999
        div.Parent = btn
    end
    return btn
end

local searchTabBtn = makeTab("search", 1, 3)
local savedTabBtn = makeTab("saved", 2, 3)
local settingsTabBtn = makeTab("settings", 3, 3)
searchTabBtn.TextColor3 = pal.text

local function switchTab(idx)
    searchTabBtn.TextColor3 = idx == 1 and pal.text or pal.sub
    savedTabBtn.TextColor3 = idx == 2 and pal.text or pal.sub
    settingsTabBtn.TextColor3 = idx == 3 and pal.text or pal.sub
    tabIndicator:TweenPosition(UDim2.new((idx-1)/3, 0, 1, -1), "Out", "Quint", 0.2, true)
end

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -68)
content.Position = UDim2.new(0, 0, 0, 68)
content.BackgroundTransparency = 1
content.ZIndex = 9999
content.Parent = main

-- search frame
local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, -16, 1, -8)
searchFrame.Position = UDim2.new(0, 8, 0, 8)
searchFrame.BackgroundTransparency = 1
searchFrame.Visible = true
searchFrame.ZIndex = 9999
searchFrame.Parent = content

local function makeInput(placeholder, yPos, parent)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, -76, 0, 30)
    wrap.Position = UDim2.new(0, 0, 0, yPos)
    wrap.BackgroundColor3 = pal.card
    wrap.BackgroundTransparency = getTrans(pal.cardTrans)
    wrap.BorderSizePixel = 0
    wrap.ZIndex = 9999
    wrap.Parent = parent or searchFrame
    local wStroke = Instance.new("UIStroke")
    wStroke.Color = pal.border wStroke.Thickness = 1 wStroke.Parent = wrap
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.TextColor3 = pal.text
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = pal.sub
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.Text = ""
    box.ZIndex = 9999
    box.Parent = wrap
    return box, wrap
end

local function makeBtn(text, color, size, pos, parent, textColor)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = getTrans(0.1)
    btn.Text = text:upper()
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = textColor or pal.text
    btn.LetterSpacing = 1
    btn.ZIndex = 9999
    btn.Parent = parent
    local bs = Instance.new("UIStroke")
    bs.Color = pal.border bs.Thickness = 1 bs.Parent = btn
    return btn
end

local searchBox, _ = makeInput("search ugc emotes...", 0, searchFrame)
local searchBtn = makeBtn("go", pal.btnActive, UDim2.new(0, 64, 0, 30), UDim2.new(1, -64, 0, 0), searchFrame)
local idBox, _ = makeInput("paste animation id...", 38, searchFrame)
local playIdBtn = makeBtn("play", pal.btnActive, UDim2.new(0, 64, 0, 30), UDim2.new(1, -64, 0, 38), searchFrame)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -76)
scroll.Position = UDim2.new(0, 0, 0, 76)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = pal.border
scroll.ZIndex = 9999
scroll.Parent = searchFrame

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

-- saved frame
local savedFrame = Instance.new("Frame")
savedFrame.Size = UDim2.new(1, -16, 1, -8)
savedFrame.Position = UDim2.new(0, 8, 0, 8)
savedFrame.BackgroundTransparency = 1
savedFrame.Visible = false
savedFrame.ZIndex = 9999
savedFrame.Parent = content

local savedScroll = Instance.new("ScrollingFrame")
savedScroll.Size = UDim2.new(1, 0, 1, 0)
savedScroll.BackgroundTransparency = 1
savedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
savedScroll.ScrollBarThickness = 2
savedScroll.ScrollBarImageColor3 = pal.border
savedScroll.ZIndex = 9999
savedScroll.Parent = savedFrame

local savedList = Instance.new("UIListLayout", savedScroll)
savedList.Padding = UDim.new(0, 4)
savedList.SortOrder = Enum.SortOrder.LayoutOrder
savedList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    savedScroll.CanvasSize = UDim2.new(0, 0, 0, savedList.AbsoluteContentSize.Y + 8)
end)

-- settings frame
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(1, -16, 1, -8)
settingsFrame.Position = UDim2.new(0, 8, 0, 8)
settingsFrame.BackgroundTransparency = 1
settingsFrame.Visible = false
settingsFrame.ZIndex = 9999
settingsFrame.Parent = content

local settingsScroll = Instance.new("ScrollingFrame")
settingsScroll.Size = UDim2.new(1, 0, 1, 0)
settingsScroll.BackgroundTransparency = 1
settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
settingsScroll.ScrollBarThickness = 2
settingsScroll.ScrollBarImageColor3 = pal.border
settingsScroll.ZIndex = 9999
settingsScroll.Parent = settingsFrame

local settingsList = Instance.new("UIListLayout", settingsScroll)
settingsList.Padding = UDim.new(0, 4)
settingsList.SortOrder = Enum.SortOrder.LayoutOrder
settingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    settingsScroll.CanvasSize = UDim2.new(0, 0, 0, settingsList.AbsoluteContentSize.Y + 8)
end)

local function makeRow(labelText)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -2, 0, 40)
    row.BackgroundColor3 = pal.card
    row.BackgroundTransparency = getTrans(pal.cardTrans)
    row.BorderSizePixel = 0
    row.ZIndex = 9999
    row.Parent = settingsScroll
    local cardLine = Instance.new("Frame")
    cardLine.Size = UDim2.new(0, 1, 1, 0)
    cardLine.BackgroundColor3 = pal.borderBright
    cardLine.BorderSizePixel = 0 cardLine.ZIndex = 9999 cardLine.Parent = row
    local rs = Instance.new("UIStroke")
    rs.Color = pal.border rs.Thickness = 1 rs.Parent = row
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText:upper()
    lbl.TextColor3 = pal.text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.LetterSpacing = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 9999
    lbl.Parent = row
    return row
end

local function makeToggleBtn(row, state)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 26)
    btn.Position = UDim2.new(1, -68, 0.5, -13)
    btn.BackgroundColor3 = state and pal.borderBright or pal.btnHover
    btn.BackgroundTransparency = getTrans(0.1)
    btn.Text = state and "ON" or "OFF"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = state and pal.text or pal.sub
    btn.LetterSpacing = 2
    btn.ZIndex = 9999
    btn.Parent = row
    local bs = Instance.new("UIStroke")
    bs.Color = state and pal.borderBright or pal.border bs.Thickness = 1 bs.Parent = btn
    return btn, bs
end

local function makeSlider(row, min, max, val, callback)
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0, 160, 0, 6)
    sliderBg.Position = UDim2.new(1, -220, 0.5, -3)
    sliderBg.BackgroundColor3 = pal.btnHover
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 9999
    sliderBg.Parent = row
    local ss = Instance.new("UIStroke")
    ss.Color = pal.border ss.Thickness = 1 ss.Parent = sliderBg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = pal.borderBright
    fill.BorderSizePixel = 0
    fill.ZIndex = 9999
    fill.Parent = sliderBg

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 48, 1, 0)
    valLabel.Position = UDim2.new(1, -52, 0.5, -13)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(math.floor(val * 100) / 100)
    valLabel.TextColor3 = pal.text
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 10
    valLabel.ZIndex = 9999
    valLabel.Parent = row

    local dragging = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local newVal = math.floor((min + (max - min) * rel) * 100) / 100
            fill.Size = UDim2.new(rel, 0, 1, 0)
            valLabel.Text = tostring(newVal)
            callback(newVal)
        end
    end)
end

local function updateToggleBtn(btn, stroke, state)
    btn.Text = state and "ON" or "OFF"
    btn.BackgroundColor3 = state and pal.borderBright or pal.btnHover
    btn.TextColor3 = state and pal.text or pal.sub
    stroke.Color = state and pal.borderBright or pal.border
end

-- toggle rows
local transRow = makeRow("transparent ui")
local transBtn, transBtnStroke = makeToggleBtn(transRow, cfg.transparent)

local loopRow = makeRow("loop emote")
local loopBtn, loopBtnStroke = makeToggleBtn(loopRow, cfg.looped)

local stopOthersRow = makeRow("stop others on play")
local stopOthersBtn, stopOthersBtnStroke = makeToggleBtn(stopOthersRow, cfg.stopothers)

-- slider rows
local fadeInRow = makeRow("fade in")
makeSlider(fadeInRow, 0, 1, cfg.fadein, function(v)
    Settings.FadeIn = v cfg.fadein = v saveCfg()
end)

local fadeOutRow = makeRow("fade out")
makeSlider(fadeOutRow, 0, 1, cfg.fadeout, function(v)
    Settings.FadeOut = v cfg.fadeout = v saveCfg()
end)

local weightRow = makeRow("weight")
makeSlider(weightRow, 0, 1, cfg.weight, function(v)
    Settings.Weight = v cfg.weight = v saveCfg()
end)

local speedRow = makeRow("speed")
makeSlider(speedRow, 0.1, 3, cfg.speed, function(v)
    Settings.Speed = v cfg.speed = v saveCfg()
end)

-- keybind row
local keyRow = makeRow("open key")
keyRow.Size = UDim2.new(1, -2, 0, 40)
local keyBtn = Instance.new("TextButton")
keyBtn.Size = UDim2.new(0, 100, 0, 26)
keyBtn.Position = UDim2.new(1, -108, 0.5, -13)
keyBtn.BackgroundColor3 = pal.btnActive
keyBtn.BackgroundTransparency = getTrans(0.1)
keyBtn.Text = cfg.openkey
keyBtn.Font = Enum.Font.GothamBold
keyBtn.TextSize = 10
keyBtn.TextColor3 = pal.text
keyBtn.LetterSpacing = 2
keyBtn.ZIndex = 9999
keyBtn.Parent = keyRow
local kbs = Instance.new("UIStroke")
kbs.Color = pal.border kbs.Thickness = 1 kbs.Parent = keyBtn

keyBtn.MouseButton1Click:Connect(function()
    if bindingKey then return end
    bindingKey = true
    keyBtn.Text = "PRESS KEY..."
    keyBtn.TextColor3 = pal.accent
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local keyName = input.KeyCode.Name
        openKey = input.KeyCode
        cfg.openkey = keyName
        saveCfg()
        keyBtn.Text = keyName
        keyBtn.TextColor3 = pal.text
        subtitleLabel.Text = keyName .. " TO TOGGLE"
        bindingKey = false
        conn:Disconnect()
    end)
end)

-- version label
local verLabel = Instance.new("TextLabel")
verLabel.Size = UDim2.new(1, -2, 0, 24)
verLabel.BackgroundColor3 = pal.card
verLabel.BackgroundTransparency = getTrans(pal.cardTrans)
verLabel.BorderSizePixel = 0
verLabel.Text = "EMOTE SCRIPT  //  7SWAZYS"
verLabel.TextColor3 = pal.sub
verLabel.Font = Enum.Font.Gotham
verLabel.TextSize = 9
verLabel.LetterSpacing = 3
verLabel.ZIndex = 9999
verLabel.Parent = settingsScroll
local vs = Instance.new("UIStroke")
vs.Color = pal.border vs.Thickness = 1 vs.Parent = verLabel

-- toggle callbacks
transBtn.MouseButton1Click:Connect(function()
    cfg.transparent = not cfg.transparent
    saveCfg()
    updateToggleBtn(transBtn, transBtnStroke, cfg.transparent)
    main.BackgroundTransparency = getTrans(pal.bgTrans)
    titleBar.BackgroundTransparency = getTrans(pal.panelTrans)
    tabBar.BackgroundTransparency = getTrans(0.5)
    notify("transparent: " .. (cfg.transparent and "on" or "off"), pal.accent)
end)

loopBtn.MouseButton1Click:Connect(function()
    Settings.Looped = not Settings.Looped
    cfg.looped = Settings.Looped
    saveCfg()
    updateToggleBtn(loopBtn, loopBtnStroke, Settings.Looped)
    notify("loop: " .. (Settings.Looped and "on" or "off"), pal.accent)
end)

stopOthersBtn.MouseButton1Click:Connect(function()
    Settings.StopOthers = not Settings.StopOthers
    cfg.stopothers = Settings.StopOthers
    saveCfg()
    updateToggleBtn(stopOthersBtn, stopOthersBtnStroke, Settings.StopOthers)
    notify("stop others: " .. (Settings.StopOthers and "on" or "off"), pal.accent)
end)

-- card maker
local function makeCard(parent, item, isSaved, index)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -2, 0, 40)
    card.BackgroundColor3 = pal.card
    card.BackgroundTransparency = getTrans(pal.cardTrans)
    card.BorderSizePixel = 0
    card.ZIndex = 9999
    card.Parent = parent
    local cs = Instance.new("UIStroke")
    cs.Color = pal.border cs.Thickness = 1 cs.Parent = card
    local cardLine = Instance.new("Frame")
    cardLine.Size = UDim2.new(0, 1, 1, 0)
    cardLine.BackgroundColor3 = pal.borderBright
    cardLine.BorderSizePixel = 0 cardLine.ZIndex = 9999 cardLine.Parent = card

    local nameL = Instance.new("TextLabel")
    nameL.Size = UDim2.new(1, -268, 1, 0)
    nameL.Position = UDim2.new(0, 12, 0, 0)
    nameL.BackgroundTransparency = 1
    nameL.Text = item.Name or "unknown"
    nameL.Font = Enum.Font.Gotham
    nameL.TextSize = 11
    nameL.TextColor3 = pal.text
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.TextTruncate = Enum.TextTruncate.AtEnd
    nameL.ZIndex = 9999
    nameL.Parent = card

    local function cardBtn(text, color, xOff, textColor)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 52, 0, 26)
        b.Position = UDim2.new(1, xOff, 0.5, -13)
        b.BackgroundColor3 = color
        b.BackgroundTransparency = getTrans(0.1)
        b.Text = text:upper()
        b.Font = Enum.Font.GothamBold
        b.TextSize = 9
        b.TextColor3 = textColor or pal.text
        b.LetterSpacing = 1
        b.ZIndex = 9999
        b.Parent = card
        local bs = Instance.new("UIStroke")
        bs.Color = pal.border bs.Thickness = 1 bs.Parent = b
        return b
    end

    local playBtn = cardBtn("play", pal.btnActive, -262)
    playBtn.Name = "PlayBtn"
    local inlineStop = cardBtn("stop", pal.stop, -262)
    inlineStop.Name = "StopBtn"
    inlineStop.Visible = false
    local actionBtn = cardBtn(isSaved and "remove" or "save", isSaved and pal.stop or pal.btnActive, -202)
    local copyBtn = cardBtn("copy", pal.btnHover, -142, pal.sub)

    local id = item.AssetId or item.Id

    playBtn.MouseButton1Click:Connect(function()
        LoadTrack(id, item.Name, card)
        notify("playing: " .. (item.Name or "emote"), pal.accent)
    end)

    inlineStop.MouseButton1Click:Connect(function() StopEmote() end)

    copyBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(tostring(id)) end)
        copyBtn.Text = "OK"
        copyBtn.TextColor3 = pal.text
        task.wait(1)
        copyBtn.Text = "COPY"
        copyBtn.TextColor3 = pal.sub
    end)

    if isSaved then
        actionBtn.MouseButton1Click:Connect(function()
            table.remove(savedEmotes, index)
            saveToDisk()
            card:Destroy()
            notify("removed", pal.stop)
        end)
    else
        actionBtn.MouseButton1Click:Connect(function()
            local already = false
            for _, s in savedEmotes do if s.Id == id then already = true break end end
            if not already then
                table.insert(savedEmotes, {Id = id, Name = item.Name or "unknown"})
                saveToDisk()
                actionBtn.Text = "OK"
                task.wait(1)
                actionBtn.Text = "SAVE"
                notify("saved: " .. (item.Name or "emote"), pal.accent)
            else
                actionBtn.Text = "DUP"
                task.wait(0.7)
                actionBtn.Text = "SAVE"
                notify("already saved", pal.sub)
            end
        end)
    end
    return card
end

local function refreshSaved()
    for _, c in savedScroll:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
    if #savedEmotes == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 40)
        empty.BackgroundTransparency = 1
        empty.Text = "NO SAVED EMOTES"
        empty.TextColor3 = pal.sub
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 11
        empty.LetterSpacing = 2
        empty.ZIndex = 9999
        empty.Parent = savedScroll
        return
    end
    for i, item in ipairs(savedEmotes) do makeCard(savedScroll, item, true, i) end
end

local function doSearch(keyword)
    for _, c in scroll:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
    notify("searching...", pal.accent)
    local params = CatalogSearchParams.new()
    params.SearchKeyword = keyword or ""
    params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
    params.IncludeOffSale = true
    params.SortType = Enum.CatalogSortType.Relevance
    local ok, pages = pcall(function() return AvatarEditorService:SearchCatalog(params) end)
    if not ok or not pages then notify("search failed", pal.stop) return end
    local ok2, results = pcall(function() return pages:GetCurrentPage() end)
    if not ok2 or not results or #results == 0 then notify("no results", pal.sub) return end
    for _, item in results do makeCard(scroll, item, false, nil) end
    notify(#results .. " results", pal.accent)
end

searchTabBtn.MouseButton1Click:Connect(function()
    searchFrame.Visible = true savedFrame.Visible = false settingsFrame.Visible = false
    switchTab(1)
end)

savedTabBtn.MouseButton1Click:Connect(function()
    searchFrame.Visible = false savedFrame.Visible = true settingsFrame.Visible = false
    switchTab(2) refreshSaved()
end)

settingsTabBtn.MouseButton1Click:Connect(function()
    searchFrame.Visible = false savedFrame.Visible = false settingsFrame.Visible = true
    switchTab(3)
end)

searchBtn.MouseButton1Click:Connect(function() doSearch(searchBox.Text) end)
searchBox.FocusLost:Connect(function(enter) if enter then doSearch(searchBox.Text) end end)

playIdBtn.MouseButton1Click:Connect(function()
    local id = tonumber(idBox.Text)
    if id then
        LoadTrack(id, "id:" .. tostring(id), nil)
        notify("playing " .. tostring(id), pal.accent)
    else
        notify("invalid id", pal.stop)
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or bindingKey then return end
    if input.KeyCode == openKey then
        gui.Enabled = not gui.Enabled
    end
end)

notify("emote script  //  " .. cfg.openkey .. " to open", pal.accent)
