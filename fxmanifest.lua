fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 's82_siren'
author 'S82 Studio · Peach Blossom City'
description 'S82 Siren - điều khiển đèn/còi xe cứu hộ (dựa trên Luxart Vehicle Control v3, GPLv3) + OISS Server Sided Sounds'
version '1.0.0'
license 'GPL-3.0-or-later'

ui_page 'web/index.html'

dependencies {
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'sirens.lua',
    'locales/*.lua',
    'shared.lua',
}

client_scripts {
    'client/tones.lua',
    'client/sound.lua',
    'client/hud.lua',
    'client/storage.lua',
    'client/main.lua',
    'client/sync.lua',
    'client/menu.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/fonts/*.woff2',
    'web/sounds/*.ogg',
    'web/sounds/**/*.ogg',

    -- ===== OISS Server Sided Audio =====
    'data/serversideaudio_sounds.dat54.rel',
    'data/serversideaudio_sounds.dat54.nametable',

    -- Bank ĐANG DÙNG trong sirens.lua (Config.AudioBanks)
    'dlc_serversideaudio/oiss_ssa_vehaud_lspd_new.awc',
    'dlc_serversideaudio/oiss_ssa_vehaud_lssd_new.awc',
    'dlc_serversideaudio/oiss_ssa_vehaud_bcso_new.awc',
    'dlc_serversideaudio/oiss_ssa_vehaud_sahp_new.awc',
    'dlc_serversideaudio/oiss_ssa_vehaud_fib_new.awc',
    'dlc_serversideaudio/oiss_ssa_vehaud_lsfd_new.awc',
    'dlc_serversideaudio/oiss_ssa_vehaud_bcfd_new.awc',

    -- Bank CHƯA DÙNG: bỏ comment dòng tương ứng + thêm vào Config.AudioBanks nếu muốn dùng
    -- (để comment giúp người chơi không phải tải thêm ~10MB không cần thiết)
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_lspd_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_lssd_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_bcso_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_sahp_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_sahp_bike.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_noose_new.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_noose_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_fib_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_rhpd_new.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_rhpd_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_dppd_new.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_dppd_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_lsia_new.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_lsia_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_lspp_new.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_lspp_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_lsfd_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_lscofd_new.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_lscofd_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_bcfd_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_sanfire_new.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_sanfire_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_sams_new.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_sams_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_usfs_new.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_usfs_old.awc',
    -- 'dlc_serversideaudio/oiss_ssa_vehaud_etc.awc',
}

data_file 'AUDIO_WAVEPACK' 'dlc_serversideaudio'
data_file 'AUDIO_SOUNDDATA' 'data/serversideaudio_sounds.dat'