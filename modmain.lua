local _G = GLOBAL

-- From Show Me (Origin)
local SERVER_SIDE = _G.TheNet:GetIsServer()
local CLIENT_SIDE =	 _G.TheNet:GetIsClient() or (SERVER_SIDE and not _G.TheNet:IsDedicated())


Assets = {
    Asset("ANIM", "anim/motorbike_passenger_build.zip"),
    Asset("ANIM", "anim/motorbike_passenger_anim.zip"),
    Asset("ANIM", "anim/motorbike_hud.zip"),
    Asset("ANIM", "anim/motorbike_ui.zip"),
    Asset("ATLAS", "minimap/motorbike_minimap.xml" ),
    Asset("IMAGE", "minimap/motorbike_minimap.tex" ),
    Asset("ATLAS", "images/inventoryimages/motorbike.xml" ),
    Asset("IMAGE", "images/inventoryimages/motorbike.tex" ),
    Asset("ATLAS", "images/motorbike_slot_bg.xml" ),
    Asset("IMAGE", "images/motorbike_slot_bg.tex" ),
}

PrefabFiles =
{
    "motorbike",
    "motorbike_headlight",
    "motorbike_puff",
}

AddMinimapAtlas("minimap/motorbike_minimap.xml")

AddRecipe("motorbike",
	{
		_G.Ingredient("gears", 2),
		_G.Ingredient("boards", 3),
		_G.Ingredient("saddle_basic", 1),
	},
	_G.RECIPETABS.SCIENCE,
	_G.TECH.SCIENCE_TWO,
	"motorbike_placer", -- placer
	1.5, -- min_spacing
	nil, -- nounlock
	nil, -- numtogive
	nil, -- builder_tag
	"images/inventoryimages/motorbike.xml", -- atlas
	"motorbike.tex" -- image
)


GLOBAL.STRINGS.NAMES.MOTORBIKE = "Motorbike"
GLOBAL.STRINGS.RECIPE_DESC.MOTORBIKE = "STEAM powered!"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.MOTORBIKE = "STEAM powered!"

-- ThePlayer.components.motorbikedriver:TurnOn()

modimport('scripts/motorbike_rpc_handlers')


-----------------------------------------------

local function AddMotorbikeHUD(self)

	self.inst:DoTaskInTime( 0, function()

        local MotorbikeHUD = require "widgets/motorbike_hud"
		self.motorbike_hud = self.bottom_root:AddChild( MotorbikeHUD(self.owner) )
		self.motorbike_hud.curr_pos=self.motorbike_hud.closed_pos
		self.motorbike_hud:SetPosition(0,0)
		local hud_scale = self.bottom_root:GetScale()
	    local screensize_x, screensize_y
	    screensize_x, screensize_y=_G.TheSim:GetScreenSize()
        local ssx=screensize_x/1432./hud_scale.x
        local ssy=screensize_y/812./hud_scale.y
        self.motorbike_hud:SetScale(ssx,ssy)
		self.motorbike_hud:Hide()
	end)

end

AddClassPostConstruct( "widgets/controls", AddMotorbikeHUD )


-----------------------------------------------

local containers = require "containers"
local params = {}

local containers_widgetsetup_pf = containers.widgetsetup  
function containers.widgetsetup(container, prefab, data, ...)
    local t = params[prefab or container.inst.prefab]
    if t ~= nil then
        for k, v in pairs(t) do
            container[k] = v
        end
        container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
    else
        containers_widgetsetup_pf(container, prefab, data, ...)
    end
end

params.motorbike =
{
    widget =
    {
        slotpos =
        {
            _G.Vector3(0, 7, 0),
        },
        animbank = "motorbike_ui",
        animbuild = "motorbike_ui",
        pos = _G.Vector3(200, 0, 0),
        side_align_tip = 120,
        slotbg =
        {
            { 
                image = "motorbike_slot_bg.tex",
                atlas = "images/motorbike_slot_bg.xml"
            },
        },
        buttoninfo =
        {
            text = 'Drive!',
            position = _G.Vector3(0, -53, 0),
        }
    },
    type = "chest",
}


function params.motorbike.itemtestfn(container, item, slot)
    return item:HasTag("wateringcan")
end

function params.motorbike.widget.buttoninfo.fn(inst, doer)
    SendModRPCToServer(MOD_RPC.motorbike.drive, inst)
end

function params.motorbike.widget.buttoninfo.validfn(inst)
    return inst.replica.container ~= nil and inst.replica.container:IsFull()
end


---------------------------------------------------------------------------------------------


AddPlayerPostInit(function(inst)
    inst.AnimState:AddOverrideBuild("motorbike")
    inst.AnimState:AddOverrideBuild("motorbike_passenger_build")
end)

AddPrefabPostInit("player_classified",function(inst)
    inst.motorbike_ison = _G.net_bool(inst.GUID, "motorbike_ison", "motorbike_ison")
    inst.motorbike_passenger_ison = _G.net_bool(inst.GUID, "motorbike_passenger_ison", "motorbike_passenger_ison")
    inst.motorbike_angle = _G.net_float(inst.GUID, "motorbike_angle")
    inst.motorbike_speed = _G.net_float(inst.GUID, "motorbike_speed")
    inst.motorbike_speed_frac = _G.net_float(inst.GUID, "motorbike_speed_frac")
    inst.motorbike_heat_frac = _G.net_float(inst.GUID, "motorbike_heat_frac")
    inst.motorbike_fuel_frac = _G.net_float(inst.GUID, "motorbike_fuel_frac")
    inst:DoTaskInTime(0,function(inst)
        local parent=inst.entity:GetParent()
        if SERVER_SIDE then
            parent:AddComponent("motorbikedriver")
            parent:AddComponent("motorbikepassenger")
            parent._motorbike_old_OnDespawn=parent.OnDespawn
            parent.OnDespawn = function(inst, migrationdata)
                if parent.components.motorbikedriver and parent.components.motorbikedriver.motorbike ~= nil then
                    parent.components.motorbikedriver:TurnOff()
                end
                return parent._motorbike_old_OnDespawn(inst,migrationdata)
            end
        end
        if CLIENT_SIDE then
            parent:AddComponent("motorbikecontroller")
            inst:ListenForEvent("motorbike_ison", function(inst,data)
                local parent=inst.entity:GetParent()
                if parent ~= nil and parent.components.motorbikecontroller
                   and inst.motorbike_ison:value() then
                    parent.components.motorbikecontroller:TurnOn(true)
                else
                    parent.components.motorbikecontroller:TurnOff()
                end
            end)
            inst:ListenForEvent("motorbike_passenger_ison", function(inst,data)
                local parent=inst.entity:GetParent()
                if parent ~= nil and parent.components.motorbikecontroller
                   and inst.motorbike_passenger_ison:value() then
                    parent.components.motorbikecontroller:TurnOn(false)
                else
                    parent.components.motorbikecontroller:TurnOff()
                end
            end)
        end
    end)
end)

AddPrefabPostInit("charcoal",function(inst)
    if not inst.components.tradable then
        inst:AddComponent("tradable")    
    end
end)

AddPrefabPostInit("motorbike",function(inst)
    if SERVER_SIDE then
        inst.charcoal_mult = GetModConfigData("MOTOBIKE_CHARCOAL_RATE")
        inst.components.motorbike.fuel_mult = GetModConfigData("MOTOBIKE_FUEL_RATE")
        inst.components.motorbike.heat_mult = GetModConfigData("MOTOBIKE_HEAT_RATE")
        inst.components.motorbike.drop_on_exit = GetModConfigData("MOTOBIKE_DROP_CAN_ON_EXIT")
    end
end)

OnMotorbike = require("motorbike_stategraphs")

AddStategraphState("wilson",OnMotorbike)
