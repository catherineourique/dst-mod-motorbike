require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/motorbike.zip"),
    Asset("ANIM", "anim/motorbike_driver.zip"),
}

local prefabs =
{
    "collapse_small",
    "motorbike_headlight",
}

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("motorbike", false)
end

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end


local function OnActivate(inst, doer)
	if doer.components.motorbikedriver then
	    --inst:RemoveComponent("activatable")
	    inst.components.activatable.inactive=true
	    inst.components.motorbike:SetDriver(doer)
    	return true
	end
    return false	
end

local function CanActivate(inst, doer)
	return false
end

local function ShouldAcceptItem(inst, item)
    return item.prefab=="charcoal" and inst.components.motorbike.heat/inst.components.motorbike.heat_max < 0.95
end

local function AddHeat(inst, giver, item)
    inst.components.motorbike:DoDeltaHeat(inst.charcoal_mult*inst.charcoal_base)
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform() -- Coordenadas
    inst.entity:AddAnimState() -- Animações
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter() --
    inst.entity:AddNetwork()


    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("motorbike_minimap")

    inst.Transform:SetFourFaced()
    inst.AnimState:SetBank("motorbike")
    inst.AnimState:SetBuild("motorbike")
    inst.AnimState:PlayAnimation("motorbike")

    inst:AddTag("structure")
    inst:AddTag("motorbike")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
    inst:ListenForEvent("onbuilt", onbuilt)
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("motorbike")
    
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
	
    inst:AddComponent("motorbike")
    
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = AddHeat
    
    inst.charcoal_mult = 1
    inst.charcoal_base = 30

    
    MakeLargeBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)

    inst.OnSave = onsave 
    inst.OnLoad = onload

    return inst
end

return Prefab("motorbike", fn, assets, prefabs),
    MakePlacer("motorbike_placer", "motorbike", "motorbike", "motorbike")
