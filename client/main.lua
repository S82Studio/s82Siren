Siren = {
    veh       = 0,       
    lastVeh   = 0,       
    emerg     = false,   
    land      = false,   
    trailer   = 0,
    keyLock   = false,
    lockPresses = Config.Lock.firstReminder,
    state     = { m = 0, p = 0, h = 0 },  
    indic     = 0,       
    dirty     = false,
    manu      = false,
    horn      = false,
    muteTemp  = false,   
    toneTemp  = 0,
    radioWheel = false,
    lastActivity = 0,
}

local IND_OFF, IND_L, IND_R, IND_H = 0, 1, 2, 3
local C = Config.Controls
local NON_LAND = { [14] = true, [15] = true, [16] = true, [21] = true }
local function notifyThirdParty()
    local s = Siren.state
    local data = {
        state_lxsiren = s.m, state_pwrcall = s.p, state_airmanu = s.h,
        state_indic = Siren.indic, actv_manu = Siren.manu, actv_horn = Siren.horn,
    }
    TriggerEvent('s82_siren:client:stateChanged', Siren.veh, data)
    TriggerEvent('lvc:UpdateThirdParty', data) -- tương thích script cũ dùng LVC
end

function Siren.Set(slot, tone)
    tone = tone or 0
    if Siren.state[slot] == tone then return end
    Siren.state[slot] = tone
    Sound.Apply(Siren.veh, Siren.state)
    Siren.dirty = true
    notifyThirdParty()
end

local function flush()
    if not Siren.dirty or Siren.veh == 0 then return end
    Siren.dirty = false
    if NetworkGetEntityIsNetworked(Siren.veh) then
        TriggerServerEvent('s82_siren:server:setState', VehToNet(Siren.veh), Siren.state)
    end
end

local function setIndicator(value)
    local veh = Siren.veh
    Siren.indic = value
    SetVehicleIndicatorLights(veh, 0, value == IND_R or value == IND_H)
    SetVehicleIndicatorLights(veh, 1, value == IND_L or value == IND_H)
    if NetworkGetEntityIsNetworked(veh) then
        TriggerServerEvent('s82_siren:server:setIndicator', VehToNet(veh), value)
    end
    notifyThirdParty()
end

local function resetActivity()
    Siren.lastActivity = GetGameTimer()
end

local function refreshHud()
    local s = Siren.state
    local sirenOn = s.m > 0 or s.p > 0 or Siren.muteTemp or Siren.manu
    Hud.Set('lights', Siren.veh ~= 0 and IsVehicleSirenOn(Siren.veh) or false)
    Hud.Set('siren', sirenOn)
    Hud.Set('tone', s.m > 0 and Tones.GetName(s.m) or (Siren.muteTemp and Tones.GetName(Siren.toneTemp)) or false)
    Hud.Set('aux', s.p > 0 and Tones.GetName(s.p) or false)
    Hud.Set('horn', s.h > 0)
    Hud.Set('lock', Siren.keyLock)
end
Siren.RefreshHud = refreshHud

local function onEnterEmergency(veh)
    SetVehicleHasMutedSirens(veh, true)

    if veh ~= Siren.lastVeh then
        Siren.lastVeh = veh
        Tones.Update(veh)
        Storage.Reset()
        Storage.Load()
    end
    local st = Entity(veh).state[S82_STATE_KEY]
    Siren.state = {
        m = st and tonumber(st.m) or Sound.Get(veh, 'm'),
        p = st and tonumber(st.p) or Sound.Get(veh, 'p'),
        h = 0,
    }
    Sound.Apply(veh, Siren.state)
    Siren.dirty = true

    if Sfx.radio then
        SetVehRadioStation(veh, 'OFF')
    end
    SetVehicleRadioEnabled(veh, Sfx.radio)
    resetActivity()
    refreshHud()
    Hud.SetTempHidden(false)
end

local function onLeave(veh, wasEmerg)
    Siren.manu, Siren.horn, Siren.muteTemp = false, false, false
    if wasEmerg and DoesEntityExist(veh) then
        Siren.state.h = 0
        if Config.Features.parkKill and Settings.parkKill then
            if not Settings.resetStandby and Siren.state.m > 0 then
                Tones.SetByID('MAIN_MEM', Siren.state.m)
            end
            Siren.state.m, Siren.state.p = 0, 0
        end
        Sound.Apply(veh, Siren.state)
        Siren.dirty = true
        flush()
    end
    Siren.veh, Siren.emerg, Siren.land = 0, false, false
    Hud.SetTempHidden(true)
    if Hud.moving then Hud.SetMoveMode(false) end
    if Menu and Menu.IsOpen() then Menu.Close() end
end

local function lockedPress()
    if IsDisabledControlJustReleased(0, C.horn) or IsDisabledControlJustReleased(0, C.aux)
        or IsDisabledControlJustReleased(0, C.siren) or IsDisabledControlJustReleased(0, C.lights) then
        if Siren.lockPresses % Config.Lock.reminderRate == 0 then
            Sfx.Play('Locked_Press', Sfx.volume.lockReminder, true)
            Notify(L('lock_reminder'))
        end
        Siren.lockPresses = Siren.lockPresses + 1
    end
end

local function startMainSiren()
    local tone
    if not Settings.resetStandby then
        local mem = Tones.Get('MAIN_MEM')
        local opt = Tones.GetOption(mem)
        if Tones.IsApproved(mem) and opt ~= 3 and opt ~= 4 then
            tone = mem
        else
            tone = Tones.Next(mem, true)
            Tones.SetByID('MAIN_MEM', tone)
        end
    else
        local first = Tones.AtPos(2)
        local opt = Tones.GetOption(first)
        tone = (opt == 3 or opt == 4) and Tones.Next(first, true) or first
    end
    Siren.Set('m', tone or 0)
end

local function emergencyFrame(veh, menuOpen)
    DisableControlAction(0, C.cycle, true)
    DisableControlAction(0, C.horn, true)
    DisableControlAction(0, C.aux, true)

    if Sfx.radio and IsControlPressed(0, C.radioWheel) then
        Siren.radioWheel = true
        SetControlNormal(0, C.lights, 1.0)
        return
    elseif Siren.radioWheel then
        Siren.radioWheel = false
        return
    end
    DisableControlAction(0, C.lights, true)

    local s = Siren.state
    local lightsOn = IsVehicleSirenOn(veh)

    if not lightsOn then
        if s.m > 0 then
            if not Settings.resetStandby then Tones.SetByID('MAIN_MEM', s.m) end
            Siren.Set('m', 0)
        end
        if s.p > 0 then Siren.Set('p', 0) end
        Siren.muteTemp = false
    end

    if IsPauseMenuActive() or UpdateOnscreenKeyboard() == 0 then return end

    if Siren.keyLock then
        lockedPress()
        Siren.manu, Siren.horn = false, false
    else

        if IsDisabledControlJustReleased(0, C.lights) then
            local turnOn = not lightsOn
            Sfx.Play(turnOn and 'On' or 'Off', turnOn and Sfx.volume.on or Sfx.volume.off)
            SetVehicleSiren(veh, turnOn)
            local _, trailer = GetVehicleTrailerVehicle(veh)
            if trailer and trailer ~= 0 then SetVehicleSiren(trailer, turnOn) end
            lightsOn = turnOn
            resetActivity()


        elseif IsDisabledControlJustReleased(0, C.siren) then
            if s.m == 0 and not Siren.muteTemp then
                if lightsOn then
                    Sfx.Play('Upgrade', Sfx.volume.upgrade)
                    startMainSiren()
                end
            else
                Sfx.Play('Downgrade', Sfx.volume.downgrade)
                local cur = Siren.muteTemp and Siren.toneTemp or s.m
                if not Settings.resetStandby and cur > 0 then Tones.SetByID('MAIN_MEM', cur) end
                Siren.muteTemp = false
                Siren.Set('m', 0)
            end
            resetActivity()


        elseif not menuOpen and IsDisabledControlJustReleased(0, C.aux) then
            if s.p == 0 then
                if lightsOn then
                    Sfx.Play('Upgrade', Sfx.volume.upgrade)
                    Siren.Set('p', Tones.Get('AUX') or 0)
                end
            else
                Sfx.Play('Downgrade', Sfx.volume.downgrade)
                Siren.Set('p', 0)
            end
            resetActivity()
        end

        if s.m > 0 and IsDisabledControlJustReleased(0, C.cycle) then
            Sfx.Play('Upgrade', Sfx.volume.upgrade)
            Siren.Set('m', Tones.Next(s.m, true))
            resetActivity()
        end

        local manu = s.m == 0 and not Siren.muteTemp and IsDisabledControlPressed(0, C.cycle)
        local horn = IsDisabledControlPressed(0, C.horn)
        if manu or horn then resetActivity() end
        Siren.manu, Siren.horn = manu, horn

        if Sfx.hornSfx then
            if IsDisabledControlJustPressed(0, C.horn) then Sfx.Play('Press', Sfx.volume.upgrade) end
            if IsDisabledControlJustReleased(0, C.horn) then Sfx.Play('Release', Sfx.volume.upgrade) end
        end
        if Sfx.manuSfx and s.m == 0 then
            if IsDisabledControlJustPressed(0, C.cycle) then Sfx.Play('Press', Sfx.volume.upgrade) end
            if IsDisabledControlJustReleased(0, C.cycle) then Sfx.Play('Release', Sfx.volume.upgrade) end
        end
    end

    local hm = 0
    if Siren.horn and not Siren.manu then
        hm = Tones.Get('ARHRN') or 0
    elseif Siren.manu and not Siren.horn then
        hm = Tones.Get('PMANU') or 0
    elseif Siren.manu and Siren.horn then
        hm = Tones.Get('SMANU') or 0
    end

    if Settings.airhornInterrupt then
        if Siren.horn and not Siren.manu then
            if s.m > 0 and not Siren.muteTemp then
                Siren.toneTemp = s.m
                Siren.muteTemp = true
                Siren.Set('m', 0)
            end
        elseif Siren.muteTemp then
            Siren.muteTemp = false
            if lightsOn then Siren.Set('m', Siren.toneTemp) end
        end
    end

    if s.h ~= hm then Siren.Set('h', hm) end
    refreshHud()
end

local hazardStart, hazardDone, indicTimer = nil, false, 0

local function indicatorFrame(veh, menuOpen)
    if IsPauseMenuActive() then return end
    local I = Config.Indicators

    if not menuOpen then
        if IsDisabledControlJustReleased(0, I.left) then
            setIndicator(Siren.indic == IND_L and IND_OFF or IND_L)
            indicTimer = 0
        elseif IsDisabledControlJustReleased(0, I.right) then
            setIndicator(Siren.indic == IND_R and IND_OFF or IND_R)
            indicTimer = 0
        end

        if IsControlJustPressed(0, I.hazard) and IsUsingKeyboard(0) then
            hazardStart, hazardDone = GetGameTimer(), false
        end
        if hazardStart then
            if not IsControlPressed(0, I.hazard) then
                hazardStart = nil
            elseif not hazardDone and GetGameTimer() - hazardStart >= I.hazardHold then
                hazardDone = true
                local on = Siren.indic ~= IND_H
                Sfx.Play(on and 'Hazards_On' or 'Hazards_Off', Sfx.volume.hazards, true)
                setIndicator(on and IND_H or IND_OFF)
            end
        end
    else
        hazardStart = nil
    end

    if I.autoCancel and (Siren.indic == IND_L or Siren.indic == IND_R) then
        if GetEntitySpeed(veh) < I.autoCancelSpeed then
            indicTimer = 0
        else
            indicTimer = indicTimer + GetFrameTime() * 1000
            if indicTimer >= I.autoCancelTime then
                indicTimer = 0
                setIndicator(IND_OFF)
            end
        end
    end
end

local function startDriverLoop(veh)
    CreateThread(function()
        local useIndic = Config.Indicators.enabled and Siren.land
        while Siren.veh == veh do
            local menuOpen = Menu and Menu.IsOpen() or false
            if Siren.emerg then
                emergencyFrame(veh, menuOpen)
                flush()
            end
            if useIndic then indicatorFrame(veh, menuOpen) end
            Wait(0)
        end
    end)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local isDriver = veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped
        if isDriver and GetIsTaskActive(ped, 2) then isDriver = false end
        if isDriver and veh ~= Siren.veh then
            if Siren.veh ~= 0 then onLeave(Siren.veh, Siren.emerg) end
            local class = GetVehicleClass(veh)
            Siren.veh = veh
            Siren.emerg = class == 18
            Siren.land = not NON_LAND[class]
            Siren.indic = tonumber(Entity(veh).state[S82_INDIC_KEY]) or IND_OFF
            if Siren.emerg then onEnterEmergency(veh) end
            if Siren.emerg or (Config.Indicators.enabled and Siren.land) then
                startDriverLoop(veh)
            end
        elseif not isDriver and Siren.veh ~= 0 then
            onLeave(Siren.veh, Siren.emerg)
        end

        Wait(Siren.veh ~= 0 and 250 or 500)
    end
end)

CreateThread(function()
    while true do
        local veh = Siren.veh
        if Siren.emerg and veh ~= 0 then
            Hud.SetTempHidden(IsHudHidden() or IsPauseMenuActive())

            if Hud.backlight == 1 then
                local _, lightsOn, highbeams = GetVehicleLightsState(veh)
                Hud.SetLit(lightsOn == 1 or lightsOn == true or highbeams == 1 or highbeams == true)
            end

            refreshHud()
            local interval = Sfx.reminderLookup[Sfx.reminderIndex]
            if interval and IsVehicleSirenOn(veh) and Siren.state.m == 0 and Siren.state.p == 0 then
                if GetGameTimer() - Siren.lastActivity >= interval then
                    Sfx.Play('Reminder', Sfx.volume.reminder)
                    resetActivity()
                end
            end
            Wait(500)
        else
            Wait(1000)
        end
    end
end)
RegisterCommand(Config.Commands.lock, function()
    if not Siren.emerg then return end
    Siren.keyLock = not Siren.keyLock
    Sfx.Play('Key_Lock', Sfx.volume.lock, true)
    Hud.Set('lock', Siren.keyLock)
    if not (Hud.show and not Hud.tempHidden) then
        Notify(Siren.keyLock and L('locked') or L('unlocked'))
    end
end, false)
RegisterKeyMapping(Config.Commands.lock, L('key_lock'), 'keyboard', Config.DefaultKeys.lock or '')

RegisterCommand(Config.Commands.debug, function()
    Config.Debug = not Config.Debug
    Notify(L('debug', { state = tostring(Config.Debug) }))
    if Config.Debug and Siren.veh ~= 0 then
        print(('^5[S82 Siren]^7 profile=%s tones=%s'):format(tostring(Tones.profile), json.encode(Tones.approved)))
    end
end, false)

CreateThread(function()
    if not Config.NumberKeyTones then return end
    local maxPos = 0
    for _, list in pairs(SIREN_ASSIGNMENTS) do
        if #list > maxPos then maxPos = #list end
    end
    maxPos = math.min(maxPos, 11)

    for pos = 2, maxPos do
        local n = pos - 1
        local cmd = '_s82siren_tone_' .. n
        RegisterCommand(cmd, function()
            if not Siren.emerg or Siren.keyLock or Siren.veh == 0 then return end
            if not IsVehicleSirenOn(Siren.veh) or pos > Tones.Count() then return end
            local tone = Tones.AtPos(pos)
            local opt = Tones.GetOption(tone)
            if opt ~= 1 and opt ~= 3 then return end
            if Siren.state.m ~= tone then
                Sfx.Play('Upgrade', Sfx.volume.upgrade)
                Siren.muteTemp = false
                Siren.Set('m', tone)
            else
                Sfx.Play('Downgrade', Sfx.volume.downgrade)
                Siren.Set('m', 0)
            end
            resetActivity()
        end, false)
        RegisterKeyMapping(cmd, L('key_tone', { n = n }), 'keyboard', n <= 9 and tostring(n) or '0')
    end
end)

exports('GetSirenState', function()
    return { vehicle = Siren.veh, main = Siren.state.m, aux = Siren.state.p, horn = Siren.state.h, indicator = Siren.indic, locked = Siren.keyLock }
end)
exports('IsLocked', function() return Siren.keyLock end)
