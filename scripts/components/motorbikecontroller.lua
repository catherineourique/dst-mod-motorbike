local MotorbikeController = Class(function(self, inst)
    self.inst = inst
    self.is_driver = false
    self.camera_heading=0
    self.scale=0.50
end)

function MotorbikeController:SaveCamera()
    self.camera_heading=TheCamera:GetHeadingTarget()
    self.camera_offset=TheCamera.targetoffset
    self.camera_headinggain=TheCamera.headinggain
    self.camera_onupdatefn=TheCamera.onupdatefn
end

function MotorbikeController:LoadCamera()
    TheCamera:SetHeadingTarget(self.camera_heading)
    TheCamera.targetoffset=self.camera_offset
    TheCamera.targetoffset.x=0
    TheCamera.targetoffset.z=0
    TheCamera.headinggain=self.camera_headinggain
    TheCamera.onupdatefn=self.camera_onupdatefn
end


function MotorbikeController:TurnOn(is_driver)
    self.is_driver = is_driver and is_driver or false
    if self.is_driver then
        self:SaveCamera()
        TheCamera.controllable=false
        TheCamera.headinggain=5
        TheCamera.motorbike_speed=0
        TheCamera.newpitch=TheCamera.pitch
        TheCamera.onupdatefn = function(self, dt) self.newpitch= self.newpitch-0.1*(self.newpitch-(45-0.7*self.motorbike_speed)) self.pitch=self.newpitch end
    end
    self.inst:StartUpdatingComponent(self)
    self.inst.Physics:Stop()
end

function MotorbikeController:TurnOff()
    self.inst:StopUpdatingComponent(self)
    if self.is_driver then
        self:LoadCamera()
        TheCamera.controllable=true
    end
    self.inst.Physics:Stop()
end

function MotorbikeController:OnUpdate(dt)
    ThePlayer.player_classified.motorbike_brake=0
    ThePlayer.player_classified.motorbike_turn=0
    ThePlayer.player_classified.motorbike_gas=0

    local screen = TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name or ""
    if screen:find("HUD") ~= nil then -- Do not use controls when chat is open
        if TheInput:IsControlPressed(CONTROL_ACTION) then
            SendModRPCToServer(MOD_RPC.motorbike.dropoff)
            ThePlayer.player_classified.motorbike_brake = 1
        end

        if self.is_driver then
            if TheInput:IsControlPressed(CONTROL_MOVE_UP) then
                SendModRPCToServer(MOD_RPC.motorbike.accelerate)
                ThePlayer.player_classified.motorbike_gas = 1
            end
            if TheInput:IsControlPressed(CONTROL_MOVE_DOWN) then
                SendModRPCToServer(MOD_RPC.motorbike.brake)
                ThePlayer.player_classified.motorbike_brake = 1
            end
            if TheInput:IsControlPressed(CONTROL_MOVE_LEFT) then
                SendModRPCToServer(MOD_RPC.motorbike.turnleft)
                ThePlayer.player_classified.motorbike_turn = ThePlayer.player_classified.motorbike_turn-1
            end
            if TheInput:IsControlPressed(CONTROL_MOVE_RIGHT) then
                SendModRPCToServer(MOD_RPC.motorbike.turnright)
                ThePlayer.player_classified.motorbike_turn = ThePlayer.player_classified.motorbike_turn+1
            end
        end

    end
    
    if self.inst.player_classified and self.is_driver then
        local angle=self.inst.player_classified.motorbike_angle:value()
        local speed=self.inst.player_classified.motorbike_speed:value()
        TheCamera:SetHeadingTarget(-angle+180)
        TheCamera.targetoffset.x=math.cos(-angle/180.*math.pi)*self.scale*speed
        TheCamera.targetoffset.z=math.sin(-angle/180.*math.pi)*self.scale*speed
        TheCamera.motorbike_speed=speed
        self.inst.Physics:SetMotorVel(speed,0,0)
    end
end

return MotorbikeController
