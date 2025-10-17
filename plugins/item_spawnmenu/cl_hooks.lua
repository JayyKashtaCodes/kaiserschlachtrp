local icons = {
	["Ammunition"] = "bomb",
	["Clothing"] = "user_suit",
	["Consumables"] = "cake",
	["Crafting"] = "cog",
    ["Filing"] = "page_white_text",
	["Literature"] = "book",
	["Medical"] = "heart",
    ["Objects"] = "box",
    ["Permits"] = "page_key",
	["Storage"] = "package",
	["Security"] = "lock",
	["Tools"] = "wrench",
	["Weapons"] = "gun",
    ["misc"] = "bricks",
}

function PLUGIN:PopulateItems(pnlContent, tree, node)
	local Items = ix.item.list
	local Categorised = {}

	for k, v in pairs(Items) do
		local Category = v.category or "misc"

		Categorised[Category] = Categorised[Category] or {}
		table.insert(Categorised[ Category ], v)
	end

	Items = nil

	for k, v in SortedPairs(Categorised) do
        local icon = icons[k] and "icon16/" .. icons[k] .. ".png" or "icon16/brick.png"

		local node = tree:AddNode(k, icon)
		node.DoPopulate = function(self)
			if (self.PropPanel) then return end

			self.PropPanel = vgui.Create("ContentContainer", pnlContent)
			self.PropPanel:SetVisible(false)
			self.PropPanel:SetTriggerSpawnlistChange(false)

			for k2, v2 in SortedPairsByMemberValue(v, "name") do
				spawnmenu.CreateContentIcon("item", self.PropPanel, {
					name = v2.name or v2.uniqueID,
					uniqueid = v2.uniqueID,
					model = v2.model,
					skin = v2.skin or 0
				})
			end
		end
		node.DoClick = function(self)
			self:DoPopulate()
			pnlContent:SwitchPanel(self.PropPanel)
		end
	end

	local FirstNode = tree:Root():GetChildNode(0)
	if IsValid(FirstNode) then
		FirstNode:InternalDoClick()
	end
end