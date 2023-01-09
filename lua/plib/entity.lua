local ENTITY = FindMetaTable( 'Entity' )

-- ENTITY:IsProp()
do

    local propClasses = {
        ['prop_detail'] = true,
        ['prop_static'] = true,
        ['prop_physics'] = true,
        ['prop_ragdoll'] = true,
        ['prop_dynamic'] = true,
        ['prop_physics_override'] = true,
        ['prop_dynamic_override'] = true,
        ['prop_physics_multiplayer'] = true
    }

    function ENTITY:IsProp()
        if propClasses[ self:GetClass() ] then
            return true
        end

        return false
    end

end

-- ENTITY:IsDoor()
do

    local doorClasses = {
        ['prop_testchamber_door'] = true,
        ['prop_door_rotating'] = true,
        ['func_door_rotating'] = true,
        ['func_door'] = true
    }

    function ENTITY:IsDoor()
        if doorClasses[ self:GetClass() ] then
            return true
        end

        return false
    end

end