 Public portion (TAG 7F 49)  

function NXPIASSmartCard.mt:get_os_version()
    log.output('NXPIASSmartCard:get_os_version():')
    local get_version = hex.hexf("00cb000304")
    local recv = self:sm_transmit(get_version, self.ActiveSM)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hex.hexf("9000") then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'get_os_version Error' ))
    end
    return bin.unpack("%>%H%>%H", recv)
end

function NXPIASSmartCard.mt:get_free_mem()
    log.output('NXPIASSmartCard:get_free_mem():')
    local get_size = hex.hexf("80cb001100")
    local recv = self:sm_transmit(get_size, self.ActiveSM)
    local sw = string.sub(recv, -2, -1)
    if sw ~= hex.hexf("9000") then
        error(NXPIASSmartCard.NXPIASSmartCardError.new(sw, 'get_free_mem Error' ))
    end
    return bin.unpack("%>%L", recv)
end

function NXPIASSmartCard.parse_ambs(data)
    local acs = {}
    while data and string.len(data) > 0 do
        local amb = string.byte(data, 1)
        local ambF = bin.flags(amb)
        local index = 2
        acs[7] = ambF[bin.flags((2^7))]
        
        for i=6,0,-1 do
            local iF = bin.flags(2^i)
            if ambF[iF] then
                local scb = string.byte(data, index)
                index = index + 1
                if not acs[i] then
                    acs[i] = {}
                end

                table.insert(acs[i], scb)
            end
        end
        data = string.sub(data, index, -1)
    end
    return acs
end

function NXPIASSmartCard.build_ambs(acs)
    local amb_7 = acs[7] and bin.flags(2^7) or bin.flags(0)
    local ambs = ""
    local sbc_index = 1
    while true do
        local cur = ""
        local cur_amb = amb_7
        local cur_scps = ""
        for i=6,0,-1 do
            local iF = bin.flags(2^i)
            local sbcs = acs[i]
            if sbcs and sbcs[sbc_index] then
                cur_amb = cur_amb + iF
                cur_scps = cur_scps .. string.char(sbcs[sbc_index])
            end
        end
        
        if string.len(cur_scps) == 0 then
            break
        end
        ambs = ambs .. string.char(cur_amb.asnumber) .. cur_scps
        sbc_index = sbc_index + 1
    end
    
    return ambs
end

-- local acContactAMBs1 = {[5]={[1]=19}, [7]=true, [0]={[1]=0}, [3]={[1]=19}}
-- local acContactAMBs2 = {[1]={[1]=255}, [4]={[1]=215, [2]=211}, [5]={[1]=0}, [6]={[1]=215, [2]=211}, [7]=true, [0]={[1]=0}}
-- local acContact1="F3D700D7FF00D0D3D3"
-- local ambs = NXPIASSmartCard.build_ambs(acContactAMBs1)
-- print (hex.hexify(ambs))
-- local ambs = NXPIASSmartCard.build_ambs(acContactAMBs2)
-- print (hex.hexify(ambs))
-- print (acContact1)

-- object classes
-- SDO CLASS                                  IDENTIFIER     TAG MIDDLE BYTE CODING
-- User authentication: PIN / Password        '01'           '81'
-- Biometric authentication : BIO             '02'           '82'
-- 3DES Symmetric key set of 2 keys           '0A'           '8A'
-- AES Symmetric key set of 2 keys            '0B'           '8B'
-- Asymmetric keys RSA 