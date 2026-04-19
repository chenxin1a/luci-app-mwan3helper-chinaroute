
-- Licensed to the public under the GNU General Public License v3.

module("luci.controller.mwan3helper", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/mwan3helper") then
		return
	end


  local page = entry({"admin", "services", "mwan3helper"},alias("admin", "services", "mwan3helper", "client"),_("MWAN3 Helper"), 300)
	page.dependent = true
	page.acl_depends = { "luci-app-mwan3helper" }
  entry({"admin", "services", "mwan3helper", "client"},cbi("mwan3helper/client"),_("Settings"), 10).leaf = true
 	
	entry({"admin", "services", "mwan3helper", "lists"},cbi("mwan3helper/list"),_("IPSet Lists"), 20).leaf = true
	
  entry({"admin","services","mwan3helper","status"},call("act_status")).leaf=true
	
	entry({"admin", "services", "mwan3helper", "gfwedit"},cbi("mwan3helper/gfwedit"),_("GFW网址编辑"), 30).leaf = true
	
entry({"admin","services","mwan3helper","restart"},call("act_restart")).leaf=true
	
	entry({"admin", "services", "mwan3helper", "add_domain"}, call("act_add_domain")).leaf = true
	
	entry({"admin", "services", "mwan3helper", "delete_domain"}, call("act_delete_domain")).leaf = true
	
end

function act_status()
  local e={}
  e.running=luci.sys.call("pgrep mwan3dns >/dev/null")==0
  luci.http.prepare_content("application/json")
  luci.http.write_json(e)
end

function act_restart()
  luci.http.prepare_content("text/plain")
  local ret = luci.sys.call("/etc/init.d/mwan3helper restart >/dev/null 2>&1")
  if ret == 0 then
    luci.http.write("ok")
  else
    luci.http.status(500, "Error")
    luci.http.write("failed")
  end
end

function act_add_domain()
    luci.http.prepare_content("application/json")
    local domain_input = luci.http.formvalue("domain")
    if not domain_input or domain_input == "" then
        luci.http.write_json({status="error", msg="域名不能为空"})
        return
    end
    
    local gfw_file = "/etc/mwan3helper/gfw.txt"
    local existing = {}
    
    local fp = io.open(gfw_file, "r")
    if fp then
        for line in fp:lines() do
            existing[line:lower()] = true
        end
        fp:close()
    end
    
    local added = 0
    local exists_count = 0
    
    fp = io.open(gfw_file, "a")
    if not fp then
        luci.http.write_json({status="error", msg="无法写入文件"})
        return
    end
    
    for line in domain_input:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
            if not existing[line:lower()] then
                fp:write(line .. "\n")
                existing[line:lower()] = true
                added = added + 1
            else
                exists_count = exists_count + 1
            end
        end
    end
    fp:close()
    
    if added > 0 then
        if exists_count > 0 then
            luci.http.write_json({status="ok", added=added, exists=exists_count})
        else
            luci.http.write_json({status="ok", added=added})
        end
    else
        luci.http.write_json({status="exists", msg="所有域名均已存在"})
    end
end

function act_delete_domain()
    luci.http.prepare_content("application/json")
    local domains_str = luci.http.formvalue("domains")
    if not domains_str or domains_str == "" then
        luci.http.write_json({status="error", msg="域名不能为空"})
        return
    end
    
    local domains = {}
    for line in domains_str:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
            domains[line:lower()] = true
        end
    end
    
    local gfw_file = "/etc/mwan3helper/gfw.txt"
    local lines_to_keep = {}
    local deleted_count = 0
    
    local fp = io.open(gfw_file, "r")
    if fp then
        for line in fp:lines() do
            local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" and not domains[trimmed:lower()] then
                table.insert(lines_to_keep, line)
            else
                deleted_count = deleted_count + 1
            end
        end
        fp:close()
    else
        luci.http.write_json({status="error", msg="无法读取文件"})
        return
    end
    
    fp = io.open(gfw_file, "w")
    if fp then
        fp:write(table.concat(lines_to_keep, "\n") .. "\n")
        fp:close()
        luci.http.write_json({status="ok", deleted=deleted_count})
    else
        luci.http.write_json({status="error", msg="无法写入文件"})
    end
end
