local chatMessages = {}
local qbx          = exports.qbx_core
local oxmysql      = exports.oxmysql

RegisterNetEvent('arkeo-doj:server:sendChat')
AddEventHandler('arkeo-doj:server:sendChat', function(data)
    local src  = source
    local user = qbx:GetPlayer(src)
    if not user or not user.PlayerData then return end

    local pd       = user.PlayerData
    local ci       = pd.charinfo
    local fullName = (ci.firstname or '') .. ' ' .. (ci.lastname or '')

    local role = 'citizen'
    if pd.job.name == 'justice' then
        local lvl = pd.job.grade.level or 0
        if     lvl == 1 then role = 'lawyer'
        elseif lvl == 2 then role = 'judge' end
    end

    local msg = {
        sender    = fullName,
        text      = data.text or '',
        timestamp = os.date('%H:%M:%S'),
        role      = role
    }

    table.insert(chatMessages, msg)
    TriggerClientEvent('arkeo-doj:client:newChatMessage', -1, msg)
end)

RegisterNetEvent('arkeo-doj:server:setDuty')
AddEventHandler('arkeo-doj:server:setDuty', function(onDuty)
    local src = source
    qbx:SetJobDuty(src, onDuty)
end)

RegisterNetEvent('arkeo-doj:server:updateStatus')
AddEventHandler('arkeo-doj:server:updateStatus', function(data)
    local src = source
    if data.status then
        TriggerEvent('qbx_core:server:setMetaData', src, 'status', data.status)
    end
end)

RegisterNetEvent('arkeo-doj:server:search')
AddEventHandler('arkeo-doj:server:search', function(data)
    local src     = source
    local term    = '%' .. string.lower(data.term or '') .. '%'
    local results = {}

    for _, pd in ipairs(qbx:GetPlayersData() or {}) do
        local name = (pd.charinfo.firstname or '') .. ' ' .. (pd.charinfo.lastname or '')
        if string.find(string.lower(name), string.lower(data.term or ''), 1, true) then
            table.insert(results, { view='Citizens', id=pd.citizenid, label=name })
        end
    end

    oxmysql:execute('SELECT id,title FROM doj_dockets WHERE LOWER(title) LIKE ?', { term }, function(r1)
        for _, v in ipairs(r1) do
            table.insert(results, { view='Dockets', id=v.id, label=('[Docket #%s] %s'):format(v.id, v.title) })
        end
        oxmysql:execute('SELECT id,summary FROM doj_reports WHERE LOWER(summary) LIKE ?', { term }, function(r2)
            for _, v in ipairs(r2) do
                table.insert(results, { view='Reports', id=v.id, label=('[Report #%s] %s'):format(v.id, v.summary) })
            end
            oxmysql:execute('SELECT id,reason FROM doj_warrants WHERE LOWER(reason) LIKE ?', { term }, function(r3)
                for _, v in ipairs(r3) do
                    table.insert(results, { view='Warrants', id=v.id, label=('[Warrant #%s] %s'):format(v.id, v.reason) })
                end
                oxmysql:execute('SELECT id,title FROM doj_legislations WHERE LOWER(title) LIKE ?', { term }, function(r4)
                    for _, v in ipairs(r4) do
                        table.insert(results, { view='Legislations', id=v.id, label=('[Legislation #%s] %s'):format(v.id, v.title) })
                    end
                    oxmysql:execute('SELECT id,description FROM doj_finances WHERE LOWER(description) LIKE ?', { term }, function(r5)
                        for _, v in ipairs(r5) do
                            table.insert(results, { view='Finances', id=v.id, label=('[Finance #%s] %s'):format(v.id, v.description) })
                        end
                        TriggerClientEvent('arkeo-doj:client:searchResults', src, results)
                    end)
                end)
            end)
        end)
    end)
end)

RegisterNetEvent('arkeo-doj:server:requestDashboardData')
AddEventHandler('arkeo-doj:server:requestDashboardData', function()
    local src   = source
    local chat  = chatMessages
    local employees = {}

    for _, pd in ipairs(qbx:GetPlayersData() or {}) do
        if pd.job.name == 'justice' and pd.job.onduty then
            local ci   = pd.charinfo
            local name = (ci.firstname or '') .. ' ' .. (ci.lastname or '')
            table.insert(employees, {
                id     = pd.citizenid,
                name   = name,
                status = pd.metadata.status or 'Available'
            })
        end
    end

    local profile = {}
    local me      = qbx:GetPlayer(src)
    if me and me.PlayerData then
        local pd       = me.PlayerData
        local ci       = pd.charinfo
        local fullName = (ci.firstname or '') .. ' ' .. (ci.lastname or '')
        local jobData  = pd.job
        local jobLabel = jobData.label or jobData.name or ''
        local gradeLbl = jobData.grade.name or tostring(jobData.grade.level or '')
        profile = {
            id        = pd.citizenid,
            avatarUrl = ci.avatarUrl or '',
            fullName  = fullName,
            rank      = jobLabel .. ' ' .. gradeLbl,
            status    = pd.metadata.status or 'Available'
        }
    end

    TriggerClientEvent('arkeo-doj:client:dashboardData', src, {
        chat      = chat,
        employees = employees,
        profile   = profile
    })
end)
