fx_version 'cerulean'
game 'gta5'


author 'ArkeologeN'
description 'DOJ Tablet'
version '1.0.0'

-- UI
ui_page 'web/build/index.html'

-- Shared Scripts
shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/*.lua',
    'shared/*.js'
}

-- Client Scripts
client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/*.js',
    'client/*.lua'
}

-- Server Scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.js',
    'server/*.lua'
}

-- Additional UI Assets
files {
    'web/build/index.html',
    'web/build/**/*'
} 

Lua54 'yes'