"""
当任务携带的词项已经存在于记忆中时,应用本地规则
"""
# TODO
function localmatch(task, belief, nar)
    sentence = deepcopy(task.sentence)
    if isjudgment(sentence)
        if sentence.term == belief.term
            derivetask2(Revise(), sentence.term, :revision, nar)
            return true
        end
        return false
    elseif unify!(QVar, sentence.term, belief.term)
        trysolution!(belief, task, nar)
        return true
    end
    false
end

"""
TODO
"""
function trysolution!(answer::Belief, task::NaTask, nar::Nar)
    problem = task.sentence
    old_best = task.best_solu
    new_quality = quality(problem, answer)
    if !isnothing(old_best)
        old_quality = quality(problem, old_best)
        old_quality >= new_quality && return
    end
    task.best_solu = answer
    # TODO task应该携带相关Channel的通道口
    @info "Answer: $(name(task.best_solu))"

    # ! 调整相关链接
    bgt(task).priority = min(1 - new_quality, priority(task))
    new_bgt = Budget(or(priority(task), new_quality), durability(task), t2q(answer.truth))
    # TODO feed back to links?
    if above_threshold(new_bgt)
        new_task = NaTask(
            Token(hash(nar.cpt.term), new_bgt),
            answer, task, answer, task.pbelief) # ! what?
        put!(nar.internal_exp, new_task)
    end
    nothing
end


"""
计算一个判断作为问题的答案的质量
"""
Gene.quality(::Nothing, solution::Sentence) = expect(solution.truth)
function Gene.quality(problem::Sentence, solution::Sentence)
    if has(QVar, problem.term)
        expect(solution.truth) / cpx(solution.term)
    else
        solution.truth.confidence
    end
end

"""
这里的revision是规则
"""
function revise(judgment::Sentence, belief::Sentence, nar::Nar)
    overlapped(judgment.stamp, belief.stamp) && return false
    nar.belief = belief # TODO redundant?
    newtruth = revision(judgment.truth, belief.truth)
    # 生成新任务
    derivetask!(Revise, judgment.term, newtruth, nar)
    return true
end

function reviselinks!(truth::Truth, nar::Nar)
    btruth = nar.belief.truth
    ttruth = nar.tasksentence.truth
    tdiff = absexpdiff(truth, ttruth)
    dec_priority!(nar.task, 1 - tdiff)
    dec_durability!(nar.task, 1 - tdiff)
    if nar.tasklink !== nothing
        # feedback to links
        bdiff = absexpdiff(truth, btruth)
        dec_priority!(nar.tasklink, 1 - tdiff)
        dec_durability!(nar.tasklink, 1 - tdiff)
        dec_priority!(nar.termlink, 1 - bdiff)
        dec_durability!(nar.termlink, 1 - bdiff)
    end
    confdiff = truth.confidence - max(ttruth.confidence, btruth.confidence)
    Budget(
        or(confdiff, priority(nar.task)),
        ave_ari(confdiff, durability(nar.task)),
        t2q(truth)
    )
end
