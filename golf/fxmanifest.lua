ui_page 'oof/client/ui/index.html'

client_scripts {
    -- oof module, nothing should precede this module
    'oof/shared/game/IsRedM.lua',
    'oof/shared/lua-overloads/*.lua',
    'oof/shared/lua-additions/*.lua',
    'oof/shared/object-oriented/class.lua', -- no class instances on initial frame before this file
    'oof/shared/object-oriented/shGetterSetter.lua', -- getter_setter, getter_setter_encrypted
    'oof/shared/object-oriented/shObjectOrientedUtilities.lua', -- is_class_instance
    'oof/shared/standalone-data-structures/*', -- Enum, IdPool
    'oof/shared/math/*.lua',
    '**/shared/enums/*Enum.lua', -- load all Enums
    '**/client/enums/*Enum.lua',
    'oof/shared/events/*.lua', -- Events class
    'oof/client/network/*.lua', -- Network class
    'oof/shared/value-storage/*.lua', -- ValueStorage class
    'oof/client/typecheck/*.lua', -- TypeCheck class
    'oof/client/asset-requester/*.lua',
    'oof/shared/timer/*.lua', -- Timer class
    'oof/client/entity/*.lua', -- Entity class
    'oof/client/player/cPlayer.lua',
    'oof/client/player/cPlayers.lua',
    'oof/client/player/cPlayerManager.lua',
    'oof/client/ped/*.lua', -- Ped class
    'oof/client/physics/*.lua',
    'oof/client/localplayer/*.lua', -- LocalPlayer class
    'oof/shared/color/*.lua',
    'oof/client/render/*.lua',
    'oof/client/camera/*.lua', -- Camera class
    'oof/client/blip/*.lua', -- Blip class
    'oof/client/object/*.lua', -- Object, ObjectManager classes
    'oof/client/screen-effects/*.lua', -- ScreenEffects class
    'oof/client/world/*.lua',
    'oof/client/sound/*.lua', -- Sound class
    'oof/client/light/*.lua', -- Light class
    'oof/client/particle-effect/*.lua', -- ParticleEffect class
    'oof/client/anim-post-fx/*.lua', -- AnimPostFX class
    'oof/client/volume/*.lua', -- Volume class
    'oof/client/explosion/*.lua', -- Explosion class
    'oof/client/pause-menu/*.lua', -- PauseMenu class
    'oof/client/hud/*.lua', -- HUD class
    'oof/client/keypress/*.lua',
    'oof/client/prompt/*.lua', -- Prompt class
    'oof/client/map/*.lua', -- Imap/Ipl class
    'oof/client/marker/*.lua', -- Marker class
    'oof/client/apitest.lua',
    'gameplay/shared/shTest.lua',
    -- ui
    'oof/client/ui/ui.lua',
    'oof/client/localplayer_behaviors/*.lua',
    'gameplay/client/localplayer_behaviors/*.lua',
    'oof/client/weapons/*.lua',
    -- events module
    'events/client/cDefaultEvents.lua',
    'events/shared/shTick.lua',
    -- sounds
    'stream/sounds/loader.lua',
    -- logo
    'logo/client/discord.lua',
    -- lobby
    'lobby/client/cLobbyManager.lua',
    -- game
    'gameplay/shared/shConfig.lua',
    'gameplay/client/cSpawnStrategy.lua',
    'gameplay/client/spawning_strategies/*.lua',
    'gameplay/client/cSpawnManager.lua',
    'gameplay/client/cGameManager.lua',
    'gameplay/client/cPlayerLauncher.lua',
    'gameplay/client/ui/cGamePlayUI.lua',
    'gameplay/client/ui/cIconManager.lua',
    'gameplay/client/ui/cScreenIcon.lua',
    'gameplay/client/cHolePlacer.lua',
    'gameplay/client/cGolfClub.lua',
    'gameplay/client/pickups/*.lua',
    'gameplay/client/powerups/*.lua',
    'gameplay/client/cCameraMod.lua',
    'gameplay/client/cUfo.lua',
    'oof/client/spectate/*.lua', -- spectate mode
    'gameplay/client/map_mods/*.lua',
    -- pausemenu edits
    'gameplay/client/cPauseMenu.lua',
    -- blackscreen
    'blackscreen/client/BlackScreen.lua',
    -- chat
    'chat/shared/shChatUtility.lua',
    'chat/client/cChat.lua',
    -- tips
    'tips/client/Tips.lua',
    -- sounds
    'sounds/client/Sounds.lua',
    -- object editor
    'object-editor/client/cObjectEditor.lua',
    -- anticheat
    'anticheat/client/*.lua',
    -- LOAD LAST
    'oof/shared/object-oriented/LOAD_ABSOLUTELY_LAST.lua'
}

server_scripts {
    -- api module, nothing should precede this module
    'oof/shared/game/IsRedM.lua',
    'oof/server/sConfig.lua',
    'oof/shared/lua-overloads/*.lua',
    'oof/shared/lua-additions/*.lua',
    'oof/shared/object-oriented/class.lua', -- no class instances on initial frame before this file
    'oof/shared/object-oriented/shGetterSetter.lua',
    'oof/shared/object-oriented/shObjectOrientedUtilities.lua', -- is_class_instance
    'oof/shared/math/*.lua',
    'oof/shared/standalone-data-structures/*', -- Enum, IdPool
    '**/shared/enums/*Enum.lua', -- load all the enums from all the modules
    '**/server/enums/*Enum.lua',
    'oof/shared/color/*.lua',
    'oof/shared/events/*.lua', -- Events class
    'oof/server/network/*.lua', -- Network class
    'oof/server/json/*.lua', -- JsonOOF, JsonUtils classes
    -- mysql enabler
    'oof/server/mysql-async/MySQLAsync.net.dll',
    'oof/server/mysql-async/lib/init.lua',
    'oof/server/mysql-async/lib/MySQL.lua',
    -- mysql wrapper
    'oof/server/mysql/MySQL.lua',
    'oof/server/key-value-store/*.lua',
    'oof/shared/value-storage/*.lua', -- ValueStorage class
    'oof/shared/timer/*.lua', -- Timer class
    'oof/server/player/sPlayer.lua', -- Player class
    'oof/server/player/sPlayers.lua', -- Players class
    'oof/server/player/sPlayerManager.lua', -- PlayerManager class
    'oof/server/world/*.lua', -- World class
    -- events module
    'events/server/sDefaultEvents.lua',
    'events/shared/shTick.lua',
    -- courses
    'gameplay/shared/shCourse.lua',
    'gameplay/shared/shCourses.lua',
    -- lobby
    'lobby/server/*.lua',
    'lobby/server/shop/*.lua',
    -- gameplay
    'gameplay/server/config.lua',
    'gameplay/shared/shConfig.lua',
    'gameplay/server/sWaveDelegator.lua',
    'gameplay/server/wave-delegators/*.lua',
    'gameplay/server/*.lua',
    'gameplay/server/powerups/*.lua',
    -- chat
    'chat/server/config.lua',
    'chat/shared/shChatUtility.lua',
    'gameplay/shared/shTest.lua',
    'chat/server/sChat.lua',
    -- object-editor
    'object-editor/server/sObjectEditor.lua',
    -- anticheat
    'anticheat/server/*.lua',
    'oof/shared/object-oriented/LOAD_ABSOLUTELY_LAST.lua'
}

files {
    -- general ui
    'oof/client/ui/reset.css',
    'oof/client/ui/jquery.js',
    'oof/client/ui/events.js',
    'oof/client/ui/index.html',
    'lobby/client/html/fonts/Kirsty.ttf',
    'lobby/client/html/fonts/KirstyB.ttf',
    'lobby/client/html/fonts/MainTitles.ttf',
    -- loadscreen module
    'loadscreen/client/html/index.html',
    'loadscreen/client/html/bg.jpg',
    'loadscreen/client/html/style.css',
    'loadscreen/client/html/script.js',
    -- logo ui
    'logo/client/html/index.html',
    'logo/client/html/logo.png',
    -- lobby
    'lobby/client/html/index.html',
    'lobby/client/html/script.js',
    'lobby/client/html/style.css',
    'lobby/client/html/selectmenu.css',
    'lobby/client/html/images/question.png',
    'lobby/client/html/images/*.jpg',
    'lobby/client/html/images/shop/*.JPG',
    -- gameplay
    'gameplay/client/ui/html/index.html',
    'gameplay/client/ui/html/scoreboard.html',
    'gameplay/client/ui/html/script.js',
    'gameplay/client/ui/html/scoreboard_script.js',
    'gameplay/client/ui/html/style.css',
    'gameplay/client/ui/html/imgs/*.png',
    -- blackscreen
    'blackscreen/client/html/index.html',
    'blackscreen/client/html/style.css',
    'blackscreen/client/html/script.js',
    -- tips
    'tips/client/html/index.html',
    'tips/client/html/script.js',
    'tips/client/html/style.css',
    -- sounds
    'sounds/client/ui/index.html',
    'sounds/client/ui/script.js',
    'sounds/client/ui/sounds/*.ogg',
    -- chat
    'chat/client/ui/index.html',
    'chat/client/ui/script.js',
    'chat/client/ui/style.css'
}

fx_version 'adamant'
games { 'rdr3', 'gta5' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'