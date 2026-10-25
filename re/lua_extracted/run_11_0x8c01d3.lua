 abilitato

s.files_detect_table = {
    { files ={'3f0010001003', '3f0014008100'},
      filesystem = 'cns_incard',    -- incard: cns + DS
    },
    { files ={'3f0010001003', '3f0014009002'},
      filesystem = 'cns_oberthur', -- oberthur: cns + DS
    },
    { files ={'3f0010001010', '3f0014009002'},
      filesystem = 'cns_oberthur_postecom', -- oberthur per POSTECOM: cns + DS
    },
    { files ={'3f0010001003', '3f0014007100'},
      filesystem = 'cns_athena', -- athena: cns + DS
    },
    { files={'3f008100'},
      filesystem = 'ds_incard',    -- incard: ds only
    },
    { files={'3f007F00'},
      filesystem = 'ds_incard',    -- incard: ds only on 7F00
    },
    { files ={'3f0010001003', '3f002fff'},
      filesystem = 'cns_incard', -- incard: cns + P11
    },
    { files ={'3f002fff' },
      filesystem = 'cns_incard', -- incard: P11 only
    },
    { files={'3f0014008100'},
      filesystem = 'ds_incard',    -- incard: ds only on 1400
    },
    { files ={'3f0010001003', '3f0014009101'},
      filesystem = 'cns_gemalto', -- gemalto: cns + DS
    },
    { files ={'3f0010001003'},
      filesystem = 'cns',          -- cns generica
    },
}

function s._file_exist(card, file_path)
    local cns_card = CnsSmartcard.new(hcard)
    local pcRes, theErrorT = pcall(function() 
        card:select(hex.hexf(file_path))
        end)
    if pcRes then
        return 1
    else
        log.output("--LUA: _file_exist() error:", theErrorT)
        return 0
    end
end

-- if there's 
function s._detect_fs_cached(hcard, cfg)

    local fsname
    local reader_name
    local cache_path = cfg and (cfg["umcachepath"] or cfg["oumcachepath"] or cfg["iumcachepath"])
    local cache_enabled
    local uniquereadernames = cfg and cfg["uniquereadernames"]
    log.output("--LUA: _detect_fs_cached()...")
    local status, err = hcard:status()
    if status and status.reader then
        reader_name = status.reader
        log.output("--LUA: _detect_fs_cached(): evaluating reader_name=", reader_name)
        cache_enabled = util.cache_verify_unique_reader(uniquereadernames, reader_name)
    end
    
    if cache_enabled then
        log.output("--LUA: _detect_fs_cached(): cache_enabled for reader=", reader_name)
        fsname = util.cache_read(reader_name, "detect_fsname", true, cache_path)
        if type(fsname) == "string" and string.len(fsname) > 0 then
            log.output("--LUA: _detect_fs_cached(): returning cached fsname=", fsname)
            return fsname
        end
    end
            
    local fsname = s._detect_fs(hcard, cfg)
    
    if cache_enabled then
        log.output("--LUA: _detect_fs_cached(): caching fsname=", fsname)
        util.cache_write(reader_name, "detect_fsname", fsname, cache_path)
    end
    
    return fsname
end

function s._detect_fs(hcard, cfg)

    local _etokensf = s._active_tokens_mask
    
    log.output("--LUA: _detect_fs():...")
    
    log.output("--LUA: _detect_fs(): detect part 1: cards detected by ATR only")
    
    if _etokensf[bin.flags(token_class_nxpias)] then
        log.output("_detect_fs(): detect by ATR NXP IAS/ECC...")
        -- WARNING: ATR ONLY DETECT CODE
        -- IF you add any trasmit before ATR detect, detect priority shall be re-evaluated
        
        local status, err = hcard:status()
        log.output("_detect_fs(): status result:", err)
        log.output("_detect_fs(): status:", util.repr(status))
        if status and (
            status.atr == hex.hexf("3BDF18FF8191FE1FC30031B8640C01ECC173940180829000B3")
            or status.atr == hex.hexf("3BDC18FF8191FE1FC38073C821136605036351000250")
            or status.atr == hex.hexf("3BDC18FF8091FE1FC38073C8211366010B0352000539")
            ) then
            log.output("_detect_fs(): ATR is a NXP IAS/ECC")
            return "nxpias"
        end
    end
    
    if _etokensf[bin.flags(token_class_nxpcdlite)] then
        -- WARNING: ATR ONLY DETECT CODE
        -- IF you add any trasmit before ATR detect, detect priority shall be re-evaluated
        log.output("_detect_fs(): detect by ATR NXP ChipDoc Lite...")
        
        local status, err = hcard:status()
        log.output("_detect_fs(): status result:", err)
        log.output("_detect_fs(): status:", util.repr(status))
        if status and (
            status.atr == hex.hexf("3BFF9400008131FE45006B150C0302010101434E53103180ED") -- CDLite + CNS: TA1=94
            or status.atr == hex.hexf("3BFF1800008131FE45006B150C0302010101434E5310318061") -- CDLite + CNS: TA1=18
            or status.atr == hex.hexf("3BFF1800008131FE45006B150C03020101014234441031800D") -- CDLite: TA1=18
            ) then
            log.output("_detect_fs(): ATR is a NXP Chipdoc Lite")
            return "nxpcdlite"
        end
    end
    
    if _etokensf[bin.flags(token_class_idacosmox)] then
        -- WARNING: ATR ONLY DETECT CODE
        -- IF you add any trasmit before ATR detect, detect priority shall be re-evaluated
        log.output("_detect_fs(): detect by ATR ID-A CosmoX...")
        
        local status, err = hcard:status()
        log.output("_detect_fs(): status result:", err)
        log.output("_detect_fs(): status:", util.repr(status))
        if status and (
            status.atr == hex.hexf("3BDF96008131FE4580738421E0574D44415F415350810176")
            or status.atr == hex.hexf("3BDF96008131FE4580738421E0574D44415F415350810F78")
            or status.atr == hex.hexf("3B8F800180738421E0574D44415F41535081003B")
            ) then
            log.output("_detect_fs(): ATR is a ID-A CosmoX")
            local CosmoXIASSmartCard = require "CosmoXIASSmartCard"
            local card = CosmoXIASSmartCard.new(hcard)    
            local found
            card:begin_transaction()
            local pcRes, theErrorT = pcall( function()
                card:select_Applet()
                found = true
            end)
            card:end_transaction()
            if not pcRes then
                log.output("--LUA: _detect_fs(): ID-A CosmoX (By AID) error:", theErrorT)
            end
            if found then
                log.output("_detect_fs(): is a ID-A CosmoX (By AID)")
                return "idacosmox"
            end
        end
    end
    
    log.output("--LUA: _detect_fs(): detect part 2: all other cards")

    if _etokensf[bin.flags(token_class_oberthur)] then
        local select_v1 = hex.hexf("00A4040010A0000000770103000610000000000002")
        local select_v2 = hex.hexf("00a4040010A000000077010800071000FE00000900")
        local select_1, select_2
        local status, err = hcard:status()
        
        if status and status.atr == hex.hexf("3BFF1800008131FE45006B05052000012101434E5310318079") then
            select_1, select_2 = select_v2, select_v1
            log.output("--LUA: _detect_fs(): oberthur detect order v2 -> v1")
        else
            select_1, select_2 = select_v1, select_v2
            log.output("--LUA: _detect_fs(): oberthur detect order v1 -> v2")
        end
        local card = CnsSmartcard.new(hcard)    
        local found, postecom, normal
        card:begin_transaction()
        pcall( function()
            local recv = card:transmit(select_1) -- select CNS applet
            local sw = string.sub(recv, -2, -1)
            if sw ~= hex.hexf("9000") then
                recv = card:transmit(select_2) -- select CNS applet
            end
        end)
        local pcRes, theErrorT = pcall( function()
            card:select(hex.hexf("3f0014009002")) -- path
            found = true
        end)
        if not pcRes then
            log.output("--LUA: _detect_fs(): oberthur detect error:", theErrorT)
        else
            pcall( function()
                card:select(hex.hexf("3f0010001003")) -- path
                normal = true
            end)
            if not normal then
                pcall( function()
                    card:select(hex.hexf("3f0010001010")) -- path
                    postecom = true
                end)
            end
        end
        card:end_transaction()
        
        if postecom then
            return "cns_oberthur_postecom"
        elseif normal then
            return "cns_oberthur"
        end
    end
    
    if _etokensf[bin.flags(token_class_nxpcdlite)] then
        local NXPChipDocLite = require "NXPChipDocLite"
        local card = NXPChipDocLite.new(hcard)    
        local found
        card:begin_transaction()
        local pcRes, theErrorT = pcall( function()
            card:select_applet()    -- force select APPLET
            card:select_Generic()   -- force select Generic (Applet AID may collide with other ICAO applets)
            found = true
        end)
        card:end_transaction()
        if not pcRes then
            log.output("--LUA: _detect_fs(): NXP Chipdoc Lite (By AID) error:", theErrorT)
        end
        if found then
            log.output("_detect_fs(): is a NXP Chipdoc Lite (By AID)")
            return "nxpcdlite"
        end
    end

    if _etokensf[bin.flags(token_class_idacosmox)] then
        local CosmoXIASSmartCard = require "CosmoXIASSmartCard"
        local card = CosmoXIASSmartCard.new(hcard)    
        local found
        card:begin_transaction()
        local pcRes, theErrorT = pcall( function()
            card:select_Applet()
            card:select_Generic()   -- force select Generic
            found = true
        end)
        card:end_transaction()
        if not pcRes then
            log.output("--LUA: _detect_fs(): ID-A CosmoX (By AID) error:", theErrorT)
        end
        if found then
            log.output("_detect_fs(): is a ID-A CosmoX (By AID)")
            return "idacosmox"
        end
    end

    if _etokensf[bin.flags(token_class_nxpias)] then
        local NXPIASSmartCard = require "NXPIASSmartCard"
        local card = NXPIASSmartCard.new(hcard)    
        local found
        card:begin_transaction()
        local pcRes, theErrorT = pcall( function()
            card:select_Applet()
            found = true
        end)
        card:end_transaction()
        if not pcRes then
            log.output("--LUA: _detect_fs(): NXP IAS/ECC (By AID) error:", theErrorT)
        end
        if found then
            log.output("_detect_fs(): is a NXP IAS/ECC (By AID)")
            return "nxpias"
        end
    end
    
    if _etokensf[bin.flags(token_class_cryptoid)] then
        local found
        local recvAtr, recvSelect1, recvSelect2  = "", "", ""
        log.output("--LUA: _detect_fs(): detecting token_class_cryptoid")
        hcard:begintransaction()
        local pcRes, theErrorT = pcall( function()
            recvAtr = hcard:transmit(hex.hexf("00CA010000")) -- get data ATR
            if recvAtr and string.sub(recvAtr, -2, -1) == hex.hexf("9000") then
                local status, err = hcard:status()
                if status and string.find(status.atr, string.sub(recvAtr, 1, -3), 1, true) then
                    log.output("--LUA: _detect_fs(): found cryptoID, FS detect now....")
                    recvSelect1 = hcard:transmit(hex.hexf("00A40800043f00501100")) -- select P11 APP
                    recvSelect2 = hcard:transmit(hex.hexf("00A4020002000100")) -- select P11 info
                end
            end
        end)
        hcard:endtransaction()
        found = recvSelect1 and recvSelect2 and string.sub(recvSelect1, -2, -1) == hex.hexf("9000")
                    and string.sub(recvSelect2, -2, -1) == hex.hexf("9000")
        
        
        if found then
            return "cryptoid"
        end
    else
        log.output("--LUA: _detect_fs(): _etokensf:", util.repr(_etokensf))
    end
    
    if _etokensf[bin.flags(token_class_aet_startcos)] then
        local StarCosSKP23Smartcard = require "StarCosSKP23Smartcard"
        local card = StarCosSKP23Smartcard.new(hcard)    
        local found
        card:begin_transaction()
        local pcRes, theErrorT = pcall( function()
            card:select_p15()
            -- select the card IPF
            card:select(hex.hexf("4601"), true) -- fid, relative
            card:select(hex.hexf("4400"), true) -- fid, relative
            found = true
        end)
        card:end_transaction()
        if not pcRes then
            log.output("--LUA: _detect_fs(): starcos aet error:", theErrorT)
        end
        if found then
            return "aet_startcos"
        end
    end
    
    if _etokensf[bin.flags(token_class_gemalto_classic)] then
        local GemaltoSmartcard = require "GemaltoSmartcard"
        local card = GemaltoSmartcard.new(hcard)    
        local found
        card:begin_transaction()
        local pcRes, theErrorT = pcall( function()
            card:select_p15()
            -- select the card SN file
            card:select(hex.hexf("0001"), true, false) -- fid, relative, use_sm
            found = true
        end)
        card:end_transaction()
        if not pcRes then
            log.output("--LUA: _detect_fs(): gemalto classic error:", theErrorT)
        end
        if found then
            return "gemalto_classic"
        end
    end


    if _etokensf[bin.flags(token_class_eida)] then
        local EIDASmartcard = require "EIDASmartcard"
        local card = EIDASmartcard.new(hcard)    
        local found
        card:begin_transaction()
        local pcRes, theErrorT = pcall( function()
            card:select_p15()
            -- select the card SN file
            card:select(hex.hexf("0003"), true, false) -- fid, relative, use_sm
            found = true
        end)
        card:end_transaction()
        if not pcRes then
            log.output("--LUA: _detect_fs(): EIDA error:", theErrorT)
        end
        if found then
            return "eida"
        end
    end
    
    if _etokensf[bin.flags(token_class_cmd)] then
        local card = CnsSmartcard.new(hcard)    
        local found
        card:begin_transaction()
        local pcRes, theErrorT = pcall( function()
            card:select(hex.hexf("3f0012001400c000")) -- path
            card:select(hex.hexf("3f0010001003")) -- path
            found = true
        end)
        card:end_transaction()
        if not pcRes then
            log.output("--LUA: _detect_fs(): CMD/MilCard error:", theErrorT)
        end
        if found then
            return "cmd_milcard"
        end
    end
    
    if _etokensf[bin.flags(token_class_cmg)] then
        local card = CnsSmartcard.new(hcard)    
        local found
        card:begin_transaction()
        local pcRes, theErrorT = pcall( function()
            card:select(hex.hexf("3f0012001f073f01")) -- path
            card:select(hex.hexf("3f001400150124002401")) -- path
            card:select(hex.hexf("3f0010001003")) -- path
            found = true
        end)
        card:end_transaction()
        if not pcRes then
            log.output("--LUA: _detect_fs(): CMG error:", theErrorT)
        end
        if found then
            return "cmg"
        end
    end

    if _etokensf[bin.flags(token_class_it_telecom)] then
        local card = s.token_types[token_class_it_telecom].ITTelecomSmartcard.new(hcard)
        local found
        card:begin_transaction()
        -- durante il detect la selezione AID viene forzata
        local pcRes, theErrorT = pcall(function() card:select_aid(true) end)
        if not pcRes then
            log.output("itTelecom detect error:", theErrorT)
        end
        found = pcRes 
        card:end_transaction()
        if found then
            return "it_telecom"
        end
    end
    
    if _etokensf[bin.flags(token_class_cardos44)] then
        local card = CnsSmartcard.new(hcard)
        local found
        card:begin_transaction()
        local recv = card:transmit(hex.hexf("00A404000405040200"))
        found = recv and string.sub(recv, -2, -1) == hex.hexf("9000")
        if found then
            recv = card:transmit(hex.hexf("00A40900020001"))
            found = recv and string.sub(recv, -2, -1) == hex.hexf("9000")
        end
        card:end_transaction()
        if found then
            return "cardos44"
        end
    end
    
    if _etokensf[bin.flags(token_class_iasecc)] then
        local status, err = hcard:status()
        log.output("_detect_fs(): status result:", err)
        log.output("_detect_fs(): status:", util.repr(status))
        if string.find( status.atr,  hex.hexf("008131FE4580F9A000000077010800079000"), 1, true) then
            log.output("_detect_fs(): is a iasecc")
            return "iasecc"
        end
    end
    
    if _etokensf[bin.flags(token_class_inside)] then
        local status, err = hcard:status()
        log.output("_detect_fs(): status result:", err)
        log.output("_detect_fs(): status:", util.repr(status))
        if status.atr == hex.hexf("3B9F11108062697434696420312E303020202020") or 
        status.atr == hex.hexf("3B9F1110805661756C74494320343035312E3030") then
            log.output("_detect_fs(): is an inside")
            return "inside"
        end
    end
       

    if _etokensf[bin.flags(token_class_cns_full)] 
            or _etokensf[bin.flags(token_class_cns_incard)]
            or _etokensf[bin.flags(token_class_cns_incard_pinpad)] then
        log.output("--LUA: _detect_fs(): probing JSIGN CNS generic applet")
        local card = CnsSmartcard.new(hcard)
        local found
        local recv
        card:begin_transaction()
        pcall( function()
            recv = card:transmit(hex.hexf("00A4040009A00000009501004D00")) -- select CNS Jsign3 & "generic" applet
            if  recv and string.sub(recv, -2, -1) == hex.hexf("6a82") then
            log.output("--LUA: _detect_fs(): probing JSIGN CNS legacy applet")
                recv = card:transmit(hex.hexf("00A404000CA00000009501004D00000001")) -- select CNS Jsign1/2 applet
            end
        end)
        card:end_transaction()
        found = recv and string.sub(recv, -2, -1) == hex.hexf("9000")
        if found then
            return "cns_incard"
        end
    end
    
    

    if _etokensf[bin.flags(token_class_piv)] then
        local found
        local recv
        hcard:begintransaction()
        pcall( function()
            recv = hcard:transmit(hex.hexf("00A404000BA00000030800001000010000")) -- select PIV applet            
        end)
        hcard:endtransaction()
        found = recv and string.sub(recv, -2, -1) == hex.hexf("9000")
        if found then
            return "piv"
        end
    end

    if _etokensf[bin.flags(token_class_dni_peru)] then
        local DniSmartcard = require "DniSmartcard"
        local card = DniSmartcard.new(hcard)    
        local found
        card:begin_transaction()
        pcall( function()
            card:transmit(hex.hexf("00A4040010A0000000770100700A1000F100000100")) -- select PKI applet            
        end)
        local pcRes, theErrorT = pcall( function()
            card:select(hex.hexf("3f0050153402")) -- path
        end)
        if not pcRes then
            log.output("--LUA: _detect_fs(): DNI Peru detect error:", theErrorT)
        end
        found = pcRes
        card:end_transaction()
        if found then
            return "dni_peru"
        end
    end
    
    if _etokensf[bin.flags(token_class_arjo)] then
        local found
        local recv
        log.output("--LUA: _detect_fs(): detecting token_class_cryptoid")
        hcard:begintransaction()
        pcall( function()
            recv = hcard:transmit(hex.hexf("00A404000CA000000063504B43532D313500")) -- select p15            
        end)
        hcard:endtransaction()
        found = recv and string.sub(recv, -2, -1) == hex.hexf("9000")
        
        if found then
            return "arjo"
        end
    end
    
    if _etokensf[bin.flags(token_class_cie3)] then
        local found
        local recv
        log.output("--LUA: _detect_fs(): detecting token_class_cie3")
        hcard:begintransaction()
        pcall( function()
            recv = hcard:transmit(hex.hexf("00A4040C0DA000000030800000000981600100")) -- select IAS AID
            if recv and string.sub(recv, -2, -1) == hex.hexf("9000") then
                recv = hcard:transmit(hex.hexf("00b09C0000")) -- read binary of file D003 with SFI=0x1C: P1 = 0x80 | 0x1C = 0x90
                found = recv and string.sub(recv, -2, -1) == hex.hexf("9000")
            end
        end)
        hcard:endtransaction()
        if found then
            return "cie3"
        end
    end
    
    if _etokensf[bin.flags(token_class_siae)] then
        local status, err = hcard:status()
        log.output("_detect_fs(): status result:", err)
        log.output("_detect_fs(): status:", util.repr(status))
        if status.atr == hex.hexf("3BFB1100FF81318055006802001010534941450004") then
            log.output("_detect_fs(): is a siae")
            return "siae"
        end
    end
    

    local cns_card = CnsSmartcard.new(hcard)
    local select_cache = {}
    cns_card:begin_transaction()
    local pcRes, theErrorT = pcall( function()
        for n, v in s.files_detect_table do
            log.output("--LUA: _detect_fs(): trying ", v.filesystem)
            local found = true
            for k, f in v.files do
                if not select_cache[f] then
                    log.output("--LUA: _detect_fs(): select not in cache")
                    select_cache[f] = s._file_exist(cns_card, f)
                end
                if select_cache[f] == 0 then
                    found = false
                    break
                end
            end
            if found then
                log.output("--LUA: _detect_fs(): detected fs", v.filesystem)
                return v.filesystem, v.lib
            end
        end
        log.output("--LUA: _detect_fs(): unknown fs")
        return 'unknown'
    end )
    cns_card:end_transaction()
    if not pcRes then
        log.output("--LUA: _detect_fs(): error:", theErrorT)
        return 'unknown'
    end
    return theErrorT
end

-----------------------------------------------------------------------------

-- Quella che segue 