local skill = fk.CreateSkill {
  name = "shade_skill",
}

skill:addEffect("cardskill", {
  can_use = Util.FalseFunc,
})

return skill
