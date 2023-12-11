--//
--// Bypass skills/profession and character creation
--// Author: Colin J.D. Stewart | Updated: 16.08.2022
--// 


function CoopCharacterCreationProfession:setVisible(visible, joypadData)
	ISPanelJoypad.setVisible(self, visible, joypadData)

	--// Auto clicking next was the best option for compatibility with future updates/versions
	if visible == true then	
		self:onOptionMouseDown({internal = 'NEXT'}, 0,0);
	end;
end;

function CoopCharacterCreationMain:setVisible(visible, joypadData)
	ISPanelJoypad.setVisible(self, visible, joypadData)

	if visible == true then	
		self:onOptionMouseDown({internal = 'NEXT'}, 0,0);
	end;
end;


function CharacterCreationProfession:setVisible(visible, joypadData)
	ISPanelJoypad.setVisible(self, visible, joypadData)

	--// Auto clicking next was the best option for compatibility with future updates/versions
	if visible == true then	
		self:onOptionMouseDown({internal = 'NEXT'}, 0,0);
	end;
end;


function CharacterCreationMain:setVisible(visible, joypadData)
	ISPanelJoypad.setVisible(self, visible, joypadData)

	if visible == true then	
		self:onOptionMouseDown({internal = 'NEXT'}, 0,0);
	end;
end;

