local GPluginPath = _G.PluginPath
-- 生成脚本模块
local Template = {}
-- 页面对象
local TemplateView = nil
local Config = require(PluginPath .. '/Src/Config')

function Template.CreateView(res)
    if not res then
        return
    end

    if not TemplateView then
        App.pluginManager:LoadUIPackage(GPluginPath .. '/Package/Template')
        TemplateView = CS.FairyGUI.UIPackage.CreateObject("Template", "View")
    end

    local arr = string.split(res.fileName,".")
    Template.codeContent = string.gsub(Config.Template,"_T",arr[1])
    Template.packageName = res.file:match("\\([^\\/]+)/")
    Template.componentName = arr[1]

    Template.GeneratePath = App.project.basePath .."/".. App.project:GetSettings("Publish").codeGeneration.codePath .. "/"
    -- 设置窗体可以拖动
    TemplateView.draggable = true
    local btn_save = TemplateView:GetChild("btn_save")
    local btn_exit = TemplateView:GetChild("btn_exit")
    local text_path = TemplateView:GetChild("text_path")
    local list_file_content = TemplateView:GetChild("list_file_content")
    
    list_file_content.itemRenderer = function(idx,item)
        local textCom = item:GetChild("text")
        Template.textCom = textCom
        Template.textCom.text = Template.codeContent
    end

    text_path.text = Template.packageName .. "/"..Template.componentName..".lua"
    list_file_content.numItems = 1
    btn_save.onClick:Set(function()
        Template.save()
        Template.clear()
        TemplateView:RemoveFromParent()
    end)

    btn_exit.onClick:Set(function()
        Template.clear()
        TemplateView:RemoveFromParent()
    end)

    local parent = App.groot
    parent:AddChild(TemplateView)
    TemplateView:SetPosition(parent.width / 2, parent.height / 2)
end

function Template.save()
    local packageFolder = Template.GeneratePath..Template.packageName
    if not directoryExists(packageFolder) then
        if not mkdir_p(packageFolder) then
            return
        end
    end

    local luaFile = Template.GeneratePath .. Template.packageName .. "/"..Template.componentName..".lua"
    if directoryExists(luaFile) then
        App.Alert(luaFile .. "已存在")
        return
    end

    createFile(luaFile,true,Template.textCom.text)
end

function Template.Init()
    App.libView.contextMenu:AddItem("生成模板LUA","生成模板LUA",function()
        local res = App.libView:GetSelectedResource()
        if res and res.type then
            if res.type ~= "component" then
                App.Alert("非组件不能生成LUA")
                return
            end
            Template.CreateView(res)
        end
    end)
end

function Template.clear()
    Template.codeContent = nil
    Template.codeContent = nil
    Template.packageName = nil
    Template.componentName = nil
    Template.GeneratePath = nil
end

function Template.onDestroy()
    App.libView.contextMenu:RemoveItem("生成模板LUA")
    if TemplateView then
        TemplateView:Dispose()
        TemplateView = nil
    end
end

return Template