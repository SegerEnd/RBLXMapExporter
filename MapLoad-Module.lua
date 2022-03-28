local module = {}

local HttpService = game:GetService("HttpService") --Getting access to the RBLX HttpService

function Deserialize(prop, value) --Checks what the type of the properties
	local r 
	if prop == "Position" or prop == "Size" then
		r = Vector3.new(value.X, value.Y, value.Z)
	elseif prop == "CFrame" then
		r = CFrame.fromMatrix(Deserialize("Position", value.pos), Deserialize("Position", value.rX), Deserialize("Position", value.rY), Deserialize("Position", value.rZ))
	elseif prop == "BrickColor" then
		r = BrickColor.new(value)
	elseif prop == "Color" or prop == "Color3" then
		r = Color3.fromHSV(unpack(value))
	elseif prop == "Material" or prop == "Face" or prop == "Shape" then
		r = Enum[value[1]][value[2]]
	else
		r = value
	end
	return r
end

local function create(parent, t)
	for class, _ in pairs(t) do
		for _, obj in pairs(t[class]) do
			local object = Instance.new(class)
			for prop, value in pairs(obj) do
				if prop ~= "Children" then -- If the prop has no children then start function Deserialize
					object[prop] = Deserialize(prop, value)
				else
					create(object, value)
				end
			end
			object.Parent = parent
			if object.ClassName == "MeshPart" then --Checks if part is a MeshPart if so I replace the part with a preloaded mesh.
				if object.Name == "rbxassetid://7802788464" then
					local objClone = game:GetService("ReplicatedStorage").preLoadedObjects.Meshes.Foilage.Leaves:Clone()
					objClone.Name = "Leaves"
					objClone.Size = object.Size
					objClone.Position = object.Position
					objClone.Orientation = object.Orientation
					objClone.TextureID = object.TextureID
					objClone.Color = object.Color
					objClone.Material = object.Material
					objClone.Transparency = object.Transparency
					objClone.Reflectance = object.Reflectance
					objClone.CanCollide = object.CanCollide
					objClone.CastShadow = object.CastShadow
					objClone.Parent = object.Parent
					object:Destroy()
				elseif object.Name == "rbxassetid://7803000000" then
					local objClone = game:GetService("ReplicatedStorage").preLoadedObjects.Meshes.Foilage.TreeBranch:Clone()
					objClone.Name = "TreeBranch"
					objClone.Size = object.Size
					objClone.Position = object.Position
					objClone.Orientation = object.Orientation
					objClone.TextureID = object.TextureID
					objClone.Color = object.Color
					objClone.Material = object.Material
					objClone.Transparency = object.Transparency
					objClone.Reflectance = object.Reflectance
					objClone.CanCollide = object.CanCollide
					objClone.CastShadow = object.CastShadow
					objClone.Parent = object.Parent
					object:Destroy()
				end
			elseif object.ClassName == "SpawnLocation" then
				object.Duration = 0
			end
			if object.Name == "Grass" then
				local grassClone = game:GetService("ReplicatedStorage").preLoadedObjects.Particles.GrassEmitter:Clone() --Clones the Particle Emitter from storage into the object.
				grassClone.Parent = object
			end
			if object.Name == "Ledge" then
				object:SetAttribute("LedgeEnabled", true)
			end
		end
	end
end

function module.Decrypt(dic, slot)
	local t = HttpService:JSONDecode(dic) --JSON decodes the given string
	create(slot, t)
end

return module
