 valido
    if self.token then
        if not s.hcard_valid(self.token.hcard) then
            log.output('--LUA: detectd invalid token...')
            local pcRes, theErrorT = pcall( function()
                if self.token.initialized and self.token.finalize then
                    log.output('--LUA: slot-pcsc:_get_token() finalizing token...')
                    self.token:finalize()
                end
            end)
            if not pcRes then
                log.output('--LUA: slot-pcsc:_get_token(): token finalize error: ', theErrorT)
            end
            
            log.output('--LUA: slot-pcsc:_get_token() closing scard handle...')
            pcall(function() 
                self.token.hcard:disconnect(pcsc.SCARD_LEAVE_CARD)
            end)
            self.token = nil
                
        end
    end
    if not self.token then
        local ctx = self.pcsc_ctx or s.ctx
        local atr, lRes = ctx:getatr(self.reader_name, true)
        if not atr and not s.pre_ctx then
            log.output('--LUA: slot-pcsc:_get_token() get ATR error:', lRes)
            if lRes == SCARD_E_SERVICE_STOPPED or lRes == SCARD_E_NO_SERVICE then
                log.output('--LUA: slot-pcsc:_get_token() try re-establish slot context...')
                ctx, err = pcsc.establishcontext()
                if ctx then
                    self.pcsc_ctx = ctx
                    atr = ctx:getatr(self.reader_name, true)
                end
                
                log.output('--LUA: slot-pcsc:_get_token() try re-establish global context...')
                ctx, err = pcsc.establishcontext()
                if ctx then
                    s.ctx = ctx
                    log.output('--LUA: slot-pcsc:_get_token() general ctx established:', self.ctx)
                end
            end
        end
        if atr then
            log.output('--LUA: slot-pcsc:_get_token() (re)connecting...')
            -- prova a connettersi con i parametri di default
            new_hcard, err = ctx:connect(self.reader_name)  
            if not new_hcard and err ~= 0 then
                -- prova a connettersi con protocollo T=0 or T=1
                new_hcard, err = ctx:connect(self.reader_name, nil, pcsc.PROTOCOL_Tx)
            end
            if not new_hcard then
                log.output('--LUA: slot-pcsc:_get_token() connect() error: ',
                           hex.tohex8(err))
            elseif not s.hcard_valid(new_hcard) then
                log.output('--LUA: slot-pcsc:_get_token() connect() error: invalid handle?')
                pcall(function() new_hcard:disconnect(pcsc.SCARD_LEAVE_CARD) end)
            else
                self.token = { initialized=false, hcard = new_hcard, slotID=self.slotID, reader_name=self.reader_name }
                setmetatable(self.token, s.dummytoken_mt)
            end
        else
            log.output('--LUA: slot-pcsc:_get_token() no smartcard in reader', self.reader_name)
        end
    end
    return self.token
end

function s.slot_mt:get_info()
    local info = {
        slotDescription = string.sub(self.reader_name, 1, 64),
        manufacturerID  = 'unknown',
        flags           = CKF.REMOVABLE_DEVICE+CKF.HW_SLOT,
        hardwareVersion = { major=0, minor=0 },
        firmwareVersion = { major=0, minor=0 }
    }
    if self:_get_token() then
        info.flags = info.flags + CKF.TOKEN_PRESENT
    end
    return info
end

function s.slot_mt:get_token_info()
    local token = self:_get_token()
    if token then
        local pcRes1, theError1, info = pcall(function()
            token:begin_transaction()
            local pcResT, theErrorT = pcall(
                function()
                    local token_info = token:get_info()
                    return token_info
                end)
            token:end_transaction()
            if not pcResT then
                log.output('--LUA: s.slot_mt:get_token_info(): failed with error:', theErrorT)
                return CKR.TOKEN_NOT_RECOGNIZED, nil
            end
            if not theErrorT then
                log.output('--LUA: s.slot_mt:get_token_info(): token:get_info() returnend nil')
                return CKR.TOKEN_NOT_RECOGNIZED, nil 
            end
            return CKR.OK, theErrorT
        end)
        if not pcRes1 then
            log.output("--LUA: s.slot_mt:get_token_info(): error:", theError1)
            return CKR.TOKEN_NOT_RECOGNIZED, nil
        else
            return theError1, info
        end
    else
        return CKR.TOKEN_NOT_PRESENT, nil
    end
end

local fSCARD_STATE_PRESENT = bin.flags(pcsc.SCARD_STATE_PRESENT)

function s.slot_mt:event_occurred()
    local ctx = self.pcsc_ctx or s.ctx
    if not self.fold_state then
        local old_state = ctx:get_state(self.reader_name)
        if not old_state then
            return false
        end
        self.fold_state = bin.flags(old_state)
        log.output("--LUA: s.slot_mt:event_occurred(): initial state: ", self.fold_state)
    end
    local newState = ctx:get_state(self.reader_name)
    if not newState then
        return false
    end
    local fnewState = bin.flags(newState)
    local eventOccurred = (fnewState[fSCARD_STATE_PRESENT] and not self.fold_state[fSCARD_STATE_PRESENT])
                        or (not fnewState[fSCARD_STATE_PRESENT] and self.fold_state[fSCARD_STATE_PRESENT])
    self.fold_state = fnewState
    return eventOccurred
end

------------------------------------------------------------------------------
-- funzioni per il detect del filesystem

-- *** tutti questi filesystem sono noti e non vanno rimossi:
-- un FS noto non deve essere gestito se il token corrispondente non 