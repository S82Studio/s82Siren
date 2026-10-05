Tones = {
    approved = {},      
    profile  = false,   
    options  = {},      
    ids      = { MAIN_MEM = nil, PMANU = nil, SMANU = nil, AUX = nil, ARHRN = nil },
    names    = {},      
    customNames = false,
}

local DEFAULT_POS = { ARHRN = 1, PMANU = 2, SMANU = 3, AUX = 2, MAIN_MEM = 2 }

function DebugPrint(msg)
    if Config.Debug then print('^5[S82 Siren]^7 ' .. msg) end
end

function Notify(msg)
    Config.Notify(msg)
end
---@return table tones, string|false profileName
function Tones.FindProfile(tbl, veh)
    local name = (GetDisplayNameFromVehicleModel(GetEntityModel(veh)) or 'CARNOTFOUND'):upper()

    if tbl[name] then return tbl[name], name end
    local lead = name:match('^%d*%a+')
    if lead then
        local trail = name:sub(#lead + 1):gsub('%d+', '#')
        local key = lead .. trail
        if tbl[key] then return tbl[key], key end
    end
    local anyDigits = name:gsub('%d+', '#')
    if tbl[anyDigits] then return tbl[anyDigits], anyDigits end

    if tbl['DEFAULT'] then
        if Config.Debug then Notify(L('default_profile', { model = name })) end
        return tbl['DEFAULT'], 'DEFAULT'
    end
    return {}, false
end

function Tones.IsApproved(id)
    if not id then return false end
    for i = 1, #Tones.approved do
        if Tones.approved[i] == id then return true end
    end
    return false
end

function Tones.GetPos(id)
    for i = 1, #Tones.approved do
        if Tones.approved[i] == id then return i end
    end
    return -1
end

function Tones.AtPos(pos)
    return Tones.approved[pos]
end

function Tones.Count()
    return #Tones.approved
end

function Tones.Get(kind)
    return Tones.ids[kind]
end

function Tones.SetByPos(kind, pos)
    local id = Tones.approved[pos]
    if id then Tones.ids[kind] = id end
end

function Tones.SetByID(kind, id)
    if Tones.IsApproved(id) then
        Tones.ids[kind] = id
        return true
    end
    DebugPrint(('Bỏ qua tone %s=%s (không thuộc profile %s)'):format(kind, tostring(id), tostring(Tones.profile)))
    return false
end

function Tones.GetOption(id)
    return Tones.options[id]
end

function Tones.SetOption(id, opt)
    Tones.options[id] = opt
end

function Tones.GetName(id)
    if not id or not SIRENS[id] then return '?' end
    return Tones.names[id] or SIRENS[id].Name
end

function Tones.Rename(id, name)
    if SIRENS[id] then
        Tones.names[id] = name
        Tones.customNames = true
    end
end

function Tones.ResetNames()
    Tones.names = {}
    Tones.customNames = false
end

function Tones.BuildOptions()
    local t = {}
    for _, id in ipairs(Tones.approved) do
        if SIRENS[id] then t[id] = SIRENS[id].Option or 1 end
    end
    Tones.options = t
end

function Tones.ResetIds()
    for kind, pos in pairs(DEFAULT_POS) do
        Tones.ids[kind] = nil
        Tones.SetByPos(kind, pos)
    end
end

function Tones.Update(veh)
    local list, profile = Tones.FindProfile(SIREN_ASSIGNMENTS, veh)
    Tones.approved, Tones.profile = {}, profile
    for _, id in ipairs(list) do
        if SIRENS[id] then
            Tones.approved[#Tones.approved + 1] = id
        else
            print(('^3[S82 Siren] Bỏ qua tone ID %s không tồn tại trong profile %s^7'):format(tostring(id), tostring(profile)))
        end
    end
    if not profile then
        Notify(L('no_profile'))
        return
    end
    for kind, pos in pairs(DEFAULT_POS) do
        if not Tones.IsApproved(Tones.ids[kind]) then Tones.SetByPos(kind, pos) end
    end
end

function Tones.Next(current, mainOnly)
    local count = #Tones.approved
    if count < 2 then return Tones.approved[1] or 0 end
    local pos = Tones.GetPos(current)
    if pos < 1 then pos = 1 end
    for _ = 1, count do
        pos = pos + 1
        if pos > count then pos = 2 end
        local id = Tones.approved[pos]
        if not mainOnly or (Tones.options[id] or 1) <= 2 then
            return id
        end
    end
    return Tones.approved[2]
end

function Tones.IsOkayToDisable()
    local n = 0
    for i = 2, #Tones.approved do
        if (Tones.options[Tones.approved[i]] or 1) < 3 then n = n + 1 end
    end
    return n > 1
end

function Tones.MenuList()
    local labels, values = {}, {}
    for i = 2, #Tones.approved do
        local id = Tones.approved[i]
        labels[#labels + 1] = Tones.GetName(id)
        values[#values + 1] = id
    end
    return labels, values
end
