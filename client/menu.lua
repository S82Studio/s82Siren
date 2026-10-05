Menu = {}

local isOpen = false
local stack = {}            
local confirming = nil      
local busy = false          
local current = nil         
local Pages = {}
local function sep(label) return { type = 'separator', label = label } end
local function renameTone(id)
    if not id or not SIRENS[id] or not Config.Features.sirenSettings then return end
    busy = true
    CreateThread(function()
        local name = Hud.KeyboardInput(L('rename_title', { tone = SIRENS[id].String }), Tones.GetName(id), 15)
        if name then
            Tones.Rename(id, name)
            Siren.RefreshHud()
        end
        busy = false
        Menu.Render()
    end)
end

local function confirmButton(id, label, desc, action)
    local waiting = confirming == id
    return {
        type = 'button', label = label,
        desc = waiting and L('confirm_desc') or desc,
        right = waiting and L('confirm') or nil,
        highlight = waiting,
        onSelect = function()
            if waiting then
                confirming = nil
                action()
            else
                confirming = id
            end
        end,
    }
end

local function toneList(kind, labelKey, descKey)
    local labels, values = Tones.MenuList()
    local pos = Tones.GetPos(Tones.Get(kind))
    if pos < 2 or #labels == 0 then return nil end
    return {
        type = 'list', label = L(labelKey), desc = L(descKey),
        options = labels, index = pos - 1,
        onChange = function(i) Tones.SetByID(kind, values[i]) end,
        onSelect = function() renameTone(Tones.Get(kind)) end,
    }
end

local function volumeSlider(key, labelKey, file, schemeless)
    return {
        type = 'slider', label = L(labelKey), desc = L('vol_desc'),
        value = math.floor((Sfx.volume[key] or 0) * 100 + 0.5), min = 0, max = 100, step = 2, suffix = '%',
        onChange = function(v) Sfx.volume[key] = v / 100 end,
        onSelect = function() Sfx.Play(file, Sfx.volume[key], schemeless) end,
    }
end

Pages.main = function()
    local F = Config.Features
    local items = {
        sep(L('sep_siren')),
        { type = 'button', label = L('siren_settings'), desc = L('siren_settings_desc'), submenu = 'siren' },
    }
    if F.customManualTones then
        items[#items + 1] = toneList('PMANU', 'primary_manu', 'primary_manu_desc')
        items[#items + 1] = toneList('SMANU', 'secondary_manu', 'secondary_manu_desc')
    end
    if F.customAuxTone then
        items[#items + 1] = toneList('AUX', 'aux_tone', 'aux_tone_desc')
    end
    if F.parkKill then
        items[#items + 1] = {
            type = 'checkbox', label = L('park_kill'), desc = L('park_kill_desc'), value = Settings.parkKill,
            onChange = function(v) Settings.parkKill = v end,
        }
    end
    items[#items + 1] = sep(L('sep_other'))
    items[#items + 1] = { type = 'button', label = L('hud'), desc = L('hud_desc'), submenu = 'hud' }
    items[#items + 1] = { type = 'button', label = L('audio'), desc = L('audio_desc'), submenu = 'audio' }
    items[#items + 1] = { type = 'button', label = L('storage'), desc = L('storage_desc'), submenu = 'storage' }
    items[#items + 1] = { type = 'button', label = L('info'), desc = L('info_desc'), submenu = 'info' }
    local out = {}
    for i = 1, #items do if items[i] then out[#out + 1] = items[i] end end
    return L('menu_main'), out
end

Pages.siren = function()
    local F = Config.Features
    local items = {}
    if F.airhornInterrupt then
        items[#items + 1] = {
            type = 'checkbox', label = L('airhorn_interrupt'), desc = L('airhorn_interrupt_desc'),
            value = Settings.airhornInterrupt, onChange = function(v) Settings.airhornInterrupt = v end,
        }
    end
    if F.resetStandby then
        items[#items + 1] = {
            type = 'checkbox', label = L('reset_standby'), desc = L('reset_standby_desc'),
            value = Settings.resetStandby, onChange = function(v) Settings.resetStandby = v end,
        }
    end
    if F.sirenSettings then
        items[#items + 1] = sep(L('sep_tones'))
        local opts = { L('opt_cycle_button'), L('opt_cycle'), L('opt_button'), L('opt_disabled') }
        for pos = 2, Tones.Count() do
            local id = Tones.AtPos(pos)
            items[#items + 1] = {
                type = 'list', label = Tones.GetName(id), desc = L('tone_desc'),
                options = opts, index = Tones.GetOption(id) or 1,
                onChange = function(i)
                    if i < 3 or Tones.IsOkayToDisable() then
                        Tones.SetOption(id, i)
                    else
                        Notify(L('unable_to_disable'))
                    end
                end,
                onSelect = function() renameTone(id) end,
            }
        end
    end
    return L('siren_settings'), items
end

Pages.hud = function()
    local on = Hud.show
    return L('hud'), {
        { type = 'checkbox', label = L('hud_enabled'), desc = L('hud_enabled_desc'), value = on,
          onChange = function(v) Hud.SetShow(v) end },
        { type = 'button', label = L('hud_move'), desc = L('hud_move_desc'), disabled = not on,
          onSelect = function() Menu.Close(); Hud.SetMoveMode(true) end },
        { type = 'slider', label = L('hud_scale'), desc = L('hud_scale_desc'), disabled = not on,
          value = math.floor(Hud.scale * 100 + 0.5), min = 50, max = 150, step = 5, suffix = '%',
          onChange = function(v) Hud.SetScale(v / 100) end },
        { type = 'list', label = L('hud_backlight'), desc = L('hud_backlight_desc'), disabled = not on,
          options = { L('bl_auto'), L('bl_off'), L('bl_on') }, index = Hud.backlight,
          onChange = function(i) Hud.SetBacklightMode(i) end },
        { type = 'button', label = L('hud_reset'), desc = L('hud_reset_desc'), disabled = not on,
          onSelect = function() Hud.ResetPosition() end },
    }
end

Pages.audio = function()
    local schemeIndex = 1
    for i, s in ipairs(Config.Sfx.schemes) do if s == Sfx.scheme then schemeIndex = i end end
    return L('audio'), {
        { type = 'checkbox', label = L('radio'), desc = L('radio_desc'), value = Sfx.radio,
          onChange = function(v)
              Sfx.radio = v
              if Siren.veh ~= 0 then SetVehicleRadioEnabled(Siren.veh, v) end
          end },
        sep(L('sep_sfx')),
        { type = 'list', label = L('sfx_scheme'), desc = L('sfx_scheme_desc'),
          options = Config.Sfx.schemes, index = schemeIndex,
          onChange = function(i)
              Sfx.scheme = Config.Sfx.schemes[i]
              Sfx.Play('Upgrade', Sfx.volume.upgrade)
          end },
        { type = 'checkbox', label = L('manu_sfx'), desc = L('manu_sfx_desc'), value = Sfx.manuSfx,
          onChange = function(v) Sfx.manuSfx = v end },
        { type = 'checkbox', label = L('horn_sfx'), desc = L('horn_sfx_desc'), value = Sfx.hornSfx,
          onChange = function(v) Sfx.hornSfx = v end },
        { type = 'list', label = L('reminder'), desc = L('reminder_desc'),
          options = { L('off'), '0.5', '1', '2', '5', '10' }, index = Sfx.reminderIndex,
          onChange = function(i) Sfx.reminderIndex = i; Siren.lastActivity = GetGameTimer() end },
        { type = 'button', label = L('volumes'), desc = L('volumes_desc'), submenu = 'volume' },
    }
end

Pages.volume = function()
    return L('volumes'), {
        volumeSlider('on', 'vol_on', 'On'),
        volumeSlider('off', 'vol_off', 'Off'),
        volumeSlider('upgrade', 'vol_upgrade', 'Upgrade'),
        volumeSlider('downgrade', 'vol_downgrade', 'Downgrade'),
        volumeSlider('reminder', 'vol_reminder', 'Reminder'),
        volumeSlider('hazards', 'vol_hazards', 'Hazards_On', true),
        volumeSlider('lock', 'vol_lock', 'Key_Lock', true),
        volumeSlider('lockReminder', 'vol_lock_reminder', 'Locked_Press', true),
    }
end

Pages.storage = function()
    local profile = tostring(Tones.profile or '-')
    local note = Tones.profile == 'DEFAULT' and (' ' .. L('default_profile_note')) or ''
    local saved = Storage.GetSavedProfiles()
    local save = confirmButton('save', L('save'), L('save_desc') .. note, function()
        if Storage.Save() then Notify(L('save_success', { profile = profile })) end
    end)
    save.right = save.right or profile
    local load = confirmButton('load', L('load'), L('load_desc') .. note, function()
        Storage.Load()
        Siren.RefreshHud()
        Notify(L('load_success'))
    end)
    load.right = load.right or profile
    return L('storage'), {
        save, load,
        sep(L('sep_advanced')),
        { type = 'button', label = L('copy'), desc = L('copy_desc'), submenu = 'copy', disabled = #saved == 0,
          right = tostring(#saved) },
        confirmButton('reset', L('reset'), L('reset_desc'), function()
            Storage.Reset()
            Siren.RefreshHud()
            Notify(L('reset_success'))
        end),
        confirmButton('factory', L('factory'), L('factory_desc'), function()
            Menu.Close()
            busy = true
            CreateThread(function()
                -- chờ nhả Enter để không tự xác nhận luôn
                repeat Wait(0) until not IsDisabledControlPressed(2, 201) and not IsDisabledControlPressed(0, 191)
                Wait(100)
                if Hud.Confirm(L('warning'), L('factory_confirm'), L('factory_options')) then
                    Storage.FactoryReset()
                end
                busy = false
            end)
        end),
    }
end

Pages.copy = function()
    local items = {}
    for _, name in ipairs(Storage.GetSavedProfiles()) do
        items[#items + 1] = confirmButton('copy:' .. name, name, L('copy_item_desc', { profile = name }), function()
            Storage.Load(name)
            Siren.RefreshHud()
            Notify(L('load_success'))
        end)
    end
    return L('copy'), items
end

Pages.info = function()
    local version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?'
    return L('info'), {
        { type = 'button', label = L('version'), desc = 'S82 Studio · Peach Blossom City', right = 'v' .. version },
        { type = 'button', label = L('vehicle_profile'), desc = L('vehicle_profile'), right = tostring(Tones.profile or '-') },
        { type = 'button', label = L('credits'), desc = L('credits_desc') },
    }
end
local function top() return stack[#stack] end
local function selectable(item)
    return item and item.type ~= 'separator' and not item.disabled
end
local function fixIndex(entry, dir)
    local n = #current
    if n == 0 then entry.index = 0 return end
    entry.index = math.max(1, math.min(entry.index, n))
    if selectable(current[entry.index]) then return end
    dir = dir or 1
    for _ = 1, n do
        entry.index = entry.index + dir
        if entry.index > n then entry.index = 1 elseif entry.index < 1 then entry.index = n end
        if selectable(current[entry.index]) then return end
    end
end

function Menu.Render()
    if not isOpen then return end
    local entry = top()
    local subtitle, items = Pages[entry.page]()
    current = items
    fixIndex(entry)

    local payload = {}
    for i, it in ipairs(items) do
        payload[i] = {
            type = it.type, label = it.label, right = it.right, disabled = it.disabled or false,
            submenu = it.submenu ~= nil, value = it.value, highlight = it.highlight or false,
            option = it.options and it.options[it.index] or nil,
            min = it.min, max = it.max, suffix = it.suffix,
        }
    end
    local cur = items[entry.index]
    Hud.Send('menu:render', {
        title = L('menu_title'), subtitle = subtitle, items = payload,
        index = entry.index, desc = cur and cur.desc or '',
    })
end

local function push(page)
    stack[#stack + 1] = { page = page, index = 1 }
    confirming = nil
    Menu.Render()
end

function Menu.Open()
    if isOpen then return end
    isOpen = true
    stack = {}
    Hud.Send('menu:open')
    push('main')
    Menu.Loop()
end

function Menu.Close()
    if not isOpen then return end
    isOpen = false
    stack, confirming, current = {}, nil, nil
    Hud.Send('menu:close')
end

function Menu.IsOpen() return isOpen end

local function back()
    confirming = nil
    if #stack <= 1 then
        Menu.Close()
    else
        stack[#stack] = nil
        Menu.Render()
    end
end

local function move(dir)
    local entry = top()
    if #current == 0 then return end
    confirming = nil
    entry.index = entry.index + dir
    if entry.index > #current then entry.index = 1 elseif entry.index < 1 then entry.index = #current end
    fixIndex(entry, dir)
    Sfx.Play('Press', 0.15)
    Menu.Render()
end

local function change(dir)
    local item = current and current[top().index]
    if not selectable(item) then return end
    if item.type == 'list' then
        local n = #item.options
        local i = item.index + dir
        if i > n then i = 1 elseif i < 1 then i = n end
        item.onChange(i)
    elseif item.type == 'slider' then
        local v = math.max(item.min, math.min(item.max, item.value + dir * item.step))
        if v == item.value then return end
        item.onChange(v)
    elseif item.type == 'checkbox' then
        item.onChange(not item.value)
    else
        return
    end
    Menu.Render()
end

local function choose()
    local item = current and current[top().index]
    if not selectable(item) then return end
    if item.submenu then
        push(item.submenu)
        return
    end
    if item.type == 'checkbox' then
        item.onChange(not item.value)
    elseif item.onSelect then
        item.onSelect()
    end
    if isOpen then Menu.Render() end
end

-- Lặp phím khi giữ
local held = {}
local function pressed(control)
    local now = GetGameTimer()
    if IsDisabledControlJustPressed(0, control) then
        held[control] = now + 350
        return true
    end
    if IsDisabledControlPressed(0, control) then
        if held[control] and now >= held[control] then
            held[control] = now + 70
            return true
        end
    else
        held[control] = nil
    end
    return false
end

local BLOCK = { 27, 99, 172, 173, 174, 175, 177, 191, 194, 199, 200, 201, 202, 14, 15, 16, 17 }

function Menu.Loop()
    CreateThread(function()
        while isOpen do
            for i = 1, #BLOCK do DisableControlAction(0, BLOCK[i], true) end
            if not busy and UpdateOnscreenKeyboard() ~= 0 then
                if pressed(172) then move(-1)
                elseif pressed(173) then move(1)
                elseif pressed(174) then change(-1)
                elseif pressed(175) then change(1)
                elseif IsDisabledControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 201) then choose()
                elseif IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 194)
                    or IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 202) then back()
                end
            end
            Wait(0)
        end
        local t = GetGameTimer() + 300
        while GetGameTimer() < t do
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 199, true)
            Wait(0)
        end
    end)
end

RegisterCommand(Config.Commands.menu, function()
    if isOpen then Menu.Close() return end
    if Siren.emerg and Siren.veh ~= 0 and not Siren.keyLock and not busy and UpdateOnscreenKeyboard() ~= 0 then
        Menu.Open()
    end
end, false)
RegisterKeyMapping(Config.Commands.menu, L('key_menu'), 'keyboard', Config.DefaultKeys.menu)
