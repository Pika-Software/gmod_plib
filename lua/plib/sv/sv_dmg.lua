-- Fixes for prop_vehicle_prisoner_pod

hook.Add("EntityTakeDamage", "PLib:ApplyDamageForce", function(ent, cdmg)
    if not IsValid(ent) then return end

    if ent["AcceptDamageForce"] or ent:GetClass() == "prop_vehicle_prisoner_pod" then
        ent:TakePhysicsDamage(cdmg)
    end 
end)

hook.Add("EntityFireBullets", "PLib:PrisonerDmgAccept", function(ent, data)
    local old_callback = data["Callback"]
    function data.Callback(attk, tr, cdmg, ...)
        local ent = tr["Entity"]
        if ent:IsValid() and ent:GetClass() == "prop_vehicle_prisoner_pod" then
            hook.Run("EntityTakeDamage", ent, cdmg)
        end
        if old_callback then return old_callback(attk, tr, cdmg, ...) end
    end
    return true
end)