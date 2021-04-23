function ignite(nacore::NaCore)
    mem = nacore.mem
    buffer = nacore.internal_exp

    while true
        print("Junars> ")
        input = readline(stdin) |> strip |> string
        length(input) == 0 && continue
        if input == ":q" || input == ":quit"
            return
        elseif input == ":p"
            @show count(mem)
            showtracks(mem)
            continue
        elseif startswith(input, ":c")
            if length(input) == 2
                cycle!(nacore)
                continue
            end
            if input == ":cp"
                cycle!(nacore)
                showtracks(mem)
                continue
            end
            for i in 1:parse(Int, input[3:end])
                cycle!(nacore)
            end
            continue
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
