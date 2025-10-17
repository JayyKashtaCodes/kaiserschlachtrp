local PLUGIN = PLUGIN

-- luacheck: globals ACCESS_LABELS
ACCESS_LABELS = {}
ACCESS_LABELS[DOOR_OWNER] = "owner"
ACCESS_LABELS[DOOR_TENANT] = "tenant"
ACCESS_LABELS[DOOR_GUEST] = "guest"
ACCESS_LABELS[DOOR_NONE] = "none"

function PLUGIN:GetDefaultDoorInfo(door)
    local owner = IsValid(door:GetDTEntity(0)) and door:GetDTEntity(0) or nil
    local name = door:GetNetVar("title", door:GetNetVar("name", IsValid(owner) and L"dTitleOwned" or L"dTitle"))
    local description = door:GetNetVar("ownable") and L("dIsOwnable") or L("dIsNotOwnable")
    local color = ix.config.Get("color")
    local faction = door:GetNetVar("faction")
    local class = door:GetNetVar("class")

	if (class) then
		local classData = ix.class.list[class]

		if (classData) then
			if (classData.color) then
				color = classData.color
			end

			if (!owner) then
				description = L("dOwnedBy", L2(classData.name) or classData.name)
			end
		end
	elseif (faction) then
		local info = ix.faction.indices[faction]
		color = team.GetColor(faction)

		if (info and !owner) then
			description = L("dOwnedBy", L2(info.name) or info.name)
		end
	end

	if (owner) then
		description = L("dOwnedBy", owner:GetName())
	end

	local classGroup = door:GetNetVar("classGroup")
    if classGroup and PLUGIN.classGroups[classGroup] then
        description = description .. "\n" .. L("Class Group:") .. " " .. classGroup
    end

	return {
		name = name,
		description = description,
		color = color
	}
end

function PLUGIN:DrawDoorInfo(door, width, position, angles, scale, clientPosition)
    local alpha = math.max((1 - clientPosition:DistToSqr(door:GetPos()) / 65536) * 255, 0)
    if (alpha < 1) then return end

    local info = hook.Run("GetDoorInfo", door) or self:GetDefaultDoorInfo(door)
    if (!istable(info) or table.IsEmpty(info)) then return end

    -- title + background
    surface.SetFont("ix3D2DMediumFont")

    local titleLines = string.Split(info.name, "\n")
    local totalTitleHeight, widestTitle = 0, 0
    local titleLineHeights = {}

    for _, line in ipairs(titleLines) do
        local w, h = surface.GetTextSize(line)
        widestTitle = math.max(widestTitle, w)
        totalTitleHeight = totalTitleHeight + h
        table.insert(titleLineHeights, h)
    end

    derma.SkinFunc("DrawImportantBackground", -width * 0.5, -totalTitleHeight * 0.5,
        width, totalTitleHeight, ColorAlpha(info.color, alpha * 0.5))

    surface.SetTextColor(ColorAlpha(color_white, alpha))

    local titleYOffset = -totalTitleHeight * 0.5
    for i, line in ipairs(titleLines) do
        local lineWidth, lineHeight = surface.GetTextSize(line)
        surface.SetTextPos(-lineWidth * 0.5, titleYOffset)
        surface.DrawText(line)
        titleYOffset = titleYOffset + lineHeight
    end

    -- description
	local descLines = {}
	for _, block in ipairs(string.Split(info.description, "\n")) do
		local wrapped = ix.util.WrapText(block, width, "ix3D2DSmallFont")
		table.Add(descLines, wrapped)
	end

	local y = totalTitleHeight * 0.5 + 4

	for i = 1, #descLines do
		local line = descLines[i]
		local textWidth, textHeight = surface.GetTextSize(line)

		surface.SetTextPos(-textWidth * 0.5, y)
		surface.DrawText(line)

		y = y + textHeight
	end


    -- background blur
    ix.util.PushBlur(function()
        cam.Start3D2D(position, angles, scale)
            surface.SetDrawColor(11, 11, 11, math.max(alpha - 100, 0))
            surface.DrawRect(-width * 0.5, -totalTitleHeight * 0.5, width, y + totalTitleHeight * 0.5 + 4)
        cam.End3D2D()
    end)
end

function PLUGIN:PostDrawTranslucentRenderables(bDepth, bSkybox)
	if (bDepth or bSkybox or !LocalPlayer():GetCharacter()) then
		return
	end

	local entities = ents.FindInSphere(EyePos(), 256)
	local clientPosition = LocalPlayer():GetPos()

	for _, v in ipairs(entities) do
		if (!IsValid(v) or !v:IsDoor() or !v:GetNetVar("visible")) then
			continue
		end

		local color = v:GetColor()

		if (v:IsEffectActive(EF_NODRAW) or color.a <= 0) then
			continue
		end

		local position = v:LocalToWorld(v:OBBCenter())
		local mins, maxs = v:GetCollisionBounds()
		local width = 0
		local size = maxs - mins
		local trace = {
			collisiongroup = COLLISION_GROUP_WORLD,
			ignoreworld = true,
			endpos = position
		}

		-- trace from shortest side to center to get correct position for rendering
		if (size.z < size.x and size.z < size.y) then
			trace.start = position - v:GetUp() * size.z
			width = size.y
		elseif (size.x < size.y) then
			trace.start = position - v:GetForward() * size.x
			width = size.y
		elseif (size.y < size.x) then
			trace.start = position - v:GetRight() * size.y
			width = size.x
		end

		width = math.max(width, 12)
		trace = util.TraceLine(trace)

		local angles = trace.HitNormal:Angle()
		local anglesOpposite = trace.HitNormal:Angle()

		angles:RotateAroundAxis(angles:Forward(), 90)
		angles:RotateAroundAxis(angles:Right(), 90)
		anglesOpposite:RotateAroundAxis(anglesOpposite:Forward(), 90)
		anglesOpposite:RotateAroundAxis(anglesOpposite:Right(), -90)

		local positionFront = trace.HitPos - (((position - trace.HitPos):Length() * 2) + 1) * trace.HitNormal
		local positionOpposite = trace.HitPos + (trace.HitNormal * 2)

		if (trace.HitNormal:Dot((clientPosition - position):GetNormalized()) < 0) then
			-- draw front
			cam.Start3D2D(positionFront, angles, 0.1)
				self:DrawDoorInfo(v, width * 8, positionFront, angles, 0.1, clientPosition)
			cam.End3D2D()
		else
			-- draw back
			cam.Start3D2D(positionOpposite, anglesOpposite, 0.1)
				self:DrawDoorInfo(v, width * 8, positionOpposite, anglesOpposite, 0.1, clientPosition)
			cam.End3D2D()
		end
	end
end

net.Receive("ixDoorMenu", function()
	if (IsValid(ix.gui.door)) then
		return ix.gui.door:Remove()
	end

	local door = net.ReadEntity()
	local access = net.ReadTable()
	local entity = net.ReadEntity()

	if (IsValid(door)) then
		ix.gui.door = vgui.Create("ixDoorMenu")
		ix.gui.door:SetDoor(door, access, entity)
	end
end)

net.Receive("ixDoorPermission", function()
	local door = net.ReadEntity()

	if (!IsValid(door)) then
		return
	end

	local target = net.ReadEntity()
	local access = net.ReadUInt(4)

	local panel = door.ixPanel

	if (IsValid(panel) and IsValid(target)) then
		panel.access[target] = access

		for _, v in ipairs(panel.access:GetLines()) do
			if (v.player == target) then
				v:SetColumnText(2, L(ACCESS_LABELS[access or 0]))

				return
			end
		end
	end
end)
