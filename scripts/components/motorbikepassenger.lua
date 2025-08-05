
local MotorbikePassenger = Class(function(self, inst)
    self.inst = inst
    self.driver = nil
    self.anim_speed = 1
    self.driver_distance=1.5
end)

function MotorbikePassenger:GetIn(driver)
    self.driver = driver
    self.driver.components.motorbikedriver:AddPassenger(self.inst)
    self.inst.sg:GoToState("onmotorbike")
    self.inst.player_classified.motorbike_passenger_ison:set(true)
    self.inst:StartUpdatingComponent(self)
    
    SpawnPrefab('collapse_small').Transform:SetPosition(self.inst:GetPosition():Get())
end


function MotorbikePassenger:DropOff()
    self.driver.components.motorbikedriver:RemovePassenger(self.inst)
    self.inst.player_classified.motorbike_passenger_ison:set(false)
    self.driver = nil
    self.inst:StopUpdatingComponent(self)
    self.inst:DoTaskInTime(FRAMES, function(inst)
        inst.AnimState:SetDeltaTimeMultiplier(1)
    end)
    if not self.inst.sg or not self.inst.player_classified or not self.inst.sg.currentstate.name == "onmotorbike" then
        return
    end
    if self.inst.sg.currentstate.name ~="death" then
        self.inst.sg:GoToState("idle")
    end
    
    SpawnPrefab('collapse_small').Transform:SetPosition(self.inst:GetPosition():Get())
    
end

function MotorbikePassenger:ChooseAnim()
    self.inst.AnimState:SetDeltaTimeMultiplier(self.driver.components.motorbikedriver.anim_speed)
end

function MotorbikePassenger:OnUpdate(dt)
    if not self.driver or not self.driver:IsValid() then
        self:DropOff()
        return
    end
    
    self.inst.Transform:SetScale(1,1,1)
    
    local pos=self.driver:GetPosition()
    local mpos = self.inst:GetPosition()
    local angle = self.driver.components.motorbikedriver.angle/180*math.pi-math.pi/2
    if mpos:DistSq(pos) > 1.5625*self.driver_distance*self.driver_distance * (1+self.driver.components.motorbikedriver.speed/24) then
        self:DropOff()
        return
    end
    self.inst.Transform:SetPosition(pos.x+self.driver_distance*math.sin(angle), 0, pos.z+self.driver_distance*math.cos(angle))
    self.inst:FacePoint(pos)
    
    self:ChooseAnim()
    
end

return MotorbikePassenger
