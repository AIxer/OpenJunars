# 语法组成 NAL 1-6
const copula = ["-->", "<->", "==>", "<=>"]
const native_op = ["&", "|", "-", "~", "*", "/", "\\", "--", "&&", "||", "#"]

const opener = ['(', '{', '[', '<']
const closer = [')', '}', ']', '>']

isopener(c::Char) = c in opener || false
iscloser(c::Char) = c in closer || false
iscopula(cop::AbstractString) = cop in copula || false
isvalid_op(op::AbstractString) = op in native_op || false


# <<$sth --> (&,[furry,meowing],animal)> =/> <$sth --> [good]>>
function parsese(input::String, stamp)
    # 先预处理,提取出字段
    budget, term_str, type, truth = preprocess(input)
    type_str = type == Judgement ? "." : "?"
    term = parse_term(term_str)
    renamevar!(term, Dict())
    revisible = !(term isa Conjunction && has(DVar, term))
    sentence = Sentence{type}(term, truth, stamp, revisible)
    task_token = Token(hash(sentence), budget)
    # 返回解析结果 Task
    NaTask(task_token, sentence)
end

# 预处理
function preprocess(nse::String)
    nse = replace(nse, " " => "")
    budget = nothing
    truth_str = nothing

    # 是否输入了Truth
    # 解析完裁掉truth_str
    if nse[end] == '%'
        truth_start = findlast('%', nse[1:prevind(nse, end, 1)])
        truth_str = nse[truth_start:end]
        nse = nse[1:prevind(nse, truth_start, 1)]
    end

    # type 只占用一个字符
    if nse[end] == '.'
        type = Judgement
    elseif nse[end] == '?'
        type = Question
    end

    term_str = nse[1:prevind(nse, end, 1)]

    # 没输入就给各默认的Truth,可用户自定义默认值
    truth = truth_str === nothing ? Truth() : parse_truth(truth_str)

    # 初始化budget
    budget = gen_budget(type, truth)

    (budget, term_str, type, truth)
end


# 根据输入的句子类型生成Budget初始值
# TODO 还有待完善
function gen_budget(t, truth::Truth)
    if t <: Judgement
        Budget(0.8, 0.8, t2q(truth))
    else
        Budget(0.9, 0.9, t2q(truth))
    end
end

# %0.4;0.5%   %0.4%
function parse_truth(truth_str::String)
    # truth_str = strip(truth_str)

    if length(truth_str) < 3
        throw(error("Invalid truth value Input! $truth_str"))
    end

    truth_str = truth_str[2:prevind(truth_str, end, 1)]
    # 0.4; 0.5   0.4
    # 看看是输入了一个还是两个
    if ';' in truth_str
        fc = split(truth_str, ';') .|> strip .|> string
        try
            fc = parse.(Float64, fc)
        catch e
            @error "Invalid truth value Input! $truth_str"
            rethrow(e)
        end
        return Truth(fc[1], fc[2])
    end
    try
        return Truth(parse(Float64, truth_str))
    catch e
        @error "Invalid truth value Input! $truth_str"
        rethrow(e)
    end

end

# Term解析第一入口
function parse_term(term::String)
    term = replace(term, " "=>"")
    if term[1] == '<'
        parse_statement(term)
    elseif term[1] == '('
        parse_compound(term)
    elseif term[1] == '{'
        parse_set_ext(term)
    elseif term[1] == '['
        parse_set_int(term)
    else
        parse_atom(term)
    end
end

# {a, b, c}
function parse_set_ext(term::String)
    if term[end] != '}'
        @error "Invalid ExtSet Input!"
    end
    ExtSet(parse_args(term[2:prevind(term, end, 1)]))
end

# [a,b,c]
function parse_set_int(term::String)
    if term[end] != ']'
        @error "Invalid IntSet Input! $term"
    end
    IntSet(parse_args(term[2:prevind(term, end, 1)]))
end


# (op, args)
# Operation or SetOp
# Image
function parse_compound(term::String)
    if term[end] != ')'
        @error "Invalid input! $term"
    end
    term = term[2:prevind(term, end, 1)]
    op_end = nextsep(',', term)
    op = term[1:prevind(term, op_end, 1)]
    op = strip(op)


    if startswith(op, "^")
        length(op) > 1 || @error "Invalid input! $term"
    else
        isvalid_op(op) || @error "Invalid input! $term"
    end

    args = parse_args(term[nextind(term, op_end, 1):end])
    if op == "*"        Product(args)
    elseif op == "&&"   Conjunction(AbstractStatement[args...])
    elseif op == "||"   Disjunction(args)
    elseif op == "|"    IntIntersection(args)
    elseif op == "&"    ExtIntersection(args)
    elseif op == "-"    ExtDiff(args[1], args[2])
    elseif op == "~"    IntDiff(args[1], args[2])
    elseif op == "*"    Product(args)
    elseif op == "\\"   parse_image(args, op)
    elseif op == "/"    parse_image(args, op)
    elseif op == "--"   Negation(args[1])
    elseif startswith(op, "^")  parse_operation(op, args)
    end
end

"""
</, A, _, B --> C
"""
function parse_image(args, type)
    relaidx = 0
    comps = Vector{Term}(undef, length(args))
    for (i, term) in enumerate(args)
        if term isa PlaceHolder
            relaidx = i
        end
        @inbounds comps[i] = term
    end
    if type == "/"
        return ExtImage(relaidx, comps)
    end
    IntImage(relaidx, comps)
end

"""
(^op, arg1, arg2, arg3, ...)
==> <(*, arg1, arg2, arg3, ...) --> ^op>
"""
function parse_operation(op, args)
    actor = Action(Symbol(op[2:end]))
    Operation(ArgProduct(args), actor)
end

# 用于解析^op, * 的参数
# T1,T2,T3,...,
function parse_args(args::String)
    res = Term[]
    last = nextsep(',', args)
    while last != -1
        push!(res, parse_term(args[1:prevind(args, last, 1)])) # not include ','
        args = args[nextind(args, last, 1):end]
        last = nextsep(',', args)
    end
    # last one
    push!(res, parse_term(args))
    return res
end


# Word or Variable
function parse_atom(term::String)
    term = strip(term)
    if term[1] == '$'
        Variable{IVar}(term[2:end])
    elseif term[1] == '#'
        Variable{DVar}(term[2:end])
    elseif term[1] == '?'
        length(term) == 1 && return Variable{QVar}("what")
        Variable{QVar}(term[2:end])
    elseif term == "_"
        PlaceHolder()
    else
        Word(term)
    end
end

# <a --> b>
function parse_statement(term::String)
    # @debug term[end]
    if term[end] != '>'
        @error "Invalid input! $term"
    end
    term = term[2:prevind(term, end, 1)]

    main_idx = find_top_relation(term)
    if main_idx === nothing
        @error "Invalid input: No main copula in a statement"
    end

    top_relation = term[main_idx:nextind(term, main_idx, 2)]
    # @debug term[1:main_idx-1]
    subj = parse_term(term[begin:prevind(term, main_idx, 1)])
    # @debug term[main_idx+3:end]
    pred = parse_term(term[nextind(term, main_idx, 3):end])

    if top_relation == "-->"
        Inheritance(subj, pred)
    elseif top_relation == "<->"
        Similarity(subj, pred)
    elseif top_relation == "==>"
        Implication(subj, pred)
    elseif  top_relation == "<=>"
        Equivalence(subj, pred)
    end
end

# term 应该去掉头尾
# main copula are
# --> <-> ==> <=>
function find_top_relation(term::String)
    level = 1
    for idx in eachindex(term[begin:prevind(term, end, 2)])
        if iscopula(term[idx:nextind(term, idx, 2)])
            level == 1 && return idx
            continue
        end
        if isopener(term[idx]) level += 1 end
        if iscloser(term[idx])
            if idx > 2 && !iscopula(term[prevind(term, idx, 2):idx])
                level -= 1
                # ? else? 
            end
        end
    end
    nothing
end

function find_closer(nse_part::String)
    level = 1
    indice = find_copula(nse_part)
    for idx in eachindex(nse_part)
        if isopener(nse_part[idx])
            iscopula(nse_part[idx:nextind(nse_part, idx, 2)]) && continue
            level += 1
        end
        if iscloser(nse_part[idx])
            iscopula(nse_part[prevind(nse_part, idx, 2):idx]) && continue
            if level == 1
                return idx
            end
            level -= 1
        end
    end
    nothing
end

function find_copula(term::String)
    indice = Int[]
    for i in eachindex(term[begin:prevind(term, end, 2)])
        if iscopula(term[i:nextind(term, i, 2)])
            push!(indice, i)
        end
    end
    indice
end

# 获取下一个分隔符的索引
# TODO: 潜在Bug: Unicode字符会解析错误
# 使用eachindex()
function nextsep(sep::Char, term::String)
    level = 1
    for idx in eachindex(term)
        if term[idx] == sep && level == 1 
            return idx
        end

        if isopener(term[idx]) 
            if idx <= length(term) - 2
                iscopula(term[idx:nextind(term, idx, 2)]) && continue
            end
            level += 1
        end

        if iscloser(term[idx])
            if idx > 2
                iscopula(term[prevind(term, idx, 2):idx]) && continue
            end
            level -= 1 
        end
    end
    -1
end
