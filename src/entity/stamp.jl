struct Stamp
    evbase::Vector{UInt}
    creatime::UInt
end

Base.length(s::Stamp) = length(s.evbase)

function Base.:(==)(s1::Stamp, s2::Stamp)
    length(s1.evbase) == length(s2.evbase) && length(setdiff(s1.evbase, s2.evbase)) == 0
end

function unionstamp(s1::Stamp, s2::Stamp, time; base_len = 8)
    # @debug "Union Stamp: " s1.evbase, s2.evbase
    len1 = length(s1.evbase)
    len2 = length(s2.evbase)
    newlen = min(len1 + len2, base_len)
    new_evbase = zeros(HashValue, newlen)
    zev = zip(s1.evbase, s2.evbase)
    @inbounds new_evbase[1:2length(zev)] = collect(Iterators.flatten(zev))
    if 2length(zev) < newlen
        if len1 < len2
            @inbounds new_evbase[2len1 + 1 : end] = s2.evbase[len1 + 1 : newlen - 2len1]
        else
            @inbounds new_evbase[2len2 + 1 : end] = s1.evbase[len2 + 1 : newlen - 2len2]
        end
    end
    # @debug "New Evbase: " new_evbase
    return Stamp(new_evbase, time)
end


function overlapped(stamp1::Stamp, stamp2::Stamp)
    for snum in stamp1.evbase
        snum in stamp2.evbase && return true
    end
    false
end
