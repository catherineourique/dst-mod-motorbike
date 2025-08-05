local OnMotorbike = State({
	name = "onmotorbike",
    tags = { "pinned", "nopredict" },

    onenter = function(inst)

        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(false)
            inst.components.playercontroller:Enable(false)
        end
        
        inst.components.inventory:Hide()
        
        if inst.components.motorbikedriver and inst.components.motorbikedriver.motorbike ~= nil then
            inst.AnimState:PlayAnimation("motorbike_driver", true)
        elseif inst.components.motorbikepassenger and inst.components.motorbikepassenger.driver ~= nil then
            inst.AnimState:PlayAnimation("motorbike_passenger", true)
        end
        
        inst.Transform:SetFourFaced()
        inst.AnimState:SetDeltaTimeMultiplier(0)
        inst.AnimState:SetTime(256)
    end,

    onexit = function(inst)
        inst.components.inventory:Show()
        inst.AnimState:SetDeltaTimeMultiplier(1)
        if inst.components.playercontroller ~= nil then
            inst:DoTaskInTime(0.55, function(inst)
                inst.components.playercontroller:EnableMapControls(true)
                inst.components.playercontroller:Enable(true)
            end)
        end
    end,
    
    events =
    {
        EventHandler("attacked", function(inst)
        
            if inst.components.motorbikedriver and inst.components.motorbikedriver.motorbike ~= nil then
                inst.components.motorbikedriver:TurnOff()
            elseif inst.components.motorbikepassenger and inst.components.motorbikepassenger.driver ~= nil then
                inst.components.motorbikepassenger:DropOff()
            end
            
            if inst.components.playercontroller ~= nil then
                inst:DoTaskInTime(0.5, function(inst)
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end)
            end
        end),
        EventHandler("death", function(inst, data)
        
            if inst.components.motorbikedriver and inst.components.motorbikedriver.motorbike ~= nil then
                inst.components.motorbikedriver:TurnOff()
            elseif inst.components.motorbikepassenger and inst.components.motorbikepasenger.driver ~= nil then
                inst.components.motorbikepassenger:DropOff()
            end
            
            if inst.components.playercontroller ~= nil then
                inst:DoTaskInTime(0.5, function(inst)
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end)
            end
        end),
    },
})

return OnMotorbike

