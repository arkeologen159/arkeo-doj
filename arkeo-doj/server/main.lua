local chatMessages = {}
local qbx          = exports.qbx_core
local oxmysql      = exports.oxmysql

RegisterNetEvent('arkeo-doj:server:sendChat')
AddEventHandler('arkeo-doj:server:sendChat', function(data)
    local src = source
    local p   = qbx:GetPlayer(src)
    if not p or not p.PlayerData then return end
    local ci       = p.PlayerData.charinfo
    local fullName = (ci.firstname or '') .. ' ' .. (ci.lastname or '')
    local role = 'citizen'
    if p.PlayerData.job.name == 'justice' then
        local lvl = p.PlayerData.job.grade.level or 0
        if lvl == 1 then role = 'lawyer' elseif lvl == 2 then role = 'judge' end
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
    if onDuty then
        qbx:SetMetadata(src, 'status', 'Available')
    else
        qbx:SetMetadata(src, 'status', nil)
    end
end)

RegisterNetEvent('arkeo-doj:server:updateStatus')
AddEventHandler('arkeo-doj:server:updateStatus', function(data)
    local src     = source
    local newStat = data.status or ''

    exports.oxmysql:execute([[
      UPDATE players
      SET metadata = JSON_SET(
        metadata,
        '$.status',
        ?
      )
      WHERE citizenid = ?
    ]], { newStat, src })
end)


RegisterNetEvent('arkeo-doj:server:search')
AddEventHandler('arkeo-doj:server:search', function(data)
    local src  = source
    local term = '%' .. string.lower(data.term or '') .. '%'
    local results = {}

    for _, pd in ipairs(qbx:GetPlayersData() or {}) do
        local name = (pd.charinfo.firstname or '') .. ' ' .. (pd.charinfo.lastname or '')
        if string.find(string.lower(name), string.lower(data.term or ''), 1, true) then
            table.insert(results, { view='Citizens', id=pd.citizenid, label=name })
        end
    end

    oxmysql:execute('SELECT id,title FROM doj_dockets WHERE LOWER(title) LIKE ?', {term}, function(r1)
        for _, v in ipairs(r1) do
            table.insert(results, { view='Dockets', id=v.id, label=('[Docket #%s] %s'):format(v.id, v.title) })
        end
        oxmysql:execute('SELECT id,summary FROM doj_reports WHERE LOWER(summary) LIKE ?', {term}, function(r2)
            for _, v in ipairs(r2) do
                table.insert(results, { view='Reports', id=v.id, label=('[Report #%s] %s'):format(v.id, v.summary) })
            end
            oxmysql:execute('SELECT id,reason FROM doj_warrants WHERE LOWER(reason) LIKE ?', {term}, function(r3)
                for _, v in ipairs(r3) do
                    table.insert(results, { view='Warrants', id=v.id, label=('[Warrant #%s] %s'):format(v.id, v.reason) })
                end
                oxmysql:execute('SELECT id,title FROM doj_legislations WHERE LOWER(title) LIKE ?', {term}, function(r4)
                    for _, v in ipairs(r4) do
                        table.insert(results, { view='Legislations', id=v.id, label=('[Legislation #%s] %s'):format(v.id, v.title) })
                    end
                    oxmysql:execute('SELECT id,description FROM doj_finances WHERE LOWER(description) LIKE ?', {term}, function(r5)
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
    local src       = source
    local chat      = chatMessages
    local employees = {}

    -- on-duty list
    for _, pd in ipairs(qbx:GetPlayersData() or {}) do
        if pd.job.name == 'justice' and pd.job.onduty then
            local ci     = pd.charinfo
            local name   = (ci.firstname or '') .. ' ' .. (ci.lastname or '')
            local status = pd.metadata and pd.metadata.status or 'Available'
            table.insert(employees, {
                id     = pd.citizenid,
                name   = name,
                status = status
            })
        end
    end

    -- src profile fetch
    local me = qbx:GetPlayer(src)
    if me and me.PlayerData then
        local cid = me.PlayerData.citizenid
        oxmysql:execute([[
            SELECT charinfo, metadata
            FROM players
            WHERE citizenid = ?
        ]], { cid }, function(rows)
            local profile = {}
            if rows[1] then
                local ci = json.decode(rows[1].charinfo or '{}')
                local md = json.decode(rows[1].metadata or '{}')
                profile = {
                    id        = cid,
                    avatarUrl = md.avatarUrl or '',
                    fullName  = (ci.firstname or '') .. ' ' .. (ci.lastname or ''),
                    rank      = (me.PlayerData.job.label or me.PlayerData.job.name)
                                .. ' '
                                .. (me.PlayerData.job.grade.name or me.PlayerData.job.grade.level),
                    status    = md.status or 'Available',
                }
            end
            TriggerClientEvent('arkeo-doj:client:dashboardData', src, {
                chat      = chat,
                employees = employees,
                profile   = profile
            })
        end)
    else
        TriggerClientEvent('arkeo-doj:client:dashboardData', src, {
            chat      = chat,
            employees = employees,
            profile   = {}
        })
    end
end)

RegisterNetEvent('arkeo-doj:server:getCitizens')
AddEventHandler('arkeo-doj:server:getCitizens', function()
    local src = source
    oxmysql:execute([[
        SELECT citizenid, charinfo, metadata
        FROM players
    ]], {}, function(rows)
        local list = {}
        for _, row in ipairs(rows) do
            local ci = json.decode(row.charinfo or '{}')
            local md = json.decode(row.metadata or '{}')
            table.insert(list, {
                citizenid = row.citizenid,
                fullName  = (ci.firstname or '') .. ' ' .. (ci.lastname or ''),
                avatarUrl = md.avatarUrl or ''
            })
        end
        TriggerClientEvent('arkeo-doj:client:citizensList', src, list)
    end)
end)

RegisterNetEvent('arkeo-doj:server:getCitizenProfile')
AddEventHandler('arkeo-doj:server:getCitizenProfile', function(data)
    local src = source
    oxmysql:execute([[
        SELECT charinfo, metadata
        FROM players
        WHERE citizenid = ?
    ]], { data.id }, function(rows)
        if not rows[1] then return end
        local ci = json.decode(rows[1].charinfo or '{}')
        local md = json.decode(rows[1].metadata or '{}')
        local profile = {
            citizenid   = data.id,
            fullName    = (ci.firstname or '') .. ' ' .. (ci.lastname or ''),
            avatarUrl   = md.avatarUrl or '',
            dob         = ci.birthdate or 'Unknown',
            nationality = ci.nationality or 'Unknown',
            licenses    = md.licences or {},
            properties  = md.properties or {},
            convictions = md.criminalrecord or {},
            inJail      = md.inJail and true or false
        }
        TriggerClientEvent('arkeo-doj:client:citizenProfile', src, profile)
    end)
end)

RegisterNetEvent('arkeo-doj:server:updateAvatar')
AddEventHandler('arkeo-doj:server:updateAvatar', function(data)
    oxmysql:execute([[
      UPDATE players
      SET metadata = JSON_SET(
        metadata,
        '$.avatarUrl',
        ?
      )
      WHERE citizenid = ?
    ]], { data.url or '', data.id }, function()
        TriggerClientEvent('arkeo-doj:client:avatarUpdated', -1, {
          id  = data.id,
          url = data.url or ''
        })
    end)
end)

-- Expunge convictions // still needs work really 
RegisterNetEvent('arkeo-doj:server:expungeCitizen')
AddEventHandler('arkeo-doj:server:expungeCitizen', function(data)
    oxmysql:execute([[
        UPDATE players
        SET metadata = JSON_SET(
            metadata,
            '$.criminalrecord',
            JSON_ARRAY()
        )
        WHERE citizenid = ?
    ]], { data.id })
end)