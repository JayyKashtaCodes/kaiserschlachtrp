local PLUGIN = PLUGIN

do
	hook.Add("InitializedConfig", "ixMoneyCommands", function()
		local MONEY_NAME = string.gsub(ix.util.ExpandCamelCase(ix.currency.plural), "%s", "")

		ix.command.Add("Give" .. MONEY_NAME, {
			alias = {"GiveMoney"},
			description = "@cmdGiveMoney",
			arguments = ix.type.number,
			OnRun = function(self, client, amount)
				-- Allow floats, but force positive
				amount = math.abs(tonumber(amount) or 0)

				if (amount <= 0) then
					return L("invalidArg", client, 1)
				end

				local data = {
					start = client:GetShootPos(),
					endpos = client:GetShootPos() + client:GetAimVector() * 96,
					filter = client
				}
				local target = util.TraceLine(data).Entity

				if (IsValid(target) and target:IsPlayer() and target:GetCharacter()) then
					if (not client:GetCharacter():HasMoney(amount)) then
						return
					end

					target:GetCharacter():GiveMoney(amount)
					client:GetCharacter():TakeMoney(amount)

					target:NotifyLocalized("moneyTaken", ix.currency.Get(amount))
					client:NotifyLocalized("moneyGiven", ix.currency.Get(amount))
				end
			end
		})

		ix.command.Add("CharSet" .. MONEY_NAME, {
			alias = {"CharSetMoney"},
			description = "@cmdCharSetMoney",
			superAdminOnly = true,
			arguments = {
				ix.type.character,
				ix.type.number
			},
			OnRun = function(self, client, target, amount)
				amount = tonumber(amount) or 0

				if (amount < 0) then
					return "@invalidArg", 2
				end

				target:SetMoney(amount)
				client:NotifyLocalized("setMoney", target:GetName(), ix.currency.Get(amount))
			end
		})

		local lastDropTime = {}

		ix.command.Add("Drop" .. MONEY_NAME, {
			alias = {"DropMoney"},
			description = "@cmdDropMoney",
			arguments = ix.type.number,
			OnRun = function(self, client, amount)
				local steamID = client:SteamID64()
				local now = CurTime()

				-- spam cooldown in seconds
				local cooldown = 1.5 

				if lastDropTime[steamID] and (now - lastDropTime[steamID] < cooldown) then
					return "You’re doing that too quickly. Please wait " ..
						string.format("%.1f", cooldown - (now - lastDropTime[steamID])) .. "s."
				end

				amount = math.abs(tonumber(amount) or 0)
				local minDropAmount = 0.01

				if (amount < minDropAmount) then
					return "@belowMinMoneyDrop", minDropAmount
				end

				if (not client:GetCharacter():HasMoney(amount)) then
					return "@insufficientMoney"
				end

				client:GetCharacter():TakeMoney(amount)

				local money = ix.currency.Spawn(client, amount)
				money.ixCharID = client:GetCharacter():GetID()
				money.ixSteamID = client:SteamID()

				lastDropTime[steamID] = now
			end
		})

	end)
end