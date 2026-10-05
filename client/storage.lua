Settings = {
    airhornInterrupt = Config.Features.airhornInterruptDefault,
    resetStandby     = Config.Features.resetStandbyDefault,
    parkKill         = Config.Features.parkKillDefault,
}

Storage = {}

local PREFIX = ('s82siren_%s_'):format(Config.CommunityId or 'S82')
local SAVE_VERSION = 1

local function profileKey(name)
    return PREFIX .. 'profile_' .. tostring(name):gsub('%s', '_') .. '!'
end

local function audioKey(name)
    return PREFIX .. 'audio_' .. tostring(name):gsub('%s', '_')
end

local function decode(str)
    if not str or str == '' then return nil end
    local ok, res = pcall(json.decode, str)
    return ok and res or nil
end

function Storage.SaveHud()
    SetResourceKvp(PREFIX .. 'hud', json.encode({
        show = Hud.show, scale = Hud.scale, pos = Hud.pos, backlight = Hud.backlight,
    }))
end

function Storage.LoadHud()
    local d = decode(GetResourceKvpString(PREFIX .. 'hud'))
    if not d then return end
    if d.show ~= nil then Hud.SetShow(d.show) end
    if d.scale then Hud.SetScale(d.scale) end
    if type(d.pos) == 'table' then Hud.SetPosition(d.pos) end
    if d.backlight then Hud.SetBacklightMode(d.backlight) end
end

function Storage.Save()
    local profile = Tones.profile
    if not profile then return false end

    SetResourceKvpInt(PREFIX .. 'save_version', SAVE_VERSION)
    Storage.SaveHud()

    if Tones.customNames then
        local names = {}
        for id, name in pairs(Tones.names) do names[tostring(id)] = name end
        SetResourceKvp(PREFIX .. 'tone_names', json.encode(names))
    end

    local options = {}
    for id, opt in pairs(Tones.options) do options[tostring(id)] = opt end

    SetResourceKvp(profileKey(profile), json.encode({
        PMANU = Tones.Get('PMANU'),
        SMANU = Tones.Get('SMANU'),
        AUX   = Tones.Get('AUX'),
        airhornInterrupt = Settings.airhornInterrupt,
        resetStandby     = Settings.resetStandby,
        parkKill         = Settings.parkKill,
        options          = options,
    }))

    SetResourceKvp(audioKey(profile), json.encode({
        radio    = Sfx.radio,
        scheme   = Sfx.scheme,
        volume   = Sfx.volume,
        hornSfx  = Sfx.hornSfx,
        manuSfx  = Sfx.manuSfx,
        reminder = Sfx.reminderIndex,
    }))
    DebugPrint('Đã lưu profile ' .. profile)
    return true
end
function Storage.Load(profileName)
    Storage.LoadHud()

    local names = decode(GetResourceKvpString(PREFIX .. 'tone_names'))
    if names and Config.Features.sirenSettings then
        for id, name in pairs(names) do
            id = tonumber(id)
            if id and SIRENS[id] then Tones.names[id] = name end
        end
        Tones.customNames = next(Tones.names) ~= nil
    end

    profileName = profileName or Tones.profile
    if not profileName then return end

    local p = decode(GetResourceKvpString(profileKey(profileName)))
    if p then
        if p.PMANU then Tones.SetByID('PMANU', p.PMANU) end
        if p.SMANU then Tones.SetByID('SMANU', p.SMANU) end
        if p.AUX   then Tones.SetByID('AUX', p.AUX) end
        if Config.Features.sirenSettings then
            if p.airhornInterrupt ~= nil then Settings.airhornInterrupt = p.airhornInterrupt end
            if p.resetStandby ~= nil then Settings.resetStandby = p.resetStandby end
            if p.parkKill ~= nil then Settings.parkKill = p.parkKill end
            if type(p.options) == 'table' then
                for id, opt in pairs(p.options) do
                    id, opt = tonumber(id), tonumber(opt)
                    if id and opt and Tones.options[id] then Tones.SetOption(id, opt) end
                end
            end
        end
    end

    local a = decode(GetResourceKvpString(audioKey(profileName)))
    if a then
        if a.radio ~= nil then Sfx.radio = a.radio end
        if a.scheme then
            for _, s in ipairs(Config.Sfx.schemes) do
                if s == a.scheme then Sfx.scheme = a.scheme end
            end
        end
        if type(a.volume) == 'table' then
            for k, v in pairs(a.volume) do
                if Sfx.volume[k] ~= nil and tonumber(v) then Sfx.volume[k] = tonumber(v) end
            end
        end
        if a.hornSfx ~= nil then Sfx.hornSfx = a.hornSfx end
        if a.manuSfx ~= nil then Sfx.manuSfx = a.manuSfx end
        if tonumber(a.reminder) then Sfx.reminderIndex = tonumber(a.reminder) end
    end
end
function Storage.Reset()
    Siren.keyLock = false
    Settings.airhornInterrupt = Config.Features.airhornInterruptDefault
    Settings.resetStandby     = Config.Features.resetStandbyDefault
    Settings.parkKill         = Config.Features.parkKillDefault

    Hud.SetShow(Config.Hud.showByDefault)
    Hud.SetScale(Config.Hud.scale)
    Hud.ResetPosition()
    Hud.SetBacklightMode(1)

    Tones.ResetNames()
    Tones.ResetIds()
    Tones.BuildOptions()

    Sfx.radio, Sfx.hornSfx, Sfx.manuSfx, Sfx.reminderIndex = true, false, false, 1
    Sfx.scheme = Config.Sfx.default
    for k, v in pairs(Config.Sfx.volume) do Sfx.volume[k] = v end
end

function Storage.FactoryReset()
    local handle = StartFindKvp(PREFIX)
    local keys = {}
    repeat
        local key = FindKvp(handle)
        if key then keys[#keys + 1] = key end
    until not key
    EndFindKvp(handle)
    for _, key in ipairs(keys) do DeleteResourceKvp(key) end
    Storage.Reset()
    Notify(L('factory_success'))
end
function Storage.GetSavedProfiles()
    local list, seen = {}, {}
    local handle = StartFindKvp(PREFIX .. 'profile_')
    repeat
        local key = FindKvp(handle)
        if key then
            local name = key:match('profile_(.+)!$')
            if name and not seen[name] and name ~= Tones.profile then
                seen[name] = true
                list[#list + 1] = name
            end
        end
    until not key
    EndFindKvp(handle)
    table.sort(list)
    return list
end

RegisterCommand(Config.Commands.reset, function()
    CreateThread(function()
        repeat Wait(0) until not IsDisabledControlPressed(2, 201) and not IsDisabledControlPressed(0, 191)
        Wait(100)
        if Hud.Confirm(L('warning'), L('factory_confirm'), L('factory_options')) then
            Storage.FactoryReset()
        end
    end)
end, false)
