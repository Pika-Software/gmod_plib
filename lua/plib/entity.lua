local list = list

local ENTITY = FindMetaTable( 'Entity' )

-- ENTITY:IsProp()
do

    list.Set( 'Prop Classes', 'prop_detail', true )
    list.Set( 'Prop Classes', 'prop_static', true )
    list.Set( 'Prop Classes', 'prop_physics', true )
    list.Set( 'Prop Classes', 'prop_ragdoll', true )
    list.Set( 'Prop Classes', 'prop_dynamic', true )
    list.Set( 'Prop Classes', 'prop_physics_override', true )
    list.Set( 'Prop Classes', 'prop_dynamic_override', true )
    list.Set( 'Prop Classes', 'prop_physics_multiplayer', true )

    function ENTITY:IsProp()
        if list.Get( 'Prop Classes' )[ self:GetClass() ] then
            return true
        end

        return false
    end

end

-- ENTITY:IsDoor()
do


    list.Set( 'Door Classes', 'prop_testchamber_door', true )
    list.Set( 'Door Classes', 'prop_door_rotating', true )
    list.Set( 'Door Classes', 'func_door_rotating', true )
    list.Set( 'Door Classes', 'func_door', true )

    function ENTITY:IsDoor()
        if list.Get( 'Door Classes' )[ self:GetClass() ] then
            return true
        end

        return false
    end

end

-- ENTITY:IsButton()
if (SERVER) then

    list.Set( 'Button Classes', 'momentary_rot_button', true )
    list.Set( 'Button Classes', 'func_rot_button', true )
    list.Set( 'Button Classes', 'func_button', true )
    list.Set( 'Button Classes', 'gmod_button', true )

    function ENTITY:IsButton()
        if list.Get( 'Button Classes' )[ self:GetClass() ] then
            return true
        end

        return false
    end

end
