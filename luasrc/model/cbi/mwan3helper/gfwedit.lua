
m = Map("mwan3helper")
m.title = translate("GFW网址编辑")
m.description = translate("编辑GFW列表规则，修改后需重启服务生效")

s = m:section(TypedSection, "mwan3helper")
s.anonymous = true
s.addremove = false

rule_list = s:option(DummyValue, "_rule_list", translate("规则列表"))
rule_list.template = "mwan3helper/gfwedit_rulelist"

add_section = s:option(DummyValue, "_add_section", translate("添加域名"))
add_section.template = "mwan3helper/gfwedit_add"

delete_section = s:option(DummyValue, "_delete_section", translate("删除域名"))
delete_section.template = "mwan3helper/gfwedit_delete"

restart_btn = s:option(Button, "_restart", translate("重启服务"))
restart_btn.inputtitle = translate("重启mwan3helper服务")
restart_btn.inputstyle = "apply"
restart_btn.template = "mwan3helper/gfwedit_restart"

return m
