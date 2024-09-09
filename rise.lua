local extension = Package("rise")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["rise"] = "江山如故·兴",
}

local jiananfeng = General(extension, "jiananfeng", "jin", 3, 3, General.Female)
local fuyu = fk.CreateActiveSkill{
  name = "fuyu",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  prompt = "#fuyu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    table.insert(effect.tos, player.id)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, function(id) return room:getPlayerById(id) end)
    local discussion = U.Discussion{
      reason = self.name,
      from = player,
      tos = targets,
    }
    if not player.dead and discussion.results[player.id] and
      discussion.color == discussion.results[player.id].opinion then
      local targets1 = table.filter(targets, function (p)
        return not p.dead and discussion.results[p.id].opinion ~= discussion.results[player.id].opinion
      end)
      local targets2 = table.filter(room.alive_players, function (p)
        return not table.contains(targets, p)
      end)
      if #targets1 == 0 and #targets2 == 0 then return end
      room:setPlayerMark(player, "fuyu-tmp", {table.map(targets1, Util.IdMapper), table.map(targets2, Util.IdMapper)})
      local success, dat = room:askForUseActiveSkill(player, "fuyu_active", "#fuyu-damage", true, nil, false)
      room:setPlayerMark(player, "fuyu-tmp", 0)
      if success and dat then
        room:sortPlayersByAction(dat.targets)
        for _, id in ipairs(dat.targets) do
          local p = room:getPlayerById(id)
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = self.name,
            }
          end
        end
      end
    end
  end,
}
local fuyu_active = fk.CreateActiveSkill{
  name = "fuyu_active",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return table.contains(Self:getMark("fuyu-tmp")[1], to_select) or table.contains(Self:getMark("fuyu-tmp")[2], to_select)
  end,
  feasible = function (self, selected, selected_cards)
    if #selected == 1 then
      return true
    elseif #selected == 2 then
      if table.contains(Self:getMark("fuyu-tmp")[1], selected[1]) then
        return table.contains(Self:getMark("fuyu-tmp")[2], selected[2])
      else
        return table.contains(Self:getMark("fuyu-tmp")[1], selected[2])
      end
    end
  end,
}
local shanzheng = fk.CreateTriggerSkill{
  name = "shanzheng",
  anim_type = "control",
  events = {"fk.StartDiscussion"},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (player == data.from or table.contains(data.tos, player)) and
      (table.every(player.room.alive_players, function (p)
        return player:getHandcardNum() >= p:getHandcardNum()
      end) or
      table.every(player.room.alive_players, function (p)
        return player.hp >= p.hp
      end))
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"red", "black", "Cancel"}, self.name,
      "#shanzheng-invoke::"..data.from.id..":"..data.reason)
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.results[player.id] = data.results[player.id] or {}
    data.results[player.id].opinion = self.cost_data.choice
    data.extra_data = data.extra_data or {}
    data.extra_data.shanzheng = data.extra_data.shanzheng or {}
    data.extra_data.shanzheng[player.id] = self.cost_data.choice
  end,

  refresh_events = {"fk.DiscussionResultConfirming"},
  can_refresh = function (self, event, target, player, data)
    return data.extra_data and data.extra_data.shanzheng and data.extra_data.shanzheng[player.id]
  end,
  on_refresh = function (self, event, target, player, data)
    local color = data.extra_data.shanzheng[player.id]
    data.opinions[color] = (data.opinions[color] or 0) + 1
  end,
}
local xiongbao = fk.CreateTriggerSkill{
  name = "xiongbao",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player.room:getOtherPlayers(player), function(p)
        return p:isFemale() or p:getHandcardNum() < player:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p)
      return p:isFemale() or p:getHandcardNum() < player:getHandcardNum()
    end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
local liedu = fk.CreateTriggerSkill{
  name = "liedu",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target and target == player and player:hasSkill(self) and
      (data.to.hp < player.hp and data.to:isFemale() or data.to.hp == 1) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#liedu-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage * 2
  end,
}
Fk:addSkill(fuyu_active)
jiananfeng:addSkill(fuyu)
jiananfeng:addSkill(shanzheng)
jiananfeng:addSkill(xiongbao)
jiananfeng:addSkill(liedu)
Fk:loadTranslationTable{
  ["jiananfeng"] = "贾南风",
  ["#jiananfeng"] = "",
  ["illustrator:jiananfeng"] = "",

  ["fuyu"] = "覆雨",
  [":fuyu"] = "出牌阶段限一次，你可以与任意名角色议事，若结果与你的意见相同，你可以对一名意见不同和一名未参与议事的角色各造成1点伤害。",
  ["shanzheng"] = "擅政",
  [":shanzheng"] = "当你参与议事选择议事牌前，若你的手牌数或体力值为全场最大，你本次议事无需展示手牌，改为声明一种颜色作为你的意见，且你的"..
  "意见视为两名角色的意见。",
  ["xiongbao"] = "凶暴",
  [":xiongbao"] = "锁定技，其他女性角色和手牌数小于你的角色不能响应你使用的牌。",
  ["liedu"] = "烈妒",
  [":liedu"] = "每回合限一次，当你对体力值小于你的女性角色或体力值为1的角色造成伤害时，你可以令此伤害值翻倍。",
  ["#fuyu"] = "覆雨：与任意名角色议事，若结果与你的意见相同，你可以对一名意见不同和一名未参与议事的角色各造成1点伤害",
  ["fuyu_active"] = "覆雨",
  ["#fuyu-damage"] = "覆雨：你可以对一名意见不同和一名未参与议事的角色各造成1点伤害",
  ["#shanzheng-invoke"] = "擅政：%dest 因“%arg”发起议事，是否改为选择一种颜色作为你的意见？",
  ["#liedu-invoke"] = "烈妒：是否令你对 %dest 造成的伤害翻倍？",
}

return extension
