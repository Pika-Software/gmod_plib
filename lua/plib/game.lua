local plib_Info = plib.plib_Info
local hook = hook

local ready = false
function game.IsReady()
    return ready
end

if (CLIENT) then

    local LocalPlayer = LocalPlayer
    local IsValid = IsValid

    hook.Add('RenderScene', 'Game Ready - CLIENT', function()
        local ply = LocalPlayer()
        if IsValid( ply ) then
            hook.Remove( 'RenderScene', 'Game Ready - CLIENT' )
            ready = true

            hook.Run( 'PlayerInitialized', ply )
            hook.Run( 'GameReady' )
            plib_Info( 'Game ready!' )
        end
    end)

    hook.Add('ShutDown', 'Game Ready - CLIENT', function()
        hook.Remove('ShutDown', 'Game Ready - CLIENT')

        local ply = LocalPlayer()
        if IsValid( ply ) then
            hook.Run( 'PlayerDisconnected', ply )
        end
    end)

end

if (SERVER) then

    timer.Simple(0, function()
        ready = true

        hook.Add('PlayerInitialSpawn', 'Game Ready - SERVER', function( ply )
            hook.Add('SetupMove', ply, function( self, _, mv, cmd )
                if (self == ply) and not cmd:IsForced() then
                    hook.Remove( 'SetupMove', self )
                    plib_Info( 'Player {0} ({1}) is fully initialized.', self:Nick(), self:IsBot() and 'BOT' or self:SteamID() )
                    self:SetNWBool( 'm_pInitialized', true )
                    hook.Run( 'PlayerInitialized', self )
                end
            end)
        end)

        plib_Info( 'Game is ready!')
        hook.Run( 'GameReady' )
    end)

end

local PLAYER = FindMetaTable( 'Player' )
if (PLAYER) then
    function PLAYER:Initialized()
        return self:GetNWBool( 'p_Initialized', false )
    end
end
