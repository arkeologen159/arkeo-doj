-- dev cmd
RegisterCommand('doj', function()
    SetNuiFocus(true, true)
    SendNuiMessage(json.encode({ type='setVisible', data=true }))
end, false)

-- code
RegisterNUICallback('arkeo-doj:client:sendChat', function(data, cb)
    TriggerServerEvent('arkeo-doj:server:sendChat', data)
    cb({ status='ok' })
end)

RegisterNUICallback('arkeo-doj:client:search', function(data, cb)
    TriggerServerEvent('arkeo-doj:server:search', { term=data.term })
    cb({ status='ok' })
end)

RegisterNUICallback('arkeo-doj:client:requestDashboardData', function(_, cb)
    TriggerServerEvent('arkeo-doj:server:requestDashboardData')
    cb({ status='ok' })
end)

RegisterNUICallback('arkeo-doj:client:updateStatus', function(data, cb)
    TriggerServerEvent('arkeo-doj:server:updateStatus', data)
    cb({ status='ok' })
end)

RegisterNUICallback('hideui', function(_, cb)
    SetNuiFocus(false, false)
    cb({ status='ok' })
end)

RegisterNetEvent('arkeo-doj:client:newChatMessage')
AddEventHandler('arkeo-doj:client:newChatMessage', function(msg)
    SendNuiMessage(json.encode({ type='newChatMessage', data=msg }))
end)

RegisterNetEvent('arkeo-doj:client:searchResults')
AddEventHandler('arkeo-doj:client:searchResults', function(results)
    SendNuiMessage(json.encode({ type='searchResults', data=results }))
end)

RegisterNetEvent('arkeo-doj:client:dashboardData')
AddEventHandler('arkeo-doj:client:dashboardData', function(payload)
    SendNuiMessage(json.encode({ type='dashboardData', data=payload }))
end)

RegisterNetEvent('QBCore:Client:SetDuty')
AddEventHandler('QBCore:Client:SetDuty', function(onDuty)
    TriggerServerEvent('arkeo-doj:server:setDuty', onDuty)
end)
