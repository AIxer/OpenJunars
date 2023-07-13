function ignite(nacore::NaCore)
    while true
        # 输出彩色字符（绿色粗体→"Junars> "→重置格式 ）
        print("\e[1;32mJunars> \e[0m")
        input = readline(stdin) |> strip |> string
        isempty(input) && continue
        # 冒号开头的特殊指令
        if startswith(input, ':')
            response = handleColonCmd(nacore, input[2:end])
            isnothing(response) && return # quit指令
            response && continue # 若有响应，不作为语句执行
        end
        task = nothing
        try
            addone(nacore, input)
        catch e
            throw(e)
            continue
        end
    end
end

"""
处理「冒号命令」
参数「cmdStr」：不带冒号
返回：命令是否被执行
"""
function handleColonCmd(nacore::NaCore, cmdStr::String)

    mem = nacore.mem
    buffer = nacore.internal_exp

    args = split(cmdStr) # 将命令拆解成参数列表

    if startswith("quit", args[1]) # 指令「quit」：退出
        return nothing
    elseif args[1] == "p" # 指令「:p」：打印跟踪
        @show count(mem)
        showtracks(mem)
        return true
    elseif startswith(args[1], "c") # 指令「:c」「:cp」：cycle 运行指定周期
        if cmdStr == "c" # 只有c：直接cycle
            cycle!(nacore)
            return true
        end
        # 若c/cp后面带参数：循环一定次数
        length(args) > 1 && for _ in 1:parse(Int, args[2])
            cycle!(nacore)
        end
        # cp：打印跟踪
        if args[1] == "cp" # cp：先cycle，再打印跟踪
            showtracks(mem)
        end
        return true
    end
    return false
end

function addone(nacore, s::AbstractString)
    stamp = Stamp([nacore.serials[]], nacore.cycles[])
    task = parsese(s, stamp)
    put!(nacore.internal_exp, task)
    nacore.serials[] += 1
end

function showtracks(cpts::Narsche)
    for level in cpts.total_level:-1:1
        length(cpts.track[level]) == 0 && continue
        print("L$level: ")
        for racer in cpts.track[level]
            print("{$(name(racer)); $(round(priority(racer), digits=2))}")
        end
        println()
    end
end
