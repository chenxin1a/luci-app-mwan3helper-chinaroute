
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
