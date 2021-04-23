using Base.Order
mutable struct Table{T, O <: Ordering}
    o::O
    cap::Int
    count::Int
    items::Vector{T}
end

Table{T}(n::Int, o::Ordering=Forward) where T = Table{T, typeof(o)}(o, n, 0, Vector{T}(undef, n))
Table{T}(o::Ordering=Forward) where T = Table{T}(NaParam.TABLE_MAX_LENGTH, o)

function Table{T}(e::T, o::Ordering=Forward) where T
    table = Table{T}(NaParam.TABLE_MAX_LENGTH, o)
    add!(table, e)
end

Base.eltype(::Table{T, O}) where {T, O } = T
Base.setindex!(t::Table{T}, v::T, i) where T = t.items[i] = v # TODO should deprecate this?
Base.iterate(t::Table, state=1) = state > t.count ? nothing : @inbounds (t.items[state], state+1)
Base.length(t::Table) = t.count
Base.isempty(t::Table) = t.count == 0
Base.first(t::Table) = length(t) < 1 ? nothing : @inbounds t.items[1]
Base.maximum(f::Function, t::Table) = maximum(f, t.items)

function add!(t::Table{T}, item::T) where T
    pos = length(t) + 1
    for i in 1:length(t)
        if lt(t.o, rank(t.items[i]), rank(item))
            t.items[i] == item && return
            pos = i
            break
        end
    end
    insert!(t, pos, item)
end

function Base.insert!(t::Table{T}, idx::Int, v::T) where T
    if idx >= t.cap
        @inbounds t.items[t.cap] = v
        return t
    end

    last = ifelse(t.count == t.cap, t.count - 1, t.count)
    for j in last:-1:idx
        @inbounds t.items[j+1] = t.items[j]
    end
    @inbounds t.items[idx] = v
    t.count == t.cap && return t
    t.count += 1
    return t
end

function Base.delete!(table::Table, idx::Int)
    @boundscheck 1 <= idx <= table.count || throw(BoundsError(table, idx))
    if idx == table.count
        table.count -= 1
        return table
    end
    for i in idx+1:table.count
        @inbounds table.items[i-1] = table.items[i]
    end
    table.count -= 1
    return table
end

function Base.append!(t::Table{T}, v::T) where T
    if t.count == t.cap
        t.items[t.cap] = v
        return t
    end
    t.items[t.count + 1] = v
    t.count += 1
    return t
end
