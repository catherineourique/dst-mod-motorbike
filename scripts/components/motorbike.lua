local Motorbike = Class(function(self, inst)
    self.inst = inst
    self.is_updating=false
    self.angle=0
    self.fuel = 0
    self.fuel_max = 1000
    self.fuel_scale = 0.04
    self.fuel_mult = 1
    self.heat = 0
    self.heat_max = 150
    self.heat_scale = 0.0001
    self.heat_mult = 1
    self.drop_on_exit = false
    self.fx = 0
    self.fx_max = 1000
    self.fx_dr = 0.25
    self.inst:DoTaskInTime(0, function(inst)
        inst:StartUpdatingComponent(inst.components.motorbike)
    end)
    -- Headlights just don't look good due to the required light-distance to it work properly
    --self.headlights_par={{0,0.1, 0.8},{1,0.2,0.7}, {1.5,0.3,0.68},{2,0.4,0.65}, {3,0.55,0.62},{4,0.7,0.6}, {5,1,0.55}, {6.5,1.2,0.5},{9,2,0.4}}
    ----self.headlights={}
    --self.inst:DoTaskInTime(0, function(inst)
    --    inst.components.motorbike:StartHeadlights()
    --end)
end)

function Motorbike:DoDeltaFuel(val)
    self.fuel=self.fuel+val
    if self.fuel < 0 then
        self.fuel=0
    end
    if self.fuel > self.fuel_max then
        self.fuel=self.fuel_max
    end
    --if not self.is_updating then
    --    self.is_updating=true
    --    self.inst:StartUpdatingComponent(self)
    --end
end

function Motorbike:DoDeltaHeat(val)
    self.heat=self.heat+val
    if self.heat < 0 then
        self.heat=0
    end
    if self.heat > self.heat_max then
        self.heat=self.heat_max
    end
    if not self.is_updating then
        self.is_updating=true
        self.inst:StartUpdatingComponent(self)
    end
end


function Motorbike:StartHeadlights()
    for k,v in pairs(self.headlights_par) do
        local light=SpawnPrefab("motorbike_headlight")
        light.entity:SetParent(self.inst.entity)
        light.Transform:SetPosition(v[1],0,0)
        light.Light:SetRadius(v[2])
        light.Light:SetIntensity(v[3])
        light.Light:Enable(true)
        table.insert(self.headlights,light)
    end
end

function Motorbike:StopHeadlights()
    for k,v in pairs(self.headlights) do
        v:Remove()
    end
    self.headlights={}
end

function Motorbike:SetDriver(driver)
    self.inst.Transform:SetRotation(self.angle)
    if not driver or not driver:IsValid() then
        self.inst:ReturnToScene()
        local old_parent = self.inst.entity:GetParent()
        self.inst.entity:SetParent(nil)
        if old_parent and old_parent:IsValid() then
            local op_pos = old_parent:GetPosition()
            self.inst:DoTaskInTime(1*FRAMES, function(inst)
                local angle=2*math.pi*math.random()
                local r = 0.05+0.05*math.random()
                inst.Transform:SetPosition(op_pos.x+r*math.cos(angle),0,op_pos.z+r*math.sin(angle))
            end)
        end
        if self.drop_on_exit then
            self.inst.components.container:DropEverything()
        end
        return
    end
    self.driver=driver
    self.inst:RemoveFromScene()
    self.inst.entity:SetParent(self.driver.entity)
    self.inst.Transform:SetPosition(0,0,0)
    self.driver.components.motorbikedriver:TurnOn(self.inst)
end

function Motorbike:OnSave()
    local data =
    {
        fuel = self.fuel,
        angle = self.angle,
        heat = self.heat,
    }
    return next(data) ~= nil and data or nil
end

function Motorbike:OnLoad(data)
    self.fuel = data.fuel or self.fuel
    self.angle = data.angle or self.angle
    self.heat = data.heat or self.heat
    self.inst:DoTaskInTime(0, function(inst)
        if inst.components.motorbike and inst.components.motorbike.heat > 0 then
            self.is_updating = true
            inst:StartUpdatingComponent(inst.components.motorbike)
        end
    end)
end

function Motorbike:OnUpdate(dt)
    if self.heat <= 0 then
        self.is_updating=false
        self.inst:StopUpdatingComponent(self)
        return
    end

    local world_temperature = TheWorld.state.temperature
    local heat_delta = -self.heat_mult*self.heat_scale*(self.heat_max-world_temperature)
    
    if self.fuel <= 0 and self.inst.components.container:IsFull() then
        local wateringcan = self.inst.components.container.slots[1]
        if wateringcan and wateringcan.components.finiteuses:GetUses() > 0 then
            wateringcan.components.finiteuses:Use(1)
            self:DoDeltaFuel(self.fuel_max)
        end
    end
    
    self:DoDeltaHeat(heat_delta)
    self:DoDeltaFuel(-self.fuel_mult*self.heat*self.fuel_scale)
    
    self.fx = self.fx+self.heat
    if self.fx > self.fx_max and self.fuel > 0 then
        self.fx = 0
        local pos = self.inst:GetPosition()
        SpawnPrefab('motorbike_puff').Transform:SetPosition(
            pos.x + self.fx_dr*math.sin(self.angle*math.pi/180-math.pi/2),
            0,
            pos.z + self.fx_dr*math.cos(self.angle*math.pi/180-math.pi/2)
        )
    end
    
end

return Motorbike
