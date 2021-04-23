struct Distributor
    order::Array{Int}
    capacity::Int
end

function Distributor(rng::Int)
    capacity = div(rng * (rng + 1), 2)
    order = fill(-1, capacity)
    idx = capacity
    for rank in rng:-1:1
        for time in 1:rank
            idx = (div(capacity, rank) + idx) % capacity + 1
            while order[idx] >= 0
                idx = idx % capacity + 1
            end
            order[idx] = rank
        end
    end
    Distributor(order, capacity)
end

pick(dtr::Distributor, idx::Int) = dtr.order[idx]

next(dtr::Distributor, idx::Int) = idx % dtr.capacity + 1

# [2, 2, 3, 3, 1, 3]
# @show Distributor(3)
