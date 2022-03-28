-- Load Plugin

local toolbarSeger = plugin:CreateToolbar("Seger's plugins") --Creates a place on the toolbar
local setupBtn = toolbarSeger:CreateButton("Setup", "Automatically creates the layout you need to get started creating your maps", "http://www.roblox.com/asset/?id=9091745830")
local exportBtn = toolbarSeger:CreateButton("Export World Compressed", "Export and compresses your map to import it into my FPS", "http://www.roblox.com/asset/?id=9133648234")
local exportNonCompressBtn = toolbarSeger:CreateButton("Export World Non Compressed", "Export your map to import it into my FPS", "http://www.roblox.com/asset/?id=9091748029")
local exportComprLightBtn = toolbarSeger:CreateButton("Export World Lighter", "Export and compresses your map to import it into my FPS. By chosing this option your file size will be smaller but less precise", "http://www.roblox.com/asset/?id=9133648930")
local exportJSONBtn = toolbarSeger:CreateButton("Export World RBLX Table", "Export your map as a ROBLOX table (currently not supported for import)", "http://www.roblox.com/asset/?id=9133581678")
local settingsBtn = toolbarSeger:CreateButton("Settings", "Settings/Options menu", "http://www.roblox.com/asset/?id=9091747193")

-- Save Function

function SaveFile(text) -- This function is to make a Save As .txt/.lua screen pop up
	local script = Instance.new("Script", game.ReplicatedStorage)
	script.Source = text
	script.Name = "ExportedMapTemp"
	game:GetService("Selection"):Set({script})
	print(script.Source)
	plugin:PromptSaveSelection("ExportedMap")
	wait(0.25)
	script:Destroy()
end

-- Buttons

setupBtn.Click:Connect(function() --When the setup button is pressed
	if game:GetService("ServerStorage"):FindFirstChild("SegerWorldExport") and game:GetService("ServerStorage"):FindFirstChild("SegerWorldExport").Settings.MapLocationFolder.Value == nil then
		warn("Already found a setup file in ServerStorage, But there is no map location selected in (game.ServerStorage.SegerWorldExport.Settings.MapLocationFolder.Value)")
	elseif game.Workspace:FindFirstChild("Map") and not game:GetService("ServerStorage"):FindFirstChild("SegerWorldExport") then
		warn("Found a map file in workspace, But no config files in ServerStorage!")
	else
		print("Seems like the setup is okay. If you get an error about the setup try deleting the folder 'SegerWorldExport' in ServerStorage")
	end
	if not game.Workspace:FindFirstChild("Map") then
		local map = Instance.new("Folder")
		map.Name = "Map"
		map.Parent = game.Workspace
		print("Created a folder named 'Map'. Place everything of your map that you want to be exported in that exact folder.")
	end
	if not game:GetService("ServerStorage"):FindFirstChild("SegerWorldExport") then
		local folder = Instance.new("Folder")
		folder.Name = "SegerWorldExport"
		folder.Parent = game:GetService("ServerStorage")
		local settingsF = Instance.new("Folder")
		settingsF.Name = "Settings"
		settingsF.Parent = folder
		local scriptF = Instance.new("Folder")
		scriptF.Name = "Scripts"
		scriptF.Parent = folder
		local mapLocation = Instance.new("ObjectValue")
		mapLocation.Name = "Map1"
		mapLocation.Value = game.Workspace.Map
		mapLocation.Parent = settingsF
		local compressScript = Instance.new("ModuleScript")
		compressScript.Name = "CompressScript"
		compressScript.Source = [[
local dictionary = {}
do -- populate dictionary
	local length = 0
	for i = 32, 127 do
		if i ~= 34 and i ~= 92 then
			local c = string.char(i)
			dictionary[c], dictionary[length] = length, c
			length = length + 1
		end
	end
end

local escapemap = {}
do -- Populate escape map
	for i = 1, 34 do
		i = ({ 34, 92, 127 })[i - 31] or i
		local c, e = string.char(i), string.char(i + 31)
		escapemap[c], escapemap[e] = e, c
	end
end

local function escape(s)
	return string.gsub(s, '[%c"\\]', function(c)
		return "\127" .. escapemap[c]
	end)
end
local function unescape(s)
	return string.gsub(s, "\127(.)", function(c)
		return escapemap[c]
	end)
end

local function copy(t)
	local new = {}
	for k, v in pairs(t) do
		new[k] = v
	end
	return new
end

local b93Cache = {}
local function tobase93(n)
	local value = b93Cache[n]
	if value then
		return value
	end

	value = ""
	repeat
		local remainder = n % 93
		value = dictionary[remainder] .. value
		n = (n - remainder) / 93
	until n == 0

	b93Cache[n] = value
	return value
end

local b10Cache = {}
local function tobase10(value)
	local n = b10Cache[value]
	if n then
		return n
	end

	n = 0
	for i = 1, #value do
		n = n + 93 ^ (i - 1) * dictionary[string.sub(value, -i, -i)]
	end

	b10Cache[value] = n
	return n
end

local function compress(text)
	local dictionaryCopy = copy(dictionary)
	local key, sequence, size = "", {}, #dictionaryCopy
	local width, spans, span = 1, {}, 0
	print("Compressing map")
	local function listkey(k)
		local value = tobase93(dictionaryCopy[k])
		local valueLength = #value
		if valueLength > width then
			width, span, spans[width] = valueLength, 0, span
		end
		table.insert(sequence, string.rep(" ", width - valueLength) .. value)
		span += 1
	end
	text = escape(text)
	for i = 1, #text do
		local c = string.sub(text, i, i)
		local new = key .. c
		if dictionaryCopy[new] then
			key = new
		else
			listkey(key)
			key = c
			size += 1
			dictionaryCopy[new], dictionaryCopy[size] = size, new
		end
	end
	listkey(key)
	spans[width] = span
	return table.concat(spans, ",") .. "|" .. table.concat(sequence)
end

local function decompress(text)
	local dictionaryCopy = copy(dictionary)
	local sequence, spans, content = {}, string.match(text, "(.-)|(.*)")
	local groups, start = {}, 1
	for span in string.gmatch(spans, "%d+") do
		local width = #groups + 1
		groups[width] = string.sub(content, start, start + span * width - 1)
		start = start + span * width
	end
	local previous

	for width, group in ipairs(groups) do
		for value in string.gmatch(group, string.rep(".", width)) do
			local entry = dictionaryCopy[tobase10(value)]
			if previous then
				if entry then
					table.insert(dictionaryCopy, previous .. string.sub(entry, 1, 1))
				else
					entry = previous .. string.sub(previous, 1, 1)
					table.insert(dictionaryCopy, entry)
				end
				table.insert(sequence, entry)
			else
				sequence[1] = entry
			end
			previous = entry
		end
	end
	return unescape(table.concat(sequence))
end

return { Compress = compress, Decompress = decompress }
]]
		compressScript.Parent = scriptF
		print("Created important folders in ServerStorage.SegerWorldExport")
	end

	print("Setup finished")
end)

-- Export Map Compressed

exportBtn.Click:Connect(function()
	if not game:GetService("ServerStorage"):FindFirstChild("SegerWorldExport") then
		error("Before exporting you need to complete the map and plugin setup!")
	end
	local serializer = require(9090316599)

	for _, maps in pairs(game:GetService("ServerStorage").SegerWorldExport.Settings:GetChildren()) do
		local result, problem = pcall(function()
			for _, obj in pairs(maps.Value:GetDescendants()) do
				if obj.ClassName == "MeshPart" then
					obj.Name = obj.MeshId
				end
				if obj.ClassName ~= "Folder" and obj.ClassName ~= "Model" and obj.ClassName ~= "Part" and obj.ClassName ~= "MeshPart" and obj.ClassName ~= "TrussPart" and obj.ClassName ~= "WedgePart"  and obj.ClassName ~= "CornerWedgePart" and obj.ClassName ~= "Decal" and obj.ClassName ~= "WeldConstraint" and obj.ClassName ~= "Texture" and obj.ClassName ~= "SpecialMesh" and obj.ClassName ~= "Fire" and obj.ClassName ~= "Smoke" and obj.ClassName ~= "Explosion" and obj.ClassName ~= "Sparkles" and obj.ClassName ~= "PointLight" and obj.ClassName ~= "SpotLight" and obj.ClassName ~= "SurfaceLight" and obj.ClassName ~= "SpawnLocation" then
					obj:Destroy()
					print("Destroyed "..obj.ClassName .." with name: ".. obj.Name .." | Reason: Object not yet supported for export")
				end
			end
			wait(0.1)
			local compressor = require(game:GetService("ServerStorage").SegerWorldExport.Scripts.CompressScript)
			print("Starting exporting...")
			SaveFile(compressor.Compress(serializer.Encrypt(maps.Value:GetChildren())))
		end)

		if not(result) then
			if problem == "String too long" then
				local compressor = require(game:GetService("ServerStorage").SegerWorldExport.Scripts.CompressScript)
				print(compressor.Compress(serializer.Encrypt(maps.Value:GetChildren())))
				warn("String/File size was too much for Roblox to paste inside a .lua file. But you can right-click and copy and paste the above JSON table manualy in a .lua/.txt file")
			else
				error(problem)
			end

		end
	end
end)

-- Export map noncompressed

exportNonCompressBtn.Click:Connect(function()
	if not game:GetService("ServerStorage"):FindFirstChild("SegerWorldExport") then
		error("Before exporting you need to complete the map and plugin setup!")
	end
	local serializer = require(game.ServerScriptService.MainModule)

	for _, maps in pairs(game:GetService("ServerStorage").SegerWorldExport.Settings:GetChildren()) do
		local result, problem = pcall(function()
			for _, obj in pairs(maps.Value:GetDescendants()) do
				if obj.ClassName == "MeshPart" then
					obj.Name = obj.MeshId
				end
				if obj.ClassName ~= "Folder" and obj.ClassName ~= "Model" and obj.ClassName ~= "Part" and obj.ClassName ~= "MeshPart" and obj.ClassName ~= "TrussPart" and obj.ClassName ~= "WedgePart"  and obj.ClassName ~= "CornerWedgePart" and obj.ClassName ~= "Decal" and obj.ClassName ~= "WeldConstraint" and obj.ClassName ~= "Texture" and obj.ClassName ~= "SpecialMesh" and obj.ClassName ~= "Fire" and obj.ClassName ~= "Smoke" and obj.ClassName ~= "Explosion" and obj.ClassName ~= "Sparkles" and obj.ClassName ~= "PointLight" and obj.ClassName ~= "SpotLight" and obj.ClassName ~= "SurfaceLight" and obj.ClassName ~= "SpawnLocation" then
					obj:Destroy()
					print("Destroyed "..obj.ClassName .." with name: ".. obj.Name .." | Reason: Object not yet supported for export")
				end
			end
			wait(0.1)
			print("Starting exporting...")
			SaveFile(serializer.Encrypt(maps.Value:GetChildren()))
		end)

		if not(result) then
			if problem == "String too long" then
				print(serializer.Encrypt(maps.Value:GetChildren()))
				warn("String/File size was too much for Roblox to paste inside a .lua file. But you can right-click and copy and paste the above JSON table manualy in a .lua/.txt file, Its not recommend to do because importing doesn't work.")
			else
				error(problem)
			end
		end
	end
end)

-- Export map to RBLX table

exportJSONBtn.Click:Connect(function()
	if not game:GetService("ServerStorage"):FindFirstChild("SegerWorldExport") then
		error("Before exporting you need to complete the map and plugin setup!")
	end
	local serializer = require(9090316599)

	for _, maps in pairs(game:GetService("ServerStorage").SegerWorldExport.Settings:GetChildren()) do
		local result, problem = pcall(function()
			for _, obj in pairs(maps.Value:GetDescendants()) do
				if obj.ClassName == "MeshPart" then
					obj.Name = obj.MeshId
				end
				if obj.ClassName ~= "Folder" and obj.ClassName ~= "Model" and obj.ClassName ~= "Part" and obj.ClassName ~= "MeshPart" and obj.ClassName ~= "TrussPart" and obj.ClassName ~= "WedgePart"  and obj.ClassName ~= "CornerWedgePart" and obj.ClassName ~= "Decal" and obj.ClassName ~= "WeldConstraint" and obj.ClassName ~= "Texture" and obj.ClassName ~= "SpecialMesh" and obj.ClassName ~= "Fire" and obj.ClassName ~= "Smoke" and obj.ClassName ~= "Explosion" and obj.ClassName ~= "Sparkles" and obj.ClassName ~= "PointLight" and obj.ClassName ~= "SpotLight" and obj.ClassName ~= "SurfaceLight" and obj.ClassName ~= "SpawnLocation" then
					obj:Destroy()
					print("Destroyed "..obj.ClassName .." with name: ".. obj.Name .." | Reason: Object not yet supported for export, Its not recommend to do because importing doesn't work.")
				end
			end
			wait(0.1)
			local compressor = require(game:GetService("ServerStorage").SegerWorldExport.Scripts.CompressScript)
			print("Starting exporting...")
			print(serializer.JSON(maps.Value:GetChildren()))
		end)

		if not(result) then
			if problem == "String too long" then
				local compressor = require(game:GetService("ServerStorage").SegerWorldExport.Scripts.CompressScript)
				print(serializer.JSON(maps.Value:GetChildren()))
				warn("String/File size was too much for Roblox to paste inside a .lua file. But you can right-click and copy and paste the above JSON table manualy in a .lua/.txt file, Its not recommend to do because importing doesn't work.")
			else
				error(problem)
			end
		end
	end
end)

-- Export map light for reduced file sizes

exportComprLightBtn.Click:Connect(function()
	if not game:GetService("ServerStorage"):FindFirstChild("SegerWorldExport") then
		error("Before exporting you need to complete the map and plugin setup!")
	end
	local serializer = require(9090316599)

	for _, maps in pairs(game:GetService("ServerStorage").SegerWorldExport.Settings:GetChildren()) do
		local result, problem = pcall(function()
			for _, obj in pairs(maps.Value:GetDescendants()) do
				if obj.ClassName == "MeshPart" then
					obj.Name = obj.MeshId
				end
				if obj.ClassName ~= "Folder" and obj.ClassName ~= "Model" and obj.ClassName ~= "Part" and obj.ClassName ~= "MeshPart" and obj.ClassName ~= "TrussPart" and obj.ClassName ~= "WedgePart"  and obj.ClassName ~= "CornerWedgePart" and obj.ClassName ~= "Decal" and obj.ClassName ~= "WeldConstraint" and obj.ClassName ~= "Texture" and obj.ClassName ~= "SpecialMesh" and obj.ClassName ~= "Fire" and obj.ClassName ~= "Smoke" and obj.ClassName ~= "Explosion" and obj.ClassName ~= "Sparkles" and obj.ClassName ~= "PointLight" and obj.ClassName ~= "SpotLight" and obj.ClassName ~= "SurfaceLight" and obj.ClassName ~= "SpawnLocation" then
					obj:Destroy()
					print("Destroyed "..obj.ClassName .." with name: ".. obj.Name .." | Reason: Object not yet supported for export")
				end
			end
			wait(0.1)
			local compressor = require(game:GetService("ServerStorage").SegerWorldExport.Scripts.CompressScript)
			print("Starting exporting...")
			SaveFile(compressor.Compress(serializer.EncryptLight(maps.Value:GetChildren())))
		end)

		if not(result) then
			if problem == "String too long" then
				local compressor = require(game:GetService("ServerStorage").SegerWorldExport.Scripts.CompressScript)
				print(compressor.Compress(serializer.EncryptLight(maps.Value:GetChildren())))
				warn("String/File size was too much for Roblox to paste inside a .lua file. But you can right-click and copy and paste the above JSON table manualy in a .lua/.txt file, Its not recommend to do because importing doesn't work.")
			else
				error(problem)
			end
		end
	end
end)
