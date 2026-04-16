
m = Map("mwan3helper")
m.title = translate("GFW网址编辑")
m.description = translate("编辑GFW列表规则，修改后需重启服务生效")

s = m:section(TypedSection, "mwan3helper")
s.anonymous = true
s.addremove = false

gfw_file = "/etc/mwan3helper/gfw.txt"

local gfw_content = ""
if nixio.fs.access(gfw_file) then
    local fp = io.open(gfw_file, "r")
    if fp then
        gfw_content = fp:read("*a")
        fp:close()
    end
end

rule_list = s:option(TextValue, "rule_list", translate("规则列表"))
rule_list.rows = 15
rule_list.readonly = true
rule_list.rmeempty = false
rule_list.default = gfw_content

add_section = s:option(DummyValue, "_add_section", translate("添加域名"))
add_section.template = "mwan3helper/gfwedit_add"

delete_section = s:option(DummyValue, "_delete_section", translate("删除域名"))
delete_section.template = "mwan3helper/gfwedit_delete"

restart_btn = s:option(Button, "_restart", translate("重启服务"))
restart_btn.inputtitle = translate("重启mwan3helper服务")
restart_btn.inputstyle = "apply"
restart_btn.template = "mwan3helper/gfwedit_restart"

function m.on_commit(self)
    local add_domain = luci.http.formvalue("cbid.mwan3helper.1._add_domain")
    local delete_domains = luci.http.formvalue("cbid.mwan3helper.1._delete_domains")
    local do_add = luci.http.formvalue("cbid.mwan3helper.1._do_add")
    local do_delete = luci.http.formvalue("cbid.mwan3helper.1._do_delete")

    if do_add == "1" and add_domain and #add_domain > 0 then
        add_domain = add_domain:gsub("^%s+", ""):gsub("%s+$", "")
        if add_domain ~= "" then
            local fp = io.open(gfw_file, "a")
            if fp then
                fp:write("\n" .. add_domain)
                fp:close()
            end
        end
    end

    if do_delete == "1" and delete_domains and #delete_domains > 0 then
        local domains = {}
        for line in delete_domains:gmatch("[^\r\n]+") do
            line = line:gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" then
                table.insert(domains, line)
            end
        end

        if #domains > 0 then
            local fp = io.open(gfw_file, "r")
            local content = ""
            if fp then
                content = fp:read("*a")
                fp:close()
            end

            for _, domain in ipairs(domains) do
                local escaped = domain:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
                content = content:gsub("\n" .. escaped .. "\n", "\n")
                content = content:gsub("^" .. escaped .. "\n", "")
                content = content:gsub("\n" .. escaped .. "$", "")
                content = content:gsub("^" .. escaped .. "$", "")
            end

            fp = io.open(gfw_file, "w")
            if fp then
                fp:write(content)
                fp:close()
            end
        end
    end
end

return m
