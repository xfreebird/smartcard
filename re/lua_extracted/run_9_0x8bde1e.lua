 facilmente accessibile
            for i, v in self.readers do
                readers_map[v] = true
            end
            log.output('--LUA: virtual slot:_check_reader(): readers_map:', util.repr(readers_map))
            log.output('--LUA: virtual slot:_check_reader(): used_readers:', util.repr(self.used_readers))
            for i, v in readers do
                log.output('--LUA: virtual slot:_check_reader(): checking phisical reader:', v)
                if not readers_map[v] and not self.used_readers[v] then
                    self.initialized = true
                    self.reader_name = v
                    self.detached_reader_name = nil
                    self.used_readers[v] = true
                    self:event_occurred()
                    log.output('--LUA: virtual slot:_check_reader(): attached to reader:', v)
                    break
                end
            end
        else
            local found
            for i, v in readers do
                if self.reader_name == v then
                    found = true
                end
            end
            if not found then
                log.output('--LUA: virtual slot:_check_reader(): detached from reader:', self.reader_name)
                self.initialized = false
                self.used_readers[self.reader_name] = nil
                self.detached_reader_name = self.reader_name
                self.reader_name = self.virtual_name
            end
        end
    end
end

function s.virtual_slot_mt:_get_token()
    self:_check_reader()
    if self.initialized then
        return s.slot_mt._get_token(self)
    end
    return nil
end

function s.virtual_slot_mt:get_info()
    self:_check_reader()
    if self.initialized then
        return s.slot_mt.get_info(self)
    end
    local info = {
        slotDescription = string.sub(self.reader_name, 1, 64),
        manufacturerID  = 'unknown',
        flags           = CKF.REMOVABLE_DEVICE+CKF.HW_SLOT,
        hardwareVersion = { major=0, minor=0 },
        firmwareVersion = { major=0, minor=0 }
    }
    return info
end

function s.virtual_slot_mt:get_token_info()
    self:_check_reader()
    if self.initialized then
        return s.slot_mt.get_token_info(self)
    end
    return CKR.TOKEN_NOT_PRESENT, nil
end

local fSCARD_STATE_PRESENT = bin.flags(pcsc.SCARD_STATE_PRESENT)

function s.virtual_slot_mt:event_occurred()
    self:_check_reader()
    if self.initialized then
        return s.slot_mt.event_occurred(self)
    end
    return false
end

-----------------------------------------------------------------------------
-- slot-pcsc
-----------------------------------------------------------------------------
function s.hcard_valid(hcard)
    local status, err = hcard:status()
    if not status then
        log.output('--LUA: hcard_valid(): status() error', hex.tohex8(err or 0))
        return false
    elseif status.protocol == 0 or string.len(status.atr or '') == 0 then
        log.output('--LUA: hcard_valid(): card removed? status=', util.repr(status))
        return false
    end
    return true
end

function s.slot_mt:_get_token()
    local status, err, new_hcard
    -- distruggi un eventuale token non pi