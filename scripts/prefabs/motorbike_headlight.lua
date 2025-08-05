require "prefabutil"

local assets =
{
}

local prefabs =
{
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform() -- Coordenadas
    inst.entity:AddNetwork()
    inst.entity:AddLight()
    
    inst.Light:Enable(false)
    inst.Light:SetFalloff(.8)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetRadius(3)
    inst.Light:SetColour(255 / 255, 248 / 255, 198 / 255)
    

    inst:AddTag("DECOR")
    inst:AddTag("noclick")
    inst:AddTag("noblock")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("motorbike_headlight", fn, assets, prefabs)
