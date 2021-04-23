using DataStructures

import Base: put!, take!, union!

"""
```
Narsche: NARS 存储结构
    take!(::Narsche{T})
    put!(::Narsche{T}, ::T)
    peek(::Narsche{T}, ::HashValue)
    out_track!(::Narsche{T}, ::HashValue)
    into_track!(::Narsche{T}, ::T)
```

"""
mutable struct Narsche{T <: Racer}
    total_level::Int
    thresh_level::Int
    current_level::Int
    current_count::Int
    next_level::Int
    capacity::Int
    mass::Int
    dtr::Distributor
    racers::Dict{HashValue, T}
    track::Vector{MutableLinkedList{T}}
end

Base.count(ns::Narsche) = ns.racers.count

function Narsche{T}(total::Int, thresh::Int, cap::Int) where T <: Racer
    Narsche(
        total,              # total_level
        thresh,             # thresh_level
        total,              # current_level  从最高等级开始
        0,                  # current_count
        cap % total + 1,    # next_level
        cap,                # capacity
        0,                  # mass
        Distributor(total), # dtr
        Dict{HashValue, T}(),                      # racers
        [MutableLinkedList{T}() for _ in 1:total]  # track
    )
end

function put!(ns::Narsche{T}, racers::T...) where T
    for racer in racers
        put!(ns, racer)
    end
end

function put!(ns::Narsche{T}, racer::T) where T
    token = racer.token

    # 有没有?
    old_racer = out_track!(ns, target(racer))
    if old_racer !== nothing
        merge!(old_racer, racer)
        into_track!(ns, old_racer)
        return nothing
    end

    in_level = p2l(priority(racer), ns.total_level)
    # in_level < ns.thresh_level && return 

    # 满没满？
    if length(ns.racers) >= ns.capacity
        # 去掉一个
        # 找到非空level pq
        out_level = 1
        for i in 1:ns.total_level
            if length(ns.track[i]) != 0
                out_level = i
                break
            end
        end
    
        # 忽略
        # 没装进去就把它吐出来！
        # 我也没明白...
        out_level > in_level && return nothing # racer?
            
        # 从 track 中删除最后一个?
        overf_racer = pop!(ns.track[out_level])
        # 从 racers 中删除
        Base.delete!(ns.racers, target(overf_racer))
        ns.mass -= out_level
    end

    # 有空位, 加进去
    ns.racers[token.target] = racer
    push!(ns.track[in_level], racer)
    ns.mass += in_level
    nothing
end

# racers 和 track 都删
function take!(ns::Narsche{T})::Union{Nothing, T} where T

    length(ns.racers) == 0 && return 

    # 找到非空level
    if is_empty_level(ns, ns.current_level) || ns.current_count == 0
        # 先换条道(这步是必须的)
        ns.current_level = pick(ns.dtr, ns.next_level)
        ns.next_level = next(ns.dtr, ns.next_level)

        while is_empty_level(ns, ns.current_level)
            ns.current_level = pick(ns.dtr, ns.next_level)
            ns.next_level = next(ns.dtr, ns.next_level)
        end

        if ns.current_level < ns.thresh_level
            ns.current_count = 1    # 非活跃等级只取1个
        else
            ns.current_count = length(ns.track[ns.current_level])
        end

    end

    # 取出第一个
    racer = popfirst!(ns.track[ns.current_level])

    # 检查bgt是否和当前等级匹配
    # 如果其它操作如 activate! 等没有out_track!，那么就需要检查
    belonging_level = p2l(priority(racer), ns.total_level)
    if belonging_level != ns.current_level
        push!(ns.track[belonging_level], racer)
        return take!(ns)
    end

    ns.current_count -= 1

    # 删除记录
    delete!(ns.racers, target(racer))

    # 更新mass
    ns.mass -= ns.current_level

    return racer
end

function Base.take!(ns::Narsche, term::Term)
    hs = hash(term)
    racer = peek(ns, hs)
    isnothing(racer) && return
    out_track!(ns, hs)
    delete!(ns.racers, hs)
    return racer
end

Base.peek(ns::Narsche, term::Term) = peek(ns, hash(term))
Base.peek(ns::Narsche, key::HashValue) = get(ns.racers, key, nothing)


function out_track!(ns::Narsche{T}, racer::T) where T
    out_track!(ns, target(racer))
end

# 从track中取出
function out_track!(ns::Narsche, hs::HashValue)
    racer = peek(ns, hs)
    if racer !== nothing
        level = p2l(priority(racer), ns.total_level)
        ll_delete!(ns.track[level], hs)
        ns.mass -= level
    end
    racer
end

function into_track!(ns::Narsche{T}, racer::T) where T <: Racer
    level = p2l(priority(racer), ns.total_level)
    append!(ns.track[level], racer)
    ns.mass += level
    nothing
end

function Base.merge!(ns1::Narsche{T}, ns2::Narsche{T}) where T <: Racer
    for racer in values(ns2.racers)
        put!(ns1, racer)
    end
end

function is_empty_level(ns::Narsche, level::Int)
    length(ns.track[level]) == 0
end

function ll_delete!(ll::MutableLinkedList{T}, hs::HashValue) where T <: Racer
    for (idx, racer) in enumerate(ll)
        if target(racer) == hs 
            delete!(ll, idx)
            return nothing
        end
    end
    nothing
end

# priority to bag level
p2l(priority::Float64, total_level::Int) = ceil(Int, priority * total_level)

# average priority
function ave_priority(ns::Narsche)
    num = length(ns.racers)
    num == 0 && return 0.01
    f = ns.mass / (num * ns.total_level)
    f > 1 && return 1.0
    return f
end
