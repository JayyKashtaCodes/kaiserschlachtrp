local PLUGIN = PLUGIN

PLUGIN.bgPanel = PLUGIN.bgPanel or nil

net.Receive("SBMOpenMenu", function()
    local target = net.ReadPlayer()

    if IsValid(PLUGIN.bgPanel) then
        PLUGIN.bgPanel:Remove()
    end

    local panel = vgui.Create("ixCambiadorBodygroups")
    PLUGIN.bgPanel = panel
    panel:Fill(target)
end)
