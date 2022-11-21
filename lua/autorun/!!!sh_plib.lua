AddCSLuaFile( 'plib/functions.lua' )
include( 'plib/functions.lua' )

local string_format = string.format
local AddCSLuaFile = AddCSLuaFile
local file_Exists = file.Exists
local file_Find = file.Find
local file_Path = file.Path
local ArgAssert = ArgAssert
local SysTime = SysTime

local plibStopwatch = SysTime()

module( 'plib', package.seeall )

-- PLib Version
Version = 020000

-- Colors
do

    local colors = {}
    function GetColor( name )
        ArgAssert( name, 1, 'string' )
        return colors[ name ]
    end

    function SetColor( name, color )
        ArgAssert( name, 1, 'string' )
        local old = colors[ name ]
        if (old ~= nil) and (old.r ~= color.r and old.g ~= color.g and old.b ~= color.b and old.a ~= (color.a or 255)) then
            hook_Run( 'ColorUpdated', name, old, color )
        end

        colors[ name ] = color
    end

end

-- Default Colors
do

    local Color = Color

    -- Grey
    SetColor( 'light_grey', Color( 150, 150, 150, 255 ) )
    SetColor( 'dark_grey', Color( 20, 20, 20, 255 ) )
    SetColor( 'grey', Color( 50, 50, 50, 255 ) )

    -- White
    SetColor( 'dark_white', Color( 200, 200, 200, 255 ) )
    SetColor( 'white', Color( 255, 255, 255, 255 ) )

    -- Black
    SetColor( 'black', Color( 0, 0, 0, 255 ) )

    -- Blue
    SetColor( 'blue', Color( 50, 150, 200 ) )

    -- Orange
    SetColor( 'orange', Color( 200, 100, 50 ) )

end

-- Log
do

    local string_NetFormat = string.NetFormat
    local os_time = os.time
    local os_date = os.date

    function Log( level, str, ... )
        ArgAssert( level, 1, 'string' )
        ArgAssert( str, 2, 'string' )
        MsgC( GetColor( 'light_grey' ), os_date( '[%H:%M:%S]', os_time() ), GetColor( (SERVER) and 'blue' or 'orange' ), '[PLib/' .. level .. ']: ', GetColor( 'dark_white' ), string_NetFormat( str, ... ) .. '\n' )
    end

end

-- Logs
function Info( str, ... )
    Log( 'INFO', str, ... )
end

function Error( str, ... )
    Log( 'ERROR', str, ... )
end

function Warn( str, ... )
    Log( 'WARN', str, ... )
end

-- Include
do
    local CompileFile = CompileFile
    function Include( filePath )
        ArgAssert( filePath, 1, 'string' )
        if file_Exists( filePath, 'LUA' ) then
            local func = CompileFile( filePath )
            if isfunction( func ) then
                return pcall( func )
            else
                return false, 'File \'' .. filePath .. '\' assembly failed.'
            end
        else
            return false, 'File \'' .. filePath .. '\' does not exist.'
        end
    end
end

-- Modules
do

    -- Folders :x
    local modulesFolder = 'plib/modules'
    local clientModulesFolder = file_Path( modulesFolder, 'client' )
    local serverModulesFolder = file_Path( modulesFolder, 'server' )

    -- Server side jobs
    if (SERVER) then

        -- Shared
        for num, fl in ipairs( file_Find( file_Path( modulesFolder, '*' ), 'LUA' ) ) do
            AddCSLuaFile( file_Path( modulesFolder, fl ) )
        end

        -- Client
        for num, fl in ipairs( file_Find( file_Path( clientModulesFolder, '*' ), 'LUA' ) ) do
            AddCSLuaFile( file_Path( clientModulesFolder, fl ) )
        end

    end

    local modules = {}
    function IsModuleInstalled( moduleName )
        ArgAssert( moduleName, 1, 'string' )
        if (modules[ moduleName ] == nil) then
            return false
        end

        return true
    end

    do

        local table_insert = table.insert
        local pairs = pairs

        function ModulesInstalled()
            local modulesList = {}
            for moduleName, state in pairs( modules ) do
                if (state) then
                    table_insert( modulesList, moduleName )
                end
            end

            return modulesList
        end

    end

    do

        local isfunction = isfunction
        local pcall = pcall

        -- Web require function
        do

            local string_GetFileFromFilename = string.GetFileFromFilename
            local CompileString = CompileString

            function WebRequire( url, callback )
                ArgAssert( url, 1, 'string' )

                -- Stopwatch
                local startTime = SysTime()
                local moduleName = string_GetFileFromFilename( url )

                -- Re-installation lock
                if IsModuleInstalled( moduleName ) then return end

                -- Downloading & installing
                http.Fetch(url, function( luaCode, _, __, statusCode )
                    if (statusCode == 200) then
                        local func = CompileString( luaCode, url )
                        if isfunction( func ) then
                            local ok, result = pcall( func )
                            if (ok) then
                                Info( string_format( 'Web module \'{0}\' successfully installed. (Took %.4f seconds)', SysTime() - startTime ), moduleName )
                                if isfunction( callback ) then
                                    callback( ok, result )
                                end
                            else
                                Error( 'Web module \'{0}\' could not be installed.', moduleName )
                                if isfunction( callback ) then
                                    callback( false )
                                end

                                error( result )
                            end
                        else
                            Error( 'Web module \'{0}\' assembly failed.', moduleName )
                            if isfunction( callback ) then
                                callback( false )
                            end
                        end
                    else
                        Error( 'Web module \'{0}\' url is invalid.', moduleName )
                        if isfunction( callback ) then
                            callback( false )
                        end
                    end
                end,
                function( err )
                    Error( 'Web module \'{0}\' downloading error: {1}', moduleName, err )
                    if isfunction( callback ) then
                        callback( false )
                    end
                end)
            end

        end

        -- Require function
        do

            local file_IsDir = file.IsDir
            local error = error

            local SERVER = SERVER
            local CLIENT = CLIENT

            function Require( moduleName, noErros )
                ArgAssert( moduleName, 1, 'string' )

                -- Re-installation lock
                if IsModuleInstalled( moduleName ) then return end

                -- Stopwatch & empty path
                local startTime = SysTime()
                local filePath

                -- Client
                if (CLIENT) then
                    local clientFolder = file_Path( clientModulesFolder, moduleName )
                    if file_IsDir( clientFolder, 'LUA' ) then
                        filePath = file_Path( clientFolder, 'init.lua' )
                    end

                    local clientFile = file_Path( clientModulesFolder, moduleName .. '.lua' )
                    if file_Exists( clientFile, 'LUA' ) then
                        filePath = clientFile
                    end
                end

                -- Server
                if (SERVER) then
                    local serverFolder = file_Path( serverModulesFolder, moduleName )
                    if file_IsDir( serverFolder, 'LUA' ) then
                        filePath = file_Path( serverFolder, 'init.lua' )
                    end

                    local serverFile = file_Path( serverModulesFolder, moduleName .. '.lua' )
                    if file_Exists( serverFile, 'LUA' ) then
                        filePath = serverFile
                    end
                end

                -- Shared
                local sharedFolder = file_Path( modulesFolder, moduleName )
                if file_IsDir( sharedFolder, 'LUA' ) then
                    filePath = file_Path( sharedFolder, 'init.lua' )
                end

                if isnil( filePath ) then
                    filePath = file_Path( modulesFolder, moduleName .. '.lua' )
                end

                -- Including
                local ok, result = Include( filePath )
                if (ok) then
                    Info( string_format( 'Module \'' .. moduleName .. '\' successfully installed. (Took %.4f seconds)', SysTime() - startTime ) )
                    modules[ moduleName ] = true
                    return result
                else
                    if (noErros) then
                        return false
                    else
                        Error( 'Module \'{0}\' could not be installed.', moduleName )
                        error( result )
                    end
                end
            end

        end

    end

end

-- Addons
do

    -- Include Function
    function AddonInclude( filePath, addonName )
        ArgAssert( filePath, 1, 'string' )
        ArgAssert( addonName, 2, 'string' )

        -- Stopwatch
        local startTime = SysTime()

        -- Include
        local ok, err = Include( filePath )
        if (ok) then
            Info( string_format( 'Addon \'' .. addonName .. '\' successfully included. (Took %.4f seconds)', SysTime() - startTime ) )
        else
            Error( 'Addon \'' .. addonName .. '\' include failed: ' .. err )
        end
    end

    -- Folders x:
    local addonsFolder = 'plib/addons'
    local clientAddonsFolder = file_Path( addonsFolder, 'client' )
    local serverAddonsFolder = file_Path( addonsFolder, 'server' )

    -- Shared
    do

        local files, folders = file_Find( file_Path( addonsFolder, '*' ), 'LUA' )
        for num, fl in ipairs( files ) do
            local filePath = file_Path( addonsFolder, fl )
            if (SERVER) then
                AddCSLuaFile( filePath )
            end

            AddonInclude( filePath, string.sub( fl, 1, #fl - 4 ) .. ' (FILE)' )
        end

        for num, fol in ipairs( folders ) do
            local filePath = file_Path( addonsFolder, fol, 'init.lua' )
            if file_Exists( filePath, 'LUA' ) then
                if (SERVER) then
                    AddCSLuaFile( filePath )
                end

                AddonInclude( filePath, string.sub( fol, 1, #fol - 4 ) .. ' (FOLDER)' )
            end
        end

    end

    -- Client
    do

        local files, folders = file_Find( file_Path( clientAddonsFolder, '*' ), 'LUA' )
        for num, fl in ipairs( files ) do
            local filePath = file_Path( clientAddonsFolder, fl )
            if (SERVER) then
                AddCSLuaFile( filePath )
            else
                AddonInclude( filePath, string.sub( fl, 1, #fl - 4 ) .. ' (FILE)' )
            end
        end

        for num, fol in ipairs( folders ) do
            local filePath = file_Path( clientAddonsFolder, fol, 'init.lua' )
            if file_Exists( filePath, 'LUA' ) then
                if (SERVER) then
                    AddCSLuaFile( filePath )
                else
                    AddonInclude( filePath, string.sub( fol, 1, #fol - 4 ) .. ' (FOLDER)' )
                end
            end
        end

    end

    -- Server
    if (SERVER) then

        local files, folders = file_Find( file_Path( serverAddonsFolder, '*' ), 'LUA' )
        for num, fl in ipairs( files ) do
            AddonInclude( file_Path( serverAddonsFolder, fl ), string.sub( fl, 1, #fl - 4 ) .. ' (FILE)' )
        end

        for num, fol in ipairs( folders ) do
            local filePath = file_Path( serverAddonsFolder, fol, 'init.lua' )
            if file_Exists( filePath, 'LUA' ) then
                AddonInclude( filePath, string.sub( fol, 1, #fol - 4 ) .. ' (FOLDER)' )
            end
        end

    end

end

Info( string_format( 'PLib v{0} loaded. (Took %.4f seconds)', SysTime() - plibStopwatch ), string.Version( Version ) )