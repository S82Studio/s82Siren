Sound = {
    active = {},  
}

local SLOTS = { 'm', 'p', 'h' }
CreateThread(function()
    for _, bank in ipairs(Config.AudioBanks or {}) do
        local tries = 0
        while not RequestScriptAudioBank(bank, false) and tries < 50 do
            tries = tries + 1
            Wait(100)
        end
        if tries >= 50 then
            print(('^1[S82 Siren] Không load được audio bank %s (kiểm tra fxmanifest / file .awc)^7'):format(bank))
        else
            DebugPrint('Đã load audio bank ' .. bank)
        end
    end
end)

local function stopSlot(slot)
    StopSound(slot.id)
    ReleaseSoundId(slot.id)
end
---@param ent integer
---@param st table|nil
function Sound.Apply(ent, st)
    if not ent or ent == 0 then return end
    local slots = Sound.active[ent] or {}
    local exists = DoesEntityExist(ent) and not IsEntityDead(ent)

    for i = 1, 3 do
        local k = SLOTS[i]
        local want = exists and st and tonumber(st[k]) or 0
        local cur = slots[k]
        if (cur and cur.tone or 0) ~= want then
            if cur then stopSlot(cur); slots[k] = nil end
            local tone = want > 0 and SIRENS[want]
            if tone then
                local id = GetSoundId()
                PlaySoundFromEntity(id, tone.String, ent, tone.Ref, false, 0)
                slots[k] = { id = id, tone = want }
            end
        end
    end

    if next(slots) then
        Sound.active[ent] = slots
        SetVehicleHasMutedSirens(ent, true)
    else
        Sound.active[ent] = nil
    end
end

function Sound.Stop(ent)
    local slots = Sound.active[ent]
    if not slots then return end
    for _, s in pairs(slots) do stopSlot(s) end
    Sound.active[ent] = nil
end

function Sound.Get(ent, k)
    local slots = Sound.active[ent]
    return slots and slots[k] and slots[k].tone or 0
end
CreateThread(function()
    while true do
        for ent, slots in pairs(Sound.active) do
            if not DoesEntityExist(ent) or IsEntityDead(ent) then
                Sound.Stop(ent)
            elseif slots.h and IsVehicleSeatFree(ent, -1) then
                stopSlot(slots.h)
                slots.h = nil
                if not next(slots) then Sound.active[ent] = nil end
            end
        end
        if Config.DisableDistantSirens then DistantCopCarSirens(false) end
        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for ent in pairs(Sound.active) do Sound.Stop(ent) end
    for _, bank in ipairs(Config.AudioBanks or {}) do ReleaseNamedScriptAudioBank(bank) end
end)
