"""
记录已经推理过的 TermLink
"""
struct BLinkRecord
    bkey::HashValue
    ocur_time::UInt
end

Base.isless(b1::BLinkRecord, b2::BLinkRecord) = isless(b1.ocur_time, b2.ocur_time)
Gene.priority(e::BLinkRecord) = e.ocur_time

"""
TaskLink 不仅有自身的预算值,还链接着一个Task
"""
mutable struct TaskLink <: Racer
    token::Token
    task::NaTask
    ltype::LinkStyle
    pos::SVector
    bcords::Table{BLinkRecord}
end

TaskLink(token, task, ltype, pos) = TaskLink(token, task, ltype, pos, Table{BLinkRecord}(NaParam.TERMLINK_RECORD_LENGTH, Base.Order.Reverse))

function Base.append!(t::Table{BLinkRecord}, v::BLinkRecord)
    if t.count == t.cap
        t.items[argmin(t.items)] = v
        return t
    end
    t.items[t.count + 1] = v
    t.count += 1
    return t
end

Gene.forget!(tlink::TaskLink) = forget!(bgt(tlink), NaParam.TASKLINK_FORGET_CYCLES)