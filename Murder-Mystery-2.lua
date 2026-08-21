--[[
	Arjhay Hub
	· black / red theme, Gotham font (no monospace)
	· draggable window, minimize + close, floating re-open button
	· mouse + touch (mobile) input, auto-scales to the viewport
	· every connection is tracked and dropped on unload (no leaks)
]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService       = game:GetService("GuiService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local T = {
	Bg        = Color3.fromRGB(10, 10, 12),
	Panel     = Color3.fromRGB(15, 15, 18),
	Card      = Color3.fromRGB(22, 22, 26),
	Hover     = Color3.fromRGB(31, 31, 36),
	Stroke    = Color3.fromRGB(42, 42, 48),
	Accent    = Color3.fromRGB(215, 30, 45),
	AccentDim = Color3.fromRGB(92, 16, 24),
	Text      = Color3.fromRGB(238, 238, 242),
	Sub       = Color3.fromRGB(142, 142, 152),
}

local FONT   = Enum.Font.Gotham
local FONT_M = Enum.Font.GothamMedium
local FONT_B = Enum.Font.GothamBold

local WIN_W, WIN_H = 580, 368
local TOPBAR_H     = 46
local SIDEBAR_W    = 152

--==============================================================
-- cleanup bin: nothing survives an unload
--==============================================================
local Bin = { conns = {}, undo = {} }
function Bin.conn(c) table.insert(Bin.conns, c) return c end
function Bin.onUnload(fn) table.insert(Bin.undo, fn) end
function Bin.flush()
	for _, c in ipairs(Bin.conns) do pcall(function() c:Disconnect() end) end
	table.clear(Bin.conns)
	for _, fn in ipairs(Bin.undo) do pcall(fn) end
	table.clear(Bin.undo)
end

--==============================================================
-- tiny builders
--==============================================================
local function new(class, props, children)
	local inst   = Instance.new(class)
	local parent = nil
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else inst[k] = v end
	end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	inst.Parent = parent
	return inst
end

local function corner(inst, r)
	new("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = inst })
	return inst
end

local function stroke(inst, col, th)
	new("UIStroke", {
		Color = col or T.Stroke, Thickness = th or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inst,
	})
	return inst
end

local function pad(inst, t, b, l, r)
	new("UIPadding", {
		PaddingTop    = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or t or 0),
		PaddingLeft   = UDim.new(0, l or 0), PaddingRight  = UDim.new(0, r or l or 0),
		Parent = inst,
	})
	return inst
end

local function list(inst, gap, dir)
	return new("UIListLayout", {
		Padding       = UDim.new(0, gap or 6),
		FillDirection = dir or Enum.FillDirection.Vertical,
		SortOrder     = Enum.SortOrder.LayoutOrder,
		Parent        = inst,
	})
end

local function tw(o, t, props)
	TweenService:Create(o,
		TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props):Play()
end

--==============================================================
-- click feedback + drawn icons
--==============================================================
-- 0.5s press animation, used by EVERY control. An accent sheet is laid over
-- whatever was clicked and fades out. It copies the host's UICorner so it can
-- never show square corners over a pill, and reads the host's UIPadding so it
-- covers the whole row instead of just the padded interior. It destroys itself,
-- and if the hub is unloaded first the Destroy is simply a no-op — nothing to bin.
local PULSE = 0.5

local function pulse(inst, tint)
	if not inst or not inst.Parent then return end
	local p = inst:FindFirstChildOfClass("UIPadding")
	local pl = p and p.PaddingLeft.Offset   or 0
	local pr = p and p.PaddingRight.Offset  or 0
	local pt = p and p.PaddingTop.Offset    or 0
	local pb = p and p.PaddingBottom.Offset or 0
	local host = inst:FindFirstChildOfClass("UICorner")
	local ov = new("Frame", {
		Parent = inst, BorderSizePixel = 0, ZIndex = 20,
		BackgroundColor3 = tint or T.Accent, BackgroundTransparency = 0.68,
		Position = UDim2.fromOffset(-pl, -pt),
		Size = UDim2.new(1, pl + pr, 1, pt + pb),
	}, {
		new("UICorner", { CornerRadius = host and host.CornerRadius or UDim.new(0, 8) }),
	})
	tw(ov, PULSE, { BackgroundTransparency = 1 })
	task.delay(PULSE + 0.06, function() pcall(function() ov:Destroy() end) end)
end

-- Text glyphs are NOT safe: a font that lacks one draws an empty rectangle (the
-- box in the screenshot), and which glyphs are missing depends on the device. So
-- every icon in this hub is drawn out of Frames instead.
local function iconTint(holder, col)
	for _, c in ipairs(holder:GetChildren()) do
		if c:IsA("Frame") then
			if c.BackgroundTransparency < 1 then
				tw(c, 0.12, { BackgroundColor3 = col })
			end
			local s = c:FindFirstChildOfClass("UIStroke")
			if s then tw(s, 0.12, { Color = col }) end
		end
	end
end

-- A chevron: two bars meeting at the bottom centre. Rotating the HOLDER turns
-- "down" into "right", which makes the open/closed flip a tween instead of a
-- glyph swap.
local function chevron(parent, size, col)
	local holder = new("Frame", {
		Parent = parent, BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, size),
	})
	local len = math.max(4, math.floor(size * 0.62))
	local off = len * 0.354                       -- puts both ends on one point
	for _, rot in ipairs({ 45, -45 }) do
		new("Frame", {
			Parent = holder, BorderSizePixel = 0, BackgroundColor3 = col or T.Sub,
			AnchorPoint = Vector2.new(0.5, 0.5), Rotation = rot,
			Position = UDim2.new(0.5, (rot > 0) and -off or off, 0.5, 0),
			Size = UDim2.fromOffset(len, 2),
		}, { new("UICorner", { CornerRadius = UDim.new(0, 1) }) })
	end
	return holder
end

local function magnifier(parent)
	local holder = new("Frame", {
		Parent = parent, BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
	})
	new("Frame", {                                -- lens
		Parent = holder, BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.fromOffset(10, 10),
	}, {
		new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		new("UIStroke", { Color = T.Sub, Thickness = 1.4 }),
	})
	new("Frame", {                                -- handle
		Parent = holder, BorderSizePixel = 0, BackgroundColor3 = T.Sub, Rotation = 45,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(11, 11),
		Size = UDim2.fromOffset(6, 2),
	}, { new("UICorner", { CornerRadius = UDim.new(0, 1) }) })
	return holder
end

--==============================================================
-- ScreenGui (executor-agnostic parent) + window shell
--==============================================================
local function wipeOld(container)
	if not container then return end
	pcall(function()
		for _, old in ipairs(container:GetChildren()) do
			-- "ArjhayHubESP" too: the ESP draws into a Folder of its own, next to this
			-- ScreenGui rather than inside it, so a run that died without unloading
			-- would otherwise leave highlights and name tags on screen forever.
			if old.Name == "ArjhayHub" or old.Name == "ArjhayHubESP" then
				pcall(function() old:Destroy() end)
			end
		end
	end)
end
wipeOld(gethui and gethui() or nil)
pcall(function() wipeOld(CoreGui) end)
wipeOld(LocalPlayer:FindFirstChild("PlayerGui"))

local screen = new("ScreenGui", {
	Name = "ArjhayHub", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999,
})
do
	local ok = pcall(function()
		if gethui then
			screen.Parent = gethui()
		else
			if syn and syn.protect_gui then syn.protect_gui(screen) end
			screen.Parent = CoreGui
		end
	end)
	if not ok or not screen.Parent then
		screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

local root = new("Frame", {
	Name = "Window", Parent = screen, Active = true, ClipsDescendants = true,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(WIN_W, WIN_H),
	BackgroundColor3 = T.Bg, BorderSizePixel = 0,
})
corner(root, 10)
stroke(root, T.Stroke)

local uiScale = new("UIScale", { Parent = root })

local manualScale = nil

local function fitViewport()
	if manualScale then
		uiScale.Scale = manualScale
		return
	end
	local cam = workspace.CurrentCamera
	local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local s   = math.min(vp.X / (WIN_W + 40), vp.Y / (WIN_H + 60))
	uiScale.Scale = math.clamp(s, 0.5, 1)
end

local camConn
local function hookCamera()
	if camConn then pcall(function() camConn:Disconnect() end) end
	local cam = workspace.CurrentCamera
	if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitViewport) end
	fitViewport()
end

hookCamera()
Bin.conn(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera))
Bin.onUnload(function() if camConn then pcall(function() camConn:Disconnect() end) end end)

--==============================================================
-- top bar: logo · title · search · minimize · close
--==============================================================
local topbar = new("Frame", {
	Name = "TopBar", Parent = root, Active = true,
	Size = UDim2.new(1, 0, 0, TOPBAR_H),
	BackgroundColor3 = T.Panel, BorderSizePixel = 0,
})
corner(topbar, 10)
new("Frame", { -- squares off the bottom corners of the rounded bar
	Parent = topbar, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
	BackgroundColor3 = T.Panel, BorderSizePixel = 0,
})
new("Frame", { -- accent hairline under the bar
	Parent = topbar, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = T.Accent, BackgroundTransparency = 0.45, BorderSizePixel = 0,
})

new("TextLabel", {
	Name = "Title", Parent = topbar, BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0, 240, 1, 0),
	Font = FONT_B, Text = "Arjhay Hub | MM2", TextSize = 17,
	TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
})

local searchBox
do
	local wrap = new("Frame", {
		Parent = topbar, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -84, 0.5, 0), Size = UDim2.fromOffset(212, 28),
		BackgroundColor3 = T.Bg, BorderSizePixel = 0, Active = true,
	})
	corner(wrap, 8)
	stroke(wrap)

	magnifier(wrap)
	searchBox = new("TextBox", {
		Parent = wrap, BackgroundTransparency = 1, ClearTextOnFocus = false,
		Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -36, 1, 0),
		Font = FONT, TextSize = 13, TextColor3 = T.Text,
		PlaceholderText = "Search all settings...", PlaceholderColor3 = T.Sub,
		Text = "", TextXAlignment = Enum.TextXAlignment.Left,
	})
end

-- The bar buttons draw their own glyph out of Frames: "—" and "✕" are exactly the
-- kind of character that turns into an empty box on a device whose font is missing it.
local function barButton(xOffset, kind)
	local b = new("TextButton", {
		Parent = topbar, AnchorPoint = Vector2.new(1, 0.5), AutoButtonColor = false,
		Position = UDim2.new(1, xOffset, 0.5, 0), Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = T.Card, BorderSizePixel = 0, Text = "",
	})
	corner(b, 8)
	stroke(b)

	local marks = {}
	local function bar(rot)
		local f = new("Frame", {
			Parent = b, BorderSizePixel = 0, BackgroundColor3 = T.Sub, Rotation = rot or 0,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(11, 2),
		}, { new("UICorner", { CornerRadius = UDim.new(0, 1) }) })
		table.insert(marks, f)
	end
	if kind == "close" then bar(45); bar(-45) else bar(0) end

	local function tint(col)
		for _, m in ipairs(marks) do tw(m, 0.12, { BackgroundColor3 = col }) end
	end
	Bin.conn(b.MouseEnter:Connect(function()
		tw(b, 0.12, { BackgroundColor3 = T.AccentDim })
		tint(T.Text)
	end))
	Bin.conn(b.MouseLeave:Connect(function()
		tw(b, 0.12, { BackgroundColor3 = T.Card })
		tint(T.Sub)
	end))
	Bin.conn(b.MouseButton1Click:Connect(function() pulse(b) end))
	return b
end

local minBtn   = barButton(-46, "min")
local closeBtn = barButton(-12, "close")

-- Drag handle. Deliberately NOT the whole top bar: InputBegan also fires on a
-- parent frame when a child is touched, so using the bar itself would drag the
-- window while you type in the search box or tap the buttons.
local grabStrip = new("Frame", {
	Name = "Grab", Parent = topbar, Active = true, BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, -300, 1, 0),
})

--==============================================================
-- body: sidebar + page area
--==============================================================
local body = new("Frame", {
	Name = "Body", Parent = root, Active = true, BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, TOPBAR_H), Size = UDim2.new(1, 0, 1, -TOPBAR_H),
})

local sidebar = new("Frame", {
	Name = "Sidebar", Parent = body, Active = true,
	Size = UDim2.new(0, SIDEBAR_W, 1, 0),
	BackgroundColor3 = T.Panel, BorderSizePixel = 0,
})
new("Frame", { -- divider (parented to Body so the sidebar's padding can't shift it)
	Parent = body, Size = UDim2.new(0, 1, 1, 0),
	Position = UDim2.new(0, SIDEBAR_W - 1, 0, 0),
	BackgroundColor3 = T.Stroke, BorderSizePixel = 0,
})
pad(sidebar, 10, 10, 10, 12)
list(sidebar, 6)

local pageArea = new("Frame", {
	Name = "PageArea", Parent = body, Active = true, BackgroundTransparency = 1,
	Position = UDim2.new(0, SIDEBAR_W, 0, 0), Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
})

-- No page header: the "Main" title and its subtitle were deleted by request, so
-- the section list starts at the top of the page area instead of 50px down.
local pageHolder = new("Frame", {
	Name = "Pages", Parent = pageArea, Active = true, BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 8), Size = UDim2.new(1, 0, 1, -8),
})

--==============================================================
-- drag (mouse + touch), shared by the window and the re-open pip
--==============================================================
local function makeDraggable(target, handle, onTap)
	local dragging, from, base, travel = false, nil, nil, 0
	Bin.conn(handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			dragging, from, base, travel = true, i.Position, target.Position, 0
		end
	end))
	Bin.conn(UserInputService.InputChanged:Connect(function(i)
		if not dragging then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement
			or i.UserInputType == Enum.UserInputType.Touch then
			local d = i.Position - from
			travel = math.max(travel, math.abs(d.X) + math.abs(d.Y))
			target.Position = UDim2.new(
				base.X.Scale, base.X.Offset + d.X,
				base.Y.Scale, base.Y.Offset + d.Y)
		end
	end))
	Bin.conn(UserInputService.InputEnded:Connect(function(i)
		if not dragging then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			if onTap and travel < 8 then onTap() end
		end
	end))
end
makeDraggable(root, grabStrip)

--==============================================================
-- 0.5s slide-open, shared by section headers and dropdown menus
--==============================================================
-- Anything that "opens" grows into place over SLIDE seconds instead of popping.
-- Two traps this has to dodge:
--   1. A snapshot height is a bug, not an optimisation. If the frame kept the
--      pixel height it had when it opened, adding a control later (or a longer
--      wrapped label) would clip the last row. So the fixed height is borrowed
--      ONLY for the 0.5s the tween runs, and AutomaticSize.Y is handed back at
--      the end — from then on the frame measures itself again, forever.
--   2. UIListLayout skips invisible children but still spaces a 0-height VISIBLE
--      one, so a collapsed frame must actually end up Visible = false or it
--      leaves its list gap behind.
--   3. ClipsDescendants is what makes the growth read as a reveal, but it is only
--      switched on WHILE the tween runs. Leaving it on would quietly cut anything
--      that legitimately draws outside the frame — the Toggle's expanding ring is
--      6px taller than its row — so it goes back off the moment we are done.
-- The generation counter is what makes double-tapping safe: a stale tween's
-- follow-up work sees my ~= gen and does nothing.
local SLIDE = 0.5

local function makeSlide(frame)
	local gen = 0
	return function(open, instant)
		gen = gen + 1
		local my = gen
		local scale = (uiScale.Scale > 0) and uiScale.Scale or 1
		if instant then
			frame.ClipsDescendants = false
			frame.AutomaticSize = open and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.Visible = open
			return
		end
		if open then
			frame.ClipsDescendants = true
			frame.AutomaticSize = Enum.AutomaticSize.None
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.Visible = true
			task.spawn(function()
				-- one frame so the layout inside has measured itself; reading
				-- AbsoluteContentSize before that returns the stale size
				RunService.Heartbeat:Wait()
				if my ~= gen or not frame.Parent then return end
				local h = 0
				local l = frame:FindFirstChildOfClass("UIListLayout")
				if l then h = l.AbsoluteContentSize.Y / scale end
				local p = frame:FindFirstChildOfClass("UIPadding")
				if p then h = h + p.PaddingTop.Offset + p.PaddingBottom.Offset end
				tw(frame, SLIDE, { Size = UDim2.new(1, 0, 0, h) })
				task.delay(SLIDE + 0.02, function()
					if my ~= gen or not frame.Parent then return end
					frame.AutomaticSize = Enum.AutomaticSize.Y
					frame.ClipsDescendants = false
				end)
			end)
		else
			-- it is open right now, so its own height is the exact start value
			local h = frame.AbsoluteSize.Y / scale
			frame.ClipsDescendants = true
			frame.AutomaticSize = Enum.AutomaticSize.None
			frame.Size = UDim2.new(1, 0, 0, h)
			tw(frame, SLIDE, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(SLIDE + 0.02, function()
				if my ~= gen or not frame.Parent then return end
				frame.Visible = false
				frame.ClipsDescendants = false
			end)
		end
	end
end

--==============================================================
-- tab system
--==============================================================
local tabs, activeTab = {}, nil
local sections, searchRows = {}, {}

local Ctl = {}      -- control constructors, filled in below
Ctl.__index = Ctl

local function selectTab(tab)
	activeTab = tab
	for _, t in ipairs(tabs) do
		local on = (t == tab)
		t.page.Visible = on
		t.bar.Visible  = on
		t.button.BackgroundTransparency = on and 0 or 1
		tw(t.button, 0.12, { BackgroundColor3 = on and T.Card or T.Panel })
		tw(t.label,  0.12, { TextColor3 = on and T.Text or T.Sub })
		iconTint(t.icon, on and T.Accent or T.Sub)
	end
end

local function addTab(name)
	local button = new("TextButton", {
		Parent = sidebar, AutoButtonColor = false, Text = "",
		Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.Panel,
		BackgroundTransparency = 1, BorderSizePixel = 0,
		-- explicit, because the sidebar sorts by LayoutOrder and every button
		-- defaulting to 0 leaves the running order down to child insertion
		LayoutOrder = #tabs,
	})
	corner(button, 8)
	local bar = new("Frame", {
		Parent = button, Visible = false, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(2, 18), BackgroundColor3 = T.Accent,
	})
	corner(bar, 1)
	-- drawn diamond, not a "◆" glyph
	local icon = new("Frame", {
		Parent = button, BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 19, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
	})
	new("Frame", {
		Parent = icon, BorderSizePixel = 0, BackgroundColor3 = T.Sub, Rotation = 45,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
	}, { new("UICorner", { CornerRadius = UDim.new(0, 2) }) })
	local label = new("TextLabel", {
		Parent = button, BackgroundTransparency = 1, Font = FONT_M,
		Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, -40, 1, 0),
		Text = name, TextSize = 13, TextColor3 = T.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local page = new("ScrollingFrame", {
		Parent = pageHolder, Visible = false, Active = true,
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Accent, ScrollBarImageTransparency = 0.3,
		ClipsDescendants = true,
	})
	pad(page, 0, 14, 16, 14)
	list(page, 10)

	local tab = { name = name, button = button, bar = bar,
	              icon = icon, label = label, page = page }
	table.insert(tabs, tab)

	Bin.conn(button.MouseButton1Click:Connect(function()
		pulse(button)
		selectTab(tab)
	end))
	Bin.conn(button.MouseEnter:Connect(function()
		if activeTab ~= tab then
			button.BackgroundTransparency = 0
			tw(button, 0.12, { BackgroundColor3 = T.Card })
		end
	end))
	Bin.conn(button.MouseLeave:Connect(function()
		if activeTab ~= tab then button.BackgroundTransparency = 1 end
	end))

	function tab:Section(title)
		local card = new("Frame", {
			Parent = page, Active = true, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = T.Card,
		})
		corner(card, 10)
		stroke(card)
		local inner = new("Frame", {
			Parent = card, Active = true, BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		})
		pad(inner, 10, 12, 12, 12)
		list(inner, 8)

		local head = new("TextButton", {
			Parent = inner, Text = "", AutoButtonColor = false,
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22),
			LayoutOrder = 0,
		})
		local dot = new("Frame", {
			Parent = head, Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = T.Accent,
		})
		corner(dot, 4)

		new("TextLabel", {
			Parent = head, BackgroundTransparency = 1, Font = FONT_B,
			Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -40, 1, 0),
			Text = title, TextSize = 13, TextColor3 = T.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local chev = chevron(head, 16, T.Sub)
		chev.Position = UDim2.new(1, -8, 0.5, 0)

		local holder = new("Frame", {
			Parent = inner, Active = true, BackgroundTransparency = 1, LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		})
		list(holder, 6)

		local sec = setmetatable({
			card = card, body = holder, key = string.lower(title), open = true,
		}, Ctl)
		table.insert(sections, sec)

		local slideHolder = makeSlide(holder)

		Bin.conn(head.MouseButton1Click:Connect(function()
			pulse(head)
			sec.open = not sec.open
			slideHolder(sec.open)              -- 0.5s grow / shrink, not a pop
			-- rotating the whole chevron turns "v" into ">" — no glyph swap
			tw(chev, 0.2, { Rotation = sec.open and 0 or -90 })
			iconTint(chev, sec.open and T.Sub or T.Accent)
		end))

		return sec
	end

	if not activeTab then selectTab(tab) end
	return tab
end

--==============================================================
-- "coming soon" page
--==============================================================
-- Three of the four tabs have no features yet, and an empty scrolling frame reads
-- as a broken tab rather than as a planned one. This fills the page with a card
-- that says so deliberately. The clock is drawn out of Frames for the usual
-- reason: a glyph the device's font happens to lack renders as an empty box.
local function comingSoon(tab, blurb)
	local card = new("Frame", {
		Parent = tab.page, Active = true, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 240), BackgroundColor3 = T.Card,
	})
	corner(card, 10)
	stroke(card)
	local edge = card:FindFirstChildOfClass("UIStroke")

	-- the dial is an empty Frame wearing a circular UIStroke: a ring, no glyph
	local dial = new("Frame", {
		Parent = card, BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40),
		Size = UDim2.fromOffset(44, 44),
	}, {
		new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		new("UIStroke", { Color = T.Accent, Thickness = 2 }),
	})
	local ring = dial:FindFirstChildOfClass("UIStroke")

	local handA = new("Frame", {                    -- hour hand, straight up
		Parent = dial, BorderSizePixel = 0, BackgroundColor3 = T.Accent,
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(2, 12),
	}, { new("UICorner", { CornerRadius = UDim.new(0, 1) }) })
	local handB = new("Frame", {                    -- minute hand, out to the right
		Parent = dial, BorderSizePixel = 0, BackgroundColor3 = T.Accent,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(11, 2),
	}, { new("UICorner", { CornerRadius = UDim.new(0, 1) }) })

	local title = new("TextLabel", {
		Parent = card, BackgroundTransparency = 1, Font = FONT_B,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 98),
		Size = UDim2.new(1, -40, 0, 20),
		Text = "COMING SOON", TextSize = 15, TextColor3 = T.Text,
	})
	local rule = new("Frame", {
		Parent = card, BorderSizePixel = 0, BackgroundColor3 = T.Accent,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 126),
		Size = UDim2.fromOffset(28, 2),
	})
	corner(rule, 1)
	local sub = new("TextLabel", {
		Parent = card, BackgroundTransparency = 1, Font = FONT,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 140),
		Size = UDim2.new(1, -72, 0, 40),
		Text = blurb, TextSize = 12, TextColor3 = T.Sub, TextWrapped = true,
	})

	local pill = new("Frame", {
		Parent = card, Active = true, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 192),
		Size = UDim2.fromOffset(136, 24), BackgroundColor3 = T.AccentDim,
	})
	corner(pill, 12)
	local pillText = new("TextLabel", {
		Parent = pill, BackgroundTransparency = 1, Font = FONT_M,
		Size = UDim2.fromScale(1, 1), Text = "IN DEVELOPMENT",
		TextSize = 11, TextColor3 = T.Text,
	})

	-- everything else in this hub animates, so the placeholder fades in each time
	-- its tab is opened. It fades rather than slides because the page's
	-- UIListLayout owns the card's Position and would fight a move tween.
	local solids = { handA, handB, rule, pill }
	local texts  = { title, sub, pillText }

	local function fadeIn()
		card.BackgroundTransparency = 1
		if edge then edge.Transparency = 1 end
		if ring then ring.Transparency = 1 end
		for _, f in ipairs(solids) do f.BackgroundTransparency = 1 end
		for _, l in ipairs(texts)  do l.TextTransparency = 1 end

		tw(card, PULSE, { BackgroundTransparency = 0 })
		if edge then tw(edge, PULSE, { Transparency = 0 }) end
		if ring then tw(ring, PULSE, { Transparency = 0 }) end
		for _, f in ipairs(solids) do tw(f, PULSE, { BackgroundTransparency = 0 }) end
		for _, l in ipairs(texts)  do tw(l, PULSE, { TextTransparency = 0 }) end
	end

	Bin.conn(tab.page:GetPropertyChangedSignal("Visible"):Connect(function()
		if tab.page.Visible then fadeIn() end
	end))
	fadeIn()

	return card
end

--==============================================================
-- search filter over every registered control
--==============================================================
local function registerRow(sec, row, text)
	table.insert(searchRows, { sec = sec, row = row, text = string.lower(text) })
end

local function applySearch(query)
	local q = string.lower(query or "")
	local hit = {}
	for _, e in ipairs(searchRows) do
		local ok = (q == "") or (string.find(e.text, q, 1, true) ~= nil)
			or (string.find(e.sec.key, q, 1, true) ~= nil)
		e.row.Visible = ok
		if ok then hit[e.sec] = true end
	end

	for _, s in ipairs(sections) do
		s.card.Visible = (q == "") or (hit[s] == true)
	end
end

Bin.conn(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	applySearch(searchBox.Text)
end))

--==============================================================
-- controls
--==============================================================
local function baseRow(sec, h)
	return new("Frame", {
		Parent = sec.body, Active = true, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, h or 32), BorderSizePixel = 0,
	})
end

local function rowLabel(row, text, width)
	return new("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT,
		Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, width or -60, 0, 18),
		Text = text, TextSize = 13, TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
end

function Ctl:Label(text)
	local lab = new("TextLabel", {
		Parent = self.body, BackgroundTransparency = 1, Font = FONT,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Text = text, TextSize = 12, TextColor3 = T.Sub, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	registerRow(self, lab, text)
	local api = {}
	function api:Set(v) lab.Text = tostring(v) end
	return api
end

function Ctl:Button(text, callback)
	local row = baseRow(self, 34)
	local b = new("TextButton", {
		Parent = row, Size = UDim2.fromScale(1, 1), AutoButtonColor = false,
		BackgroundColor3 = T.Hover, BorderSizePixel = 0,
		Font = FONT_M, Text = text, TextSize = 13, TextColor3 = T.Text,
	})
	corner(b, 8)
	stroke(b)
	Bin.conn(b.MouseEnter:Connect(function() tw(b, 0.12, { BackgroundColor3 = T.AccentDim }) end))
	Bin.conn(b.MouseLeave:Connect(function() tw(b, 0.12, { BackgroundColor3 = T.Hover }) end))

	Bin.conn(b.MouseButton1Click:Connect(function()
		pulse(b)
		tw(b, 0.1, { BackgroundColor3 = T.Accent })
		task.delay(0.14, function()
			if b.Parent then tw(b, PULSE - 0.14, { BackgroundColor3 = T.Hover }) end
		end)
		if callback then task.spawn(callback) end
	end))
	registerRow(self, row, text)
	return b
end

function Ctl:Toggle(text, default, callback)
	local row = baseRow(self, 32)
	rowLabel(row, text, -60).Position = UDim2.new(0, 0, 0.5, -9)

	local pill = new("TextButton", {
		Parent = row, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(42, 22), BackgroundColor3 = T.Bg,
	})
	corner(pill, 11)
	stroke(pill)
	local knob = new("Frame", {
		Parent = pill, BorderSizePixel = 0, BackgroundColor3 = T.Sub,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
	})
	corner(knob, 8)

	local state = default and true or false
	local function render()
		tw(pill, 0.14, { BackgroundColor3 = state and T.Accent or T.Bg })
		tw(knob, 0.14, {
			Position = UDim2.new(0, state and 23 or 3, 0.5, 0),
			BackgroundColor3 = state and Color3.new(1, 1, 1) or T.Sub,
		})
	end
	render()

	local api = {}
	function api:Get() return state end
	function api:Set(v, silent)
		state = v and true or false
		render()
		if callback and not silent then task.spawn(callback, state) end
	end
	Bin.conn(pill.MouseButton1Click:Connect(function()
		-- 0.5s press animation: the row lights up and a ring expands off the pill
		pulse(row)
		local ring = new("Frame", {
			Parent = pill, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(42, 22),
		}, {
			new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			new("UIStroke", { Color = T.Accent, Thickness = 2, Transparency = 0.25 }),
		})
		tw(ring, PULSE, { Size = UDim2.fromOffset(72, 46) })
		local rs = ring:FindFirstChildOfClass("UIStroke")
		if rs then tw(rs, PULSE, { Transparency = 1 }) end
		task.delay(PULSE + 0.06, function() pcall(function() ring:Destroy() end) end)
		api:Set(not state)
	end))
	registerRow(self, row, text)
	return api
end

function Ctl:Slider(text, min, max, default, callback)
	local row = baseRow(self, 48)
	rowLabel(row, text, -60)
	local valLab = new("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_M,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(58, 18), Text = "", TextSize = 12,
		TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track = new("Frame", {
		Parent = row, BackgroundColor3 = T.Bg, BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 0, 6),
	})
	corner(track, 3)
	stroke(track)
	local fill = new("Frame", {
		Parent = track, BackgroundColor3 = T.Accent, BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	})
	corner(fill, 3)
	local knob = new("Frame", {
		Parent = track, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12), ZIndex = 2,
	})
	corner(knob, 6)
	local hit = new("TextButton", {
		Parent = row, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		Position = UDim2.new(0, -6, 0, 22), Size = UDim2.new(1, 12, 0, 24),
	})

	local step  = ((max - min) <= 5) and 0.1 or 1
	local value = math.clamp(default or min, min, max)

	local function render(fire)
		local a = (max > min) and (value - min) / (max - min) or 0
		fill.Size     = UDim2.fromScale(a, 1)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		valLab.Text   = (step < 1) and string.format("%.1f", value) or tostring(math.floor(value + 0.5))
		if fire and callback then task.spawn(callback, value) end
	end

	local function setFromX(px)
		local w = track.AbsoluteSize.X
		if w <= 0 then return end
		local a = math.clamp((px - track.AbsolutePosition.X) / w, 0, 1)
		local raw = min + a * (max - min)
		value = math.clamp(math.floor(raw / step + 0.5) * step, min, max)
		render(true)
	end

	render(false)

	local sliding = false
	Bin.conn(hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			-- pulse the ROW, not the 6px track: a sheet over the track is invisible
			-- against the accent fill that is already there
			pulse(row)
			tw(knob, 0.1, { Size = UDim2.fromOffset(16, 16) })
			setFromX(i.Position.X)
		end
	end))
	Bin.conn(UserInputService.InputChanged:Connect(function(i)
		if not sliding then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement
			or i.UserInputType == Enum.UserInputType.Touch then
			setFromX(i.Position.X)
		end
	end))
	Bin.conn(UserInputService.InputEnded:Connect(function(i)
		if not sliding then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			sliding = false
			tw(knob, 0.1, { Size = UDim2.fromOffset(12, 12) })
		end
	end))

	local api = {}
	function api:Get() return value end
	function api:Set(v, silent)
		value = math.clamp(v, min, max)
		render(not silent)
	end
	registerRow(self, row, text)
	return api
end

-- MULTI-SELECT. `defaults` may be a single string or a list of strings; the
-- callback receives (set, sortedList) on every change, so a caller can just index
-- the set. Rows are checkboxes, not radio buttons: tapping one never clears
-- another, and the menu stays open so you can tick several in one go.
function Ctl:Dropdown(text, options, defaults, callback)
	local wrap = new("Frame", {
		Parent = self.body, Active = true, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	})
	list(wrap, 4)

	local head = new("TextButton", {
		Parent = wrap, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.Bg, LayoutOrder = 0,
	})
	corner(head, 8)
	stroke(head)
	pad(head, 0, 0, 10, 10)

	new("TextLabel", {
		Parent = head, BackgroundTransparency = 1, Font = FONT,
		Size = UDim2.new(0.42, 0, 1, 0), Text = text, TextSize = 13,
		TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
	})
	local valLab = new("TextLabel", {
		Parent = head, BackgroundTransparency = 1, Font = FONT_M,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0),
		Size = UDim2.new(0.58, -14, 1, 0), Text = "", TextSize = 12,
		TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local chev = chevron(head, 14, T.Sub)
	chev.Position = UDim2.new(1, -1, 0.5, 0)
	chev.Rotation = -90            -- the menu starts closed, so start pointing right

	local menu = new("Frame", {
		Parent = wrap, Visible = false, Active = true, LayoutOrder = 1,
		BackgroundColor3 = T.Bg, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	})
	corner(menu, 8)
	stroke(menu)
	pad(menu, 6, 6, 6, 6)
	list(menu, 3)

	local chosen, rows = {}, {}
	local menuOpen  = false
	local slideMenu = makeSlide(menu)
	slideMenu(false, true)         -- normalise the closed state without animating
	do
		local d = defaults
		if type(d) == "string" then d = { d } end
		for _, v in ipairs(d or {}) do chosen[v] = true end
	end

	local function orderedSelection()
		local out = {}
		for _, opt in ipairs(options or {}) do
			if chosen[opt] then table.insert(out, opt) end
		end
		return out
	end

	local api = {}

	local function refresh(silent)
		local sel = orderedSelection()
		if #sel == 0 then
			valLab.Text = "none"
		elseif #sel <= 2 then
			valLab.Text = table.concat(sel, ", ")
		else
			valLab.Text = #sel .. " selected"
		end
		for opt, r in pairs(rows) do
			local on = chosen[opt] == true
			tw(r.btn, 0.1, { BackgroundColor3 = on and T.AccentDim or T.Card })
			r.btn.TextColor3 = on and T.Text or T.Sub
			tw(r.box, 0.12, { BackgroundColor3 = on and T.Accent or T.Bg })
			-- a drawn fill, not a "✓" glyph
			tw(r.tick, 0.12, {
				Size = on and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0),
				BackgroundTransparency = on and 0 or 1,
			})
		end
		if callback and not silent then task.spawn(callback, chosen, sel) end
	end

	function api:Get() return chosen end
	function api:List() return orderedSelection() end
	function api:Has(opt) return chosen[opt] == true end
	function api:Set(v, silent)
		if type(v) == "string" then v = { v } end
		chosen = {}
		for _, opt in ipairs(v or {}) do chosen[opt] = true end
		refresh(silent)
	end

	for i, opt in ipairs(options or {}) do
		local ob = new("TextButton", {
			Parent = menu, AutoButtonColor = false, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.Card, LayoutOrder = i,
			Font = FONT, Text = "      " .. tostring(opt), TextSize = 12,
			TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left,
		})
		corner(ob, 6)
		pad(ob, 0, 0, 8, 8)

		local box = new("Frame", {
			Parent = ob, Active = false, BorderSizePixel = 0, BackgroundColor3 = T.Bg,
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
		})
		corner(box, 4)
		stroke(box)
		local tick = new("Frame", {
			Parent = box, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
		}, { new("UICorner", { CornerRadius = UDim.new(0, 2) }) })

		rows[opt] = { btn = ob, box = box, tick = tick, order = i }

		Bin.conn(ob.MouseEnter:Connect(function()
			if not chosen[opt] then tw(ob, 0.1, { BackgroundColor3 = T.Hover }) end
		end))
		Bin.conn(ob.MouseLeave:Connect(function()
			if not chosen[opt] then tw(ob, 0.1, { BackgroundColor3 = T.Card }) end
		end))
		-- tapping toggles this one row and leaves the menu open. The row does NOT
		-- move under your finger: selected-first re-ordering happens on OPEN only.
		Bin.conn(ob.MouseButton1Click:Connect(function()
			pulse(ob)
			chosen[opt] = (not chosen[opt]) or nil
			refresh(false)
		end))
	end

	Bin.conn(head.MouseButton1Click:Connect(function()
		pulse(head)
		-- track open state ourselves: menu.Visible now lags by the 0.5s collapse,
		-- so reading it back would double-fire a close
		menuOpen = not menuOpen
		local opening = menuOpen
		if opening then
			local sel, n = {}, 0
			for _, opt in ipairs(orderedSelection()) do
				n = n + 1
				sel[opt] = n
			end
			for opt, r in pairs(rows) do
				r.btn.LayoutOrder = sel[opt] or (1000 + r.order)
			end
		end
		slideMenu(opening)             -- 0.5s grow / shrink, not a pop
		-- the chevron is drawn from two Frames, so "open" is a rotation, not a glyph.
		-- Same direction as a section header: down = open, right = closed.
		tw(chev, 0.2, { Rotation = opening and 0 or -90 })
		iconTint(chev, opening and T.Accent or T.Sub)
	end))

	refresh(true)
	registerRow(self, wrap, text .. " " .. table.concat(options or {}, " "))
	return api
end

function Ctl:Input(text, placeholder, callback)
	local row = baseRow(self, 34)
	local box = new("TextBox", {
		Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Bg,
		BorderSizePixel = 0, ClearTextOnFocus = false, Text = "",
		Font = FONT, TextSize = 13, TextColor3 = T.Text,
		PlaceholderText = placeholder or text, PlaceholderColor3 = T.Sub,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	corner(box, 8)
	stroke(box)
	pad(box, 0, 0, 10, 10)
	Bin.conn(box.Focused:Connect(function()
		pulse(box)
		tw(box, 0.1, { BackgroundColor3 = T.Hover })
	end))
	Bin.conn(box.FocusLost:Connect(function(enter)
		tw(box, 0.1, { BackgroundColor3 = T.Bg })
		if enter and callback then task.spawn(callback, box.Text) end
	end))
	registerRow(self, row, text .. " " .. (placeholder or ""))
	local api = {}
	function api:Get() return box.Text end
	function api:Set(v) box.Text = tostring(v) end
	return api
end

--==============================================================
-- minimize (collapses to a round pip) · close · hotkey
--==============================================================
local minimized = false

local pip = new("TextButton", {
	Name = "Pip", Parent = screen, Visible = false, AutoButtonColor = false,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 62, 0.42, 0),
	Size = UDim2.fromOffset(52, 52), BackgroundColor3 = T.Panel, BorderSizePixel = 0,
	Font = FONT_B, Text = "AH", TextSize = 17, TextColor3 = T.Text, ZIndex = 5,
})
corner(pip, 26)                      -- half the size = a true circle
stroke(pip, T.Accent, 2)
new("Frame", {                        -- inner accent ring
	Parent = pip, BackgroundTransparency = 1, BorderSizePixel = 0,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(42, 42),
}, {
	new("UICorner", { CornerRadius = UDim.new(1, 0) }),
	new("UIStroke", { Color = T.AccentDim, Thickness = 1, Transparency = 0.35 }),
})

local function setMinimized(v)
	minimized = v and true or false
	if minimized then
		tw(root, 0.14, { Size = UDim2.fromOffset(WIN_W * 0.9, WIN_H * 0.9) })
		task.delay(0.14, function()
			if not minimized then return end
			root.Visible = false
			root.Size    = UDim2.fromOffset(WIN_W, WIN_H)
			pip.Visible  = true
			pip.Size     = UDim2.fromOffset(30, 30)
			tw(pip, 0.16, { Size = UDim2.fromOffset(52, 52) })
		end)
	else
		pip.Visible  = false
		root.Visible = true
		root.Size    = UDim2.fromOffset(WIN_W * 0.92, WIN_H * 0.92)
		tw(root, 0.16, { Size = UDim2.fromOffset(WIN_W, WIN_H) })
	end
end

Bin.conn(minBtn.MouseButton1Click:Connect(function() setMinimized(true) end))
Bin.conn(pip.MouseEnter:Connect(function() tw(pip, 0.12, { BackgroundColor3 = T.AccentDim }) end))
Bin.conn(pip.MouseLeave:Connect(function() tw(pip, 0.12, { BackgroundColor3 = T.Panel }) end))
makeDraggable(pip, pip, function() setMinimized(false) end)

local function unload()
	Bin.flush()
	pcall(function() screen:Destroy() end)
	if getgenv then getgenv().ArjhayHub = nil end
end

Bin.conn(closeBtn.MouseButton1Click:Connect(function() unload() end))

Bin.conn(UserInputService.InputBegan:Connect(function(i, processed)
	if processed then return end
	if i.KeyCode == Enum.KeyCode.RightShift then setMinimized(not minimized) end
end))

--==============================================================
-- MM2 · shared helpers
--==============================================================
local FTI    = firetouchinterest
local FPP    = fireproximityprompt
local GETCON = getconnections

-- The ReplicatedStorage.Coins folders are CLONE TEMPLATES; the live pickups are
-- copies sitting somewhere in Workspace. So we never hardcode a container: we
-- read the template NAMES out of ReplicatedStorage and hunt those names instead.
local COIN_CATS = {
	{ label = "Coins",       folders = { "CoinObjects" } },
	{ label = "Beach Balls", folders = { "BeachBallObjects" } },
	{ label = "Candy",       folders = { "CandyObjects", "_CandiesObjects" } },
	{ label = "Eggs",        folders = { "EggObjects" } },
	{ label = "Snow Tokens", folders = { "SnowTokenObjects" } },
}
local CAT_LABELS = { "Coins", "Beach Balls", "Candy", "Eggs", "Snow Tokens", "Everything" }

-- children of the template folders that are decoration, not the pickup itself.
-- Also the parts a LIVE coin is welded out of: the recon dump showed the real
-- thing is  CoinContainer.Coin_Server → CoinVisual → MainCoin , and we must
-- target only the top part or we would chase the same coin three times.
local IGNORE_NAMES = {
	SpinningVisual = true, SpinningVisuals = true, Spin = true, Visual = true,
	Effect = true, CoinVisual = true, MainCoin = true, CoinSound = true,
	DecalPart = true, Num_2 = true, ["2Part"] = true,
}

-- CONFIRMED by the recon dump (2026-08-20, map "Factory"):
--   · live coins are Parts named `Coin_Server` inside Workspace.<Map>.CoinContainer
--   · the 20s remote spy logged ZERO FireServer/InvokeServer calls while coins
--     were being picked up, so the server owns the .Touched — there is no collect
--     remote to call. Arriving at the coin + firetouchinterest IS the pickup.
local CONTAINER_NAMES = { CoinContainer = true }

-- a live clone is the template name plus a side suffix (Coin → Coin_Server), so
-- compare on the stripped name. Explicit list, not a pattern: a greedy pattern
-- would also eat legitimate underscores.
local LIVE_SUFFIX = { "_Server", "_Client", "_Visual", "_Model" }

local function baseName(n)
	for _, suf in ipairs(LIVE_SUFFIX) do
		if #n > #suf and string.sub(n, -#suf) == suf then
			return string.sub(n, 1, #n - #suf)
		end
	end
	return n
end

local coinsFolder = ReplicatedStorage:FindFirstChild("Coins")

local function walkTemplates(inst, set)
	for _, child in ipairs(inst:GetChildren()) do
		if child:IsA("Folder") or child:IsA("Configuration") then
			walkTemplates(child, set)                      -- EggObjects → Eggs / RareEggs
		elseif not IGNORE_NAMES[child.Name]
			and (child:IsA("BasePart") or child:IsA("Model")) then
			set[child.Name] = true                         -- template root only
		end
	end
end

local function partOf(inst)
	if inst:IsA("BasePart") then return inst end
	if inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

-- `inst.Parent ~= nil` IS NOT A LIVENESS TEST, and believing it was is the whole
-- of "it still tweens even if there's no coin". MM2 destroys the entire map model
-- between rounds: Destroy() nils the MAP's parent, but every coin inside it keeps
-- its own parent pointer, so a cached CoinContainer and the coins left in it all
-- still answer `.Parent` and still report a Position. The character then chases
-- ghosts at the OLD map's coordinates — and because the next map sits somewhere
-- else in the world, flying at one is also how we earn the server's
-- "Invalid position" kick. Ask the only question that actually matters: is this
-- thing still attached to the world we are standing in?
local function alive(inst)
	return inst ~= nil and inst.Parent ~= nil and inst:IsDescendantOf(workspace)
end

-- A CFrame holding a NaN or an infinite component is an invalid position by
-- definition, and so is anything out past the edge of the world. Both are cheap
-- to refuse, and refusing beats being kicked.
local POS_LIMIT = 20000

local function sanePos(v)
	if typeof(v) ~= "Vector3" then return false end
	-- x ~= x is the NaN test: NaN fails every comparison, including with itself
	if v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z then return false end
	return math.abs(v.X) < POS_LIMIT
		and math.abs(v.Y) < POS_LIMIT
		and math.abs(v.Z) < POS_LIMIT
end

local function myRoot()
	local char = LocalPlayer.Character
	if not char or not char.Parent then return nil, nil end
	return char:FindFirstChild("HumanoidRootPart"), char
end

--==============================================================
-- config engine
--==============================================================
-- Every control already exposes the same two methods, :Get and :Set, so a config
-- is just a map of key -> value. The keys below are written out by hand rather than
-- derived from each control's label: a label is a thing that gets reworded (this
-- hub has already renamed a tab and two rows), and a reworded label must not
-- silently orphan every config the user has saved.
--
-- Everything lives on one table on purpose. This file is close to Luau's ceiling
-- of 200 top-level locals, and past it the error is reported as a nil call on
-- line 1, which is a miserable thing to debug.
local Cfg = {
	rows   = {},                          -- ordered { key, kind, api }
	dir    = "ArjhayHub/MM2/configs",
	flat   = "ArjhayHub_MM2_cfg_",
	useDir = false,
	-- APPLY ORDER, and it matters: a toggle starts a loop that reads the sliders,
	-- so every number and list has to be in place before any switch is thrown.
	rank   = { input = 1, slider = 2, dropdown = 3, toggle = 4 },
}

Cfg.canWrite = (type(writefile) == "function") and (type(readfile) == "function")

do
	if Cfg.canWrite and type(makefolder) == "function" and type(isfolder) == "function" then
		pcall(function()
			for _, p in ipairs({ "ArjhayHub", "ArjhayHub/MM2", Cfg.dir }) do
				if not isfolder(p) then makefolder(p) end
			end
		end)
		local ok, is = pcall(isfolder, Cfg.dir)
		Cfg.useDir = ok and is == true
	end
end

-- .txt, so it can never be mistaken for a config by the .json listing below
Cfg.autoPath = Cfg.useDir and (Cfg.dir .. "/autoload.txt")
	or (Cfg.flat .. "autoload.txt")

function Cfg.add(key, kind, api)
	table.insert(Cfg.rows, { key = key, kind = kind, api = api })
	return api
end

-- Cfg.rows holds a closure per control, and every one of those closures captures
-- the Instances that make up its row. Cfg is also handed out through
-- getgenv().ArjhayHub, which survives the close button -- so without this, closing
-- the hub would leave a table in the global environment pinning the whole
-- destroyed interface in memory.
Bin.onUnload(function()
	Cfg.rows = {}
	Cfg.setStatus = nil
	Cfg.startMin = nil
end)

function Cfg.clean(s)
	s = tostring(s or "")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	s = s:gsub("[^%w _%-]", "")             -- a name becomes a filename; keep it tame
	return string.sub(s, 1, 24)
end

function Cfg.path(name)
	if Cfg.useDir then return Cfg.dir .. "/" .. name .. ".json" end
	return Cfg.flat .. name .. ".json"
end

function Cfg.capture()
	local out = {}
	for _, e in ipairs(Cfg.rows) do
		local ok, v = pcall(function()
			if e.kind == "dropdown" then return e.api:List() end
			return e.api:Get()
		end)
		if ok then out[e.key] = v end
	end
	return out
end

-- A saved config is just a file: it can be hand-edited, half-written, or left over
-- from an older build. Every value is checked against the control it belongs to, so
-- one bad entry is skipped instead of throwing inside a :Set and leaving the whole
-- UI half restored.
local function cfgTypeOk(kind, v)
	if kind == "toggle"   then return type(v) == "boolean" end
	if kind == "slider"   then return type(v) == "number" and v == v end
	if kind == "dropdown" then return type(v) == "table" end
	if kind == "input"    then return type(v) == "string" end
	return false
end

-- JSONDecode hands back whatever the file said, so a dropdown's list is rebuilt
-- from scratch here: strings only, array part only, and capped. A junk entry is
-- inert against a real option list, but without this it would be saved straight
-- back out again on the next Save and live in the file forever.
local function cfgList(v)
	local out = {}
	for _, s in ipairs(v) do
		if type(s) == "string" and #s > 0 and #s < 64 then
			out[#out + 1] = s
			if #out >= 64 then break end
		end
	end
	return out
end

function Cfg.apply(values)
	if type(values) ~= "table" then return 0, 0 end
	local order = {}
	for _, e in ipairs(Cfg.rows) do order[#order + 1] = e end
	table.sort(order, function(a, b)
		local ra, rb = Cfg.rank[a.kind] or 9, Cfg.rank[b.kind] or 9
		if ra ~= rb then return ra < rb end
		return a.key < b.key
	end)

	local done, skipped = 0, 0
	for _, e in ipairs(order) do
		local v = values[e.key]
		if v == nil then
			-- absent is not an error: a config saved before a feature existed just
			-- leaves that control at whatever it already was
		elseif not cfgTypeOk(e.kind, v) then
			skipped = skipped + 1
		else
			if e.kind == "dropdown" then v = cfgList(v) end
			if pcall(function() e.api:Set(v) end) then
				done = done + 1
			else
				skipped = skipped + 1
			end
		end
	end
	return done, skipped
end

function Cfg.names()
	local out = {}
	if not Cfg.canWrite or type(listfiles) ~= "function" then return out end
	local ok, files = pcall(listfiles, Cfg.useDir and Cfg.dir or ".")
	if not ok or type(files) ~= "table" then return out end
	for _, f in ipairs(files) do
		local base = tostring(f):gsub("\\", "/"):match("([^/]+)$")
		if base then
			local name
			if Cfg.useDir then
				name = base:match("^(.+)%.json$")
			else
				name = base:match("^" .. Cfg.flat .. "(.+)%.json$")
			end
			if name and #name > 0 then out[#out + 1] = name end
		end
	end
	table.sort(out, function(a, b) return string.lower(a) < string.lower(b) end)
	return out
end

function Cfg.save(name)
	if not Cfg.canWrite then return false, "this executor cannot write files" end
	local ok, body = pcall(function()
		return HttpService:JSONEncode({
			hub    = "ArjhayHub MM2",
			name   = name,
			saved  = os.date("%Y-%m-%d %H:%M:%S"),
			values = Cfg.capture(),
		})
	end)
	if not ok then return false, "could not encode" end
	if pcall(writefile, Cfg.path(name), body) then return true end
	return false, "could not write the file"
end

function Cfg.load(name)
	if not Cfg.canWrite then return nil, "this executor cannot read files" end
	local p = Cfg.path(name)
	if type(isfile) == "function" then
		local okf, is = pcall(isfile, p)
		if okf and not is then return nil, "no config named " .. tostring(name) end
	end
	local ok, body = pcall(readfile, p)
	if not ok or type(body) ~= "string" then return nil, "could not read it" end
	local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
	if not ok2 or type(data) ~= "table" then return nil, "that file is not valid json" end
	local done, skipped = Cfg.apply(data.values or data)
	return done, skipped
end

function Cfg.remove(name)
	if type(delfile) ~= "function" then return false, "this executor cannot delete files" end
	if pcall(delfile, Cfg.path(name)) then return true end
	return false, "could not delete it"
end

function Cfg.autoGet()
	if not Cfg.canWrite then return nil end
	if type(isfile) == "function" then
		local okf, is = pcall(isfile, Cfg.autoPath)
		if okf and not is then return nil end
	end
	local ok, body = pcall(readfile, Cfg.autoPath)
	if not ok or type(body) ~= "string" then return nil end
	local name = Cfg.clean(body)
	if name == "" then return nil end
	return name
end

-- Clearing writes an empty file rather than deleting one, because delfile is not
-- on every executor and an empty file reads back as "no autoload" anyway.
function Cfg.autoSet(name)
	if not Cfg.canWrite then return false end
	return pcall(writefile, Cfg.autoPath, (name and name ~= "") and name or "")
end

-- Reads ONE value out of the autoload config WITHOUT applying anything.
--
-- Cfg.load cannot serve this. Loading means calling :Set on controls, so it has to
-- run dead last, after every tab is built -- and "should the window open minimized"
-- has to be answered before the window opens at all. Peeking is what makes a
-- start-up preference possible without opening the window and folding it again a
-- fifth of a second later.
--
-- Same untrusted-file rules as Cfg.load: every step is pcall'd, and it returns the
-- raw value so the caller decides what a valid one looks like. nil means "no
-- autoload set", "unreadable", "not json", or "that key was never saved" -- all four
-- are the same answer to the caller, which is "use the default".
function Cfg.autoPeek(key)
	local name = Cfg.autoGet()
	if not name then return nil end
	local ok, body = pcall(readfile, Cfg.path(name))
	if not ok or type(body) ~= "string" then return nil end
	local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
	if not ok2 or type(data) ~= "table" then return nil end
	local vals = data.values or data
	if type(vals) ~= "table" then return nil end
	return vals[key]
end

--==============================================================
-- CONFIG TAB
--==============================================================
local Config = addTab("Config")

-- Created before Farm so the sidebar reads Config, Farm, Combat, ESP top to
-- bottom. Farm is still the tab the hub OPENS on, because it is the one that does
-- something -- see selectTab(Farm) at the bottom of the file.
do
	local sec = Config:Section("Config Manager")
	sec.card.LayoutOrder = 1        -- explicit: two cards tied at 0 sort by whatever
	                                -- GetChildren happens to return, same trap as the
	                                -- sidebar buttons had

	sec:Label("Saves every toggle, slider and dropdown in the hub. Stored as "
		.. ((Cfg.useDir and (Cfg.dir .. "/") or Cfg.flat) .. "NAME.json")
		.. (Cfg.canWrite and "" or "  --  UNAVAILABLE: this executor cannot write files."))

	local status  = sec:Label("Ready.")
	local nameBox = sec:Input("Config Name", "my config")
	-- forward declared: rebuild() below has to be able to switch this off when the
	-- config it points at is deleted, and a closure only captures a local that is
	-- already in scope where the closure is written
	local autoTog

	Cfg.setStatus = function(s) pcall(function() status:Set(s) end) end

	local listSec  = Config:Section("Saved Configs")
	listSec.card.LayoutOrder = 2
	local rowConns = {}
	local rowKids  = {}

	-- Registered with the search index, unlike the rows below: a section with no
	-- searchable row of its own gets hidden the moment anything is typed into the
	-- search box, because applySearch only lights a card that one of its rows matched.
	listSec:Label("Load puts every saved setting back. Delete removes the file.")

	-- The rows are rebuilt on every save and delete, so their connections cannot go
	-- into Bin: that list would grow by two per row per refresh and never shrink.
	-- They get their own list, dropped before each rebuild and once more on unload.
	local function dropRowConns()
		for _, c in ipairs(rowConns) do pcall(function() c:Disconnect() end) end
		rowConns = {}
	end
	Bin.onUnload(dropRowConns)

	local rebuild
	rebuild = function()
		dropRowConns()
		-- destroys exactly what a previous rebuild made, never "every child that is
		-- not a UIListLayout": the static label above is a child too, and destroying
		-- it would leave searchRows holding a dead Instance forever
		for _, k in ipairs(rowKids) do pcall(function() k:Destroy() end) end
		rowKids = {}

		local names = Cfg.names()
		if #names == 0 then
			rowKids[1] = new("TextLabel", {
				Parent = listSec.body, BackgroundTransparency = 1, Font = FONT,
				Size = UDim2.new(1, 0, 0, 22), TextSize = 12, TextColor3 = T.Sub,
				LayoutOrder = 1, TextXAlignment = Enum.TextXAlignment.Left,
				Text = Cfg.canWrite and "Nothing saved yet."
					or "File access unavailable on this executor.",
			})
			return
		end

		local auto = Cfg.autoGet()
		for i, name in ipairs(names) do
			local row = new("Frame", {
				Parent = listSec.body, Active = true, BackgroundColor3 = T.Bg,
				BorderSizePixel = 0, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 32),
			})
			rowKids[#rowKids + 1] = row
			corner(row, 8)
			stroke(row)
			pad(row, 0, 0, 10, 6)
			new("TextLabel", {
				Parent = row, BackgroundTransparency = 1, Font = FONT,
				Size = UDim2.new(1, -112, 1, 0), TextSize = 12,
				TextColor3 = (name == auto) and T.Accent or T.Text,
				Text = (name == auto) and (name .. "   (auto)") or name,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local function chip(label, x, w, col)
				local b = new("TextButton", {
					Parent = row, AutoButtonColor = false, BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0),
					Size = UDim2.fromOffset(w, 22), BackgroundColor3 = col,
					Font = FONT_M, Text = label, TextSize = 11, TextColor3 = T.Text,
				})
				corner(b, 6)
				return b
			end
			local del  = chip("Delete", 0, 50, T.Hover)
			local load = chip("Load", -54, 42, T.AccentDim)

			table.insert(rowConns, load.MouseButton1Click:Connect(function()
				pulse(load)
				nameBox:Set(name)
				local done, extra = Cfg.load(name)
				if done then
					status:Set("Loaded " .. name .. ": " .. done .. " settings restored"
						.. ((extra > 0) and (", " .. extra .. " skipped") or "") .. ".")
				else
					status:Set("Load failed: " .. tostring(extra))
				end
			end))
			table.insert(rowConns, del.MouseButton1Click:Connect(function()
				pulse(del)
				local ok, why = Cfg.remove(name)
				status:Set(ok and ("Deleted " .. name .. ".")
					or ("Delete failed: " .. tostring(why)))
				if ok and Cfg.autoGet() == name then
					Cfg.autoSet(nil)
					if autoTog then autoTog:Set(false, true) end
				end
				rebuild()
			end))
		end
	end

	sec:Button("Save Config", function()
		local name = Cfg.clean(nameBox:Get())
		if name == "" then
			status:Set("Type a name first. Letters, numbers, spaces, - and _ only.")
			return
		end
		local ok, why = Cfg.save(name)
		if not ok then
			status:Set("Save failed: " .. tostring(why))
			return
		end
		nameBox:Set(name)
		if autoTog and autoTog:Get() then Cfg.autoSet(name) end
		status:Set("Saved " .. name .. " (" .. #Cfg.rows .. " settings).")
		rebuild()
	end)

	sec:Button("Refresh List", function()
		rebuild()
		status:Set("Found " .. #Cfg.names() .. " saved.")
	end)

	autoTog = sec:Toggle("Auto Load On Launch", Cfg.autoGet() ~= nil, function(on)
		if not on then
			Cfg.autoSet(nil)
			status:Set("Auto load off.")
			rebuild()
			return
		end
		local name = Cfg.clean(nameBox:Get())
		if name == "" then
			status:Set("Put a config name in the box first, then switch this on.")
			autoTog:Set(false, true)      -- silent, or this callback re-enters itself
			return
		end
		Cfg.autoSet(name)
		status:Set("Auto load set to " .. name .. ".")
		rebuild()
	end)

	do
		local a = Cfg.autoGet()
		if a then nameBox:Set(a) end
	end
	rebuild()

	----------------------------------------------------------------
	-- Window
	----------------------------------------------------------------
	local win = Config:Section("Window")
	win.card.LayoutOrder = 3

	-- This toggle stores a preference and nothing else -- flipping it now must NOT
	-- minimize the window, because "start minimized" is a statement about the next
	-- load, and folding the hub the instant you tick the box reads like a bug. The
	-- thing that acts on it is the open step at the bottom of the file, which peeks
	-- the saved value through Cfg.autoPeek before anything is drawn.
	Cfg.add("window.startmin", "toggle",
	win:Toggle("Start Minimized", false, function(v) Cfg.startMin = v end))

	win:Label("Opens the hub as just the circle on the next load. Tap the circle to"
		.. " open the window, or press Right Shift. It is saved inside the config like"
		.. " every other setting, so it only takes effect for a config that Auto Load"
		.. " is switched on for -- tick this, save, then switch Auto Load on above.")
end

--==============================================================
-- FARM TAB   (renamed from "Main" by request)
--==============================================================
local Farm = addTab("Farm")

--------------------------------------------------------------------
-- Auto Collect Coins
--------------------------------------------------------------------
local coinSec = Farm:Section("Auto Collect Coins")

local COIN_RADIUS = 150            -- fixed by request; the slider is gone
local COIN_TOUCH  = 10             -- studs: close enough to grab in passing
local COIN_STOP   = 2              -- studs: close enough to count as ARRIVED
local coinCats    = { Coins = true }
local coinSpeed   = 60
local coinDelay   = 1              -- the deliberate stop at each coin
local autoCoins   = false

local nameCache, namesDirty = {}, true

local function currentNames()
	if not namesDirty then return nameCache end
	local set = {}
	if coinsFolder then
		local wanted = {}
		for _, cat in ipairs(COIN_CATS) do
			if coinCats.Everything or coinCats[cat.label] then
				for _, f in ipairs(cat.folders) do wanted[f] = true end
			end
		end
		for _, folder in ipairs(coinsFolder:GetChildren()) do
			if wanted[folder.Name] then walkTemplates(folder, set) end
		end
	end
	-- the "Extra Names" box was deleted by request, so the template names above
	-- are route one and the by-position CoinContainer scan is route two. Both
	-- still exist, which is the point: a rename can only break one of them.
	nameCache, namesDirty = set, false
	return set
end

-- container cache: a full Workspace walk is expensive, so we remember the
-- parents that actually held a hit and only re-walk every few seconds.
local containers, containerStamp = {}, -1e9

local function nameHit(names, inst)
	if IGNORE_NAMES[inst.Name] then return false end
	if not (inst:IsA("BasePart") or inst:IsA("Model")) then return false end
	return (names[inst.Name] or names[baseName(inst.Name)]) and true or false
end

local function rebuildContainers(names)
	local found, seen = {}, {}
	local function add(p)
		if p and not seen[p] then
			seen[p] = true
			table.insert(found, p)
		end
	end
	for _, inst in ipairs(workspace:GetDescendants()) do
		if CONTAINER_NAMES[inst.Name] then
			-- remember a CoinContainer even while it is EMPTY (between rounds), so
			-- that when coins respawn — the dump caught roughly two per second — we
			-- see them instantly instead of waiting out the 4s re-walk throttle
			add(inst)
		elseif nameHit(names, inst) then
			add(inst.Parent)
		end
	end
	containers, containerStamp = found, os.clock()
end

local function candidates(names, force)
	-- throttled: never re-walk the whole Workspace more than once every 4s, even
	-- when the last walk found nothing (between rounds there are simply no coins)
	if force or (os.clock() - containerStamp) > 4 then
		rebuildContainers(names)
	end
	-- a known CoinContainer holds nothing but pickups, so when Coins (or
	-- Everything) is ticked we take its children by POSITION IN THE TREE rather
	-- than by name. That is what makes this immune to the rename we got caught by:
	-- the templates are called "Coin", the live clones are called "Coin_Server".
	local agnostic = (coinCats.Coins or coinCats.Everything) and true or false
	local out = {}
	for _, c in ipairs(containers) do
		-- alive(), not c.Parent: a container inside a destroyed map still has a
		-- parent and still lists its leftover coins. That is the ghost pool.
		if alive(c) then
			local takeAll = agnostic and CONTAINER_NAMES[c.Name]
			for _, inst in ipairs(c:GetChildren()) do
				if (inst:IsA("BasePart") or inst:IsA("Model"))
					and not IGNORE_NAMES[inst.Name]
					and (takeAll or nameHit(names, inst)) then
					table.insert(out, inst)
				end
			end
		end
	end
	return out
end

-- the movement loop runs every frame, so the child scan above gets its own short
-- cache on top of the 4s container throttle. Coins respawn about twice a second,
-- so a tenth of a second of staleness is invisible.
local poolCache, poolStamp = {}, -1e9

local function livePool(force)
	if force or (os.clock() - poolStamp) > 0.1 then
		poolCache, poolStamp = candidates(currentNames(), force), os.clock()
	end
	return poolCache
end

-- noclip, snapshot-and-restore so we never leave the character non-solid
local collideSnap = setmetatable({}, { __mode = "k" })
local noclipConn, noclipOn = nil, false

local function restoreCollide()
	local snap = collideSnap
	collideSnap = setmetatable({}, { __mode = "k" })   -- swap, don't clear
	for part, was in pairs(snap) do
		if part.Parent then pcall(function() part.CanCollide = was end) end
	end
end

local function setNoclip(on)
	noclipOn = on
	if on then
		if noclipConn then return end
		noclipConn = Bin.conn(RunService.Stepped:Connect(function()
			if not noclipOn then return end
			local _, char = myRoot()
			if not char then return end
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then
					if collideSnap[p] == nil then collideSnap[p] = true end
					p.CanCollide = false
				end
			end
		end))
	else
		restoreCollide()
	end
end

Bin.onUnload(function()
	autoCoins, noclipOn = false, false
	restoreCollide()
end)

-- The server owns the coin's .Touched (see CONTAINER_NAMES note), and the touch
-- interest can sit on the pickup part OR on one of the visual parts welded to it,
-- so fire against all of them. Capped: a coin is 3 parts, not 300.
local function forceTouch(hrp, inst, part)
	local hit = false
	if typeof(FTI) == "function" then
		local targets, n = { part }, 1
		for _, d in ipairs(inst:GetDescendants()) do
			if n >= 4 then break end
			if d:IsA("BasePart") and d ~= part then
				n = n + 1
				targets[n] = d
			end
		end
		for _, t in ipairs(targets) do
			if pcall(function() FTI(hrp, t, 0) end) then hit = true end
		end
		task.wait()
		for _, t in ipairs(targets) do
			pcall(function() FTI(hrp, t, 1) end)
		end
	end
	local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
		or (part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
	if prompt and typeof(FPP) == "function" then pcall(FPP, prompt) end
	return hit
end

--==============================================================
-- CONTINUOUS DRIVER
--
-- Two rewrites in, the stutter kept coming back for the SAME reason, and it was
-- never the tween or the delay slider: the character arrived at the coin and
-- then had to WAIT there, because the coin it was standing on was still the
-- nearest one and therefore still the target. Only the server can destroy it,
-- so every pickup paid for a round trip. That pause is the "it stops a little
-- bit" in the report.
--
-- So stop treating "the coin still exists" as "the coin is still wanted". The
-- moment a coin comes in range it is CLAIMED and pushed on a queue, and claimed
-- coins are invisible to target selection — the very next frame is already free
-- to move on while the server is still catching up on the last one. A separate
-- worker drains that queue and fires the touches. A claim that did not pay off
-- (the part is still there after RECLAIM_AFTER) is released, so a refused touch
-- is retried instead of silently abandoned.
--
-- On top of that the user then asked for the pause BACK, but a regular one:
-- "tween stop 0.5 and tween stop 0.5". That is `holdUntil` in coinFrame — a
-- fixed stop the DRIVER owns, started only when the character actually ARRIVES
-- at the coin it committed to (`targetInst`, claimed at COIN_STOP instead of
-- COIN_TOUCH). The two designs are not in conflict: the queue removed the
-- *server* wait, which was irregular and unpredictable, and holdUntil adds back
-- a stop of a length we choose. Nothing in here ever waits on the server again.
--==============================================================
local driveConn  = nil
local driveGen   = 0                                    -- invalidates an old worker
local claimQueue = {}                                   -- FIFO of coins to touch
local claimHead, claimTail = 1, 0
local claimed    = setmetatable({}, { __mode = "k" })   -- coin -> os.clock() claimed
local reclaims   = setmetatable({}, { __mode = "k" })   -- coin -> unpaid claim count
local blocked    = setmetatable({}, { __mode = "k" })   -- coin -> os.clock() gave up
local lastWarnAt = 0
local holdUntil  = 0                                    -- the deliberate stop, by request
local targetInst = nil                                  -- the coin we committed to fly at
local charSeen   = setmetatable({}, { __mode = "k" })   -- characters we have already reset for

local RECLAIM_AFTER = 1.2      -- seconds before an unpaid claim is released
local QUEUE_CAP     = 128      -- past this we simply do not claim, so nothing is lost
local FIRE_RANGE    = 60       -- studs: past this, release instead of firing blind
local GIVE_UP_AFTER = 3        -- unpaid claims on ONE instance before we stop chasing it
local BLOCK_FOR     = 20       -- seconds it sits on the bench before it gets another go
local MAX_STEP      = 8        -- studs the root may move in a SINGLE frame, any speed

-- the status label is gone by request, so a failure has to reach the console or
-- it reaches nobody. Rate limited: this can be called every frame.
local function coinWarn(msg)
	if (os.clock() - lastWarnAt) > 1 then
		lastWarnAt = os.clock()
		warn("[Arjhay Hub] coins: " .. tostring(msg))
	end
end

-- swap, don't clear: a fresh table can never be mutated out from under a walk
local function dropClaims()
	claimed = setmetatable({}, { __mode = "k" })
	reclaims = setmetatable({}, { __mode = "k" })
	blocked = setmetatable({}, { __mode = "k" })
	claimQueue, claimHead, claimTail = {}, 1, 0
	holdUntil = 0                  -- never resume a stop that belongs to an old run
	targetInst = nil               -- and never hold a reference to an old coin
end

local function pushClaim(inst, now)
	claimed[inst] = now
	claimTail = claimTail + 1
	claimQueue[claimTail] = inst    -- indices only; table.remove would be O(n)
end

-- The worker only fires touches; the DRIVER owns the timing now (see holdUntil
-- in coinFrame). It must not sleep for coinDelay itself: the stop the user asked
-- for happens while parked next to the coin, and if the worker also waited the
-- queue would fall a whole delay behind the character on every pickup. It exits
-- on its own when autoCoins clears or its generation is superseded, which is why
-- it needs no Bin entry beyond the flag hooks below.
local function startDrain()
	driveGen = driveGen + 1
	local gen = driveGen
	task.spawn(function()
		while autoCoins and gen == driveGen do
			if claimHead > claimTail then
				task.wait(0.03)                       -- queue empty: idle cheaply
			else
				local inst = claimQueue[claimHead]
				claimQueue[claimHead] = nil
				claimHead = claimHead + 1
				local hrp = myRoot()
				local part = alive(inst) and partOf(inst) or nil
				if hrp and alive(part) and sanePos(part.Position) then
					-- The touch used to fire from ~0 studs, which is the distance we
					-- know the server accepts. Pacing means we can be further off by
					-- the time a coin's turn comes, so past FIRE_RANGE we release the
					-- claim instead of firing on a guess: it becomes a target again
					-- and gets touched from close up on the next pass.
					if (part.Position - hrp.Position).Magnitude > FIRE_RANGE then
						claimed[inst] = nil
					else
						local ok, err = pcall(forceTouch, hrp, inst, part)
						if not ok then coinWarn(err) end
						task.wait()                   -- one frame, so a burst still paces
					end
				end
			end
		end
	end)
end

local function stopDrain()
	driveGen = driveGen + 1        -- any live worker falls out of its loop
end

-- STOP THE CHARACTER — and stopping is an active instruction, not a `return`.
-- Noclip is on for the whole run, so any frame that skips the CFrame write hands
-- the character to gravity and it sinks through the map. Every path out of
-- coinFrame that does not glide has to come through here instead: the deliberate
-- 0.5s+ pause at a coin, an empty container between rounds, and — the case the
-- user asked about — nothing detected inside COIN_RADIUS.
local function holdStill(hrp)
	hrp.CFrame = CFrame.new(hrp.Position) * (hrp.CFrame - hrp.Position)
	pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
end

-- move the root toward pos at coinSpeed studs/second, keeping the current facing
local function glideToward(hrp, pos, dt)
	local here = hrp.Position
	-- Never hand the engine a position we cannot vouch for. A NaN or an
	-- out-of-world coordinate replicates as an invalid position and the server
	-- kicks for it, so a bad goal means stand still, not "try it and see".
	if not sanePos(pos) or not sanePos(here) then
		coinWarn("refused an out-of-world position")
		holdStill(hrp)
		return math.huge
	end
	local goal = pos + Vector3.new(0, 1.5, 0)
	local delta = goal - here
	local dist  = delta.Magnitude
	-- Speed 0 is a real setting now that the slider starts there, and "already on
	-- top of the goal" is a real state. Both take a step of zero, and BOTH still
	-- write the position: an early return here would be the sinking bug again.
	local step = 0
	if dist >= 0.05 and coinSpeed > 0 then
		-- THE ANTI-KICK CLAMP. dt is capped at a thirtieth and the whole step at
		-- MAX_STEP, so a frame hitch — a round change, a map load, an alt-tab —
		-- cannot turn one frame into a 25-stud jump. It never bites in normal
		-- play (100 studs/s at 60fps is 1.7 studs a frame); it only exists for
		-- the hitch, which is exactly when the server is least forgiving.
		step = math.min(dist, coinSpeed * math.min(dt, 1 / 30), MAX_STEP)
	end
	local nextPos = (step > 0) and (here + delta.Unit * step) or here
	if not sanePos(nextPos) then nextPos = here end
	-- CFrame.new(pos) alone would snap the character to face north; keep rotation
	hrp.CFrame = CFrame.new(nextPos) * (hrp.CFrame - hrp.Position)
	-- gravity would otherwise accumulate between our writes and fling us down
	pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
	return dist - step
end

local function coinFrame(dt)
	local hrp, char = myRoot()
	if not hrp then return end

	local now = os.clock()

	-- A NEW BODY IS A NEW WORLD. Dying, respawning or a round change gives us a
	-- fresh character somewhere else entirely, and every claim and target we were
	-- holding belongs to where the last one stood. Weak keys, so the characters
	-- we have already seen do not pin a single destroyed model.
	if char and not charSeen[char] then
		charSeen[char] = true
		dropClaims()
	end

	-- Dead is not a state to fly in. MM2 leaves the body behind for a moment after
	-- a kill, and shoving a corpse across the map is both pointless and exactly
	-- the sort of position a server-side check objects to. Let go and let it lie —
	-- no CFrame write at all here, because sinking does not matter to a corpse and
	-- a fresh character is on its way.
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then
		targetInst = nil
		return
	end

	-- THE REQUESTED RHYTHM: fly -> stop for coinDelay -> fly -> stop.
	if now < holdUntil then
		holdStill(hrp)
		return
	end

	local pool = livePool()
	-- Nothing in the world to fly at. Between MM2 rounds this is the normal state
	-- and the answer is to stop the character, not to let it sink — and to let go
	-- of the target, or the early return here would smuggle it into the next round.
	if #pool == 0 then
		targetInst = nil
		holdStill(hrp)
		return
	end

	local best, bestPart, bestD = nil, nil, math.huge
	local tgtPart = nil                              -- set if targetInst is still valid
	local queued  = claimTail - claimHead + 1

	for _, inst in ipairs(pool) do
		local part = partOf(inst)
		-- alive(), not part.Parent — see the note on alive(). And a part whose
		-- position is not a real coordinate is not a place we will fly to.
		if alive(part) and sanePos(part.Position) then
			local at = claimed[inst]
			if at and (now - at) > RECLAIM_AFTER then
				-- the touch did not pay off; put it back in play
				claimed[inst] = nil
				at = nil
				-- ...but not forever. Something that sits in a CoinContainer and
				-- never responds to a touch (map furniture, a coin the server has
				-- already banked) would otherwise be re-targeted every second for
				-- the rest of the round, which reads exactly like "it still tweens
				-- when there are no coins". Three refusals and it goes on the bench.
				local n = (reclaims[inst] or 0) + 1
				reclaims[inst] = n
				if n >= GIVE_UP_AFTER then
					blocked[inst] = now
					if inst == targetInst then targetInst = nil end
				end
			end
			local bench = blocked[inst]
			if bench and (now - bench) > BLOCK_FOR then
				blocked[inst], reclaims[inst] = nil, nil   -- time served, try again
				bench = nil
			end
			if not at and not bench then
				local d = (part.Position - hrp.Position).Magnitude
				if inst == targetInst then
					-- The coin we are flying AT is the one that earns the stop, and
					-- it is claimed only on ARRIVAL. Claiming it at COIN_TOUCH like
					-- any other coin would make it invisible to targeting 10 studs
					-- out, so the character would peel off early and never actually
					-- get there — the stop would never fire at all.
					if d <= COIN_STOP and queued < QUEUE_CAP then
						pushClaim(inst, now)
						queued = queued + 1
						if coinDelay > 0 then holdUntil = now + coinDelay end
						targetInst = nil
					elseif d <= COIN_RADIUS then
						tgtPart = part
					else
						-- THE COMMITMENT EXPIRED. This branch used to have no
						-- distance ceiling at all, and a commitment outlives the
						-- reason for it: a respawn or a round change moves us, and
						-- then the character flies hundreds of studs back to a coin
						-- that is nowhere near it — with no coin in sight the whole
						-- way, and often clean out of the map, which is the
						-- "Invalid position" kick. Let go and re-pick from what is
						-- actually near us.
						targetInst = nil
					end
				elseif d <= COIN_TOUCH and queued < QUEUE_CAP then
					-- swept up in passing: a free grab, and it must NOT start a stop
					-- or the character would freeze in mid-air beside coins it was
					-- only flying past.
					pushClaim(inst, now)
					queued = queued + 1
				elseif d <= COIN_RADIUS and d < bestD then
					best, bestPart, bestD = inst, part, d
				end
			end
		end
	end

	if tgtPart then
		glideToward(hrp, tgtPart.Position, dt)
	else
		-- the target was collected, destroyed, or dropped out of the pool. This
		-- assignment runs even when best is nil, on purpose: holding a strong
		-- reference to a destroyed Instance is exactly the leak we don't allow.
		targetInst = best
		if best then
			glideToward(hrp, bestPart.Position, dt)
		else
			-- NOTHING DETECTED INSIDE COIN_RADIUS (150 studs): stop the character
			-- and wait right here. It stays put until a coin spawns in range, then
			-- flies off again on that frame.
			holdStill(hrp)
		end
	end
end

local function setCollecting(on)
	autoCoins = on
	if on then
		if driveConn then return end
		dropClaims()
		setNoclip(true)                       -- on for the whole run, by request
		livePool(true)                        -- first frame already has a target
		startDrain()
		driveConn = Bin.conn(RunService.Heartbeat:Connect(function(dt)
			if not autoCoins then return end
			-- never swallow the throw: a silent collector is unfixable
			local ok, err = pcall(coinFrame, dt)
			if not ok then coinWarn(err) end
		end))
	else
		if driveConn then
			pcall(function() driveConn:Disconnect() end)
			driveConn = nil
		end
		stopDrain()
		dropClaims()
		setNoclip(false)
	end
end

-- the driver is a connection, but the drain worker is a spawned loop that
-- Bin.flush() cannot reach — it needs the flag cleared or it keeps touching
-- coins after unload. Do NOT teleport anything here: unloading the hub should
-- never move the character somewhere it did not ask to go.
Bin.onUnload(function()
	autoCoins = false
	if driveConn then
		pcall(function() driveConn:Disconnect() end)
		driveConn = nil
	end
	stopDrain()
	dropClaims()
	setNoclip(false)
end)

--------------------------------------------------------------------
-- controls, in the order asked for: target → speed → delay → toggle
--------------------------------------------------------------------
-- Cfg.add returns the control it was handed, so registering one is a wrap around
-- the call that was already here. The keys are fixed strings and must stay fixed:
-- rename one and every config the user has already saved forgets that setting.
Cfg.add("farm.coins.target", "dropdown",
coinSec:Dropdown("Target", CAT_LABELS, { "Coins" }, function(set)
	coinCats, namesDirty = set, true
	containerStamp, poolStamp = -1e9, -1e9    -- force a fresh Workspace walk
end))

-- 0 is a real setting on this one, not a floor: at 0 the character stops flying
-- and only takes coins that come to it (see glideToward)
Cfg.add("farm.coins.speed", "slider",
coinSec:Slider("Tween Speed (studs/s)", 0, 100, 60, function(v) coinSpeed = v end))
-- the length of the deliberate stop at each coin. It starts at 1 by request, so
-- there is no longer a "never stop" setting here.
Cfg.add("farm.coins.delay", "slider",
coinSec:Slider("Delay Between Pickups", 1, 2, 1, function(v) coinDelay = v end))

Cfg.add("farm.coins.enabled", "toggle",
coinSec:Toggle("Auto Collect Coins", false, function(on) setCollecting(on) end))

-- Deleted by request: "Return To Start When Empty", the status label, and the
-- "Extra Names" textbox. Pickup names come from the ReplicatedStorage.Coins
-- templates plus the by-position CoinContainer scan; there is nothing left to
-- type in. Failures go to the console through coinWarn.

--------------------------------------------------------------------
-- Auto Claim Shells
--------------------------------------------------------------------
local shellSec = Farm:Section("Auto Claim Shells")

local autoShells, shellBusy = false, false
local shellDelay = 0.4
local claimStamp = setmetatable({}, { __mode = "k" })
local lastWin  = nil           -- which click variant last actually worked

local function trulyVisible(obj)
	local cur = obj
	while cur and cur ~= game do
		if cur:IsA("GuiObject") then
			if not cur.Visible then return false end
			if cur.AbsoluteSize.X <= 0 or cur.AbsoluteSize.Y <= 0 then return false end
		elseif cur:IsA("LayerCollector") then
			if not cur.Enabled then return false end
		end
		cur = cur.Parent
	end
	return true
end

-- The recon dump found the real Shells popup and, importantly, that its button
-- reports  MouseButton1Click connections=0  — the game binds the press somewhere
-- getconnections cannot reach. So a synthetic click is not a fallback here, it is
-- the primary path, and it has to actually land on the button.
local CLAIM_PATHS = {
	{ "CrossPlatform", "NewItem", "Medium", "Container", "Claim" },
	{ "MainGUI", "Game", "NewItem", "Container", "Claim" },
}

-- Never press these, whatever their text says: a stray press on a purchase
-- button is not recoverable.
local CLAIM_DENY = { "buy", "purchase", "robux", "gamepass", "get it now", "upgrade", "pack" }

local function claimDenied(btn)
	local node, hops = btn, 0
	while node and node ~= game and hops < 5 do
		local low = string.lower(node.Name)
		for _, kw in ipairs(CLAIM_DENY) do
			if string.find(low, kw, 1, true) then return true end
		end
		node, hops = node.Parent, hops + 1
	end
	local txt = string.lower(btn.Text)
	for _, kw in ipairs(CLAIM_DENY) do
		if string.find(txt, kw, 1, true) then return true end
	end
	return false
end

local function rectsOverlap(aPos, aSize, bPos, bSize)
	return aPos.X < bPos.X + bSize.X and bPos.X < aPos.X + aSize.X
		and aPos.Y < bPos.Y + bSize.Y and bPos.Y < aPos.Y + aSize.Y
end

--==============================================================
-- WHY THIS IS SO CAREFUL
--
-- "Claim Once Now" worked and the loop did not, which means the *press* itself is
-- unreliable, not the search. Three things can eat a synthetic click and all of
-- them are invisible from Lua:
--   1. GUI INSET. AbsolutePosition is measured from below Roblox's 36px top bar,
--      but VirtualInputManager takes true window coordinates. The dump has the
--      Claim button at y=610.5 height 50, so its centre is 635.5 — click 36px off
--      and you land at 599.5, eleven pixels ABOVE the button. Just barely a miss,
--      which is exactly what "sometimes" looks like.
--   2. OUR OWN WINDOW. Disabling the ScreenGui does not change hit-testing until
--      the next frame, so a click sent in the same frame still hits the hub.
--   3. THE POPUP'S OWN ANIMATION. NewItem has a sibling `Animation` frame (the
--      dump caught Animation.ItemIcon being created), and while it is up it can
--      cover the card. By hand you always click after it settles; a 0.4s loop
--      does not.
-- So: try coordinate variants, yield a frame after hiding ourselves, and above all
-- VERIFY — a click only counts when the popup actually goes away. Nothing here
-- trusts pcall success as proof that anything happened.
--==============================================================
local function claimGone(btn)
	if not btn.Parent then return true end
	local ok, vis = pcall(trulyVisible, btn)
	return ok and not vis
end

-- true screen coordinates for a GUI element's centre. Elements under a
-- LayerCollector that does NOT ignore the inset are reported 36px high.
local function clickPoint(btn, useInset)
	local c = btn.AbsolutePosition + btn.AbsoluteSize / 2
	if useInset then
		local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
		if ok and inset then c = c + inset end
	end
	return c
end

local function insetApplies(btn)
	local cur = btn
	while cur and cur ~= game do
		if cur:IsA("LayerCollector") then
			local ok, ignores = pcall(function() return cur.IgnoreGuiInset end)
			return not (ok and ignores)
		end
		cur = cur.Parent
	end
	return true
end

-- hide our own GUI only while it is actually in the way, and give Roblox a frame
-- to notice before the click goes out
local function withHubHidden(btn, fn)
	local inTheWay = false
	if screen.Enabled then
		for _, ours in ipairs({ root, pip }) do
			if ours.Visible and rectsOverlap(btn.AbsolutePosition, btn.AbsoluteSize,
				ours.AbsolutePosition, ours.AbsoluteSize) then
				inTheWay = true
				break
			end
		end
	end
	if inTheWay then
		screen.Enabled = false
		RunService.Heartbeat:Wait()            -- hit-testing updates next frame
	end
	local ok, err = pcall(fn)
	if inTheWay then screen.Enabled = true end -- always restore, even on throw
	return ok, err
end

local function sendClick(btn, useInset)
	return withHubHidden(btn, function()
		local vim = game:GetService("VirtualInputManager")
		local c = clickPoint(btn, useInset)
		-- hover first: some buttons only arm on the enter event
		pcall(function() vim:SendMouseMoveEvent(c.X, c.Y, game) end)
		vim:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 1)
		task.wait(0.06)
		-- recompute: a popup that is still animating may have shifted under us
		local c2 = clickPoint(btn, useInset)
		vim:SendMouseButtonEvent(c2.X, c2.Y, 0, false, game, 1)
	end)
end

-- getconnections is a free shot, but only when there is something connected:
-- firing an empty signal "succeeds" while doing nothing, and treating that as a
-- press is what would make us skip the click that actually works.
local function fireHandlers(btn)
	if typeof(GETCON) ~= "function" then return false end
	local fired = false
	for _, signal in ipairs({ btn.Activated, btn.MouseButton1Click, btn.MouseButton1Down }) do
		local ok, conns = pcall(GETCON, signal)
		if ok and type(conns) == "table" and #conns > 0 then
			for _, c in ipairs(conns) do
				if pcall(function() c:Fire() end) then
					fired = true
				elseif pcall(function() c.Function() end) then
					fired = true
				end
			end
		end
	end
	return fired
end

-- Presses the button and returns (didItWork, whichMethod). Tries the cheapest
-- thing first, re-checks after every attempt, and remembers the winner so the
-- next popup starts with the method that worked last time.
local function pressButton(btn)
	if claimDenied(btn) then return false, "denied" end

	local attempts = {
		{ name = "handlers", run = function() return fireHandlers(btn) end },
		{ name = "click",    run = function() return sendClick(btn, insetApplies(btn)) end },
		{ name = "click+inset", run = function() return sendClick(btn, true) end },
		{ name = "click-raw",   run = function() return sendClick(btn, false) end },
	}

	-- start with whatever worked last time, then fall through the rest
	if lastWin then
		for i, a in ipairs(attempts) do
			if a.name == lastWin and i > 1 then
				table.remove(attempts, i)
				table.insert(attempts, 1, a)
				break
			end
		end
	end

	for _, a in ipairs(attempts) do
		if claimGone(btn) then return true, "already gone" end
		a.run()
		task.wait(0.12)                    -- let the popup react before judging
		if claimGone(btn) then
			lastWin = a.name
			return true, a.name
		end
	end
	return false, "all methods missed"
end

-- one sweep of the PlayerGui; returns how many buttons it actually pressed.
-- No "only shells" filter any more — the toggle is gone and the single Auto Claim
-- Shells switch does what the manual button used to do, which is the version the
-- user could confirm working. CLAIM_DENY is what keeps this safe.
local function claimPass()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return 0 end
	local pressed = 0

	local function consider(d)
		if not (d:IsA("TextButton") and string.find(string.lower(d.Text), "claim", 1, true)) then
			return
		end
		if not trulyVisible(d) then return end
		-- short debounce only. The old 1s window meant a missed press could not be
		-- retried for over a second — long enough for the popup to time out on its
		-- own and look like the feature simply never fired.
		local stamp = claimStamp[d]
		if stamp and os.clock() - stamp <= 0.3 then return end
		claimStamp[d] = os.clock()
		if pressButton(d) then pressed = pressed + 1 end
	end

	-- fast path first: the two confirmed popup paths, so the common case costs two
	-- lookups instead of a full PlayerGui walk
	local seen = {}
	for _, path in ipairs(CLAIM_PATHS) do
		local node = pg
		for _, seg in ipairs(path) do
			node = node and node:FindFirstChild(seg)
		end
		if node and not seen[node] then
			seen[node] = true
			consider(node)
		end
	end

	-- then the general sweep, in case the popup moved or is a variant we have not
	-- seen (Small/Large containers, a future event layout)
	for _, d in ipairs(pg:GetDescendants()) do
		if not seen[d] then consider(d) end
	end

	return pressed
end

local function shellLoop()
	if shellBusy then return end
	shellBusy = true
	while autoShells do
		-- the status label is gone by request, so the only place a throw can
		-- surface is the console. Never swallow it silently.
		local ok, err = pcall(claimPass)
		if not ok then
			warn("[Arjhay Hub] shells: " .. tostring(err))
			task.wait(0.4)
		end
		task.wait(shellDelay)
	end
	shellBusy = false
end

Cfg.add("farm.shells.enabled", "toggle",
shellSec:Toggle("Auto Claim Shells", false, function(on)
	autoShells = on
	if on then task.spawn(shellLoop) end
end))
Cfg.add("farm.shells.delay", "slider",
shellSec:Slider("Check Every (sec)", 0.1, 2, 0.4, function(v) shellDelay = v end))

-- "Claim Once Now" and the status label were deleted by request. The toggle now
-- does everything the manual button did.

-- the loop is a while-loop, not a connection, so Bin.flush() cannot reach it:
-- clear the flag it spins on or it keeps polling forever after the close button
Bin.onUnload(function() autoShells = false end)

--==============================================================
-- COMBAT TAB   (placeholder)
--==============================================================
-- Sits above Performance on purpose -- the tab order was asked for as Config, Farm,
-- Combat, Performance, and addTab() takes its LayoutOrder from #tabs, so creation
-- order IS sidebar order. Moving a tab means moving its addTab() call, nothing else.
comingSoon(addTab("Combat"),
	"Kill aura and gun mods are not built yet. This tab is a placeholder. Murderer"
	.. " tracking lives in the ESP tab.")

--==============================================================
-- PERFORMANCE TAB   (FPS Boost)
--==============================================================
-- Asked for as "FPS Boost this like it will destroy building, walls etc of course
-- should all function working". Both halves of that are requirements, and the second
-- one decides the whole design.
--
-- WHAT IT WILL NOT DO, AND WHY
-- It does not delete anything you can stand on. A part with CanCollide = true is made
-- INVISIBLE, never destroyed. Deleting a floor drops you through the map, which in
-- MM2 kills you for the round -- and dying is a bigger performance problem than any
-- number of frames. It is also how you earn a position kick. So the split is:
--   * CanCollide = false  ->  DESTROYED. Nothing stands on it, nothing collides with
--     it, nothing can be reached through it. This is the foliage, the signs, the
--     clutter, the decorative meshes -- pure render cost, zero gameplay. This is the
--     "destroy" that was asked for, and it is the half where destroying is free.
--   * CanCollide = true   ->  Transparency 1 + CastShadow off. The wall is gone from
--     the screen and gone from the render pass, but the collision box is untouched,
--     so the map still plays exactly as it did. You cannot fall out of it, you cannot
--     walk through a wall you should not, and the murderer's line of sight is
--     unchanged.
-- Deleting collidable walls would ALSO be a gameplay change, not just a visual one,
-- which "all function working" rules out on its own.
--
-- WHY THE DESTROY IS LESS PERMANENT THAN IT SOUNDS
-- MM2 builds a fresh map every round. Anything destroyed here is back next round,
-- and the sweep simply runs again on the new map. So the irreversible half undoes
-- itself on a timer measured in minutes, which is what makes destroying acceptable
-- at all. Turning a switch off restores the hidden half immediately from a snapshot.
--
-- PROTECTED BY STRUCTURE, NOT BY A LIST OF NAMES
-- Coins, characters, tools and pickups are skipped entirely. Note that protection
-- matching here is deliberately LOOSE (substrings, not whole words) -- the exact
-- opposite call from Auto Pick Device above. There, over-matching presses the wrong
-- button and costs a rejoin, so it must be strict. Here, over-matching keeps a prop
-- alive and costs a frame, while under-matching deletes a coin the collector needs.
-- Same file, opposite rule, because the cost of being wrong points the other way.
--
-- IT MUST NOT COST WHAT IT SAVES
-- A synchronous walk of a full MM2 Workspace, mutating every part, is a multi-second
-- freeze on the phone this is meant to help. So the sweep is PACED: a fixed budget of
-- instances per frame, yielding in between. Protection answers are memoised per
-- ancestor, because otherwise every part re-climbs and re-lowercases the same six
-- parents. And the restore walk materialises its keys into a strong array first --
-- never iterate a weak table across a yield, or a collection mid-walk throws
-- "invalid key to 'next'".
--==============================================================
;(function()
	local Perf = addTab("Performance")

	-- declared in here, not at the top of the file: the main chunk is at its local
	-- register ceiling and a function body is its own frame (see the ESP note below)
	local Lighting = game:GetService("Lighting")
	local WS       = workspace

	-- ON is the truth. Every switch writes exactly one field of it and asks for a
	-- pass; nothing else holds state about what is stripped.
	local ON = { geo = false, light = false, tex = false, fx = false, water = false }

	local BUDGET  = 250        -- instances touched per frame during a sweep
	local RESWEEP = 6          -- seconds between catch-up passes while anything is on

	local alive           = true
	local working, again  = false, false
	local touched         = false      -- have we modified anything that needs undoing
	local fpsCap          = 0

	-- weak keys throughout: MM2 destroys the whole map every round, and a strong
	-- reference to last round's 8000 parts is a leak that grows for as long as the
	-- session lasts
	local snap    = setmetatable({}, { __mode = "k" })   -- part     -> original fields
	local fxSnap  = setmetatable({}, { __mode = "k" })   -- effect   -> original Enabled
	local decSnap = setmetatable({}, { __mode = "k" })   -- decal    -> original Transparency
	local protCache = setmetatable({}, { __mode = "k" }) -- instance -> protected?

	----------------------------------------------------------------
	-- what must never be touched
	----------------------------------------------------------------
	-- Two independent routes to the same protection, on purpose: a rename in the game
	-- can only ever break one of them. This is the same reasoning as currentNames()
	-- over in Farm, and for the same reason -- these are the instances Auto Collect
	-- Coins and the ESP tab read, so losing one silently breaks a different feature.
	local KEEP_SUB = {
		"coin", "gun", "knife", "revolver", "pistol", "weapon",
		"drop", "spawn", "chest", "crate", "door", "ladder", "elevator",
	}
	local function nameKept(n)
		local low = string.lower(n)
		for _, w in ipairs(KEEP_SUB) do
			if string.find(low, w, 1, true) then return true end
		end
		-- route two: the game's own word for "things that matter" is a Container
		-- folder. Live coins are Coin_Server inside CoinContainer.
		return #low >= 9 and string.sub(low, -9) == "container"
	end

	-- Memoised and recursive: each ancestor is answered once and every part below it
	-- reuses that answer. Without this, a 9000 part map re-climbs and re-lowercases
	-- the same handful of parent names 9000 times per sweep.
	local function keptAncestor(node)
		if node == nil or node == WS then return false end
		local hit = protCache[node]
		if hit ~= nil then return hit end
		local v
		if node:IsA("Tool") or node:IsA("Accessory") then
			v = true                        -- held or equipped: never scenery
		elseif node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			v = true                        -- a character. Player ESP reads these.
		elseif nameKept(node.Name) then
			v = true
		else
			v = keptAncestor(node.Parent)
		end
		protCache[node] = v
		return v
	end

	local function kept(p)
		-- Terrain and spawns are load-bearing in the most literal sense
		if p:IsA("Terrain") or p:IsA("SpawnLocation") then return true end
		return keptAncestor(p)
	end

	----------------------------------------------------------------
	-- one part
	----------------------------------------------------------------
	local function take(p)
		local s = snap[p]
		if s then return s end
		s = { t = p.Transparency, m = p.Material, c = p.CastShadow, r = p.Reflectance }
		if p:IsA("MeshPart") then s.f = p.RenderFidelity end
		snap[p]  = s
		touched  = true
		return s
	end

	-- Writes the value each field SHOULD have for the switches as they stand right
	-- now. That is the whole trick: there is no separate "undo" path to keep in step
	-- with the apply path, so a switch going off restores exactly the fields it owns
	-- and leaves the others alone. Idempotent, and no visible flash when a second
	-- switch is added to a strip that is already running.
	local function reconcile(p, s)
		p.Transparency = ON.geo and 1 or s.t
		p.CastShadow   = ON.geo and false or s.c
		p.Material     = ON.tex and Enum.Material.SmoothPlastic or s.m
		p.Reflectance  = ON.tex and 0 or s.r
		if s.f ~= nil then
			p.RenderFidelity = ON.tex and Enum.RenderFidelity.Performance or s.f
		end
	end

	local function visitPart(p)
		if kept(p) then return end
		local s = snap[p]
		if ON.geo and not p.CanCollide then
			-- the safe half of "destroy buildings and walls": decoration only
			p:Destroy()
			return
		end
		if s == nil then
			-- never touched and nothing wants it touched: do not even snapshot it,
			-- or turning everything off would record the entire map for no reason
			if not (ON.geo or ON.tex) then return end
			s = take(p)
		end
		reconcile(p, s)
	end

	local FX = {
		ParticleEmitter = true, Trail = true, Beam = true, Smoke = true,
		Fire = true, Sparkles = true,
		PointLight = true, SpotLight = true, SurfaceLight = true,
	}

	local function visitOther(d)
		local cls = d.ClassName
		if FX[cls] then
			if fxSnap[d] == nil then
				if not ON.fx then return end
				fxSnap[d] = d.Enabled
				touched   = true
			end
			d.Enabled = not ON.fx and fxSnap[d] or false
		elseif cls == "Decal" or cls == "Texture" then
			if decSnap[d] == nil then
				if not ON.tex then return end
				decSnap[d] = d.Transparency
				touched    = true
			end
			d.Transparency = ON.tex and 1 or decSnap[d]
		end
	end

	----------------------------------------------------------------
	-- lighting and water: small, fixed, and instant
	----------------------------------------------------------------
	local lightSnap, waterSnap = nil, nil

	local function doLighting()
		if ON.light and not lightSnap then
			lightSnap = {
				gs  = Lighting.GlobalShadows,
				br  = Lighting.Brightness,
				fe  = Lighting.FogEnd,
				ed  = Lighting.EnvironmentDiffuseScale,
				es  = Lighting.EnvironmentSpecularScale,
				tech = Lighting.Technology,
				post = {},
				atmo = {},
			}
			for _, e in ipairs(Lighting:GetDescendants()) do
				if e:IsA("PostEffect") then
					lightSnap.post[e] = e.Enabled
				elseif e:IsA("Atmosphere") then
					lightSnap.atmo[e] = { d = e.Density, h = e.Haze, g = e.Glare }
				end
			end
		end
		if not lightSnap then return end
		local s = lightSnap
		Lighting.GlobalShadows            = not ON.light and s.gs or false
		Lighting.Brightness               = ON.light and 2 or s.br
		Lighting.FogEnd                   = ON.light and 1e6 or s.fe
		Lighting.EnvironmentDiffuseScale  = ON.light and 0 or s.ed
		Lighting.EnvironmentSpecularScale = ON.light and 0 or s.es
		-- Technology is the single biggest lever on a phone (Future and ShadowMap both
		-- do per-pixel lighting work that Voxel does not) and it is also the one most
		-- likely to be locked at runtime, hence the pcall rather than a guess.
		pcall(function()
			Lighting.Technology = ON.light and Enum.Technology.Compatibility or s.tech
		end)
		for e, was in pairs(s.post) do
			if e.Parent then e.Enabled = not ON.light and was or false end
		end
		for e, was in pairs(s.atmo) do
			if e.Parent then
				e.Density = ON.light and 0 or was.d
				e.Haze    = ON.light and 0 or was.h
				e.Glare   = ON.light and 0 or was.g
			end
		end
		if ON.light then touched = true end
	end

	local function doWater()
		local t = WS.Terrain
		if not t then return end
		if ON.water and not waterSnap then
			waterSnap = {
				ws = t.WaterWaveSize, sp = t.WaterWaveSpeed,
				rf = t.WaterReflectance, tr = t.WaterTransparency,
			}
		end
		if not waterSnap then return end
		local s = waterSnap
		t.WaterWaveSize    = ON.water and 0 or s.ws
		t.WaterWaveSpeed   = ON.water and 0 or s.sp
		t.WaterReflectance = ON.water and 0 or s.rf
		t.WaterTransparency = ON.water and 0 or s.tr
		if ON.water then touched = true end
	end

	----------------------------------------------------------------
	-- the paced sweep
	----------------------------------------------------------------
	local function anyOn()
		return ON.geo or ON.light or ON.tex or ON.fx or ON.water
	end

	local function sweep(ignoreAlive)
		local list = WS:GetDescendants()
		local n = 0
		for i = 1, #list do
			if not (alive or ignoreAlive) then return end
			local d = list[i]
			-- A stale entry from this snapshot is a harmless wasted write, not a chase:
			-- unlike the coin pool's ghost bug, nothing here moves the character toward
			-- the instance, so `.Parent ~= nil` is a good enough cheap filter and does
			-- not need to be a real liveness test.
			if d.Parent ~= nil then
				if d:IsA("BasePart") then
					pcall(visitPart, d)
				else
					pcall(visitOther, d)
				end
			end
			n = n + 1
			if n >= BUDGET then
				n = 0
				RunService.Heartbeat:Wait()
			end
		end
	end

	-- Restoring walks what we TOUCHED, not the Workspace: after a round change most of
	-- the snapshot is dead and most of the Workspace was never ours. The keys are
	-- copied into a strong array in one non-yielding pass FIRST -- iterating a weak
	-- table across a yield lets the collector take a key mid-walk, which throws
	-- "invalid key to 'next'". That bug cost a whole afternoon in the other hub.
	local function restoreTouched(ignoreAlive)
		local parts, fx, dec = {}, {}, {}
		for p in pairs(snap)    do parts[#parts + 1] = p end
		for e in pairs(fxSnap)  do fx[#fx + 1]       = e end
		for d in pairs(decSnap) do dec[#dec + 1]     = d end

		local n = 0
		local function tick()
			n = n + 1
			if n >= BUDGET then n = 0; RunService.Heartbeat:Wait() end
		end
		for _, p in ipairs(parts) do
			if not (alive or ignoreAlive) then return end
			if p.Parent then pcall(reconcile, p, snap[p]) end
			tick()
		end
		for _, e in ipairs(fx) do
			if e.Parent then pcall(function() e.Enabled = fxSnap[e] end) end
			tick()
		end
		for _, d in ipairs(dec) do
			if d.Parent then pcall(function() d.Transparency = decSnap[d] end) end
			tick()
		end
	end

	local function run()
		doLighting()
		doWater()
		if anyOn() then
			sweep(false)
		elseif touched then
			restoreTouched(false)
			-- swapped for fresh tables rather than cleared: table.clear on a weak table
			-- that the collector is working through is the other way to earn "invalid
			-- key to 'next'". Dropping the reference lets the whole thing go at once.
			snap    = setmetatable({}, { __mode = "k" })
			fxSnap  = setmetatable({}, { __mode = "k" })
			decSnap = setmetatable({}, { __mode = "k" })
			lightSnap, waterSnap = nil, nil
			touched = false
		end
	end

	-- Coalescing gate. The one toggle sets all five flags in a single statement and
	-- asks for one pass, so this no longer has to absorb a burst from the UI -- but it
	-- still does for the two drivers below: a round change and the catch-up timer can
	-- both land while a sweep is mid-yield, and `again` turns that into one more pass
	-- instead of two sweeps fighting over the same 9000 parts.
	local function schedule()
		if working then again = true; return end
		working = true
		task.spawn(function()
			repeat
				again = false
				local ok, err = pcall(run)
				if not ok then warn("[Arjhay Hub] perf: " .. tostring(err)) end
			until not again or not alive
			working = false
		end)
	end

	----------------------------------------------------------------
	-- ui
	----------------------------------------------------------------
	-- ONE switch, by request: "delete the What Gets Stripped just combine it to FPS
	-- Boost toggle". The five scopes still exist in the engine above -- they are how
	-- reconcile() knows which fields it owns, and dropping them would mean five
	-- hard-coded apply paths and five hard-coded undo paths -- but they are no longer
	-- five rows the user has to reason about.
	--
	-- Setting all five in ONE statement is strictly better than the five `api:Set(v)`
	-- calls this replaced, not just fewer rows: those arrived as five separate
	-- task.spawn callbacks, so the first sweep could start against a half-set ON table
	-- and only the `again` pass saw the truth. A single assignment cannot be observed
	-- half-done, so the first pass is already the correct one.
	local boostSec = Perf:Section("FPS Boost")
	boostSec.card.LayoutOrder = 1

	-- Only two Cfg keys are left here, of different kinds, so the alphabetical
	-- same-rank tiebreak no longer decides anything. A config saved by the previous
	-- build still carries five `perf.scope.*` keys: Cfg.apply walks Cfg.rows and looks
	-- values up by key, so a saved key with no row is simply never read. Nothing to
	-- migrate, and nothing that will fight this toggle on load.
	Cfg.add("perf.boost", "toggle",
	boostSec:Toggle("FPS Boost", false, function(v)
		ON.geo, ON.light, ON.tex, ON.fx, ON.water = v, v, v, v, v
		schedule()
	end))

	boostSec:Label("Walls and buildings stop being drawn and their decoration is"
		.. " deleted, lighting goes flat, textures and particles stop. Collision is"
		.. " never touched, so you cannot fall through a floor that stopped being"
		.. " drawn -- and coins, players and held weapons are skipped, so the rest of"
		.. " the hub keeps working.")

	local rateSec = Perf:Section("Frame Rate")
	rateSec.card.LayoutOrder = 2

	Cfg.add("perf.fpscap", "slider",
	rateSec:Slider("FPS Cap (0 = unlimited)", 0, 360, 0, function(v)
		fpsCap = math.floor(v)
		-- 0 is asked for as "unlimited", but a literal setfpscap(0) means different
		-- things in different executors and in some of them it means "stop drawing",
		-- so unlimited is sent as a number no device will reach instead of as 0.
		if type(setfpscap) == "function" then
			pcall(setfpscap, fpsCap > 0 and fpsCap or 9999)
		end
	end))

	rateSec:Label("Only does anything if your executor supports it -- if yours does"
		.. " not, this slider is ignored and nothing breaks. Capping LOWER is worth"
		.. " trying on a phone that throttles when it gets hot: a steady 45 beats 60"
		.. " that collapses to 20.")

	----------------------------------------------------------------
	-- drivers
	----------------------------------------------------------------
	-- A new round means a whole new map, and it arrives as one ChildAdded on Workspace
	-- followed by the map filling itself in over the next second or two. So this is a
	-- nudge, not the mechanism -- the catch-up pass below is what actually finishes
	-- the job on a map that was still loading when the first sweep ran.
	Bin.conn(WS.ChildAdded:Connect(function()
		if anyOn() then schedule() end
	end))

	task.spawn(function()
		while alive do
			task.wait(RESWEEP)
			if alive and anyOn() then schedule() end
		end
	end)

	-- while-loops cannot be reached by Bin.flush(), so the flag they spin on has to be
	-- cleared by hand -- the same bug class as the shells loop and the device picker.
	-- The restore is spawned rather than run inline because Bin.flush() is what makes
	-- the close button feel instant: a synchronous walk of 9000 parts inside an
	-- onUnload handler is a visible freeze at exactly the moment the user asked for
	-- the hub to go away. It ignores `alive` on purpose, since it is the thing that
	-- has to outlive it, and it is a finite job that ends on its own.
	Bin.onUnload(function()
		alive = false
		if not touched then return end
		for k in pairs(ON) do ON[k] = false end
		task.spawn(function()
			pcall(doLighting)
			pcall(doWater)
			pcall(restoreTouched, true)
		end)
	end)
end)()

--==============================================================
-- ESP TAB
--==============================================================
-- WHERE THE ROLE COMES FROM
--
-- The 240 second role dump, run through one whole round, settled this. Four things
-- that look like they have to carry a role, and do not:
--   · attributes    — EquippedKnife / EquippedGun are the COSMETIC loadout. Every
--                     player carries both, all round, alive or dead: smiddy09091995
--                     read EquippedKnife=Boneblade while holding nothing at all.
--   · Value objects — DisplayRefKnife and DisplayRefGun sit on EVERY character,
--                     eight of them across four players, so they separate nobody.
--   · Teams         — "Teams service holds: no teams at all".
--   · leaderstats   — no fields on anyone.
-- The server->client remotes that DO name a role only ever talk about ME:
-- RoleSelect("Sheriff", nil, nil, false, "Classic") and GiveWeapon("Gun"). Nothing
-- this client is sent says who anybody else is.
--
-- That leaves the TOOL, and two findings sitting inside the dump's own player table
-- turn it from a last resort into a real signal:
--   1. Player.Backpack REPLICATES in this game. The dump went in expecting the
--      opposite -- its own note reads "Backpack normally does NOT replicate" -- and
--      then printed  smiddy09091995 backpack: visible: Toys,Knife  while that
--      player's hands were empty and tool= was "-". So the murderer is knowable the
--      moment the round STARTS, not the moment they first swing.
--   2. The Tool NAME is the role, never the skin. That same knife Tool is called
--      "Knife" whether the attribute says Boneblade, HeartWand or nothing.
--
-- Sheriff vs Hero falls out of ORDER rather than out of any field: whoever holds the
-- Gun first in a round is the sheriff, and anyone holding it after them picked it up
-- off the sheriff's body. Loading the hub halfway through a round whose sheriff is
-- already dead is the one case that mislabels, and there is no field to check it
-- against, so it is left alone rather than guessed at.
--==============================================================
-- WHY THIS IS A FUNCTION AND NOT A do BLOCK
--
-- The first build of this used `do ... end` and died on load with
--   Out of local registers when trying to allocate gunPool: exceeded limit 200
-- A `do` block opens a new SCOPE but not a new register FRAME: its locals stack on
-- top of whatever the main chunk is already holding. The top level of this file
-- holds 159 locals for the whole run, so a do block here only ever had 41 registers
-- to spend and this tab needs about 55 -- gunPool was simply the 201st name.
--
-- A function body is its own frame, so this gets a fresh 200. Upvalues (new, Bin,
-- Cfg, livePool, ...) are counted separately against a 255 limit, so reaching out
-- of here costs nothing. It is anonymous and self-calling so it adds ZERO top-level
-- locals -- naming it would spend one of the 41 that are left.
--
-- The leading semicolon is load-bearing: the statement above ends in `)`, and
-- `comingSoon(...)` followed by `(function() ... end)()` on the next line parses as
-- calling comingSoon's RESULT. Do not delete it.
--==============================================================
;(function()
	local ESP = addTab("ESP")

	----------------------------------------------------------------
	-- drawing surface
	----------------------------------------------------------------
	-- A Folder NEXT TO the window's ScreenGui, never inside it. Auto Claim Shells
	-- disables that ScreenGui for a frame at a time to land a synthetic click, and
	-- ESP that blinks off every time the shell loop fires reads as broken. wipeOld()
	-- at the top of this file already destroys "ArjhayHubESP" by name, so a run that
	-- dies without unloading cannot leave highlights on screen forever either.
	local bag = new("Folder", { Name = "ArjhayHubESP", Parent = screen.Parent })

	-- Tracers are 2D, so they need a LayerCollector of their own, and IgnoreGuiInset
	-- stays FALSE on purpose: WorldToViewportPoint hands back points measured from
	-- BELOW Roblox's top bar, while a ScreenGui that ignores the inset measures from
	-- above it. Mixing the two puts every line 36px out -- the same inset trap the
	-- shell clicker had to solve, just from the other side.
	local lines = new("ScreenGui", {
		Name = "Lines", Parent = bag, ResetOnSpawn = false, IgnoreGuiInset = false,
		DisplayOrder = 9998, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	-- new() does not pcall, so an unknown class would kill this whole block on the
	-- way in. Ask once; without Highlight the tags and tracers still work alone.
	local canHL = pcall(function() Instance.new("Highlight"):Destroy() end)

	----------------------------------------------------------------
	-- roles
	----------------------------------------------------------------
	local ROLE_COL = {
		Murderer = Color3.fromRGB(235, 45, 55),
		Sheriff  = Color3.fromRGB(60, 140, 255),
		Hero     = Color3.fromRGB(255, 185, 60),
		Innocent = Color3.fromRGB(70, 215, 120),
		Unknown  = Color3.fromRGB(150, 150, 160),
	}
	local ROLE_OPTS   = { "Murderer", "Sheriff", "Hero", "Innocent", "Unknown" }
	local DETAIL_OPTS = { "Name", "Role", "Distance", "Health" }

	-- Tool names. Toys is the emote tool that everybody carries, so it is not here.
	local WEAPON_ROLE = { Knife = "Murderer", Gun = "Sheriff" }

	-- Both containers, because a Tool sits in the Backpack until it is equipped and
	-- in the Character after. Iterating beats FindFirstChildOfClass("Tool"): a
	-- murderer with the Toys out would answer "Toys" to that question and read as an
	-- innocent for as long as they kept it out.
	local function weaponOf(plr)
		local char = plr.Character
		if char then
			for _, t in ipairs(char:GetChildren()) do
				if WEAPON_ROLE[t.Name] and t:IsA("Tool") then return t.Name end
			end
		end
		local bp = plr:FindFirstChild("Backpack")
		if bp then
			for _, t in ipairs(bp:GetChildren()) do
				if WEAPON_ROLE[t.Name] and t:IsA("Tool") then return t.Name end
			end
		end
		return nil
	end

	----------------------------------------------------------------
	-- round state
	----------------------------------------------------------------
	-- Two independent sources, deliberately.
	--   · the remotes are the precise answer, and the dump caught VictoryScreen and
	--     RoundEndFade genuinely arriving
	--   · but the hub is normally injected MID-round, and then no RoundStart ever
	--     fires. So "somebody is holding a knife" stands as a backstop: it cannot be
	--     true between rounds and it is true for every second of one.
	-- Without the backstop a mid-round load would call the entire lobby Unknown, and
	-- the user would quite reasonably read that as the feature being broken.
	local roundFlag = false
	local gunFirst  = nil            -- Player who held the Gun first this round

	local ROUND_ON  = { RoundStart = true, CoinsStarted = true }
	local ROUND_OFF = { VictoryScreen = true, GameOver = true, RoundEndFade = true }

	-- Looked up by NAME rather than by a hard-coded folder path. The dump found its
	-- remotes by walking four different roots and printed full paths, so writing
	-- ReplicatedStorage.Remotes.Gameplay.X here would be me guessing at which folder
	-- it was -- and a path that is one folder off fails SILENTLY: the knife backstop
	-- below would quietly cover for it and the round flag would simply never update.
	do
		local found, hits = {}, 0

		local function sweep(root)
			if not root then return end
			pcall(function()
				for _, d in ipairs(root:GetDescendants()) do
					if (ROUND_ON[d.Name] or ROUND_OFF[d.Name])
						and found[d.Name] == nil and d:IsA("RemoteEvent") then
						found[d.Name], hits = d, hits + 1
					end
				end
			end)
		end

		sweep(ReplicatedStorage)
		pcall(function() sweep(game:GetService("ReplicatedFirst")) end)
		-- workspace only as a last resort: that walk is tens of thousands of instances
		-- and there is no reason to pay for it if the events are where they should be.
		if hits == 0 then sweep(workspace) end

		-- OnClientEvent takes any number of listeners, so this cannot disturb the
		-- game's own handlers, and it only ever listens -- nothing in this whole tab
		-- fires anything at the server.
		for name, r in pairs(found) do
			local want = ROUND_ON[name] and true or false
			Bin.conn(r.OnClientEvent:Connect(function()
				roundFlag = want
				if want then gunFirst = nil end
			end))
		end
	end

	-- One walk per pass: every player's weapon, plus whether a knife exists at all,
	-- which is the round-live backstop above.
	local function scanWeapons()
		local map, knifeOut = {}, false
		for _, plr in ipairs(Players:GetPlayers()) do
			local w = weaponOf(plr)
			if w then
				map[plr] = w
				if w == "Knife" then knifeOut = true end
			end
		end
		return map, knifeOut
	end

	local function roleOf(plr, weapon, live)
		if weapon == "Knife" then return "Murderer" end
		if weapon == "Gun" then
			-- There is only ever one gun, so the first holder of the round is the
			-- sheriff and anyone holding it later took it off the sheriff's body.
			-- If that sheriff has since left the server the reference is dropped and
			-- the current holder inherits the label -- wrong in principle, but a
			-- stale Player reference held for the rest of the round is worse.
			if gunFirst == nil or gunFirst.Parent ~= Players then gunFirst = plr end
			return (gunFirst == plr) and "Sheriff" or "Hero"
		end
		return live and "Innocent" or "Unknown"
	end

	----------------------------------------------------------------
	-- state the controls write and the passes read
	----------------------------------------------------------------
	local on        = false
	local showSelf  = false
	local maxDist   = 0              -- 0 means no limit
	local useHL     = true
	local fillPct   = 55
	local thruWalls = true
	local useTags   = true
	local useTracer = false
	local coinsOn   = false
	local gunOn     = false

	-- These two alias the dropdowns' own selection tables. api:Set builds a NEW table
	-- and then re-fires the callback, so the alias is refreshed on every change and on
	-- config load -- the same pattern the Farm tab's Target dropdown uses. They must
	-- start out matching the dropdown defaults exactly, because construction refreshes
	-- silently and the callback does not run until something is actually tapped.
	local showRoles = {
		Murderer = true, Sheriff = true, Hero = true, Innocent = true, Unknown = true,
	}
	local detail = { Name = true, Role = true, Distance = true }

	----------------------------------------------------------------
	-- drawables
	----------------------------------------------------------------
	-- One entry per player, built when their character appears and destroyed when it
	-- goes. The range and role filters only flip Enabled: tearing a Highlight down and
	-- rebuilding it every time somebody steps over the distance line would churn
	-- instances several times a second and flicker on the boundary.
	local drawn    = {}             -- Player   -> entry
	local coinDots = {}             -- Instance -> BillboardGui
	local gunMarks = {}             -- Instance -> { tag, hl }

	local function makeEntry()
		local e = {}
		if canHL then
			e.hl = new("Highlight", {
				Parent = bag, Enabled = false,
				FillTransparency = 0.45, OutlineTransparency = 0,
			})
		end
		-- MaxDistance is set explicitly rather than left to the default. A tag that
		-- quietly fades out past some distance is the single most confusing thing an
		-- ESP can do -- it looks exactly like the role detection having failed.
		e.tag = new("BillboardGui", {
			Parent = bag, Enabled = false, AlwaysOnTop = true, LightInfluence = 0,
			MaxDistance = math.huge,
			Size = UDim2.fromOffset(240, 44), StudsOffset = Vector3.new(0, 2.4, 0),
		})
		e.txt = new("TextLabel", {
			Parent = e.tag, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
			Font = FONT_B, Text = "", TextSize = 13, TextColor3 = T.Text,
			TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.4,
		})
		e.line = new("Frame", {
			Parent = lines, Visible = false, BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(2, 0),
			BackgroundColor3 = T.Accent, BackgroundTransparency = 0.25,
		})
		return e
	end

	-- e.txt is a child of e.tag, so destroying the tag takes the label with it.
	local function killEntry(plr)
		local e = drawn[plr]
		if not e then return end
		drawn[plr] = nil
		for _, k in ipairs({ "hl", "tag", "line" }) do
			local inst = e[k]
			if inst then pcall(function() inst:Destroy() end) end
		end
	end

	-- A dot, not a Highlight. Roblox stops rendering past roughly 31 Highlights in a
	-- scene, and a busy MM2 map carries far more coins than that -- highlighting coins
	-- would silently blank the PLAYERS along with them.
	local function makeDot(col, px)
		local g = new("BillboardGui", {
			Parent = bag, Enabled = false, AlwaysOnTop = true, LightInfluence = 0,
			MaxDistance = math.huge, Size = UDim2.fromOffset(px, px),
		})
		local d = new("Frame", {
			Parent = g, BorderSizePixel = 0, BackgroundColor3 = col,
			Size = UDim2.fromScale(1, 1),
		})
		corner(d, math.floor(px / 2))
		stroke(d, Color3.new(0, 0, 0), 1)
		return g
	end

	-- ASCII only. A glyph the device's font happens to lack draws as an empty box,
	-- which is why every icon in this hub is a Frame; a name tag is the one place text
	-- is unavoidable, so it stays inside the safe range.
	local function tagText(plr, role, dist, hum)
		local top, bits = (detail.Name and plr.Name or ""), {}
		if detail.Role then bits[#bits + 1] = role end
		if detail.Distance and dist then
			bits[#bits + 1] = string.format("%d studs", math.floor(dist + 0.5))
		end
		if detail.Health and hum then
			bits[#bits + 1] = string.format("%d hp", math.floor(hum.Health + 0.5))
		end
		local low = table.concat(bits, "  |  ")
		if top == "" then return low end
		if low == "" then return top end
		return top .. "\n" .. low
	end

	----------------------------------------------------------------
	-- teardown helpers
	----------------------------------------------------------------
	-- Every one of these SWAPS the table for a fresh one and walks the old copy,
	-- rather than clearing keys while iterating. Same reason as the plant bookkeeping
	-- in the other hub: it is the one shape that cannot raise "invalid key to next".
	local function dropPlayers()
		if next(drawn) == nil then return end
		local old = drawn
		drawn = {}
		for _, e in pairs(old) do
			for _, k in ipairs({ "hl", "tag", "line" }) do
				local inst = e[k]
				if inst then pcall(function() inst:Destroy() end) end
			end
		end
	end

	local function dropCoins()
		if next(coinDots) == nil then return end
		local old = coinDots
		coinDots = {}
		for _, g in pairs(old) do pcall(function() g:Destroy() end) end
	end

	local function dropGuns()
		if next(gunMarks) == nil then return end
		local old = gunMarks
		gunMarks = {}
		for _, m in pairs(old) do
			for _, k in ipairs({ "tag", "hl" }) do
				local inst = m[k]
				if inst then pcall(function() inst:Destroy() end) end
			end
		end
	end

	----------------------------------------------------------------
	-- the player pass
	----------------------------------------------------------------
	local function playerPass(origin)
		local weapons, knifeOut = scanWeapons()
		local live = roundFlag or knifeOut
		local seen = {}

		for _, plr in ipairs(Players:GetPlayers()) do
			local char = plr.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			-- IsDescendantOf(workspace), not .Parent ~= nil: a character sitting
			-- inside a model the game has already destroyed still answers .Parent and
			-- still reports a Position. Treating that as alive is exactly what had the
			-- coin collector chasing ghosts across a dead map.
			local ok = char ~= nil and hrp ~= nil and char:IsDescendantOf(workspace)
				and sanePos(hrp.Position) and (hum == nil or hum.Health > 0)

			if ok and (showSelf or plr ~= LocalPlayer) then
				seen[plr] = true
				local e = drawn[plr]
				if not e then
					e = makeEntry()
					drawn[plr] = e
				end

				local role = roleOf(plr, weapons[plr], live)
				local col  = ROLE_COL[role] or ROLE_COL.Unknown
				local dist = origin and (hrp.Position - origin).Magnitude or nil
				local show = (showRoles[role] == true)
					and ((maxDist <= 0) or dist == nil or dist <= maxDist)

				e.part, e.on = hrp, show

				if e.hl then
					local hlOn = show and useHL
					e.hl.Enabled = hlOn
					e.hl.Adornee = hlOn and char or nil
					if hlOn then
						e.hl.FillColor        = col
						e.hl.OutlineColor     = col
						e.hl.FillTransparency = 1 - (fillPct / 100)
						e.hl.DepthMode        = thruWalls
							and Enum.HighlightDepthMode.AlwaysOnTop
							or Enum.HighlightDepthMode.Occluded
					end
				end

				local tagOn = show and useTags
				e.tag.Enabled = tagOn
				e.tag.Adornee = tagOn and (char:FindFirstChild("Head") or hrp) or nil
				if tagOn then
					e.txt.Text       = tagText(plr, role, dist, hum)
					e.txt.TextColor3 = col
				end

				e.line.BackgroundColor3 = col
				if not (show and useTracer) then e.line.Visible = false end
			end
		end

		-- A player who left, died or respawned stops having drawables at all. The
		-- filters above only ever flip Enabled, so this list is the only thing in the
		-- pass that destroys anything.
		local gone
		for plr in pairs(drawn) do
			if not seen[plr] then
				gone = gone or {}
				gone[#gone + 1] = plr
			end
		end
		if gone then
			for _, plr in ipairs(gone) do killEntry(plr) end
		end
	end

	----------------------------------------------------------------
	-- the coin pass
	----------------------------------------------------------------
	local COIN_CAP = 90

	local function coinPass(origin)
		local seen, n = {}, 0
		-- livePool() is the collector's own pool: cached for a tenth of a second,
		-- already immune to the destroyed-map ghost coins, and it follows the Farm
		-- tab's Target dropdown. So the ESP marks exactly what Auto Collect Coins
		-- would go for, which is the useful answer rather than a second opinion.
		for _, inst in ipairs(livePool(false)) do
			if n >= COIN_CAP then break end
			local part = alive(inst) and partOf(inst) or nil
			if part and sanePos(part.Position) then
				local d = origin and (part.Position - origin).Magnitude or nil
				if (maxDist <= 0) or d == nil or d <= maxDist then
					n = n + 1
					seen[inst] = true
					local g = coinDots[inst]
					if not g then
						g = makeDot(Color3.fromRGB(255, 205, 60), 10)
						coinDots[inst] = g
					end
					g.Adornee = part
					g.Enabled = true
				end
			end
		end
		-- Strong keys, not weak ones: a weak key would let a collected coin take its
		-- table row away while the BillboardGui was still parented to the Folder, and
		-- then nothing on this side would ever hold a reference to destroy. A coin
		-- that leaves the pool is unmarked here instead, one pass later at most.
		local gone
		for inst in pairs(coinDots) do
			if not seen[inst] then
				gone = gone or {}
				gone[#gone + 1] = inst
			end
		end
		if gone then
			for _, inst in ipairs(gone) do
				local g = coinDots[inst]
				coinDots[inst] = nil
				if g then pcall(function() g:Destroy() end) end
			end
		end
	end

	----------------------------------------------------------------
	-- the dropped-gun pass
	----------------------------------------------------------------
	-- The dropped gun is the one thing in this tab the dump does NOT confirm: the
	-- round it watched ended on the clock, so the sheriff never died and nothing was
	-- ever dropped. This is a name scan rather than a known path, throttled like the
	-- coin container walk, and a wrong guess costs a marker that never appears --
	-- never a misfire, because nothing in here touches or fires anything.
	local GUN_NAMES = { Gun = true, GunDrop = true, DroppedGun = true, GunPickup = true }
	local gunPool, gunStamp = {}, -1e9

	local function heldBySomebody(inst)
		for _, plr in ipairs(Players:GetPlayers()) do
			local c = plr.Character
			if c and inst:IsDescendantOf(c) then return true end
		end
		return false
	end

	local function rebuildGuns()
		local out = {}
		for _, inst in ipairs(workspace:GetDescendants()) do
			if GUN_NAMES[baseName(inst.Name)]
				and (inst:IsA("Tool") or inst:IsA("Model") or inst:IsA("BasePart"))
				and not heldBySomebody(inst) then
				out[#out + 1] = inst
			end
		end
		gunPool, gunStamp = out, os.clock()
	end

	local function gunPass(origin)
		-- Only ever while the toggle is on: this is a full workspace descendant walk
		-- and there is no reason to pay for it otherwise.
		if (os.clock() - gunStamp) > 4 then rebuildGuns() end
		local seen = {}
		for _, inst in ipairs(gunPool) do
			local part = alive(inst) and partOf(inst) or nil
			if part and sanePos(part.Position) and not heldBySomebody(inst) then
				local d = origin and (part.Position - origin).Magnitude or nil
				if (maxDist <= 0) or d == nil or d <= maxDist then
					seen[inst] = true
					local m = gunMarks[inst]
					if not m then
						m = { tag = makeDot(ROLE_COL.Sheriff, 14) }
						if canHL then
							m.hl = new("Highlight", {
								Parent = bag, Enabled = true,
								FillColor        = ROLE_COL.Sheriff,
								OutlineColor     = ROLE_COL.Sheriff,
								FillTransparency = 0.4, OutlineTransparency = 0,
								DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
							})
						end
						gunMarks[inst] = m
					end
					m.tag.Adornee = part
					m.tag.Enabled = true
					if m.hl then
						m.hl.Adornee = inst:IsA("Model") and inst or part
					end
				end
			end
		end
		local gone
		for inst in pairs(gunMarks) do
			if not seen[inst] then
				gone = gone or {}
				gone[#gone + 1] = inst
			end
		end
		if gone then
			for _, inst in ipairs(gone) do
				local m = gunMarks[inst]
				gunMarks[inst] = nil
				if m then
					for _, k in ipairs({ "tag", "hl" }) do
						if m[k] then pcall(function() m[k]:Destroy() end) end
					end
				end
			end
		end
	end

	----------------------------------------------------------------
	-- tracers
	----------------------------------------------------------------
	-- Geometry every frame, because a line that lags the camera by 150ms looks worse
	-- than no line at all. Everything expensive happens on the slow pass instead.
	local function linePass(cam)
		if not cam then return end
		local vp     = cam.ViewportSize
		local ox, oy = vp.X * 0.5, vp.Y
		for _, e in pairs(drawn) do
			local part = e.part
			if useTracer and e.on and part and part.Parent then
				local sp = cam:WorldToViewportPoint(part.Position)
				-- The Z of that result, not the visible-on-screen flag it also returns:
				-- Z is depth in front of the camera, and a tracer to somebody who is
				-- OFF screen is the whole point of drawing one. Using the flag would
				-- hide every line the moment the target left the frame, which is the
				-- exact moment it becomes useful. Behind the camera (Z <= 0) still has
				-- to go, because the projection flips there and the line would confidently
				-- point the wrong way.
				if sp.Z > 0 then
					local dx, dy = sp.X - ox, sp.Y - oy
					local len    = math.sqrt(dx * dx + dy * dy)
					e.line.Size     = UDim2.fromOffset(2, len)
					e.line.Position = UDim2.fromOffset(ox + dx * 0.5, oy + dy * 0.5)
					-- a Frame's long axis runs down the screen, so take off the
					-- quarter turn that atan2 does not know about
					e.line.Rotation = math.deg(math.atan2(dy, dx)) - 90
					e.line.Visible  = true
				else
					e.line.Visible = false
				end
			elseif e.line.Visible then
				e.line.Visible = false
			end
		end
	end

	----------------------------------------------------------------
	-- the driver
	----------------------------------------------------------------
	local REFRESH = 0.15
	local acc, drive = 0, nil

	local function step(dt)
		local cam = workspace.CurrentCamera
		acc = acc + dt
		if acc >= REFRESH then
			acc = 0
			local hrp = myRoot()
			-- A dead spectator has no root part, and the camera is then the honest
			-- origin for "how far is that" -- it is where the user is looking from.
			local origin = (hrp and hrp.Position) or (cam and cam.CFrame.Position) or nil
			if origin and not sanePos(origin) then origin = nil end

			playerPass(origin)
			if coinsOn then coinPass(origin) else dropCoins() end
			if gunOn then gunPass(origin) else dropGuns() end
		end
		linePass(cam)
	end

	-- The driver is one RenderStepped connection and it is deliberately NOT handed to
	-- Bin.conn: that list only ever grows, so a toggle flicked twenty times would
	-- leave twenty dead connections sitting in it. It lives in a local with its own
	-- onUnload, the same shape the coin driver uses.
	local function setEsp(v)
		on = v and true or false
		if on then
			if not drive then
				acc = REFRESH        -- draw on the very next frame, not in 150ms
				drive = RunService.RenderStepped:Connect(step)
			end
		else
			if drive then
				pcall(function() drive:Disconnect() end)
				drive = nil
			end
			dropPlayers()
			dropCoins()
			dropGuns()
		end
	end

	Bin.conn(Players.PlayerRemoving:Connect(function(plr)
		killEntry(plr)
		if gunFirst == plr then gunFirst = nil end
	end))

	Bin.onUnload(function()
		on = false
		if drive then
			pcall(function() drive:Disconnect() end)
			drive = nil
		end
		-- Destroying the Folder takes every Highlight, tag, dot and tracer with it in
		-- one go. The tables still have to be emptied by hand: the RenderStepped
		-- closure above holds all three, and the control callbacks that hold it are
		-- reachable from Cfg, which is handed out through getgenv() and outlives the
		-- close button. A table left full of destroyed Instances pins them for the
		-- rest of the session.
		dropPlayers()
		dropCoins()
		dropGuns()
		gunPool, gunFirst = {}, nil
		pcall(function() bag:Destroy() end)
	end)

	----------------------------------------------------------------
	-- Player ESP
	----------------------------------------------------------------
	local main = ESP:Section("Player ESP")
	main.card.LayoutOrder = 1

	main:Label("Roles come from the Knife and Gun tools, because MM2 sends nobody"
		.. " else's role to your client. The backpack replicates, so the murderer"
		.. " shows up when the round starts rather than when they first swing.")

	main:Label("Between rounds nobody is carrying a weapon, so everyone reads"
		.. " Unknown. Untick that role to only draw once a round is running.")

	Cfg.add("esp.players.enabled", "toggle",
	main:Toggle("Player ESP", false, function(v) setEsp(v) end))

	Cfg.add("esp.players.roles", "dropdown",
	main:Dropdown("Show Roles", ROLE_OPTS, ROLE_OPTS, function(set)
		showRoles = set
	end))

	Cfg.add("esp.players.self", "toggle",
	main:Toggle("Include Yourself", false, function(v) showSelf = v end))

	Cfg.add("esp.players.range", "slider",
	main:Slider("Max Distance (0 = no limit)", 0, 2000, 0, function(v)
		maxDist = v
	end))

	----------------------------------------------------------------
	-- ESP Style
	----------------------------------------------------------------
	local style = ESP:Section("ESP Style")
	style.card.LayoutOrder = 2

	if not canHL then
		style:Label("This client has no Highlight class, so the character glow is"
			.. " unavailable here. Name tags and tracers still work.")
	end

	Cfg.add("esp.style.highlight", "toggle",
	style:Toggle("Highlight Characters", true, function(v) useHL = v end))

	Cfg.add("esp.style.fill", "slider",
	style:Slider("Highlight Fill", 0, 100, 55, function(v) fillPct = v end))

	Cfg.add("esp.style.walls", "toggle",
	style:Toggle("Draw Through Walls", true, function(v) thruWalls = v end))

	Cfg.add("esp.style.tags", "toggle",
	style:Toggle("Name Tags", true, function(v) useTags = v end))

	Cfg.add("esp.style.detail", "dropdown",
	style:Dropdown("Tag Shows", DETAIL_OPTS, { "Name", "Role", "Distance" },
	function(set)
		detail = set
	end))

	Cfg.add("esp.style.tracers", "toggle",
	style:Toggle("Tracers", false, function(v) useTracer = v end))

	----------------------------------------------------------------
	-- Object ESP
	----------------------------------------------------------------
	local objects = ESP:Section("Object ESP")
	objects.card.LayoutOrder = 3

	objects:Label("Coins are marked with dots rather than glows on purpose: Roblox"
		.. " stops drawing highlights past about thirty of them, and a map holds far"
		.. " more coins than that. They follow the Farm tab's Target setting.")

	Cfg.add("esp.objects.coins", "toggle",
	objects:Toggle("Coin ESP", false, function(v)
		coinsOn = v
		if not v then dropCoins() end
	end))

	Cfg.add("esp.objects.gun", "toggle",
	objects:Toggle("Dropped Gun ESP", false, function(v)
		gunOn = v
		if v then gunStamp = -1e9 else dropGuns() end
	end))

	objects:Label("The dropped gun is a name guess, not a confirmed path -- the round"
		.. " the dump watched ended on the clock, so no gun was ever dropped to look"
		.. " at. If it never marks anything, that is why.")
end)()

--==============================================================
-- AUTO PICK DEVICE   (the Android "Choose Your Device" popup)
--==============================================================
-- No toggle and no button, by request: it just happens. A thing you always want has
-- no business being a switch.
--
-- WHY THIS IS SO PARANOID
-- The popup's own warning is "Choosing the wrong device will mess up your menu --
-- rejoin if you select the wrong device", so a misfire is not a no-op, it costs a
-- rejoin. Nothing about this GUI has been dumped, so every name in here is a guess,
-- and a guess that presses SOMETHING is far worse than one that presses nothing:
--   * "phone" is matched as a whole WORD, tokenised, never as a substring -- a
--     substring test fires on "Headphones" and "iPhone 12" just as happily.
--   * a phone-looking panel is not enough on its own. It only counts as a device
--     chooser when a RIVAL device word (tablet / pc / console / ...) is on screen in
--     an enclosing panel, or the "choose your device" title is. One word alone could
--     be any settings menu in the game.
--   * the chosen panel must contain "phone" and NO rival word. That is also what
--     rejects the wrapper holding BOTH panels -- it contains both words, so it is
--     never mistaken for the button.
--   * if two different panels both look like the phone one it presses NEITHER and
--     writes a report. Ambiguity is a dump, never a coin flip.
--   * handlers are tried before coordinates, because firing a button's own signal
--     cannot physically land on its neighbour.
--
-- ONE SHOT. THIS IS THE RULE THE FIRST BUILD GOT WRONG.
-- v1 pressed the panel four ways in a burst (handlers, click, click+inset,
-- click-raw), judged the result, and if the popup was still there it did the whole
-- burst again three seconds later, for three minutes. It froze the user's phone.
-- The mechanism was a feedback loop, not just repetition:
--   1. picking a device REBUILDS the menu -- that is what "will mess up your menu"
--      means -- so the panel we pressed is destroyed and replaced.
--   2. the cooldown was keyed on that panel INSTANCE, so the rebuilt panel was a
--      brand new key with no cooldown at all.
--   3. so a press that WORKED read as a press that missed, and earned an immediate
--      retry, whose rebuild earned another. ~240 presses and 240 menu rebuilds.
-- The debounce was invalidated by the very thing it was debouncing. So now:
--   * ONE input event, ever. A latch is set the instant anything is sent and this
--     block never scans or presses again for the rest of the session.
--   * no coordinate variants. insetApplies() already computes the right answer from
--     IgnoreGuiInset; trying the other one "just in case" is what a storm is made of.
--   * the ONLY thing that can send a second event is fireHandlers returning false,
--     which does not mean "it missed" -- it means the signal had no connections and
--     literally nothing was sent. That is bounded at two events for the session.
--   * verification still runs, but it now decides only what gets REPORTED. It can no
--     longer decide to press again. Being wrong quietly once beats being wrong 240
--     times, and if it did miss, the dump says so and a manual tap costs one tap.
--
-- COST
-- Armed, not permanent: fast for 30s, slow until a 2 minute deadline, then the loop
-- ends and costs nothing. A new ScreenGui in PlayerGui re-arms it. A tick walks only
-- the ENABLED ScreenGuis and skips our own hub -- v1 walked all of PlayerGui every
-- 0.4s including the several hundred instances of this very interface, which on a
-- phone is a stutter all by itself, before a single click is sent.
--==============================================================
;(function()
	local WANT   = "phone"
	-- Whole words only, and deliberately NOT "switch": the tablet panel reads
	-- "Touch to switch", so treating that as a device word would reject the real
	-- phone panel the moment the layout put the same hint on its side.
	local RIVALS = {
		tablet = true, ipad = true, pc = true, computer = true, laptop = true,
		desktop = true, console = true, xbox = true, playstation = true,
	}
	local DENY = {
		buy = true, purchase = true, robux = true, gamepass = true, premium = true,
		upgrade = true, shop = true,
	}
	-- Proof that a device chooser is what is on screen. The title is the obvious one,
	-- but the other three are the strings the popup itself puts on the panels and in
	-- its red warning line, and they matter: if the Tablet panel happens to sit more
	-- than HOPS levels away from the Phone panel there is no shared wrapper to find,
	-- and without one of these the feature would decide "not a chooser" and do
	-- nothing at all -- silently, which is the worst outcome available.
	local TITLE_BITS = {
		"choose your device", "select your device", "choose device",
		"previous device", "touch to switch", "wrong device",
	}

	local HOPS       = 8            -- ancestors walked up from a phone label
	-- The chooser is a MODAL: it sits there waiting for you, so there is nothing to
	-- react quickly to. A 1s tick is imperceptible to a human and two and a half times
	-- cheaper than v1's 0.4s, which is the whole reason those numbers were wrong.
	local FAST, SLOW = 1.0, 3.0
	local FAST_FOR   = 30           -- seconds of fast polling per arming
	local LIFETIME   = 120          -- seconds before the loop gives up entirely
	local SETTLE     = 0.35         -- time given to the popup to react before judging
	local DUMP_PATH  = "ArjhayHub_MM2_device.txt"

	-- `fired` is a LATCH, not a "did it work" flag. It goes true the moment any input
	-- is sent and nothing clears it -- no scan, no press, no re-arm afterwards for the
	-- rest of the session. There is deliberately no `tried` table any more: v1 keyed a
	-- 3s cooldown on the panel instance, and picking a device destroys and rebuilds
	-- that instance, so the new one was never in the table and the "cooldown" let
	-- every single tick press again. See the ONE SHOT note above.
	local wantLoop, busy = true, false
	local fired, dumped = false, false
	local armUntil, deadline, lastWarn = 0, 0, 0

	local function isTextNode(d)
		return d:IsA("TextLabel") or d:IsA("TextButton")
	end

	local function wordsOf(inst, into)
		local t = inst.Text
		if type(t) == "string" and #t > 0 and #t <= 200 then
			for w in string.gmatch(string.lower(t), "%a+") do into[w] = true end
		end
		return into
	end

	-- Every word in a subtree. The cap bounds the ITERATION, not GetDescendants'
	-- allocation, which is fine: this only ever runs once a visible "phone" word
	-- exists, which in practice means the popup is already up.
	local function subtreeWords(root, cap)
		local out = {}
		if isTextNode(root) then wordsOf(root, out) end
		local n = 0
		for _, d in ipairs(root:GetDescendants()) do
			n = n + 1
			if n > cap then break end
			if isTextNode(d) then wordsOf(d, out) end
		end
		return out
	end

	local function anyWord(set, list)
		for w in pairs(list) do
			if set[w] then return w end
		end
		return nil
	end

	-- The surfaces worth walking: an ENABLED LayerCollector that is not our own. A
	-- disabled one cannot be showing a popup whatever is inside it, and MM2 parks most
	-- of its menus as disabled ScreenGuis, so this skips most of PlayerGui for free.
	-- Excluding `screen` earns its place twice: the hub is several hundred instances of
	-- pure cost on a tick that used to run every 0.4s, and it is text WE wrote, so it
	-- has no business being evidence about what the game is showing.
	local function surfaces(pg)
		local out = {}
		for _, sg in ipairs(pg:GetChildren()) do
			if sg ~= screen and sg:IsA("LayerCollector") then
				local ok, on = pcall(function() return sg.Enabled end)
				if ok and on then table.insert(out, sg) end
			end
		end
		return out
	end

	----------------------------------------------------------------
	-- the report, for when the guesswork does not pan out
	----------------------------------------------------------------
	-- Console text cannot be copied out, so a failure has to land in a file or it
	-- may as well not have been reported. Once per session, and capped so the result
	-- is small enough to actually send.
	local function dumpDevice(pg, why)
		if dumped then return end
		dumped = true
		if type(writefile) ~= "function" then
			warn("[Arjhay Hub] device: " .. why .. " -- no writefile, cannot report")
			return
		end

		-- The report deliberately does NOT reuse surfaces() as a filter. This file only
		-- ever gets written because the scanner did the wrong thing, and if the reason
		-- was that surfaces() wrongly skipped the chooser's own ScreenGui, a report
		-- built through the same filter would show an empty screen and hide the bug
		-- that caused it. So: walk everything except our own hub, and MARK which nodes
		-- the scanner was able to see. A row tagged [scanner skipped] next to the word
		-- Phone is the answer on its own.
		local scannable = {}
		for _, sg in ipairs(surfaces(pg)) do scannable[sg] = true end
		local function surfaceOf(d)
			local cur = d
			while cur and cur ~= pg do
				if cur:IsA("LayerCollector") then return cur end
				cur = cur.Parent
			end
			return nil
		end
		local function tag(d)
			local sg = surfaceOf(d)
			if sg and scannable[sg] then return "" end
			return "   [scanner skipped: " .. (sg and (sg.Name .. " is disabled") or "no surface") .. "]"
		end

		local roots = {}
		for _, sg in ipairs(pg:GetChildren()) do
			if sg ~= screen and sg:IsA("LayerCollector") then table.insert(roots, sg) end
		end

		local out = {}
		table.insert(out, "Arjhay Hub -- Choose Your Device report")
		table.insert(out, "why: " .. why)
		table.insert(out, "looking for the whole word: " .. WANT)
		table.insert(out, "one shot only: the latch is up, nothing here will press again")
		table.insert(out, "")
		table.insert(out, "== surfaces in PlayerGui (our own hub excluded) ==")
		for _, sg in ipairs(roots) do
			table.insert(out, string.format("  %-28s %s", sg.Name,
				scannable[sg] and "ENABLED (scanned)" or "disabled (skipped)"))
		end
		if #roots == 0 then table.insert(out, "  (none at all)") end
		table.insert(out, "")
		table.insert(out, "== visible text on screen ==")
		local n = 0
		for _, sg in ipairs(roots) do
			for _, d in ipairs(sg:GetDescendants()) do
				if isTextNode(d) and #d.Text > 0 and n < 150 then
					local ok, vis = pcall(trulyVisible, d)
					if ok and vis then
						n = n + 1
						table.insert(out, string.format(
							"%3d  %-12s %-22s pos=%d,%d  size=%dx%d  text=%s%s",
							n, d.ClassName, d.Name,
							math.floor(d.AbsolutePosition.X), math.floor(d.AbsolutePosition.Y),
							math.floor(d.AbsoluteSize.X), math.floor(d.AbsoluteSize.Y),
							d.Text, tag(d)))
						table.insert(out, "     " .. d:GetFullName())
					end
				end
			end
		end
		if n == 0 then table.insert(out, "(nothing visible with text)") end
		table.insert(out, "")
		table.insert(out, "== visible buttons ==")
		local b = 0
		for _, sg in ipairs(roots) do
			for _, d in ipairs(sg:GetDescendants()) do
				if d:IsA("GuiButton") and b < 80 then
					local ok, vis = pcall(trulyVisible, d)
					if ok and vis then
						b = b + 1
						table.insert(out, string.format("%3d  %-12s %-22s pos=%d,%d  size=%dx%d%s",
							b, d.ClassName, d.Name,
							math.floor(d.AbsolutePosition.X), math.floor(d.AbsolutePosition.Y),
							math.floor(d.AbsoluteSize.X), math.floor(d.AbsoluteSize.Y), tag(d)))
						table.insert(out, "     " .. d:GetFullName())
					end
				end
			end
		end
		if b == 0 then table.insert(out, "(no visible buttons at all -- the panels are")
			table.insert(out, " plain Frames, so the click has to be by coordinate)")
		end
		if pcall(writefile, DUMP_PATH, table.concat(out, "\n")) then
			warn("[Arjhay Hub] device: " .. why .. " -- wrote " .. DUMP_PATH)
		else
			warn("[Arjhay Hub] device: " .. why .. " -- writefile failed")
		end
	end

	----------------------------------------------------------------
	-- one sweep
	----------------------------------------------------------------
	local function scan()
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		if not pg then return "no playergui" end

		-- ONE walk per enabled surface. trulyVisible is expensive per node (it climbs to
		-- the root), so it only ever runs on a node whose text already matched a keyword.
		local phones, titled = {}, false
		for _, sg in ipairs(surfaces(pg)) do
			for _, d in ipairs(sg:GetDescendants()) do
				if isTextNode(d) then
					local raw = d.Text
					if #raw > 0 and #raw <= 200 then
						local low = string.lower(raw)
						if not titled then
							for _, bit in ipairs(TITLE_BITS) do
								if string.find(low, bit, 1, true) and trulyVisible(d) then
									titled = true
									break
								end
							end
						end
						if string.find(low, WANT, 1, true) then
							local w = {}
							for x in string.gmatch(low, "%a+") do w[x] = true end
							if w[WANT] and trulyVisible(d) then table.insert(phones, d) end
						end
					end
				end
			end
		end
		if #phones == 0 then return "no phone label" end

		-- Climb from each phone label. The first ancestor that also contains a rival
		-- device word is the WRAPPER holding both panels, so everything below it is
		-- the phone side. Never climb past a LayerCollector -- the popup cannot be
		-- wider than its own ScreenGui.
		local best, bestWrap, clashed, sawChooser = nil, nil, false, false
		for _, lab in ipairs(phones) do
			local chain, wrap = {}, nil
			local node, hops = lab, 0
			while node and node ~= pg and hops <= HOPS do
				if node:IsA("LayerCollector") then break end
				if node:IsA("GuiObject") then
					if anyWord(subtreeWords(node, 400), RIVALS) then wrap = node; break end
					table.insert(chain, node)
				end
				node, hops = node.Parent, hops + 1
			end

			-- A lone "Phone" word with no rival above it and no title on screen is
			-- not a device chooser, it is just a word. Leave it alone.
			if (wrap or titled) and #chain > 0 then
				sawChooser = true
				-- outermost button below the wrapper: the whole panel is usually the
				-- clickable thing and the label inside it may be a button too
				local target = nil
				for i = #chain, 1, -1 do
					if chain[i]:IsA("GuiButton") then target = chain[i]; break end
				end
				target = target or chain[#chain]

				-- named tws, not tw: `tw` is the file's tween helper, and shadowing it
				-- inside a 150-line function is a trap laid for whoever edits next
				local tws = subtreeWords(target, 400)
				if tws[WANT] and not anyWord(tws, RIVALS) and not anyWord(tws, DENY) then
					if best == nil then
						best, bestWrap = target, wrap
					elseif best ~= target then
						clashed = true
					end
				end
			end
		end

		if clashed then
			dumpDevice(pg, "two different panels both look like Phone")
			return "ambiguous"
		end
		if not best then
			-- Context said "device chooser" and still nothing under the phone label
			-- passed the word test. Returning quietly here is exactly how a feature
			-- dies silently, so this is the case that has to leave a file behind.
			if sawChooser then
				dumpDevice(pg, "chooser is on screen but no panel passed the word test")
				return "unresolved"
			end
			return "no chooser context"
		end

		-- A press counts only when the popup actually goes away -- pcall not throwing
		-- proves nothing, that lesson came from the shells clicker. But note what this
		-- is now FOR: it decides what gets logged, and it is read AFTER the latch is
		-- already set. It cannot ask for another press. In v1 it could, and a rebuilt
		-- menu made it ask ~240 times.
		local wrap = bestWrap or best
		local function gone()
			if best.Parent == nil or wrap.Parent == nil then return true end
			local okW, visW = pcall(trulyVisible, wrap)
			if okW and not visW then return true end
			local okB, visB = pcall(trulyVisible, best)
			return okB and not visB
		end
		if gone() then return "already gone" end

		-- THE LATCH GOES UP BEFORE THE PRESS, NOT AFTER.
		-- Setting it afterwards would leave a window where the press has landed, the
		-- game is already rebuilding the menu, and this function has not yet recorded
		-- that anything happened -- and if the press throws, or the scheduler steps
		-- away at the task.wait below, that window is where a second press comes from.
		-- The whole bug was a press that did not count as one.
		fired = true

		local how = nil
		if best:IsA("GuiButton") and fireHandlers(best) then
			-- Firing the panel's own connections cannot physically land on Tablet, so
			-- this is the safest possible way in and it is tried first.
			how = "handlers"
		else
			-- Either it is not a button, or the signal had no connections and so
			-- literally nothing was sent -- which is not a miss, it is a no-op, and is
			-- the ONE case allowed to send a second event. insetApplies reads
			-- IgnoreGuiInset off the panel's own LayerCollector, so it is the answer,
			-- not a guess; v1's extra "try it the other way" variants are gone.
			sendClick(best, insetApplies(best))
			how = "click"
		end

		task.wait(SETTLE)
		if gone() then
			print("[Arjhay Hub] device: chose Phone via " .. how .. ". Stopping.")
			return "picked"
		end
		-- Pressed once and the popup is still up. It may have worked anyway (a chooser
		-- that stays open until the menu reloads looks identical to one that ignored
		-- us), so this reports and stops rather than escalating. One manual tap is a
		-- cheaper failure than a click storm.
		dumpDevice(pg, "pressed the Phone panel via " .. how
			.. " and it was still on screen " .. SETTLE .. "s later -- stopped anyway,"
			.. " one shot only. Tap Phone by hand if it did not take.")
		return "pressed, unconfirmed"
	end

	----------------------------------------------------------------
	-- driver
	----------------------------------------------------------------
	local function loop()
		if busy then return end
		busy = true
		-- `fired` is checked here AND at the top of arm(), because these are two
		-- different ways back in: this one ends the tick loop, that one refuses to
		-- start a new one when a ScreenGui shows up later.
		while wantLoop and not fired and os.clock() < deadline do
			local ok, res = pcall(scan)
			if not ok then
				if os.clock() - lastWarn > 5 then      -- never spam at tick rate
					lastWarn = os.clock()
					warn("[Arjhay Hub] device: " .. tostring(res))
				end
			end
			-- Note what is NOT here any more: v1 set its stop flag from `res == "picked"`,
			-- i.e. only when the popup was confirmed gone. Any other outcome kept the
			-- loop alive to press again. scan() now latches itself the instant it sends
			-- anything, so every outcome ends this loop, confirmed or not.
			if fired then break end
			task.wait((os.clock() < armUntil) and FAST or SLOW)
		end
		busy = false
	end

	local function arm()
		if fired then return end
		armUntil = os.clock() + FAST_FOR
		deadline = os.clock() + LIFETIME
		if not busy then task.spawn(loop) end
	end

	-- The popup may also be up before the hub is injected, in which case the first
	-- tick already catches it. This connection is for the other case: a chooser that
	-- arrives later inside a ScreenGui of its own. It cannot see a popup that lives
	-- in an ALREADY existing ScreenGui and merely gets re-enabled, which is why the
	-- first arming polls rather than trusting events.
	--
	-- THIS WAS THE THIRD AMPLIFIER, and the one that made v1's "2 minute deadline"
	-- meaningless. Choosing a device rebuilds the menu, a rebuilt menu parents new
	-- ScreenGuis into PlayerGui, ChildAdded fires, and arm() pushed `deadline` out by
	-- another full LIFETIME and `armUntil` back to fast. So every press bought the
	-- loop more time to press again -- the lifetime cap could never expire while the
	-- storm was running, because the storm itself kept renewing it. arm() now refuses
	-- outright once the latch is up, and this hands itself in as soon as it sees that.
	local pgNow = LocalPlayer:FindFirstChild("PlayerGui")
	if pgNow then
		local armConn
		armConn = Bin.conn(pgNow.ChildAdded:Connect(function(child)
			if fired then
				if armConn then pcall(function() armConn:Disconnect() end) end
				return
			end
			if child:IsA("LayerCollector") then arm() end
		end))
	end

	-- while-loop, not a connection, so Bin.flush() cannot reach it: clear the flag
	-- it spins on or it keeps polling after the close button
	Bin.onUnload(function() wantLoop = false end)

	-- dead last on purpose: task.spawn runs the worker up to its first yield
	-- SYNCHRONOUSLY, so arming any earlier would let a press happen before the flag
	-- that stops it was ever registered
	arm()
end)()

--==============================================================
-- open
--==============================================================
selectTab(Farm)
applySearch("")

-- Start Minimized is PEEKED out of the autoload config here rather than waited for.
-- The real autoload runs dead last -- it has to, every control must exist before
-- anything is :Set -- and by the time it fires the window has already tweened open,
-- so a preference read from it could only ever fold a window the user had already
-- seen. setMinimized(true) is deliberately not used either: it plays a 0.14s shrink
-- and then swaps to the circle, which is exactly the flash this setting exists to
-- avoid. Open straight as the circle instead, leaving root at full size and fully
-- opaque so the first restore behaves like every other one.
if Cfg.autoPeek("window.startmin") == true then
	minimized    = true
	root.Visible = false
	pip.Visible  = true
	pip.Size     = UDim2.fromOffset(30, 30)
	tw(pip, 0.16, { Size = UDim2.fromOffset(52, 52) })
else
	root.Size = UDim2.fromOffset(WIN_W, WIN_H - 24)
	root.BackgroundTransparency = 1
	tw(root, 0.22, { Size = UDim2.fromOffset(WIN_W, WIN_H), BackgroundTransparency = 0 })
end

--==============================================================
-- auto load
--==============================================================
-- Dead last on purpose. Loading a config means calling :Set on controls, so every
-- one of them has to exist first -- run this any higher up and it silently restores
-- only the half of the hub that had been built by then.
do
	local name = Cfg.autoGet()
	if name then
		task.spawn(function()
			local done, extra = Cfg.load(name)
			if done then
				local msg = "Auto loaded " .. name .. ": " .. done .. " settings"
					.. ((extra > 0) and (", " .. extra .. " skipped") or "") .. "."
				if Cfg.setStatus then Cfg.setStatus(msg) end
				print("[Arjhay Hub] " .. msg)
			elseif Cfg.setStatus then
				Cfg.setStatus("Auto load failed: " .. tostring(extra))
			end
		end)
	end
end

if getgenv then
	getgenv().ArjhayHub = {
		Screen    = screen,
		Window    = root,
		Pip       = pip,
		AddTab    = addTab,
		Select    = selectTab,
		Unload    = unload,
		Minimize  = setMinimized,
		Theme     = T,
		Config    = Cfg,
	}
end

