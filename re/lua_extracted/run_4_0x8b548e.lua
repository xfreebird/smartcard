 del token e per recuperare gli attributi
        -- per tutti gli altri casi viene aperta una nuova sessione
        self.session = self:_new_session(CKF.SERIAL_SESSION)
        self.default_container_data_obj = "CSPSmartLogon"
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end
end


function t.mt:finalize()
    log.output("token-p11wrap:finalize():", self.session, self.userType)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    
    local pcRes, theErrorT = pcall(function()
        if self.session then
            if self.userType then
                self.p11_lib:logout(self.session)
            end
        end
        self:_close_session(self.session)
        self:_close_session(self.sess_gettattr)
        self.session = nil
        self.sess_gettattr=nil
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end

end

function t.mt:begin_transaction()
-- not needed
end

function t.mt:end_transaction()
-- not needed
end


function t.mt:get_info()
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    
    local pcRes, theErrorT = pcall(function()
        local rv, info = self.p11_lib:get_token_info(self.P11SlotID)
        if rv ~= CKR.OK then error(string.format("%x", rv)) end
        info.flags = info.flags + CKF.WRITE_PROTECTED
        return info
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end
end

function t.mt:get_mechanisms()
    -- todo: mechanisms
    return t.mechanisms
end

function t.mt:valid()
    local status, err = self.hcard:status()
    if not status then
        log.output('valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('valid(): card removed?')
        return false
    end

    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    
        local pcRes, theErrorT = pcall(function()
        local rv, sinfo = self.p11_lib:get_session_info(self.session)
        return rv == CKR.OK
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end        
end

function t.mt:verify_pin(pin, userType)
    log.output("token-p11wrap:verify_pin():", userType, pin)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    local rv
    local pcRes, theErrorT = pcall(function()
    
        if self.userType then
            self:unverify_pin()
        end
        rv = self.p11_lib:login(self.session, userType, pin)
        if rv == CKR.SESSION_READ_ONLY_EXISTS 
                or rv == CKR.SESSION_READ_WRITE_SO_EXISTS then
            self.p11_lib:close_all_sessions(self.P11SlotID)
            self.session = self:_new_session(CKF.SERIAL_SESSION, true)
            rv = self.p11_lib:login(self.session, userType, pin)
        end
        if rv == CKR.OK then
            self.cached_main_pin = pin
            self.userType = userType
        else
            log.output("token-p11wrap:verify_pin(): error: ", rv)
        end
        return rv
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end
end

function t.mt:unverify_pin()
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    
        local pcRes, theErrorT = pcall(function()
        self.cached_main_pin = nil
        self.userType = nil
        local rv = self.p11_lib:logout(self.session);
        return rv
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end

end


-- NOTA: lcuni PKCS#11 richiedono una sessione RW per cambiare o sbloccare il PIN
-- altri PKCS#11 permettono una sola sessione RW: di conseguenza la sessione RW va aperta e subito chiusa.
function t.mt:change_pin(oldPin, newPin)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    
    local pcRes, theErrorT = pcall(function()
        local session = self:_new_session(CKF.SERIAL_SESSION, true)  -- prova ad aprire una sessione RW, se non ci riesce la apre RO
        local rv = self.p11_lib:change_pin(session, oldPin, newPin)
        self:_close_session(session)
        return rv
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end
end


function t.mt:reset_pin(newPin)
    --if self.userType ~= CKU.SO then
    --    log.output('token-cns reset_pin(): user not SO!')
    --    return CKR.USER_NOT_LOGGED_IN
    --end
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    
    local pcRes, theErrorT = pcall(function()
        local session = self:_new_session(CKF.SERIAL_SESSION, true) -- prova ad aprire una sessione RW, se non ci riesce la apre RO
        local rv = self.p11_lib:reset_pin(session, newPin)
        self:_close_session(session)
        return rv
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end
end

--=====================================================================================

function t.mt:sign_buffer(hKeyExt, pMechanism, pData, allocated_space)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    local hKey = self:_unwrap_handle(hKeyExt)
    
    local pcRes, theErrorT, result = pcall(function()
        local session = self:_new_session(CKF.SERIAL_SESSION)
        local rv, result = self.p11_lib:sign_buffer(session, hKey, pMechanism, pData, allocated_space)
        self:_close_session(session)
        return rv, result
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT, result
    end
    
end

function t.mt:decrypt_buffer(hKeyExt, pMechanism, pData, allocated_space)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    local hKey = self:_unwrap_handle(hKeyExt)
    
    local pcRes, theErrorT, result = pcall(function()
    
        local session = self:_new_session(CKF.SERIAL_SESSION)
        local rv, result = self.p11_lib:decrypt_buffer(session, hKey, pMechanism, pData, allocated_space)
        self:_close_session(session)
        return rv, result
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT, result
    end
end


-- se search_state.lastobj==nil si richiede l'handle del primo oggetto che risponda
-- al template. Altrimenti restituisce il primo oggetto che sia
-- compatibile con il template e abbia handle>search_state.lastobj.
-- quando non ci sono pi