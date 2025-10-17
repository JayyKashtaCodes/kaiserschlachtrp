local PLUGIN = PLUGIN or {}

PLUGIN.name = "Trash Collection System"
PLUGIN.author = "Dzhey Kashta"
PLUGIN.description = "Adds trash cans that can be spawned and automatically replaces matching map props with functional trash can entities."

-- The model to replace in the map
PLUGIN.trashCanModel = "models/props_junk/TrashDumpster02.mdl"
PLUGIN.trashCanEntity = "ix_trashcan"

if SERVER then
    -- Replace map props with our trash can entity
    function PLUGIN:InitPostEntity()
        local replaced = 0

        for _, ent in ipairs(ents.FindByModel(self.trashCanModel)) do
            if IsValid(ent) and ent:GetClass() == "prop_physics" then
                local pos = ent:GetPos()
                local ang = ent:GetAngles()
                ent:Remove()

                local newEnt = ents.Create(self.trashCanEntity)
                if IsValid(newEnt) then
                    newEnt:SetPos(pos)
                    newEnt:SetAngles(ang)
                    newEnt:Spawn()
                    replaced = replaced + 1
                end
            end
        end

        if replaced > 0 then
            print(string.format("[TrashCan] Replaced %d map props with trash can entities.", replaced))
        end
    end
end
