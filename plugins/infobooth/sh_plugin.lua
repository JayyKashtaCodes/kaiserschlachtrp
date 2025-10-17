local PLUGIN = PLUGIN or {}

PLUGIN.name = "Information Booth"
PLUGIN.author = "DzheyKashta"
PLUGIN.description = "Adds a configurable information booth entity with modular topics and in-game editing."
PLUGIN.license = [[
MIT License

Copyright (c) 2025 DzheyKashta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

PLUGIN.defaultTopics = {
    { title = "Welcome", content = "Welcome to the server! Use this booth to learn more." },
    { title = "Rules", content = "1. Be respectful\n2. No RDM\n3. Follow staff instructions" }
}

if SERVER then
    util.AddNetworkString("ixInfoBooth_OpenView")
    util.AddNetworkString("ixInfoBooth_OpenEditor")
    util.AddNetworkString("ixInfoBooth_Update")
    util.AddNetworkString("ixInfoBooth_RequestEdit")
end


function PLUGIN:GetEntityTopics(ent)
    local topics = ent:GetNetVar("topics")
    if istable(topics) then
        return topics
    end
    return table.Copy(self.defaultTopics)
end

if SERVER then
    net.Receive("ixInfoBooth_RequestEdit", function(_, client)
        local ent = net.ReadEntity()
        if not (IsValid(ent) and ent:GetClass() == "ix_info_booth") then return end
        if not client:IsUA() then return end

        net.Start("ixInfoBooth_Open")
            net.WriteEntity(ent)
            net.WriteTable(PLUGIN:GetEntityTopics(ent))
            net.WriteBool(true)
        net.Send(client)
    end)

    net.Receive("ixInfoBooth_Update", function(_, client)
        if not client:IsUA() then return end

        local ent = net.ReadEntity()
        local topics = net.ReadTable()

        if not (IsValid(ent) and ent:GetClass() == "ix_info_booth") then return end
        if not istable(topics) then return end

        ent:SetNetVar("topics", topics)
        ix.data.Set("info_booth_" .. ent:EntIndex(), topics)

        client:Notify("Information booth updated.")
    end)
end

if CLIENT then
    -- View panel
    net.Receive("ixInfoBooth_OpenView", function()
        local ent = net.ReadEntity()
        local topics = net.ReadTable()

        if not vgui.GetControlTable("ixInfoBoothView") then
            print("[INFO] ixInfoBoothView panel not found!")
            return
        end

        local view = vgui.Create("ixInfoBoothView")
        view:SetTopics(topics)
    end)

    -- Editor panel
    net.Receive("ixInfoBooth_OpenEditor", function()
        local ent = net.ReadEntity()
        local topics = net.ReadTable()

        if not vgui.GetControlTable("ixInfoBoothEditor") then
            print("[INFO] ixInfoBoothEditor panel not found!")
            return
        end

        local editor = vgui.Create("ixInfoBoothEditor")
        print("[DEBUG] Created editor:", editor)
        editor:SetBooth(ent)
        editor:SetTopics(topics)
    end)
end

function PLUGIN:LoadData()
    for _, ent in ipairs(ents.FindByClass("ix_info_booth")) do
        local saved = ix.data.Get("info_booth_" .. ent:EntIndex())
        if istable(saved) then
            ent:SetNetVar("topics", saved)
        end
    end
end

function PLUGIN:SaveData()
    for _, ent in ipairs(ents.FindByClass("ix_info_booth")) do
        local topics = ent:GetNetVar("topics")
        if istable(topics) then
            ix.data.Set("info_booth_" .. ent:EntIndex(), topics)
        end
    end
end
