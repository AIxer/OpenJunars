do_what() = @error "Wait to be implemented!"

function reason(nar::Nar)
    tlink = nar.tasklink
    blink = nar.termlink
    nar.tasksentence = nar.task.sentence

    nar.beliefcpt = peek(nar, target(blink))
    nar.beliefcpt === nothing && return
    beliefcpt = nar.beliefcpt
    nar.belief = choosebelief(beliefcpt.beliefs, nar.tasksentence)

    # @debug name(nar.tasksentence) beliefcpt belief

    nar.forward = nar.tasksentence isa Sentence{Judgement} ? true : false

    # try match local rules
    if !isnothing(nar.belief)
        localmatch(nar.task, nar.belief, nar) && return
    end

    try
        dispatch(deepcopy(nar.tasksentence.term), deepcopy(beliefcpt.term), nar)
    catch e
        @show nar.cpt.term
        @show name(nar.tasksentence)
        @show nar.beliefcpt.term
        @show nar.belief
        rethrow(e)
    end
end

"""
从信念表中挑信念,信念表应该是排好序的
"""
# TODO
function choosebelief(beliefs, sentence)
    beliefs === nothing && return
    for belief in beliefs
        overlapped(belief.stamp, sentence.stamp) && continue
        return belief
    end
end

function gentask(term, truth, bgt, nar)
    new_quality = t2q(truth)
    new_budget = genbgt(infer_type, new_truth, cpx(term), nar)
    new_stamp = unionstamp(task_senten.stamp, belief.stamp, nar.time)
    new_senten = Sentence{SenType(infer_type)}(term, new_truth, new_stamp)
    new_token = Token(hash(new_senten), bgt)
    adjust_blink!(blink, new_quality, priority(blink))
    task = NaTask(new_token, new_senten, nothing)
    put!(nar.internal_exp, task)
end


function adjust_blink!(blink, quality, bpri)
    inc_priority!(blink, or(quality, bpri))
    inc_durability!(blink, quality)
    nothing
end
