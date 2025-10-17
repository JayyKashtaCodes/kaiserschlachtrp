local PANEL = {}

local baseSizeW, baseSizeH = ScrW() / 5, 20

function PANEL:Init()
    self.message = markup.Parse("")
    self:SetSize(baseSizeW, baseSizeH)
    self.startTime = CurTime()
    self.endTime = CurTime() + ix.config.Get("notificationLifetime")
    self.backgroundImage = Material("vgui/notify/notificationback")
end

function PANEL:SetMessage(...)
    local msg = "<font=VintageFont18><color=0,0,0>"

    for k, v in ipairs({...}) do
        if type(v) == "table" then
            msg = msg.."<color="..v.r..","..v.g..","..v.b..">"
        elseif type(v) == "Player" then
            local col = team.GetColor(v:Team())
            msg = msg.."<color="..col.r..","..col.g..","..col.b..">"..tostring(v:Name()):gsub("<", "&lt;"):gsub(">", "&gt;").."</color>"
        else
            msg = msg..tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;")
        end
    end
    msg = msg.."</color></font>"

    self.message = markup.Parse(msg, baseSizeW-20)

    if self.message then
        local shiftHeight = self.message:GetHeight()
        self:SetHeight(shiftHeight + baseSizeH)
    else
        self:SetHeight(baseSizeH)
    end
    --surface.PlaySound("sfx/paper-2.wav")
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(self.backgroundImage)
    surface.DrawTexturedRect(0, 0, w, h)

    if self.message then
        self.message:Draw(10, 10, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local w2 = math.TimeFraction(self.startTime, self.endTime, CurTime()) * w
    surface.SetDrawColor(ix.config.Get("color"))
    surface.DrawRect(w2, h - 2, w - w2, 2)
end

vgui.Register("ixNotify", PANEL, "DPanel")
