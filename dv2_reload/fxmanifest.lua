fx_version 'cerulean'
game 'gta5'

lua54 'yes'

description 'Reload owned ESX vehicles from database with /dv2'
author 'Codex'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    '@es_extended/imports.lua',
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependency 'es_extended'
