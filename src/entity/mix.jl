function putback!(ns::Narsche{T}, racer::T) where T
    forget!(racer)
    put!(ns, racer)
end

function Gene.forget!(bgt::Budget, fc::Int)
    quality = bgt.quality * NaParam.RELA_THRESHOLD  # re-scaled quality
    p = bgt.priority - quality     
    # priority above quality   
    if p > 0 
        quality += p * (bgt.durability^(1.0 / (fc * p)))
    end
    bgt.priority = quality
end
