local dict = (Locales and (Locales[Config.Locale] or Locales['en'])) or {}
local fallback = (Locales and Locales['en']) or {}
---@param key string
---@param subs table|nil
function L(key, subs)
    local s = dict[key] or fallback[key] or key
    if subs then
        s = s:gsub('%%{(%w+)}', function(k)
            local v = subs[k]
            return v ~= nil and tostring(v) or ''
        end)
    end
    return s
end
function IsValidTone(id)
    return id == 0 or (math.type(id) == 'integer' and SIRENS[id] ~= nil)
end
do
    local fixed = {}
    for name, tones in pairs(SIREN_ASSIGNMENTS) do
        local key = tostring(name):upper()
        if #key > 11 then key = key:sub(1, 11) end
        fixed[key] = tones
    end
    SIREN_ASSIGNMENTS = fixed
end

S82_STATE_KEY = 's82siren'
S82_INDIC_KEY = 's82indic'
