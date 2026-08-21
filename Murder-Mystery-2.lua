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
			if old.Name == "ArjhayHub" then pcall(function() old:Destroy() end) end
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
coinSec:Dropdown("Target", CAT_LABELS, { "Coins" }, function(set)
	coinCats, namesDirty = set, true
	containerStamp, poolStamp = -1e9, -1e9    -- force a fresh Workspace walk
end)

-- 0 is a real setting on this one, not a floor: at 0 the character stops flying
-- and only takes coins that come to it (see glideToward)
coinSec:Slider("Tween Speed (studs/s)", 0, 100, 60, function(v) coinSpeed = v end)
-- the length of the deliberate stop at each coin. It starts at 1 by request, so
-- there is no longer a "never stop" setting here.
coinSec:Slider("Delay Between Pickups", 1, 2, 1, function(v) coinDelay = v end)

coinSec:Toggle("Auto Collect Coins", false, function(on) setCollecting(on) end)

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

shellSec:Toggle("Auto Claim Shells", false, function(on)
	autoShells = on
	if on then task.spawn(shellLoop) end
end)
shellSec:Slider("Check Every (sec)", 0.1, 2, 0.4, function(v) shellDelay = v end)

-- "Claim Once Now" and the status label were deleted by request. The toggle now
-- does everything the manual button did.

-- the loop is a while-loop, not a connection, so Bin.flush() cannot reach it:
-- clear the flag it spins on or it keeps polling forever after the close button
Bin.onUnload(function() autoShells = false end)

--==============================================================
-- open
--==============================================================
selectTab(Farm)
applySearch("")

root.Size = UDim2.fromOffset(WIN_W, WIN_H - 24)
root.BackgroundTransparency = 1
tw(root, 0.22, { Size = UDim2.fromOffset(WIN_W, WIN_H), BackgroundTransparency = 0 })

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
	}
end

