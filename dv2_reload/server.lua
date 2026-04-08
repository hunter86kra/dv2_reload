local ESX

local function getESX()
    if ESX then
        return ESX
    end

    if GetResourceState('es_extended') == 'started' then
        local ok, sharedObject = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)

        if ok and sharedObject then
            ESX = sharedObject
            return ESX
        end
    end

    TriggerEvent('esx:getSharedObject', function(obj)
        ESX = obj
    end)

    return ESX
end

local function normalizePlate(plate)
    if type(plate) ~= 'string' then
        return nil
    end

    local normalized = plate:gsub('%s+', ''):upper()
    if normalized == '' then
        return nil
    end

    return normalized
end

local function fetchAll(query, params)
    local p = promise.new()

    if Config.MySQL == 'oxmysql' and GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute(query, params or {}, function(result)
            p:resolve(result or {})
        end)
    elseif Config.MySQL == 'mysql-async' and MySQL and MySQL.Async and MySQL.Async.fetchAll then
        MySQL.Async.fetchAll(query, params or {}, function(result)
            p:resolve(result or {})
        end)
    else
        p:resolve(false)
    end

    return Citizen.Await(p)
end

local function getStoredVehicle(plate)
    local normalizedPlate = normalizePlate(plate)
    if not normalizedPlate then
        return false, 'notFound'
    end

    local rows = fetchAll(
        ("SELECT plate, vehicle FROM %s WHERE REPLACE(UPPER(plate), ' ', '') = @plate LIMIT 1"):format(Config.VehicleTable),
        {
            ['@plate'] = normalizedPlate
        }
    )

    if rows == false then
        return false, 'dbOffline'
    end

    if not rows[1] or not rows[1].vehicle then
        return false, 'notFound'
    end

    local ok, decoded = pcall(json.decode, rows[1].vehicle)
    if not ok or type(decoded) ~= 'table' then
        return false, 'invalidData'
    end

    return true, {
        plate = rows[1].plate,
        props = decoded
    }
end

CreateThread(function()
    while not getESX() do
        Wait(200)
    end

    ESX.RegisterServerCallback('dv2_reload:getOwnedVehicle', function(source, cb, plate)
        local ok, result = getStoredVehicle(plate)

        if not ok then
            cb({
                success = false,
                reason = result
            })
            return
        end

        cb({
            success = true,
            plate = result.plate,
            props = result.props
        })
    end)
end)
