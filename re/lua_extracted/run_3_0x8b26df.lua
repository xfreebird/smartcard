 noto quanti ATR esistono)
      mask= hex.hexf("ffffffffffffff"),   -- ATR completo: 3bb794008131fe 6553504b32339000d1
      lib="ipmpkilc",
      card_factory=StarCosSKP23SmartcardLite.new,
      required_files={"1111"},
      partial=true,
    },
    { atr = hex.hexf("3b9f94401e0067164346495345105266ff819000"),   -- Infocamere 1201 setec
      mask= hex.hexf("ffffffffffffffffffffffffffffffffffffffff"),
      lib="ipmpki32",
    },
    { atr = hex.hexf("3bf29800ffc11031fe55c80412"),   -- Infocamere 1203 - CardOS M4.01a
      mask= hex.hexf("ffffffffffffffffffffffffff"),
      lib="ipmpki32",
    },
        { atr = hex.hexf("3bff1100ff81318055006802001010494e43525950544f001a"),   -- ST INCARD INCRYPTO V1 32K
          mask= hex.hexf("ffffffffffffffffffffffffffffffffffffffffffffffffff"),
          lib="ipmpki32",
        },
        { atr = hex.hexf("3be200ffc11031fe55c8029c"),   -- Postecom
          mask= hex.hexf("ffffffffffffffffffffffff"),
          lib="gclib",
        },
        { atr = hex.hexf("3ba70040188065a208010152"),   -- RTRT
          mask= hex.hexf("ffffffffffffffffffffffff"),
          lib="gclib",
        },
        { atr = hex.hexf("3bf4180002c10a31fe5856346376c5"),   -- Token EUTRON CARDOS M4.3B - Charismatics
          mask= hex.hexf("ffffffffffffffffffffffffffffff"),
          lib="cmp11",
        },

    -- Infocamere 1204 / Infocamere 7420 (solo per test)
    --{ atr = hex.hexf("3bff1800ff8131fe55006b02090200011101434e531131808e"),
    --  mask= hex.hexf("ffffffffffffffffffffffffffffffffffffffffffffffffff"),
    --  lib="incryptoki",
    -- required_files = nil,  -- lista di file richiesti
    -- card_factory = nil,    -- factory della ll'interfaccia smartcard che implementa la select(path)
    -- handlecns=nil          -- per questa carta la parte CNS DOVREBBE essere gestita dal PKCS#11
    -- continue=nil          -- se non riesce a caricare libreria p11 associata o a individuare i required_files, passa al prossimo ATR
    --},    
}

log.output("libs table (before global hook):")
for i, v in p11_util.pkcs11_libs do
    log.output(string.format("lib: '%s'=%s", i, repr(v) ) )
end
log.output("ATRs table (before global hook):")
for i, v in p11_util.atrs_detect_table do
    log.output(string.format("lib:'%s', ATR:%s, MASK:%s", v.lib, hex.hexify(v.atr), hex.hexify(v.mask)) )
end

-- HOOK sulla lista di librerie
p11_util.pkcs11_libs = global_pkcs11_libs or p11_util.pkcs11_libs

-- HOOK sulla lista di ATR
p11_util.atrs_detect_table = global_atrs_detect_table or p11_util.atrs_detect_table


-- conterra' le istanze delle librerie caricate
p11_util.loaded_libraries = {

}


    

function p11_util.finalize()
    log.output("p11_util.finalize")
    for k, p in p11_util.loaded_libraries do
        pcall(function ()
            local finalize = (not _dont_finalize_pkcs11_libs)
            log.output("Closing lib:", k, p.lib, "finalizing:", finalize)
            if not p.buggedunload then
                p.lib:close(finalize)
            else
                log.output("buggedunload was set, not unloading library!")
            end
        end )
    end
    p11_util.loaded_libraries = {}
end

function p11_util.get_p11(hcard)
    local p
    local wasDisabled = hcard:disabletransactions(false)
    if wasDisabled then hcard:endtransaction() end
    
    local status, err = hcard:status()
    if not status then
        log.output("p11_util.get_p11(): smartcard removed?...")
        return
    end
    local pcRes, theErrorT=pcall(function()
        for k, v in p11_util.atrs_detect_table do
            local atr = status.atr
            local partial_found = false
            log.output("Trying ATR/MASK:", hex.hexify(v.atr), hex.hexify(v.mask or ""), v.lib, v.partial)
            if v.partial then
                if v.mask then
                    atr=string.sub(status.atr, 1, string.len(v.atr))
                    log.output("partial ATR cutted...")
                else
                    partial_found = string.find(status.atr, v.atr, 1, true) ~= nil
                    if partial_found then 
                        log.output("partial ATR found:", partial_found)
                    end
                end
            end
            
            if partial_found or (v.mask and bin.mask_compare(atr, v.atr, v.mask)) then
                log.output("p11_util.get_p11(): ATR recognized")
                
                local files_ok = true
                if v.required_files and v.card_factory then
                    log.output("p11_util.get_p11(): card requires additional file based identification")
                    local scard = v.card_factory(hcard)
                    for j, f in v.required_files do
                        local pcRes = pcall(function()
                            scard:select(hex.hexf(f))
                        end)
                        if not pcRes then
                            files_ok = false
                            break
                        end
                    end
                    log.output("p11_util.get_p11(): additional file based identification result:", files_ok)
                end
                if files_ok and p11_util.pkcs11_libs[v.lib] then
                    log.output("p11_util.get_p11(): card is", v.lib)
                    local handlecns = p11_util.pkcs11_libs[v.lib].handlecns and v.handlecns
                    if p11_util.loaded_libraries[v.lib] then
                        p = p11_util.loaded_libraries[v.lib]
                        log.output("p11_util.get_p11(): lib already loaded:", p, p.slotBase)
                        return p.lib, p.slotBase, handlecns
                    elseif p11_util.pkcs11_libs[v.lib] then
                        local forceInit = p11_util.pkcs11_libs[v.lib].forceInitialize
                        for n, l in p11_util.pkcs11_libs[v.lib].libs do
                            log.output("p11_util.get_p11(): loading", l)
                            if pcall(function() p = p11wrap.load(l, true, forceInit) end) then
                                p11_util.loaded_libraries[v.lib] = {
                                    lib=p,
                                    slotBase=p11_util.pkcs11_libs[v.lib].slotBase,
                                    buggedunload=p11_util.pkcs11_libs[v.lib].buggedunload}
                                log.output("pkcs11 successfully loaded:", p, p11_util.pkcs11_libs[v.lib].slotBase, p11_util.pkcs11_libs[v.lib].buggedunload)
                                -- todo: check p11 instance ?
                                return p, p11_util.pkcs11_libs[v.lib].slotBase, handlecns
                            end
                        end
                    end
                end
                log.output("p11_util.get_p11(): unable to load a pkcs11 for this card. files_ok:", files_ok)
                if not v.continue then
                    log.output("p11_util.get_p11(): cannot try next ATR since 'continue' flag is not set")
                    return nil
                else
                    log.output("p11_util.get_p11(): trying next ATR...")
                end
            end
        end
        log.output("p11_util.get_p11(): card type not supported...")
        return nil
    end)
    if wasDisabled then
        local status, err = hcard:status()
        if not status or (err and err ~= 0) then
            hcard:reconnect()
        end
        hcard:begintransaction()
    end
    hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end
end

-----------------------------------------------------------------
--- sistema di wrapping degli handle degli oggetti
--- evita le collisioni con gli handle degli oggetti di sessione
-----------------------------------------------------------------

function t.mt:alloc_object_handle()
    self.objects_next = self.objects_next+1
    return self.objects_next-1
end

function t.mt:_init_objects()
    if not self.objects then
        self.objects = {}
        self.objects_next = 5001;
    end
end

function t.mt:_wrap_handle(hInternal)
    self:_init_objects()
    if not hInternal or hInternal==0 then
        return 0
    end
    for i,h in self.objects do
        if h.handle == hInternal then
            -- already wrapped
            return i
        end
    end
    local newHandle = self:alloc_object_handle()
    self.objects[newHandle] = {handle = hInternal}
    return newHandle
end

function t.mt:_unwrap_handle(hExternal)
    self:_init_objects()
    if not hExternal or hExternal==0 then
        return 0
    end
    local wrapped = self.objects[hExternal]
    return (wrapped and wrapped.handle) or 0
end

function t.mt:_remove_handle(hInternal)
    self:_init_objects()
    for i,h in self.objects do
        if h.handle == hInternal then
            self.objects[i] = nil
            return
        end
    end
end
-----------------------------------------------------------------

function t.mt:_new_session(flags, tryRW)
    local rv, session
    if tryRW then
        local nflags = flags + CKF.RW_SESSION
        log.output("Opening RW session...", nflags)
        rv, session = self.p11_lib:open_session(self.P11SlotID, nflags.asnumber)
    end
    if not tryRW or rv ~= CKR.OK then
        log.output("Opening RO session...", flags)
        rv, session = self.p11_lib:open_session(self.P11SlotID, flags.asnumber)
    end    
    if rv ~= CKR.OK then error(string.format("%x", rv)) end
    return session
end

function t.mt:_close_session(session)
    if session then
        local rv = self.p11_lib:close_session(session)
        return rv
    else
        return CKR.FUNCTION_FAILED
    end
end


function t.mt:initialize(cfg)
    local rv, slotlist, info
    -- associazione reader name - slotID
    local reader_len = string.len(self.reader_name)
    
    log.output("token-p11wrap:initialize(): current reader name:", repr(self.reader_name))
    
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    
    local pcRes, theErrorT = pcall(function()
        rv, slotlist = self.p11_lib:get_slot_list(false)
        log.output("token-p11wrap:initialize(): slotlist:", rv, repr(slotlist))
        if rv == CKR.OK then
            for i, v in slotlist do
                rv, info = self.p11_lib:get_slot_info(v)
                log.output(string.format("token-p11wrap:initialize(): current slot: %d '%s'", v, tostring(info.slotDescription)))
                local desc = string.sub(info.slotDescription, 1, reader_len)
                log.output("token-p11wrap:initialize(): looking for", desc)
                local trimmedReader = string.sub(self.reader_name, 1, string.len(desc))
                if desc == trimmedReader then
                    log.output(string.format("token-p11wrap:initialize(): reader name '%s' (trimmed to: '%s') binded to PKCS11 SlotID: %d", self.reader_name, trimmedReader, v) )
                    self.P11SlotID = v
                    break
                end
            end
        end
        if not self.P11SlotID then
            self.P11SlotID = self.slotID + (self.slotBase or 1)
            log.output(string.format("token-p11wrap: internal slotID %d binded to PKCS11 SlotID %d", self.slotID, self.P11SlotID) )
        end
        -- sessione primaria RO: usata per stabilire la validit