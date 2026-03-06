local PCSettingPageBase = class("PCSettingPageBase")

function PCSettingPageBase:ResetComponent(component)
	self.component = component
end

function PCSettingPageBase:Enter()
end

function PCSettingPageBase:Exit()
	self.component = nil
end

return PCSettingPageBase