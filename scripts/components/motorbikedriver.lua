local function CanActivate(inst, doer)
    return math.abs(inst.components.motorbikedriver.speed) < 0.5 and
           #inst.components.motorbikedriver.passengers < inst.components.motorbikedriver.max_passengers
end

local function OnActivate(inst, doer)
	doer.components.motorbikepassenger:GetIn(inst)
	inst.components.activatable.inactive = true
end

local MotorbikeDriver = Class(function(self, inst)
    self.inst = inst
    self:ResetVariables()
end)

function MotorbikeDriver:ResetVariables()
    self.speed = 0.0
    self.accelerate_factor=0.5
    self.brake_factor=0.75
    self.reverse_factor=0.125
    self.damping_factor=1/48.
    self.turning_factor=0.06
    self.key_accelerate=0
    self.key_brake=0
    self.key_dropoff=0
    self.key_turning=0
    self.holding_dropoff=0
    self.holding_dropoff_turnoff=10
    self.angle=0
    self.speedar_angle=0
    self.damping_angle=0.5
    self.dv_threshold = 0.1
    self.knockback_threshold = 15
    self.crash_damage = 100
    self.passengers = {}
    self.max_passengers = 1
    self.anim_speed = 1
    self.player_mass=75
    --self.headlights={}
end

function MotorbikeDriver:AddPassenger(passenger)
    table.insert(self.passengers, passenger)
end

function MotorbikeDriver:RemovePassenger(passenger)
    local new_passengers = {}
    for k, v in pairs(self.passengers) do
        if v ~= passenger then
            table.insert(new_passengers, v)
        end
    end
    self.passengers = new_passengers
end


function MotorbikeDriver:Accelerate()
    self.key_accelerate=1
end

function MotorbikeDriver:Brake()
    self.key_brake=1
end

function MotorbikeDriver:StartHeadlights()
    for k,v in pairs(self.motorbike.components.motorbike.headlights_par) do
        local light=SpawnPrefab("motorbike_headlight")
        light.entity:SetParent(self.inst.entity)
        light.Transform:SetPosition(v[1],0,0)
        light.Light:SetRadius(v[2])
        light.Light:SetIntensity(v[3])
        light.Light:Enable(true)
        table.insert(self.headlights,light)
    end
end

function MotorbikeDriver:StopHeadlights()
    for k,v in pairs(self.headlights) do
        v:Remove()
    end
    self.headlights={}
end

function MotorbikeDriver:DropOff()
    self.key_dropoff=1
    if self.speed > 1 then
        self.key_brake=1
    end
    if self.speed < -1 then
        self.key_accelerate=1
    end
end

function MotorbikeDriver:TurnLeft()
    self.key_turning=-1
end

function MotorbikeDriver:TurnRight()
    self.key_turning=1
end

function MotorbikeDriver:TurnOn(motorbike)
    if not self.inst.sg or not self.inst.player_classified or not motorbike or not motorbike:IsValid() then
        return
    end
    self:ResetVariables()
    self.motorbike=motorbike
    self.angle=self.motorbike.components.motorbike.angle
    --self:StartHeadlights()
    self.inst.sg:GoToState("onmotorbike")
    self.inst.player_classified.motorbike_ison:set(true)
    self.inst.Physics:SetMotorVel(self.speed,0,0)
    self.inst.Physics:Stop()
    self.inst:StartUpdatingComponent(self)
    
    if not self.inst.components.activatable then
        self.inst:AddComponent('activatable')
	    self.inst.components.activatable.OnActivate = OnActivate
        self.inst.components.activatable.CanActivateFn = CanActivate
        self.inst.components.activatable.standingaction = true
    end
    
    self.player_mass = self.inst.Physics:GetMass()
    self.inst.Physics:SetMass(5000)
    
    SpawnPrefab('collapse_small').Transform:SetPosition(self.inst:GetPosition():Get())
    
end

function MotorbikeDriver:TurnOff()
    for k, v in pairs(self.passengers) do
        if v.components.motorbikepassenger then
            v.components.motorbikepassenger:DropOff()
        end
    end

    if not self.inst.sg or not self.inst.player_classified or not self.inst.sg.currentstate.name == "onmotorbike" then
        return
    end
    if self.inst.sg.currentstate.name ~="death" then
        self.inst.sg:GoToState("idle")
    end

    self.inst.player_classified.motorbike_ison:set(false)
    self.inst:StopUpdatingComponent(self)
    self.inst.Physics:Stop()
    if self.motorbike and self.motorbike:IsValid() then
        self.motorbike.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        self.motorbike.components.motorbike:SetDriver()
    end
    self.inst:DoTaskInTime(FRAMES, function(inst)
        self.inst.AnimState:SetDeltaTimeMultiplier(1)
        self.motorbike = nil
    end)
    
    if self.inst.components.activatable ~= nil then
        self.inst:RemoveComponent('activatable')
    end
    
    self.inst.Physics:SetMass(self.player_mass)
    
    SpawnPrefab('collapse_small').Transform:SetPosition(self.inst:GetPosition():Get())
end

function MotorbikeDriver:ChooseAnim()
    self.anim_speed = 5*self.speed/self.accelerate_factor*self.damping_factor
    self.inst.AnimState:SetDeltaTimeMultiplier(self.anim_speed)
end

function MotorbikeDriver:OnUpdate(dt)
    if not self.motorbike or not self.motorbike:IsValid() then
        self:TurnOff()
        return
    end
    
    self.inst.Transform:SetScale(1,1,1)
    
    local speed_x, speed_y, speed_z = self.inst.Physics:GetVelocity()
    
    
    local rv=math.sqrt(speed_x*speed_x+speed_z*speed_z)
    local dv=self.speed-rv

    if dv*dv > self.dv_threshold*self.dv_threshold then
        if self.speed > self.knockback_threshold then
            self:TurnOff()
            self.inst:PushEvent("attacked", {attacker = self.motorbike, damage = 0})
            self.inst:PushEvent('knockback', { knocker = self.motorbike, radius = 5})
            local pos = self.inst:GetPosition()
            local ent = TheSim:FindEntities(pos.x,pos.y,pos.z, 1.5, {'_combat'}, {'player'})
            for k,v in pairs(ent) do
                if v and v:IsValid() and v.components.health and v.components.health.currenthealth > 0 and v.components.combat then
                    v:PushEvent("attacked", {attacker=self.inst, damage=self.crash_damage})
                end
            end
            local ent = TheSim:FindEntities(pos.x,pos.y,pos.z, 2.5, {},{'motorbike'}, {'CHOP_workable', 'DIG_workable', 'HAMMER_workable', 'MINE_workable'})
            for k,v in pairs(ent) do
                if v and v:IsValid() and v.components.workable and v.components.workable.workleft > 0 then
                    v.components.workable:WorkedBy(self.inst, 30)
                end
            end
            SpawnPrefab("collapse_small").Transform:SetPosition(self.motorbike:GetPosition():Get())
        elseif self.speed > 0 then
            self.speed=rv
        else
            self.speed=-rv
        end
    end
    
    self.speedar_angle=(1-self.damping_angle)*self.speedar_angle+self.key_turning*self.turning_factor*self.speed
    self.angle=self.angle+self.speedar_angle
    
    self.motorbike.components.motorbike.angle=self.angle
    
    if self.motorbike.components.motorbike.fuel <= 0 then
        self.key_accelerate=0
        if self.speed < 0 then
            self.key_brake=0
        end
    end
    
    self.speed=(
        (1-self.damping_factor)*self.speed+
        self.accelerate_factor*self.key_accelerate*
        (self.motorbike.components.motorbike.heat/self.motorbike.components.motorbike.heat_max)
    )
    if self.key_brake > 0.1 then
        if self.speed > 0 then
            self.speed=self.speed-self.brake_factor
        else
            self.speed=self.speed-self.reverse_factor
        end
    end
    
    
    if not (self.key_accelerate+self.key_brake) and self.speed*self.speed < 0.1 then 
        self.speed=0
    end
    
    self.inst.Physics:SetMotorVel(self.speed,0,0)
    
    if self.speed*self.speed < 0.25 then
        self.holding_dropoff=self.key_dropoff*(self.holding_dropoff+self.key_dropoff)
    end
    
    if self.holding_dropoff > self.holding_dropoff_turnoff then
        self:TurnOff()
    end
    
    if self.inst.player_classified then
        self.inst.Transform:SetRotation(self.angle)
        self.inst.player_classified.motorbike_angle:set(self.angle)
        self.inst.player_classified.motorbike_speed:set(self.speed)
        if self.motorbike ~= nil then
            self.inst.player_classified.motorbike_speed_frac:set(self.speed / (self.accelerate_factor/self.damping_factor ) )
            self.inst.player_classified.motorbike_heat_frac:set(self.motorbike.components.motorbike.heat/self.motorbike.components.motorbike.heat_max)
            
            if self.motorbike.components.container and 
               self.motorbike.components.container:IsFull() and
               self.motorbike.components.container.slots[1].components.finiteuses ~= nil then
                self.inst.player_classified.motorbike_fuel_frac:set(
                    (
                    self.motorbike.components.container.slots[1].components.finiteuses.current + 
                    self.motorbike.components.motorbike.fuel / self.motorbike.components.motorbike.fuel_max
                    ) / self.motorbike.components.container.slots[1].components.finiteuses.total
                )
            end
            
        end
    end
    
    self:ChooseAnim()
    
    self.key_accelerate=0
    self.key_brake=0
    self.key_dropoff=0
    self.key_turning=0
    
    
end

return MotorbikeDriver
