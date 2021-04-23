function cycle!(nac::NaCore)
    nar = now(nac)
    concept = take!(nar.mem)
    if concept !== nothing
        # 保持被选中的概念时刻在线
        putback!(nar.mem, concept)
        attach!(nar, concept)
        @debug "Attach Nar to Concept: $(name(concept))"
        spike!(nar)
        clear!(nar) # TODO 好像是多余的,因为下次生成新的Nar的时候默认值就是nothing
    end
    absorb!(nar)
    nac.cycles[] += 1
end

"""
选取tasklink和termlink进行推理
"""
function spike!(nar::Nar)
    cpt = nar.cpt
    nar.tasklink = take!(cpt.tasklinks)
    isnothing(nar.tasklink) && return
    nar.task = nar.tasklink.task
    nar.tasksentence = nar.task.sentence
    if nar.tasklink.ltype == TRANSFORM
        term = deepcopy(nar.task.sentence.term)
        #  <(*, term, #) --> #>
        #  <<(*, term, #) --> #> ==> #>
        #  <(&&, <(*, term, #) --> #>, #) ==> #>
        try
            transformrela(term, nar)
        catch e
            @show nar.cpt.term
            @show nar.tasksentence
            @show nar.beliefcpt
            rethrow(e)
        end
    else
        for i in 1:min(NaParam.MAX_REASONED_TERM_LINK, count(cpt.termlinks))
            pickblink!(nar) || break
            reason(nar)
            putback!(cpt.termlinks, nar.termlink)
            nar.termlink = nothing
        end
    end
    putback!(cpt.tasklinks, nar.tasklink) # TODO bit of wired
    nothing
end

function pickblink!(nar::Nar)
    for i in 1:NaParam.MAX_MATCHED_TERMLINK
        blink = take!(nar.cpt.termlinks)
        blink === nothing && return false
        if novel(nar, blink)
            nar.termlink = blink
            return true
        end
        putback!(nar.cpt.termlinks, blink)
    end
    return false
end

function novel(nar::Nar, blink::TermLink)
    # 相同词项不推理
    target(nar.tasklink) == target(blink) && return false
    bcords = nar.tasklink.bcords
    for (idx, record) in enumerate(bcords)
        if target(blink) == record.bkey
            if nar.time > record.ocur_time + NaParam.TERMLINK_MEMED_CYCLES
                # 已经过了一段时间了
                @inbounds bcords[idx] = BLinkRecord(record.bkey, nar.time)
                return true
            end
            return false
        end
    end
    append!(bcords, BLinkRecord(target(blink), nar.time))
    return true
end
