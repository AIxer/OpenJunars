"""
检查两个词项是否可以组成一个有效的句子
"""
invalid(::Nothing) = true
invalid(st::Term) = false
invalid(st::Statement) = invalidstatement(st[1], st[2])
function invalidstatement(subj::Term, pred::Term)
    subj == pred && return true
    invalidreflexive(subj, pred) && return true
    invalidreflexive(pred, subj) && return true
    return false
end

function invalidstatement(subj::Statement, pred::Statement)
    subj == pred && return true
    invalidreflexive(subj, pred) && return true
    invalidreflexive(pred, subj) && return true
    @inbounds t11, t12 = subj[1], subj[2]
    @inbounds t21, t22 = pred[1], pred[2]
    t11 == t22 && t12 == t21 && return true
    return false
end

function invalidreflexive(subj::AbstractCompound, pred::Term)
    # BUG containall 不完全准确 (&&, a-->c, a-->b) a-->#1
    containall(subj, pred)
end
invalidreflexive(subj::Image, pred::Term) = false
invalidreflexive(subj::Term, pred::Term) = false

invalidpair(t1::Term, t2::Term) = hasivar(t1) ⊻ hasivar(t2)