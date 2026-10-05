local function getEntity(bagName)
    local ent = GetEntityFromStateBagName(bagName)
    local tries = 0
    while ent == 0 and tries < 20 do
        Wait(50)
        tries = tries + 1
        ent = GetEntityFromStateBagName(bagName)
    end
    return ent
end

local function isMine(ent)
    return ent == Siren.veh and Siren.emerg
end

AddStateBagChangeHandler(S82_STATE_KEY, nil, function(bagName, _, value)
    if not bagName:find('^entity:') then return end
    CreateThread(function()
        local ent = getEntity(bagName)
        if ent == 0 or isMine(ent) then return end
        SetVehicleHasMutedSirens(ent, true)
        Sound.Apply(ent, value)
    end)
end)

AddStateBagChangeHandler(S82_INDIC_KEY, nil, function(bagName, _, value)
    if not Config.Indicators.enabled or not bagName:find('^entity:') then return end
    CreateThread(function()
        local ent = getEntity(bagName)
        if ent == 0 or ent == Siren.veh then return end
        value = tonumber(value) or 0
        SetVehicleIndicatorLights(ent, 0, value == 2 or value == 3)
        SetVehicleIndicatorLights(ent, 1, value == 1 or value == 3)
    end)
end)

CreateThread(function()
    while true do
        Wait(2000)
        local vehicles = GetGamePool('CVehicle')
        for i = 1, #vehicles do
            local ent = vehicles[i]
            if GetVehicleClass(ent) == 18 and not isMine(ent) and NetworkGetEntityIsNetworked(ent) then
                local st = Entity(ent).state[S82_STATE_KEY]
                if st then
                    SetVehicleHasMutedSirens(ent, true)
                    local want = {
                        m = tonumber(st.m) or 0,
                        p = tonumber(st.p) or 0,
                        h = IsVehicleSeatFree(ent, -1) and 0 or (tonumber(st.h) or 0),
                    }
                    if Sound.Get(ent, 'm') ~= want.m or Sound.Get(ent, 'p') ~= want.p or Sound.Get(ent, 'h') ~= want.h then
                        Sound.Apply(ent, want)
                    end
                end
            end
        end
    end
end)
