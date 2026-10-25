 effettuata
function s.mt:initialize(slot_mgr, pre_ctx, pre_hcard, cfg)
    local err, pre_reader
    if pre_ctx then
        log.output('--LUA: slot-pcsc:initialize(): using pre established context...', tostring(pre_ctx))
        self.ctx = pre_ctx
        self.pre_ctx = true
        if pre_hcard then
            log.output('--LUA: slot-pcsc:initialize(): using pre connected handle...', tostring(pre_hcard))
            local status, err = pre_hcard:status()
            pre_reader = status.reader
            log.output('--LUA: slot-pcsc:initialize(): handle connected to', pre_reader)
        end
    else
        self.ctx, err = pcsc.establishcontext()
        if not self.ctx then
            log.output('--LUA: slot-pcsc: establishcontext() error:',
                       hex.tohex8(err))
            return CKR.OK
        end
    end
    local readers = self.ctx:listreaders()
    if readers then
        log.output('--LUA: slot-pcsc: no readers...')
        for i, reader_name in readers do
            local slot = self:new(reader_name)
            table.insert(self.slots, slot)
            local slotID = slot_mgr.slots_insert(slot)
            slot.slotID = slotID
            if pre_hcard and reader_name == pre_reader then
                slot.token = { initialized=false, hcard=pre_hcard, slotID=slotID, reader_name=reader_name }
                setmetatable(slot.token, s.dummytoken_mt)
            end
            if not pre_ctx then
                log.output('--LUA: slot-pcsc: acquiring slot specific context...')
                slot.pcsc_ctx, err = pcsc.establishcontext()
                log.output('--LUA: slot-pcsc: slot specific context:', slot.pcsc_ctx, err)
            end
        end
    end
    local virtualSlots = cfg and tonumber(cfg["virtualslots"]) or 0
    local used_readers ={}
    for i=0,virtualSlots-1 do
        local slot = self:new_virtual(readers or {}, used_readers, tostring(i), cfg["virtualslotsname"] or "token")
        table.insert(self.slots, slot)
        local slotID = slot_mgr.slots_insert(slot)
        slot.slotID = slotID
    end


    -- following setting is intended to be used on mobile applications, iOS & ANDROID
    -- avoid using on Windows/Mac/Linux where .conf file is easily accessible
    if cfg and type(cfg["tokens"]) == "string" and string.len(cfg["tokens"]) > 0 and tokens_table.compiled_tokens then
        log.output('--LUA: slot-pcsc: conf: checking tokens(1):', cfg["tokens"])
        local tokensArray = util.split(cfg["tokens"], ";", true)
        local tokens = {}
        for i=1,table.getn(tokensArray) do
            tokens[tokensArray[i]] = true
        end
        log.output('--LUA: slot-pcsc: conf: tokens(2):', util.repr(tokensArray))
        log.output('--LUA: slot-pcsc: conf: tokens(3):', util.repr(tokens))
        if table.getn(tokensArray) > 0 then
            local disabled_tokens = {}
            local compiled_tokens = {}
            local enabled_tokens = {}
            tokens_table.active_tokens = {}
            tokens_table.active_tokens_mask = bin.flags(0)
            
            for id, token in tokens_table.compiled_tokens do
                table.insert(compiled_tokens, token.name)
                if tokens[token.name] then
                    log.output('--LUA: slot-pcsc: conf: enabling token:', token.name, id)
                    table.insert(enabled_tokens, token.name)
                    tokens_table.active_tokens_mask = tokens_table.active_tokens_mask + bin.flags(id)
                    tokens_table.active_tokens[id] = token
                else
                    table.insert(disabled_tokens, token.name)
                end
                s.token_types = tokens_table.active_tokens
                s._active_tokens_mask = tokens_table.active_tokens_mask
                s.p11wrap_util = tokens_table.active_tokens[token_class_p11wrap] and tokens_table.active_tokens[token_class_p11wrap].p11wrap_util
            end
            log.output('--LUA: slot-pcsc: conf: compiled tokens:', table.concat(compiled_tokens, ", "))
            log.output('--LUA: slot-pcsc: conf: disabled tokens:', table.concat(disabled_tokens, ", "))
            log.output('--LUA: slot-pcsc: conf: enabled tokens:', table.concat(enabled_tokens, ", "))
        end
    end
    
    if _etokens then
        log.output('ovverriding default active tokens with:', _etokens, "; was:", s._active_tokens_mask)
        s._active_tokens_mask = bin.flags(tonumber(_etokens, 16) )
    end
    
    log.output('active tokens:', s._active_tokens_mask)
    
    self.mobile = cfg and cfg["mobile"] == "true"
    
    if self.mobile then
        log.output('initial slots refresh disabled on mobile')
    else
        log.output('initial slots refresh...')
        local pcRes, theErrorT = pcall(function()
            s:refresh_slots()
        end)
        if not pcRes then
            log.output('initial slots refresh error:', theErrorT)
        end
    end
    return CKR.OK
end

function s.mt:set_ctx(ctx)
    self.ctx = ctx
end

local SCARD_E_NO_SERVICE = -((bin.flags("0x8010001d") ^ bin.flags("0xFFFFFFFF")).asnumber +1)
local SCARD_E_SERVICE_STOPPED = -((bin.flags("0x8010001e") ^ bin.flags("0xFFFFFFFF")).asnumber +1) --tonumber("8010001e", 16)
local SCARD_E_NO_READERS_AVAILABLE = -((bin.flags("0x8010002e") ^ bin.flags("0xFFFFFFFF")).asnumber +1) -- tonumber("8010002e", 16)
local SCARD_E_READER_UNAVAILABLE = -((bin.flags("0x80100017") ^ bin.flags("0xFFFFFFFF")).asnumber +1) -- tonumber("80100017", 16)

function s.mt:refresh_slots()
    local readers, rv
    local slotID
    if not self.ctx then
        self.ctx = pcsc.establishcontext()
        log.output('refresh_slots(): general ctx established:', self.ctx)
    end
    if self.ctx then
        readers, rv = self.ctx:listreaders()
        if not readers then
            log.output('refresh_slots(): general ctx list readers error:', rv)
            local ctx, err = pcsc.establishcontext()
            if ctx then
                if self.ctx then
                    self.ctx:release()
                end
                self.ctx = ctx
                readers, rv = self.ctx:listreaders()
                log.output('refresh_slots(): NEW general ctx:', self.ctx)
            end
        end
    end
    
    readers = readers or {}
    if util.repr(readers) ~= util.repr(self.readers) then
    
        log.output('refresh_slots(): readers changed: ', util.repr(self.readers), "->", util.repr(readers))
        local attached_readers = {}
        local detached_readers = {}
        local old_readers = {}
        local new_readers = {}
        local self_readers = self.readers or {}
        for i, r in self_readers do
            old_readers[r] = true
        end
        for i, r in readers do
            new_readers[r] = true
        end

        for i, r in readers do
            attached_readers[r] = not old_readers[r]
            attached_readers[r] = attached_readers[r] or nil
        end
        for i, r in self_readers do
            detached_readers[r] = not new_readers[r]
            detached_readers[r] = detached_readers[r] or nil
        end
        
        for i, v in self.slots do
            log.output('refresh_slots(): evaluating slot: ', v.reader_name)
            if v.virtual_name then
                local reader_name = v.reader_name
                v:_check_reader()
                if not slotID and 
                (detached_readers[reader_name]
                or attached_readers[reader_name]
                or attached_readers[v.reader_name]
                or (v.detached_reader_name and (detached_readers[v.detached_reader_name] or attached_readers[v.detached_reader_name]) )
                ) then
                    slotID = v.slotID
                    log.output('refresh_slots(): attach/detach event on slot: ', slotID)
                end
            end
            if v.virtual_name and v.reader_name == v.virtual_name then
                log.output('refresh_slots(): jumping virtual detached reader', v.reader_name)
            else
                if v.pcsc_ctx then
                    if not slotID and (detached_readers[v.reader_name] or attached_readers[v.reader_name]) then
                        slotID = v.slotID
                        log.output('refresh_slots(): attach/detach event on slot: ', slotID)
                    end
                    local state, rv = v.pcsc_ctx:get_state(v.reader_name)
                    if not state and rv ~= 0 then
                        log.output('refresh_slots(): get_state rv=', rv)
                        log.output('refresh_slots(): refresh context on reader: ', v.reader_name)
                        
                        v.pcsc_ctx=re_establish(v.pcsc_ctx)
                    end
                end
            end
        end
        
        slotID = slotID or 1000
        log.output('refresh_slots(): SETTING event on slot: ', slotID)

        self.readers = readers
    end
    
    return slotID
end

function s.mt:relist_slots(slot_mgr)
    if self.mobile then
        log.output('relist_slots(): disabled on mobile')
    end
    local readers, rv
    if not self.ctx then
        self.ctx = pcsc.establishcontext()
        log.output('relist_slots(): general ctx established:', self.ctx)
    end
    if self.ctx then
        readers, rv = self.ctx:listreaders()
        if not readers then
            log.output('relist_slots(): general ctx list readers error:', rv)
            local ctx, err = pcsc.establishcontext()
            if ctx then
                if self.ctx then
                    self.ctx:release()
                end
                self.ctx = ctx
                readers, rv = self.ctx:listreaders()
                log.output('relist_slots(): NEW general ctx:', self.ctx)
            end
        end
    end
    
    readers = readers or {}
    if util.repr(readers) ~= util.repr(self.readers) then
    
        log.output('relist_slots(): readers changed: ', util.repr(self.readers), "->", util.repr(readers))
        local attached_readers = {}
        local detached_readers = {}
        local old_readers = {}
        local new_readers = {}
        local self_readers = self.readers or {}
        for i, r in self_readers do
            old_readers[r] = true
        end
        for i, r in readers do
            new_readers[r] = true
        end

        for i, r in readers do
            attached_readers[r] = not old_readers[r]
            attached_readers[r] = attached_readers[r] or nil
        end
        for i, r in self_readers do
            detached_readers[r] = not new_readers[r]
            detached_readers[r] = detached_readers[r] or nil
        end
        
        local new_slots = {}
        local virtual_slots = {}
        log.output('relist_slots(): checking virtual slots...')
        for i, v in self.slots do
            if v.virtual_name then
                log.output('relist_slots(): checking virtual slot: ', v.virtual_name)
                v:_check_reader()
                
                if detached_readers[v.reader_name] then
                    log.output('relist_slots(): detached slot handled by virtual driver:', v.reader_name)
                    detached_readers[v.reader_name] = nil
                end
                if attached_readers[v.reader_name] then
                    log.output('relist_slots(): attached slot handled by virtual driver:', v.reader_name)
                    attached_readers[v.reader_name] = nil
                end
            end
            
        end
        
        log.output('relist_slots(): checking other slots...')
        for i, v in self.slots do
        
            if not v.virtual_name then
                log.output('relist_slots(): evaluating slot:', v.reader_name)
                if detached_readers[v.reader_name] then
                    log.output('relist_slots(): delisting detached reader:', v.reader_name)
                    slot_mgr.slots_remove(v.slotID)
                elseif attached_readers[v.reader_name] then
                    log.output('relist_slots(): WARNING: attached reader already in the slot list, ignoring:', v.reader_name)
                    attached_readers[v.reader_name] = nil
                else
                    log.output('relist_slots(): re-adding existing reader:', v.reader_name)
                    table.insert(new_slots, v)
                end
            else
                log.output('relist_slots(): pushing back existing virtual slot:', v.virtual_name)
                slot_mgr.slots_remove(v.slotID)
                table.insert(virtual_slots, v)
            end
        end
        

        for reader_name, value in attached_readers do
            if value then
                log.output('relist_slots(): adding new reader:', reader_name)
                local slot = self:new(reader_name)
                table.insert(new_slots, slot)
                local slotID = slot_mgr.slots_insert(slot)
                slot.slotID = slotID
            end
        end
        
        for i, v in virtual_slots do
            log.output('relist_slots(): re-adding virtual slot with updated readers:', v.virtual_name)
            table.insert(new_slots, v)
            local slotID = slot_mgr.slots_insert(v)
            v.slotID = slotID
            v.readers = readers
        end
        
        log.output('relist_slots(): updating internal slots...')
        self.slots = new_slots
        log.output('relist_slots(): updating internal readers...')
        self.readers = readers
    end
    
end

function s.mt:finalize()
    log.output('pcsc-slot:finalize() entry')
    local hcards = {}
    local hcards2 = {}
    for i, slot in self.slots do
        if slot.token then
            if slot.token.hcard:disconnectdisabled() then
                -- l'handle non pu