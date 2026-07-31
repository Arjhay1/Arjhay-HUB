--[[
    Arjhay Hub - Custom GUI
    Style based on Speed Hub X layout
    Features: Black theme, Draggable, Minimize (floating "A" badge), PC + Mobile friendly
    - Main tab: blank (no features yet)
    - Automation tab: Auto Sprinkler
]]

--// Services
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--// Clean up previous copies
local old = PlayerGui:FindFirstChild("ArjhayHub")
if old then old:Destroy() end

--============================================================
--  THEME  (Black Theme)
--============================================================
local Theme = {
    Background   = Color3.fromRGB(15, 15, 15),   -- main window
    Sidebar      = Color3.fromRGB(20, 20, 20),   -- left panel
    TopBar       = Color3.fromRGB(10, 10, 10),   -- title bar
    Button       = Color3.fromRGB(28, 28, 28),   -- list buttons
    ButtonHover  = Color3.fromRGB(40, 40, 40),
    Selected     = Color3.fromRGB(45, 45, 45),   -- active tab
    Accent       = Color3.fromRGB(220, 60, 60),  -- red accent (title / search)
    Text         = Color3.fromRGB(235, 235, 235),
    SubText      = Color3.fromRGB(170, 170, 170),
    Stroke       = Color3.fromRGB(50, 50, 50),
    ToggleOn     = Color3.fromRGB(60, 200, 90),
    ToggleOff    = Color3.fromRGB(70, 70, 70),
}

--============================================================
--  ROOT
--============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "ArjhayHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = PlayerGui

--// Helper for rounded corners
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

--// Helper for stroke
local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

--============================================================
--  MAIN WINDOW
--============================================================
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.AnchorPoint      = Vector2.new(0.5, 0.5)
Main.Position         = UDim2.new(0.5, 0, 0.5, 0)
Main.Size             = UDim2.new(0, 560, 0, 360)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.Parent           = ScreenGui
corner(Main, 8)
stroke(Main, Theme.Stroke, 1)

--============================================================
--  TOP BAR (title + minimize + close)  -> also the drag handle
--============================================================
local TopBar = Instance.new("Frame")
TopBar.Name             = "TopBar"
TopBar.Size             = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = Theme.TopBar
TopBar.BorderSizePixel  = 0
TopBar.Parent           = Main
corner(TopBar, 8)

-- cover bottom rounded corners of topbar
local TopBarFix = Instance.new("Frame")
TopBarFix.Size             = UDim2.new(1, 0, 0, 10)
TopBarFix.Position         = UDim2.new(0, 0, 1, -10)
TopBarFix.BackgroundColor3 = Theme.TopBar
TopBarFix.BorderSizePixel  = 0
TopBarFix.Parent           = TopBar

local Title = Instance.new("TextLabel")
Title.Name                   = "Title"
Title.BackgroundTransparency = 1
Title.Position               = UDim2.new(0, 12, 0, 0)
Title.Size                   = UDim2.new(1, -90, 1, 0)
Title.Font                   = Enum.Font.GothamBold
Title.Text                   = "Arjhay Hub | Version 1.0.0 | discord.gg/arjhayhub"
Title.TextColor3             = Theme.Accent
Title.TextSize               = 14
Title.TextXAlignment         = Enum.TextXAlignment.Left
Title.TextTruncate           = Enum.TextTruncate.AtEnd
Title.Parent                 = TopBar

--// Minimize button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name                   = "Minimize"
MinimizeBtn.AnchorPoint            = Vector2.new(1, 0.5)
MinimizeBtn.Position               = UDim2.new(1, -44, 0.5, 0)
MinimizeBtn.Size                   = UDim2.new(0, 26, 0, 26)
MinimizeBtn.BackgroundColor3       = Theme.Button
MinimizeBtn.Text                   = "—"
MinimizeBtn.Font                   = Enum.Font.GothamBold
MinimizeBtn.TextColor3             = Theme.Text
MinimizeBtn.TextSize               = 16
MinimizeBtn.AutoButtonColor        = true
MinimizeBtn.Parent                 = TopBar
corner(MinimizeBtn, 6)

--// Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name                   = "Close"
CloseBtn.AnchorPoint            = Vector2.new(1, 0.5)
CloseBtn.Position               = UDim2.new(1, -12, 0.5, 0)
CloseBtn.Size                   = UDim2.new(0, 26, 0, 26)
CloseBtn.BackgroundColor3       = Theme.Button
CloseBtn.Text                   = "X"
CloseBtn.Font                   = Enum.Font.GothamBold
CloseBtn.TextColor3             = Theme.Text
CloseBtn.TextSize               = 14
CloseBtn.AutoButtonColor        = true
CloseBtn.Parent                 = TopBar
corner(CloseBtn, 6)

--============================================================
--  SIDEBAR (left)
--============================================================
local Sidebar = Instance.new("Frame")
Sidebar.Name             = "Sidebar"
Sidebar.Position         = UDim2.new(0, 0, 0, 34)
Sidebar.Size             = UDim2.new(0, 140, 1, -34)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel  = 0
Sidebar.Parent           = Main

--// Search box
local SearchHolder = Instance.new("Frame")
SearchHolder.Position         = UDim2.new(0, 10, 0, 10)
SearchHolder.Size             = UDim2.new(1, -20, 0, 28)
SearchHolder.BackgroundColor3 = Theme.Button
SearchHolder.BorderSizePixel  = 0
SearchHolder.Parent           = Sidebar
corner(SearchHolder, 6)
stroke(SearchHolder, Theme.Accent, 1)

local SearchBox = Instance.new("TextBox")
SearchBox.BackgroundTransparency = 1
SearchBox.Position               = UDim2.new(0, 8, 0, 0)
SearchBox.Size                   = UDim2.new(1, -16, 1, 0)
SearchBox.Font                   = Enum.Font.Gotham
SearchBox.PlaceholderText        = "Search"
SearchBox.Text                   = ""
SearchBox.TextColor3             = Theme.Text
SearchBox.PlaceholderColor3      = Theme.SubText
SearchBox.TextSize               = 13
SearchBox.TextXAlignment         = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus       = false
SearchBox.Parent                 = SearchHolder

--// Tab list container
local TabList = Instance.new("Frame")
TabList.Position               = UDim2.new(0, 8, 0, 48)
TabList.Size                   = UDim2.new(1, -16, 1, -56)
TabList.BackgroundTransparency = 1
TabList.Parent                 = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding    = UDim.new(0, 4)
TabLayout.SortOrder  = Enum.SortOrder.LayoutOrder
TabLayout.Parent     = TabList

--// Tab definitions
local tabs = {
    { name = "Home",         icon = "🙂" },
    { name = "Main",         icon = "🏠" },
    { name = "Automation",   icon = "▶" },
    { name = "Inventory",    icon = "🎒" },
    { name = "Shop",         icon = "🛒" },
    { name = "Webhook",      icon = "🔗" },
    { name = "Misc",         icon = "⚙" },
}

local tabButtons = {}
local selectedTab = "Main"

local function makeTabButton(info, index)
    local btn = Instance.new("TextButton")
    btn.Name                   = info.name
    btn.Size                   = UDim2.new(1, 0, 0, 30)
    btn.LayoutOrder            = index
    btn.BackgroundColor3       = (info.name == selectedTab) and Theme.Selected or Theme.Sidebar
    btn.BackgroundTransparency = (info.name == selectedTab) and 0 or 1
    btn.Text                   = ""
    btn.AutoButtonColor        = false
    btn.Parent                 = TabList
    corner(btn, 6)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position               = UDim2.new(0, 10, 0, 0)
    label.Size                   = UDim2.new(1, -12, 1, 0)
    label.Font                   = Enum.Font.GothamMedium
    label.Text                   = info.icon .. "  " .. info.name
    label.TextColor3             = Theme.Text
    label.TextSize               = 13
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.TextTruncate           = Enum.TextTruncate.AtEnd
    label.Parent                 = btn

    tabButtons[info.name] = btn
    return btn
end

for i, info in ipairs(tabs) do
    makeTabButton(info, i)
end

--============================================================
--  CONTENT AREA (right)
--============================================================
local Content = Instance.new("Frame")
Content.Name             = "Content"
Content.Position         = UDim2.new(0, 140, 0, 34)
Content.Size             = UDim2.new(1, -140, 1, -34)
Content.BackgroundColor3 = Theme.Background
Content.BorderSizePixel  = 0
Content.Parent           = Main

local Header = Instance.new("TextLabel")
Header.Name                   = "Header"
Header.BackgroundTransparency = 1
Header.Position               = UDim2.new(0, 16, 0, 6)
Header.Size                   = UDim2.new(1, -32, 0, 34)
Header.Font                   = Enum.Font.GothamBold
Header.Text                   = "Main"
Header.TextColor3             = Theme.Text
Header.TextSize               = 24
Header.TextXAlignment         = Enum.TextXAlignment.Left
Header.Parent                 = Content

--// Container that holds one page per tab
local Pages = Instance.new("Frame")
Pages.Name                   = "Pages"
Pages.Position               = UDim2.new(0, 12, 0, 46)
Pages.Size                   = UDim2.new(1, -24, 1, -58)
Pages.BackgroundTransparency = 1
Pages.Parent                 = Content

--// Helper: create a scrolling page for a tab
local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name                   = name
    page.Size                   = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel        = 0
    page.ScrollBarThickness     = 4
    page.ScrollBarImageColor3   = Theme.Accent
    page.CanvasSize             = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    page.Visible                = false
    page.Parent                 = Pages

    local layout = Instance.new("UIListLayout")
    layout.Padding   = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent    = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent        = page

    return page
end

--// Helper: an "empty / coming soon" placeholder
local function makeEmptyLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size                   = UDim2.new(1, 0, 0, 60)
    lbl.Font                   = Enum.Font.Gotham
    lbl.Text                   = text
    lbl.TextColor3             = Theme.SubText
    lbl.TextSize               = 14
    lbl.Parent                 = parent
    return lbl
end

--// Helper: a toggle row (label + on/off switch)
local function makeToggleRow(parent, text, index, callback)
    local row = Instance.new("Frame")
    row.Name                   = text
    row.Size                   = UDim2.new(1, 0, 0, 34)
    row.LayoutOrder            = index
    row.BackgroundColor3       = Theme.Button
    row.BorderSizePixel        = 0
    row.Parent                 = parent
    corner(row, 6)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position               = UDim2.new(0, 12, 0, 0)
    label.Size                   = UDim2.new(1, -70, 1, 0)
    label.Font                   = Enum.Font.GothamMedium
    label.Text                   = text
    label.TextColor3             = Theme.Text
    label.TextSize               = 14
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.Parent                 = row

    -- switch track
    local track = Instance.new("TextButton")
    track.AnchorPoint            = Vector2.new(1, 0.5)
    track.Position               = UDim2.new(1, -12, 0.5, 0)
    track.Size                   = UDim2.new(0, 42, 0, 22)
    track.BackgroundColor3       = Theme.ToggleOff
    track.Text                   = ""
    track.AutoButtonColor        = false
    track.Parent                 = row
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.AnchorPoint            = Vector2.new(0, 0.5)
    knob.Position               = UDim2.new(0, 2, 0.5, 0)
    knob.Size                   = UDim2.new(0, 18, 0, 18)
    knob.BackgroundColor3       = Color3.fromRGB(240, 240, 240)
    knob.BorderSizePixel        = 0
    knob.Parent                 = track
    corner(knob, 9)

    local state = false
    local function setState(on)
        state = on
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = on and Theme.ToggleOn or Theme.ToggleOff
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        }):Play()
        if callback then callback(on) end
    end

    track.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    return row
end

--============================================================
--  PAGES
--============================================================
local pages = {}

-- Main tab: holds the Fruit Collect feature (built later, after helpers)
pages["Main"] = makePage("Main")

-- Home page is built later (Farm Details section, after the garden helpers).
pages["Home"] = makePage("Home")

-- Inventory / Webhook : blank placeholders
-- (Misc is built later with the Performance section,
--  Shop is built later with the Seed Shop section)
for _, n in ipairs({ "Inventory", "Webhook" }) do
    pages[n] = makePage(n)
    makeEmptyLabel(pages[n], "No features yet — coming soon!")
end

--============================================================
--  EXTRA HELPERS FOR THE AUTOMATION PAGE
--============================================================

--// A small icon + label + toggle switch, on ONE compact row
local function makeIconToggle(parent, icon, text, index, callback)
    local row = Instance.new("Frame")
    row.Name                   = text
    row.Size                   = UDim2.new(1, 0, 0, 36)
    row.LayoutOrder            = index
    row.BackgroundColor3       = Theme.Button
    row.BorderSizePixel        = 0
    row.Parent                 = parent
    corner(row, 6)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position               = UDim2.new(0, 10, 0, 0)
    label.Size                   = UDim2.new(1, -70, 1, 0)
    label.Font                   = Enum.Font.GothamMedium
    label.Text                   = icon .. "  " .. text
    label.TextColor3             = Theme.Text
    label.TextSize               = 13
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.TextWrapped            = true
    label.Parent                 = row

    local track = Instance.new("TextButton")
    track.AnchorPoint            = Vector2.new(1, 0.5)
    track.Position               = UDim2.new(1, -10, 0.5, 0)
    track.Size                   = UDim2.new(0, 42, 0, 22)
    track.BackgroundColor3       = Theme.ToggleOff
    track.Text                   = ""
    track.AutoButtonColor        = false
    track.Parent                 = row
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.AnchorPoint            = Vector2.new(0, 0.5)
    knob.Position               = UDim2.new(0, 2, 0.5, 0)
    knob.Size                   = UDim2.new(0, 18, 0, 18)
    knob.BackgroundColor3       = Color3.fromRGB(240, 240, 240)
    knob.BorderSizePixel        = 0
    knob.Parent                 = track
    corner(knob, 9)

    local state = false
    track.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        }):Play()
        if callback then callback(state) end
    end)

    return row
end

--// A section label (icon + text), used above dropdowns / inputs
local function makeSectionLabel(parent, icon, text, index)
    local lbl = Instance.new("TextLabel")
    lbl.Name                   = text
    lbl.BackgroundTransparency = 1
    lbl.Size                   = UDim2.new(1, 0, 0, 20)
    lbl.LayoutOrder            = index
    lbl.Font                   = Enum.Font.GothamMedium
    lbl.Text                   = icon .. "  " .. text
    lbl.TextColor3             = Theme.Text
    lbl.TextSize               = 13
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Parent                 = parent
    return lbl
end

--// A centered divider label like  - [ Config ] -
local function makeDivider(parent, text, index)
    local lbl = Instance.new("TextLabel")
    lbl.Name                   = "Divider_" .. text
    lbl.BackgroundTransparency = 1
    lbl.Size                   = UDim2.new(1, 0, 0, 22)
    lbl.LayoutOrder            = index
    lbl.Font                   = Enum.Font.GothamBold
    lbl.Text                   = "- [ " .. text .. " ] -"
    lbl.TextColor3             = Theme.SubText
    lbl.TextSize               = 13
    lbl.TextXAlignment         = Enum.TextXAlignment.Center
    lbl.Parent                 = parent
    return lbl
end

--// A collapsible section: a header row that expands/collapses its content.
--// Returns the inner content frame (uses its own UIListLayout) so you can
--// add rows into it.  Header shows a chevron that flips when open.
local function makeCollapsible(parent, title, index, startOpen)
    -- outer holder so header + content stack together in the page layout
    local holder = Instance.new("Frame")
    holder.Name                   = title
    holder.Size                   = UDim2.new(1, 0, 0, 36)
    holder.AutomaticSize          = Enum.AutomaticSize.Y
    holder.LayoutOrder            = index
    holder.BackgroundTransparency = 1
    holder.Parent                 = parent

    local hLayout = Instance.new("UIListLayout")
    hLayout.Padding   = UDim.new(0, 6)
    hLayout.SortOrder = Enum.SortOrder.LayoutOrder
    hLayout.Parent    = holder

    -- header button
    local header = Instance.new("TextButton")
    header.Name             = "Header"
    header.Size             = UDim2.new(1, 0, 0, 36)
    header.LayoutOrder      = 1
    header.BackgroundColor3 = Theme.Button
    header.Text             = ""
    header.AutoButtonColor  = false
    header.Parent           = holder
    corner(header, 6)

    -- red underline accent (like the screenshot)
    local underline = Instance.new("Frame")
    underline.AnchorPoint      = Vector2.new(0, 1)
    underline.Position         = UDim2.new(0, 0, 1, 0)
    underline.Size             = UDim2.new(1, 0, 0, 2)
    underline.BackgroundColor3 = Theme.Accent
    underline.BorderSizePixel  = 0
    underline.Parent           = header

    local hLabel = Instance.new("TextLabel")
    hLabel.BackgroundTransparency = 1
    hLabel.Position               = UDim2.new(0, 12, 0, 0)
    hLabel.Size                   = UDim2.new(1, -44, 1, 0)
    hLabel.Font                   = Enum.Font.GothamBold
    hLabel.Text                   = title
    hLabel.TextColor3             = Theme.Text
    hLabel.TextSize               = 14
    hLabel.TextXAlignment         = Enum.TextXAlignment.Left
    hLabel.Parent                 = header

    local chev = Instance.new("TextLabel")
    chev.BackgroundTransparency = 1
    chev.AnchorPoint            = Vector2.new(1, 0.5)
    chev.Position               = UDim2.new(1, -12, 0.5, 0)
    chev.Size                   = UDim2.new(0, 20, 1, 0)
    chev.Font                   = Enum.Font.GothamBold
    chev.Text                   = "⌄"
    chev.TextColor3             = Theme.Text
    chev.TextSize               = 18
    chev.Parent                 = header

    -- content container (holds the actual controls)
    local content = Instance.new("Frame")
    content.Name                   = "Content"
    content.Size                   = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize          = Enum.AutomaticSize.Y
    content.LayoutOrder            = 2
    content.BackgroundTransparency = 1
    content.Visible                = startOpen and true or false
    content.Parent                 = holder

    local cLayout = Instance.new("UIListLayout")
    cLayout.Padding   = UDim.new(0, 6)
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.Parent    = content

    local open = startOpen and true or false
    local function refreshChevron()
        chev.Text = open and "⌄" or "›"
        chev.Rotation = open and 0 or 0
    end
    refreshChevron()

    header.MouseButton1Click:Connect(function()
        open = not open
        content.Visible = open
        refreshChevron()
    end)

    return content
end


--// A full-window popup list for choosing an option (styled to our theme)
local function openDropdownPopup(titleIcon, titleText, options, current, onSelect)
    local Overlay = Instance.new("Frame")
    Overlay.Name             = "Popup"
    Overlay.Size             = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.4
    Overlay.BorderSizePixel  = 0
    Overlay.ZIndex           = 50
    Overlay.Parent           = ScreenGui

    local Panel = Instance.new("Frame")
    Panel.AnchorPoint      = Vector2.new(0.5, 0.5)
    Panel.Position         = UDim2.new(0.5, 0, 0.5, 0)
    Panel.Size             = UDim2.new(0, 520, 0, 400)
    Panel.BackgroundColor3 = Theme.Background
    Panel.BorderSizePixel  = 0
    Panel.ZIndex           = 51
    Panel.Parent           = Overlay
    corner(Panel, 8)
    stroke(Panel, Theme.Stroke, 1)

    -- header
    local Head = Instance.new("Frame")
    Head.Size             = UDim2.new(1, 0, 0, 40)
    Head.BackgroundColor3 = Theme.TopBar
    Head.BorderSizePixel  = 0
    Head.ZIndex           = 52
    Head.Parent           = Panel
    corner(Head, 8)

    local HeadTitle = Instance.new("TextLabel")
    HeadTitle.BackgroundTransparency = 1
    HeadTitle.Position               = UDim2.new(0, 12, 0, 0)
    HeadTitle.Size                   = UDim2.new(1, -110, 1, 0)
    HeadTitle.Font                   = Enum.Font.GothamBold
    HeadTitle.Text                   = titleIcon .. "  " .. titleText
    HeadTitle.TextColor3             = Theme.Text
    HeadTitle.TextSize               = 15
    HeadTitle.TextXAlignment         = Enum.TextXAlignment.Left
    HeadTitle.ZIndex                 = 53
    HeadTitle.Parent                 = Head

    local CloseBtn2 = Instance.new("TextButton")
    CloseBtn2.AnchorPoint      = Vector2.new(1, 0.5)
    CloseBtn2.Position         = UDim2.new(1, -10, 0.5, 0)
    CloseBtn2.Size             = UDim2.new(0, 80, 0, 26)
    CloseBtn2.BackgroundColor3 = Theme.Button
    CloseBtn2.Text             = "Close"
    CloseBtn2.Font             = Enum.Font.GothamMedium
    CloseBtn2.TextColor3       = Theme.Text
    CloseBtn2.TextSize         = 13
    CloseBtn2.ZIndex           = 53
    CloseBtn2.Parent           = Head
    corner(CloseBtn2, 6)

    -- search box (filters the option list live)
    local searchHolder = Instance.new("Frame")
    searchHolder.Position         = UDim2.new(0, 8, 0, 48)
    searchHolder.Size             = UDim2.new(1, -16, 0, 30)
    searchHolder.BackgroundColor3 = Theme.Button
    searchHolder.BorderSizePixel  = 0
    searchHolder.ZIndex           = 52
    searchHolder.Parent           = Panel
    corner(searchHolder, 6)
    stroke(searchHolder, Theme.Accent, 1)

    local searchBox = Instance.new("TextBox")
    searchBox.BackgroundTransparency = 1
    searchBox.Position               = UDim2.new(0, 10, 0, 0)
    searchBox.Size                   = UDim2.new(1, -16, 1, 0)
    searchBox.Font                   = Enum.Font.Gotham
    searchBox.PlaceholderText        = "Search..."
    searchBox.Text                   = ""
    searchBox.TextColor3             = Theme.Text
    searchBox.PlaceholderColor3      = Theme.SubText
    searchBox.TextSize               = 13
    searchBox.TextXAlignment         = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus       = false
    searchBox.ZIndex                 = 53
    searchBox.Parent                 = searchHolder

    -- option list
    local ListScroll = Instance.new("ScrollingFrame")
    ListScroll.Position               = UDim2.new(0, 8, 0, 86)
    ListScroll.Size                   = UDim2.new(1, -16, 1, -94)
    ListScroll.BackgroundTransparency = 1
    ListScroll.BorderSizePixel        = 0
    ListScroll.ScrollBarThickness     = 4
    ListScroll.ScrollBarImageColor3   = Theme.Accent
    ListScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    ListScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    ListScroll.ZIndex                 = 52
    ListScroll.Parent                 = Panel

    local lay = Instance.new("UIListLayout")
    lay.Padding   = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent    = ListScroll

    local rows = {}
    for i, opt in ipairs(options) do
        local item = Instance.new("TextButton")
        item.Name             = opt
        item.Size             = UDim2.new(1, 0, 0, 40)
        item.LayoutOrder      = i
        item.BackgroundColor3 = (opt == current) and Theme.Selected or Theme.Button
        item.Text             = ""
        item.AutoButtonColor  = false
        item.ZIndex           = 53
        item.Parent           = ListScroll
        corner(item, 6)

        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Position               = UDim2.new(0, 12, 0, 0)
        t.Size                   = UDim2.new(1, -20, 1, 0)
        t.Font                   = Enum.Font.Gotham
        t.Text                   = opt
        t.TextColor3             = Theme.Text
        t.TextSize               = 14
        t.TextXAlignment         = Enum.TextXAlignment.Left
        t.ZIndex                 = 54
        t.Parent                 = item

        item.MouseEnter:Connect(function()
            if opt ~= current then item.BackgroundColor3 = Theme.ButtonHover end
        end)
        item.MouseLeave:Connect(function()
            if opt ~= current then item.BackgroundColor3 = Theme.Button end
        end)
        item.MouseButton1Click:Connect(function()
            if onSelect then onSelect(opt) end
            Overlay:Destroy()
        end)
        rows[opt] = item
    end

    -- live filtering
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(searchBox.Text)
        for opt, item in pairs(rows) do
            item.Visible = (q == "") or string.find(string.lower(opt), q, 1, true) ~= nil
        end
    end)

    CloseBtn2.MouseButton1Click:Connect(function()
        Overlay:Destroy()
    end)
end

--// A dropdown box (shows selected value + chevron) that opens the popup
local function makeDropdown(parent, titleIcon, titleText, boxDefault, options, index, onSelect)
    local box = Instance.new("TextButton")
    box.Name             = "Dropdown_" .. titleText

    box.Size             = UDim2.new(1, 0, 0, 30)
    box.LayoutOrder      = index
    box.BackgroundColor3 = Theme.Button
    box.Text             = ""
    box.AutoButtonColor  = false
    box.Parent           = parent
    corner(box, 6)
    stroke(box, Theme.Stroke, 1)

    local valueLbl = Instance.new("TextLabel")
    valueLbl.BackgroundTransparency = 1
    valueLbl.Position               = UDim2.new(0, 10, 0, 0)
    valueLbl.Size                   = UDim2.new(1, -32, 1, 0)
    valueLbl.Font                   = Enum.Font.Gotham
    valueLbl.Text                   = boxDefault
    valueLbl.TextColor3             = Theme.Text
    valueLbl.TextSize               = 13
    valueLbl.TextXAlignment         = Enum.TextXAlignment.Left
    valueLbl.TextTruncate           = Enum.TextTruncate.AtEnd
    valueLbl.Parent                 = box

    local chev = Instance.new("TextLabel")
    chev.BackgroundTransparency = 1
    chev.AnchorPoint            = Vector2.new(1, 0.5)
    chev.Position               = UDim2.new(1, -8, 0.5, 0)
    chev.Size                   = UDim2.new(0, 16, 1, 0)
    chev.Font                   = Enum.Font.GothamBold
    chev.Text                   = "⌄"
    chev.TextColor3             = Theme.SubText
    chev.TextSize               = 16
    chev.Parent                 = box

    box.MouseButton1Click:Connect(function()
        openDropdownPopup(titleIcon, titleText, options, valueLbl.Text, function(opt)
            valueLbl.Text = opt
            if onSelect then onSelect(opt) end
        end)
    end)


    return valueLbl
end

--// Two buttons side by side (All / Clear)
local function makeButtonPair(parent, index, onAll, onClear)
    local holder = Instance.new("Frame")
    holder.Size                   = UDim2.new(1, 0, 0, 30)
    holder.LayoutOrder            = index
    holder.BackgroundTransparency = 1
    holder.Parent                 = parent

    local hl = Instance.new("UIListLayout")
    hl.FillDirection = Enum.FillDirection.Horizontal
    hl.Padding       = UDim.new(0, 8)
    hl.Parent        = holder

    local function mk(text, color, cb)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0.5, -4, 1, 0)
        b.BackgroundColor3 = Theme.Button
        b.Text             = text
        b.Font             = Enum.Font.GothamMedium
        b.TextColor3       = color
        b.TextSize         = 13
        b.AutoButtonColor  = true
        b.Parent           = holder
        corner(b, 6)
        stroke(b, Theme.Stroke, 1)
        b.MouseButton1Click:Connect(cb)
    end

    mk("✔  All", Theme.ToggleOn, onAll or function() end)
    mk("✖  Clear", Theme.Accent, onClear or function() end)
end

--// A number input box (with a small label above)
local function makeNumberInput(parent, default, index, onChanged)
    local holder = Instance.new("Frame")
    holder.Size                   = UDim2.new(1, 0, 0, 30)
    holder.LayoutOrder            = index
    holder.BackgroundColor3       = Theme.Button
    holder.BorderSizePixel        = 0
    holder.Parent                 = parent
    corner(holder, 6)
    stroke(holder, Theme.Stroke, 1)

    local input = Instance.new("TextBox")
    input.BackgroundTransparency = 1
    input.Position               = UDim2.new(0, 10, 0, 0)
    input.Size                   = UDim2.new(1, -16, 1, 0)
    input.Font                   = Enum.Font.Gotham
    input.Text                   = tostring(default)
    input.PlaceholderText        = "0"
    input.TextColor3             = Theme.Text
    input.PlaceholderColor3      = Theme.SubText
    input.TextSize               = 13
    input.TextXAlignment         = Enum.TextXAlignment.Left
    input.ClearTextOnFocus       = false
    input.Parent                 = holder

    input.FocusLost:Connect(function()
        local n = tonumber(input.Text)
        if not n then
            input.Text = tostring(default)
        elseif onChanged then
            onChanged(n)
        end
    end)

    return input
end

--// A multi-select sprinkler row: [checkbox + name] .......... [count box]
--// Lets the user enable a sprinkler AND set how many of it to place.
local function makeSprinklerSelectRow(parent, name, index, entry)
    local row = Instance.new("Frame")
    row.Name                   = name
    row.Size                   = UDim2.new(1, 0, 0, 32)
    row.LayoutOrder            = index
    row.BackgroundColor3       = Theme.Button
    row.BorderSizePixel        = 0
    row.Parent                 = parent
    corner(row, 6)
    stroke(row, Theme.Stroke, 1)

    -- checkbox
    local check = Instance.new("TextButton")
    check.AnchorPoint      = Vector2.new(0, 0.5)
    check.Position         = UDim2.new(0, 8, 0.5, 0)
    check.Size             = UDim2.new(0, 20, 0, 20)
    check.BackgroundColor3 = Theme.ToggleOff
    check.Text             = ""
    check.AutoButtonColor  = false
    check.Parent           = row
    corner(check, 4)

    local tick = Instance.new("TextLabel")
    tick.BackgroundTransparency = 1
    tick.Size                   = UDim2.new(1, 0, 1, 0)
    tick.Font                   = Enum.Font.GothamBold
    tick.Text                   = "✔"
    tick.TextColor3             = Color3.fromRGB(255, 255, 255)
    tick.TextSize               = 14
    tick.Visible                = false
    tick.Parent                 = check

    -- name label
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position               = UDim2.new(0, 36, 0, 0)
    label.Size                   = UDim2.new(1, -110, 1, 0)
    label.Font                   = Enum.Font.GothamMedium
    label.Text                   = name
    label.TextColor3             = Theme.Text
    label.TextSize               = 13
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.TextTruncate           = Enum.TextTruncate.AtEnd
    label.Parent                 = row

    -- count box on the right
    local countHolder = Instance.new("Frame")
    countHolder.AnchorPoint      = Vector2.new(1, 0.5)
    countHolder.Position         = UDim2.new(1, -8, 0.5, 0)
    countHolder.Size             = UDim2.new(0, 56, 0, 24)
    countHolder.BackgroundColor3 = Theme.Background
    countHolder.BorderSizePixel  = 0
    countHolder.Parent           = row
    corner(countHolder, 4)
    stroke(countHolder, Theme.Stroke, 1)

    local countBox = Instance.new("TextBox")
    countBox.BackgroundTransparency = 1
    countBox.Size                   = UDim2.new(1, 0, 1, 0)
    countBox.Font                   = Enum.Font.Gotham
    countBox.Text                   = tostring(entry.count)
    countBox.PlaceholderText        = "1"
    countBox.TextColor3             = Theme.Text
    countBox.PlaceholderColor3      = Theme.SubText
    countBox.TextSize               = 13
    countBox.TextXAlignment         = Enum.TextXAlignment.Center
    countBox.ClearTextOnFocus       = false
    countBox.Parent                 = countHolder

    local function refresh()
        check.BackgroundColor3 = entry.enabled and Theme.ToggleOn or Theme.ToggleOff
        tick.Visible           = entry.enabled
    end
    refresh()

    check.MouseButton1Click:Connect(function()
        entry.enabled = not entry.enabled
        refresh()
    end)

    countBox.FocusLost:Connect(function()
        local n = tonumber(countBox.Text)
        if not n or n < 0 then
            countBox.Text = tostring(entry.count)
        else
            n = math.floor(n)
            entry.count = n
            countBox.Text = tostring(n)
        end
    end)

    return row
end

--============================================================
--  NOCLIP  (keeps the character passing THROUGH plants instead of
--  flying / standing on top of the giant plant model)
--============================================================
local noclipActive = false
local noclipConn
local function setNoclip(on)
    noclipActive = on
    if on and not noclipConn then
        noclipConn = RunService.Stepped:Connect(function()
            if not noclipActive then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    end
end

--// Smoothly tween the character to a target position (NOT fast).
--// Returns when it arrives (or times out).
--// The target is snapped to a proper STANDING height above the ground so the
--// character doesn't sink into the floor (important for Plant Target, whose
--// position sits at ground level).
-- Teleports the character horizontally to stand at targetPos.
--
-- KEY FIX FOR THE "FLYING" BUG:
-- The farm ground is FLAT and the character is already standing ON the ground
-- before we teleport (walking with the mouse always keeps it grounded). So we
-- DO NOT raycast for ground height (that was landing on top of tall plant
-- models and launching the character into the air). Instead we KEEP the
-- character's CURRENT Y height and only move it on X/Z — it stays exactly as
-- grounded as it was before the teleport.
--
-- We also DON'T anchor here; we just preserve the current height, which keeps
-- the humanoid walking/standing normally on the flat farm.
local function smoothTeleport(targetPos)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Turn ON noclip so the character passes THROUGH plants/objects while
    -- moving and while standing on the spot. Without this, the character
    -- collides with a tall plant model and gets pushed UP on top of it — that
    -- is the "flying" you saw. Noclip stays on during automation and is turned
    -- off when the systems stop / the hub closes.
    setNoclip(true)

    local startPos = hrp.Position

    -- keep the SAME height as now (already grounded); move only horizontally
    local goal = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)

    local distance = (goal - startPos).Magnitude
    if distance < 1 then
        -- already basically there; make sure we sit exactly on the spot
        hrp.CFrame = CFrame.new(goal)
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.AutoRotate = false end

    -- Travel speed for the auto-teleport tween.
    -- Lower TWEEN_STUDS_PER_SEC = slower, calmer movement. 60 was too fast and
    -- looked like an instant snap between plants, so this is dialed down and the
    -- minimum duration is raised so even short hops are visibly smooth.
    local TWEEN_STUDS_PER_SEC = 22
    local duration = math.clamp(distance / TWEEN_STUDS_PER_SEC, 0.55, 4)

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        { CFrame = CFrame.new(goal) }
    )
    tween:Play()
    tween.Completed:Wait()

    -- settle on the exact spot (keeping current height) before the remote fires
    hrp.CFrame = CFrame.new(goal)
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    task.wait(0.1)

    if humanoid then humanoid.AutoRotate = true end
end



--============================================================
--  AUTOMATION TAB  (Auto Sprinkler)
--============================================================

pages["Automation"] = makePage("Automation")
local ap = pages["Automation"]

-- Placement Mode options (only these, per request)
local placementOptions = {
    "Plant Target",
    "Saved Position",
}


-- Sprinkler types (top -> bottom)
local SPRINKLER_TYPES = {
    "Common Sprinkler",
    "Uncommon Sprinkler",
    "Rare Sprinkler",
    "Legendary Sprinkler",
    "Super Sprinkler",
}

-- Plant names (used by "Plant Target" placement mode).
-- We try to build this list DYNAMICALLY from the game's plant template folder
-- (ReplicatedStorage.Assets.Plants) so it always matches the real names.
-- If that folder isn't found, we fall back to the hard-coded list below.
local PLANT_NAMES = {}

do
    local ok, folder = pcall(function()
        return ReplicatedStorage:WaitForChild("Assets", 5)
            and ReplicatedStorage.Assets:WaitForChild("Plants", 5)
    end)
    if ok and folder then
        for _, child in ipairs(folder:GetChildren()) do
            table.insert(PLANT_NAMES, child.Name)
        end
        table.sort(PLANT_NAMES)
        print("[Arjhay Hub] Loaded " .. #PLANT_NAMES .. " plants from ReplicatedStorage.Assets.Plants")
    end
end

-- Fallback list (used only if the folder above was empty / missing)
if #PLANT_NAMES == 0 then
    PLANT_NAMES = {
        "Acorn", "Amber Cranberry", "Apple", "Atlantic Giant Pumpkin", "Baby Cactus",
        "Bamboo", "Banana", "Beanstalk", "Blueberry", "Briar Rose", "Buttercup",
        "Cactus", "Carrot", "Cherry", "Cinnamon Stick", "Coconut",
        "Conifer Cone", "Conifer Cone Sapling", "Corn", "Dragon Fruit", "Dragon's Breath",
        "Eclipse Bloom", "Fire Fern", "Ghost Pepper", "Glow Mushroom", "Gold", "Grape",
        "Green Bean", "Horned Melon", "Hypno Bloom", "Lotus", "Mango", "Maple Apple",
        "Maple Bamboo", "Maple Blueberry", "Maple Cactus", "Maple Carrot", "Maple Corn",
        "Maple Green Bean", "Maple Mushroom", "Maple Pineapple", "Maple Poison Apple",
        "Maple Pomegranate", "Maple Strawberry", "Maple Tomato", "Maple Tulip",
        "Maple Venom Spitter", "Maple Venus Fly Trap", "Mega", "Moon Bloom",
        "Moon Bloom OLD", "Mushroom", "PartFruit", "Pineapple", "Pinetree",
        "Plum", "Poison Apple", "Poison Ivy", "Pomegranate", "Pumpkin", "Rainbow",
        "Rocket Pop", "Romanesco", "Star Fruit", "Strawberry", "Sun Bloom", "Sunflower",
        "Thorn Rose", "Tomato", "Tulip", "Venom Spitter", "Venus Fly Trap",
    }
end



-- Lifetime (seconds) for each sprinkler — used by "Replace Near Expiry".
-- The in-game timer shows "2m" (=120s), so we use 12 here.(its actually 120 secs so dont cahnge it)
-- Tweak these to match the real in-game durations if they differ.
local SPRINKLER_LIFETIME = {
    ["Common Sprinkler"]    = 123,
    ["Uncommon Sprinkler"]  = 123,
    ["Rare Sprinkler"]      = 123,
    ["Legendary Sprinkler"] = 123,
    ["Super Sprinkler"]     = 123,
}


-- Per-type ground Y offset (studs). Different sprinkler MODELS have different
-- heights / pivot points, so one ground Y makes taller ones float and shorter
-- ones sink. Nudge each type here:  + = raise,  - = lower.
-- Start at 0 and tweak the ones that float/sink until they sit on the ground.
local SPRINKLER_Y_OFFSET = {
    ["Common Sprinkler"]    = -1,
    ["Uncommon Sprinkler"]  = -1,
    ["Rare Sprinkler"]      = -1,
    ["Legendary Sprinkler"] = -1,
    ["Super Sprinkler"]     = -1,
}



-- How far (studs) sprinklers are spread out AROUND the saved position, in a
-- circle, so they don't all stack on the same tile. Bigger = wider circle.
-- Kept small so multiple sprinklers stay close together near the saved spot.
local SPRINKLER_CIRCLE_RADIUS = 2.5

-- Returns a position arranged in a CIRCLE around `center`.
--   slot  = which sprinkler this is (1,2,3,...)
--   total = how many sprinklers total (used to space them evenly)
-- slot 1 sits on the center; the rest fan out evenly around the ring.
local function circlePosition(center, slot, total)
    if not center then return center end
    if total <= 1 or slot <= 1 then
        return center
    end
    -- distribute the remaining sprinklers evenly around the ring
    local ringCount = total - 1
    local i         = slot - 2                 -- 0-based index on the ring
    local angle     = (i / ringCount) * math.pi * 2
    local ox        = math.cos(angle) * SPRINKLER_CIRCLE_RADIUS
    local oz        = math.sin(angle) * SPRINKLER_CIRCLE_RADIUS
    return center + Vector3.new(ox, 0, oz)
end





-- state
local sprinklerState = {
    defaultTarget   = 1,
    placementMode   = "Plant Target",
    targetPlant     = "---",

    autoTeleport    = false,
    replaceExpiry   = false,
    systemEnabled   = false,
    savedPosition   = nil,   -- Vector3 saved via "Copy Current Position"
    selection       = {},    -- [name] = { enabled = bool, count = number }
}
for _, n in ipairs(SPRINKLER_TYPES) do
    sprinklerState.selection[n] = { enabled = false, count = 1 }
end


--============================================================
--  SPRINKLER PLACEMENT  (fires the game's placement remote)
--============================================================
-- Packet format (little-endian):
--   u8 = 26  |  u8 = 0  |  f32 X | f32 Y | f32 Z | u8 nameLen | name | u8 = 1
local PlaceRemote = ReplicatedStorage:WaitForChild("SharedModules")
    :WaitForChild("Packet"):WaitForChild("RemoteEvent")

-- Snaps a position down to the ground so sprinklers sit ON the floor,
-- not floating at character-center height. Raycasts downward, ignoring
-- the player's own character.
local function snapToGround(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {}
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    params.FilterDescendantsInstances = filter

    -- start a bit above, shoot far down
    local origin = pos + Vector3.new(0, 5, 0)
    local result = workspace:Raycast(origin, Vector3.new(0, -50, 0), params)
    if result then
        return Vector3.new(pos.X, result.Position.Y, pos.Z)
    end
    -- fallback: HRP is ~3 studs above the ground, so drop by ~3
    return pos - Vector3.new(0, 3, 0)
end

local function buildPlacementBuffer(pos, sprinklerName)

    local nameLen = #sprinklerName
    local buf = buffer.create(16 + nameLen)
    buffer.writeu8(buf, 0, 26)
    buffer.writeu8(buf, 1, 0)
    buffer.writef32(buf, 2, pos.X)
    buffer.writef32(buf, 6, pos.Y)
    buffer.writef32(buf, 10, pos.Z)
    buffer.writeu8(buf, 14, nameLen)
    buffer.writestring(buf, 15, sprinklerName)
    buffer.writeu8(buf, 15 + nameLen, 1)
    return buf
end

-- Finds the sprinkler tool in Backpack OR Character (equipped).
local function findSprinklerTool(sprinklerName)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local t = backpack:FindFirstChild(sprinklerName)
        if t then return t end
    end
    local char = LocalPlayer.Character
    if char then
        local t = char:FindFirstChild(sprinklerName)
        if t then return t end
    end
    return nil
end

-- Equips the tool into the character (many games require the sprinkler to be
-- HELD before the placement remote is accepted). Returns the tool once held.
local function equipTool(sprinklerName)
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    -- already equipped?
    local held = char:FindFirstChild(sprinklerName)
    if held and held:IsA("Tool") then
        return held
    end

    -- pull from backpack and equip
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local tool = backpack and backpack:FindFirstChild(sprinklerName)
    if tool and humanoid then
        humanoid:EquipTool(tool)
        -- wait until it's actually in the character
        local t0 = os.clock()
        repeat task.wait() until char:FindFirstChild(sprinklerName) or (os.clock() - t0) > 1
        return char:FindFirstChild(sprinklerName)
    end
    return tool
end

-- Places one sprinkler (default: "Super Sprinkler") at the given position.
local function placeSprinkler(pos, sprinklerName)
    sprinklerName = sprinklerName or "Super Sprinkler"

    if not pos then
        warn("[Arjhay Hub] placeSprinkler: no position given")
        return false
    end

    -- snap down to the ground so it doesn't float at character-center height,
    -- then apply this sprinkler's per-type Y offset (different models sit at
    -- different heights).
    pos = snapToGround(pos)
    local yOff = SPRINKLER_Y_OFFSET[sprinklerName] or 0
    if yOff ~= 0 then
        pos = pos + Vector3.new(0, yOff, 0)
    end

    -- must own the sprinkler tool; equip it first (held) so the server accepts it


    local tool = equipTool(sprinklerName) or findSprinklerTool(sprinklerName)
    if not tool then
        warn("[Arjhay Hub] No '" .. sprinklerName .. "' found in Backpack/Character")
        return false
    end

    local args = {
        buildPlacementBuffer(pos, sprinklerName),
        { tool },
    }

    local ok, err = pcall(function()
        PlaceRemote:FireServer(unpack(args))
    end)
    if not ok then
        warn("[Arjhay Hub] FireServer failed:", err)
        return false
    end

    print(string.format("[Arjhay Hub] Placed %s at %.1f, %.1f, %.1f (equipped=%s)",
        sprinklerName, pos.X, pos.Y, pos.Z, tostring(tool.Parent and tool.Parent.Name)))
    return true
end




-- Collapsible "Automation Sprinkler" section (click header to expand)
local ap2 = makeCollapsible(ap, "Automation Sprinkler", 1, false)

-- --- Multi-select sprinkler picker: a dropdown-style box that opens a
-- --- FULL-WINDOW popup (like Placement Mode). Each row inside the popup has
-- --- a checkbox + name + amount. The box label shows how many are selected.
local sprinklerBoxLabel  -- forward ref so the popup can refresh the summary text

-- builds the "X selected" summary text for the closed box
local function sprinklerSummary()
    local names = {}
    for _, name in ipairs(SPRINKLER_TYPES) do
        if sprinklerState.selection[name].enabled then
            table.insert(names, name)
        end
    end
    if #names == 0 then
        return "None selected"
    elseif #names == 1 then
        return names[1]
    else
        return #names .. " selected"
    end
end

-- Opens the sprinkler multi-select as a full-window popup panel.
local function openSprinklerPopup()
    local Overlay = Instance.new("Frame")
    Overlay.Name             = "SprinklerPopup"
    Overlay.Size             = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.4
    Overlay.BorderSizePixel  = 0
    Overlay.ZIndex           = 50
    Overlay.Parent           = ScreenGui

    local Panel = Instance.new("Frame")
    Panel.AnchorPoint      = Vector2.new(0.5, 0.5)
    Panel.Position         = UDim2.new(0.5, 0, 0.5, 0)
    Panel.Size             = UDim2.new(0, 520, 0, 400)
    Panel.BackgroundColor3 = Theme.Background
    Panel.BorderSizePixel  = 0
    Panel.ZIndex           = 51
    Panel.Parent           = Overlay
    corner(Panel, 8)
    stroke(Panel, Theme.Stroke, 1)

    -- header
    local Head = Instance.new("Frame")
    Head.Size             = UDim2.new(1, 0, 0, 40)
    Head.BackgroundColor3 = Theme.TopBar
    Head.BorderSizePixel  = 0
    Head.ZIndex           = 52
    Head.Parent           = Panel
    corner(Head, 8)

    local HeadTitle = Instance.new("TextLabel")
    HeadTitle.BackgroundTransparency = 1
    HeadTitle.Position               = UDim2.new(0, 12, 0, 0)
    HeadTitle.Size                   = UDim2.new(1, -110, 1, 0)
    HeadTitle.Font                   = Enum.Font.GothamBold
    HeadTitle.Text                   = "❄  Sprinklers To Place"
    HeadTitle.TextColor3             = Theme.Text
    HeadTitle.TextSize               = 15
    HeadTitle.TextXAlignment         = Enum.TextXAlignment.Left
    HeadTitle.ZIndex                 = 53
    HeadTitle.Parent                 = Head

    local CloseBtn2 = Instance.new("TextButton")
    CloseBtn2.AnchorPoint      = Vector2.new(1, 0.5)
    CloseBtn2.Position         = UDim2.new(1, -10, 0.5, 0)
    CloseBtn2.Size             = UDim2.new(0, 80, 0, 26)
    CloseBtn2.BackgroundColor3 = Theme.Button
    CloseBtn2.Text             = "Close"
    CloseBtn2.Font             = Enum.Font.GothamMedium
    CloseBtn2.TextColor3       = Theme.Text
    CloseBtn2.TextSize         = 13
    CloseBtn2.ZIndex           = 53
    CloseBtn2.Parent           = Head
    corner(CloseBtn2, 6)

    -- scrolling list of sprinkler rows
    local ListScroll = Instance.new("ScrollingFrame")
    ListScroll.Position               = UDim2.new(0, 8, 0, 48)
    ListScroll.Size                   = UDim2.new(1, -16, 1, -92)
    ListScroll.BackgroundTransparency = 1
    ListScroll.BorderSizePixel        = 0
    ListScroll.ScrollBarThickness     = 4
    ListScroll.ScrollBarImageColor3   = Theme.Accent
    ListScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    ListScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    ListScroll.ZIndex                 = 52
    ListScroll.Parent                 = Panel

    local lay = Instance.new("UIListLayout")
    lay.Padding   = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent    = ListScroll

    local popupRows = {}
    for i, name in ipairs(SPRINKLER_TYPES) do
        local row = makeSprinklerSelectRow(ListScroll, name, i, sprinklerState.selection[name])
        row.ZIndex = 53
        for _, d in ipairs(row:GetDescendants()) do
            if d:IsA("GuiObject") then d.ZIndex = 54 end
        end
        popupRows[name] = row
    end

    -- refresh helper for the All/Clear buttons
    local function refreshChecks()
        for _, name in ipairs(SPRINKLER_TYPES) do
            local row = popupRows[name]
            local check = row:FindFirstChildWhichIsA("TextButton")
            if check then
                local on = sprinklerState.selection[name].enabled
                check.BackgroundColor3 = on and Theme.ToggleOn or Theme.ToggleOff
                local t = check:FindFirstChildWhichIsA("TextLabel")
                if t then t.Visible = on end
            end
        end
    end

    -- All / Clear buttons (bottom of the popup)
    local btnHolder = Instance.new("Frame")
    btnHolder.AnchorPoint            = Vector2.new(0.5, 1)
    btnHolder.Position               = UDim2.new(0.5, 0, 1, -8)
    btnHolder.Size                   = UDim2.new(1, -16, 0, 30)
    btnHolder.BackgroundTransparency = 1
    btnHolder.ZIndex                 = 53
    btnHolder.Parent                 = Panel

    local bl = Instance.new("UIListLayout")
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding       = UDim.new(0, 8)
    bl.Parent        = btnHolder

    local function mkBtn(text, color, cb)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0.5, -4, 1, 0)
        b.BackgroundColor3 = Theme.Button
        b.Text             = text
        b.Font             = Enum.Font.GothamMedium
        b.TextColor3       = color
        b.TextSize         = 13
        b.AutoButtonColor  = true
        b.ZIndex           = 54
        b.Parent           = btnHolder
        corner(b, 6)
        stroke(b, Theme.Stroke, 1)
        b.MouseButton1Click:Connect(cb)
    end

    mkBtn("✔  All", Theme.ToggleOn, function()
        for _, name in ipairs(SPRINKLER_TYPES) do
            sprinklerState.selection[name].enabled = true
        end
        refreshChecks()
    end)
    mkBtn("✖  Clear", Theme.Accent, function()
        for _, name in ipairs(SPRINKLER_TYPES) do
            sprinklerState.selection[name].enabled = false
        end
        refreshChecks()
    end)

    CloseBtn2.MouseButton1Click:Connect(function()
        if sprinklerBoxLabel then sprinklerBoxLabel.Text = sprinklerSummary() end
        Overlay:Destroy()
    end)
end

-- The closed "box" (dropdown-style) that opens the popup
local sprinklerBox = Instance.new("TextButton")
sprinklerBox.Name             = "SprinklersToPlace"
sprinklerBox.Size             = UDim2.new(1, 0, 0, 30)
sprinklerBox.LayoutOrder      = 1
sprinklerBox.BackgroundColor3 = Theme.Button
sprinklerBox.Text             = ""
sprinklerBox.AutoButtonColor  = false
sprinklerBox.Parent           = ap2
corner(sprinklerBox, 6)
stroke(sprinklerBox, Theme.Stroke, 1)

sprinklerBoxLabel = Instance.new("TextLabel")
sprinklerBoxLabel.BackgroundTransparency = 1
sprinklerBoxLabel.Position               = UDim2.new(0, 10, 0, 0)
sprinklerBoxLabel.Size                   = UDim2.new(1, -32, 1, 0)
sprinklerBoxLabel.Font                   = Enum.Font.Gotham
sprinklerBoxLabel.Text                   = "❄  Sprinklers To Place"
sprinklerBoxLabel.TextColor3             = Theme.Text
sprinklerBoxLabel.TextSize               = 13
sprinklerBoxLabel.TextXAlignment         = Enum.TextXAlignment.Left
sprinklerBoxLabel.TextTruncate           = Enum.TextTruncate.AtEnd
sprinklerBoxLabel.Parent                 = sprinklerBox

local spChev = Instance.new("TextLabel")
spChev.BackgroundTransparency = 1
spChev.AnchorPoint            = Vector2.new(1, 0.5)
spChev.Position               = UDim2.new(1, -8, 0.5, 0)
spChev.Size                   = UDim2.new(0, 16, 1, 0)
spChev.Font                   = Enum.Font.GothamBold
spChev.Text                   = "⌄"
spChev.TextColor3             = Theme.SubText
spChev.TextSize               = 16
spChev.Parent                 = sprinklerBox

sprinklerBox.MouseButton1Click:Connect(openSprinklerPopup)


makeSectionLabel(ap2, "📍", "Placement Mode", 21)
makeDropdown(ap2, "📍", "Placement Mode", "Plant Target", placementOptions, 22, function(opt)

    sprinklerState.placementMode = opt
    print("[Arjhay Hub] Placement Mode:", opt)
end)

-- Target Plant dropdown (used when Placement Mode = "Plant Target")
makeSectionLabel(ap2, "🌱", "Target Plant", 22.4)
makeDropdown(ap2, "🌱", "Target Plant", "Select a plant...", PLANT_NAMES, 22.5, function(opt)
    sprinklerState.targetPlant = opt
    print("[Arjhay Hub] Target Plant:", opt)
end)


-- Saved Position label + "Copy Current Position" button
local savedPosLabel = makeSectionLabel(ap2, "📌", "Saved Position: Not set", 23)
do
    local btn = Instance.new("TextButton")
    btn.Name             = "CopyCurrentPosition"
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.LayoutOrder      = 24
    btn.BackgroundColor3 = Theme.Button
    btn.Text             = "📌  Copy Current Position"
    btn.Font             = Enum.Font.GothamMedium
    btn.TextColor3       = Theme.Text
    btn.TextSize         = 13
    btn.AutoButtonColor  = true
    btn.Parent           = ap2
    corner(btn, 6)
    stroke(btn, Theme.Stroke, 1)

    btn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            sprinklerState.savedPosition = hrp.Position
            local p = hrp.Position
            savedPosLabel.Text = string.format("📌  Saved Position: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
            print("[Arjhay Hub] Saved Position:", p)
        else
            savedPosLabel.Text = "📌  Saved Position: (character not found)"
        end
    end)
end

makeIconToggle(ap2, "🚀", "Auto Teleport", 25, function(on)
    sprinklerState.autoTeleport = on
    print("[Arjhay Hub] Auto Teleport:", on)
end)
makeIconToggle(ap2, "♻", "Replace Near Expiry (auto refresh)", 26, function(on)

    sprinklerState.replaceExpiry = on
    print("[Arjhay Hub] Replace Near Expiry:", on)
end)

-- forward declaration (used by the maintenance / system loops)
local placeSelectedOnce

--============================================================

--  AUTO SPRINKLER LOOP
--============================================================

-- Tracks placed sprinklers so "Replace Near Expiry" can re-place them.
-- placed[name] = { {expireAt=os.clock()+life}, ... }
local placed = {}

-- Master switch. When the window is closed (X), this becomes false and ALL
-- auto features stop (maintenance loop + system loop exit).
local guiAlive = true


-- Finds the NEAREST plant in the world matching the chosen Target Plant name.
-- Searches common plant containers (your farm / the workspace) for a model or
-- part whose name matches, and returns the closest one's world position.
local function findPlantPosition(plantName)
    if not plantName or plantName == "---" or plantName == "Select a plant..." then
        return nil
    end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local origin = hrp and hrp.Position or Vector3.new(0, 0, 0)

    local target = string.lower(plantName)

    local function getPos(inst)
        if inst:IsA("BasePart") then
            return inst.Position
        elseif inst:IsA("Model") then
            local ok, cf = pcall(function() return inst:GetPivot() end)
            if ok and cf then return cf.Position end
            if inst.PrimaryPart then return inst.PrimaryPart.Position end
            -- last resort: average the parts
            local sum, n = Vector3.new(), 0
            for _, p in ipairs(inst:GetDescendants()) do
                if p:IsA("BasePart") then sum = sum + p.Position; n = n + 1 end
            end
            if n > 0 then return sum / n end
        end
        return nil
    end


    -- The planted model in the world is usually NOT named after the plant —
    -- it's often named by a unique ID, with the real seed name stored in an
    -- ATTRIBUTE (e.g. "Plant", "PlantName", "Type", "Seed") or in a child
    -- StringValue. So we match against ALL of: the instance name, its
    -- attributes, and any StringValue children.
    local function nameMatches(inst)
        -- 1) the instance's own name
        local iname = string.lower(inst.Name)
        if iname == target then return "exact" end

        -- 2) attributes
        local ok, attrs = pcall(function() return inst:GetAttributes() end)
        if ok and attrs then
            for _, v in pairs(attrs) do
                if type(v) == "string" and string.lower(v) == target then
                    return "exact"
                end
            end
        end

        -- 3) a StringValue child holding the name (common pattern)
        for _, ch in ipairs(inst:GetChildren()) do
            if (ch:IsA("StringValue") or ch:IsA("ObjectValue")) then
                if type(ch.Value) == "string" and string.lower(ch.Value) == target then
                    return "exact"
                end
            end
        end

        -- 4) loose contains-match on the instance name
        if string.find(iname, target, 1, true) then return "loose" end
        return nil
    end

    local exactInst, exactDist = nil, math.huge
    local looseInst, looseDist = nil, math.huge
    local exactCount = 0

    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("Model") or inst:IsA("BasePart") then
            local kind = nameMatches(inst)
            if kind then
                local pos = getPos(inst)
                if pos then
                    local d = (pos - origin).Magnitude
                    if kind == "exact" then
                        exactCount = exactCount + 1
                        if d < exactDist then exactInst, exactDist = inst, d end
                    else
                        if d < looseDist then looseInst, looseDist = inst, d end
                    end
                end
            end
        end
    end

    local best = exactInst or looseInst
    if best then
        local pos = getPos(best)
        print(string.format(
            "[Arjhay Hub] Plant '%s' -> %s (%s) | exactMatches=%d | dist=%.1f | pos %.1f, %.1f, %.1f",
            plantName, best:GetFullName(), best.ClassName, exactCount,
            (pos - origin).Magnitude, pos.X, pos.Y, pos.Z))
        return pos
    end

    -- Still nothing. As a last resort, use the closest plant to the character
    -- so at least it places near SOME plant, and log nearby plant names so we
    -- can learn the real naming/structure.
    warn("[Arjhay Hub] Plant '" .. plantName .. "' NOT found by name/attribute. "
        .. "Listing nearby workspace models to help identify the structure:")
    local nearby = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("Model") then
            local pos = getPos(inst)
            if pos then
                local d = (pos - origin).Magnitude
                if d < 25 then
                    table.insert(nearby, { name = inst:GetFullName(), d = d })
                end
            end
        end
    end
    table.sort(nearby, function(a, b) return a.d < b.d end)
    for i = 1, math.min(#nearby, 15) do
        print(string.format("   near[%d] %.1f studs : %s", i, nearby[i].d, nearby[i].name))
    end
    return nil
end





-- Returns the position to place at.
-- Prefers the Saved Position when one exists (unless a live mode is chosen),
-- otherwise falls back to the current character position.
local function getPlacePosition()
    local mode = sprinklerState.placementMode

    -- Plant Target: find the chosen plant in the world and use its position
    if mode == "Plant Target" then
        local plantPos = findPlantPosition(sprinklerState.targetPlant)
        if plantPos then
            return plantPos
        end
        warn("[Arjhay Hub] Plant Target: couldn't find '" ..
            tostring(sprinklerState.targetPlant) .. "' — falling back to character position.")
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        return hrp and hrp.Position or sprinklerState.savedPosition
    end

    -- live modes always use the current character position
    if mode == "Default Placement" and sprinklerState.savedPosition then
        return sprinklerState.savedPosition
    end
    if mode == "Saved Position" then
        return sprinklerState.savedPosition
    end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or sprinklerState.savedPosition
end


-- Place one sprinkler of a type + record it (with its ground position) so
-- "Replace Near Expiry" can re-place it later at the SAME spot.
local function placeAndTrack(name, pos)
    -- Teleport if Auto Teleport is on, OR if we're in Plant Target mode.
    -- (Plant Target ALWAYS needs the character near the plant, otherwise the
    --  server rejects the placement because you're too far away.)
    if sprinklerState.autoTeleport or sprinklerState.placementMode == "Plant Target" then
        smoothTeleport(pos)          -- smooth tween (not fast)
    end
    local groundPos = snapToGround(pos)

    if placeSprinkler(groundPos, name) then
        placed[name] = placed[name] or {}
        local life = SPRINKLER_LIFETIME[name] or 60
        table.insert(placed[name], { expireAt = os.clock() + life, pos = groundPos })
        return true
    end
    return false
end

-- Places every checked sprinkler once, at the current placement position.
-- Returns how many were actually placed (also tracks them for expiry replace).
-- (assigns to the forward-declared local above)
placeSelectedOnce = function()
    local pos = getPlacePosition()

    if not pos then
        warn("[Arjhay Hub] No position — copy a position or move your character first.")
        return 0
    end
    local total = 0
    local anyChecked = false
    for _, name in ipairs(SPRINKLER_TYPES) do
        local entry = sprinklerState.selection[name]
        if entry.enabled then
            anyChecked = true
            for _ = 1, math.max(entry.count, 1) do
                if placeAndTrack(name, pos) then total = total + 1 end
                task.wait(0.5)
            end
        end
    end
    if not anyChecked then
        warn("[Arjhay Hub] No sprinkler checked — tick a box first (e.g. Super Sprinkler).")
    end
    return total
end

--============================================================
--  MAINTENANCE LOOP  (Replace Near Expiry) — always running.
--  Re-places a tracked sprinkler AFTER it expires (the tile is only free
--  once the old one is gone; trying earlier gets rejected and the tool
--  just stays held). Waits ~1s past expiry, then re-places at the SAME
--  ground spot. Independent of the system toggle, so it also refreshes
--  Test-placed sprinklers.
--============================================================
task.spawn(function()
    while guiAlive do
        if sprinklerState.replaceExpiry then

            local now = os.clock()
            for _, name in ipairs(SPRINKLER_TYPES) do
                local list = placed[name]
                if list then
                    -- snapshot the current records so newly re-placed ones
                    -- (appended during this pass) aren't processed again here.
                    local snapshot = {}
                    for i = 1, #list do snapshot[i] = list[i] end

                    for _, rec in ipairs(snapshot) do
                        -- only re-place once the old one has actually expired
                        -- (+1s grace so the server has cleared the tile)
                        if now >= (rec.expireAt + 1) then
                            local spot = snapToGround(rec.pos or getPlacePosition())

                            -- Re-place with RETRIES. When 2+ sprinklers expire
                            -- together, the second placement can be rejected
                            -- (tile not cleared yet / tool not re-equipped in
                            -- time), so we try several times with waits until
                            -- it actually goes down.
                            local success = false
                            for attempt = 1, 5 do
                                -- make sure the correct tool is equipped first
                                equipTool(name)
                                task.wait(0.25)
                                if placeSprinkler(spot, name) then
                                    success = true
                                    break
                                end
                                task.wait(0.6)  -- wait before the next attempt
                            end

                            if success then
                                -- remove the specific old record
                                for i = #list, 1, -1 do
                                    if list[i] == rec then
                                        table.remove(list, i)
                                        break
                                    end
                                end
                                -- track the freshly placed one
                                local life = SPRINKLER_LIFETIME[name] or 60
                                table.insert(list, { expireAt = os.clock() + life, pos = spot })
                            else
                                -- still failed after retries: try again next pass
                                rec.expireAt = os.clock()
                            end
                            task.wait(0.6)
                        end
                    end

                end
            end

        end
        task.wait(1)
    end
end)



makeIconToggle(ap2, "⚡", "Enable Sprinkler System", 27, function(on)
    sprinklerState.systemEnabled = on
    print("[Arjhay Hub] Sprinkler System:", on and "ON" or "OFF")
    if not on then
        -- FULL STOP: clear tracked sprinklers so the maintenance loop
        -- (Replace Near Expiry) stops re-placing them.
        for k in pairs(placed) do placed[k] = nil end
        -- restore collision unless the watering system still needs noclip
        if not wateringState.systemEnabled then setNoclip(false) end
        return
    end



    task.spawn(function()
        -- Initial placement pass: place each selected sprinkler its count times.
        -- (Refreshing on expiry is handled by the always-on maintenance loop
        --  above, as long as "Replace Near Expiry" is toggled on.)
        local center = getPlacePosition()
        if not center then
            warn("[Arjhay Hub] No position available — set Placement Mode or Saved Position.")
            return
        end

        -- count how many sprinklers total so we can space them in a circle
        local total = 0
        for _, name in ipairs(SPRINKLER_TYPES) do
            local entry = sprinklerState.selection[name]
            if entry.enabled and entry.count > 0 then
                total = total + entry.count
            end
        end

        -- place each one at its own slot AROUND the saved position (circle)
        local slot = 1
        for _, name in ipairs(SPRINKLER_TYPES) do
            local entry = sprinklerState.selection[name]
            if entry.enabled and entry.count > 0 then
                for _ = 1, entry.count do
                    if not sprinklerState.systemEnabled then break end
                    local spot = circlePosition(center, slot, total)
                    placeAndTrack(name, spot)
                    slot = slot + 1
                    task.wait(0.6)
                end
            end
        end
    end)

end)






--============================================================
--  AUTOMATION WATERING CAN
--============================================================
-- Watering can packet (from your dump):
--   u8 = 73 ("I") | u8 = 0 | f32 X | f32 Y | f32 Z | u8 nameLen | name
-- (note: NO trailing byte, unlike the sprinkler packet)
local WATERING_TYPES = {
    "Common Watering Can",
    "Super Watering Can",
}

local function buildWateringBuffer(pos, name)
    local nameLen = #name
    local buf = buffer.create(15 + nameLen)
    buffer.writeu8(buf, 0, 73)   -- "I"
    buffer.writeu8(buf, 1, 0)
    buffer.writef32(buf, 2, pos.X)
    buffer.writef32(buf, 6, pos.Y)
    buffer.writef32(buf, 10, pos.Z)
    buffer.writeu8(buf, 14, nameLen)
    buffer.writestring(buf, 15, name)
    return buf
end

-- Uses one watering can (equips it first, then fires the remote at pos).
local function useWateringCan(pos, name)
    name = name or "Super Watering Can"
    if not pos then
        warn("[Arjhay Hub] useWateringCan: no position given")
        return false
    end
    pos = snapToGround(pos)

    local tool = equipTool(name) or findSprinklerTool(name)
    if not tool then
        warn("[Arjhay Hub] No '" .. name .. "' found in Backpack/Character")
        return false
    end

    local args = {
        buildWateringBuffer(pos, name),
        { tool },
    }
    local ok, err = pcall(function()
        PlaceRemote:FireServer(unpack(args))
    end)
    if not ok then
        warn("[Arjhay Hub] Watering FireServer failed:", err)
        return false
    end

    print(string.format("[Arjhay Hub] Watered with %s at %.1f, %.1f, %.1f",
        name, pos.X, pos.Y, pos.Z))
    return true
end

-- Resolves a placement position from a mode/plant/saved-position (generic,
-- reused by the watering system).
local function resolvePosition(mode, targetPlant, savedPosition)
    if mode == "Plant Target" then
        local plantPos = findPlantPosition(targetPlant)
        if plantPos then return plantPos end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        return hrp and hrp.Position or savedPosition
    end
    if mode == "Saved Position" then
        return savedPosition
    end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or savedPosition
end

-- state
local wateringState = {
    placementMode = "Plant Target",
    targetPlant   = "---",
    autoTeleport  = false,
    delay         = 25,        -- seconds between each watering can use
    systemEnabled = false,
    savedPosition = nil,
    selection     = {},       -- [name] = { enabled = bool, count = number }
}
for _, n in ipairs(WATERING_TYPES) do
    wateringState.selection[n] = { enabled = false, count = 1 }
end

-- Collapsible "Automation Watering Can" section
local aw = makeCollapsible(ap, "Automation Watering Can", 2, false)

-- --- Multi-select watering-can picker: a dropdown-style box that opens a
-- --- FULL-WINDOW popup (same style as the sprinkler picker).
local wateringBoxLabel  -- forward ref so the popup can refresh the summary text

local function wateringSummary()
    local names = {}
    for _, name in ipairs(WATERING_TYPES) do
        if wateringState.selection[name].enabled then
            table.insert(names, name)
        end
    end
    if #names == 0 then
        return "💧  Watering Cans To Use"
    elseif #names == 1 then
        return names[1]
    else
        return #names .. " selected"
    end
end

-- Opens the watering-can multi-select as a full-window popup panel.
local function openWateringPopup()
    local Overlay = Instance.new("Frame")
    Overlay.Name             = "WateringPopup"
    Overlay.Size             = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.4
    Overlay.BorderSizePixel  = 0
    Overlay.ZIndex           = 50
    Overlay.Parent           = ScreenGui

    local Panel = Instance.new("Frame")
    Panel.AnchorPoint      = Vector2.new(0.5, 0.5)
    Panel.Position         = UDim2.new(0.5, 0, 0.5, 0)
    Panel.Size             = UDim2.new(0, 520, 0, 400)
    Panel.BackgroundColor3 = Theme.Background
    Panel.BorderSizePixel  = 0
    Panel.ZIndex           = 51
    Panel.Parent           = Overlay
    corner(Panel, 8)
    stroke(Panel, Theme.Stroke, 1)

    -- header
    local Head = Instance.new("Frame")
    Head.Size             = UDim2.new(1, 0, 0, 40)
    Head.BackgroundColor3 = Theme.TopBar
    Head.BorderSizePixel  = 0
    Head.ZIndex           = 52
    Head.Parent           = Panel
    corner(Head, 8)

    local HeadTitle = Instance.new("TextLabel")
    HeadTitle.BackgroundTransparency = 1
    HeadTitle.Position               = UDim2.new(0, 12, 0, 0)
    HeadTitle.Size                   = UDim2.new(1, -110, 1, 0)
    HeadTitle.Font                   = Enum.Font.GothamBold
    HeadTitle.Text                   = "💧  Watering Cans To Use"
    HeadTitle.TextColor3             = Theme.Text
    HeadTitle.TextSize               = 15
    HeadTitle.TextXAlignment         = Enum.TextXAlignment.Left
    HeadTitle.ZIndex                 = 53
    HeadTitle.Parent                 = Head

    local CloseBtn2 = Instance.new("TextButton")
    CloseBtn2.AnchorPoint      = Vector2.new(1, 0.5)
    CloseBtn2.Position         = UDim2.new(1, -10, 0.5, 0)
    CloseBtn2.Size             = UDim2.new(0, 80, 0, 26)
    CloseBtn2.BackgroundColor3 = Theme.Button
    CloseBtn2.Text             = "Close"
    CloseBtn2.Font             = Enum.Font.GothamMedium
    CloseBtn2.TextColor3       = Theme.Text
    CloseBtn2.TextSize         = 13
    CloseBtn2.ZIndex           = 53
    CloseBtn2.Parent           = Head
    corner(CloseBtn2, 6)

    -- scrolling list of watering-can rows
    local ListScroll = Instance.new("ScrollingFrame")
    ListScroll.Position               = UDim2.new(0, 8, 0, 48)
    ListScroll.Size                   = UDim2.new(1, -16, 1, -92)
    ListScroll.BackgroundTransparency = 1
    ListScroll.BorderSizePixel        = 0
    ListScroll.ScrollBarThickness     = 4
    ListScroll.ScrollBarImageColor3   = Theme.Accent
    ListScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    ListScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    ListScroll.ZIndex                 = 52
    ListScroll.Parent                 = Panel

    local lay = Instance.new("UIListLayout")
    lay.Padding   = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent    = ListScroll

    local popupRows = {}
    for i, name in ipairs(WATERING_TYPES) do
        local row = makeSprinklerSelectRow(ListScroll, name, i, wateringState.selection[name])
        row.ZIndex = 53
        for _, d in ipairs(row:GetDescendants()) do
            if d:IsA("GuiObject") then d.ZIndex = 54 end
        end
        popupRows[name] = row
    end

    local function refreshChecks()
        for _, name in ipairs(WATERING_TYPES) do
            local row = popupRows[name]
            local check = row:FindFirstChildWhichIsA("TextButton")
            if check then
                local on = wateringState.selection[name].enabled
                check.BackgroundColor3 = on and Theme.ToggleOn or Theme.ToggleOff
                local t = check:FindFirstChildWhichIsA("TextLabel")
                if t then t.Visible = on end
            end
        end
    end

    -- All / Clear buttons (bottom of the popup)
    local btnHolder = Instance.new("Frame")
    btnHolder.AnchorPoint            = Vector2.new(0.5, 1)
    btnHolder.Position               = UDim2.new(0.5, 0, 1, -8)
    btnHolder.Size                   = UDim2.new(1, -16, 0, 30)
    btnHolder.BackgroundTransparency = 1
    btnHolder.ZIndex                 = 53
    btnHolder.Parent                 = Panel

    local bl = Instance.new("UIListLayout")
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding       = UDim.new(0, 8)
    bl.Parent        = btnHolder

    local function mkBtn(text, color, cb)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0.5, -4, 1, 0)
        b.BackgroundColor3 = Theme.Button
        b.Text             = text
        b.Font             = Enum.Font.GothamMedium
        b.TextColor3       = color
        b.TextSize         = 13
        b.AutoButtonColor  = true
        b.ZIndex           = 54
        b.Parent           = btnHolder
        corner(b, 6)
        stroke(b, Theme.Stroke, 1)
        b.MouseButton1Click:Connect(cb)
    end

    mkBtn("✔  All", Theme.ToggleOn, function()
        for _, name in ipairs(WATERING_TYPES) do
            wateringState.selection[name].enabled = true
        end
        refreshChecks()
    end)
    mkBtn("✖  Clear", Theme.Accent, function()
        for _, name in ipairs(WATERING_TYPES) do
            wateringState.selection[name].enabled = false
        end
        refreshChecks()
    end)

    CloseBtn2.MouseButton1Click:Connect(function()
        if wateringBoxLabel then wateringBoxLabel.Text = wateringSummary() end
        Overlay:Destroy()
    end)
end

-- The closed "box" (dropdown-style) that opens the popup
local wateringBox = Instance.new("TextButton")
wateringBox.Name             = "WateringCansToUse"
wateringBox.Size             = UDim2.new(1, 0, 0, 30)
wateringBox.LayoutOrder      = 1
wateringBox.BackgroundColor3 = Theme.Button
wateringBox.Text             = ""
wateringBox.AutoButtonColor  = false
wateringBox.Parent           = aw
corner(wateringBox, 6)
stroke(wateringBox, Theme.Stroke, 1)

wateringBoxLabel = Instance.new("TextLabel")
wateringBoxLabel.BackgroundTransparency = 1
wateringBoxLabel.Position               = UDim2.new(0, 10, 0, 0)
wateringBoxLabel.Size                   = UDim2.new(1, -32, 1, 0)
wateringBoxLabel.Font                   = Enum.Font.Gotham
wateringBoxLabel.Text                   = "💧  Watering Cans To Use"
wateringBoxLabel.TextColor3             = Theme.Text
wateringBoxLabel.TextSize               = 13
wateringBoxLabel.TextXAlignment         = Enum.TextXAlignment.Left
wateringBoxLabel.TextTruncate           = Enum.TextTruncate.AtEnd
wateringBoxLabel.Parent                 = wateringBox

local wChev = Instance.new("TextLabel")
wChev.BackgroundTransparency = 1
wChev.AnchorPoint            = Vector2.new(1, 0.5)
wChev.Position               = UDim2.new(1, -8, 0.5, 0)
wChev.Size                   = UDim2.new(0, 16, 1, 0)
wChev.Font                   = Enum.Font.GothamBold
wChev.Text                   = "⌄"
wChev.TextColor3             = Theme.SubText
wChev.TextSize               = 16
wChev.Parent                 = wateringBox

wateringBox.MouseButton1Click:Connect(openWateringPopup)


-- Placement Mode
makeSectionLabel(aw, "📍", "Placement Mode", 10)
makeDropdown(aw, "📍", "Placement Mode", "Plant Target", placementOptions, 11, function(opt)
    wateringState.placementMode = opt
    print("[Arjhay Hub] Watering Placement Mode:", opt)
end)

-- Target Plant
makeSectionLabel(aw, "🌱", "Target Plant", 12)
makeDropdown(aw, "🌱", "Target Plant", "Select a plant...", PLANT_NAMES, 13, function(opt)
    wateringState.targetPlant = opt
    print("[Arjhay Hub] Watering Target Plant:", opt)
end)

-- Saved Position + Copy button
local wSavedLabel = makeSectionLabel(aw, "📌", "Saved Position: Not set", 14)
do
    local btn = Instance.new("TextButton")
    btn.Name             = "WCopyCurrentPosition"
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.LayoutOrder      = 15
    btn.BackgroundColor3 = Theme.Button
    btn.Text             = "📌  Copy Current Position"
    btn.Font             = Enum.Font.GothamMedium
    btn.TextColor3       = Theme.Text
    btn.TextSize         = 13
    btn.AutoButtonColor  = true
    btn.Parent           = aw
    corner(btn, 6)
    stroke(btn, Theme.Stroke, 1)
    btn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            wateringState.savedPosition = hrp.Position
            local p = hrp.Position
            wSavedLabel.Text = string.format("📌  Saved Position: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
        else
            wSavedLabel.Text = "📌  Saved Position: (character not found)"
        end
    end)
end

-- Delay (seconds per watering can)
makeSectionLabel(aw, "⏱", "Delay (seconds per watering can)", 16)
makeNumberInput(aw, 1, 17, function(n)
    wateringState.delay = math.max(n, 0)
    print("[Arjhay Hub] Watering delay:", wateringState.delay)
end)

makeIconToggle(aw, "🚀", "Auto Teleport", 18, function(on)
    wateringState.autoTeleport = on
    print("[Arjhay Hub] Watering Auto Teleport:", on)
end)

makeIconToggle(aw, "⚡", "Enable Watering System", 19, function(on)
    wateringState.systemEnabled = on
    print("[Arjhay Hub] Watering System:", on and "ON" or "OFF")
    if not on then
        -- restore collision unless the sprinkler system still needs noclip
        if not sprinklerState.systemEnabled then setNoclip(false) end
        return
    end


    task.spawn(function()
        while wateringState.systemEnabled and guiAlive do
            local pos = resolvePosition(
                wateringState.placementMode,
                wateringState.targetPlant,
                wateringState.savedPosition
            )
            if not pos then
                warn("[Arjhay Hub] Watering: no position — set a Target Plant or Saved Position.")
                task.wait(1)
            else
                local anyChecked = false
                for _, name in ipairs(WATERING_TYPES) do
                    local entry = wateringState.selection[name]
                    if entry.enabled and entry.count > 0 then
                        anyChecked = true
                        for _ = 1, entry.count do
                            if not (wateringState.systemEnabled and guiAlive) then break end
                            -- teleport to the plant if needed
                            if wateringState.autoTeleport
                            or wateringState.placementMode == "Plant Target" then
                                smoothTeleport(pos)
                            end
                            useWateringCan(pos, name)
                            task.wait(wateringState.delay)
                        end
                    end
                end
                if not anyChecked then
                    warn("[Arjhay Hub] Watering: no watering can checked — tick one first.")
                    task.wait(1)
                end
            end
        end
    end)
end)

--============================================================
--  MAIN TAB  →  FRUIT COLLECT
--============================================================
local fruitPage = pages["Main"]

-- Known mutation + variant lists (from the game / your screenshots)
local MUTATION_LIST = {
    "Aurora", "Bloodlit", "Chained", "Eclipsed", "Electric", "Frozen",
    "Glow", "Ignited", "Pizza", "Solarflare", "Starstruck", "Veil",
}
local VARIANT_LIST = {
    "Normal", "Gold", "Rainbow",
}

-- forward declaration — defined later in the Sell section, but the Fruit
-- Collector's "Stop When Backpack Full" needs to call it.
local isBackpackFull

-- state
local fruitState = {
    targetFruits   = {},        -- set: [fruitNameLower]=true  (empty = collect all)
    useFruitFilter = false,     -- when OFF, collect anything regardless of filters
    autoTeleport   = false,
    gardenPos      = nil,       -- saved garden spot to tween back to
    fastCollector  = false,

    stopWhenFull   = false,     -- stop collecting while the backpack is full
    collectDelay   = 0,         -- seconds to wait between each fruit collect
    minWeight      = 0,
    maxWeight      = 150,
    onlyMutations  = {},        -- set: [mutation]=true  (empty = allow all)
    onlyVariants   = {},        -- set: [variant]=true   (empty = allow all)
    protectVariants= {},        -- set: [variant]=true   (never collect these)
}



-- The list of collectable fruit TYPE names. Built from the game's SEED DATA
-- (the same PLANT_NAMES list loaded from ReplicatedStorage.Assets.Plants),
-- so it always matches the real fruit/plant names. "---" = collect everything.
local FRUIT_NAMES = { "---" }
for _, n in ipairs(PLANT_NAMES) do
    table.insert(FRUIT_NAMES, n)
end

-- Try to detect the fruit-collect remote once (falls back to ProximityPrompt).
local CollectRemote = nil
do
    local shared = ReplicatedStorage:FindFirstChild("SharedModules")
    if shared then
        local packet = shared:FindFirstChild("Packet")
        if packet then
            -- some games expose a dedicated collect remote here
            CollectRemote = packet:FindFirstChild("CollectFruit")
                or packet:FindFirstChild("Collect")
        end
    end
end

--// Reads a fruit's weight from common attribute names. Returns number or nil.
local function getFruitWeight(inst)
    if not inst then return nil end   -- guard: prompt may have no model/part
    for _, key in ipairs({ "Weight", "weight", "KG", "Kg", "Mass" }) do

        local ok, v = pcall(function() return inst:GetAttribute(key) end)
        if ok and type(v) == "number" then return v end
    end
    -- a NumberValue child?
    local nv = inst:FindFirstChild("Weight")
    if nv and nv:IsA("NumberValue") then return nv.Value end
    return nil
end

--// Reads a fruit's mutation(s) as a set of lowercase names.
local function getFruitMutations(inst)
    local out = {}
    for _, key in ipairs({ "Mutation", "Mutations", "mutation" }) do
        local ok, v = pcall(function() return inst:GetAttribute(key) end)
        if ok and type(v) == "string" and v ~= "" then
            for word in string.gmatch(v, "[^,%s]+") do
                out[string.lower(word)] = true
            end
        end
    end
    return out
end

--// Reads a fruit's variant (Normal/Gold/Rainbow) as lowercase, or "normal".
local function getFruitVariant(inst)
    for _, key in ipairs({ "Variant", "variant", "Type", "Rarity" }) do
        local ok, v = pcall(function() return inst:GetAttribute(key) end)
        if ok and type(v) == "string" and v ~= "" then
            return string.lower(v)
        end
    end
    return "normal"
end

--// Is this instance a collectable fruit? (has a weight attribute, or lives in
--// a folder/attribute that marks it as fruit). Kept permissive.
local function isFruit(inst)
    if not (inst:IsA("Model") or inst:IsA("BasePart")) then return false end
    if getFruitWeight(inst) ~= nil then return true end
    local ok, v = pcall(function() return inst:GetAttribute("Fruit") end)
    if ok and v ~= nil then return true end
    return false
end

--// Counts how many keys are in a set table.
local function setCount(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

--// Decides whether a fruit passes ALL the current filters.
local function fruitPassesFilters(inst)
    -- weight
    local w = getFruitWeight(inst)
    if w ~= nil then
        if w < fruitState.minWeight or w > fruitState.maxWeight then
            return false
        end
    end

    -- variant protection (never collect protected variants)
    local variant = getFruitVariant(inst)
    if fruitState.protectVariants[variant] then
        return false
    end

    -- only-variants (if any selected, fruit's variant must be in the set)
    if setCount(fruitState.onlyVariants) > 0 then
        if not fruitState.onlyVariants[variant] then return false end
    end

    -- only-mutations (if any selected, fruit must have at least one)
    if setCount(fruitState.onlyMutations) > 0 then
        local muts = getFruitMutations(inst)
        local match = false
        for m in pairs(fruitState.onlyMutations) do
            if muts[m] then match = true break end
        end
        if not match then return false end
    end

    return true
end

--// Fires a ProximityPrompt to harvest (this game uses the "E — Harvest"
--// prompt, as seen in-game).
--
-- IMPORTANT (regrow fix): a freshly-grown fruit's prompt is often DISABLED,
-- requires line-of-sight, or has a small activation distance — so a plain
-- fireproximityprompt() call silently does nothing and it looks like the
-- collector "stops working" after the first harvest. So before firing we force
-- the prompt into a fireable state every time:
--   * Enabled              = true
--   * RequiresLineOfSight  = false
--   * MaxActivationDistance = huge
--   * HoldDuration         = 0   (instant)
-- Then we fire it (twice, tiny gap) to be safe.
local function firePrompt(prompt)
    pcall(function()
        prompt.Enabled              = true
        prompt.RequiresLineOfSight  = false
        prompt.MaxActivationDistance = 1e9
        prompt.HoldDuration         = 0
    end)
    local ok = pcall(function()
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
            fireproximityprompt(prompt)   -- fire again in case the first was eaten
        end
    end)
    return ok == true
end


--// Is this a harvest/collect ProximityPrompt?
local function isHarvestPrompt(p)
    if not p:IsA("ProximityPrompt") then return false end
    local a = string.lower(p.ActionText or "")
    local o = string.lower(p.ObjectText or "")
    local n = string.lower(p.Name or "")
    return string.find(a, "harvest", 1, true) ~= nil
        or string.find(a, "collect", 1, true) ~= nil
        or string.find(o, "harvest", 1, true) ~= nil
        or string.find(n, "harvest", 1, true) ~= nil
        or string.find(n, "collect", 1, true) ~= nil
end

--// Given a harvest prompt, find the plant/fruit MODEL it belongs to.
local function promptModel(prompt)
    return prompt:FindFirstAncestorWhichIsA("Model") or prompt.Parent
end

--// Reads the fruit NAME and WEIGHT for a prompt by scanning the BillboardGui
--// text labels above the plant (e.g. "Blueberry" + "2.05kg"). Falls back to
--// attributes / the model name. Returns (nameStringLower, weightNumber|nil).
-- Normalises a name for comparison: lowercase, letters+digits only.
-- "Dragon's Breath" / "dragons breath" / "Dragon Breath" all collapse to
-- "dragonsbreath" / "dragonbreath", so the apostrophe can't break a match.
-- Stored on fruitState (not as new locals) to stay clear of Luau's 200-local
-- limit in the main chunk.
fruitState.norm = function(s)
    return (string.gsub(string.lower(s or ""), "[^%a%d]", ""))
end

-- Resolves the REAL seed name for a harvest prompt.
--
-- THIS IS THE FRUIT-COLLECTOR FIX. The old code only looked at billboard
-- TextLabels and then fell back to `model.Name` — but a planted crop's model is
-- named with a UUID (Gardens > Plot# > Plants > <uuid>), never the seed. So for
-- any fruit whose billboard wasn't currently rendered (which is most of them,
-- and ALL of them with Remove Plants on) the "name" was a UUID, so picking
-- "Dragon's Breath" in the filter matched nothing and collected nothing.
--
-- Order of preference, most reliable first:
--   1. the prompt's own ObjectText/ActionText ("Dragon's Breath 68.24kg") —
--      part of the crop, so it replicates and needs no proximity
--   2. Plant/PlantName/Seed/SeedName attributes on the prompt's ancestors
--   3. a StringValue holding a known plant name
--   4. billboard text (only present when rendered nearby)
fruitState.resolveName = function(prompt, model)
    -- 1) prompt text
    for _, s in ipairs({ prompt.ObjectText, prompt.ActionText }) do
        if type(s) == "string" and s ~= "" then
            local cleaned = s:gsub("[%d%.]+%s*[kK][gG]", "")
                             :gsub("^%s+", ""):gsub("%s+$", "")
            -- ignore the generic verb-only prompt text ("Harvest")
            local nc = fruitState.norm(cleaned)
            if nc ~= "" and nc ~= "harvest" and nc ~= "collect" then
                return cleaned
            end
        end
    end

    -- 2) attributes on the prompt's ancestor chain (the crop model)
    local a, depth = model or prompt.Parent, 0
    while a and depth < 8 do
        for _, key in ipairs({ "Plant", "PlantName", "Seed", "SeedName",
                               "Type", "Species" }) do
            local ok, v = pcall(function() return a:GetAttribute(key) end)
            if ok and type(v) == "string" and v ~= "" then return v end
        end
        -- 3) a StringValue child naming the plant
        for _, ch in ipairs(a:GetChildren()) do
            if ch:IsA("StringValue") and type(ch.Value) == "string"
            and ch.Value ~= "" then
                for _, pn in ipairs(PLANT_NAMES) do
                    if fruitState.norm(pn) == fruitState.norm(ch.Value) then
                        return ch.Value
                    end
                end
            end
        end
        a = a.Parent
        depth = depth + 1
    end

    return nil
end

local function readPromptInfo(prompt)
    local model = promptModel(prompt)
    local nameText, weight

    -- the prompt itself usually carries BOTH the name and the kg
    nameText = fruitState.resolveName(prompt, model)
    for _, s in ipairs({ prompt.ObjectText, prompt.ActionText }) do
        if type(s) == "string" and s ~= "" then
            local w = tonumber(s:match("([%d%.]+)%s*[kK][gG]") or "")
            if w and not weight then weight = w end
        end
    end

    local root = model
    -- widen the search a little: also look at the prompt's parent part
    local searchRoots = { root }
    if prompt.Parent and prompt.Parent ~= root then
        table.insert(searchRoots, prompt.Parent)
    end

    for _, r in ipairs(searchRoots) do
        if r then
            for _, d in ipairs(r:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    local t = d.Text
                    if t and t ~= "" then
                        -- weight like "2.05kg" / "2.05 KG"
                        local w = t:match("([%d%.]+)%s*[kK][gG]")
                        if w and not weight then weight = tonumber(w) end
                        -- name = the text with any weight/kg stripped out
                        local cleaned = t:gsub("[%d%.]+%s*[kK][gG]", "")
                                         :gsub("^%s+", ""):gsub("%s+$", "")
                        if cleaned ~= "" and not nameText then
                            nameText = cleaned
                        end
                    end
                end
            end
        end
    end

    -- fallbacks. NOTE: model.Name is a UUID for planted crops, so it is only a
    -- last resort and will simply fail to match any real seed name.
    if not nameText and model then nameText = model.Name end
    if not weight then weight = getFruitWeight(model) end

    return nameText and string.lower(nameText) or "", weight
end

--// Builds the world position of the plant a prompt belongs to.
local function promptPosition(prompt)
    local model = promptModel(prompt)
    if model then
        if model:IsA("BasePart") then return model.Position end
        local ok, cf = pcall(function() return model:GetPivot() end)
        if ok and cf then return cf.Position end
    end
    if prompt.Parent and prompt.Parent:IsA("BasePart") then
        return prompt.Parent.Position
    end
    return nil
end

--// Filters based on the NAME + WEIGHT we read from the billboard, plus the
--// mutation/variant attribute filters (checked on the model when available).
local function promptPassesFilters(prompt, fruitName, weight)
    -- weight range (only enforce if we actually read a weight)
    if weight ~= nil then
        if weight < fruitState.minWeight or weight > fruitState.maxWeight then
            return false
        end
    end

    local model = promptModel(prompt)

    -- variant protection / only-variants (from attributes if present)
    if model then
        local variant = getFruitVariant(model)
        if fruitState.protectVariants[variant] then return false end
        if setCount(fruitState.onlyVariants) > 0 and not fruitState.onlyVariants[variant] then
            return false
        end
        if setCount(fruitState.onlyMutations) > 0 then
            local muts = getFruitMutations(model)
            local match = false
            for m in pairs(fruitState.onlyMutations) do
                if muts[m] then match = true break end
            end
            if not match then return false end
        end
    end

    return true
end

--// Populates FRUIT_NAMES from the plant list + any fruits found in the world.
local reloadFruitDropdown  -- forward ref (set after the dropdown is built)
local function reloadFruitList()
    local seen = { ["---"] = true }
    FRUIT_NAMES = { "---" }
    -- start from the known plant names (fruits usually share plant names)
    for _, n in ipairs(PLANT_NAMES) do
        if not seen[n] then seen[n] = true; table.insert(FRUIT_NAMES, n) end
    end
    -- add any fruit instances currently in the world (by name)
    for _, inst in ipairs(workspace:GetDescendants()) do
        if isFruit(inst) then
            local nm = inst.Name
            if not seen[nm] then seen[nm] = true; table.insert(FRUIT_NAMES, nm) end
        end
    end
    table.sort(FRUIT_NAMES, function(a, b)
        if a == "---" then return true end
        if b == "---" then return false end
        return a < b
    end)
    if reloadFruitDropdown then reloadFruitDropdown() end
    print("[Arjhay Hub] Reloaded fruit list — " .. #FRUIT_NAMES .. " entries")
end

--// A multi-select FILTER popup (search + checkbox list) bound to a set table.
local function openFilterPopup(titleIcon, titleText, options, stateSet)
    local Overlay = Instance.new("Frame")
    Overlay.Size             = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.4
    Overlay.BorderSizePixel  = 0
    Overlay.ZIndex           = 60
    Overlay.Parent           = ScreenGui

    local Panel = Instance.new("Frame")
    Panel.AnchorPoint      = Vector2.new(0.5, 0.5)
    Panel.Position         = UDim2.new(0.5, 0, 0.5, 0)
    Panel.Size             = UDim2.new(0, 520, 0, 400)
    Panel.BackgroundColor3 = Theme.Background
    Panel.BorderSizePixel  = 0
    Panel.ZIndex           = 61
    Panel.Parent           = Overlay
    corner(Panel, 8)
    stroke(Panel, Theme.Stroke, 1)

    local Head = Instance.new("Frame")
    Head.Size             = UDim2.new(1, 0, 0, 40)
    Head.BackgroundColor3 = Theme.TopBar
    Head.BorderSizePixel  = 0
    Head.ZIndex           = 62
    Head.Parent           = Panel
    corner(Head, 8)

    local HeadTitle = Instance.new("TextLabel")
    HeadTitle.BackgroundTransparency = 1
    HeadTitle.Position               = UDim2.new(0, 12, 0, 0)
    HeadTitle.Size                   = UDim2.new(1, -110, 1, 0)
    HeadTitle.Font                   = Enum.Font.GothamBold
    HeadTitle.Text                   = titleIcon .. "  " .. titleText
    HeadTitle.TextColor3             = Theme.Text
    HeadTitle.TextSize               = 15
    HeadTitle.TextXAlignment         = Enum.TextXAlignment.Left
    HeadTitle.ZIndex                 = 63
    HeadTitle.Parent                 = Head

    local DoneBtn = Instance.new("TextButton")
    DoneBtn.AnchorPoint      = Vector2.new(1, 0.5)
    DoneBtn.Position         = UDim2.new(1, -10, 0.5, 0)
    DoneBtn.Size             = UDim2.new(0, 80, 0, 26)
    DoneBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 240)
    DoneBtn.Text             = "Done"
    DoneBtn.Font             = Enum.Font.GothamMedium
    DoneBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    DoneBtn.TextSize         = 13
    DoneBtn.ZIndex           = 63
    DoneBtn.Parent           = Head
    corner(DoneBtn, 6)

    -- search box
    local searchHolder = Instance.new("Frame")
    searchHolder.Position         = UDim2.new(0, 8, 0, 48)
    searchHolder.Size             = UDim2.new(1, -16, 0, 30)
    searchHolder.BackgroundColor3 = Theme.Button
    searchHolder.BorderSizePixel  = 0
    searchHolder.ZIndex           = 62
    searchHolder.Parent           = Panel
    corner(searchHolder, 6)

    local searchBox = Instance.new("TextBox")
    searchBox.BackgroundTransparency = 1
    searchBox.Position               = UDim2.new(0, 10, 0, 0)
    searchBox.Size                   = UDim2.new(1, -16, 1, 0)
    searchBox.Font                   = Enum.Font.Gotham
    searchBox.PlaceholderText        = "Search items..."
    searchBox.Text                   = ""
    searchBox.TextColor3             = Theme.Text
    searchBox.PlaceholderColor3      = Theme.SubText
    searchBox.TextSize               = 13
    searchBox.TextXAlignment         = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus       = false
    searchBox.ZIndex                 = 63
    searchBox.Parent                 = searchHolder

    local ListScroll = Instance.new("ScrollingFrame")
    ListScroll.Position               = UDim2.new(0, 8, 0, 86)
    ListScroll.Size                   = UDim2.new(1, -16, 1, -94)
    ListScroll.BackgroundTransparency = 1
    ListScroll.BorderSizePixel        = 0
    ListScroll.ScrollBarThickness     = 4
    ListScroll.ScrollBarImageColor3   = Theme.Accent
    ListScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    ListScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    ListScroll.ZIndex                 = 62
    ListScroll.Parent                 = Panel

    local lay = Instance.new("UIListLayout")
    lay.Padding   = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent    = ListScroll

    local rows = {}
    for i, opt in ipairs(options) do
        local item = Instance.new("TextButton")
        item.Name             = opt
        item.Size             = UDim2.new(1, 0, 0, 34)
        item.LayoutOrder      = i
        item.BackgroundColor3 = stateSet[string.lower(opt)] and Theme.Selected or Theme.Button
        item.Text             = ""
        item.AutoButtonColor  = false
        item.ZIndex           = 63
        item.Parent           = ListScroll
        corner(item, 6)

        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Position               = UDim2.new(0, 12, 0, 0)
        t.Size                   = UDim2.new(1, -20, 1, 0)
        t.Font                   = Enum.Font.Gotham
        t.Text                   = opt
        t.TextColor3             = Theme.Text
        t.TextSize               = 14
        t.TextXAlignment         = Enum.TextXAlignment.Left
        t.ZIndex                 = 64
        t.Parent                 = item

        item.MouseButton1Click:Connect(function()
            local key = string.lower(opt)
            if stateSet[key] then
                stateSet[key] = nil
                item.BackgroundColor3 = Theme.Button
            else
                stateSet[key] = true
                item.BackgroundColor3 = Theme.Selected
            end
        end)
        rows[opt] = item
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(searchBox.Text)
        for opt, item in pairs(rows) do
            item.Visible = (q == "") or string.find(string.lower(opt), q, 1, true) ~= nil
        end
    end)

    DoneBtn.MouseButton1Click:Connect(function()
        Overlay:Destroy()
    end)
end

--// A filter box (dropdown-style) that opens the multi-select filter popup and
--// shows a summary of how many are selected.
local function makeFilterBox(parent, icon, title, options, index, stateSet)
    local box = Instance.new("TextButton")
    box.Name             = title
    box.Size             = UDim2.new(1, 0, 0, 30)
    box.LayoutOrder      = index
    box.BackgroundColor3 = Theme.Button
    box.Text             = ""
    box.AutoButtonColor  = false
    box.Parent           = parent
    corner(box, 6)
    stroke(box, Theme.Stroke, 1)

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position               = UDim2.new(0, 10, 0, 0)
    lbl.Size                   = UDim2.new(1, -32, 1, 0)
    lbl.Font                   = Enum.Font.Gotham
    lbl.Text                   = "---"
    lbl.TextColor3             = Theme.Text
    lbl.TextSize               = 13
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextTruncate           = Enum.TextTruncate.AtEnd
    lbl.Parent                 = box

    local chev = Instance.new("TextLabel")
    chev.BackgroundTransparency = 1
    chev.AnchorPoint            = Vector2.new(1, 0.5)
    chev.Position               = UDim2.new(1, -8, 0.5, 0)
    chev.Size                   = UDim2.new(0, 16, 1, 0)
    chev.Font                   = Enum.Font.GothamBold
    chev.Text                   = "⌄"
    chev.TextColor3             = Theme.SubText
    chev.TextSize               = 16
    chev.Parent                 = box

    local function refresh()
        local c = setCount(stateSet)
        lbl.Text = (c == 0) and "---" or (c .. " selected")
    end

    box.MouseButton1Click:Connect(function()
        openFilterPopup(icon, title, options, stateSet)
        -- refresh the summary shortly after (popup edits the set live)
        task.spawn(function()
            while ScreenGui:FindFirstChild("Frame") do task.wait(0.2) end
            refresh()
        end)
    end)

    -- also refresh continuously while open is simplest via a light loop:
    task.spawn(function()
        while box.Parent and guiAlive ~= false do
            refresh()
            task.wait(0.5)
        end
    end)

    return box
end

-- ---------- FRUIT COLLECTOR section ----------
local fc = makeCollapsible(fruitPage, "Fruit Collector", 1, true)

makeSectionLabel(fc, "🍎", "Collect Fruits (multi-select)", 2)

makeFilterBox(fc, "🍎", "Collect Fruits", FRUIT_NAMES, 3, fruitState.targetFruits)

reloadFruitDropdown = function() end  -- no-op; filterBox reads FRUIT_NAMES live

do
    local btn = Instance.new("TextButton")
    btn.Name             = "ReloadFruitList"
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.LayoutOrder      = 4
    btn.BackgroundColor3 = Theme.Button
    btn.Text             = "🔄  Reload Fruit List"
    btn.Font             = Enum.Font.GothamMedium
    btn.TextColor3       = Theme.Text
    btn.TextSize         = 13
    btn.AutoButtonColor  = true
    btn.Parent           = fc
    corner(btn, 6)
    stroke(btn, Theme.Stroke, 1)
    btn.MouseButton1Click:Connect(reloadFruitList)
end

-- Fruit Auto Teleport: this does NOT hop between plants. Instead, the moment
-- you enable it, it saves your CURRENT spot as your "garden" position. A
-- watchdog then tweens you BACK to that garden spot whenever you drift too far
-- from it (e.g. you wandered off, or got knocked away), so you always stay on
-- your plot while the collector harvests.
local GARDEN_LEASH = 30   -- studs: if farther than this from garden, tween back
makeIconToggle(fc, "🚀", "Auto Teleport", 5, function(on)
    fruitState.autoTeleport = on
    print("[Arjhay Hub] Fruit Auto Teleport:", on)
    if not on then return end

    -- save the garden spot = where you are right now
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        fruitState.gardenPos = hrp.Position
        print("[Arjhay Hub] Garden position saved:", fruitState.gardenPos)
    end

    -- watchdog loop: tween back to garden only when we drift too far away
    task.spawn(function()
        while fruitState.autoTeleport and guiAlive do
            local c = LocalPlayer.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")
            if root and fruitState.gardenPos then
                if (root.Position - fruitState.gardenPos).Magnitude > GARDEN_LEASH then
                    smoothTeleport(fruitState.gardenPos)
                end
            end
            task.wait(0.5)
        end
    end)
end)



-- Tries to collect a single prompt if it passes all filters.
-- Fires the prompt REMOTELY — the character does NOT move at all.
-- (Auto Teleport toggle only moves the character when explicitly enabled.)
--
-- FILTER LOGIC:
--   * "Use Fruit Filter" OFF -> collect EVERY fruit (ignore type/weight/etc.)
--   * "Use Fruit Filter" ON  -> only collect fruits that match the selected
--                               types (multi-select) AND pass the weight /
--                               mutation / variant filters.
--   * If filter is ON but NO fruit types are selected, treat as "collect all
--     types" (still applies weight/mutation/variant filters).
local function tryCollectPrompt(inst)
    if not isHarvestPrompt(inst) then return false end

    -- Stop When Backpack Is Full: skip collecting while the backpack is full
    if fruitState.stopWhenFull and isBackpackFull() then return false end

    -- filter OFF -> collect anything
    -- NOTE: we do NOT teleport to the plant here. Fruit is collected REMOTELY
    -- (firePrompt), and Auto Teleport now only keeps you on your GARDEN spot
    -- via the leash watchdog — it never hops between plants.
    if not fruitState.useFruitFilter then
        return firePrompt(inst)
    end


    -- filter ON -> check selected types + attribute filters
    local fruitName, weight = readPromptInfo(inst)
    local model = promptModel(inst)

    -- type match against the multi-select set (empty set = all types).
    -- Compared on NORMALISED names so "Dragon's Breath" matches "dragons
    -- breath"/"Dragon Breath", and both directions are tested so a longer
    -- billboard string ("Frozen Dragon's Breath") still matches the seed.
    local typeOk = true
    if setCount(fruitState.targetFruits) > 0 then
        typeOk = false
        local got = fruitState.norm(fruitName)
        for wanted in pairs(fruitState.targetFruits) do
            local w = fruitState.norm(wanted)
            if wanted == "---" or w == "" then
                typeOk = true
                break
            end
            if got ~= "" and (string.find(got, w, 1, true)
                           or string.find(w, got, 1, true)) then
                typeOk = true
                break
            end
        end
    end

    if typeOk and promptPassesFilters(inst, fruitName, weight) then
        if fruitState.autoTeleport then
            local pos = promptPosition(inst)
            if pos then smoothTeleport(pos) end
        end
        return firePrompt(inst)
    end
    return false
end


--============================================================
--  REGROW SAFETY NET  (this is the actual "not collecting after regrow" fix)
--
--  Relying on workspace.DescendantAdded alone is fragile:
--    * a regrown fruit's prompt is often added DISABLED and only enabled later,
--      so the one-shot listener fired 0.3s after creation and gave up;
--    * with Remove Plants ON we also add/destroy a lot of instances, so a
--      prompt event can be missed entirely;
--    * the full-workspace scan loop below runs at most every 0.5s and walks
--      tens of thousands of instances, so it often misses the window too.
--
--  This sweeper instead walks ONLY the crop folders
--  (Workspace.Gardens.Plot#.Plants) near the player — a few hundred instances
--  instead of the whole map — so it can run several times a second and will
--  always pick up a regrown fruit no matter when its prompt appears or what
--  state it was created in.
--
--  NOTE: getMyPlot() is declared later in the file, so we can't call it here.
--  We use a simple distance gate around the character instead, which resolves
--  to your own garden in practice.
--
--  This is stored ON fruitState (not as a new local) on purpose: the main chunk
--  is already close to Luau's hard limit of 200 locals per function — the same
--  limit that previously broke this script entirely ("Out of local registers").
--============================================================
fruitState.sweepRadius = 120

fruitState.sweepGardenPrompts = function()
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return 0 end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local me   = hrp and hrp.Position or nil

    local fired = 0
    for _, plot in ipairs(gardens:GetChildren()) do
        local plantsFolder = plot:FindFirstChild("Plants")
        if plantsFolder then
            for _, crop in ipairs(plantsFolder:GetChildren()) do
                if not (fruitState.fastCollector and guiAlive) then return fired end

                -- only crops near me (= my own plot)
                local near = true
                if me then
                    local okp, cf = pcall(function() return crop:GetPivot() end)
                    if okp and cf then
                        near = (cf.Position - me).Magnitude <= fruitState.sweepRadius
                    end
                end

                if near then
                    for _, d in ipairs(crop:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then
                            if tryCollectPrompt(d) then
                                fired = fired + 1
                                task.wait(fruitState.collectDelay > 0
                                    and fruitState.collectDelay or 0.05)
                            end
                        end
                    end
                end
            end
        end
    end
    return fired
end

-- Connection that fires IMMEDIATELY when a new ProximityPrompt is added.
-- This is the KEY fix for regrown fruit: every time a plant regrows, the game
-- adds a brand-new ProximityPrompt instance. We catch it the instant it
-- appears and fire it — no scan loop needed for regrows.
local fruitAddedConn = nil

makeIconToggle(fc, "🍏", "Fast Fruit Collector", 5, function(on)
    fruitState.fastCollector = on
    print("[Arjhay Hub] Fast Fruit Collector:", on and "ON" or "OFF")

    if not on then
        if fruitAddedConn then
            fruitAddedConn:Disconnect()
            fruitAddedConn = nil
        end
        return
    end

    -- REGROW FIX: listen for any new ProximityPrompt added anywhere in the
    -- workspace. Regrown fruit always adds a fresh prompt instance — we fire
    -- it after a short delay so it's fully initialized.
    -- We do NOT filter by Model here because the prompt may be parented to a
    -- BasePart directly, and we want to catch it regardless of hierarchy.
    if not fruitAddedConn then
        fruitAddedConn = workspace.DescendantAdded:Connect(function(inst)
            if not (fruitState.fastCollector and guiAlive) then return end
            if not inst:IsA("ProximityPrompt") then return end
            -- wait a bit longer (0.3s) so the game fully attaches the prompt
            -- and sets its ActionText/ObjectText before we read them
            task.delay(0.3, function()
                if not (fruitState.fastCollector and guiAlive) then return end
                if not (inst and inst.Parent) then return end
                -- force-enable so a disabled/fresh prompt can still be fired
                pcall(function()
                    inst.Enabled              = true
                    inst.RequiresLineOfSight  = false
                    inst.MaxActivationDistance = 1e9
                    inst.HoldDuration         = 0
                end)
                tryCollectPrompt(inst)
            end)
        end)
    end

    -- REGROW SAFETY NET loop: cheap, garden-only sweep that runs several times
    -- a second. This is what keeps collecting after every regrow (especially
    -- with Remove Plants ON, where prompt-added events are easy to miss).
    task.spawn(function()
        while fruitState.fastCollector and guiAlive do
            local n = 0
            local okSweep, res = pcall(fruitState.sweepGardenPrompts)
            if okSweep and type(res) == "number" then n = res end
            task.wait(n > 0 and 0.15 or 0.4)
        end
    end)

    -- Periodic scan loop: collects prompts that already exist when the toggle
    -- is turned on. Also acts as a safety net for any prompt the listener
    -- might have missed (e.g. already present before the listener was set up).
    task.spawn(function()
        while fruitState.fastCollector and guiAlive do
            local collectedThisPass = 0
            for _, inst in ipairs(workspace:GetDescendants()) do
                if not (fruitState.fastCollector and guiAlive) then break end
                if tryCollectPrompt(inst) then
                    collectedThisPass = collectedThisPass + 1
                    -- honour the user's "Delay Collect Fruits" setting between
                    -- each fruit collect (0 = as fast as possible)
                    task.wait(fruitState.collectDelay > 0 and fruitState.collectDelay or 0.05)
                end
            end
            task.wait(collectedThisPass == 0 and 0.5 or 0.1)
        end
    end)
end)



-- ---------- FRUIT FILTERS (now INSIDE the Fruit Collector section) ----------
-- Uses the exact same dropdown design as "Collect Fruits" above.

-- Stop collecting when the backpack is full

makeIconToggle(fc, "🎒", "Stop When Backpack Is Full", 6.1, function(on)
    fruitState.stopWhenFull = on
    print("[Arjhay Hub] Stop When Backpack Is Full:", on)
end)

-- Delay (seconds) between each fruit collect
makeSectionLabel(fc, "⏱", "Delay Collect Fruits (seconds)", 6.2)
makeNumberInput(fc, 0, 6.3, function(n)
    fruitState.collectDelay = math.max(n, 0)
    print("[Arjhay Hub] Collect Delay:", fruitState.collectDelay)
end)

-- Use Fruit Filter — when OFF, collect ANY fruit ignoring type/weight/mutation
makeIconToggle(fc, "🔍", "Use Fruit Filter", 6.4, function(on)
    fruitState.useFruitFilter = on
    print("[Arjhay Hub] Use Fruit Filter:", on)
end)

makeSectionLabel(fc, "⬇", "Min Weight (KG)", 7)
makeNumberInput(fc, 0, 8, function(n)
    fruitState.minWeight = math.max(n, 0)
    print("[Arjhay Hub] Min Weight:", fruitState.minWeight)
end)


makeSectionLabel(fc, "⬆", "Max Weight (KG)", 9)
makeNumberInput(fc, 150, 10, function(n)
    fruitState.maxWeight = math.max(n, 0)
    print("[Arjhay Hub] Max Weight:", fruitState.maxWeight)
end)

makeSectionLabel(fc, "✅", "Only Mutations", 11)
makeFilterBox(fc, "✅", "Only Mutations", MUTATION_LIST, 12, fruitState.onlyMutations)

makeSectionLabel(fc, "✅", "Only Variants", 13)
makeFilterBox(fc, "✅", "Only Variants", VARIANT_LIST, 14, fruitState.onlyVariants)

makeSectionLabel(fc, "🛡", "Protect Variants", 15)
makeFilterBox(fc, "🛡", "Protect Variants", VARIANT_LIST, 16, fruitState.protectVariants)

--============================================================
--  MAIN TAB  →  SELL MANAGER
--  Two collapsible sections:
--    • Sell Fruits  (Sell When Backpack Is Full / Turbo Sell / Enable Auto Sell)
--    • Sell Filters (Sell Fruits dropdown, Reload, Use Sell Filters, Min/Max KG,
--                    Only Mutations, Only Variants, Protect Variants)
--  NOTE: per request, there is NO "Protect Mutations" here — the sell filters
--  reuse the same mutation/variant logic as the Fruit Collector.
--============================================================

-- sell state
local sellState = {
    onlyWhenFull   = false,   -- only sell when the backpack is full
    autoSell       = false,   -- master enable
    sellDelay      = 1,       -- seconds between each sell
}



-- ============================================================
--  SELL HELPER
--  Uses the EXACT two packets captured from the game when selling fruit:
--
--    local args = { buffer.fromstring("\190\000\021") }
--    ...Packet.RemoteEvent:FireServer(unpack(args))
--
--    local args = { buffer.fromstring("\189\000\022") }
--    ...Packet.RemoteEvent:FireServer(unpack(args))
--
--  Packet 1 bytes: 190, 0, 21   Packet 2 bytes: 189, 0, 22
--  Both are fired (in order) to sell ALL fruit in the backpack — no NPC
--  interaction / per-item work needed.
-- ============================================================

-- Fires the game's "sell fruit" packets (both, in order).
local function fireSell()
    local ok, err = pcall(function()
        PlaceRemote:FireServer(buffer.fromstring("\190\000\021"))
        PlaceRemote:FireServer(buffer.fromstring("\189\000\022"))
    end)
    if not ok then
        warn("[Arjhay Hub] Sell FireServer failed:", err)
        return false
    end
    print("[Arjhay Hub] Sold fruit (packets \\190\\000\\021 + \\189\\000\\022)")
    return true
end






-- Is the backpack "full"? Uses the player's inventory count vs a max attribute
-- if available; otherwise treats a large item count as full.
-- (assigns to the forward-declared local near the top of the Main tab so the
--  Fruit Collector's "Stop When Backpack Full" can use it too.)
-- Detecting "backpack full". The most RELIABLE signal in this game is the
-- on-screen popup "Your inventory is full [X##]" (the number varies: X49, X66,
-- ...), so counting tools against a fixed cap does NOT work. Instead we scan
-- the PlayerGui for that popup text. As backups we also honour an explicit
-- attribute (if the game exposes one) and a tool-count vs max-slots attribute.
local BACKPACK_MAX = 49

-- Scans every visible TextLabel/TextButton in PlayerGui for the "inventory is
-- full" message. Returns true while that popup is showing.
local function inventoryFullPopupShowing()
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
            local t = string.lower(gui.Text or "")
            if t ~= "" and string.find(t, "inventory is full", 1, true) then
                -- make sure the label is actually on-screen (ancestors visible)
                local shown = true
                local a = gui.Parent
                while a and a ~= PlayerGui do
                    if a:IsA("GuiObject") and not a.Visible then shown = false break end
                    a = a.Parent
                end
                if shown then return true end
            end
        end
    end
    return false
end

-- The ACTUAL (heavy) full-check. Scans the PlayerGui for the popup + counts
-- tools. This is EXPENSIVE, so it is NOT called directly by the hot loops.
local function computeBackpackFull()

    -- 1) BEST signal: the on-screen "Your inventory is full [X##]" popup.
    if inventoryFullPopupShowing() then return true end

    -- 2) explicit attribute (if the game exposes a full flag, trust it)
    for _, key in ipairs({ "BackpackFull", "InventoryFull", "IsFull" }) do
        local ok, v = pcall(function() return LocalPlayer:GetAttribute(key) end)
        if ok and type(v) == "boolean" then return v end
    end

    -- 3) tool-count vs a max-slots attribute (fallback if no popup/flag)
    local maxSlots = BACKPACK_MAX
    for _, key in ipairs({ "MaxBackpack", "BackpackSize", "MaxInventory" }) do
        local ok, v = pcall(function() return LocalPlayer:GetAttribute(key) end)
        if ok and type(v) == "number" and v > 0 then maxSlots = v break end
    end

    local count = 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") then count = count + 1 end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then count = count + 1 end
        end
    end

    return count >= maxSlots
end

-- LAG FIX: the Fruit Collector calls isBackpackFull() on EVERY prompt, many
-- times per second. Doing the heavy PlayerGui scan that often froze the game.
-- Instead we compute it ONCE every ~0.3s in a tiny background loop and cache
-- the result; isBackpackFull() just returns the cached boolean (basically free).
local backpackFullCached = false
task.spawn(function()
    while guiAlive do
        local ok, res = pcall(computeBackpackFull)
        backpackFullCached = ok and res or false
        task.wait(0.3)
    end
end)

isBackpackFull = function()
    return backpackFullCached
end




-- Runs one sell cycle: fires the game's sell packet, which sells ALL fruit in
-- the backpack at once.
local function doSellPass()
    fireSell()
end




local fruitSellPage = pages["Main"]

-- ---------- SELL FRUITS section ----------
local sfSell = makeCollapsible(fruitSellPage, "Sell Fruits", 2, false)

do
    local info = Instance.new("TextLabel")
    info.Name                   = "SellInfo"
    info.BackgroundTransparency = 1
    info.Size                   = UDim2.new(1, 0, 0, 40)
    info.LayoutOrder            = 1
    info.Font                   = Enum.Font.Gotham
    info.Text                   = "ℹ  Auto Sell fires the game's sell packet, which sells ALL fruit in your backpack at once."
    info.TextColor3             = Theme.SubText
    info.TextSize               = 12
    info.TextXAlignment         = Enum.TextXAlignment.Left
    info.TextWrapped            = true
    info.Parent                 = sfSell
end

makeIconToggle(sfSell, "🎒", "Sell When Backpack Is Full", 2, function(on)
    sellState.onlyWhenFull = on
    print("[Arjhay Hub] Sell When Backpack Is Full:", on)
end)

-- Delay (seconds) between each sell
makeSectionLabel(sfSell, "⏱", "Delay Sell (seconds)", 3)
makeNumberInput(sfSell, 1, 4, function(n)
    sellState.sellDelay = math.max(n, 0)
    print("[Arjhay Hub] Sell Delay:", sellState.sellDelay)
end)

makeIconToggle(sfSell, "💰", "Enable Auto Sell", 5, function(on)
    sellState.autoSell = on
    print("[Arjhay Hub] Enable Auto Sell:", on and "ON" or "OFF")
    if not on then return end

    -- Auto Sell loop
    task.spawn(function()
        while sellState.autoSell and guiAlive do
            local ready = true
            -- if "only when full" is on, wait until the backpack is full
            if sellState.onlyWhenFull and not isBackpackFull() then
                ready = false
            end
            if ready then
                doSellPass()
            end
            -- wait the user's Delay Sell setting (minimum 0.1s so we never spin)
            task.wait(sellState.sellDelay > 0 and sellState.sellDelay or 0.1)
        end
    end)
end)



--============================================================
--  MISC TAB  →  PERFORMANCE
--============================================================

pages["Misc"] = makePage("Misc")
local mp = pages["Misc"]

-- Collapsible "Performance" section
local perf = makeCollapsible(mp, "Performance", 1, true)

-- Build a quick lookup set of plant names (lowercase) so we can recognise
-- ANY plant in the world (from the same list used for Plant Target).
local PLANT_SET = {}
for _, n in ipairs(PLANT_NAMES) do
    PLANT_SET[string.lower(n)] = true
end

-- Returns true if the given instance is a plant (by name / attribute /
-- StringValue child), matching against the full plant list.
local function isPlantInstance(inst)
    if not (inst:IsA("Model")) then return false end
    if PLANT_SET[string.lower(inst.Name)] then return true end

    local ok, attrs = pcall(function() return inst:GetAttributes() end)
    if ok and attrs then
        for _, v in pairs(attrs) do
            if type(v) == "string" and PLANT_SET[string.lower(v)] then
                return true
            end
        end
    end
    for _, ch in ipairs(inst:GetChildren()) do
        if (ch:IsA("StringValue") or ch:IsA("ObjectValue"))
        and type(ch.Value) == "string" and PLANT_SET[string.lower(ch.Value)] then
            return true
        end
    end
    return false
end

--============================================================
--  REMOVE PLANTS  (DESTROYS the heavy visuals for real FPS — but keeps the
--  model, one lightweight anchor part, the Harvest ProximityPrompt and the
--  name/weight billboard, so Auto Sprinkler (Plant Target), Auto Watering Can
--  (Plant Target) and Auto Collect Fruit KEEP WORKING).
--
--  NOTE: this is destructive (client-side). The visuals don't come back until
--  you rejoin — that's the trade-off for actually removing the lag instead of
--  just hiding it. The plant DATA (model name / attributes / prompt / billboard)
--  stays intact so all automation still finds and targets the plants.
--============================================================
local removePlantsOn   = false
local plantHideConn    = nil   -- DescendantAdded connection
local plantResweepLoop = nil   -- periodic re-hide loop for growing fruit
local strippedPlants   = setmetatable({}, { __mode = "k" })  -- [model]=true (done)

-- THE REAL LAG SOURCE (from the error log):
-- The game runs client controllers like VenusFlyTrapController /
-- VenomSpitterController that animate every plant each frame and reference
-- PlantModel.Rig.RootPart. When Remove Plants destroys parts, those controllers
-- throw "RootPart is not a valid member" errors CONTINUOUSLY for every plant —
-- and that error spam is what tanks the FPS.
--
-- Fix: disable those per-plant animation controllers. They only drive the
-- plant's idle/attack ANIMATIONS (Venus Fly Trap chomping, Venom Spitter, etc.)
-- — they are NOT needed for growth, harvesting, sprinklers or watering, so
-- turning them off removes the lag/errors while all automation keeps working.
local controllersDisabled = false
local function disablePlantControllers()
    if controllersDisabled then return end
    controllersDisabled = true

    -- The controllers live in Players.<you>.PlayerScripts.Controllers.
    -- In THIS game they are MODULE scripts (VenusFlyTrapController /
    -- VenomSpitterController), so `.Disabled` does nothing — which is why the
    -- console kept flooding with:
    --   "RootPart is not a valid member of ...PlantModel.Rig"
    --   "Base is not a valid member of Model ..."
    --   "attempt to index nil with 'Size'"
    -- ModuleScripts can't be disabled, but we CAN replace the exact functions
    -- that error on the already-required module table with no-ops. Those
    -- functions only drive the plant's idle/attack ANIMATIONS, so growth,
    -- harvesting, sprinklers and watering all keep working.
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    if ps then
        for _, s in ipairs(ps:GetDescendants()) do
            local n = string.lower(s.Name)
            -- ONLY the two animation controllers that actually spam errors.
            --
            -- THIS WAS THE FRUIT-COLLECTOR BUG: the old check also matched ANY
            -- module named like "plant...controller". In this game that is the
            -- controller which attaches the Harvest ProximityPrompt to newly
            -- grown fruit — so no-op'ing it meant regrown fruit never got a
            -- prompt, and the collector had nothing to fire. Narrowed to the
            -- FlyTrap / VenomSpitter animation modules only.
            local isPlantCtrl =
                   string.find(n, "flytrap", 1, true)
                or string.find(n, "venom", 1, true)
                or string.find(n, "spitter", 1, true)
                or string.find(n, "plantanim", 1, true)

            if isPlantCtrl then
                if s:IsA("LocalScript") or s:IsA("Script") then
                    pcall(function() s.Disabled = true end)
                elseif s:IsA("ModuleScript") then
                    pcall(function()
                        local m = require(s)
                        if type(m) == "table" then
                            -- animation-only entry points. "start"/"init" are
                            -- deliberately NOT here: those also register the
                            -- growth / harvest-prompt hooks, and killing them
                            -- stopped regrown fruit from becoming collectable.
                            for _, fname in ipairs({
                                "setupFlyTrap", "setupSpitter", "findTarget",
                                "update", "Update", "onUpdate", "step", "Step",
                            }) do
                                if type(m[fname]) == "function" then
                                    m[fname] = function() end
                                end
                            end
                        end
                    end)
                end
            end
        end
    end

    print("[Arjhay Hub] Plant controllers disabled (FlyTrap / VenomSpitter animations off)")
end

-- ============================================================
--  ERROR-SPAM FIX  ("attempt to index nil with 'Size'" from
--  VenusFlyTrapController:466 / VenomSpitterController:555)
--
--  Those controllers run setupFlyTrap() on EVERY plant and index a child part
--  (…Rig.RootPart / a hitbox part) then read `.Size`. When we DESTROY the whole
--  plant, that lookup returns nil and the controller errors every frame — the
--  red flood you saw, which is what actually kills the FPS.
--
--  THE FIX: instead of leaving the model behind with holes in it, we destroy
--  the ENTIRE plant model in one go (`model:Destroy()`), so the controller's
--  lookup fails at the FIRST step (the model itself is gone from the folder)
--  and it simply skips that plant instead of walking into a nil part.
--
--  To keep the automation working we FIRST re-parent the pieces the hub needs
--  (Harvest ProximityPrompt + name/weight BillboardGui) onto a tiny invisible
--  "proxy" part placed at the plant's exact position, and keep the plant's
--  name + attributes on that proxy. Fruit Collector, Auto Sprinkler (Plant
--  Target) and Auto Watering Can all read name/attributes/prompt/billboard, so
--  they keep working perfectly — but the heavy model (and its shadow) is gone
--  and the controllers no longer error.
-- ============================================================

-- Folder that holds all our lightweight proxies.
local ProxyFolder = workspace:FindFirstChild("ArjhayProxies")
if not ProxyFolder then
    ProxyFolder = Instance.new("Folder")
    ProxyFolder.Name = "ArjhayProxies"
    ProxyFolder.Parent = workspace
end

-- Creates the tiny invisible stand-in for a plant/fruit and moves the
-- prompt + billboard onto it. Returns the proxy part.
local function makeProxy(model)
    -- world position of the original
    local pos
    local okp, cf = pcall(function() return model:GetPivot() end)
    if okp and cf then
        pos = cf.Position
    elseif model:IsA("BasePart") then
        pos = model.Position
    else
        local bp = model:FindFirstChildWhichIsA("BasePart", true)
        pos = bp and bp.Position or Vector3.new(0, 0, 0)
    end

    local proxy = Instance.new("Part")
    proxy.Name         = model.Name        -- keep the name (Plant Target reads it)
    proxy.Size         = Vector3.new(0.05, 0.05, 0.05)
    proxy.Position     = pos
    proxy.Anchored     = true
    proxy.CanCollide   = false
    proxy.CanQuery     = false
    proxy.CanTouch     = false
    proxy.CastShadow   = false             -- NO shadow at all
    proxy.Transparency = 1
    proxy.LocalTransparencyModifier = 1
    proxy.Material     = Enum.Material.SmoothPlastic

    -- copy attributes (Plant Target / filters read these)
    local oka, attrs = pcall(function() return model:GetAttributes() end)
    if oka and attrs then
        for k, v in pairs(attrs) do
            pcall(function() proxy:SetAttribute(k, v) end)
        end
    end

    -- move over the automation-critical GUI objects + StringValues
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") or d:IsA("BillboardGui")
        or d:IsA("StringValue") or d:IsA("NumberValue") then
            pcall(function() d.Parent = proxy end)
        end
    end

    proxy.Parent = ProxyFolder
    return proxy
end

-- ============================================================
--  SAFETY GUARDS  (fixes the "whole world disappeared" bug)
--
--  destroyWhole() previously nuked ANY model isPlantInstance() matched. That
--  matched big parent containers (your farm / plot / map holder) too, so the
--  entire world got deleted and only the sky was left.
--
--  These guards make sure we ONLY ever destroy a single, small, real plant:
--    * never a direct child of workspace (those are map/farm containers)
--    * never a model containing your character, or that you're standing in
--    * never a model with too many BaseParts (a plant is small; a farm is huge)
--    * never a model whose name looks like a container (farm/plot/map/base/...)
--    * never a model that CONTAINS other plant models (it's a holder, not a plant)
-- ============================================================
local MAX_PLANT_PARTS = 60   -- a real plant model is well under this

local CONTAINER_WORDS = {
    "farm", "plot", "map", "base", "baseplate", "ground", "terrain", "island",
    "world", "garden", "land", "field", "region", "zone", "area", "lobby",
    "spawn", "house", "building", "shop", "npc", "camera", "环境",
}

local function nameLooksContainer(name)
    name = string.lower(name)
    for _, w in ipairs(CONTAINER_WORDS) do
        if string.find(name, w, 1, true) then return true end
    end
    return false
end

-- Counts BaseParts but STOPS early once it passes the limit (cheap).
local function partCountUnder(model, limit)
    local n = 0
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            n = n + 1
            if n > limit then return n end
        end
    end
    return n
end

-- STRICT plant check: the model's OWN NAME must be an exact match in the real
-- plant list (PLANT_SET, loaded from ReplicatedStorage.Assets.Plants).
--
-- This is the key fix for the black screen: isPlantInstance() also matched by
-- ATTRIBUTE and StringValue children, and lots of world/map containers carry a
-- plant name in an attribute — so they got destroyed too. For DESTROYING we
-- only ever trust an exact name match on the model itself.
-- ============================================================
--  REAL PLANT DETECTION  (based on the ACTUAL game hierarchy)
--
--  The console log revealed the real structure:
--      Workspace.Gardens.Plot4.Plants.<uuid>.PlantModel.Rig
--
--  A planted crop is NOT named after the seed — it's a UUID model inside
--  Gardens > Plot# > Plants. That is exactly why the strict name match printed
--  "found 0 plants" and your own crops never disappeared, while the
--  DescendantAdded handler was stripping random streamed models (which made
--  OTHER players' gardens flicker in and out).
-- ============================================================
local function isInsidePlantsFolder(model)
    local parent = model.Parent
    if not parent or parent.Name ~= "Plants" then return false end
    local plot = parent.Parent
    if not plot or not string.match(plot.Name, "^Plot%d+$") then return false end
    local gardens = plot.Parent
    return gardens ~= nil and gardens.Name == "Gardens"
end

-- ONLY the real hierarchy counts for destroying now.
-- (Exact-seed-name matching ALSO matched map/world containers that happen to
--  carry a plant name — that is what destroyed the whole map instead of just
--  the plants. A crop is ALWAYS inside Gardens > Plot# > Plants, so that path
--  is the one and only thing we trust.)
local function isRealPlantByName(model)
    return isInsidePlantsFolder(model)
end

--============================================================
--  WHICH PLOT IS MINE?
--  Other players' gardens get FULLY destroyed (nothing there needs to work).
--  MY garden only gets SEMI-stripped, so Fruit Collector / Auto Sprinkler
--  (Plant Target) / Auto Watering Can all keep working on my own plants.
--============================================================
local function getGardens()
    return workspace:FindFirstChild("Gardens")
end

-- Does this Plot belong to the local player? (attributes / owner values)
local function plotBelongsToMe(plot)
    local myName = string.lower(LocalPlayer.Name)
    for _, key in ipairs({ "Owner", "OwnerName", "Player", "PlayerName", "Username" }) do
        local ok, v = pcall(function() return plot:GetAttribute(key) end)
        if ok and type(v) == "string" and v ~= "" and string.lower(v) == myName then
            return true
        end
    end
    for _, key in ipairs({ "UserId", "OwnerUserId", "OwnerId" }) do
        local ok, v = pcall(function() return plot:GetAttribute(key) end)
        if ok and type(v) == "number" and v == LocalPlayer.UserId then return true end
    end
    -- an ObjectValue pointing at me, or a StringValue with my name
    for _, d in ipairs(plot:GetChildren()) do
        if d:IsA("ObjectValue") and d.Value == LocalPlayer then return true end
        if d:IsA("StringValue") and type(d.Value) == "string"
        and string.lower(d.Value) == myName then return true end
    end
    return false
end

-- Resolves (and caches) my plot.
--
-- "please only scan my only garden not others": the fallback here used to pick
-- the plot NEAREST the character. Stand near the edge of your plot — or next to
-- a neighbour's — and that returns THEIR plot, so Farm Details listed their
-- plants as yours. The nearest-plot guess is now gated on the character
-- actually being INSIDE the plot's bounds, so a neighbouring plot can never be
-- chosen. If ownership can't be proven we return nil and the panel says so,
-- which is far better than silently showing someone else's garden.
local myPlotCache = nil

-- Everything the "is this plot mine?" check needs, kept in ONE table on
-- purpose. The main chunk is already near Luau's hard limit of 200 locals per
-- function (blowing it is what broke this whole script once before with
-- "Out of local registers"), so this section spends a single local slot instead
-- of five.
local plotGuard = {
    -- Negative cache: getMyPlot() is called from the DescendantAdded hot path,
    -- so when it can't resolve a plot we must NOT redo the search for every
    -- instance that streams in.
    missAt = 0,
    retry  = 2,      -- seconds before trying to resolve again
    -- Axis-aligned XZ footprint per plot. GetBoundingBox is Model-only and
    -- these plots aren't guaranteed to be Models, so we accumulate bounds from
    -- the plot's own BaseParts. Weak keys so destroyed plots don't leak.
    bounds = setmetatable({}, { __mode = "k" }),
}

function plotGuard.footprint(plot)
    local b = plotGuard.bounds[plot]
    if b then return b end

    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    local seen = 0
    for _, d in ipairs(plot:GetDescendants()) do
        if d:IsA("BasePart") then
            local p = d.Position
            if p.X < minX then minX = p.X end
            if p.X > maxX then maxX = p.X end
            if p.Z < minZ then minZ = p.Z end
            if p.Z > maxZ then maxZ = p.Z end
            seen = seen + 1
            if seen >= 3000 then break end   -- plenty to define the footprint
        end
    end
    if seen == 0 then return nil end

    b = { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
    plotGuard.bounds[plot] = b
    return b
end

-- Is `pos` inside this plot's own footprint (with a small margin)?
function plotGuard.inside(plot, pos)
    local b = plotGuard.footprint(plot)
    if not b then return false end
    local m = 4
    return pos.X >= (b.minX - m) and pos.X <= (b.maxX + m)
       and pos.Z >= (b.minZ - m) and pos.Z <= (b.maxZ + m)
end


local function getMyPlot()
    local gardens = getGardens()
    if not gardens then return nil end
    if myPlotCache and myPlotCache.Parent == gardens then return myPlotCache end
    if (os.clock() - plotGuard.missAt) < plotGuard.retry then return nil end

    -- 1) proven ownership (attributes / owner values) — always preferred
    for _, plot in ipairs(gardens:GetChildren()) do
        if string.match(plot.Name, "^Plot%d+$") and plotBelongsToMe(plot) then
            myPlotCache = plot
            return plot
        end
    end

    -- 2) the plot I am literally STANDING IN (not merely the closest one)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, plot in ipairs(gardens:GetChildren()) do
            if string.match(plot.Name, "^Plot%d+$")
            and plotGuard.inside(plot, hrp.Position) then
                myPlotCache = plot
                return plot
            end
        end
    end

    -- 3) can't prove it's mine -> scan nothing rather than someone else's garden
    plotGuard.missAt = os.clock()
    return nil
end



-- Which Plot does this instance live in? (nil = not garden content at all)
local function plotOf(inst)
    local a = inst
    local depth = 0
    while a and depth < 12 do
        local p = a.Parent
        if p and p.Name == "Gardens" and string.match(a.Name, "^Plot%d+$") then
            return a
        end
        a = p
        depth = depth + 1
    end
    return nil
end

-- Is it SAFE to fully destroy this model?
-- Only ONE rule now: it must be a crop model sitting directly in a
-- Gardens > Plot# > Plants folder and contain at least one BasePart.
-- Nothing outside that path can ever be destroyed, so the map is always safe.
local function safeToDestroy(model)
    if not (model and model.Parent) then return false end
    if not isInsidePlantsFolder(model) then return false end
    return model:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

-- FULL destroy of a plant (used on OTHER players' gardens).
-- keepProxy=true leaves an invisible proxy behind carrying the plant's name,
-- attributes, Harvest prompt and billboard (only needed for MY OWN garden).
local function destroyWhole(model, keepProxy)
    if not safeToDestroy(model) then return end
    if keepProxy then
        pcall(function() makeProxy(model) end)
    end
    pcall(function() model:Destroy() end)
end



-- The game's plant controllers (VenusFlyTrap / VenomSpitter / etc.) animate the
-- plant's "Rig" skeleton EVERY FRAME, walking RootPart + all its limbs. If we
-- destroy ANY part inside that Rig, the controller errors every frame (the
-- "RootPart is not a valid member" spam in the log) which is the real lag.
--
-- So: never DESTROY anything inside a Rig — we make it invisible + render-free
-- instead (neutralisePart). The controller keeps animating an invisible
-- skeleton (cheap, no errors) while we still hard-destroy every heavy visual
-- part OUTSIDE the Rig. Result: garden looks empty, runs smooth, no errors,
-- and all automation (prompts/billboards) still works.
local function isInsideRig(part)
    local a = part
    local depth = 0
    while a and depth < 10 do
        if a.Name == "Rig" or a.Name == "AnimSaves" then return true end
        -- an Animator/Humanoid sibling also marks an animated skeleton
        a = a.Parent
        depth = depth + 1
    end
    return false
end

-- true if this part must be preserved (Rig skeleton the controllers need)
local function isStructuralPart(part)
    if isInsideRig(part) then return true end
    local n = string.lower(part.Name)
    return n == "rootpart" or n == "humanoidrootpart" or n == "torso"
        or n == "lowertorso" or n == "uppertorso" or n == "head"
end



-- DESTROYS the heavy render objects of a plant model in ONE fast pass while
-- KEEPING what automation needs:
--   * the Model itself (name/attributes -> Plant Target still finds it)
--   * one anchor/pivot part + any part hosting the prompt/billboard
--   * the ProximityPrompt (Auto Collect Fruit still harvests)
--   * the BillboardGui name/weight labels (filters still read them)
--
-- SPEED: single GetDescendants() pass, no per-part re-scans (the old code was
-- O(n²) which is why it felt slow). We first note which parts host a prompt or
-- billboard, then destroy everything else in the same collected list.
-- Makes a part basically free to render without destroying it (so any prompt
-- that lives on / gets attached to it later still works).
--
-- keepSize = true  -> DON'T resize the part.
--   This matters for the regrow bug: the game's plant code measures part
--   geometry (the ".Size" reads in VenusFlyTrap/VenomSpitter controllers) to
--   work out where a new fruit goes and where to attach its Harvest prompt.
--   Collapsing a plant's Rig parts to 0.05 studs corrupted that math, so on
--   your OWN plot fruit could regrow without ever getting a usable prompt —
--   the collector then had nothing to fire.
--   Shrinking was only ever a shadow workaround, and it isn't needed:
--   CastShadow = false already removes the shadow completely.
local function neutralisePart(p, keepSize)
    p.Transparency  = 1
    -- LocalTransparencyModifier forces the CLIENT to skip rendering this part
    -- even if the game re-sets Transparency back to 0 (which is what caused the
    -- leftover "plant shadow" silhouettes you could still see).
    p.LocalTransparencyModifier = 1
    p.CanCollide    = false
    p.CanQuery      = false
    p.CanTouch      = false
    p.CastShadow    = false        -- kill the drop shadow on the ground
    p.Material      = Enum.Material.SmoothPlastic
    p.Reflectance   = 0
    -- MeshParts keep casting a shadow from their mesh unless the texture is
    -- cleared too; blanking it removes the last visible trace.
    if p:IsA("MeshPart") then
        pcall(function() p.TextureID = "" end)
    end
    -- Shrink ONLY when we're allowed to (see keepSize note above). CastShadow
    -- is already off, so the shadow is gone either way.
    if not keepSize then
        pcall(function()
            p.Size = Vector3.new(0.05, 0.05, 0.05)
        end)
    end
end



-- hardDestroy = true  -> destroy heavy parts (max FPS)  [used on INITIAL sweep]
-- hardDestroy = false -> only make parts cheap, DON'T destroy them
--                        [used on plants/fruit that GROW in later, so the game
--                         can still attach a Harvest prompt to them -> Auto
--                         Collect Fruit keeps working after every regrow]
local function stripPlantVisuals(model, hardDestroy)
    if strippedPlants[model] then return end
    strippedPlants[model] = true

    local desc = model:GetDescendants()   -- ONE traversal only

    -- always kill pure-visual objects (safe — these never host prompts)
    for _, d in ipairs(desc) do
        if d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance")
        or d:IsA("SpecialMesh") or d:IsA("ParticleEmitter") or d:IsA("Trail")
        or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles")
        or d:IsA("Light") then
            d:Destroy()
        end
    end

    if not hardDestroy then
        -- LIGHT touch: keep every BasePart (so future Harvest prompts attach
        -- correctly) but make them all cheap to render. Sizes are PRESERVED so
        -- the game can still work out where regrown fruit goes.
        for _, d in ipairs(desc) do
            if d:IsA("BasePart") then
                neutralisePart(d, true)
            end
        end
        return
    end

    -- HARD destroy path (initial sweep): keep only an anchor + prompt/billboard
    -- hosts + any STRUCTURAL part (Rig.RootPart etc. — the game's plant
    -- controllers reference these every frame, so destroying them causes the
    -- "RootPart is not a valid member" error spam that lags the game).
    local keeper = model.PrimaryPart
    local needed = {}
    for _, d in ipairs(desc) do
        if d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
            local p = d.Parent
            if p and p:IsA("BasePart") then
                needed[p] = true
                keeper = keeper or p
            end
        elseif d:IsA("BasePart") and isStructuralPart(d) then
            -- NEVER destroy Rig root parts — just neutralise them below
            needed[d] = true
        end
    end
    if not keeper then
        for _, d in ipairs(desc) do
            if d:IsA("BasePart") then keeper = d break end
        end
    end

    for _, d in ipairs(desc) do
        if d:IsA("BasePart") then
            if d ~= keeper and not needed[d] then
                d:Destroy()
            elseif needed[d] then
                neutralisePart(d)   -- keep it, but make it free to render
            end
        end
    end


    if keeper and keeper.Parent then
        neutralisePart(keeper)
    end
end

-- Fruits are often SEPARATE instances (a fruit model / part with its own
-- Harvest prompt), not always inside the plant model. So Remove Plants also
-- strips fruit visuals: destroy the heavy mesh parts but KEEP the part hosting
-- the Harvest ProximityPrompt + name/weight BillboardGui, so Auto Collect
-- Fruit still harvests and the weight/mutation filters still read correctly.
local strippedFruits = setmetatable({}, { __mode = "k" })  -- [inst]=true (done)

local function stripFruitVisuals(inst)
    if strippedFruits[inst] then return end
    strippedFruits[inst] = true

    local desc = inst:GetDescendants()

    -- 1) always kill pure-visual objects (never host prompts)
    for _, d in ipairs(desc) do
        if d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance")
        or d:IsA("SpecialMesh") or d:IsA("ParticleEmitter") or d:IsA("Trail")
        or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles")
        or d:IsA("Light") then
            pcall(function() d:Destroy() end)
        end
    end

    -- 2) note which parts host a prompt / billboard — these MUST be kept
    local keep = {}
    for _, d in ipairs(desc) do
        if d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
            local p = d.Parent
            if p and p:IsA("BasePart") then keep[p] = true end
        end
    end
    if inst:IsA("BasePart") then keep[inst] = true end

    -- 3) NEVER destroy the parts — only make them free to render.
    --
    -- REGROW FIX: destroying a fruit part meant that when the fruit grew back,
    -- the game had nothing left to attach its Harvest ProximityPrompt to, so
    -- Auto Collect Fruit silently stopped working after the first harvest.
    -- Keeping every part alive (invisible, real size, no shadow) costs almost
    -- nothing to render and guarantees the prompt can reattach.
    for _, d in ipairs(desc) do
        if d:IsA("BasePart") then
            neutralisePart(d, true)
        end
    end
end

-- Strips a single world instance if it's a fruit (by Harvest prompt or the
-- isFruit() weight/attribute check).
local function stripFruitAt(inst)
    if inst:IsA("ProximityPrompt") and isHarvestPrompt(inst) then
        local model = promptModel(inst)
        if model then stripFruitVisuals(model) end
    elseif isFruit(inst) then
        stripFruitVisuals(inst)
    end
end

-- Is this object a pure visual (safe to destroy — never hosts a prompt)?
local function isVisualObject(d)
    return d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance")
        or d:IsA("SpecialMesh") or d:IsA("ParticleEmitter") or d:IsA("Trail")
        or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles")
        or d:IsA("Light")
end

-- Parts that host (or hosted) a Harvest ProximityPrompt / name-weight
-- BillboardGui. These are NEVER destroyed by the regrow killer, so Auto Collect
-- Fruit + the weight/mutation filters keep working. Weak keys so destroyed
-- parts don't leak.
local promptHosts = setmetatable({}, { __mode = "k" })

-- Does this part currently host a prompt / billboard (or did before)?
local function partHostsPrompt(part)
    if promptHosts[part] then return true end
    for _, ch in ipairs(part:GetChildren()) do
        if ch:IsA("ProximityPrompt") or ch:IsA("BillboardGui") then
            promptHosts[part] = true
            return true
        end
    end
    return false
end

-- REGROW / NOT-FULLY-GROWN FRUIT KILLER:
-- When a plant we already stripped grows a NEW fruit (even a tiny, not-yet-ripe
-- one), the game adds fresh visual objects (meshes/decals/parts) UNDER that
-- plant model. Because the model is already in `strippedPlants`, our normal
-- pass ignores it — so the growing fruit would pop back into view AND keep
-- lagging (the heavy MeshParts stay in memory even when made invisible).
--
-- So this now actually DESTROYS the growing-fruit parts for real FPS, and only
-- KEEPS a part when it hosts a Harvest ProximityPrompt or name/weight
-- BillboardGui (so Auto Sprinkler / Watering / Collect Fruit + filters still
-- work). It's called on a short delay after the instance appears, giving the
-- game time to attach the prompt first so we correctly detect + keep the host.
local function stripRegrownInstance(inst)
    if not (inst and inst.Parent) then return end

    -- Find the owning plant: either a model we've ALREADY stripped (tracked in
    -- strippedPlants) or a model recognised as a plant by name/attribute.
    -- Walking the ancestor chain (instead of just the first Model) is what
    -- makes this catch fruit that grows a few levels deep inside the plant.
    local owner = nil
    local anc = inst
    local depth = 0
    while anc and depth < 12 do
        if strippedPlants[anc] then owner = anc break end
        if anc:IsA("Model") and isPlantInstance(anc) then owner = anc break end
        anc = anc.Parent
        depth = depth + 1
    end
    if not owner then return end

    -- A prompt / billboard itself: protect its host part, never destroy.
    if inst:IsA("ProximityPrompt") or inst:IsA("BillboardGui") then
        if inst.Parent and inst.Parent:IsA("BasePart") then
            promptHosts[inst.Parent] = true
            neutralisePart(inst.Parent, true)
        end
        return
    end

    if isVisualObject(inst) then
        -- pure visual (decal/mesh/particle) — always safe to destroy
        pcall(function() inst:Destroy() end)
    elseif inst:IsA("BasePart") then
        -- NEVER destroy a regrown part.
        --
        -- THIS WAS THE BUG: a fruit part is added to the plant FIRST, and the
        -- game attaches its Harvest ProximityPrompt a moment LATER. We checked
        -- partHostsPrompt() after only 0.25s, so the prompt usually wasn't
        -- there yet, we destroyed the part, and the prompt could never be
        -- created -> the Fruit Collector had nothing to fire and "stopped
        -- working" on every regrow while Remove Plants was on.
        --
        -- Now we always just neutralise it: invisible, no shadow, no collision,
        -- but at its REAL size. Practically free to render, and the prompt
        -- attaches normally so collecting keeps working forever.
        neutralisePart(inst, true)
    elseif inst:IsA("Model") then

        -- a whole fruit sub-model streamed in at once. First note any
        -- prompt/billboard hosts so we keep them, then destroy the rest.
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
                if d.Parent and d.Parent:IsA("BasePart") then
                    promptHosts[d.Parent] = true
                end
            end
        end
        for _, d in ipairs(inst:GetDescendants()) do
            if isVisualObject(d) then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then
                -- same regrow fix as above: keep every part, just make it
                -- free to render so the Harvest prompt can still attach.
                neutralisePart(d, true)
            end
        end
    end
end





local function applyRemovePlants(on)
    removePlantsOn = on

    -- FIRST: kill the per-plant animation controllers. This is the actual fix
    -- for the lag — it stops the "RootPart is not a valid member" error spam
    -- that VenusFlyTrapController / VenomSpitterController throw every frame
    -- once we start destroying plant parts.
    if on then
        disablePlantControllers()
    end

    if not on then

        -- can't undo a destroy; just stop stripping NEW plants.
        if plantHideConn then
            plantHideConn:Disconnect()
            plantHideConn = nil
        end
        plantResweepLoop = nil   -- loop checks removePlantsOn and exits
        print("[Arjhay Hub] Remove Plants: OFF (already-removed plants return on rejoin)")
        return
    end


    -- ============================================================
    --  GARDENS-ONLY BATCH SWEEP
    --
    --  THE LAG + "EVERYTHING GOT DESTROYED" FIX:
    --  The old sweep called workspace:GetDescendants() — that walks the ENTIRE
    --  map (tens of thousands of instances) and then ran isFruit() on each one,
    --  which reads several attributes per instance. That alone froze the game,
    --  and because every streamed model went through the strip path, map/world
    --  objects got wrecked too.
    --
    --  Now we NEVER touch the whole workspace. We only walk
    --      Workspace.Gardens.Plot#.Plants
    --  which is exactly where crops live — a few hundred instances instead of
    --  tens of thousands. Everything outside Gardens is completely untouched,
    --  so the map/world can never disappear again.
    --
    --  TWO LEVELS, as requested:
    --    * OTHER players' plots -> FULL destroy (no proxy, nothing there needs
    --                              to work, so we reclaim the most FPS)
    --    * MY OWN plot          -> SEMI strip (model stays, heavy meshes go,
    --                              Rig + Harvest prompt + name/weight billboard
    --                              are kept) so Fruit Collector, Auto Sprinkler
    --                              (Plant Target) and Auto Watering Can all
    --                              keep working on my plants.
    -- ============================================================
    local BATCH_SIZE = 40   -- plants processed per frame (small = smooth)

    task.spawn(function()
        local gardens = getGardens()
        if not gardens then
            warn("[Arjhay Hub] Remove Plants: no Workspace.Gardens folder found")
            return
        end

        local myPlot = getMyPlot()

        -- HARD SAFETY STOP. getMyPlot() can now return nil (it no longer
        -- guesses at the nearest plot, so it can't hand back a neighbour's
        -- garden). Without this check a nil plot means "no plot is mine", and
        -- the sweep below would put MY OWN crops in the `others` list and
        -- destroy them outright. Refusing to run is the only safe response.
        if not myPlot then
            warn("[Arjhay Hub] Remove Plants: can't confirm which plot is yours — "
              .. "doing NOTHING so your own garden is never destroyed. "
              .. "Stand on your plot and toggle it again.")
            return
        end

        print("[Arjhay Hub] Remove Plants: my plot =", myPlot.Name)

        -- ---------- PHASE 1: collect crops, split mine vs others ----------
        local mine, others = {}, {}
        for _, plot in ipairs(gardens:GetChildren()) do
            -- (no `continue` here — some Luau linters reject it, so we just
            --  nest the checks instead)
            if string.match(plot.Name, "^Plot%d+$") then
                local plantsFolder = plot:FindFirstChild("Plants")
                if plantsFolder then
                    local isMine = (plot == myPlot)
                    for _, crop in ipairs(plantsFolder:GetChildren()) do
                        if crop:IsA("Model") then
                            if isMine then
                                mine[#mine + 1] = crop
                            else
                                others[#others + 1] = crop
                            end
                        end
                    end
                end
            end
        end

        print(string.format(
            "[Arjhay Hub] Remove Plants: %d of MY crops (semi strip) + %d other crops (full destroy)",
            #mine, #others))

        -- ---------- PHASE 2a: OTHER gardens -> FULL destroy ----------
        local i = 1
        while i <= #others do
            if not removePlantsOn then return end
            local stop = math.min(i + BATCH_SIZE - 1, #others)
            for j = i, stop do
                local m = others[j]
                if m and m.Parent then
                    destroyWhole(m, false)   -- no proxy needed
                end
            end
            i = stop + 1
            task.wait()
        end

        -- ---------- PHASE 2b: MY garden -> SEMI strip ----------
        i = 1
        while i <= #mine do
            if not removePlantsOn then return end
            local stop = math.min(i + BATCH_SIZE - 1, #mine)
            for j = i, stop do
                local m = mine[j]
                if m and m.Parent then
                    -- LIGHT strip on MY OWN plot (hardDestroy = false).
                    -- Keeps every BasePart alive (invisible + tiny) so the game
                    -- can always attach a Harvest prompt when fruit regrows —
                    -- that's what keeps the Fruit Collector working. The heavy
                    -- visuals (meshes/decals/particles/shadows) are still gone,
                    -- so we keep almost all of the FPS gain.
                    pcall(function() stripPlantVisuals(m, false) end)
                end
            end
            i = stop + 1
            task.wait()
        end

        print("[Arjhay Hub] Remove Plants: sweep complete (Gardens only)")
    end)

    -- ============================================================
    --  LIVE HANDLER for crops that stream / grow in later.
    --
    --  Scoped to garden content ONLY. The old handler ran on EVERY instance
    --  added anywhere in the workspace and called stripFruitAt() +
    --  stripRegrownInstance() on it — that fired constantly (huge lag) and was
    --  what let non-plant objects get wrecked. Now we bail out immediately
    --  unless the new instance is inside a Gardens > Plot# chain.
    -- ============================================================
    if not plantHideConn then
        plantHideConn = workspace.DescendantAdded:Connect(function(inst)
            if not removePlantsOn then return end

            -- CHEAP early exit: ignore anything not in a garden plot.
            local plot = plotOf(inst)
            if not plot then return end

            -- Same safety stop as the sweep: with no confirmed plot we must not
            -- destroy anything, or an unresolved lookup would delete our own
            -- crops as they stream in.
            local myPlot = getMyPlot()
            if not myPlot then return end

            local isMine = (plot == myPlot)

            if inst:IsA("Model") and isInsidePlantsFolder(inst) then
                -- a brand new crop model
                task.delay(0.25, function()
                    if not removePlantsOn then return end
                    if not (inst and inst.Parent) then return end
                    if isMine then
                        -- light strip on my own plot so regrown fruit can
                        -- still receive its Harvest prompt (see above)
                        pcall(function() stripPlantVisuals(inst, false) end)
                    else
                        destroyWhole(inst, false)
                    end
                end)
                return
            end

            -- Fruit / visuals growing INSIDE a crop we already handled.
            -- For OTHER players' plots the whole crop is already gone, so there
            -- is nothing to do here. Only my own plot needs the regrow cleanup,
            -- and only there do we keep the prompt/billboard alive.
            if isMine then
                task.delay(0.25, function()
                    if not removePlantsOn then return end
                    if not (inst and inst.Parent) then return end
                    stripFruitAt(inst)
                    stripRegrownInstance(inst)
                end)
            end
        end)
    end

    print("[Arjhay Hub] Remove Plants: ON (other gardens destroyed, my garden semi-stripped)")
end


makeIconToggle(perf, "🌿", "Remove Plants", 1, function(on)
    applyRemovePlants(on)
end)

--============================================================
--  REMOVE WEATHER VISUALS  (VERY thorough)
--  Kills: rain / snow / storm / fog / wind / clouds / atmosphere,
--  weather MODELS (full-screen effect parts), weather sounds, and any
--  particle/beam/trail whose name OR ancestor name looks like weather.
--  Everything is restorable and re-applied to newly-streamed objects.
--============================================================
local Lighting = game:GetService("Lighting")
local weatherOn        = false
local weatherHideConn  = nil
local weatherScanLoop  = nil
local hiddenWeather    = {}   -- [instance] = savedValue/parent, for restore

-- keyword test: does this name look weather-related?
local WEATHER_WORDS = {
    "weather","rain","snow","storm","cloud","fog","mist","wind","blizzard",
    "thunder","lightning","hail","sandstorm","tornado","meteor","aurora",
    "sunbeam","godray","overlay","droplet","puddle","frost","ice",
}

-- Load the REAL weather names from the game's WeatherData module so we target
-- the exact weather events this game uses (Rain, Lightning, Rainbow, Snowfall,
-- Starfall, Aurora, Sunburst, Eclipse, ...). Each name (and simple variants) is
-- added to the keyword list above so their models/particles/sounds get hidden.
do
    local ok, mod = pcall(function()
        local sm = ReplicatedStorage:FindFirstChild("SharedModules")
        local wd = sm and sm:FindFirstChild("WeatherData")
        return wd and require(wd)
    end)
    if ok and type(mod) == "table" and type(mod.Data) == "table" then
        for _, entry in ipairs(mod.Data) do
            if type(entry) == "table" and type(entry.Name) == "string" then
                local n = string.lower(entry.Name)
                table.insert(WEATHER_WORDS, n)
                -- also add a trimmed root (e.g. "snowfall" -> "snow", "starfall" -> "star")
                local root = n:gsub("fall$", ""):gsub("burst$", ""):gsub("storm$", "")
                if root ~= n and #root >= 3 then
                    table.insert(WEATHER_WORDS, root)
                end
            end
        end
        print("[Arjhay Hub] Loaded weather names from WeatherData (" ..
            tostring(#mod.Data) .. " events)")
    else
        print("[Arjhay Hub] WeatherData not found — using default weather keywords")
    end
end
local function nameLooksWeather(name)
    name = string.lower(name)
    for _, w in ipairs(WEATHER_WORDS) do
        if string.find(name, w, 1, true) then return true end
    end
    return false
end

-- true if the instance OR any ancestor looks weather-related
local function isWeatherRelated(inst)
    if nameLooksWeather(inst.Name) then return true end
    local a = inst.Parent
    local depth = 0
    while a and depth < 6 do
        if nameLooksWeather(a.Name) then return true end
        a = a.Parent
        depth = depth + 1
    end
    return false
end

-- hide/disable a single instance (remembering original for restore)
local function hideWeatherInstance(inst, hidden)
    if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
    or inst:IsA("Smoke") or inst:IsA("Fire") then
        if hidden then
            if hiddenWeather[inst] == nil then hiddenWeather[inst] = inst.Enabled end
            inst.Enabled = false
        elseif hiddenWeather[inst] ~= nil then
            inst.Enabled = hiddenWeather[inst]; hiddenWeather[inst] = nil
        end
    elseif inst:IsA("Sound") then
        if hidden then
            if hiddenWeather[inst] == nil then hiddenWeather[inst] = inst.Volume end
            inst.Volume = 0
        elseif hiddenWeather[inst] ~= nil then
            inst.Volume = hiddenWeather[inst]; hiddenWeather[inst] = nil
        end
    elseif inst:IsA("BasePart") then
        -- big full-screen weather planes: make them invisible (client only)
        if hidden then
            inst.LocalTransparencyModifier = 1
        else
            inst.LocalTransparencyModifier = 0
        end
    end
end

-- one full sweep of everything currently loaded
local function sweepWeather(on)
    -- 1) Lighting children: Atmosphere / Clouds / Sky / weather PostEffects
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("Atmosphere") or e:IsA("Clouds")
        or (e:IsA("PostEffect") and nameLooksWeather(e.Name)) then
            if on then
                if hiddenWeather[e] == nil then hiddenWeather[e] = e.Parent end
                e.Parent = nil            -- fully remove (kept in table)
            elseif hiddenWeather[e] then
                e.Parent = hiddenWeather[e]; hiddenWeather[e] = nil
            end
        end
    end

    -- 2) Terrain clouds + decoration
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local clouds = terrain:FindFirstChildOfClass("Clouds")
        if clouds then
            if on then
                if hiddenWeather[clouds] == nil then hiddenWeather[clouds] = clouds.Enabled end
                clouds.Enabled = false
            elseif hiddenWeather[clouds] ~= nil then
                clouds.Enabled = hiddenWeather[clouds]; hiddenWeather[clouds] = nil
            end
        end
        if on then
            if hiddenWeather["_terrainDeco"] == nil then hiddenWeather["_terrainDeco"] = terrain.Decoration end
            pcall(function() terrain.Decoration = false end)
        elseif hiddenWeather["_terrainDeco"] ~= nil then
            pcall(function() terrain.Decoration = hiddenWeather["_terrainDeco"] end)
            hiddenWeather["_terrainDeco"] = nil
        end
    end

    -- 3) Everything in workspace that looks weather-related
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
        or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sound") then
            if isWeatherRelated(inst) then
                hideWeatherInstance(inst, on)
            end
        elseif inst:IsA("BasePart") and nameLooksWeather(inst.Name) then
            hideWeatherInstance(inst, on)
        end
    end
end

local function applyRemoveWeather(on)
    weatherOn = on
    sweepWeather(on)

    if on then
        -- catch newly-streamed weather objects instantly
        if not weatherHideConn then
            weatherHideConn = workspace.DescendantAdded:Connect(function(inst)
                if not weatherOn then return end
                task.defer(function()
                    if not (weatherOn and inst and inst.Parent) then return end
                    if (inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
                        or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sound"))
                    and isWeatherRelated(inst) then
                        hideWeatherInstance(inst, true)
                    elseif inst:IsA("BasePart") and nameLooksWeather(inst.Name) then
                        hideWeatherInstance(inst, true)
                    end
                end)
            end)
        end
        -- periodic re-sweep (some games re-enable weather on a timer)
        if not weatherScanLoop then
            weatherScanLoop = task.spawn(function()
                while weatherOn and guiAlive do
                    sweepWeather(true)
                    task.wait(3)
                end
            end)
        end
    else
        if weatherHideConn then weatherHideConn:Disconnect(); weatherHideConn = nil end
        weatherScanLoop = nil   -- loop checks weatherOn and exits
    end
    print("[Arjhay Hub] Remove Weather Visuals:", on)
end

makeIconToggle(perf, "🌦", "Remove Weathers Visuals", 2, function(on)
    applyRemoveWeather(on)
end)

--============================================================

--  FPS BOOST  (AGGRESSIVE)


--  Strips almost everything that costs GPU/CPU while keeping the game
--  playable & keeping plant models intact (so Plant Target still works):
--   * lowest render quality + shadows off + no post effects
--   * flat lighting (no fog / no atmosphere)
--   * all materials -> SmoothPlastic, no reflections, casts shadow off
--   * kill every particle / trail / beam / smoke / fire / sparkle
--   * terrain water flattened, decoration off
--   * skips the player's OWN character & the Arjhay Hub GUI
--  Everything is saved and fully restored when toggled off.
--============================================================
local Terrain      = workspace:FindFirstChildOfClass("Terrain")
local fpsOn        = false
local fpsSaved     = {}     -- [instance/key] = original value
local fpsAddedConn = nil
local fpsScanLoop  = nil
local fpsCullLoop  = nil

-- "Focus My Garden": when FPS boost is on, hide everything FAR from you so only
-- your garden/plot stays visible (huge smoothness gain). Distance in studs —
-- anything whose nearest point is beyond this from you gets hidden.
local FPS_CULL_RADIUS = 120
-- remembers what the culler hid so we can un-hide when it comes back / on off.
local fpsCulled = setmetatable({}, { __mode = "k" })  -- [model] = true


-- Should we leave this part ALONE? (our own character / GUI / plants)
local function fpsSkip(inst)
    local char = LocalPlayer.Character
    if char and inst:IsDescendantOf(char) then return true end
    return false
end

-- ---- FOCUS MY GARDEN (distance culling) --------------------------------
-- Show/hide an entire model at once (client-only): transparency + no render.
-- We use a cheap approach: toggle each BasePart's LocalTransparencyModifier
-- and its particle/decal render. This does NOT destroy anything, so plants and
-- automation still work; it's purely what YOU see.
local function setModelRendered(model, visible)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = visible and 0 or 1
        elseif d:IsA("Decal") or d:IsA("Texture") then
            d.LocalTransparencyModifier = visible and 0 or 1
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
            or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
            -- only toggle off for culling; don't force-on (FPS boost disables these anyway)
            if not visible then d.Enabled = false end
        end
    end
end

-- Cheap position read for a model (pivot; falls back to a part).
local function modelPos(model)
    local ok, cf = pcall(function() return model:GetPivot() end)
    if ok and cf then return cf.Position end
    local part = model:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

-- One culling pass: hide models farther than FPS_CULL_RADIUS from you,
-- reveal ones that come back into range. Skips your own character, the
-- workspace Terrain/Camera, and huge baseplate-like models.
local function cullPass()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local me = hrp.Position

    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m ~= char then
            -- skip other players' characters? no — we WANT to hide far players.
            local pos = modelPos(m)
            if pos then
                local far = (pos - me).Magnitude > FPS_CULL_RADIUS
                if far and not fpsCulled[m] then
                    fpsCulled[m] = true
                    setModelRendered(m, false)
                elseif (not far) and fpsCulled[m] then
                    fpsCulled[m] = nil
                    setModelRendered(m, true)
                end
            end
        end
    end
end

-- Reveal everything the culler hid (used when FPS boost turns off).
local function cullRestoreAll()
    for m in pairs(fpsCulled) do
        if m and m.Parent then
            setModelRendered(m, true)
        end
        fpsCulled[m] = nil
    end
end


-- strip one descendant for max FPS (remembering originals)
local function fpsStripInstance(d)
    if d:IsA("BasePart") then
        if fpsSkip(d) then return end
        if fpsSaved[d] == nil then
            fpsSaved[d] = {
                Material     = d.Material,
                Reflectance  = d.Reflectance,
                CastShadow   = d.CastShadow,
            }
        end
        d.Material    = Enum.Material.SmoothPlastic
        d.Reflectance = 0
        d.CastShadow  = false
    elseif d:IsA("Decal") or d:IsA("Texture") then
        -- textures are expensive; hide them (client visual only)
        if fpsSaved[d] == nil then fpsSaved[d] = d.Transparency end
        d.Transparency = 1
    elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
        or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
        if fpsSaved[d] == nil then fpsSaved[d] = d.Enabled end
        d.Enabled = false
    elseif d:IsA("SpecialMesh") or d:IsA("MeshPart") then
        -- lower mesh texture load where possible
        if d:IsA("MeshPart") then
            if fpsSkip(d) then return end
            if fpsSaved[d] == nil then
                fpsSaved[d] = { Material = d.Material, Reflectance = d.Reflectance, CastShadow = d.CastShadow }
            end
            d.Material    = Enum.Material.SmoothPlastic
            d.Reflectance = 0
            d.CastShadow  = false
        end
    end
end

-- restore one descendant
local function fpsRestoreInstance(d)
    local saved = fpsSaved[d]
    if saved == nil then return end
    if type(saved) == "table" then
        pcall(function()
            if saved.Material    ~= nil then d.Material    = saved.Material end
            if saved.Reflectance ~= nil then d.Reflectance = saved.Reflectance end
            if saved.CastShadow  ~= nil then d.CastShadow  = saved.CastShadow end
        end)
    else
        if d:IsA("Decal") or d:IsA("Texture") then
            pcall(function() d.Transparency = saved end)
        else
            pcall(function() d.Enabled = saved end)
        end
    end
    fpsSaved[d] = nil
end

local function applyFpsBoost(on)
    fpsOn = on
    if on then
        --── LIGHTING ──────────────────────────────────────
        fpsSaved.GlobalShadows   = Lighting.GlobalShadows
        fpsSaved.FogEnd          = Lighting.FogEnd
        fpsSaved.FogStart        = Lighting.FogStart
        fpsSaved.EnvDiffuse      = Lighting.EnvironmentDiffuseScale
        fpsSaved.EnvSpecular     = Lighting.EnvironmentSpecularScale
        Lighting.GlobalShadows              = false
        Lighting.FogEnd                     = 1e6
        Lighting.FogStart                   = 1e6
        Lighting.EnvironmentDiffuseScale    = 0
        Lighting.EnvironmentSpecularScale   = 0

        -- remove post effects + atmosphere (kept so we can restore)
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") or e:IsA("Atmosphere") or e:IsA("Clouds") then
                if fpsSaved[e] == nil then fpsSaved[e] = e.Parent end
                e.Parent = nil
            end
        end

        --── RENDER QUALITY ───────────────────────────────
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function()
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
        end)

        --── TERRAIN ──────────────────────────────────────
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            fpsSaved._twSize   = terrain.WaterWaveSize
            fpsSaved._twSpeed  = terrain.WaterWaveSpeed
            fpsSaved._twRefl   = terrain.WaterReflectance
            fpsSaved._twTrans  = terrain.WaterTransparency
            fpsSaved._tDeco    = terrain.Decoration
            terrain.WaterWaveSize     = 0
            terrain.WaterWaveSpeed    = 0
            terrain.WaterReflectance  = 0
            terrain.WaterTransparency = 0
            pcall(function() terrain.Decoration = false end)
        end

        --── STRIP THE WHOLE WORLD ────────────────────────
        for _, d in ipairs(workspace:GetDescendants()) do
            fpsStripInstance(d)
        end

        -- keep stripping anything that streams in later
        if not fpsAddedConn then
            fpsAddedConn = workspace.DescendantAdded:Connect(function(d)
                if not fpsOn then return end
                task.defer(function()
                    if fpsOn and d and d.Parent then fpsStripInstance(d) end
                end)
            end)
        end

        -- periodic re-sweep (grown plants / streamed models)
        if not fpsScanLoop then
            fpsScanLoop = task.spawn(function()
                while fpsOn and guiAlive do
                    for _, d in ipairs(workspace:GetDescendants()) do
                        if fpsSaved[d] == nil then fpsStripInstance(d) end
                    end
                    task.wait(5)
                end
            end)
        end

        --── FOCUS MY GARDEN (distance culling) ───────────
        -- Hide everything far from you so only your nearby garden renders.
        -- Runs continuously and follows you as you move.
        if not fpsCullLoop then
            fpsCullLoop = task.spawn(function()
                while fpsOn and guiAlive do
                    local okc = pcall(cullPass)
                    if not okc then break end
                    task.wait(0.5)
                end
            end)
        end
    else
        --── STOP CULLING + REVEAL EVERYTHING ─────────────
        fpsCullLoop = nil          -- loop checks fpsOn and exits
        cullRestoreAll()

        --── RESTORE LIGHTING ─────────────────────────────
        if fpsSaved.GlobalShadows ~= nil then Lighting.GlobalShadows = fpsSaved.GlobalShadows end
        if fpsSaved.FogEnd        ~= nil then Lighting.FogEnd        = fpsSaved.FogEnd end
        if fpsSaved.FogStart      ~= nil then Lighting.FogStart      = fpsSaved.FogStart end
        if fpsSaved.EnvDiffuse    ~= nil then Lighting.EnvironmentDiffuseScale  = fpsSaved.EnvDiffuse end
        if fpsSaved.EnvSpecular   ~= nil then Lighting.EnvironmentSpecularScale = fpsSaved.EnvSpecular end

        --── RESTORE TERRAIN ──────────────────────────────
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            if fpsSaved._twSize  ~= nil then terrain.WaterWaveSize     = fpsSaved._twSize end
            if fpsSaved._twSpeed ~= nil then terrain.WaterWaveSpeed    = fpsSaved._twSpeed end
            if fpsSaved._twRefl  ~= nil then terrain.WaterReflectance  = fpsSaved._twRefl end
            if fpsSaved._twTrans ~= nil then terrain.WaterTransparency = fpsSaved._twTrans end
            if fpsSaved._tDeco   ~= nil then pcall(function() terrain.Decoration = fpsSaved._tDeco end) end
        end

        -- stop the loops first so they don't re-strip while we restore
        if fpsAddedConn then fpsAddedConn:Disconnect(); fpsAddedConn = nil end
        fpsScanLoop = nil

        --── RESTORE EVERY INSTANCE ───────────────────────
        for key, val in pairs(fpsSaved) do
            if typeof(key) == "Instance" then
                if (key:IsA("PostEffect") or key:IsA("Atmosphere") or key:IsA("Clouds")) then
                    -- these were re-parented out; put them back
                    pcall(function() key.Parent = val end)
                    fpsSaved[key] = nil
                else
                    fpsRestoreInstance(key)
                end
            end
        end
        fpsSaved = {}
    end
    print("[Arjhay Hub] FPS Boost:", on)
end

makeIconToggle(perf, "🚀", "FPS Boost", 3, function(on)
    applyFpsBoost(on)
end)

--============================================================
--  HOME TAB  →  FARM DETAILS
--
--  Shows a live summary of YOUR garden:
--    • Total Plants / Total Fruits
--    • Ready (harvestable) count
--    • Variant breakdown (Normal / Gold / Rainbow)
--    • Every plant type you own, GROUPED BY RARITY, with the count and the
--      BIGGEST kg seen for that type
--    • Mutation breakdown (Frozen / Ignited / Aurora ...)
--
--  All data comes from the real garden hierarchy
--  (Workspace.Gardens.Plot#.Plants), the plant attributes, and the name/weight
--  BillboardGui above each plant — the same sources the Fruit Collector uses.
--============================================================
-- IMPORTANT (Luau limit): the main chunk already declares close to 200 local
-- variables, and Luau allows a MAXIMUM OF 200 locals per function. A plain
-- `do ... end` block does NOT create a new function, so every local in here
-- still counted against the main chunk — that produced:
--     "Out of local registers when trying to allocate fdLine: exceeded limit 200"
-- and the whole script failed to run (no GUI at all).
--
-- Wrapping this section in an IMMEDIATELY-CALLED FUNCTION gives it its own
-- fresh register space, so all of the Farm Details locals live in their own
-- function and the main chunk only spends ONE more local slot.
local function buildFarmDetails()
local homePage = pages["Home"]

local farmState = {
    show    = false,   -- "Show Farm Details" toggle
    -- Fixed 2 second auto refresh (the old "Auto Refresh (seconds)" input was
    -- removed — the panel now always refreshes every 2s while the toggle is on).
    refresh = 2,
    -- true while a scan is running, so overlapping refreshes are dropped
    -- instead of stacking up and fighting each other.
    scanning = false,
}

-- NOTE: there used to be a `bestKgSeen` table here that remembered the highest
-- kg EVER read per plant type and forced the panel's Max back up to it.
--
-- IT HAD TO GO — it was the reason "the Max kg still the same even when there
-- are no fruits in my garden". Once a value was recorded it became a permanent
-- floor, so harvesting everything left the old number frozen on screen.
--
-- It is no longer needed either. SizeMulti is an attribute on the fruit model,
-- so it replicates with the crop and is readable without walking over. Once a
-- seed's base weight is learned (see SEED_BASE_WEIGHT / learnBaseWeight), EVERY
-- crop of that seed computes base x its own SizeMulti — which both covers
-- plants you have never approached AND drops to nothing the moment the fruit is
-- actually gone.


-- Yield budget. Every heavy walk below calls step(); once we've touched enough
-- instances in the current frame it hands control back to the game.
--
-- THIS IS THE FREEZE FIX. The weight-reading pass added to readCropInfo walked
-- every part of every plant model with no yield at all, so the whole scan had
-- to finish inside one frame — that is the 1-2 second lock-up. The same work
-- now spreads across several frames.
local WORK_PER_FRAME = 400
local workCounter = 0
local function step()
    workCounter = workCounter + 1
    if workCounter >= WORK_PER_FRAME then
        workCounter = 0
        task.wait()
    end
end

-- Reads weight / variant / mutations off an instance in ONE GetAttributes call.
--
-- The other half of the freeze: getFruitWeight, getFruitVariant and
-- getFruitMutations do about a dozen separate pcall'd GetAttribute calls
-- between them, and running all three on every part of every plant model is
-- thousands of pcalls per refresh. One GetAttributes call returns the whole
-- table, so we read it once and pick out what we need.
--
-- Returns (weight|nil, variant|nil, mutationSet|nil); a nil weight means this
-- instance carries no fruit data.
local VARIANT_KEYS  = { variant = true, type = true, rarity = true }
local MUTATION_KEYS = { mutation = true, mutations = true }

-- Is this attribute name a weight?
--
-- This used to be an exact-match set of { weight, kg, mass }, and that is a big
-- part of "still can't see the max kg": the weight attribute is very often NOT
-- named plain "Weight". Real names seen on these fruits include FruitWeight,
-- WeightKG, Weight_KG and CurrentWeight, none of which matched, so the whole
-- attribute path returned nil and the max fell back to billboard text — which
-- only exists when you are standing next to the plant.
--
-- Substring matching catches all of those spellings. "Mass" stays exact so we
-- don't accidentally grab things like "Massive".
local function isWeightKey(lk)
    if lk == "mass" then return true end
    if string.find(lk, "weight", 1, true) then return true end
    -- "kg" only when it's a whole word / suffix, not inside another word
    if lk == "kg" or string.find(lk, "kg$") or string.find(lk, "[_%s]kg") then
        return true
    end
    return false
end

local function readAttrBundle(inst)
    local ok, attrs = pcall(function() return inst:GetAttributes() end)
    if not ok or not attrs then return nil end

    local weight, variant, muts
    for k, v in pairs(attrs) do
        local lk = string.lower(k)
        if isWeightKey(lk) then
            -- weight may arrive as a number OR as a string like "16.24kg"
            local n = (type(v) == "number") and v
                or (type(v) == "string" and tonumber(v:match("([%d%.]+)") or ""))
            if n and n > 0 and n > (weight or 0) then weight = n end
        elseif VARIANT_KEYS[lk] then

            if type(v) == "string" and v ~= "" then
                variant = variant or string.lower(v)
            end
        elseif MUTATION_KEYS[lk] then
            if type(v) == "string" and v ~= "" then
                muts = muts or {}
                for word in string.gmatch(string.lower(v), "[^,%s]+") do
                    muts[word] = true
                end
            end
        end
    end
    return weight, variant, muts
end


-- Rarity colors (used for the group headers, like the screenshot)
local RARITY_COLORS = {
    ["Common"]      = Color3.fromRGB(200, 200, 200),
    ["Uncommon"]    = Color3.fromRGB(120, 220, 120),
    ["Rare"]        = Color3.fromRGB(90, 160, 255),
    ["Epic"]        = Color3.fromRGB(180, 100, 255),
    ["Legendary"]   = Color3.fromRGB(255, 200, 70),
    ["Mythic"]      = Color3.fromRGB(255, 90, 160),
    ["Super"]       = Color3.fromRGB(255, 80, 80),
    ["Secret"]      = Color3.fromRGB(100, 255, 255),
}
-- Order the rarity groups are printed in (rarest first, like the screenshot).
--
-- "Unknown" is deliberately NOT in this list. Plants whose rarity we can't
-- resolve used to be printed under an "Unknown" header, which cluttered the
-- panel. Leaving it out means those plants are grouped under the fallback
-- rarity below instead, and no "Unknown" heading is ever shown.
local RARITY_ORDER = {
    "Secret", "Super", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common",
}

-- Where plants with no known rarity go (instead of a separate "Unknown" group).
local FALLBACK_RARITY = "Common"


-- Build a name -> rarity lookup from the game's seed/plant data if available.
--
-- THIS GAME's module is ReplicatedStorage.SharedModules.SeedData and it returns
-- a plain ARRAY of entries shaped like:
--     { SeedName = "Carrot", Rarity = "Common", ... }
-- Note the field is SeedName (NOT Name), which is why the lookup used to come
-- back empty and every plant fell through to the fallback rarity.
local PLANT_RARITY = {}
local PLANT_RARITY_COUNT = 0
do
    local ok = pcall(function()
        local sm = ReplicatedStorage:FindFirstChild("SharedModules")
        -- try a few likely module names that hold the seed table
        for _, modName in ipairs({ "SeedData", "PlantData", "ItemData", "SeedsData" }) do
            local m = sm and sm:FindFirstChild(modName)
            if m and m:IsA("ModuleScript") then
                local data = require(m)
                -- data is either the list directly, or wrapped in .Data
                local list = (type(data) == "table" and (data.Data or data)) or nil
                if type(list) == "table" then
                    for key, entry in pairs(list) do
                        if type(entry) == "table" then
                            -- THIS GAME uses SeedName, not Name
                            local nm = entry.SeedName or entry.Name or (type(key) == "string" and key)
                            local rar = entry.Rarity or entry.rarity or entry.Tier
                            if type(nm) == "string" and type(rar) == "string" then
                                -- NOTE: named rarityKey, not "key" — "key" is the
                                -- pairs() loop variable above and shadowing it here
                                -- makes this loop very easy to misread.
                                local rarityKey = string.lower(nm)
                                if PLANT_RARITY[rarityKey] == nil then
                                    PLANT_RARITY_COUNT = PLANT_RARITY_COUNT + 1
                                end
                                PLANT_RARITY[rarityKey] = rar
                            end
                        end
                    end
                end
            end
        end
    end)
    if ok and PLANT_RARITY_COUNT > 0 then
        print("[Arjhay Hub] Loaded " .. PLANT_RARITY_COUNT .. " plant rarities from SeedData")
    else
        warn("[Arjhay Hub] SeedData rarities not loaded — everything will show as "
            .. FALLBACK_RARITY)
    end
end

-- ============================================================
--  COMPUTED FRUIT WEIGHT
--
--  This is what lets the panel show the highest kg for EVERY crop without
--  walking over to it, and with Remove Plants still on.
--
--  WHAT THE DUMP PROVED (Moon Bloom, 10.81kg on screen):
--    * The crop stores NO weight anywhere. The fruit Model carries only
--      Age / MaxAge / SizeMulti / CorePartName / FruitId.
--    * SeedData has NO weight field either — the Moon Bloom entry is
--      PurchasePrice / Rarity / PlantModel / PrimeTime / YHeight / SeedName /
--      RestockChance / RestockValues / RestockShop / SeedShopDisplayOrder /
--      FruitImage / IsSingleHarvest. Nothing in kg.
--      (My previous "base weight x SizeMulti" guess assumed a field that does
--      not exist, which is why SEED_BASE_WEIGHT stayed empty and maxKg=0.)
--    * WeightFormat.FormatGrams(n) = "%.2fkg" of floor(n*100+0.5)/100, so the
--      rendered number is a plain kg value with no unit scaling.
--
--  WHERE THE BASE WEIGHT ACTUALLY LIVES:
--  The fruit's SizeMulti is a pure MULTIPLIER (GetRandomFruitSize rolls ~0.85
--  to 1.15 for the common tier). The Moon Bloom above had SizeMulti 1.4811 and
--  displayed 10.81kg, giving a base of 10.81 / 1.4811 = 7.30. That base is a
--  per-plant constant that has to come from the plant TEMPLATE, and the one
--  place the template exposes it is the fruit part's geometry in
--  ReplicatedStorage.Assets.Plants.<SeedName> — the same CorePartName the fruit
--  model points at. So we read the template's core part volume once per seed,
--  calibrate it against any fruit whose real kg we HAVE seen, and reuse that
--  ratio for every other fruit of that seed.
--
--  CALIBRATION IS THE HONEST PART OF THIS:
--  Rather than inventing a constant, we learn it. Any time a real kg is read
--  (billboard or prompt text, which happens whenever you walk past ANY fruit of
--  that plant, and for every plant the prefetch sweep reaches), we divide it by
--  that fruit's SizeMulti and store the result as the seed's base weight. From
--  then on every other fruit of that seed computes as base x SizeMulti with no
--  proximity needed. One sighting per plant type unlocks the whole type.
-- ============================================================

-- [seedNameLower] = base weight in kg at SizeMulti 1, learned from a real
-- observed (kg, SizeMulti) pair. Persists for the session.
local SEED_BASE_WEIGHT = {}

-- ------------------------------------------------------------
--  GLOBAL DENSITY  (kg per stud³ of template core volume)
--
--  This is what makes a Max appear for EVERY plant on the very first refresh,
--  with no walking and no proximity. It is seeded from the one real sighting we
--  have: Hypno Bloom 51.35kg / SizeMulti 5.7060 -> base 8.999, measured against
--  its template core volume, giving 8.99933 kg/stud³.
--
--      kg  =  DENSITY  x  templateCoreVolume(seed)  x  SizeMulti
--
--  Because DENSITY is ONE game-wide number, baking it in fills in Dragon's
--  Breath, Moon Bloom, Star Fruit, Dragon Fruit and Green Bean immediately
--  instead of waiting to see each of them individually.
--
--  READ THIS BEFORE TRUSTING THE NUMBERS: it is an ESTIMATE. One density
--  assumes every plant has the same kg-per-volume, and that is not exactly
--  true — the earlier Moon Bloom dump (SizeMulti 1.4811 @ 10.81kg -> base 7.30)
--  does not match a 9.0 base, and a spot check put Green Bean and Dragon Fruit
--  noticeably off. Treat estimated figures as "close, not exact"; the panel
--  marks them with a ~ so they can be told apart from measured ones.
--
--  Any REAL kg that gets read always wins: it is stored as that seed's true
--  base (see learnBaseWeight) and preferred over the estimate from then on, so
--  the numbers only get more accurate as you move around.
local WEIGHT_DENSITY = 8.99933

-- ------------------------------------------------------------
--  PER-SEED CALIBRATION  (measured, not guessed)
--
--  One global density is NOT enough — that is why only Hypno Bloom was right.
--  A screenshot comparing the real in-game Max against this panel's estimate,
--  for the SAME fruits (counts matched exactly: DB x68, MB x67, HB x19,
--  SF x2, DF x15, GB x1), gave a direct error measurement per seed:
--
--     seed            real Max    my estimate    real/estimate
--     Dragon's Breath   96.04        90.91          1.0564
--     Moon Bloom        76.07        58.35          1.3037
--     Hypno Bloom      104.97       104.98          1.0000  (already measured)
--     Star Fruit        58.47        44.85          1.3037
--     Dragon Fruit      21.16        18.84          1.1231
--     Green Bean         6.58         4.99          1.3186
--
--  The ratio is what matters, and SizeMulti CANCELS OUT of it:
--      real / estimate = trueBase / (DENSITY x volume)
--  So one ratio per seed corrects EVERY fruit of that seed, at any size. These
--  six now reproduce the real numbers exactly rather than approximately.
--
--  HONEST LIMITS: these six are fitted to real observations, so they are right.
--  A seed NOT in this table still uses the raw density estimate and can be off
--  by the same 5-30% seen above — those are the ones still printed with a
--  leading ~. Any real kg that gets read still wins over both.
local SEED_KG_CALIBRATION = {
    ["dragon's breath"] = 1.0564,
    ["dragons breath"]  = 1.0564,   -- apostrophe-less spelling
    ["moon bloom"]      = 1.3037,
    ["hypno bloom"]     = 1.0000,
    ["star fruit"]      = 1.3037,
    ["dragon fruit"]    = 1.1231,
    ["green bean"]      = 1.3186,
}

-- NOTE: a `densityLearned` flag used to live here and re-calibrated the GLOBAL
-- density from the first real sighting. It has been REMOVED because it was
-- actively harmful: re-deriving one game-wide density from, say, a Green Bean
-- reading (ratio 1.32) shifted every other plant's estimate by that same 32%,
-- making the rest WORSE with each new sighting. The per-seed table above fixes
-- each seed independently, which is what the measurements show is needed.

-- [seedNameLower] = core-part volume in stud³ from the plant TEMPLATE, cached.
local TEMPLATE_VOLUME = {}

-- Reads the volume of a seed's fruit core part out of
-- ReplicatedStorage.Assets.Plants.<SeedName>. This is a TEMPLATE lookup, so it
-- works for plants that are nowhere near you and for plants you do not even
-- own yet — that is exactly why it can fill the panel with no walking.
--
-- Returns nil when the template or a usable part can't be found, in which case
-- the caller shows no Max rather than inventing one.
local function templateVolume(seedName)
    if not seedName then return nil end
    local key = string.lower(seedName)

    local cached = TEMPLATE_VOLUME[key]
    if cached ~= nil then
        -- false is the "looked and found nothing" marker, so we don't re-walk
        if cached == false then return nil end
        return cached
    end

    local vol = nil
    pcall(function()
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        local plants = assets and assets:FindFirstChild("Plants")
        local tmpl   = plants and plants:FindFirstChild(seedName)
        if not tmpl then return end

        -- Prefer the part the crop itself points at, then a fruit-ish name,
        -- then simply the biggest part in the template.
        local coreName = nil
        local okc, cn = pcall(function() return tmpl:GetAttribute("CorePartName") end)
        if okc and type(cn) == "string" and cn ~= "" then coreName = cn end

        local best, bestVol = nil, 0
        for _, d in ipairs(tmpl:GetDescendants()) do
            if d:IsA("BasePart") then
                local s = d.Size
                local v = s.X * s.Y * s.Z
                if coreName and d.Name == coreName then
                    best, bestVol = d, v
                    break
                end
                local ln = string.lower(d.Name)
                local fruity = string.find(ln, "fruit", 1, true)
                            or string.find(ln, "core", 1, true)
                            or string.find(ln, "berry", 1, true)
                if (fruity and v > 0) or v > bestVol then
                    if fruity or not best then
                        best, bestVol = d, v
                    end
                end
            end
        end
        if best and bestVol > 0 then vol = bestVol end
    end)

    TEMPLATE_VOLUME[key] = vol or false
    return vol
end

-- ------------------------------------------------------------
--  TEMPLATE VOLUME  ->  base weight, with ONE global density.
--
--  Why this is here: the previous version could only learn a base weight for a
--  seed we had personally seen a kg for, and your console proved we never see
--  ANY kg (no billboard text, prompt ObjectText empty, 0 adorned labels). So it
--  learned nothing and every max stayed 0.
--
--  What is actually available with no proximity at all is the plant TEMPLATE in
--  ReplicatedStorage.Assets.Plants.<SeedName>, plus the fruit's CorePartName
--  and SizeMulti from the crop. A fruit's weight scales with how big that core
--  part is, so:
--
--      kg  =  DENSITY  x  templateCoreVolume  x  SizeMulti
--
--  DENSITY is a single game-wide constant. That means ONE real kg sighting
--  anywhere calibrates EVERY plant type at once, instead of one per type — a
--  Dragon's Breath reading also fills in Moon Bloom, Hypno Bloom and the rest.
--  Until that first sighting we have no honest number, so the panel shows no
--  Max rather than a made-up one.
-- ------------------------------------------------------------
--  THE DENSITY MODEL IS AN ESTIMATE — KNOW ITS ERROR BEFORE TRUSTING IT.
--
--  It is back on purpose: it is the only thing that shows a Max for a plant you
--  have never walked to, which is the whole point. But a spot check against the
--  real garden showed how rough it can be:
--
--      Green Bean    actual 5.99kg   ->  estimate 107.79kg   (18x too high)
--      Dragon Fruit  actual 37.11kg  ->  estimate 111.33kg   (3x too high)
--      Dragon Breath actual 73.58kg  ->  estimate 88.30kg    (fairly close)
--
--  The plants that were spot-on (Moon Bloom, Hypno Bloom, Star Fruit) were
--  exactly the ones whose real kg had been read from the game. So weight is not
--  truly proportional to template volume by one shared constant — each seed has
--  its own kg-per-size relationship that isn't exposed client-side.
--
--  That is why estimated figures are printed with a LEADING ~ in the panel, and
--  why a real reading always replaces the estimate for that seed (and, on the
--  first sighting, re-calibrates the density for everything else). Read a ~
--  number as "right order of magnitude", not as fact.
--  prefetchGarden() below streams the plot in the background so real readings
--  arrive on their own without you walking anywhere.


-- Rounds like WeightFormat.FormatGrams so our number matches the game's text.
local function roundKg(n)
    return math.floor(n * 100 + 0.5) / 100
end

-- Reads the rolled size multiplier off a fruit instance.
local function sizeMultiOf(inst)
    local ok, v = pcall(function() return inst:GetAttribute("SizeMulti") end)
    if ok and type(v) == "number" and v > 0 then return v end
    return nil
end

-- Collects every fruit sub-model that carries a SizeMulti, from an ALREADY
-- COLLECTED list of the crop's Models.
--
-- SPEED: this used to run its own crop:GetDescendants() walk, and it was called
-- TWICE per crop (once to learn the base weight, once to compute the weights) on
-- top of readCropInfo's own walk — three full traversals of every plant. With
-- Remove Plants OFF a plant still has all its geometry, so that was tens of
-- thousands of instances per refresh and is exactly why the panel took so long
-- to appear with Remove Plants off but was instant with it on (stripped plants
-- have almost no descendants left to walk).
local function fruitMultsFrom(crop, models)
    local out = {}
    local m = sizeMultiOf(crop)
    if m then table.insert(out, { inst = crop, mult = m }) end
    for _, d in ipairs(models) do
        local mm = sizeMultiOf(d)
        if mm then table.insert(out, { inst = d, mult = mm }) end
    end
    return out
end

-- Teaches us a seed's base weight from a real observed kg.
-- realKg came from billboard/prompt text; mult is that same fruit's SizeMulti.
local function learnBaseWeight(seedName, realKg, mult)
    if not (seedName and realKg and mult) then return end
    if realKg <= 0 or mult <= 0 then return end
    local key = string.lower(seedName)

    -- Keep the LARGEST observed base for this seed. A crop's maxKg pairs with
    -- that crop's largest SizeMulti, and both grow together, so taking the max
    -- converges on the true base instead of latching onto the first sighting.
    local base = realKg / mult
    if base > (SEED_BASE_WEIGHT[key] or 0) then
        SEED_BASE_WEIGHT[key] = base
        print(string.format("[Arjhay Hub] Learned base weight for %s: %.3f kg "
            .. "(from %.2fkg / SizeMulti %.4f)", seedName, base, realKg, mult))
    end

    -- WEIGHT_DENSITY is deliberately NOT touched here.
    --
    -- An earlier version re-derived the one global density from whatever plant
    -- happened to be sighted first. That made things worse, not better: a Green
    -- Bean reading (ratio 1.32) would rescale Dragon's Breath, Star Fruit and
    -- everything else by that same 32%. Each seed gets its own correction via
    -- SEED_KG_CALIBRATION / SEED_BASE_WEIGHT instead, so learning one plant can
    -- never degrade another.
end

-- Returns (baseKgAtSizeMulti1, isEstimate).
--
-- THIS is what makes a Max show up with no walking. Previously this function
-- returned ONLY the learned value, so a seed we had never stood next to had no
-- base, computedCropKg bailed out, and the panel printed no Max — which is
-- exactly the "only appears when I'm near the plant" behaviour.
--
-- Now there are THREE tiers, best first:
--   1. a base LEARNED from a real observed kg          -> exact,     est=false
--   2. density x template volume x this seed's MEASURED calibration
--                                                      -> accurate,  est=false
--   3. density x template volume, uncalibrated          -> rough,     est=true
--
-- Tier 2 is what makes the other plants match the game the way Hypno Bloom
-- already did: the calibration ratio was measured against the real in-game Max,
-- so the result reproduces it. It counts as NOT an estimate for display, since
-- it is fitted to a real observation rather than assumed.
--
-- Tiers 2 and 3 are ReplicatedStorage template lookups, so they resolve for
-- every seed instantly, at any distance, for plants never approached.
local function baseWeightFor(seedName)
    if not seedName then return nil, false end

    local key = string.lower(seedName)

    local learned = SEED_BASE_WEIGHT[key]
    if learned then return learned, false end

    local vol = templateVolume(seedName)
    if vol and WEIGHT_DENSITY then
        local raw = WEIGHT_DENSITY * vol
        local cal = SEED_KG_CALIBRATION[key]
        if cal then
            -- measured correction for this specific seed -> trust it
            return raw * cal, false
        end
        return raw, true
    end
    return nil, false
end

-- Computes every fruit weight on a crop as base x SizeMulti.
-- Takes the fruit list the caller already built (see fruitMultsFrom).
-- Returns (maxKg, fruitEntries). Returns 0 until that seed's base weight has
-- been learned, in which case the caller keeps its text-based value.
local function computedCropKg(fruitMults, seedName)
    local base, isEst = baseWeightFor(seedName)
    if not base then return 0, {}, false end

    local maxKg, out = 0, {}
    for _, f in ipairs(fruitMults) do
        local kg = roundKg(base * f.mult)
        if kg > 0 then
            if kg > maxKg then maxKg = kg end
            table.insert(out, { weight = kg })
        end
    end
    return maxKg, out, isEst
end

-- Rarity of a plant name. When nothing resolves we return FALLBACK_RARITY
-- instead of "Unknown", so unresolved plants are folded into an existing
-- rarity group and the panel never renders an "Unknown" header.
local function rarityOf(plantName, model)
    local r = PLANT_RARITY[string.lower(plantName or "")]
    if r then return r end
    if model then
        for _, key in ipairs({ "Rarity", "rarity", "Tier" }) do
            local ok, v = pcall(function() return model:GetAttribute(key) end)
            if ok and type(v) == "string" and v ~= "" then return v end
        end
    end
    return FALLBACK_RARITY
end


-- Mutation words (lowercase) for parsing billboard text like "Frozen Blueberry".
local MUTATION_SET = {}
for _, m in ipairs(MUTATION_LIST) do MUTATION_SET[string.lower(m)] = true end

-- Plant names sorted LONGEST FIRST so "Maple Apple" wins over "Apple".
local PLANT_BY_LENGTH = {}
for _, n in ipairs(PLANT_NAMES) do table.insert(PLANT_BY_LENGTH, n) end
table.sort(PLANT_BY_LENGTH, function(a, b) return #a > #b end)

-- Builds a lookup of billboard LABEL INSTANCES keyed by the instance the
-- billboard is ADORNED to.
--
-- WHY THIS EXISTS (this is the "Total Fruits: x0 / no kg / all Normal" bug):
-- The name+weight billboard above a fruit is NOT necessarily parented inside
-- the crop model. This game creates it in PlayerGui and points `Adornee` at the
-- fruit part, so walking crop:GetDescendants() found ZERO text labels — no kg,
-- no plant name, no variant. That is exactly what the panel showed: 10 plants,
-- 0 fruits, no max kg, and every crop defaulting to "Normal".
-- Indexing by Adornee lets us read those labels wherever they actually live.
--
-- We store the LABEL INSTANCES (not their text) so the caller can de-duplicate.
-- A billboard can be BOTH parented inside the crop AND adorned to a part inside
-- that same crop — reading text twice would double every fruit count.
--
-- FREEZE FIX: PlayerGui holds a billboard for every streamed-in crop, so this
-- walk is thousands of instances. Doing it all inside one frame is what locked
-- the game up for 1-2 seconds the moment "Show Farm Details" was switched on.
-- Yielding every so often spreads the same work over several frames, so the
-- game keeps running smoothly while the index is built.
local function buildAdorneeIndex()
    local index = {}
    local function harvestFrom(root)
        local scanned = 0
        for _, g in ipairs(root:GetDescendants()) do
            scanned = scanned + 1
            if scanned % 1200 == 0 then task.wait() end
            if g:IsA("BillboardGui") and g.Adornee then
                local list = index[g.Adornee]
                if not list then list = {}; index[g.Adornee] = list end
                for _, l in ipairs(g:GetDescendants()) do
                    if (l:IsA("TextLabel") or l:IsA("TextButton"))
                    and l.Text and l.Text ~= "" then
                        table.insert(list, l)
                    end
                end
            end
        end
    end
    pcall(harvestFrom, PlayerGui)
    return index
end

-- Pulls variant / mutations / plant name out of ONE billboard line.
-- The game writes all of it into the same text, e.g. "Frozen Gold Apple 2.16kg".
local function parseLabel(text)
    local lower = string.lower(text)

    local variant = "normal"
    if string.find(lower, "rainbow", 1, true) then
        variant = "rainbow"
    elseif string.find(lower, "gold", 1, true) then
        variant = "gold"
    end

    local muts = {}
    for word in string.gmatch(lower, "%a+") do
        if MUTATION_SET[word] then muts[word] = true end
    end

    local plant = nil
    for _, n in ipairs(PLANT_BY_LENGTH) do
        if string.find(lower, string.lower(n), 1, true) then plant = n break end
    end

    return variant, muts, plant
end

-- Reads the plant NAME + EVERY FRUIT on a crop.
-- Returns (name, fruitList, readyCount, maxKg) where fruitList is an array of
--   { weight = n|nil, variant = "normal", mutations = {set} }
-- with ONE ENTRY PER FRUIT.
--
-- Fruit counting order of preference:
--   1. one entry per "##kg" billboard line  (most accurate: real per-fruit data)
--   2. one entry per Harvest ProximityPrompt (each ripe fruit has exactly one)
--   3. a single entry from the crop's own weight attribute
--
-- maxKg is tracked SEPARATELY from the fruit list on purpose. It is the biggest
-- weight seen ANYWHERE on this crop, from ALL of:
--   * every "##kg" billboard line
--   * a Weight/KG/Mass attribute on any descendant part or sub-model
--   * the crop model's own weight attribute
-- Previously the max only came from fruit entries built out of kg billboard
-- lines, so whenever the crop fell back to counting Harvest prompts (path 2)
-- every weight was nil, maxKg stayed 0, and the plant list printed no kg at all.
local function readCropInfo(crop, adorneeIndex)
    local nameText  = nil
    local fruits    = {}
    local readyN    = 0
    local promptN   = 0
    local texts     = {}
    local seenLabel = {}   -- de-dupe: [labelInstance] = true
    local maxKg     = 0
    -- Sub-models gathered during the ONE walk below, reused by fruitMultsFrom
    -- so the SizeMulti passes don't each re-traverse the whole crop.
    local cropModels = {}



    -- 1) plant name from attributes (the model name is a UUID)
    for _, key in ipairs({ "Plant", "PlantName", "Seed", "SeedName", "Type", "Species" }) do
        local ok, v = pcall(function() return crop:GetAttribute(key) end)
        if ok and type(v) == "string" and v ~= "" and PLANT_SET[string.lower(v)] then
            nameText = v
            break
        end
    end

    -- 2) ONE walk of the crop: gather label text (in-hierarchy AND adorned),
    --    StringValue names, and count harvest prompts.
    --
    -- addLabel() is the ONLY way text enters `texts`, and it remembers which
    -- label instances it already read. That is what stops a billboard that is
    -- both parented inside the crop AND adorned to one of its parts from being
    -- counted as two fruits.
    local function addLabel(labelInst)
        if not labelInst or seenLabel[labelInst] then return end
        seenLabel[labelInst] = true
        local t = labelInst.Text
        if t and t ~= "" then
            table.insert(texts, t)
            -- Track the biggest weight from EVERY kg line we see, even lines
            -- that never become fruit entries. This is the "highest KG" the
            -- plant list shows.
            local w = tonumber(t:match("([%d%.]+)%s*[kK][gG]") or "")
            if w and w > maxKg then maxKg = w end
        end
    end


    local function addAdorned(inst)
        local list = adorneeIndex and adorneeIndex[inst]
        if list then
            for _, l in ipairs(list) do addLabel(l) end
        end
    end
    addAdorned(crop)

    -- Fruit entries built from WEIGHT ATTRIBUTES / VALUE OBJECTS on the crop's
    -- own descendants.
    --
    -- THIS IS THE FIX FOR "max kg only shows after I walk to the plant".
    -- The "##kg" text lives in a BillboardGui, and this game only creates/fills
    -- that billboard while the fruit is close enough to be rendered — so from
    -- across the farm every crop reported no kg at all. The weight ATTRIBUTE
    -- (Weight / KG / Mass) lives on the fruit instance itself and replicates
    -- with it, so reading it here gives the kg without going to the plant.
    local attrFruits = {}

    for _, d in ipairs(crop:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            addLabel(d)
        elseif d:IsA("ProximityPrompt") then
            if isHarvestPrompt(d) then
                promptN = promptN + 1
                if d.Enabled then readyN = readyN + 1 end
                -- THE PROMPT ITSELF CARRIES THE KG.
                --
                -- This is the source that was being ignored entirely. The
                -- Harvest prompt's ObjectText is the fruit label the game shows
                -- on the prompt, e.g. "Dragon's Breath 68.24kg", and unlike the
                -- floating BillboardGui the prompt is part of the crop model —
                -- it replicates with the crop, so it is readable from anywhere
                -- on the plot. Reading it here is what makes the max appear for
                -- plants you have never walked up to.
                for _, s in ipairs({ d.ObjectText, d.ActionText }) do
                    if type(s) == "string" and s ~= "" then
                        local w = tonumber(s:match("([%d%.]+)%s*[kK][gG]") or "")
                        if w and w > maxKg then maxKg = w end
                    end
                end
            end
        elseif d:IsA("StringValue") then
            if not nameText and type(d.Value) == "string"
            and PLANT_SET[string.lower(d.Value)] then
                nameText = d.Value
            end
        elseif d:IsA("NumberValue") or d:IsA("IntValue") then
            -- a Weight / KG value object sitting next to the fruit
            local vn = string.lower(d.Name)
            if vn == "weight" or vn == "kg" or vn == "mass" then
                local w = tonumber(d.Value)
                if w and w > 0 then
                    if w > maxKg then maxKg = w end
                    table.insert(attrFruits, { weight = w })
                end
            end
        elseif d:IsA("Model") or d:IsA("BasePart") then
            if d:IsA("Model") then
                cropModels[#cropModels + 1] = d
            end
            -- weight straight off the fruit instance (no billboard needed),
            -- read with a SINGLE GetAttributes call — see readAttrBundle
            local w, variant, muts = readAttrBundle(d)
            if w then
                if w > maxKg then maxKg = w end
                table.insert(attrFruits, {
                    weight    = w,
                    variant   = variant,
                    mutations = muts,
                })
            end
        end
        addAdorned(d)
        step()
    end

    -- the crop model's own weight attribute counts too. Read through
    -- readAttrBundle as well, since getFruitWeight only checks the exact names
    -- Weight/KG/Mass and this game also uses spellings like FruitWeight.
    local ownW = getFruitWeight(crop)
    if ownW and ownW > maxKg then maxKg = ownW end

    local bundleW = readAttrBundle(crop)
    if bundleW and bundleW > maxKg then maxKg = bundleW end


    -- 3) every "##kg" line is its own fruit, and carries its own
    --    variant / mutations / plant name
    for _, t in ipairs(texts) do
        local variant, muts, plant = parseLabel(t)
        if plant and not nameText then nameText = plant end

        local w = t:match("([%d%.]+)%s*[kK][gG]")
        if w then
            table.insert(fruits, {
                weight    = tonumber(w),
                variant   = variant,
                mutations = muts,
            })
        end
    end

    -- 3a) LEARN this seed's base weight whenever we can see a real kg.
    --
    -- maxKg here came from text we could actually read (billboard or the
    -- Harvest prompt), which only happens near the plant. Pairing it with that
    -- fruit's SizeMulti gives the per-seed constant, and from then on every
    -- other plant of this type computes its kg with no proximity at all. That
    -- is what makes the max fill in across the whole farm from one sighting.
    local fruitMults = fruitMultsFrom(crop, cropModels)

    if maxKg > 0 and nameText then
        local biggest = 0
        for _, f in ipairs(fruitMults) do
            if f.mult > biggest then biggest = f.mult end
        end
        if biggest > 0 then
            learnBaseWeight(nameText, maxKg, biggest)
        end
    end

    -- 3b) COMPUTED weights: base weight x SizeMulti.
    --
    -- This is the source that works from ANYWHERE on the plot (and with Remove
    -- Plants on), because SizeMulti replicates with the crop while the "##kg"
    -- billboard only exists while the fruit is rendered nearby. It runs for
    -- every crop, not just as a fallback, so the max is correct even when a
    -- billboard happens to be loaded but shows fewer fruits than the plant has.
    -- isEst tracks whether the number we END UP showing came from the density
    -- estimate or from a real reading, so the panel can mark it with a ~.
    local isEst = false
    local compMax, compFruits, compWasEst = computedCropKg(fruitMults, nameText)
    if compMax > maxKg then
        maxKg = compMax
        isEst = compWasEst
    end
    for _, f in ipairs(compFruits) do
        table.insert(attrFruits, f)
    end

    -- 4a) no kg TEXT found, but we did read weights off the fruit instances
    --     themselves -> use those. This is what keeps the max kg showing for
    --     plants you are nowhere near.
    if #fruits == 0 and #attrFruits > 0 then
        for _, f in ipairs(attrFruits) do
            table.insert(fruits, {
                weight    = f.weight,
                variant   = f.variant or getFruitVariant(crop),
                mutations = f.mutations or getFruitMutations(crop),
            })
        end
    end

    -- 4b) nothing at all -> fall back to one entry per harvest prompt, using
    --     the crop's own attributes for variant/mutations/weight.
    if #fruits == 0 then
        local cropVariant = getFruitVariant(crop)
        local cropMuts    = getFruitMutations(crop)
        local cropWeight  = getFruitWeight(crop)
        local n = (promptN > 0) and promptN or (cropWeight and 1 or 0)
        for _ = 1, n do
            table.insert(fruits, {
                weight    = cropWeight,
                variant   = cropVariant,
                mutations = cropMuts,
            })
        end
    end

    return nameText or crop.Name, fruits, readyN, maxKg, isEst
end


-- Short-lived cache for the billboard index, so a manual Refresh right after an
-- auto refresh reuses the work instead of walking PlayerGui again.
--
-- Deliberately time-based rather than "rebuild when PlayerGui changes": crops
-- stream in and out constantly and their billboards are nested deep, so any
-- cheap change-detection goes stale and the panel would silently stop picking
-- up new fruit and new kg values.
local ADORNEE_TTL = 2.5
local cachedAdorneeIndex, cachedAdorneeAt = nil, 0

local function getAdorneeIndex()
    if cachedAdorneeIndex and (os.clock() - cachedAdorneeAt) < ADORNEE_TTL then
        return cachedAdorneeIndex
    end
    cachedAdorneeIndex = buildAdorneeIndex()
    cachedAdorneeAt    = os.clock()
    return cachedAdorneeIndex
end

-- Walks MY plot and builds the whole summary table.
local function scanFarm()
    local data = {
        totalPlants = 0,
        totalFruits = 0,
        ready       = 0,
        variants    = {},   -- [variant] = count
        mutations   = {},   -- [mutation] = count
        byRarity    = {},   -- [rarity] = { [name] = { count = n, maxKg = n } }
    }

    local plot = getMyPlot()
    if not plot then return data, false end
    local plantsFolder = plot:FindFirstChild("Plants")
    if not plantsFolder then return data, false end

    -- NOTE: streaming the plot in used to happen HERE, and that was a mistake —
    -- RequestStreamAroundAsync yields, so calling it on the render path stalled
    -- the redraw. It now lives in prefetchGarden() below, which runs on its own
    -- task and can yield freely.


    -- Use the CACHED adornee index (no longer rebuilt every 3 seconds)
    local adorneeIndex = getAdorneeIndex()

    for _, crop in ipairs(plantsFolder:GetChildren()) do
        step()
        if crop:IsA("Model") then
            data.totalPlants = data.totalPlants + 1

            local name, fruits, readyN, cropMaxKg, cropIsEst =
                readCropInfo(crop, adorneeIndex)
            data.ready = data.ready + readyN


            -- every fruit counts individually now (this is what fixes
            -- "Total Fruits: x0" and the flat "Normal x10")
            data.totalFruits = data.totalFruits + #fruits

            -- rarity bucket for this plant type
            local rar = rarityOf(name, crop)
            data.byRarity[rar] = data.byRarity[rar] or {}
            local bucket = data.byRarity[rar]
            bucket[name] = bucket[name] or { count = 0, maxKg = 0, est = false }
            bucket[name].count = bucket[name].count + 1

            -- HIGHEST KG for this plant type. cropMaxKg is the biggest weight
            -- found anywhere on the crop (billboard lines + attributes), so the
            -- list shows the heaviest fruit the plant has, not just the weight
            -- of whatever happened to be collected.
            if cropMaxKg and cropMaxKg > bucket[name].maxKg then
                bucket[name].maxKg = cropMaxKg
                bucket[name].est   = cropIsEst and true or false
            end


            -- per-fruit variant / mutation / max-kg tallies
            for _, f in ipairs(fruits) do
                local variant = f.variant or "normal"
                variant = variant:sub(1, 1):upper() .. variant:sub(2)
                data.variants[variant] = (data.variants[variant] or 0) + 1

                -- MUTATIONS ONLY. This is the "Mutations: Gold x1" bug: Gold is
                -- a VARIANT, not a mutation, but the game stores it in the same
                -- "Mutation" attribute that readAttrBundle/getFruitMutations
                -- read, and this tally used to accept ANY word it found there.
                -- Checking against MUTATION_SET (the real mutation list) means
                -- only Frozen/Ignited/Aurora/etc. can ever be counted, so a
                -- Gold/Rainbow/Normal variant can never leak in here again.
                for m in pairs(f.mutations or {}) do
                    if MUTATION_SET[m] then
                        local pretty = m:sub(1, 1):upper() .. m:sub(2)
                        data.mutations[pretty] = (data.mutations[pretty] or 0) + 1
                    end
                end

                if f.weight and f.weight > bucket[name].maxKg then
                    bucket[name].maxKg = f.weight
                end
            end

            -- NO persistent max here on purpose. The Max shown is whatever the
            -- crop reports RIGHT NOW (real kg text, or base x SizeMulti once
            -- the seed's base is known), so harvesting a fruit makes the number
            -- drop instead of freezing at the highest value ever seen.

            -- a crop with no fruit yet still has a variant of its own
            if #fruits == 0 then
                local variant = getFruitVariant(crop)
                variant = variant:sub(1, 1):upper() .. variant:sub(2)
                data.variants[variant] = (data.variants[variant] or 0) + 1
            end
        end
    end

    return data, true
end

-- ============================================================
--  GARDEN PREFETCH SWEEP
--
--  "I manually go near it and then the kg shows up in Max" — the weight lives
--  on the fruit instance, and with instance streaming the far end of the plot
--  is not replicated to this client at all until something asks for it. Walking
--  over there is what asked for it.
--
--  This sweeper asks instead. It crawls MY plot a few crops at a time, calling
--  RequestStreamAroundAsync at each crop's own position so the server sends
--  that region down, reads the weights, and records the biggest one per plant
--  type into bestKgSeen. Since bestKgSeen persists, a max keeps showing once it
--  has been read even when that crop later streams back out — so the whole
--  garden fills itself in over the first few sweeps without you moving.
--
--  Runs on its own task with a yield after every crop, so it never costs a
--  frame. RequestStreamAroundAsync yielding is exactly why this cannot live on
--  the render path.
-- ============================================================
local CROPS_PER_STREAM = 4   -- crops handled per stream request (lowered so more stream calls = better coverage)

local function prefetchGarden()
    local plot = getMyPlot()
    if not plot then return end
    local plantsFolder = plot:FindFirstChild("Plants")
    if not plantsFolder then return end

    local adorneeIndex = getAdorneeIndex()
    local sinceStream  = 0

    for _, crop in ipairs(plantsFolder:GetChildren()) do
        if not (farmState.show and guiAlive) then return end
        if crop:IsA("Model") then
            -- Stream in this crop's region so its fruit / prompts / billboards load
            if sinceStream <= 0 then
                local okp, cf = pcall(function() return crop:GetPivot() end)
                if okp and cf then
                    -- Larger radius (8 studs instead of 1) ensures the whole crop + billboard stream in
                    pcall(function()
                        LocalPlayer:RequestStreamAroundAsync(cf.Position, 8)
                    end)
                end
                sinceStream = CROPS_PER_STREAM
            end
            sinceStream = sinceStream - 1

            -- Wait a moment after the stream request so the prompted/billboard data arrives
            task.wait(0.15)

            -- Read the crop. readCropInfo internally calls learnBaseWeight() whenever
            -- it sees a real kg (from billboard text, Harvest prompt ObjectText, or
            -- weight attributes), which teaches the system that seed's base weight.
            -- From then on EVERY other crop of that seed computes its Max as
            -- base x SizeMulti with no proximity needed — exactly like Hypno Bloom
            -- and Moon Bloom, which are accurate because their real kg was read.
            local okRead, name, _, _, cropMaxKg = pcall(readCropInfo, crop, adorneeIndex)
            if okRead and name and cropMaxKg and cropMaxKg > 0 then
                -- Log whether this seed is now MEASURED or still ESTIMATED, so
                -- the console shows real coverage growing. baseWeightFor always
                -- returns something now (the density estimate), so the second
                -- return value is what actually matters here.
                local base, wasEst = baseWeightFor(name)
                if base then
                    print(string.format("[Arjhay Hub] %s: Max %.2fkg (base %.3f, %s)",
                        name, cropMaxKg, base, wasEst and "ESTIMATED" or "measured"))
                end
            end
            task.wait(0.05)
        end
    end
end

-- ---------- Farm Details UI ----------
local fd = makeCollapsible(homePage, "Farm Details", 1, true)

-- The scrolling output area where the summary is drawn
local fdOutput = Instance.new("Frame")
fdOutput.Name                   = "FarmOutput"
fdOutput.Size                   = UDim2.new(1, 0, 0, 0)
fdOutput.AutomaticSize          = Enum.AutomaticSize.Y
fdOutput.LayoutOrder            = 10
fdOutput.BackgroundColor3       = Color3.fromRGB(18, 18, 18)
fdOutput.BorderSizePixel        = 0
fdOutput.Parent                 = fd
corner(fdOutput, 6)
stroke(fdOutput, Theme.Stroke, 1)

local fdLayout = Instance.new("UIListLayout")
fdLayout.Padding   = UDim.new(0, 2)
fdLayout.SortOrder = Enum.SortOrder.LayoutOrder
fdLayout.Parent    = fdOutput

local fdPad = Instance.new("UIPadding")
fdPad.PaddingTop    = UDim.new(0, 8)
fdPad.PaddingBottom = UDim.new(0, 8)
fdPad.PaddingLeft   = UDim.new(0, 10)
fdPad.PaddingRight  = UDim.new(0, 10)
fdPad.Parent        = fdOutput

-- helper: add one colored line of text to the output
local fdLineIndex = 0
local function fdLine(text, color, bold)
    fdLineIndex = fdLineIndex + 1
    local lbl = Instance.new("TextLabel")
    lbl.Name                   = "Line" .. fdLineIndex
    lbl.BackgroundTransparency = 1
    lbl.Size                   = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize          = Enum.AutomaticSize.Y
    lbl.LayoutOrder            = fdLineIndex
    lbl.Font                   = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    lbl.RichText               = true
    lbl.Text                   = text
    lbl.TextColor3             = color or Theme.Text
    lbl.TextSize               = 13
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextWrapped            = true
    lbl.Parent                 = fdOutput
    return lbl
end

local function clearFarmOutput()
    for _, c in ipairs(fdOutput:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    fdLineIndex = 0
end

-- converts a Color3 into a RichText hex color tag
local function hex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end
local function tag(text, c)
    return string.format('<font color="%s">%s</font>', hex(c), text)
end

local CY = Color3.fromRGB(255, 220, 60)    -- yellow (numbers)
local GR = Color3.fromRGB(90, 220, 90)     -- green (headers)
local GD = Color3.fromRGB(255, 200, 60)    -- gold
local RB = Color3.fromRGB(255, 120, 200)   -- rainbow-ish

-- Renders the scanned data into the output area.
-- Scans FIRST, then clears and redraws: scanFarm() yields now, and clearing up
-- front left the panel blank for a few frames on every refresh.
local function renderFarmDetails()
    local data, ok = scanFarm()
    clearFarmOutput()
    if not ok then
        fdLine("⚠  Couldn't find your garden plot. Stand on your plot and press Refresh.",
            Theme.SubText)
        return
    end

    -- ---- SUMMARY ----
    fdLine(tag("Farm Summary", GR) .. " " .. tag("(Data)", Color3.fromRGB(90, 160, 255)), nil, true)
    fdLine("Total Plants: " .. tag("x" .. data.totalPlants, CY))
    fdLine("Total Fruits: " .. tag("x" .. data.totalFruits, CY))
    -- ready is a FRUIT count now (one enabled Harvest prompt = one ripe fruit),
    -- so it is compared against the fruit total, not the plant total.
    fdLine("Ready: " .. tag("x" .. data.ready, CY)
        .. " / " .. tag("x" .. math.max(data.totalFruits, data.ready), CY))

    -- variants on one line, like "Normal x32  ☀ Gold x1"
    local vParts = {}
    for _, v in ipairs({ "Normal", "Gold", "Rainbow" }) do
        local n = data.variants[v]
        if n and n > 0 then
            local c = (v == "Gold" and GD) or (v == "Rainbow" and RB) or Theme.Text
            local icon = (v == "Gold" and "☀ ") or (v == "Rainbow" and "🌈 ") or ""
            table.insert(vParts, icon .. tag(v, c) .. " " .. tag("x" .. n, CY))
        end
    end
    if #vParts > 0 then
        fdLine("Variants: " .. table.concat(vParts, "  "))
    end

    -- mutations summary (only if any exist)
    local mParts = {}
    for m, n in pairs(data.mutations) do
        table.insert(mParts, tag(m, Color3.fromRGB(120, 220, 255)) .. " " .. tag("x" .. n, CY))
    end
    if #mParts > 0 then
        table.sort(mParts)
        fdLine("Mutations: " .. table.concat(mParts, "  "))
    end

    -- ---- PLANTS GROUPED BY RARITY ----
    for _, rar in ipairs(RARITY_ORDER) do
        local bucket = data.byRarity[rar]
        if bucket then
            -- sort names inside the group by count (most first)
            local names = {}
            for nm in pairs(bucket) do table.insert(names, nm) end
            table.sort(names, function(a, b)
                if bucket[a].count ~= bucket[b].count then
                    return bucket[a].count > bucket[b].count
                end
                return a < b
            end)

            if #names > 0 then
                fdLine("")   -- spacer
                fdLine(tag(rar, RARITY_COLORS[rar] or Theme.Text), nil, true)
                for _, nm in ipairs(names) do
                    local e = bucket[nm]
                    -- a leading ~ means the figure came from the global density
                    -- ESTIMATE rather than a kg actually read off the game, so
                    -- estimated and measured numbers can be told apart at a
                    -- glance. Estimates can be off (see WEIGHT_DENSITY notes).
                    local kg = (e.maxKg > 0)
                        and string.format(e.est and " (~%.2fkg Max)"
                                               or  " (%.2fkg Max)", e.maxKg)
                        or ""
                    fdLine(tag(nm, RARITY_COLORS[rar] or Theme.Text)
                        .. " " .. tag("x" .. e.count, CY)
                        .. tag(kg, Color3.fromRGB(160, 160, 160)))
                end
            end
        end
    end
end

-- "Show Farm Details" toggle: when ON, auto-refreshes on a loop.
-- Runs the scan + redraw on its own task, so flipping the toggle or hitting
-- Refresh never blocks a frame. Overlapping calls are dropped.
local function refreshFarmAsync()
    if farmState.scanning then return end
    farmState.scanning = true
    task.spawn(function()
        pcall(renderFarmDetails)
        farmState.scanning = false
    end)
end

makeIconToggle(fd, "🍀", "Show Farm Details", 1, function(on)
    farmState.show = on
    fdOutput.Visible = on
    print("[Arjhay Hub] Show Farm Details:", on)
    if not on then return end

    refreshFarmAsync()

    -- auto refresh loop while the toggle is on
    task.spawn(function()
        while farmState.show and guiAlive do
            task.wait(farmState.refresh)
            if farmState.show and guiAlive then
                refreshFarmAsync()
            end
        end
    end)

    -- prefetch loop: keeps crawling the plot so every crop's kg gets read
    -- without you walking to it (see prefetchGarden above)
    task.spawn(function()
        while farmState.show and guiAlive do
            pcall(prefetchGarden)
            task.wait(2)
        end
    end)
end)

-- Manual refresh button
do
    local btn = Instance.new("TextButton")
    btn.Name             = "RefreshFarmDetails"
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.LayoutOrder      = 2
    btn.BackgroundColor3 = Theme.Button
    btn.Text             = "Refresh Farm Details"
    btn.Font             = Enum.Font.GothamMedium
    btn.TextColor3       = Theme.Text
    btn.TextSize         = 13
    btn.AutoButtonColor  = true
    btn.Parent           = fd
    corner(btn, 6)
    stroke(btn, Theme.Stroke, 1)
    btn.MouseButton1Click:Connect(function()
        fdOutput.Visible = true
        refreshFarmAsync()
    end)
end


-- NOTE: the "Auto Refresh (seconds)" input used to sit here. It was removed —
-- the panel now always auto-refreshes on the fixed 2 second interval set in
-- farmState.refresh above.

-- start hidden until the toggle is switched on
fdOutput.Visible = false
end   -- end of buildFarmDetails()

buildFarmDetails()

--============================================================
--  SHOP TAB  →  SEED SHOP
--
--  Buy packet (captured from the game, little-endian):
--      u8 = 133  |  u8 = 0  |  u8 nameLen  |  name
--  Strawberry -> "\133\000\nStrawberry"   (\n  = 10 = #"Strawberry")
--  Blueberry  -> "\133\000\tBlueberry"    (\t  =  9 = #"Blueberry")
--  Same length-prefixed shape as the sprinkler/watering packets, minus the
--  position floats — the server only needs to know WHICH seed.
--
--  Behaviour asked for:
--    * multi-select seeds, Select All / Clear
--    * NOTHING selected  ->  buy EVERY seed (opposite of the reference hub)
--    * only ever buys a seed that is actually IN STOCK
--
--  Own function (not a `do` block) for the same reason as buildFarmDetails:
--  the main chunk is near Luau's hard limit of 200 locals.
--============================================================
local function buildSeedShop()
local shopPage = pages["Shop"]

local seedShopState = {
    selection = {},    -- [seedNameLower] = true   (empty = buy all)
    enabled   = false,
    delay     = 0.3,   -- seconds between each buy packet
}

-- ---------- seed list ----------
-- Prefer the game's own SeedData so the names match the packet exactly (a
-- wrong name means the server just ignores the buy). Seeds that appear in the
-- Seed Shop are the ones carrying shop fields (SeedShopDisplayOrder /
-- RestockShop / RestockChance); everything else is a non-purchasable plant.
local SEED_NAMES  = {}
local SEED_LOOKUP = {}   -- [lowercase] = exact name for the packet

do
    local ok = pcall(function()
        local sm = ReplicatedStorage:FindFirstChild("SharedModules")
        local m  = sm and sm:FindFirstChild("SeedData")
        if not (m and m:IsA("ModuleScript")) then return end
        local data = require(m)
        local list = (type(data) == "table" and (data.Data or data)) or nil
        if type(list) ~= "table" then return end
        for key, entry in pairs(list) do
            if type(entry) == "table" then
                local nm = entry.SeedName or entry.Name
                          or (type(key) == "string" and key)
                local inShop = entry.SeedShopDisplayOrder ~= nil
                            or entry.RestockShop ~= nil
                            or entry.RestockChance ~= nil
                if type(nm) == "string" and nm ~= "" and inShop then
                    if not SEED_LOOKUP[string.lower(nm)] then
                        SEED_LOOKUP[string.lower(nm)] = nm
                        table.insert(SEED_NAMES, nm)
                    end
                end
            end
        end
    end)
    if not ok then SEED_NAMES = {} end
end

-- Fallback: the plant list (already loaded from Assets.Plants). Less precise
-- than SeedData — it includes plants that aren't sold — but the stock check
-- below means an unsellable name simply never matches a shop row.
if #SEED_NAMES == 0 then
    for _, n in ipairs(PLANT_NAMES) do
        if not SEED_LOOKUP[string.lower(n)] then
            SEED_LOOKUP[string.lower(n)] = n
            table.insert(SEED_NAMES, n)
        end
    end
    warn("[Arjhay Hub] Seed Shop: SeedData not readable — using the plant list")
else
    print("[Arjhay Hub] Seed Shop: loaded " .. #SEED_NAMES .. " purchasable seeds")
end
table.sort(SEED_NAMES)

-- ---------- buy packet ----------
local function buildBuyBuffer(seedName)
    local n = #seedName
    local buf = buffer.create(3 + n)
    buffer.writeu8(buf, 0, 133)
    buffer.writeu8(buf, 1, 0)
    buffer.writeu8(buf, 2, n)
    buffer.writestring(buf, 3, seedName)
    return buf
end

local function buySeed(seedName)
    local ok, err = pcall(function()
        PlaceRemote:FireServer(buildBuyBuffer(seedName))
    end)
    if not ok then
        warn("[Arjhay Hub] Buy '" .. seedName .. "' failed:", err)
        return false
    end
    return true
end

-- ---------- live stock ----------
-- Reads "x4 in Stock" / "NO STOCK" straight off the Seed Shop UI, which is the
-- only place the client is told the real count. Returns [seedLower] = number.
--
-- CONSEQUENCE WORTH KNOWING: the shop UI has to exist for this to see anything,
-- so buying only works while the Seed Shop is open. Nothing is fired blind —
-- a seed with no readable stock row is skipped rather than guessed at.
local function readSeedStock()
    local stock = {}
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local t = gui.Text
            if t and t ~= "" then
                local num  = t:match("[xX](%d+)%s*[iI][nN]%s*[sS][tT][oO][cC][kK]")
                local none = string.find(string.lower(t), "no stock", 1, true)
                if num or none then
                    -- walk up a few levels looking for this row's name label
                    local node, depth, found = gui.Parent, 0, nil
                    while node and depth < 4 and not found do
                        for _, d in ipairs(node:GetDescendants()) do
                            if (d:IsA("TextLabel") or d:IsA("TextButton")) and d ~= gui then
                                local txt = d.Text
                                if txt and txt ~= "" then
                                    local clean = txt:gsub("^%s+", ""):gsub("%s+$", "")
                                    local hit = SEED_LOOKUP[string.lower(clean)]
                                    if hit then found = hit break end
                                end
                            end
                        end
                        node  = node.Parent
                        depth = depth + 1
                    end
                    if found then
                        local n = num and tonumber(num) or 0
                        local key = string.lower(found)
                        -- keep the LARGEST reading: a row can hold both an
                        -- "x0 in Stock" line and a "NO STOCK" button
                        if n > (stock[key] or -1) then stock[key] = n end
                    end
                end
            end
        end
    end
    return stock
end

-- Which seeds should we try to buy this pass?
-- Empty selection = ALL seeds (as asked), otherwise just the ticked ones.
local function wantedSeeds()
    local out = {}
    if setCount(seedShopState.selection) == 0 then
        for _, n in ipairs(SEED_NAMES) do table.insert(out, n) end
    else
        for key in pairs(seedShopState.selection) do
            local exact = SEED_LOOKUP[key]
            if exact then table.insert(out, exact) end
        end
    end
    return out
end

-- One pass: buy every wanted seed that has stock, up to its stock count.
local function buyPass()
    local stock = readSeedStock()
    if next(stock) == nil then
        warn("[Arjhay Hub] Seed Shop: no stock info found — open the Seed Shop UI "
          .. "so the stock counts can be read.")
        return 0
    end

    local bought = 0
    for _, name in ipairs(wantedSeeds()) do
        if not (seedShopState.enabled and guiAlive) then return bought end
        local have = stock[string.lower(name)]
        if have and have > 0 then
            for _ = 1, have do
                if not (seedShopState.enabled and guiAlive) then return bought end
                if buySeed(name) then
                    bought = bought + 1
                    print(string.format("[Arjhay Hub] Bought %s (%d in stock)", name, have))
                end
                task.wait(seedShopState.delay > 0 and seedShopState.delay or 0.1)
            end
        end
    end
    return bought
end

-- ---------- UI ----------
local ss = makeCollapsible(shopPage, "Seed Shop", 1, true)

do
    local info = Instance.new("TextLabel")
    info.Name                   = "SeedShopInfo"
    info.BackgroundTransparency = 1
    info.Size                   = UDim2.new(1, 0, 0, 32)
    info.LayoutOrder            = 1
    info.Font                   = Enum.Font.Gotham
    info.Text                   = "ℹ  Leave the list empty to buy EVERY seed. Only seeds "
                               .. "in stock are bought. Keep the Seed Shop open."
    info.TextColor3             = Theme.SubText
    info.TextSize               = 12
    info.TextXAlignment         = Enum.TextXAlignment.Left
    info.TextWrapped            = true
    info.Parent                 = ss
end

makeSectionLabel(ss, "🌱", "Seeds To Buy", 2)
makeFilterBox(ss, "🌱", "Seeds To Buy", SEED_NAMES, 3, seedShopState.selection)

makeButtonPair(ss, 4, function()
    for _, n in ipairs(SEED_NAMES) do
        seedShopState.selection[string.lower(n)] = true
    end
    print("[Arjhay Hub] Seed Shop: selected all " .. #SEED_NAMES .. " seeds")
end, function()
    for k in pairs(seedShopState.selection) do
        seedShopState.selection[k] = nil
    end
    print("[Arjhay Hub] Seed Shop: cleared selection (will buy ALL seeds)")
end)

makeSectionLabel(ss, "⏱", "Delay Buy (seconds)", 5)
makeNumberInput(ss, 0.3, 6, function(n)
    seedShopState.delay = math.max(n, 0)
    print("[Arjhay Hub] Seed Shop delay:", seedShopState.delay)
end)

makeIconToggle(ss, "🛒", "Enable Seed Shop", 7, function(on)
    seedShopState.enabled = on
    print("[Arjhay Hub] Seed Shop:", on and "ON" or "OFF")
    if not on then return end

    task.spawn(function()
        while seedShopState.enabled and guiAlive do
            local okPass, n = pcall(buyPass)
            if not okPass then
                warn("[Arjhay Hub] Seed Shop pass errored:", n)
            end
            -- nothing bought (no stock / shop closed) -> back off a little
            task.wait((okPass and type(n) == "number" and n > 0) and 1 or 3)
        end
    end)
end)
end   -- end of buildSeedShop()

buildSeedShop()

--============================================================
--  TAB SWITCHING
--============================================================
local function selectTab(name)

    selectedTab = name
    for tabName, btn in pairs(tabButtons) do
        local active = (tabName == name)
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundTransparency = active and 0 or 1,
            BackgroundColor3       = active and Theme.Selected or Theme.Sidebar,
        }):Play()
    end
    Header.Text = name

    for pageName, page in pairs(pages) do
        page.Visible = (pageName == name)
    end
end

for name, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)
end
selectTab("Main")

--============================================================
--  SEARCH FILTER (filters rows of the current visible page)
--============================================================
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(SearchBox.Text)
    local page = pages[selectedTab]
    if not page then return end
    for _, child in ipairs(page:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            local match = (query == "") or string.find(string.lower(child.Name), query, 1, true)
            child.Visible = match and true or false
        end
    end
end)

--============================================================
--  DRAGGABLE  (works for mouse + touch) -- shared helper
--============================================================
local function makeDraggable(handle, target)
    local dragging  = false
    local dragStart = Vector2.new()
    local startPos  = UDim2.new()

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                      or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(TopBar, Main)

--============================================================
--  FLOATING "A" BADGE  (shown when minimized)
--============================================================
local Badge = Instance.new("TextButton")
Badge.Name             = "Badge"
Badge.AnchorPoint      = Vector2.new(0.5, 0.5)
Badge.Position         = UDim2.new(0.5, 0, 0.5, 0)
Badge.Size             = UDim2.new(0, 56, 0, 56)
Badge.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Badge.Text             = ""
Badge.AutoButtonColor  = false
Badge.Visible          = false
Badge.Parent           = ScreenGui
corner(Badge, 28) -- full circle
stroke(Badge, Theme.Accent, 3)

-- red ring inside
local Ring = Instance.new("Frame")
Ring.AnchorPoint      = Vector2.new(0.5, 0.5)
Ring.Position         = UDim2.new(0.5, 0, 0.5, 0)
Ring.Size             = UDim2.new(0, 44, 0, 44)
Ring.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Ring.BorderSizePixel  = 0
Ring.Parent           = Badge
corner(Ring, 22)
stroke(Ring, Theme.Accent, 2)

-- the "A" letter
local BadgeLabel = Instance.new("TextLabel")
BadgeLabel.BackgroundTransparency = 1
BadgeLabel.Size                   = UDim2.new(1, 0, 1, 0)
BadgeLabel.Font                   = Enum.Font.GothamBold
BadgeLabel.Text                   = "A"
BadgeLabel.TextColor3             = Theme.Text
BadgeLabel.TextSize               = 24
BadgeLabel.Parent                 = Ring

makeDraggable(Badge, Badge)

--============================================================
--  MINIMIZE  /  RESTORE  (collapse into the floating badge)
--============================================================
-- Remembered positions. The window and badge are INDEPENDENT:
--   savedMainPos  = where the window returns to when restored
--   savedBadgePos = where the badge reappears when minimized again
-- (nil badge pos means "first time", so put it where the window was)
local savedMainPos  = Main.Position
local savedBadgePos = nil

MinimizeBtn.MouseButton1Click:Connect(function()
    -- remember where the window was so it comes back to the same spot
    savedMainPos   = Main.Position
    -- badge reappears where it was LAST left (dragged to). First time, it
    -- appears where the window was.
    Badge.Position = savedBadgePos or Main.Position
    Main.Visible   = false
    Badge.Visible  = true

    -- pop-in animation
    Badge.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(Badge, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 56, 0, 56)}):Play()
end)


-- click badge to restore the window
local badgeDownTime = 0
local badgeDownPos  = Vector2.new()
Badge.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        badgeDownTime = tick()
        badgeDownPos  = input.Position
    end
end)
Badge.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        -- treat as a click only if it was quick and didn't move much (not a drag)
        local moved = (input.Position - badgeDownPos).Magnitude
        if (tick() - badgeDownTime) < 0.3 and moved < 6 then
            -- CLICK: restore the window to WHERE IT WAS before minimizing — the
            -- badge can be dragged anywhere without moving the window.
            Main.Position = savedMainPos
            Badge.Visible = false

            Main.Visible  = true
            Main.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 560, 0, 360)}):Play()
        else
            -- DRAG: remember where the badge was left so it stays there next
            -- time it's minimized (doesn't snap back to the window position).
            savedBadgePos = Badge.Position
        end

    end
end)

--============================================================
--  CLOSE
--============================================================
CloseBtn.MouseButton1Click:Connect(function()
    -- STOP everything: kill loops + turn off all auto features
    guiAlive = false
    sprinklerState.systemEnabled = false
    sprinklerState.replaceExpiry = false
    sprinklerState.autoTeleport  = false
    wateringState.systemEnabled  = false
    wateringState.autoTeleport   = false
    setNoclip(false)  -- restore collision so the character isn't left noclipped


    TweenService:Create(Main, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    }):Play()
    task.wait(0.2)
    ScreenGui:Destroy()
    print("[Arjhay Hub] Closed — all auto features stopped.")
end)


--============================================================
--  MOBILE SCALING  (keeps window nice on small screens)
--============================================================
local UIScale = Instance.new("UIScale")
UIScale.Parent = Main

local function updateScale()
    local viewport = workspace.CurrentCamera.ViewportSize
    if viewport.X < 700 then
        UIScale.Scale = math.clamp(viewport.X / 620, 0.6, 1)
    else
        UIScale.Scale = 1
    end
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

print("[Arjhay Hub] Loaded successfully!")
