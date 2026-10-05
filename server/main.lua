local rate = {}          
local lastVehicle = {}   

local function allow(src)
    local now = os.time()
    local r = rate[src]
    if not r or r.t ~= now then
        rate[src] = { t = now, n = 1 }
        return true
    end
    r.n = r.n + 1
    return r.n <= Config.ServerRateLimit
end

local function getDriverVehicle(src, netId)
    if math.type(netId) ~= 'integer' then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return end

    local ped = GetPlayerPed(src)
    local driver = GetPedInVehicleSeat(veh, -1)
    if driver == ped then
        lastVehicle[src] = netId
        return veh
    end
    if lastVehicle[src] == netId and (driver == 0 or not DoesEntityExist(driver)) then
        return veh
    end
end

local function toTone(v)
    v = math.tointeger(tonumber(v) or 0) or 0
    return IsValidTone(v) and v or 0
end

RegisterNetEvent('s82_siren:server:setState', function(netId, data)
    local src = source
    if not allow(src) or type(data) ~= 'table' then return end
    local veh = getDriverVehicle(src, netId)
    if not veh then return end

    local state = Entity(veh).state
    local new = { m = toTone(data.m), p = toTone(data.p), h = toTone(data.h) }
    local old = state[S82_STATE_KEY]
    if old and old.m == new.m and old.p == new.p and old.h == new.h then return end
    state:set(S82_STATE_KEY, new, true)
end)

RegisterNetEvent('s82_siren:server:setIndicator', function(netId, value)
    local src = source
    if not Config.Indicators.enabled or not allow(src) then return end
    value = math.tointeger(tonumber(value) or 0) or 0
    if value < 0 or value > 3 then return end
    local veh = getDriverVehicle(src, netId)
    if not veh then return end

    local state = Entity(veh).state
    if state[S82_INDIC_KEY] == value then return end
    state:set(S82_INDIC_KEY, value, true)
end)

AddEventHandler('playerDropped', function()
    rate[source] = nil
    lastVehicle[source] = nil
end)

CreateThread(function()
    Wait(500)
    local res = GetCurrentResourceName()
    print(('^5[S82 Siren]^7 v%s đã khởi động · resource: ^3%s^7 · community: ^3%s^7 · %d tone, %d profile xe')
        :format(GetResourceMetadata(res, 'version', 0) or '?', res, Config.CommunityId, #SIRENS,
        (function() local n = 0 for _ in pairs(SIREN_ASSIGNMENTS) do n = n + 1 end return n end)()))
    if not SIREN_ASSIGNMENTS['DEFAULT'] then
        print('^1[S82 Siren] LỖI CẤU HÌNH: thiếu SIREN_ASSIGNMENTS["DEFAULT"] trong sirens.lua^7')
    end
    if not Config.CommunityId or Config.CommunityId == '' or Config.CommunityId:find('%s') then
        print('^1[S82 Siren] LỖI CẤU HÌNH: Config.CommunityId trống hoặc có dấu cách^7')
    end
    if GetResourceState('lvc') == 'started' or GetResourceState('lux_vehcontrol') == 'started' then
        print('^3[S82 Siren] CẢNH BÁO: đang chạy song song "lvc"/"lux_vehcontrol" — hãy tắt resource cũ để tránh xung đột phím & âm thanh.^7')
    end
end)
