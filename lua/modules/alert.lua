--- This module helps you creating popups.
---@code alert = require("alert")
--- local done = alert:create("Done!")

---@type alert

alert = {}

---@function create Creates an alert
---@param text string
---@return alertInstance
---@code alert:create("Done!")
alert.create = function(self, text, config)
	if self ~= alert then
		error("alert:create(text): use `:`", 2)
	end
	if type(text) ~= Type.string then
		error("alert:create(text): text should be a string", 2)
	end

	local modal = require("modal")
	local theme = require("uitheme").current
	local ease = require("ease")

	-- default config
	local _config = {
		uikit = require("uikit"), -- allows to provide specific instance of uikit
	}

	if config then
		for k, v in pairs(_config) do
			if type(config[k]) == type(v) then
				_config[k] = config[k]
			end
		end
	end

	local ui = _config.uikit

	local minButtonWidth = 100

	local content = modal:createContent()
	content.closeButton = false

	content.idealReducedContentSize = function(content, _, _)
		content:refresh()
		return Number2(content.Width, content.Height)
	end

	local maxWidth = function()
		return Screen.Width - theme.modalMargin * 2
	end

	local maxHeight = function()
		return Screen.Height - 100
	end

	local position = function(modal, forceBounce)
		local p = Number3(Screen.Width * 0.5 - modal.Width * 0.5, Screen.Height * 0.5 - modal.Height * 0.5, 0)

		if not modal.updatedPosition or forceBounce then
			modal.LocalPosition = p - { 0, 100, 0 }
			modal.updatedPosition = true
			ease:outElastic(modal, 0.3).LocalPosition = p
		else
			ease:cancel(modal)
			modal.LocalPosition = p
		end
	end

	local node = ui:createFrame(Color(0, 0, 0))
	content.node = node

	local popup = modal:create(content, maxWidth, maxHeight, position, ui)

	local label = ui:createText(text, Color.White)
	label:setParent(node)

	-- buttons are displayed in that order:
	-- NEUTRAL, NEGATIVE, POSITIVE
	-- POSITIVE one is displayed by default but can be hidden setting callback to nil

	local positiveCallback = nil
	local negativeCallback = nil
	local neutralCallback = nil

	local okButton = nil
	local negativeButton = nil
	local neutralButton = nil

	local computeWidth = function(_)
		local buttonsWidth = 0
		if okButton then
			buttonsWidth = okButton.Width
		end
		if negativeButton then
			if buttonsWidth > 0 then
				buttonsWidth = buttonsWidth + theme.padding
			end
			buttonsWidth = buttonsWidth + negativeButton.Width
		end
		if neutralButton then
			if buttonsWidth > 0 then
				buttonsWidth = buttonsWidth + theme.padding
			end
			buttonsWidth = buttonsWidth + neutralButton.Width
		end

		local width = theme.padding

		if buttonsWidth > label.Width + theme.padding * 2 then
			width = width + buttonsWidth
		else
			width = width + label.Width + theme.padding * 2
		end

		return width
	end

	local computeHeight = function(_)
		if okButton ~= nil then
			return label.Height + theme.padding * 2 + okButton.Height + theme.paddingBig
		elseif negativeButton then
			return label.Height + theme.padding * 2 + negativeButton.Height + theme.paddingBig
		elseif neutralButton then
			return label.Height + theme.padding * 2 + neutralButton.Height + theme.paddingBig
		else
			return label.Height + theme.padding * 2
		end
	end

	node.refresh = function(self)
		label.object.MaxWidth = math.min(500, Screen.Width * 0.7)

		self.Width = computeWidth()
		self.Height = computeHeight()

		label.LocalPosition = { self.Width * 0.5 - label.Width * 0.5, self.Height - label.Height - theme.padding, 0 }

		local buttons = {}
		if neutralButton then
			table.insert(buttons, neutralButton)
		end
		if negativeButton then
			table.insert(buttons, negativeButton)
		end
		if okButton then
			table.insert(buttons, okButton)
		end

		local buttonsWidth = 0
		for i, button in ipairs(buttons) do
			if i > 1 then
				buttonsWidth = buttonsWidth + theme.padding
			end
			buttonsWidth = buttonsWidth + button.Width
		end

		local previous
		for _, button in ipairs(buttons) do
			if previous then
				button.LocalPosition.X = previous.LocalPosition.X + previous.Width + theme.padding
			else
				button.LocalPosition.X = self.Width * 0.5 - buttonsWidth * 0.5
			end
			button.LocalPosition.Y = theme.padding
			previous = button
		end
	end

	---@type alertInstance
	--- An [alertInstance] can be used to personalize its buttons.

	---@function setPositiveCallback Sets the text and the callback for positive button. Using nil for the callback removes the button.
	---@param text string
	---@param callback? function
	---@code local instance = alert:create("Are you sure?")
	--- instance:setPositiveCallback("Yes!", function()
	--- -- add your code here
	--- end)
	popup.setPositiveCallback = function(self, text, callback)
		if self ~= popup then
			error("alert:setPositiveCallback(text, callback): use `:`", 2)
		end
		if text == nil or type(text) ~= Type.string then
			error("alert:setPositiveCallback(text, callback): text should be a string", 2)
		end
		if callback ~= nil and type(callback) ~= Type["function"] then
			error("alert:setPositiveCallback(text, callback): callback should be a function or nil", 2)
		end

		positiveCallback = callback

		if callback == nil then
			if okButton ~= nil then
				okButton:remove()
				okButton = nil
			end
		else
			if okButton then
				okButton.Text = text
			else
				okButton = ui:createButton(text)
				okButton:setColor(Color(161, 217, 0), Color(45, 57, 17), false)
				okButton:setParent(node)
				okButton.onRelease = function(_)
					positiveCallback()
					if popup.close then
						popup:close()
					end
				end
			end

			okButton.Width = nil
			if okButton.Width < minButtonWidth then
				okButton.Width = minButtonWidth
			end
		end

		self:refresh()
	end

	---@function setNegativeCallback Creates, sets the text and callback of a negative button in the [alertInstance].
	--- Using nil for the callback will remove the button
	--- Buttons are displayed in that order: NEUTRAL, NEGATIVE, POSITIVE.
	---@param text string
	---@param callback? function
	---@code local instance = alert:create("Are you sure?")
	--- instance:setNegativeCallback("No", function()
	--- -- add your code here
	--- end)
	--- instance:setNegativeCallback("No", nil) -- removes the button
	popup.setNegativeCallback = function(self, text, callback)
		if self ~= popup then
			error("alert:setNegativeCallback(text, callback): use `:`", 2)
		end
		if text == nil or type(text) ~= Type.string then
			error("alert:setNegativeCallback(text, callback): text should be a string", 2)
		end
		if callback ~= nil and type(callback) ~= Type["function"] then
			error("alert:setNegativeCallback(text, callback): callback should be a function or nil", 2)
		end

		negativeCallback = callback

		if callback == nil then
			if negativeButton ~= nil then
				negativeButton:remove()
				negativeButton = nil
			end
		else
			if negativeButton then
				negativeButton.Text = text
			else
				negativeButton = ui:createButton(text)
				negativeButton:setColor(Color(227, 52, 55), Color.White, false)
				negativeButton:setParent(node)
				negativeButton.onRelease = function(_)
					negativeCallback()
					if popup.close then
						popup:close()
					end
				end
			end

			negativeButton.Width = nil
			if negativeButton.Width < minButtonWidth then
				negativeButton.Width = minButtonWidth
			end
		end

		self:refresh()
	end

	---@function setNeutralCallback Creates, sets the text and callback of a neutral button in the [alertInstance].
	--- Using nil for the callback will remove the button
	--- Buttons are displayed in that order: NEUTRAL, NEGATIVE, POSITIVE.
	---@param text string
	---@param callback? function
	---@code local instance = alert:create("Are you sure?")
	--- instance:setNeutralCallback("Cancel", function()
	--- -- add your code here
	--- end)
	popup.setNeutralCallback = function(self, text, callback)
		if self ~= popup then
			error("alert:setNeutralCallback(text, callback): use `:`", 2)
		end
		if text == nil or type(text) ~= Type.string then
			error("alert:setNeutralCallback(text, callback): text should be a string", 2)
		end
		if callback ~= nil and type(callback) ~= Type["function"] then
			error("alert:setNeutralCallback(text, callback): callback should be a function or nil", 2)
		end

		neutralCallback = callback

		if callback == nil then
			if neutralButton ~= nil then
				neutralButton:remove()
				neutralButton = nil
			end
		else
			if neutralButton then
				neutralButton.Text = text
			else
				neutralButton = ui:createButton(text)
				neutralButton:setParent(node)
				neutralButton.onRelease = function(_)
					neutralCallback()
					if popup.close then
						popup:close()
					end
				end
			end

			neutralButton.Width = nil
			if neutralButton.Width < minButtonWidth then
				neutralButton.Width = minButtonWidth
			end
		end

		self:refresh()
	end

	popup:setPositiveCallback("OK", function() end)

	popup.bounce = function(_)
		position(popup, true)
	end

	return popup
end

return alert
