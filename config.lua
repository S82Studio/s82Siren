Config = {}
Config.CommunityId = 'PBCITY'
Config.Locale = 'vi'
Config.Debug = false
Config.Commands = {
    menu  = 's82siren',          -- mở menu
    lock  = 's82sirenlock',      -- khóa / mở khóa hộp điều khiển
    debug = 's82sirendebug',
    reset = 's82sirenreset',     -- xóa toàn bộ dữ liệu đã lưu của người chơi
}

Config.DefaultKeys = {
    menu = 'F5',
    lock = '',                   -- để trống = người chơi tự gán
}
Config.NumberKeyTones = true
Config.Controls = {
    lights     = 85,   -- Q    : bật/tắt đèn ưu tiên
    siren      = 19,   -- L-ALT: bật/tắt còi chính
    cycle      = 80,   -- R    : đổi tone (giữ khi tắt còi = còi tay)
    horn       = 86,   -- E    : kèn hơi (airhorn)
    aux        = 172,  -- ↑    : còi phụ (powercall)
    radioWheel = 243,  -- ~    : giữ để mở vòng radio
}
Config.Indicators = {
    enabled         = true,
    left            = 84,   -- phím -
    right           = 83,   -- phím =
    hazard          = 202,  -- Backspace (giữ)
    hazardHold      = 750,  -- ms phải giữ để bật/tắt đèn khẩn cấp
    autoCancel      = true, -- tự tắt xi nhan sau khi chạy thẳng
    autoCancelSpeed = 6.0,  -- m/s
    autoCancelTime  = 3000, -- ms chạy trên tốc độ trên thì tự tắt
}
Config.Lock = {
    firstReminder = 5,  -- nhắc lần đầu sau N lần bấm khi đang khóa
    reminderRate  = 10, -- sau đó cứ N lần nhắc 1 lần
}
---------------------------------------------------------------------
-- TÍNH NĂNG (masterswitch = cho phép người chơi chỉnh trong menu)
---------------------------------------------------------------------
Config.Features = {
    sirenSettings            = true,  -- đổi tên tone, chế độ tone (Cycle/Button)
    parkKill                 = true,
    parkKillDefault          = false, -- tắt còi khi xuống xe
    airhornInterrupt         = true,
    airhornInterruptDefault  = true,  -- bấm kèn sẽ ngắt còi chính tạm thời
    resetStandby             = true,
    resetStandbyDefault      = true,  -- bật lại còi luôn về tone đầu
    customManualTones        = true,
    customAuxTone            = true,
}

Config.DisableDistantSirens = true
Config.Hud = {
    showByDefault = true,
    scale         = 1.0,
}
Config.Sfx = {
    schemes = { 'SSP2000', 'SSP3000', 'Cencom', 'ST300' },
    default = 'SSP2000',
    volume = {
        on            = 0.5,
        off           = 0.7,
        upgrade       = 0.5,
        downgrade     = 0.7,
        hazards       = 0.09,
        lock          = 0.25,
        lockReminder  = 0.2,
        reminder      = 0.09,
    },
}

Config.Notify = function(text)
    local nType = 'inform'
    if text:find('~r~') then nType = 'error'
    elseif text:find('~g~') then nType = 'success'
    elseif text:find('~y~') or text:find('~o~') then nType = 'warning' end
    text = text:gsub('~%a~', ''):gsub('%s+', ' ')

    lib.notify({
        title       = 'S82 Siren',
        description = text,
        type        = nType,
        icon        = 'tower-broadcast',
        position    = 'top-right',
        duration    = 4000,
    })
end

---------------------------------------------------------------------
-- BẢO VỆ SERVER: số event tối đa mỗi người chơi / giây
---------------------------------------------------------------------
Config.ServerRateLimit = 25