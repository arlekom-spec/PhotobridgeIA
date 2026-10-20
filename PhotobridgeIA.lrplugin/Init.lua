local Tasks = import 'LrTasks'
local App = import 'LrApplication'
local Files = import 'LrFileUtils'
local Paths = import 'LrPathUtils'
local Date = import 'LrDate'
local Develop = import 'LrDevelopController'
local View = import 'LrApplicationView'
local root = Paths.child(_PLUGIN.path, 'bridge')
Files.createAllDirectories(root)
local function write(name, body)
    local f = assert(io.open(Paths.child(root,name), 'wb'))
    f:write(body); f:close()
end
local function read(name)
    local f = io.open(Paths.child(root,name), 'rb')
    if not f then return nil end
    local s = f:read('*a'); f:close(); return s
end
local function clean(s) if s==nil then return '' end return tostring(s):gsub('[\r\n]', ' ') end
local limits = {
 Exposure2012={-5,5}, Contrast2012={-100,100}, Highlights2012={-100,100}, Shadows2012={-100,100},
 Whites2012={-100,100}, Blacks2012={-100,100}, Clarity2012={-100,100}, Texture={-100,100},
 Dehaze={-100,100}, Vibrance={-100,100}, Saturation={-100,100}, Temperature={2000,50000},
 Tint={-150,150}, ParametricDarks={-100,100}, ParametricLights={-100,100},
 ParametricShadows={-100,100}, ParametricHighlights={-100,100}, ParametricShadowSplit={0,100},
 ParametricMidtoneSplit={0,100}, ParametricHighlightSplit={0,100},
 Sharpness={0,150}, SharpenRadius={0.5,3}, SharpenDetail={0,100}, SharpenEdgeMasking={0,100},
 LuminanceSmoothing={0,100}, LuminanceNoiseReductionDetail={0,100},
 LuminanceNoiseReductionContrast={0,100}, ColorNoiseReduction={0,100},
 ColorNoiseReductionDetail={0,100}, ColorNoiseReductionSmoothness={0,100},
 GrainAmount={0,100}, GrainSize={0,100}, GrainFrequency={0,100},
 PostCropVignetteAmount={-100,100}, PostCropVignetteMidpoint={0,100},
 PostCropVignetteRoundness={-100,100}, PostCropVignetteFeather={0,100},
 SplitToningShadowHue={0,360}, SplitToningShadowSaturation={0,100},
 SplitToningHighlightHue={0,360}, SplitToningHighlightSaturation={0,100},
 SplitToningBalance={-100,100}, RedHue={-100,100}, GreenHue={-100,100},
 BlueHue={-100,100}, RedSaturation={-100,100}, GreenSaturation={-100,100},
 BlueSaturation={-100,100}, ShadowTint={-100,100},
 PerspectiveVertical={-100,100}, PerspectiveHorizontal={-100,100}, PerspectiveRotate={-100,100}
}
for _,c in ipairs({'Red','Orange','Yellow','Green','Aqua','Blue','Purple','Magenta'}) do
 for _,prefix in ipairs({'HueAdjustment','SaturationAdjustment','LuminanceAdjustment','GrayMixer'}) do
  limits[prefix..c]={-100,100}
 end
end
local function state(p)
    local lines = {'photo_id='..p.localIdentifier,
        'file='..clean(p:getRawMetadata('path')),
        'virtual='..tostring(p:getRawMetadata('isVirtualCopy')),
        'catalog='..clean(App.activeCatalog():getPath())}
    local s = p:getDevelopSettings()
    lines[#lines+1] = 'ConvertToGrayscale='..tostring(s.ConvertToGrayscale)
    for k in pairs(limits) do
        if s[k] ~= nil then lines[#lines+1]=k..'='..clean(s[k]) end
    end
    for _,k in ipairs({'rating','label','title','fileFormat'}) do
        local ok,v=Tasks.pcall(function() return p:getRawMetadata(k) end)
        if ok and v~=nil then lines[#lines+1]=k..'='..clean(v) end
    end
    write('state.txt',table.concat(lines,'\n'))
end
local function preview(p, id)
    p:requestJpegThumbnail(1600,1600,function(data)
        if data then
            write('preview-'..id..'.jpg', data)
            write('preview-status.txt','id='..id..'\nphoto_id='..p.localIdentifier..'\nstatus=ready')
        else
            write('preview-status.txt','id='..id..'\nstatus=error')
        end
    end)
end

local function checked(q,cat,p,requireCopy)
 assert(#cat:getTargetPhotos()==1,'Select exactly one photo')
 assert(q.photo_id==tostring(p.localIdentifier),'Selected photo changed')
 assert(q.catalog==cat:getPath(),'Catalog changed')
 -- Lightroom develop settings are non-destructive; target ID and catalog remain checked.
end
local function inspectFull(p,id)
 state(p)
 local s=p:getDevelopSettings()
 local keys={}
 local lines={'photo_id='..tostring(p.localIdentifier),'format=scalar-settings'}
 for k,v in pairs(s) do
  if type(v)=='number' or type(v)=='boolean' or type(v)=='string' then keys[#keys+1]=k end
 end
 table.sort(keys)
 for _,k in ipairs(keys) do
  local v=clean(s[k])
  if #v>300 then v=v:sub(1,300) end
  lines[#lines+1]=k..'='..v
 end
 write('settings-'..id..'.txt',table.concat(lines,'\n'))
 preview(p,id)
end
local function listPresets(id)
 local lines={'format=folder|preset|uuid'}
 local count=0
 for _,folder in ipairs(App.developPresetFolders() or {}) do
  for _,preset in ipairs(folder:getDevelopPresets() or {}) do
   lines[#lines+1]=clean(folder:getName())..'|'..clean(preset:getName())..'|'..clean(preset:getUuid())
   count=count+1
   if count>=1200 then break end
  end
  if count>=1200 then break end
 end
 write('presets-'..id..'.txt',table.concat(lines,'\n'))
end
local function capabilities(id)
 local actions={'inspect','inspect_full','capabilities','presets_list','apply','treatment','preset_apply','white_balance','crop','rotate','develop_get','develop_set','panel_show','tool_select','mask_list','mask_create','mask_invert','spot_count'}
 write('capabilities-'..id..'.txt','version=0.5-beta\ntransport=local-files\nrequire_virtual_copy_for_general_edits=false\nedit_selected_catalog_photo_nondestructively=true\nsupported_actions='..table.concat(actions,',')..'\nlimits=some_ai_and_detailed_mask_edits_need_gui')
end

local function developReady(cat,p,q)
 checked(q,cat,p,false)
 if View.getCurrentModuleName()~='develop' then
  View.switchToModule('develop')
  Tasks.sleep(0.9)
 end
 assert(View.getCurrentModuleName()=='develop','Develop unavailable')
end
local function validParam(p)
 assert(type(p)=='string' and p:match('^[%a_][%w_]*$') and #p<=80,'Invalid develop parameter')
 return p
end
local function maskDump(id)
 local all=Develop.getAllMasks() or {}
 local lines={'format=mask-properties','count='..tostring(#all)}
 local function walk(tbl,prefix,depth)
  if depth>4 or #lines>800 then return end
  local keys={}
  for k in pairs(tbl) do keys[#keys+1]=k end
  table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
  for _,k in ipairs(keys) do
   local v=tbl[k]
   local label=prefix..'.'..clean(k)
   if type(v)=='table' then walk(v,label,depth+1)
   elseif type(v)=='string' or type(v)=='number' or type(v)=='boolean' then
    lines[#lines+1]=label..'='..clean(v):sub(1,120)
   end
  end
 end
 walk(all,'mask',0)
 write('masks-'..id..'.txt',table.concat(lines,'\n'))
end
local panels={adjustPanel=true,tonePanel=true,mixerPanel=true,splitToningPanel=true,
 detailPanel=true,lensCorrectionsPanel=true,effectsPanel=true,calibratePanel=true}
local tools={loupe=true,crop=true,dust=true,redeye=true,masking=true,
 point_color=true,local_point_color=true,depth_refinement=true}
local masks={brush=true,gradient=true,radialGradient=true,rangeMask=true,aiSelection=true}
local subtypes={color=true,luminance=true,depth=true,subject=true,sky=true,
 background=true,objects=true,people=true,landscape=true}
_G.photobridgeIAGeneration = (_G.photobridgeIAGeneration or 0) + 1
local generation = _G.photobridgeIAGeneration
Tasks.startAsyncTask(function()
    -- Do not execute commands left behind by a previous Lightroom session.
    Files.delete(Paths.child(root,'command.txt'))
    write('status.txt','status=ready\nversion=0.5-beta\n')
    while _G.photobridgeIAGeneration == generation do
        local raw = read('command.txt')
        if raw then
            Files.delete(Paths.child(root,'command.txt'))
            local q = {}
            for line in raw:gmatch('[^\r\n]+') do
                local k,v=line:match('^([%w_]+)=(.*)$')
                if k then q[k]=v end
            end
            local ok,err=Tasks.pcall(function()
                assert(q.id and q.id:match('^[%w_-]+$') and #q.id<=64, 'Invalid request id')
                local cat=App.activeCatalog()
                local p=cat:getTargetPhoto()
                assert(p,'Select a photo in Lightroom')
                if q.action=='inspect' then
                    state(p); preview(p,q.id)
                elseif q.action=='treatment' then
                    assert(#cat:getTargetPhotos()==1,'Select exactly one photo')
                    assert(q.photo_id==tostring(p.localIdentifier),'Selected photo changed')
                    assert(q.catalog==cat:getPath(),'Catalog changed')
                    assert(q.value=='color' or q.value=='grayscale','Invalid treatment')
                    -- Treatment may apply directly to the selected catalog photo.
                    cat:withWriteAccessDo('PhotobridgeIA - treatment '..q.id,function()
                        p:quickDevelopSetTreatment(q.value)
                    end,{timeout=10})
                    state(p); preview(p,q.id)
                elseif q.action=='capabilities' then
                    capabilities(q.id)
                elseif q.action=='inspect_full' then
                    inspectFull(p,q.id)
                elseif q.action=='presets_list' then
                    listPresets(q.id)
                elseif q.action=='preset_apply' then
                    checked(q,cat,p,true)
                    assert(q.uuid and q.uuid:match('^[%w%-]+$') and #q.uuid<=100,'Invalid preset UUID')
                    local preset=assert(App.developPresetByUuid(q.uuid),'Preset not found')
                    cat:withWriteAccessDo('PhotobridgeIA preset '..q.id,function()
                        p:applyDevelopPreset(preset)
                    end,{timeout=10})
                    state(p); preview(p,q.id)
                elseif q.action=='white_balance' then
                    checked(q,cat,p,true)
                    local allowed={Auto=true,Daylight=true,Cloudy=true,Shade=true,Tungsten=true,Fluorescent=true,Flash=true}
                    assert(allowed[q.value],'Invalid white balance')
                    cat:withWriteAccessDo('PhotobridgeIA WB '..q.id,function()
                        p:quickDevelopSetWhiteBalance(q.value)
                    end,{timeout=10})
                    state(p); preview(p,q.id)
                elseif q.action=='crop' then
                    checked(q,cat,p,true)
                    local ratio
                    if q.value=='original' or q.value=='asshot' then ratio=q.value
                    else
                        local w,h=tonumber(q.width),tonumber(q.height)
                        assert(w and h and w>=1 and h>=1 and w<=10000 and h<=10000,'Invalid ratio')
                        ratio={w=w,h=h}
                    end
                    cat:withWriteAccessDo('PhotobridgeIA crop '..q.id,function()
                        p:quickDevelopCropAspect(ratio)
                    end,{timeout=10})
                    state(p); preview(p,q.id)
                elseif q.action=='rotate' then
                    checked(q,cat,p,true)
                    assert(q.value=='left' or q.value=='right','Invalid direction')
                    cat:withWriteAccessDo('PhotobridgeIA rotate '..q.id,function()
                        if q.value=='left' then p:rotateLeft() else p:rotateRight() end
                    end,{timeout=10})
                    state(p); preview(p,q.id)
                elseif q.action=='develop_get' then
                    developReady(cat,p,q)
                    local param=validParam(q.parameter)
                    local v=Develop.getValue(param)
                    local low,high=Develop.getRange(param)
                    write('develop-'..q.id..'.txt','photo_id='..p.localIdentifier..'\nparameter='..param..'\nvalue='..clean(v)..'\nmin='..clean(low)..'\nmax='..clean(high))
                elseif q.action=='develop_set' then
                    developReady(cat,p,q)
                    local param=validParam(q.parameter)
                    local low,high=Develop.getRange(param)
                    assert(type(low)=='number' and type(high)=='number' and low<high,'Parameter not editable')
                    local v=tonumber(q.value)
                    assert(v and v==v and v>=low and v<=high,'Value outside range')
                    cat:withWriteAccessDo('PhotobridgeIA develop '..q.id,function()
                        Develop.setValue(param,v)
                    end,{timeout=10})
                    state(p); preview(p,q.id)
                elseif q.action=='panel_show' then
                    developReady(cat,p,q)
                    assert(panels[q.panel] or (q.panel and limits[q.panel]),'Unsupported panel')
                    Develop.revealPanel(q.panel)
                elseif q.action=='tool_select' then
                    developReady(cat,p,q)
                    assert(tools[q.tool],'Unsupported Develop tool')
                    Develop.selectTool(q.tool)
                    write('tool-'..q.id..'.txt','tool='..clean(Develop.getSelectedTool()))
                elseif q.action=='mask_list' then
                    developReady(cat,p,q)
                    maskDump(q.id)
                elseif q.action=='mask_create' then
                    developReady(cat,p,q)
                    assert(masks[q.kind],'Unsupported mask kind')
                    assert((q.kind~='aiSelection' and q.kind~='rangeMask') or subtypes[q.subtype],'Mask subtype required')
                    Develop.goToMasking()
                    Develop.createNewMask(q.kind,q.subtype)
                    maskDump(q.id)
                    state(p); preview(p,q.id)
                elseif q.action=='mask_invert' then
                    developReady(cat,p,q)
                    assert(q.mask_id and q.mask_id:match('^[%w%-_]+$') and #q.mask_id<128,'Invalid mask ID')
                    Develop.invertMask(q.mask_id)
                    maskDump(q.id)
                elseif q.action=='spot_count' then
                    developReady(cat,p,q)
                    write('spots-'..q.id..'.txt','count='..clean(Develop.countAllSpots()))
                elseif q.action=='apply' then
                    assert(q.photo_id==tostring(p.localIdentifier),'Selected photo changed')
                    assert(q.catalog==cat:getPath(),'Catalog changed')
                        assert(#cat:getTargetPhotos()==1,'Select exactly one photo')
                        local settings={}
                        local count=0
                        for k,v in pairs(q) do
                            if k~='id' and k~='action' and k~='photo_id' and k~='catalog' then
                                local range=assert(limits[k],'Unsupported setting: '..k)
                                local n=tonumber(v)
                                assert(n and n>=range[1] and n<=range[2],'Out of range: '..k)
                                settings[k]=n; count=count+1
                            end
                        end
                        assert(count>0,'No adjustments supplied')
                        cat:withWriteAccessDo('PhotobridgeIA '..q.id,function()
                            p:applyDevelopSettings(settings,'PhotobridgeIA '..q.id)
                        end,{timeout=10})
                    state(p); preview(p,q.id)
                else error('Unsupported action') end
            end)
            write('response.txt','id='..clean(q.id)..'\nstatus='..(ok and 'ok' or 'error')..'\nmessage='..clean(err))
        end
        write('heartbeat.txt',tostring(Date.currentTime()))
        Tasks.sleep(1)
    end
end)
