local PLUGIN = PLUGIN

function PLUGIN:BankingCanCreateAccount(client)
    if CLIENT then
        client = LocalPlayer()
    end

    local char = client:GetCharacter()
    if char then
        if #ix.banking.GetOwnedAccounts(char) >= ix.config.Get("bankingMaxAccounts", 3) then
            return false, "bankingNotifyMaxAccountsReached"
        end
    end
end