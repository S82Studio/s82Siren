Hud = {
    show       = Config.Hud.showByDefault,
    tempHidden = true,     
    scale      = Config.Hud.scale,
    pos        = nil,      
    backlight  = 1,        
    lit        = false,
    moving     = false,
    items      = {},       
}
local function send(action, data)
    data = data or {}
    data.action = action
    SendNUIMessage(data)
end
Hud.Send = send

function Hud.Set(item, value)
    if Hud.items[item] == value then return end
    Hud.items[item] = value
    send('hud:item', { item = item, value = value })
end

function Hud.ForceRefresh()
    local copy = Hud.items
    Hud.items = {}
    for k, v in pairs(copy) do Hud.Set(k, v) end
end

local function applyVisible()
    send('hud:visible', { visible = Hud.show and not Hud.tempHidden })
end

function Hud.SetShow(state)
    Hud.show = state and true or false
    applyVisible()
end

function Hud.SetTempHidden(state)
    if Hud.tempHidden == state then return end
    Hud.tempHidden = state
    applyVisible()
end

function Hud.SetScale(scale)
    scale = math.max(0.5, math.min(1.5, tonumber(scale) or 1.0))
    Hud.scale = scale
    send('hud:scale', { scale = scale })
end

function Hud.SetPosition(pos)
    Hud.pos = pos
    send('hud:position', { pos = pos })
end

function Hud.ResetPosition()
    Hud.pos = nil
    send('hud:position', { pos = false })
end

function Hud.SetBacklightMode(mode)
    Hud.backlight = mode or 1
    if mode == 2 then Hud.SetLit(false) elseif mode == 3 then Hud.SetLit(true) end
end

function Hud.SetLit(state)
    if Hud.lit == state then return end
    Hud.lit = state
    send('hud:lit', { lit = state })
end

function Hud.SetMoveMode(state)
    Hud.moving = state
    SetNuiFocus(state, state)
    send('hud:move', { state = state, hint = L('hud_move_hint') })
    if not state then applyVisible() end
end

RegisterNUICallback('hud:savePosition', function(data, cb)
    if type(data) == 'table' and tonumber(data.x) and tonumber(data.y) then
        Hud.pos = { x = tonumber(data.x), y = tonumber(data.y) }
        Storage.SaveHud()
    end
    Hud.SetMoveMode(false)
    cb('ok')
end)

Sfx = {
    scheme   = Config.Sfx.default,
    volume   = {},
    radio    = true,
    hornSfx  = false,
    manuSfx  = false,
    reminderIndex = 1, 
}
for k, v in pairs(Config.Sfx.volume) do Sfx.volume[k] = v end

Sfx.reminderLookup = { [2] = 30000, [3] = 60000, [4] = 120000, [5] = 300000, [6] = 600000 }

function Sfx.Play(file, volume, schemeless)
    if not schemeless then file = Sfx.scheme .. '/' .. file end
    send('audio', { file = file, volume = volume or 0.5 })
end

function Hud.KeyboardInput(title, text, maxLen)
    AddTextEntry('S82_SIREN_KB', title)
    DisplayOnscreenKeyboard(1, 'S82_SIREN_KB', '', text or '', '', '', '', maxLen or 15)
    while true do
        local st = UpdateOnscreenKeyboard()
        if st == 1 then
            local res = GetOnscreenKeyboardResult()
            Wait(150)
            return (res and res ~= '') and res or nil
        elseif st == 2 or st == 3 then
            Wait(150)
            return nil
        end
        Wait(0)
    end
end

local function drawText(x, y, text, scale)
    SetTextFont(4)
    SetTextScale(0.0, scale or 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

function Hud.Confirm(title, subtitle, options)
    AddTextEntry('S82_SIREN_W1', title)
    AddTextEntry('S82_SIREN_W2', subtitle)
    while true do
        DrawFrontendAlert('S82_SIREN_W1', 'S82_SIREN_W2', 0, 0, '', 0, -1, 0, '', '', false, 0)
        drawText(0.5, 0.75, options, 0.6)
        if IsDisabledControlJustReleased(2, 202) then return false end
        if IsDisabledControlJustReleased(2, 201) then return true end
        Wait(0)
    end
end

CreateThread(function()
    Wait(300)
    send('init', {
        labels = {
            lights = L('hud_lights'), siren = L('hud_siren'), aux = L('hud_aux'),
            horn = L('hud_horn'), lock = L('hud_lock'), standby = L('hud_standby'),
            title = L('menu_title'), keys = L('menu_keys'),
        },
    })
    Hud.SetScale(Hud.scale)
    applyVisible()
end)
