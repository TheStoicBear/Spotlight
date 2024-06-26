-----------------------------------------
--- Spotlight, Made by FAXES & Slavko ---
------------ FaxSlav Devs :P ------------
-----------------------------------------

--- Config ---
spotlightCommand = "spotlight" -- Command to trigger the spotlight
whitelistLEO = true -- Only allow emergency (police, fire, ems) vehicles to use the spotlight

--- Code ---
local activeVehicleSpotlights = {}

function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function DisplayHelp(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function getVehicleSpotlightStatus(vehicleKey)
    for i, networkId in ipairs(activeVehicleSpotlights) do
        if networkId[1] == vehicleKey then
            return i
        end
    end
    return false
end

RegisterNetEvent("spotlight:syncSpotlights")
AddEventHandler("spotlight:syncSpotlights", function(activeVehicleSpotlightsServer)
    activeVehicleSpotlights = activeVehicleSpotlightsServer
end)

AddEventHandler("playerSpawned", function(spawnInfo)
    TriggerServerEvent("spotlight:syncSpotlights")
end)

local spotlightOn = false -- Variable to track spotlight state

RegisterCommand(spotlightCommand, function(source, args, rawCommand)
    local ped = GetPlayerPed(-1)
    local veh = GetVehiclePedIsIn(ped, false)
    if IsPedInAnyVehicle(ped, false) then
        if whitelistLEO then
            if GetVehicleClass(veh) ~= 18 then
                return ShowNotification("~r~Invalid permissions.")
            end
        end

        local vehicleNetworkId = VehToNet(veh)
        local direction = GetEntityForwardVector(veh)
        TriggerServerEvent("spotlight:toggleSpotlight", vehicleNetworkId, {direction.x, direction.y, direction.z})
        local spotlightStatus = getVehicleSpotlightStatus(vehicleNetworkId)
        if spotlightStatus == false then
            ShowNotification("Spotlight toggled ~g~on~w~.")
            spotlightOn = true
            SetVehicleLights(veh, 2) -- Set vehicle lights to high beams
            SetVehicleLightMultiplier(veh, 20.0) -- Increase light brightness
        else
            ShowNotification("Spotlight toggled ~r~off~w~.")
            Wait(300)
            DisplayHelp("Spotlight is ~r~off~w~.")
            spotlightOn = false
            SetVehicleLights(veh, 0) -- Set vehicle lights to low beams
            SetVehicleLightMultiplier(veh, 1.0) -- Reset light brightness
        end
    else
        ShowNotification("~y~You are not in a vehicle.")
    end
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Reduced the interval to 0 milliseconds for more frequent updates
        for i, spotlightInformation in ipairs(activeVehicleSpotlights) do
            local ped = GetPlayerPed(-1)
            local vehicle = NetToVeh(spotlightInformation[1])
            local door = GetEntityBoneIndexByName(vehicle, "door_dside_f")
            local windscreen = GetEntityBoneIndexByName(vehicle, "windscreen")
            local coords = GetWorldPositionOfEntityBone(vehicle, door)
            local windowCoords = GetWorldPositionOfEntityBone(vehicle, windscreen)
            local playerPos = GetEntityCoords(GetPlayerPed(-1), true)
            local direct = vector3(spotlightInformation[2][1], spotlightInformation[2][2], spotlightInformation[2][3])

            if not NetworkDoesEntityExistWithNetworkId(spotlightInformation[1]) then
                TriggerServerEvent("spotlight:toggleSpotlight", vehicleNetworkId, {0, 0, 0})
                return
            end

            if GetVehiclePedIsIn(ped, false) == vehicle then
                local newY = 0
                local newZ = 0
                local forwardVector = GetEntityForwardVector(vehicle)
                local heading = GetEntityHeading(vehicle)
                if IsControlPressed(0, 127) then -- Up // NumPad 8
                    newZ = newZ + 0.04
                end
                if IsControlPressed(0, 126) then -- Down // NumPad 5
                    newZ = newZ - 0.04
                end
                if IsControlPressed(0, 124) then -- Left // NumPad 4
                    if heading >= 180 and heading <= 365 then
                        newY = newY + 0.04
                    else
                        newY = newY - 0.04
                    end
                end
                if IsControlPressed(0, 125) then -- Right // NumPad 6
                    if heading >= 180 and heading <= 365 then
                        newY = newY - 0.04
                    else
                        newY = newY + 0.04
                    end
                end
                TriggerServerEvent("spotlight:updateSpotlight", i, {forwardVector.x, (direct.y + newY), (direct.z + newZ)})
                DisplayHelp("Spotlight is ~g~on~w~.")
            end
            DrawSpotLight(coords.x, windowCoords.y, coords.z, direct.x, direct.y, direct.z, 221, 221, 221, 30.0, 50.0, 4.3, 25.0, 18.6)
        end
    end
end)
