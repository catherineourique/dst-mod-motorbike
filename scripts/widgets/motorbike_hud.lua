local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"

local function MotorbikeHUDOnOff(self)
    if  self.owner ~= nil and
        self.owner.player_classified ~= nil and
        self.owner.player_classified.motorbike_ison ~= nil and
        self.owner.player_classified.motorbike_ison:value() then
        self:OpenMotorbikeHUD()
        self:Show()
        return true
    end
    self:CloseMotorbikeHUD()
    return false
end


local MotorbikeHUD = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "MotorbikeHUD")
    
    self.screensize_x, self.screensize_y=TheSim:GetScreenSize()
    self.ssx=self.screensize_x/1432.
    self.ssy=self.screensize_y/812.
    
    self.instructions = self:AddChild(UIAnim())
    self.instructions:GetAnimState():SetBank("motorbike_hud")
    self.instructions:GetAnimState():SetBuild("motorbike_hud")
    self.instructions:GetAnimState():SetPercent("instructions_close", 1)
    self.instructions:SetScale(0.7,0.7)
    self.instructions:SetPosition(0,500)
    self.instructions.is_open = false


    self.base = self:AddChild(UIAnim())
    self.base:GetAnimState():SetBank("motorbike_hud")
    self.base:GetAnimState():SetBuild("motorbike_hud")
    self.base:GetAnimState():SetPercent("base", 0)
    self.base:SetScale(1.3,1.3)
    
    self.base_rot = 0
    self.base_rot_max = 5
    self.base_rot_ratio = 0.075
    
    self.open_pos = 7
    self.closed_pos = -167
    self.delta_pos = 10
    self.hud_pos = self.closed_pos
    
    self.base:SetPosition(0,self.hud_pos)
    
    self.is_open = false
    self.is_opening = false
    
    self.speed_meter = self.base:AddChild(UIAnim())
    self.speed_meter:GetAnimState():SetBank("motorbike_hud")
    self.speed_meter:GetAnimState():SetBuild("motorbike_hud")
    self.speed_meter:GetAnimState():PlayAnimation("speed_meter",false)
    self.speed_meter:GetAnimState():SetDeltaTimeMultiplier(0)
    self.speed_meter:GetAnimState():SetTime(0)
    self.speed_meter:SetScale(0.30,0.30)
    self.speed_meter:SetPosition(0,10)
    
    self.speed_meter.animation_max = self.speed_meter:GetAnimState():GetCurrentAnimationLength()

    self.fuel_meter = self.base:AddChild(UIAnim())
    self.fuel_meter:GetAnimState():SetBank("motorbike_hud")
    self.fuel_meter:GetAnimState():SetBuild("motorbike_hud")
    self.fuel_meter:GetAnimState():PlayAnimation("water_meter",false)
    self.fuel_meter:GetAnimState():SetDeltaTimeMultiplier(0)
    self.fuel_meter:SetScale(0.30,0.30)
    self.fuel_meter:SetPosition(-100,20)
    
    self.fuel_meter.animation_max = self.fuel_meter:GetAnimState():GetCurrentAnimationLength()
    self.fuel_frac_delta = 0
    self.fuel_frac_vel = 0
    
    self.heat_meter = self.base:AddChild(UIAnim())
    self.heat_meter:GetAnimState():SetBank("motorbike_hud")
    self.heat_meter:GetAnimState():SetBuild("motorbike_hud")
    self.heat_meter:GetAnimState():PlayAnimation("heat_meter",false)
    self.heat_meter:GetAnimState():SetDeltaTimeMultiplier(0)
    self.heat_meter:SetScale(0.30,0.30)
    self.heat_meter:SetPosition(100,30)
    
    self.heat_meter.animation_max = self.heat_meter:GetAnimState():GetCurrentAnimationLength()
    self.heat_frac_delta = 0
    self.heat_frac_vel = 0

    self.brake = self.base:AddChild(UIAnim())
    self.brake:GetAnimState():SetBank("motorbike_hud")
    self.brake:GetAnimState():SetBuild("motorbike_hud")
    self.brake:GetAnimState():SetPercent("brake", 0)
    self.brake:SetScale(0.55,0.55)
    self.brake:SetPosition(-215,65)
    
    self.brake_rot = 0
    self.brake_rot_max = 12
    self.brake_rot_ratio = 0.1
    

    self.gas = self.base:AddChild(UIAnim())
    self.gas:GetAnimState():SetBank("motorbike_hud")
    self.gas:GetAnimState():SetBuild("motorbike_hud")
    self.gas:GetAnimState():SetPercent("brake", 0)
    self.gas:SetScale(-0.55,0.55)
    self.gas:SetPosition(220,70)
    
    self.gas_rot = 0
    self.gas_rot_max = 12
    self.gas_rot_ratio = 0.1
    
    self.brake_screw = self.base:AddChild(UIAnim())
    self.brake_screw:GetAnimState():SetBank("motorbike_hud")
    self.brake_screw:GetAnimState():SetBuild("motorbike_hud")
    self.brake_screw:GetAnimState():SetPercent("screw", 0)
    self.brake_screw:SetScale(0.2,0.2)
    self.brake_screw:SetPosition(-215,65)
    
    self.gas_screw = self.base:AddChild(UIAnim())
    self.gas_screw:GetAnimState():SetBank("motorbike_hud")
    self.gas_screw:GetAnimState():SetBuild("motorbike_hud")
    self.gas_screw:GetAnimState():SetPercent("screw", 0)
    self.gas_screw:SetScale(-0.2,0.2)
    self.gas_screw:SetPosition(220,70)
    
    self.togglebutton = self:AddChild(ImageButton())
    self.togglebutton:SetScale(.6,.6,.6)
    self.togglebutton:SetText("Hide Panel")
    self.togglebutton:SetOnClick( function() self:ToggleHUD() end )
    self.togglebutton:SetPosition(-600,25,0)
    
    self.togglebutton = self:AddChild(ImageButton())
    self.togglebutton:SetScale(.6,.6,.6)
    self.togglebutton:SetText("Instructions")
    self.togglebutton:SetOnClick( function() self:ToggleInstructions() end )
    self.togglebutton:SetPosition(-600,65,0)
    
    self.inst:ListenForEvent("motorbike_ison", function(inst)
        MotorbikeHUDOnOff(self)
    end, self.owner.player_classified)
    
    self:StartUpdating()

end)

function MotorbikeHUD:ToggleHUD()
    if (self.is_opening and not self.is_open) or (not self.is_opening and self.is_open) then
        return
    end

    self.is_opening = not self.is_opening
    if self.is_opening then
        self:StartUpdating()
        self:Show()
        self.base:Show()
        self.togglebutton:SetText("Hide Panel")
    else
        self.togglebutton:SetText("Show Panel")
    end
end

function MotorbikeHUD:ToggleInstructions()
    self.instructions.is_open = not self.instructions.is_open
    if self.instructions.is_open then
        self.instructions:GetAnimState():PlayAnimation('tutorial_open', false)
    else
        self.instructions:GetAnimState():PlayAnimation('tutorial_close', false)
    end
end



function MotorbikeHUD:OpenMotorbikeHUD()
    local speed_frac, heat_frac, fuel_frac
    
    speed_frac = ThePlayer.player_classified.motorbike_speed_frac:value()
    heat_frac = ThePlayer.player_classified.motorbike_heat_frac:value()
    fuel_frac = ThePlayer.player_classified.motorbike_fuel_frac:value()

    self.speed_meter:GetAnimState():SetDeltaTimeMultiplier(0)
    self.speed_meter:GetAnimState():SetTime(speed_frac*self.speed_meter.animation_max)
    self.fuel_meter:GetAnimState():SetDeltaTimeMultiplier(0)
    self.fuel_meter:GetAnimState():SetTime(fuel_frac*self.fuel_meter.animation_max)
    self.heat_meter:GetAnimState():SetDeltaTimeMultiplier(0)
    self.heat_meter:GetAnimState():SetTime(heat_frac*self.heat_meter.animation_max)
    self.heat_frac_delta = 0
    self.heat_frac_vel = 0
    self.fuel_frac_delta = 0
    self.fuel_frac_vel = 0
    self:Show()
    self.base:Show()
    self:StartUpdating()
    self.instructions:GetAnimState():SetPercent("instructions_close", 1)
    self.instructions.is_open = false
    
    self.is_opening = true
end

function MotorbikeHUD:CloseMotorbikeHUD()
    self.is_opening = false
    self.instructions_is_opening = false
end

function MotorbikeHUD:OnUpdate(dt)
    if not ThePlayer.player_classified or not ThePlayer.player_classified.motorbike_turn then
        return
    end
    
    local ison = self.owner.player_classified.motorbike_ison:value()
    
    if self.is_opening and not self.is_open then
        self.hud_pos = self.hud_pos + self.delta_pos
        if self.hud_pos >= self.open_pos then
            self.is_open = true
            self.hud_pos = self.open_pos
        end
        self.base:SetPosition(0,self.hud_pos)
    end

    if not self.is_opening and self.is_open then
        self.hud_pos = self.hud_pos - self.delta_pos
        if self.hud_pos <= self.closed_pos then
            self.is_open = false
            self.hud_pos = self.closed_pos
            self.base:Hide()
            self:StopUpdating()
            if not ison then
                self:Hide()
            end
        end
        self.base:SetPosition(0,self.hud_pos)
    end    
    
    local gas, brake, turn, speed_frac, heat_frac, fuel_frac, speed_frac_delta, speed_sign
    
    gas = ThePlayer.player_classified.motorbike_gas
    brake = ThePlayer.player_classified.motorbike_brake
    turn = ThePlayer.player_classified.motorbike_turn
    speed_frac = ThePlayer.player_classified.motorbike_speed_frac:value()
    heat_frac = ThePlayer.player_classified.motorbike_heat_frac:value()
    fuel_frac = ThePlayer.player_classified.motorbike_fuel_frac:value()
    
    speed_sign = speed_frac ~= 0 and math.abs(speed_frac)/speed_frac or 1
    brake = brake * (0.5 * (1+speed_sign))

    -- SPEED

    speed_frac_delta = 0.25*(math.random()-0.5)*speed_frac
    
    self.speed_meter_time = self.speed_meter:GetAnimState():GetCurrentAnimationTime()
    self.speed_meter_expe = speed_frac*(1 + speed_frac_delta) * self.speed_meter.animation_max
    if self.speed_meter_expe > self.speed_meter.animation_max then
        self.speed_meter_expe = self.speed_meter.animation_max
    end
    if self.speed_meter_expe < 0 then
        self.speed_meter_expe = 0
    end
    self.speed_meter_delta = self.speed_meter_expe - self.speed_meter_time
    self.speed_meter:GetAnimState():SetDeltaTimeMultiplier(3*self.speed_meter_delta)
    
    -- HEAT
    
    self.heat_meter_time = self.heat_meter:GetAnimState():GetCurrentAnimationTime()
    self.heat_meter_expe = heat_frac * self.heat_meter.animation_max
    if self.heat_meter_expe > self.heat_meter.animation_max then
        self.heat_meter_expe = self.heat_meter.animation_max
    end
    if self.heat_meter_expe < 0 then
        self.heat_meter_expe = 0
    end
    self.heat_meter_delta = self.heat_meter_expe - self.heat_meter_time
    self.heat_meter:GetAnimState():SetDeltaTimeMultiplier(3*self.heat_meter_delta)
    
    -- FUEL
    
    self.fuel_frac_vel = self.fuel_frac_vel - 0.03*self.fuel_frac_delta + 0.0025*(math.random()-0.5)
    self.fuel_frac_delta = self.fuel_frac_delta+self.fuel_frac_vel
    if math.abs(self.fuel_frac_delta) > 0.05 then
        self.fuel_frac_delta = math.abs(self.fuel_frac_delta)/self.fuel_frac_delta*0.05
    end
    
    self.fuel_meter_time = self.fuel_meter:GetAnimState():GetCurrentAnimationTime()
    self.fuel_meter_expe = fuel_frac*(1 + self.fuel_frac_delta) * self.fuel_meter.animation_max
    if self.fuel_meter_expe > self.fuel_meter.animation_max then
        self.fuel_meter_expe = self.fuel_meter.animation_max
    end
    if self.fuel_meter_expe < 0 then
        self.fuel_meter_expe = 0
    end
    self.fuel_meter_delta = self.fuel_meter_expe - self.fuel_meter_time
    self.fuel_meter:GetAnimState():SetDeltaTimeMultiplier(3*self.fuel_meter_delta)
    
    -- BASE

    self.base_rot = self.base_rot + self.base_rot_ratio*(self.base_rot_max*turn-self.base_rot)
    if math.abs(self.base_rot) > self.base_rot_max then
        self.base_rot = self.base_rot_max * self.base_rot / math.abs(self.base_rot)
    end
    if math.abs(self.base_rot) < self.base_rot_ratio/2 then
        self.base_rot = 0
    end
    self.base:SetRotation(self.base_rot)
    
    -- BRAKE
    
    self.brake_rot = self.brake_rot + self.brake_rot_ratio*(-self.brake_rot_max*brake-self.brake_rot)
    if math.abs(self.brake_rot) > self.brake_rot_max then
        self.brake_rot = self.brake_rot_max * self.brake_rot / math.abs(self.brake_rot)
    end
    if math.abs(self.brake_rot) < self.brake_rot_ratio/2 then
        self.brake_rot = 0
    end
    self.brake:SetRotation(self.brake_rot)
    
    -- GAS

    self.gas_rot = self.gas_rot + self.gas_rot_ratio*(-self.gas_rot_max*gas-self.gas_rot)
    if math.abs(self.gas_rot) > self.gas_rot_max then
        self.gas_rot = self.gas_rot_max * self.gas_rot / math.abs(self.gas_rot)
    end
    if math.abs(self.gas_rot) < self.gas_rot_ratio/2 then
        self.gas_rot = 0
    end
    self.gas:SetRotation(self.gas_rot)
end

return MotorbikeHUD
