 oggetti ritorna 0
function t.mt:get_item(search_state, showprivate, template)

    if search_state.objects and search_state.last_object then
        search_state.last_object = search_state.last_object +1
        local hObj = search_state.objects[search_state.last_object]
        return self:_wrap_handle(hObj) or 0 -- if no objects left returns 0
    end
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    
    local pcRes, theErrorT = pcall(function()
    
        local session = self:_new_session(CKF.SERIAL_SESSION)
        local rv, objects = self.p11_lib:find_objects(session, template)
        self:_close_session(session)
        if rv ~= CKR.OK then
            return 0
        end
        search_state.objects = objects
        search_state.last_object = 1 -- first object always returned
        return self:_wrap_handle(objects[1]) or 0 -- if no objects are present returns 0
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT
    end
    
end

function t.mt:get_attribute_value(hObjExt, attr, onlysize)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    local hObj = self:_unwrap_handle(hObjExt)
    
    local pcRes, theErrorT, result = pcall(function()
        local rv, result = self.p11_lib:get_attribute_value(self.session, hObj, attr, onlysize)
        --log.output("token-p11wrap:get_attribute_value():", rv, hex.hexify(result));
        if rv == CKR.FUNCTION_FAILED then
            log.output("token-p11wrap:get_attribute_value(): Patched PKCS#11 error: FUNCTION_FAILED->ATTRIBUTE_TYPE_INVALID");
            return CKR.ATTRIBUTE_TYPE_INVALID
        end
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

function t.mt:generate_key_pair(pMechanism, templatePub, templatePriv)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    local hPub, hPriv = 0, 0
    
    local pcRes, theErrorT, hPub, hPriv = pcall(function()
        local rwSession = self:_new_session(CKF.SERIAL_SESSION, true)
        local rv, hPub, hPriv = self.p11_lib:generate_key_pair(rwSession, pMechanism, templatePub, templatePriv)
        self:_close_session(rwSession)
        return rv, hPub, hPriv
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT, self:_wrap_handle(hPub), self:_wrap_handle(hPriv)
    end
end

function t.mt:create_object(pTemplate)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    local hObject = 0
    
    local pcRes, theErrorT, hObject = pcall(function()
        local rwSession = self:_new_session(CKF.SERIAL_SESSION, true)
        local rv, hObject = self.p11_lib:create_object(rwSession, pTemplate)
        self:_close_session(rwSession)
        return rv, hObject
    end)
    if wasDisabled then self.hcard:begintransaction() end
    self.hcard:disabletransactions(wasDisabled)  
    if not pcRes then
        error(theErrorT)
    else
        return theErrorT, self:_wrap_handle(hObject)
    end
end

function t.mt:destroy_object(hObjectExt)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    local hObject = self:_unwrap_handle(hObjectExt)
    
    local pcRes, theErrorT = pcall(function()
        local rwSession = self:_new_session(CKF.SERIAL_SESSION, true)
        local rv = self.p11_lib:destroy_object(rwSession, hObject)
        local hObject = self:_remove_handle(hObject)
        self:_close_session(rwSession)
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

function t.mt:set_attribute_value(hObjectExt, pTemplate)
    local wasDisabled = self.hcard:disabletransactions(false)
    if wasDisabled then self.hcard:endtransaction() end
    local hObject = self:_unwrap_handle(hObjectExt)
    
    local pcRes, theErrorT = pcall(function()
        local rwSession = self:_new_session(CKF.SERIAL_SESSION, true)
        local rv = self.p11_lib:set_attribute_value(rwSession, hObject, pTemplate)
        self:_close_session(rwSession)
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

return t

--===========================================================================
end
}
_LOADED['slot-pcsc'] = { magic = '__TOBELOADED__', loadfn = function()
--===========================================================================
-- slot-pcsc.lua ------------------------------------------------------------

local hex = require 'hex'
local util = require 'utility'
local CnsSmartcard = require 'CnsSmartcard'
-- local token_p11wrap = require 'token-p11wrap'

-- il package tokens_table 