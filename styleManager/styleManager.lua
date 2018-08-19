styleSettings = {}
styleManager = {}
styleManager.currentStyle = "Default"
styleManager.customStyle = "Default"
styleManager.sharedTexture = {}
styleManager.styles = {Default="Default"}

function scanCustomStyle()
	local styleMapper = fileOpen("styleManager/styleMapper.lua")
	local str = fileRead(styleMapper,fileGetSize(styleMapper))
	local str = "return {\n"..str.."\n}"
	local fnc = loadstring(str)
	assert(fnc,"Failed to load styleMapper")
	local customStyleTable = fnc()
	local customUsing = "Default"
	for k,v in pairs(customStyleTable) do
		if k == "use" then
			customUsing = v
		elseif k ~= "Default" then
			styleManager.styles[k] = v
		end
	end
	if customStyleTable[customUsing] then
		styleManager.customStyle = customUsing
	end
end

function getPathFromStyle(styleName)
	return "styleManager/"..(styleManager.styles[styleName] or "Default").."/"
end

function dgsCreateTextureFromStyle(theTable)
	if theTable then
		local filePath,textureType,shaderSettings = theTable[1],theTable[2],theTable[3]
		if filePath then
			textureType = textureType or "image"
			local currentStyle = styleManager.currentStyle
			local thePath = getPathFromStyle(currentStyle)..filePath
			if textureType == "image" then
				if styleSettings.sharedTexture then
					if isElement(styleManager.sharedTexture[thePath]) then
						return styleManager.sharedTexture[thePath]
					else
						styleManager.sharedTexture[thePath] = dxCreateTexture(thePath)
						return styleManager.sharedTexture[thePath]
					end
				else
					return dxCreateTexture(thePath)
				end
			elseif textureType == "shader" then
				local shader = dxCreateShader(thePath)
				for k,v in pairs(shaderSettings or {}) do
					dxSetShaderValue(shader,k,v)
				end
				return shader
			end
		end
	end
end

function checkStyle(styleName)
	if styleName then
		local stylePath = getPathFromStyle(styleName)
		if stylePath then
			assert(fileExists(stylePath.."styleSettings.txt"),"[DGS Style] Missing style setting ("..stylePath.."styleSettings.txt)")
			local styleFile = fileOpen(stylePath.."styleSettings.txt")
			local str = fileRead(styleFile,fileGetSize(styleFile))
			local fnc = loadstring("return {\n"..str.."\n}")
			assert(fnc,"[DGS Style]Error when checking "..stylePath.."styleSettings.txt")
		end
	else
		for k,v in pairs(styleManager.styles) do
			local stylePath = getPathFromStyle(k)
			if stylePath then
				assert(fileExists(stylePath.."styleSettings.txt"),"[DGS Style] Missing style setting ("..stylePath.."styleSettings.txt)")
				local styleFile = fileOpen(stylePath.."styleSettings.txt")
				local str = fileRead(styleFile,fileGetSize(styleFile))
				local fnc = loadstring("return {\n"..str.."\n}")
				assert(fnc,"[DGS Style]Error when checking "..stylePath.."styleSettings.txt")
			end
		end
	end
end

function dgsSetCurrentStyle(styleName)
	local styleName = styleName or "Default"
	assert(type(styleName) == "string","Bad argument @dgsSetCurrentStyle at argument 1, expect a string got "..type(styleName))
	assert(styleManager.styles[styleName],"Bad argument @dgsSetCurrentStyle at argument 1, Couldn't find such style "..styleName)
	styleManager.currentStyle = styleName
	local path = getPathFromStyle(styleName)
	assert(fileExists(path.."styleSettings.txt"),"[DGS Style] Missing style setting ("..path.."styleSettings.txt)")
	local styleFile = fileOpen(path.."styleSettings.txt")
	local str = fileRead(styleFile,fileGetSize(styleFile))
	local fnc = loadstring("return {\n"..str.."\n}")
	assert(fnc,"Error when loading "..path.."styleSettings.txt")
	local customStyleSettings = fnc()
	if not next(styleSettings) then
		styleSettings = customStyleSettings
		return
	end
	for dgsType,settings in pairs(styleSettings) do
		if customStyleSettings[dgsType] then
			for dgsProperty,value in pairs(settings) do
				if customStyleSettings[dgsType][dgsProperty] then
					styleSettings[dgsType][dgsProperty] = customStyleSettings[dgsType][dgsProperty]
				end
			end
		end
	end
end

function dgsGetCurrentStyle()
	return styleManager.currentStyle
end

function dgsGetLoadedStyleList()
	return styleManager.styles
end

function dgsIsStyleAvailable(styleName)
	assert(type(styleName) == "string","Bad argument @dgsSetCurrentStyle at argument 1, expect a string got "..type(styleName))
	return styleManager.styles[styleName]
end

scanCustomStyle()
dgsSetCurrentStyle("Default")
if styleManager.currentStyle ~= styleManager.customStyle then
	dgsSetCurrentStyle(styleManager.customStyle)
end