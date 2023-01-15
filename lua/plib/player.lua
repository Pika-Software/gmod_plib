do

    local hook = hook

    if (CLIENT) then

        local LocalPlayer = LocalPlayer
        local IsValid = IsValid

        hook.Add('InitPostEntity', 'PLib - Player Initialization', function()
            hook.Remove('InitPostEntity', 'PLib - Player Initialization')

            hook.Add('RenderScene', 'PLib - Player Initialization', function()
                local ply = LocalPlayer()
                if IsValid( ply ) then
                    hook.Remove('RenderScene', 'PLib - Player Initialization')
                    hook.Run( 'PlayerInitialized', ply )
                end
            end)
        end)

        hook.Add('ShutDown', 'PLib - Player Initialization', function()
            hook.Remove('ShutDown', 'PLib - Player Initialization')

            local ply = LocalPlayer()
            if IsValid( ply ) then
                hook.Run( 'PlayerDisconnected', ply )
            end
        end)

    end

    if (SERVER) then

        hook.Add('PlayerInitialSpawn', 'PLib - Player Initialization', function( pl )
            hook.Add('SetupMove', pl, function( self, ply, __, cmd )
                if (pl == self) and not cmd:IsForced() then
                    hook.Remove( 'SetupMove', self )
                    ply:SetNWBool( 'Fully Initialized', true )
                    hook.Run( 'PlayerInitialized', ply )
                end
            end)
        end)

    end

end

local PLAYER = FindMetaTable( 'Player' )

function PLAYER:Initialized()
    return self:GetNWBool( 'Fully Initialized', false )
end
