local _G = GLOBAL
local SERVER_SIDE = _G.TheNet:GetIsServer()
local CLIENT_SIDE =	 _G.TheNet:GetIsClient() or (SERVER_SIDE and not _G.TheNet:IsDedicated())

AddModRPCHandler("motorbike", "accelerate", function(player)
    if not SERVER_SIDE or not player.components.motorbikedriver then
		return
	end
	player.components.motorbikedriver:Accelerate()
end)

AddModRPCHandler("motorbike", "brake", function(player)
    if not SERVER_SIDE or not player.components.motorbikedriver then
		return
	end
	player.components.motorbikedriver:Brake()
end)


AddModRPCHandler("motorbike", "dropoff", function(player)
    if not SERVER_SIDE or not (player.components.motorbikedriver or player.components.motorbikepassenger)  then
		return
	end
	if player.components.motorbikedriver and player.components.motorbikedriver.motorbike then
    	player.components.motorbikedriver:DropOff()
	end
	if player.components.motorbikepassenger and player.components.motorbikepassenger.driver then
    	player.components.motorbikepassenger:DropOff()
	end
end)

AddModRPCHandler("motorbike", "turnleft", function(player)
    if not SERVER_SIDE or not player.components.motorbikedriver then
		return
	end
	player.components.motorbikedriver:TurnLeft()
end)

AddModRPCHandler("motorbike", "turnright", function(player)
    if not SERVER_SIDE or not player.components.motorbikedriver then
		return
	end
	player.components.motorbikedriver:TurnRight()
end)

AddModRPCHandler("motorbike", "drive", function(player, inst)
    if not SERVER_SIDE or not player.components.motorbikedriver then
		return
	end
	inst.components.motorbike:SetDriver(player)
end)
