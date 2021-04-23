const Belief = Sentence{Judgement}

function rank(b::Belief)
    confidence = b.truth.confidence
    originality = 1.0 / (length(b.stamp) + 1)
    or(confidence, originality)
end

Gene.expect(b::Belief) = expect(b.truth)

function overlapped(sentence::Sentence, beliefs::Table{Belief})
    for belief in beliefs
        overlapped(sentence.stamp, belief.stamp) && return true
    end
    return false
end

"""
挑一个证据基不重叠的信念
"""
function choose(sentence::Sentence, beliefs::Table{Belief})
    for belief in beliefs
        !overlapped(sentence.stamp, belief.stamp) && return belief
    end
    nothing
end
