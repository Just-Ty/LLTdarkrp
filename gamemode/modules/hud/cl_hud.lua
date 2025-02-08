--[[---------------------------------------------------------------------------
HUD ConVars
---------------------------------------------------------------------------]]
local ConVars = {}
local HUDWidth
local HUDHeight

local Color = Color
local CurTime = CurTime
local cvars = cvars
local DarkRP = DarkRP
local draw = draw
local GetConVar = GetConVar
local hook = hook
local IsValid = IsValid
local Lerp = Lerp
local localplayer
local math = math
local pairs = pairs
local ScrW, ScrH = ScrW, ScrH
local SortedPairs = SortedPairs
local string = string
local surface = surface
local table = table
local timer = timer
local tostring = tostring
local plyMeta = FindMetaTable("Player")

local colors = {}
colors.black = color_black
colors.blue = Color(0, 0, 255, 255)
colors.brightred = Color(200, 30, 30, 255)
colors.darkred = Color(0, 0, 70, 100)
colors.darkblack = Color(0, 0, 0, 200)
colors.gray1 = Color(0, 0, 0, 155)
colors.gray2 = Color(51, 58, 51,100)
colors.red = Color(255, 0, 0, 255)
colors.white = color_white
colors.white1 = Color(255, 255, 255, 200)

local function ReloadConVars()
    ConVars = {
        background = {0,0,0,100},
        Healthbackground = {0,0,0,200},
        Healthforeground = {140,0,0,180},
        HealthText = {255,255,255,200},
        Job1 = {0,0,150,200},
        Job2 = {0,0,0,255},
        salary1 = {0,150,0,200},
        salary2 = {0,0,0,255}
    }

    for name, Colour in pairs(ConVars) do
        ConVars[name] = {}
        for num, rgb in SortedPairs(Colour) do
            local CVar = GetConVar(name .. num) or CreateClientConVar(name .. num, rgb, true, false)
            table.insert(ConVars[name], CVar:GetInt())

            if not cvars.GetConVarCallbacks(name .. num, false) then
                cvars.AddChangeCallback(name .. num, function()
                    timer.Simple(0, ReloadConVars)
                end)
            end
        end
        ConVars[name] = Color(unpack(ConVars[name]))
    end


    HUDWidth =  (GetConVar("HudW") or CreateClientConVar("HudW", 240, true, false)):GetInt()
    HUDHeight = (GetConVar("HudH") or CreateClientConVar("HudH", 115, true, false)):GetInt()

    if not cvars.GetConVarCallbacks("HudW", false) and not cvars.GetConVarCallbacks("HudH", false) then
        cvars.AddChangeCallback("HudW", function() timer.Simple(0,ReloadConVars) end)
        cvars.AddChangeCallback("HudH", function() timer.Simple(0,ReloadConVars) end)
    end
end
ReloadConVars()

local Scrw, Scrh, RelativeX, RelativeY
--[[---------------------------------------------------------------------------
HUD separate Elements
---------------------------------------------------------------------------]]
local Health = 0
local function DrawHealth()
    local maxHealth = localplayer:GetMaxHealth()
    local myHealth = localplayer:Health()
    Health = math.min(maxHealth, (Health == myHealth and Health) or Lerp(0.1, Health, myHealth))

    local healthRatio = math.Min(Health / maxHealth, 1)
    local rounded = math.Round(3 * healthRatio)
    local Border = math.Min(6, rounded * rounded)
    draw.RoundedBox(Border, RelativeX + 4, RelativeY - 30, HUDWidth - 8, 20, ConVars.Healthbackground)
    draw.RoundedBox(Border, RelativeX + 5, RelativeY - 29, (HUDWidth - 9) * healthRatio, 18, ConVars.Healthforeground)

    draw.DrawNonParsedText(math.Max(0, math.Round(myHealth)), "DarkRPHUD2", RelativeX + 4 + (HUDWidth - 8) / 2, RelativeY - 32, ConVars.HealthText, 1)

    -- Armor
    local armor = math.Clamp(localplayer:Armor(), 0, 100)
    if armor ~= 0 then
        draw.RoundedBox(2, RelativeX + 4, RelativeY - 15, (HUDWidth - 8) * armor / 100, 5, colors.blue)
    end
end

local salaryText, JobWalletText
local function DrawInfo()
    salaryText = salaryText or DarkRP.getPhrase("salary", DarkRP.formatMoney(localplayer:getDarkRPVar("salary")), "")

    JobWalletText = JobWalletText or string.format("%s\n%s",
        DarkRP.getPhrase("job", localplayer:getDarkRPVar("job") or ""),
        DarkRP.getPhrase("wallet", DarkRP.formatMoney(localplayer:getDarkRPVar("money")), "")
    )

    draw.DrawNonParsedText(salaryText, "DarkRPHUD2", RelativeX + 5, RelativeY - HUDHeight + 6, ConVars.salary1, 0)
    draw.DrawNonParsedText(salaryText, "DarkRPHUD2", RelativeX + 4, RelativeY - HUDHeight + 5, ConVars.salary2, 0)

    surface.SetFont("DarkRPHUD2")
    local _, h = surface.GetTextSize(salaryText)

    draw.DrawNonParsedText(JobWalletText, "DarkRPHUD2", RelativeX + 5, RelativeY - HUDHeight + h + 6, ConVars.Job1, 0)
    draw.DrawNonParsedText(JobWalletText, "DarkRPHUD2", RelativeX + 4, RelativeY - HUDHeight + h + 5, ConVars.Job2, 0)
end

local Page = Material("icon16/page_white_text.png")
local function GunLicense()
    if localplayer:getDarkRPVar("HasGunlicense") then
        surface.SetMaterial(Page)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(RelativeX + HUDWidth, Scrh - 34, 32, 32)
    end
end

local agendaText
local function Agenda(gamemodeTable)
    local shouldDraw = hook.Call("HUDShouldDraw", gamemodeTable, "DarkRP_Agenda")
    if shouldDraw == false then return end

    local agenda = localplayer:getAgendaTable()
    if not agenda then return end
    agendaText = agendaText or DarkRP.textWrap((localplayer:getDarkRPVar("agenda") or ""):gsub("//", "\n"):gsub("\\n", "\n"), "DarkRPHUD1", 440)

    draw.RoundedBox(10, 10, 10, 460, 110, colors.gray1)
    draw.RoundedBox(10, 12, 12, 456, 106, colors.gray2)
    draw.RoundedBox(10, 12, 12, 456, 20, colors.darkred)

    draw.DrawNonParsedText(agenda.Title, "DarkRPHUD1", 30, 12, colors.red, 0)
    draw.DrawNonParsedText(agendaText, "DarkRPHUD1", 30, 35, colors.white, 0)
end

hook.Add("DarkRPVarChanged", "agendaHUD", function(ply, var, _, new)
    if ply ~= localplayer then return end
    if var == "agenda" and new then
        agendaText = DarkRP.textWrap(new:gsub("//", "\n"):gsub("\\n", "\n"), "DarkRPHUD1", 440)
    else
        agendaText = nil
    end

    if var == "salary" then
        salaryText = DarkRP.getPhrase("salary", DarkRP.formatMoney(new), "")
    end

    if var == "job" or var == "money" then
        JobWalletText = string.format("%s\n%s",
            DarkRP.getPhrase("job", var == "job" and new or localplayer:getDarkRPVar("job") or ""),
            DarkRP.getPhrase("wallet", var == "money" and DarkRP.formatMoney(new) or DarkRP.formatMoney(localplayer:getDarkRPVar("money")), "")
        )
    end
end)

local VoiceChatTexture = surface.GetTextureID("voice/icntlk_pl")
local function DrawVoiceChat(gamemodeTable)
    local shouldDraw = hook.Call("HUDShouldDraw", gamemodeTable, "DarkRP_VoiceChat")
    if shouldDraw == false then return end

    if localplayer.DRPIsTalking then
        local _, chboxY = chat.GetChatBoxPos()

        local Rotating = math.sin(CurTime() * 3)
        local backwards = 0

        if Rotating < 0 then
            Rotating = 1 - (1 + Rotating)
            backwards = 180
        end

        surface.SetTexture(VoiceChatTexture)
        surface.SetDrawColor(ConVars.Healthforeground)
        surface.DrawTexturedRectRotated(Scrw - 100, chboxY, Rotating * 96, 96, backwards)
    end
end

local function LockDown(gamemodeTable)
    local chbxX, chboxY = chat.GetChatBoxPos()
    if GetGlobalBool("DarkRP_LockDown") then
        local shouldDraw = hook.Call("HUDShouldDraw", gamemodeTable, "DarkRP_LockdownHUD")
        if shouldDraw == false then return end
        local cin = (math.sin(CurTime()) + 1) / 2
        local chatBoxSize = math.floor(Scrh / 4)
        draw.DrawNonParsedText(DarkRP.getPhrase("lockdown_started"), "ScoreboardSubtitle", chbxX, chboxY + chatBoxSize, Color(cin * 255, 0, 255 - (cin * 255), 255), TEXT_ALIGN_LEFT)
    end
end

local Arrested = function() end

usermessage.Hook("GotArrested", function(msg)
    local StartArrested = CurTime()
    local ArrestedUntil = msg:ReadFloat()

    Arrested = function(gamemodeTable)
        local shouldDraw = hook.Call("HUDShouldDraw", gamemodeTable, "DarkRP_ArrestedHUD")
        if shouldDraw == false then return end

        if CurTime() - StartArrested <= ArrestedUntil and localplayer:getDarkRPVar("Arrested") then
            draw.DrawNonParsedText(DarkRP.getPhrase("youre_arrested", math.ceil((ArrestedUntil - (CurTime() - StartArrested)) * 1 / game.GetTimeScale())), "DarkRPHUD1", Scrw / 2, Scrh - Scrh / 12, colors.white, 1)
        elseif not localplayer:getDarkRPVar("Arrested") then
            Arrested = function() end
        end
    end
end)

local AdminTell = function() end

usermessage.Hook("AdminTell", function(msg)
    timer.Remove("DarkRP_AdminTell")
    local Message = msg:ReadString()

    AdminTell = function()
        draw.RoundedBox(4, 10, 10, Scrw - 20, 110, colors.darkblack)
        draw.DrawNonParsedText(DarkRP.getPhrase("listen_up"), "GModToolName", Scrw / 2 + 10, 10, colors.white, 1)
        draw.DrawNonParsedText(Message, "ChatFont", Scrw / 2 + 10, 90, colors.brightred, 1)
    end

    timer.Create("DarkRP_AdminTell", 10, 1, function()
        AdminTell = function() end
    end)
end)

--[[---------------------------------------------------------------------------
Drawing the HUD elements such as Health etc.
---------------------------------------------------------------------------]]
local smoothedHealth = 100
local smoothedArmor = 100 -- New variable for armor smoothing

hook.Add("HUDPaint", "DrawDarkRPHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Get Player Data
    local health = ply:Health()
    local maxHealth = ply:GetMaxHealth()
    local armor = ply:Armor() -- Get player's armor
    local maxArmor = 100 -- Max armor value
    local money = ply:getDarkRPVar("money") or 0
    local job = ply:getDarkRPVar("job") or "Unemployed"
    local salary = ply:getDarkRPVar("salary") or 0  -- Get salary

    -- Smooth health and armor animation
    smoothedHealth = Lerp(0.1, smoothedHealth, health)
    smoothedArmor = Lerp(0.1, smoothedArmor, armor)

    -- Screen Scaling
    local screenW, screenH = ScrW(), ScrH()
    local barWidth = screenW * 0.18
    local barHeight = screenH * 0.03
    local avatarSize = screenH * 0.1 -- Avatar size
    local padding = screenH * 0.005
    local totalHeight = barHeight * 3 + padding * 2 -- Total height including padding for the new armor bar

    -- Positioning
    local boxX = screenW * 0.02 - 5
    local boxY = screenH * 0.9 - totalHeight - padding
    local boxWidth = barWidth + avatarSize + 15  -- Adjust width for the larger avatar
    local boxHeight = totalHeight + padding * 2  -- Account for padding

    -- Colors
    local bgColor = Color(40, 40, 50, 220)
    local accentColor = Color(100, 170, 255, 255)
    local healthColor = Color(0, 170, 255, 255)
    local armorColor = Color(0, 255, 0, 255) -- Armor bar color (green)
    local textColor = Color(230, 230, 230)
    local salaryColor = Color(150, 255, 150)

    -- Background Panel
    draw.RoundedBox(10, boxX, boxY, boxWidth, boxHeight, bgColor)

    -- Job + Salary Display
    draw.RoundedBox(6, boxX + avatarSize + 10, boxY + 5, barWidth, barHeight, Color(50, 50, 60, 200))
    draw.SimpleText(job .. " | $" .. string.Comma(salary) .. "/hr", "DarkRP_HUD", boxX + avatarSize + 15, boxY + 8, textColor, TEXT_ALIGN_LEFT)

    -- Money Display
    draw.RoundedBox(6, boxX + avatarSize + 10, boxY + barHeight + padding + 5, barWidth, barHeight, Color(50, 50, 60, 200))
    draw.SimpleText("$" .. string.Comma(money), "DarkRP_HUD", boxX + avatarSize + 15, boxY + barHeight + padding + 8, accentColor, TEXT_ALIGN_LEFT)

    -- Health Bar
    local healthBarY = boxY + (barHeight + padding) * 2 + 5
    draw.RoundedBox(6, boxX + avatarSize + 10, healthBarY, barWidth, barHeight, Color(60, 60, 70, 200))
    draw.RoundedBox(6, boxX + avatarSize + 10, healthBarY, math.max(barWidth * (smoothedHealth / maxHealth), 1), barHeight, healthColor)
    -- Centered text for HP
    draw.SimpleText("HP: " .. health, "DarkRP_HUD", boxX + avatarSize + 15 + (barWidth / 2), healthBarY + barHeight / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Armor Bar (New)
    local armorBarY = healthBarY + barHeight + padding
    draw.RoundedBox(6, boxX + avatarSize + 10, armorBarY, barWidth, barHeight * 0.5, Color(60, 60, 70, 200))  -- Thinner bar
    draw.RoundedBox(6, boxX + avatarSize + 10, armorBarY, math.max(barWidth * (smoothedArmor / maxArmor), 1), barHeight * 0.5, armorColor)
    -- Centered text for Armor
    draw.SimpleText("Armor: " .. armor, "DarkRP_HUD", boxX + avatarSize + 15 + (barWidth / 2), armorBarY + barHeight * 0.25, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Create avatar if it doesn’t exist
    if not IsValid(AvatarFrame) then
        AvatarFrame = vgui.Create("AvatarImage")
        AvatarFrame:SetSize(avatarSize, avatarSize)  -- Scale up the avatar size
        AvatarFrame:SetPos(boxX + 5, boxY + 5)
        AvatarFrame:SetPlayer(ply, 64) -- Get Steam Avatar
    end
end)

-- Hide Default HUD Elements
hook.Add("HUDShouldDraw", "HideDefaultHUD", function(name)
    if name == "CHudHealth" or name == "CHudBattery" then
        return false
    end
end)



-- Hide Default HUD Elements
hook.Add("HUDShouldDraw", "HideDefaultHUD", function(name)
    if name == "CHudHealth" or name == "CHudBattery" then
        return false
    end
end)




--[[---------------------------------------------------------------------------
Entity HUDPaint things
---------------------------------------------------------------------------]]
-- Draw a player's name, health and/or job above the head
-- This syntax allows for easy overriding
plyMeta.drawPlayerInfo = plyMeta.drawPlayerInfo or function(self)
    local pos = self:EyePos()

    pos.z = pos.z + 10 -- The position we want is a bit above the position of the eyes
    pos = pos:ToScreen()
    if not self:getDarkRPVar("wanted") then
        -- Move the text up a few pixels to compensate for the height of the text
        pos.y = pos.y - 50
    end

    if GAMEMODE.Config.showname then
        local nick, plyTeam = self:Nick(), self:Team()
        draw.DrawNonParsedText(nick, "DarkRPHUD2", pos.x + 1, pos.y + 1, colors.black, 1)
        draw.DrawNonParsedText(nick, "DarkRPHUD2", pos.x, pos.y, RPExtraTeams[plyTeam] and RPExtraTeams[plyTeam].color or team.GetColor(plyTeam) , 1)
    end

    if GAMEMODE.Config.showhealth then
        local health = DarkRP.getPhrase("health", math.max(0, self:Health()))
        draw.DrawNonParsedText(health, "DarkRPHUD2", pos.x + 1, pos.y + 21, colors.black, 1)
        draw.DrawNonParsedText(health, "DarkRPHUD2", pos.x, pos.y + 20, colors.white1, 1)
    end

    if GAMEMODE.Config.showjob then
        local teamname = self:getDarkRPVar("job") or team.GetName(self:Team())
        draw.DrawNonParsedText(teamname, "DarkRPHUD2", pos.x + 1, pos.y + 41, colors.black, 1)
        draw.DrawNonParsedText(teamname, "DarkRPHUD2", pos.x, pos.y + 40, colors.white1, 1)
    end

    if self:getDarkRPVar("HasGunlicense") then
        surface.SetMaterial(Page)
        surface.SetDrawColor(255,255,255,255)
        surface.DrawTexturedRect(pos.x-16, pos.y + 60, 32, 32)
    end
end

-- Draw wanted information above a player's head
-- This syntax allows for easy overriding
plyMeta.drawWantedInfo = plyMeta.drawWantedInfo or function(self)
    if not self:Alive() then return end

    local pos = self:EyePos()
    if not pos:isInSight({localplayer, self}) then return end

    pos.z = pos.z + 10
    pos = pos:ToScreen()

    if GAMEMODE.Config.showname then
        local nick, plyTeam = self:Nick(), self:Team()
        draw.DrawNonParsedText(nick, "DarkRPHUD2", pos.x + 1, pos.y + 1, colors.black, 1)
        draw.DrawNonParsedText(nick, "DarkRPHUD2", pos.x, pos.y, RPExtraTeams[plyTeam] and RPExtraTeams[plyTeam].color or team.GetColor(plyTeam) , 1)
    end

    local wantedText = DarkRP.getPhrase("wanted", tostring(self:getDarkRPVar("wantedReason")))

    draw.DrawNonParsedText(wantedText, "DarkRPHUD2", pos.x, pos.y - 40, colors.white1, 1)
    draw.DrawNonParsedText(wantedText, "DarkRPHUD2", pos.x + 1, pos.y - 41, colors.red, 1)
end

--[[---------------------------------------------------------------------------
The Entity display: draw HUD information about entities
---------------------------------------------------------------------------]]
local function DrawEntityDisplay(gamemodeTable)
    local shouldDraw, players = hook.Call("HUDShouldDraw", gamemodeTable, "DarkRP_EntityDisplay")
    if shouldDraw == false then return end

    local shootPos = localplayer:GetShootPos()
    local aimVec = localplayer:GetAimVector()

    for _, ply in ipairs(players or player.GetAll()) do
        if not IsValid(ply)
           or ply == localplayer
           or not ply:Alive()
           or ply:GetNoDraw()
           or ply:IsDormant()
           or ply:GetColor().a == 0 and (ply:GetRenderMode() == RENDERMODE_TRANSALPHA or ply:GetRenderMode() == RENDERMODE_TRANSCOLOR) then
           continue
        end
        local hisPos = ply:GetShootPos()
        if ply:getDarkRPVar("wanted") then ply:drawWantedInfo() end

        if gamemodeTable.Config.globalshow then
            ply:drawPlayerInfo()
        -- Draw when you're (almost) looking at him
        elseif hisPos:DistToSqr(shootPos) < 160000 then
            local pos = hisPos - shootPos
            local unitPos = pos:GetNormalized()
            if unitPos:Dot(aimVec) > 0.95 then
                local trace = util.QuickTrace(shootPos, pos, localplayer)
                if trace.Hit and trace.Entity ~= ply then
                    -- When the trace says you're directly looking at a
                    -- different player, that means you can draw /their/ info
                    if trace.Entity:IsPlayer() then
                        trace.Entity:drawPlayerInfo()
                    end
                    break
                end
                ply:drawPlayerInfo()
            end
        end
    end

    local ent = localplayer:GetEyeTrace().Entity

    if IsValid(ent) and ent:isKeysOwnable() and ent:GetPos():DistToSqr(localplayer:GetPos()) < 40000 then
        ent:drawOwnableInfo()
    end
end

--[[---------------------------------------------------------------------------
Drawing death notices
---------------------------------------------------------------------------]]
function GM:DrawDeathNotice(x, y)
    if not self.Config.showdeaths then return end
    self.Sandbox.DrawDeathNotice(self, x, y)
end

--[[---------------------------------------------------------------------------
Display notifications
---------------------------------------------------------------------------]]
local notificationSound = GM.Config.notificationSound
local function DisplayNotify(msg)
    local txt = msg:ReadString()
    GAMEMODE:AddNotify(txt, msg:ReadShort(), msg:ReadLong())
    surface.PlaySound(notificationSound)

    -- Log to client console
    MsgC(Color(255, 20, 20, 255), "[DarkRP] ", Color(200, 200, 200, 255), txt, "\n")
end
usermessage.Hook("_Notify", DisplayNotify)

--[[---------------------------------------------------------------------------
Remove some elements from the HUD in favour of the DarkRP HUD
---------------------------------------------------------------------------]]
local noDraw = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudSuitPower"] = true,
    ["CHUDQuickInfo"] = true
}
function GM:HUDShouldDraw(name)
    if noDraw[name] or (HelpToggled and name == "CHudChat") then
        return false
    else
        return self.Sandbox.HUDShouldDraw(self, name)
    end
end

--[[---------------------------------------------------------------------------
Disable players' names popping up when looking at them
---------------------------------------------------------------------------]]
function GM:HUDDrawTargetID()
    return false
end

--[[---------------------------------------------------------------------------
Actual HUDPaint hook
---------------------------------------------------------------------------]]
function GM:HUDPaint()
    localplayer = localplayer or LocalPlayer()

    DrawHUD(self)
    DrawEntityDisplay(self)

    self.Sandbox.HUDPaint(self)
end
