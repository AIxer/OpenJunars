"""
把Buffer里的所有Task全部处理了
"""
function absorb!(nar::Nar)
    while true
        isempty(nar.taskbuffer) && break
        task = pop!(nar.taskbuffer)
        absorb!(task, nar)
    end
    while true
        task = take!(nar.internal_exp)
        isnothing(task) && break
        absorb!(task, nar)
    end
end

function absorb!(task::NaTask, nar::Nar)
    1 + 1
    @debug "Try absorb" name(task.sentence)
    nar.task = task
    old_task_cpt = peek(nar.mem, hash(task.sentence.term))
    if !isnothing(old_task_cpt)
        activate!(nar.mem, old_task_cpt, task)
        directprocess(old_task_cpt, task, nar)
    end
    !above_threshold(task) && return
    for cpt in conceptualize(task)
        put!(nar.mem, cpt)
    end
end

function directprocess(cpt::Concept, task::NaTask, nar)
    nar.cpt = cpt
    nar.task = task
    if eltype(task.sentence) <: Judgement
        process_judgment(cpt, task, nar)
    elseif eltype(task.sentence) <: Question
        process_question(cpt, task, nar)
    end
end

"""
把Judgment添加到BeliefTable中,同时尝试修正
"""
function process_judgment(cpt::Concept, task::NaTask, nar)
    judgment = task.sentence
    oldbest = isnothing(cpt.beliefs) ? nothing : first(cpt.beliefs)
    if !isnothing(oldbest)
        if judgment.stamp == oldbest.stamp
            if !isnothing(task.ptask) && eltype(task.ptask.sentence) <: Judgement # 要查询，先看有没有
                dec_priority!(task, 0) # 重复的任务
            end
            return
        else
            judgment.revisable && revise(judgment, oldbest, nar)
        end
    end

    if above_threshold(task)
        Threads.@threads for qtask in collect(cpt.questions)
            trysolution!(judgment, qtask, nar) # Warn
        end
        if isnothing(cpt.beliefs)
            cpt.beliefs = Table{Belief}(judgment)
        else
            add!(cpt.beliefs, judgment)
        end
    end
end

function process_question(cpt, task, nar)
    quest = task.sentence
    # 检查是否是新问题
    if !any(qt->qt.sentence.term == quest.term, cpt.questions)
        if length(cpt.questions) >= NaParam.MAXIMUM_QUESTIONS_SIZE
            popfirst!(cpt.questions)
        end
        push!(cpt.questions, task)
    end
    # 给出回答
    # TODO 这里其实不应该直接送到终端
    # 先找一个最好的回答
    answer = evaluate(quest, cpt.beliefs)
    isnothing(answer) && return # ! 可能是问题先到,没有信念
    # 回答任务并看看新答案是否优于已有的
    trysolution!(answer, task, nar)
end

"""
从已有的信念出找出一个最优的解答
"""
evaluate(quest, ::Nothing) = nothing
function evaluate(quest, beliefs::Table{Belief})
    curbest = 0.
    candidate = quest
    for belief in beliefs
        solu_quality = quality(quest, belief)
        if solu_quality > curbest
            curbest = solu_quality
            candidate = belief
        end
    end
    return candidate
end

