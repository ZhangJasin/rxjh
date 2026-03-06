local MentorShipPageBase = class("MentorShipPageBase")

function MentorShipPageBase:ResetComponent(component)
	self.component = component
end

function MentorShipPageBase:Enter()
end

function MentorShipPageBase:Exit()
	self.component = nil
end

return MentorShipPageBase