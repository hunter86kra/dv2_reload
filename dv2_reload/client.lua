local ESX
local isReloading = false
local lastUseAt = 0

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

local function notify(message)
    local sharedObject = getESX()
    if sharedObject and sharedObject.ShowNotification then
        sharedObject.ShowNotification(message)
        return
    end

    TriggerEvent('chat:addMessage', {
        args = { '[dv2]', message }
    })
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

local function getTargetVehicle()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local vehicleCoords = GetEntityCoords(vehicle)
        if #(pedCoords - vehicleCoords) <= Config.ReloadDistance then
            return vehicle, GetPedInVehicleSeat(vehicle, -1) == ped
        end
    end

    local sharedObject = getESX()
    if sharedObject and sharedObject.Game and sharedObject.Game.GetClosestVehicle then
        local vehicle, distance = sharedObject.Game.GetClosestVehicle(pedCoords)
        if vehicle and vehicle ~= 0 and distance and distance <= Config.ReloadDistance then
            return vehicle, false
        end
    end

    local vehicle = GetClosestVehicle(pedCoords.x, pedCoords.y, pedCoords.z, Config.ReloadDistance + 0.0, 0, 71)
    if vehicle and vehicle ~= 0 then
        return vehicle, false
    end

    return 0, false
end

local function requestControl(entity, timeoutMs)
    if not DoesEntityExist(entity) then
        return false
    end

    local timeoutAt = GetGameTimer() + (timeoutMs or 2000)
    NetworkRequestControlOfEntity(entity)

    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeoutAt do
        Wait(50)
        NetworkRequestControlOfEntity(entity)
    end

    return NetworkHasControlOfEntity(entity)
end

local function deleteVehicleEntity(vehicle)
    if not DoesEntityExist(vehicle) then
        return true
    end

    if not requestControl(vehicle, 2500) then
        return false
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)

    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end

    return not DoesEntityExist(vehicle)
end

local function getModelHash(props, fallbackVehicle)
    if props and props.model then
        if type(props.model) == 'number' then
            return props.model
        end

        if type(props.model) == 'string' then
            local numericModel = tonumber(props.model)
            if numericModel then
                return numericModel
            end

            return GetHashKey(props.model)
        end
    end

    if fallbackVehicle and DoesEntityExist(fallbackVehicle) then
        return GetEntityModel(fallbackVehicle)
    end

    return nil
end

local function loadModel(model)
    if not model or not IsModelInCdimage(model) then
        return false
    end

    RequestModel(model)

    local timeoutAt = GetGameTimer() + 10000
    while not HasModelLoaded(model) and GetGameTimer() < timeoutAt do
        Wait(50)
    end

    return HasModelLoaded(model)
end

local function applyProperties(vehicle, props)
    local sharedObject = getESX()
    if sharedObject and sharedObject.Game and sharedObject.Game.SetVehicleProperties then
        sharedObject.Game.SetVehicleProperties(vehicle, props)
        return
    end

    if props and props.plate then
        SetVehicleNumberPlateText(vehicle, props.plate)
    end
end

local function repairVehicle(vehicle)
    if not Config.RepairAfterReload then
        return
    end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)
end

local function reloadVehicleFromProps(oldVehicle, wasDriver, props)
    local model = getModelHash(props, oldVehicle)
    if not model or not loadModel(model) then
        return false, Config.Messages.spawnFailed
    end

    local ped = PlayerPedId()
    local coords
    local heading

    if oldVehicle and DoesEntityExist(oldVehicle) then
        coords = GetEntityCoords(oldVehicle)
        heading = GetEntityHeading(oldVehicle)
    else
        coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
        heading = GetEntityHeading(ped)
    end

    if wasDriver and oldVehicle and DoesEntityExist(oldVehicle) then
        TaskLeaveVehicle(ped, oldVehicle, 16)

        local leaveTimeoutAt = GetGameTimer() + 1500
        while IsPedInVehicle(ped, oldVehicle, false) and GetGameTimer() < leaveTimeoutAt do
            Wait(50)
        end
    end

    if not deleteVehicleEntity(oldVehicle) then
        SetModelAsNoLongerNeeded(model)
        return false, Config.Messages.noControl
    end

    local newVehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    if newVehicle == 0 then
        SetModelAsNoLongerNeeded(model)
        return false, Config.Messages.spawnFailed
    end

    SetVehicleOnGroundProperly(newVehicle)
    SetEntityAsMissionEntity(newVehicle, true, false)
    applyProperties(newVehicle, props)
    repairVehicle(newVehicle)
    SetVehRadioStation(newVehicle, 'OFF')

    if wasDriver then
        TaskWarpPedIntoVehicle(ped, newVehicle, -1)
        SetVehicleEngineOn(newVehicle, true, true, false)
    end

    SetModelAsNoLongerNeeded(model)
    return true
end

RegisterCommand(Config.Command, function()
    local now = GetGameTimer()
    if isReloading then
        return
    end

    if lastUseAt > 0 and (now - lastUseAt) < Config.CommandCooldownMs then
        notify(Config.Messages.cooldown)
        return
    end

    local vehicle, wasDriver = getTargetVehicle()
    if vehicle == 0 then
        notify(Config.Messages.noVehicle)
        return
    end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    if not plate then
        notify(Config.Messages.missingPlate)
        return
    end

    local sharedObject = getESX()
    if not sharedObject then
        notify(Config.Messages.invalidData)
        return
    end

    isReloading = true
    notify(Config.Messages.loading)

    sharedObject.TriggerServerCallback('dv2_reload:getOwnedVehicle', function(response)
        isReloading = false

        if not response or not response.success then
            local reason = response and response.reason or 'notFound'
            notify(Config.Messages[reason] or Config.Messages.notFound)
            return
        end

        local ok, errorMessage = reloadVehicleFromProps(vehicle, wasDriver, response.props)
        if not ok then
            notify(errorMessage or Config.Messages.spawnFailed)
            return
        end

        lastUseAt = GetGameTimer()
        notify(Config.Messages.success)
    end, plate)
end, false)
