Script.Load("lua/Hud/Marine/GUIMarineHUDElement.lua")
Script.Load("lua/Hud/Marine/GUIMarineHUDStyle.lua")

class 'GUIMarineStatus' (GUIMarineHUDElement)

function CreateStatusDisplay(scriptHandle, hudLayer, frame)
    local marineStatus = GUIMarineStatus()
    marineStatus.script = scriptHandle
    marineStatus.hudLayer = hudLayer
    marineStatus.frame = frame
    marineStatus:Initialize()
    
    return marineStatus 
end

NO_PARASITE = 1
PARASITED = 2
ON_INFESTATION = 3

GUIMarineStatus.kParasiteTextureName = PrecacheAsset("ui/parasite_hud.dds")
GUIMarineStatus.kParasiteTextureCoords = { 0, 0, 64, 64 }
GUIMarineStatus.kParasiteSize = Vector(54, 54, 0)
GUIMarineStatus.kParasitePos = Vector(70, 0, 0)

GUIMarineStatus.kParasiteColor = {}
GUIMarineStatus.kParasiteColor[NO_PARASITE] = Color(0,0,0,0)
GUIMarineStatus.kParasiteColor[PARASITED] = Color(0xFF / 0xFF, 0xFF / 0xFF, 0xFF / 0xFF, 0.8)
GUIMarineStatus.kParasiteColor[ON_INFESTATION] = Color(0.7, 0.4, 0.4, 0.8)

GUIMarineStatus.kStatusTexture = PrecacheAsset("ui/marine_HUD_status.dds")
GUIMarineStatus.kBackgroundCoords = { 0, 0, 300, 121 }
GUIMarineStatus.kBackgroundPos = Vector(30, -160, 0)
GUIMarineStatus.kBackgroundSize = Vector(GUIMarineStatus.kBackgroundCoords[3], GUIMarineStatus.kBackgroundCoords[4], 0)
GUIMarineStatus.kStencilCoords = { 0, 140, 300, 140 + 121 }

GUIMarineStatus.kHealthTextPos = Vector(30, -16, 0)
GUIMarineStatus.kArmorTextPos = Vector(120, -16, 0)

GUIMarineStatus.kFontName = "fonts/AgencyFB_large_bold.fnt"

GUIMarineStatus.kArmorBarColor = Color(32/255, 222/255, 253/255, 0.8)
GUIMarineStatus.kHealthBarColor = Color(163/255, 210/255, 220/255, 0.8)

GUIMarineStatus.kAnimSpeedDown = 0.2
GUIMarineStatus.kAnimSpeedUp = 0.5

function GUIMarineStatus:Initialize()

    self.scale = 1

    self.lastHealth = 0
    self.lastArmor = 0
    self.lastParasiteState = 1
    
    self.statusbackground = self.script:CreateAnimatedGraphicItem()
    self.statusbackground:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.statusbackground:SetTexture(GUIMarineStatus.kStatusTexture)
    self.statusbackground:SetTexturePixelCoordinates(unpack(GUIMarineStatus.kBackgroundCoords))
    self.statusbackground:AddAsChildTo(self.frame)
    
    self.healthText = self.script:CreateAnimatedTextItem()
    self.healthText:SetNumberTextAccuracy(1)
    self.healthText:SetFontName(GUIMarineStatus.kFontName)
    self.healthText:SetTextAlignmentX(GUIItem.Align_Min)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.healthText:SetLayer(self.hudLayer + 1)
    self.healthText:SetColor(GUIMarineStatus.kHealthBarColor)
    self.statusbackground:AddChild(self.healthText)
    
    self.armorText = self.script:CreateAnimatedTextItem()
    self.armorText:SetNumberTextAccuracy(1)
    self.armorText:SetText(tostring(self.lastHealth))
    self.armorText:SetFontName(GUIMarineStatus.kFontName)
    self.armorText:SetTextAlignmentX(GUIItem.Align_Min)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.armorText:SetLayer(self.hudLayer + 1)
    self.armorText:SetColor(GUIMarineStatus.kArmorBarColor)
    self.statusbackground:AddChild(self.armorText)

    self.parasiteState = self.script:CreateAnimatedGraphicItem()
    self.parasiteState:SetTexture(GUIMarineStatus.kParasiteTextureName)
    self.parasiteState:SetTexturePixelCoordinates(unpack(GUIMarineStatus.kParasiteTextureCoords))
    self.parasiteState:AddAsChildTo(self.statusbackground)
    self.parasiteState:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.parasiteState:SetColor(GUIMarineStatus.kParasiteColor[NO_PARASITE])
    self.parasiteState:SetBlendTechnique(GUIItem.Add)
end

function GUIMarineStatus:Reset(scale)

    self.scale = scale

    self.statusbackground:SetUniformScale(scale)
    self.statusbackground:SetPosition(GUIMarineStatus.kBackgroundPos)
    self.statusbackground:SetSize(GUIMarineStatus.kBackgroundSize)
   
    self.healthText:SetUniformScale(self.scale)
    self.healthText:SetScale(GetScaledVector())
    self.healthText:SetPosition(GUIMarineStatus.kHealthTextPos)
    
    self.armorText:SetUniformScale(self.scale)
    self.armorText:SetScale(GetScaledVector() * 0.8)
    self.armorText:SetPosition(GUIMarineStatus.kArmorTextPos)

    self.parasiteState:SetUniformScale(self.scale)
    self.parasiteState:SetSize(GUIMarineStatus.kParasiteSize)
    self.parasiteState:SetPosition(GUIMarineStatus.kParasitePos)
    
end

function GUIMarineStatus:Destroy()

    if self.statusbackground then
        self.statusbackground:Destroy()
    end

    if self.healthText then
        self.healthText:Destroy()
    end   
    
    if self.armorText then
        self.armorText:Destroy()
    end  

end

function GUIMarineStatus:SetIsVisible(visible)
    self.statusbackground:SetIsVisible(visible)
end

local kLowHealth = 40
local kLowHealthAnimRate = 0.3

local function LowHealthPulsate(script, item)

    item:SetColor(Color(0.7, 0, 0, 1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, 
        function (script, item)        
            item:SetColor(Color(1, 0, 0,1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowHealthPulsate )        
        end )

end

--// set armor/health and trigger effects accordingly (armor bar particles)
function GUIMarineStatus:Update(deltaTime, parameters)

    if table.count(parameters) < 4 then
        Print("WARNING: GUIMarineStatus:Update received an incomplete parameter table.")
    end
    
    local currentHealth, maxHealth, currentArmor, maxArmor, parasiteState = unpack(parameters)
    
    if currentHealth ~= self.lastHealth then
    
	    local healthFraction = currentHealth / maxHealth

        if currentHealth < self.lastHealth then
            self.healthText:DestroyAnimation("ANIM_TEXT")
            self.healthText:SetText(tostring(math.ceil(currentHealth)))
       else
            self.healthText:SetNumberText(tostring(math.ceil(currentHealth)), GUIMarineStatus.kAnimSpeedUp, "ANIM_TEXT")
       end
	    
	    self.lastHealth = currentHealth
	    
	    if self.lastHealth < kLowHealth  then
	    
	        if not self.lowHealthAnimPlaying then
                self.lowHealthAnimPlaying = true
                self.healthText:SetColor(Color(1, 0, 0, 1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowHealthPulsate )
	        end
	        
	    else
            self.lowHealthAnimPlaying = false
            self.healthText:DestroyAnimation("ANIM_HEALTH_PULSATE")
        end    
    
    end
    
    if currentArmor ~= self.lastArmor then
    
        local animSpeed = ConditionalValue(currentArmor < self.lastArmor, GUIMarineStatus.kAnimSpeedDown, GUIMarineStatus.kAnimSpeedUp)
        
        local armorFraction = currentArmor / maxArmor

        if self.lastArmor > currentArmor then
            self.armorText:SetText(tostring(math.ceil(currentArmor)))
        else
            self.armorText:DestroyAnimations()
            self.armorText:SetNumberText(tostring(math.ceil(currentArmor)), animSpeed)
        end
        
        self.lastArmor = currentArmor

    end
    
    // update parasite state
    
    if self.lastParasiteState ~= parasiteState then

        self.parasiteState:DestroyAnimations()
        self.parasiteState:SetColor(GUIMarineStatus.kParasiteColor[parasiteState], 0.3)
        
        if self.lastParasiteState < parasiteState then
            self.parasiteState:SetSize(GUIMarineStatus.kParasiteSize * 1.55)
            self.parasiteState:SetSize(GUIMarineStatus.kParasiteSize, 0.4)
        end
        
        self.lastParasiteState = parasiteState
    end
    
end
