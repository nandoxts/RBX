-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local v0 = {
    CollectionService = game:GetService("CollectionService"), 
    ReplicatedStorage = game:GetService("ReplicatedStorage"), 
    SoundService = game:GetService("SoundService"), 
    TweenService = game:GetService("TweenService")
};
local v1 = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);
local v2 = {
    Inside = {
        AudioEqualizer = {
            LowGain = 0, 
            HighGain = 0, 
            MidGain = 0
        }, 
        ReverbSoundEffect = {
            WetLevel = -20
        }
    }, 
    Outside = {
        AudioEqualizer = {
            LowGain = 0, 
            HighGain = 0, 
            MidGain = -80
        }, 
        ReverbSoundEffect = {
            WetLevel = -10
        }
    }
};
local v3 = {
    isInside = {}, 
    activeTweens = {}, 
    loadedDetectors = {}, 
    mainEffects = v0.SoundService:WaitForChild("MusicSoundGroup"), 
    zonePlus = require(v0.ReplicatedStorage.Modules:WaitForChild("CameraZone")), 
    utils = require(v0.ReplicatedStorage.Modules.Utils)
};
local function _(v4) --[[ Line: 45 ]] --[[ Name: clearTween ]]
    -- upvalues: v3 (copy)
    if v3.activeTweens[v4] then
        v3.activeTweens[v4]:Cancel();
        v3.activeTweens[v4] = nil;
    end;
end;
local function _(v6, v7) --[[ Line: 52 ]] --[[ Name: createTween ]]
    -- upvalues: v3 (copy), v0 (copy), v1 (copy)
    if v3.activeTweens[v6] then
        v3.activeTweens[v6]:Cancel();
        v3.activeTweens[v6] = nil;
    end;
    local v8 = v0.TweenService:Create(v6, v1, v7);
    v3.activeTweens[v6] = v8;
    v8:Play();
    return v8;
end;
local function v22(v10) --[[ Line: 60 ]] --[[ Name: applyAudioSettings ]]
    -- upvalues: v2 (copy), v0 (copy), v3 (copy), v1 (copy)
    local v11 = v2[v10];
    v0.SoundService:SetAttribute("CurrentRegion", v10);
    assert(v11, "Invalid audio region specified");
    if v3.utils.getOption("music", "fidelity") == false then
        for v12, v13 in pairs(v11) do
            local l_FirstChild_0 = v3.mainEffects:FindFirstChild(v12);
            if l_FirstChild_0 then
                if v3.activeTweens[l_FirstChild_0] then
                    v3.activeTweens[l_FirstChild_0]:Cancel();
                    v3.activeTweens[l_FirstChild_0] = nil;
                end;
                local v15 = v0.TweenService:Create(l_FirstChild_0, v1, v13);
                v3.activeTweens[l_FirstChild_0] = v15;
                v15:Play();
            end;
        end;
        return;
    elseif v10 == "Inside" then
        local l_mainEffects_0 = v3.mainEffects;
        local v17 = {
            Volume = 0.5
        };
        if v3.activeTweens[l_mainEffects_0] then
            v3.activeTweens[l_mainEffects_0]:Cancel();
            v3.activeTweens[l_mainEffects_0] = nil;
        end;
        local v18 = v0.TweenService:Create(l_mainEffects_0, v1, v17);
        v3.activeTweens[l_mainEffects_0] = v18;
        v18:Play();
        return;
    else
        local l_mainEffects_1 = v3.mainEffects;
        local v20 = {
            Volume = 0.1
        };
        if v3.activeTweens[l_mainEffects_1] then
            v3.activeTweens[l_mainEffects_1]:Cancel();
            v3.activeTweens[l_mainEffects_1] = nil;
        end;
        local v21 = v0.TweenService:Create(l_mainEffects_1, v1, v20);
        v3.activeTweens[l_mainEffects_1] = v21;
        v21:Play();
        return;
    end;
end;
local function v24(v23) --[[ Line: 86 ]] --[[ Name: handleRegionTransition ]]
    -- upvalues: v3 (copy), v22 (copy)
    if v23 then
        v3.isInside.a = (v3.isInside.a or 0) + 1;
        if v3.isInside.a == 1 then
            v22("Inside");
            return;
        end;
    elseif v3.isInside.a then
        v3.isInside.a = v3.isInside.a - 1;
        if v3.isInside.a <= 0 then
            v22("Outside");
            v3.isInside.a = nil;
        end;
    end;
end;
local function v29(v25) --[[ Line: 104 ]] --[[ Name: createAudioRegion ]]
    -- upvalues: v3 (copy), v24 (copy)
    if v3.loadedDetectors[v25] then
        return;
    else
        v3.loadedDetectors[v25] = true;
        local v26 = v3.zonePlus.new(v25);
        v26:ConnectEnter(function(v27) --[[ Line: 109 ]]
            -- upvalues: v25 (copy), v24 (ref)
            if v25 ~= v27 then
                return;
            else
                v24(true);
                return;
            end;
        end);
        v26:ConnectLeave(function(v28) --[[ Line: 113 ]]
            -- upvalues: v25 (copy), v24 (ref)
            if v25 ~= v28 then
                return;
            else
                v24(false);
                return;
            end;
        end);
        return v26;
    end;
end;
local _ = function() --[[ Line: 122 ]] --[[ Name: initialize ]]
    -- upvalues: v29 (copy), v22 (copy)
    for _, v31 in workspace.Detectors.Audio:GetChildren() do
        v29(v31);
    end;
    v22("Outside");
end;
v0.CollectionService:GetInstanceAddedSignal("AntiShadow"):Connect(v29);
for _, v34 in workspace.Detectors.Audio:GetChildren() do
    v29(v34);
end;
v22("Outside");