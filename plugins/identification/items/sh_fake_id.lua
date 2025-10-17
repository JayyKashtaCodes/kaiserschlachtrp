local PLUGIN = PLUGIN

ITEM.name = "Fake Identification"
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.description = "A fake identification document."
ITEM.category = "Documents"
ITEM.uniqueID = "fake_id"
ITEM.category = "Identification"

-- Default starting data (blank fields)
ITEM.data = {
    fields = {
        name       = "",
        dob        = "",
        pob        = "",
        blood      = "",
        ethnicity  = "",
        height     = "",
        weight     = "",
        hairColour = "",
        eyeColour  = "",
        rank       = "",
        job        = ""
    }
}

if CLIENT then
    function ITEM:PopulateTooltip(tooltip)
        local data = self:GetData("fields", {})
        local row = tooltip:AddRow("name")
        row:SetText(data.name ~= "" and data.name or "No Name Set")
        row:SizeToContents()
    end
end

-- Opens editable identification panel
ITEM.functions.Edit = {
    name = "Edit Identification",
    icon = "icon16/pencil.png",
    OnRun = function(item)
        local ply = item.player
        if not IsValid(ply) then return false end

        netstream.Start(ply, "ixEditID", {
            itemID = item:GetID(),
            fields = item:GetData("fields", {}),
            model  = ply:GetModel()
        })

        return false
    end
}

-- View your own identification (read‑only)
ITEM.functions.View = {
    name = "View",
    icon = "icon16/vcard.png",
    OnRun = function(item)
        local ply = item.player
        if not IsValid(ply) then return false end

        netstream.Start(ply, "ixViewID", {
            fields = item:GetData("fields", {}),
            model  = ply:GetModel()
        })

        return false
    end,
    OnCanRun = function(item)
        -- Only in inventory, not while it's an entity in the world
        return not IsValid(item.entity) and IsValid(item.player)
    end
}

-- Show your identification to a nearby player
ITEM.functions.Show = {
    name = "Show",
    icon = "icon16/user_go.png",
    OnRun = function(item)
        local ply = item.player
        if not IsValid(ply) then return false end

        local tr = ply.GetEyeTraceNoCursor and ply:GetEyeTraceNoCursor() or ply:GetEyeTrace()
        local target = (IsValid(tr.Entity) and tr.Entity:IsPlayer()) and tr.Entity or nil

        local MAX_DIST = 128
        if not IsValid(target) or target:GetPos():DistToSqr(ply:GetPos()) > (MAX_DIST * MAX_DIST) then
            if ply.Notify then ply:Notify("Look at a nearby player to show your identification.") end
            return false
        end

        netstream.Start(target, "ixViewID", {
            fields  = item:GetData("fields", {}),
            model   = ply:GetModel(),
            shownBy = (ply:GetCharacter() and ply:GetCharacter():GetName()) or ply:Nick()
        })

        if ply.Notify then
            ply:Notify("You show your identification to " .. (target:Name() or "someone") .. ".")
        end

        return false
    end,
    OnCanRun = function(item)
        return not IsValid(item.entity) and IsValid(item.player)
    end
}
