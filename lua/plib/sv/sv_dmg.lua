-- Fixes for prop_vehicle_prisoner_pod (bullets only)

hook.Add("EntityTakeDamage", "PLib:ApplyDamageForce", function(ent, cdmg)
    if not IsValid(ent) then return end

    if ent["AcceptDamageForce"] or ent:GetClass() == "prop_vehicle_prisoner_pod" then
        ent:TakePhysicsDamage(cdmg)
    end 
end)

hook.Add("OnFireBulletCallback", "PLib:PrisonerTakeDamage", function(attk, tr, cdmg)
    local ent = tr["Entity"]
    if ent:IsValid() and ent:GetClass() == "prop_vehicle_prisoner_pod" then
        hook.Run("EntityTakeDamage", ent, cdmg)
    end
end)

hook.Add("EntityFireBullets", "PLib:BulletCallbackHook", function(ent, data)
    local old_callback = data["Callback"]
    function data.Callback(attk, tr, cdmg, ...)
        hook.Run("OnFireBulletCallback", attk, tr, cdmg, ...)
        if old_callback then return old_callback(attk, tr, cdmg, ...) end
    end
    return true
end)