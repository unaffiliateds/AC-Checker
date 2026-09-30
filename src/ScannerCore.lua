--[[
    AC-Checker
    ScannerCore.lua

    Central controller.

    Responsibilities:
    - Create scanner modules
    - Start/stop scanners
    - Store detections
    - Create/update the admin GUI
    - Expose scanner status
]]

local Players = game:GetService("Players")

local LoopScanner =
	require(
		script.Parent:WaitForChild(
			"LoopScanner"
		)
	)

local JumpScanner =
	require(
		script.Parent:WaitForChild(
			"JumpScanner"
		)
	)

local Logs =
	require(
		script.Parent:WaitForChild(
			"Logs"
		)
	)

local ScannerCore = {}
ScannerCore.__index = ScannerCore

function ScannerCore.new(config)
	config = config or {}

	local self = setmetatable({}, ScannerCore)

	self.Config = {
		Enabled = config.Enabled ~= false,

		BaseSpeed =
			config.BaseSpeed or 18,

		SprintSpeed =
			config.SprintSpeed or 21,

		SpeedTolerance =
			config.SpeedTolerance or 1.25,

		SampleInterval =
			config.SampleInterval or 0.15,

		RequiredViolations =
			config.RequiredViolations or 3,

		ViolationWindow =
			config.ViolationWindow or 1.0,

		-- During development you can show the GUI
		-- to everybody.
		ShowGuiToAll =
			config.ShowGuiToAll == true,

		-- Admin user IDs.
		AdminUserIds =
			config.AdminUserIds or {},
	}

	self.Logs =
		Logs.new(500)

	self.LoopScanner =
		LoopScanner.new({
			BaseSpeed =
				self.Config.BaseSpeed,

			SprintSpeed =
				self.Config.SprintSpeed,

			Tolerance =
				self.Config.SpeedTolerance,

			SampleInterval =
				self.Config.SampleInterval,

			RequiredViolations =
				self.Config.RequiredViolations,

			ViolationWindow =
				self.Config.ViolationWindow,

			OnDetection =
				function(data)
					self:HandleDetection(
						data
					)
				end,
		})

	self.JumpScanner =
		JumpScanner.new()

	self.Started = false

	self.GuiConnections = {}

	self.LastGuiUpdate = 0

	return self
end

function ScannerCore:IsAdmin(player)
	if self.Config.ShowGuiToAll then
		return true
	end

	for _, userId in ipairs(
		self.Config.AdminUserIds
	) do
		if player.UserId == userId then
			return true
		end
	end

	return false
end

function ScannerCore:HandleDetection(data)
	local entry =
		self.Logs:Add(data)

	print(
		string.format(
			"[AC-Checker] SPEED DETECTION | %s | %.2f studs/s | limit %.2f | sprint=%s | log #%d",

			entry.PlayerName,

			entry.Speed or 0,

			entry.Limit or 0,

			tostring(
				entry.Sprinting
			),

			entry.Id
		)
	)

	self:UpdateGui()
end

--------------------------------------------------
-- GUI
--------------------------------------------------

function ScannerCore:CreateGui(player)
	if not self:IsAdmin(player) then
		return
	end

	local playerGui =
		player:FindFirstChildOfClass(
			"PlayerGui"
		)

	if not playerGui then
		return
	end

	local oldGui =
		playerGui:FindFirstChild(
			"ACCheckerGui"
		)

	if oldGui then
		oldGui:Destroy()
	end

	local screenGui =
		Instance.new("ScreenGui")

	screenGui.Name =
		"ACCheckerGui"

	screenGui.ResetOnSpawn =
		false

	screenGui.Parent =
		playerGui

	local frame =
		Instance.new("Frame")

	frame.Name =
		"Main"

	frame.Size =
		UDim2.fromOffset(
			430,
			310
		)

	frame.Position =
		UDim2.new(
			0,
			25,
			0.5,
			-155
		)

	frame.BackgroundColor3 =
		Color3.fromRGB(
			25,
			25,
			25
		)

	frame.BorderSizePixel = 0

	frame.Parent =
		screenGui

	local title =
		Instance.new("TextLabel")

	title.Name =
		"Title"

	title.Size =
		UDim2.new(
			1,
			0,
			0,
			45
		)

	title.BackgroundTransparency = 1

	title.Text =
		"AC-CHECKER"

	title.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)

	title.TextSize = 24

	title.Font =
		Enum.Font.GothamBold

	title.Parent =
		frame

	local status =
		Instance.new("TextLabel")

	status.Name =
		"Status"

	status.Position =
		UDim2.fromOffset(
			20,
			50
		)

	status.Size =
		UDim2.new(
			1,
			-40,
			0,
			30
		)

	status.BackgroundTransparency = 1

	status.TextXAlignment =
		Enum.TextXAlignment.Left

	status.Text =
		"STATUS: ONLINE"

	status.TextColor3 =
		Color3.fromRGB(
			80,
			220,
			120
		)

	status.TextSize = 16

	status.Font =
		Enum.Font.GothamMedium

	status.Parent =
		frame

	local info =
		Instance.new("TextLabel")

	info.Name =
		"Info"

	info.Position =
		UDim2.fromOffset(
			20,
			85
		)

	info.Size =
		UDim2.new(
			1,
			-40,
			0,
			45
		)

	info.BackgroundTransparency = 1

	info.TextXAlignment =
		Enum.TextXAlignment.Left

	info.TextColor3 =
		Color3.fromRGB(
			210,
			210,
			210
		)

	info.TextSize = 14

	info.Font =
		Enum.Font.Gotham

	info.Parent =
		frame

	local list =
		Instance.new("ScrollingFrame")

	list.Name =
		"Detections"

	list.Position =
		UDim2.fromOffset(
			20,
			135
		)

	list.Size =
		UDim2.new(
			1,
			-40,
			1,
			-155
		)

	list.BackgroundColor3 =
		Color3.fromRGB(
			18,
			18,
			18
		)

	list.BorderSizePixel = 0

	list.ScrollBarThickness =
		5

	list.CanvasSize =
		UDim2.new()

	list.Parent =
		frame

	local layout =
		Instance.new(
			"UIListLayout"
		)

	layout.Padding =
		UDim.new(
			0,
			5
		)

	layout.Parent =
		list

	self:UpdateGuiForPlayer(
		player
	)
end

function ScannerCore:UpdateGuiForPlayer(player)
	if not self:IsAdmin(player) then
		return
	end

	local playerGui =
		player:FindFirstChildOfClass(
			"PlayerGui"
		)

	if not playerGui then
		return
	end

	local gui =
		playerGui:FindFirstChild(
			"ACCheckerGui"
		)

	if not gui then
		self:CreateGui(player)
		return
	end

	local frame =
		gui:FindFirstChild("Main")

	if not frame then
		return
	end

	local info =
		frame:FindFirstChild("Info")

	local list =
		frame:FindFirstChild(
			"Detections"
		)

	if info then
		local count =
			self.Logs:GetCount()

		info.Text =
			string.format(
				"Normal: %.1f | Sprint: %.1f | Detections: %d",

				self.Config.BaseSpeed,

				self.Config.SprintSpeed,

				count
			)
	end

	if not list then
		return
	end

	-- Remove old detection rows.

	for _, child in ipairs(
		list:GetChildren()
	) do

		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local entries =
		self.Logs:GetEntries()

	-- Show newest first.

	for i = #entries, 1, -1 do

		local entry =
			entries[i]

		local row =
			Instance.new(
				"TextLabel"
			)

		row.Size =
			UDim2.new(
				1,
				-10,
				0,
				28
			)

		row.BackgroundColor3 =
			Color3.fromRGB(
				35,
				35,
				35
			)

		row.BorderSizePixel = 0

		row.TextXAlignment =
			Enum.TextXAlignment.Left

		row.Text =
			string.format(
				"  %s | %.2f s/s | limit %.2f",

				entry.PlayerName,

				entry.Speed or 0,

				entry.Limit or 0
			)

		row.TextColor3 =
			Color3.fromRGB(
				235,
				235,
				235
			)

		row.TextSize = 13

		row.Font =
			Enum.Font.Gotham

		row.Parent =
			list
	end

	task.defer(function()
		list.CanvasSize =
			UDim2.new(
				0,
				0,
				0,
				list.AbsoluteCanvasSize.Y
			)
	end)
end

function ScannerCore:UpdateGui()
	for _, player in ipairs(
		Players:GetPlayers()
	) do
		if self:IsAdmin(player) then
			self:UpdateGuiForPlayer(
				player
			)
		end
	end
end

--------------------------------------------------
-- START / STOP
--------------------------------------------------

function ScannerCore:Start()
	if self.Started then
		return
	end

	if not self.Config.Enabled then
		warn(
			"[AC-Checker] Scanner is disabled."
		)

		return
	end

	self.Started = true

	self.LoopScanner:Start()
	self.JumpScanner:Start()

	for _, player in ipairs(
		Players:GetPlayers()
	) do
		task.defer(function()
			self:CreateGui(player)
		end)
	end

	table.insert(
		self.GuiConnections,

		Players.PlayerAdded:Connect(
			function(player)

				player.CharacterAdded:Connect(
					function()
						task.wait(1)

						self:CreateGui(
							player
						)
					end
				)

				task.defer(function()
					self:CreateGui(
						player
					)
				end)
			end
		)
	)

	table.insert(
		self.GuiConnections,

		Players.PlayerRemoving:Connect(
			function(player)
				self.Logs:ClearPlayer(
					player.UserId
				)

				self.LoopScanner:
					ResetPlayer(
						player
					)
			end
		)
	)

	print("[AC-Checker] Scanner started.")
	print(
		string.format(
			"[AC-Checker] Normal: %.1f studs/s",
			self.Config.BaseSpeed
		)
	)

	print(
		string.format(
			"[AC-Checker] Sprint: %.1f studs/s",
			self.Config.SprintSpeed
		)
	)
end

function ScannerCore:Stop()
	if not self.Started then
		return
	end

	self.Started = false

	self.LoopScanner:Stop()
	self.JumpScanner:Stop()

	for _, connection in ipairs(
		self.GuiConnections
	) do
		connection:Disconnect()
	end

	table.clear(
		self.GuiConnections
	)

	print("[AC-Checker] Scanner stopped.")
end

function ScannerCore:GetStatus()
	return {
		Enabled =
			self.Config.Enabled,

		Started =
			self.Started,

		BaseSpeed =
			self.Config.BaseSpeed,

		SprintSpeed =
			self.Config.SprintSpeed,

		DetectionCount =
			self.Logs:GetCount(),
	}
end

function ScannerCore:GetLogs()
	return self.Logs:GetEntries()
end

return ScannerCore
