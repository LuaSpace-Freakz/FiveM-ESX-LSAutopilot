local autopilotActive = false
local maxSpeed = 60.0
local drivingStyle = 447 -- most realistic. you can calculate your choise here: https://vespura.com/fivem/drivingstyle/

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 288) then
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if vehicle ~= 0 then
                local vehicleClass = GetVehicleClass(vehicle)

                if vehicleClass == 13 or vehicleClass == 14 or vehicleClass == 15 or vehicleClass == 16 or vehicleClass == 21 then
                    TriggerEvent('esx:showNotification', 'Autopilot-Menü kann in diesem Fahrzeugtyp nicht geöffnet werden.')
                else
                    SetNuiFocus(true, true)
                    SetNuiFocusKeepInput(true)
                    SendNUIMessage({type = 'open'})
                end
            else
                TriggerEvent('esx:showNotification', 'Du musst in einem Fahrzeug sitzen, um das Autopilot-Menü zu öffnen.')
            end
        end
    end
end)

RegisterNUICallback("startAutopilot", function(data)
    local playerPed = PlayerPedId()

    if not IsPedInAnyVehicle(playerPed, false) then
        TriggerEvent('esx:showNotification', 'Du musst in einem Fahrzeug sitzen, um den Autopiloten zu aktivieren.')
        return
    end

    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local waypoint = GetFirstBlipInfoId(8)

    if not DoesBlipExist(waypoint) then
        TriggerEvent('esx:showNotification', 'Kein Zielpunkt gesetzt. Bitte setze eine Markierung auf der Karte.')
        return
    end

    local waypointCoords = GetBlipCoords(waypoint)

    local success, roadCoords = GetClosestVehicleNode(waypointCoords.x, waypointCoords.y, waypointCoords.z, 1, 3.0, 0)
    if not success then
        TriggerEvent('esx:showNotification', 'Autopilot konnte keinen befahrbaren Weg zum Ziel finden.')
        return
    end

    local speed = tonumber(data.speed)
    if speed == nil or speed < 30 then
        speed = 60.0
    end

    ClearPedTasks(playerPed)

    TaskVehicleDriveToCoordLongrange(playerPed, vehicle, roadCoords.x, roadCoords.y, roadCoords.z, speed / 3.6, drivingStyle, 1.0, true)

    autopilotActive = true

    Citizen.CreateThread(function()
        while autopilotActive do
            Citizen.Wait(500)

            if not DoesEntityExist(vehicle) or not IsPedInAnyVehicle(playerPed, false) then
                autopilotActive = false
                break
            end

            local currentCoords = GetEntityCoords(vehicle)
            local distance = Vdist(currentCoords, roadCoords)

            if distance > 100.0 then
                adjustedSpeed = speed
            elseif distance <= 5.0 then
                adjustedSpeed = 20.0
            else
                adjustedSpeed = 20.0 + (speed - 20.0) * ((distance - 5.0) / (100.0 - 5.0))
            end
            SetDriveTaskCruiseSpeed(playerPed, adjustedSpeed / 3.6)

            if distance < 5.0 then
                ClearPedTasks(playerPed)
                autopilotActive = false
                SetVehicleForwardSpeed(vehicle, 0.0)
                SetVehicleBrake(vehicle, true)
                SetVehicleHandbrake(vehicle, true)
                SetVehicleHandbrake(vehicle, false)
                TriggerEvent('esx:showNotification', 'Ziel erreicht!')
                break
            end            
        end
    end)
end)

RegisterNUICallback("stopAutopilot", function()
    if autopilotActive then
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle ~= 0 then
            autopilotActive = false
            ClearPedTasks(playerPed)
            TaskVehicleTempAction(playerPed, vehicle, 6, 1000)
            while GetEntitySpeed(vehicle) > 0.5 do
                Citizen.Wait(100)
            end
            SetVehicleForwardSpeed(vehicle, 0.0)
            TriggerEvent('esx:showNotification', 'Autopilot gestoppt.')
        end
    else
        TriggerEvent('esx:showNotification', 'Autopilot ist derzeit nicht aktiv!')
    end
end)

RegisterNUICallback("closeMenu", function()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 322) then
            SendNUIMessage({type = 'close'})
        end
    end
end)

function IsAutopilotActive()
    return autopilotActive
end

exports('IsAutopilotActive', IsAutopilotActive)
