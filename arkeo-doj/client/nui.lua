--dev
RegisterCommand('mdt', function()
    SetNuiFocus(true, true)
    SendNuiMessage(json.encode({ type = 'setVisible', data = true }))
end, false)

-- Helper function
local function forwardToServer(nuiEvent, srvEvent)
    RegisterNUICallback(nuiEvent, function(data, cb)
        TriggerServerEvent(srvEvent, data)
        cb({ status = 'ok' })
    end)
end

forwardToServer('arkeo-doj:client:sendChat',           'arkeo-doj:server:sendChat')
forwardToServer('arkeo-doj:client:search',             'arkeo-doj:server:search')
forwardToServer('arkeo-doj:client:requestDashboardData','arkeo-doj:server:requestDashboardData')
forwardToServer('arkeo-doj:client:updateStatus',       'arkeo-doj:server:updateStatus')
forwardToServer('arkeo-doj:client:updateAvatar',       'arkeo-doj:server:updateAvatar')
forwardToServer('arkeo-doj:client:getCitizens',        'arkeo-doj:server:getCitizens')
forwardToServer('arkeo-doj:client:getCitizenProfile',  'arkeo-doj:server:getCitizenProfile')
forwardToServer('arkeo-doj:client:expungeCitizen',     'arkeo-doj:server:expungeCitizen')

-- this is for the tab navigation
RegisterNUICallback('arkeo-doj:client:navigate', function(data, cb)
    SendNuiMessage(json.encode({ type = 'navigate', data = data }))
    cb({ status = 'ok' })
end)

RegisterNUICallback('hideui', function(_, cb)
    SetNuiFocus(false, false)
    cb({ status = 'ok' })
end)

-- Helper nui to server
local function forwardToNui(evt, typ)
    RegisterNetEvent(evt)
    AddEventHandler(evt, function(payload)
        SendNuiMessage(json.encode({ type = typ, data = payload }))
    end)
end

forwardToNui('arkeo-doj:client:newChatMessage', 'newChatMessage')
forwardToNui('arkeo-doj:client:searchResults',  'searchResults')
forwardToNui('arkeo-doj:client:dashboardData',  'dashboardData')
forwardToNui('arkeo-doj:client:citizensList',   'citizensList')
forwardToNui('arkeo-doj:client:citizenProfile', 'citizenProfile')
forwardToNui('arkeo-doj:client:avatarUpdated',  'avatarUpdated')

-- This will change once job system is done
RegisterNetEvent('QBCore:Client:SetDuty')
AddEventHandler('QBCore:Client:SetDuty', function(onDuty)
    TriggerServerEvent('arkeo-doj:server:setDuty', onDuty)
end)
