mutable struct Budget
    priority::Float64
    durability::Float64
    quality::Float64
end

Budget() = Budget(0.01, 0.01, 0.01)
Budget(p::Float64, d::Float64, truth::Truth) = Budget(p, d, t2q(truth))

Base.string(bgt::Budget) = "\$$(round(bgt.priority, digits=3));" *
                "$(round(bgt.durability, digits=3));" *
                "$(round(bgt.quality, digits=3))\$"
                
"""
Summary 用于判断是否要进行报告
"""
Base.summary(bgt::Budget) = ave_geo(bgt.priority, bgt.durability, bgt.quality)

# 合并两个Budget结果到第一个参数 b1
function Base.merge(b1::Budget, b2::Budget)
    Budget(
        max(b1.priority, b2.priority),
        max(b1.durability, b2.durability),
        max(b1.quality, b2.quality)
    )
end

function Base.round(bgt::Budget; digits=2)
    Budget(
        round(bgt.priority, digits=digits),
        round(bgt.durability, digits=digits),
        round(bgt.quality, digits=digits)
    )
end

function Base.merge!(b1::Budget, b2::Budget)
    b1.priority = max(b1.priority, b2.priority)
    b1.durability = max(b1.durability, b2.durability)
    b1.quality = max(b1.quality, b2.quality)
end

function Base.:(==)(b1::Budget, b2::Budget)
    b1.priority == b2.priority &&
    b1.durability == b2.durability &&
    b1.quality == b2.quality
end

# 辅助函数: 算术平均值
ave_ari(arr::Float64...) = sum(arr) / length(arr)


# 几何平均值
function ave_geo(arr::Float64...)
    product = reduce(*, arr)
    return length(arr) == 2 ? sqrt(arr[1] * arr[2]) : product ^ (1.0 / length(arr))
end

above_threshold(bgt::Budget) = summary(bgt) >= NaParam.BUDGET_THRESHOLD 
