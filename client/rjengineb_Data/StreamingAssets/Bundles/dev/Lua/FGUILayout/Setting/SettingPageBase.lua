local SettingPageBase = class("SettingPageBase")

function SettingPageBase:ResetComponent(component)
	self.component = component
end

function SettingPageBase:Enter()
end

function SettingPageBase:Exit()
	self.component = nil
end

return SettingPageBase