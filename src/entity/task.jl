mutable struct NaTask <: Racer
    token::Token
    sentence::Sentence
    ptask::Union{Nothing, NaTask}
    pbelief::Union{Nothing, Sentence}
    best_solu::Union{Nothing, Sentence}
end

NaTask(token::Token, sentence::Sentence) = NaTask(token, sentence, nothing, nothing, nothing)

Gene.name(t::NaTask) = name(t.sentence)
Gene.target(t::NaTask) = token(t).target

creatime(task::NaTask) = task.sentence.stamp.creatime

function Base.merge!(task1::NaTask, task2::NaTask)
    if creatime(task1) > creatime(task2)
        merge!(task1.token.bgt, task2.token.bgt)
    else
        merge!(task2.token.bgt, task1.token.bgt)
    end
end

Gene.above_threshold(task::NaTask) = above_threshold(bgt(task))
