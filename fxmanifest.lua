fx_version 'cerulean'
game 'gta5'

author 'BloodLeak'
description 'BloodLeak v2 - Multicharacter System'
version '1.0.0'

shared_scripts {
    'config.lua',
    '@es_extended/imports.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
