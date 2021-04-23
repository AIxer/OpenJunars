abstract type Racer end

#=
    如果你想定义一个可以放入Narsche里调度的Racer,
    必须要满足这么一个约定: 

    实现：
    token(::Racer) 返回 Token
=#

token(r::Racer) = r.token

target(r::Racer) = token(r).target
bgt(r::Racer) = token(r).bgt

priority(racer::Racer) = bgt(racer).priority
durability(racer::Racer) = bgt(racer).durability
quality(racer::Racer) = bgt(racer).durability

dec_priority!(racer::Racer, v) = bgt(racer).priority = and(priority(racer), v)
inc_priority!(racer::Racer, v) = bgt(racer).priority = or(priority(racer), v)
dec_durability!(racer::Racer, v) = bgt(racer).durability = and(durability(racer), v)
inc_durability!(racer::Racer, v) = bgt(racer).durability = or(durability(racer), v)
dec_quality!(racer::Racer, v) = bgt(racer).quality = and(quality(racer), v)
inc_quality!(racer::Racer, v) = bgt(racer).quality = or(quality(racer), v)

function merge!(r1::Racer, r2::Racer)
    merge!(bgt(r1), bgt(r2))
    nothing
end

above_threshold(racer::Racer) = above_threshold(bgt(racer))

# trait
function forget! end
