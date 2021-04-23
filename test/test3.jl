# ENV["JULIA_PKG_SERVER"] = "https://cn-northeast.pkg.juliacn.com"
# using Revise
# using ClearStacktrace
using Junars
using Junars.Gene
using Junars.Entity
using Junars.Admins
using Junars.Control

ENV["JULIA_DEBUG"] = Junars

cycles = Ref{UInt}(0)
serial = Ref{UInt}(0)

oracle = NaCore(Narsche{Concept}(100, 20, 400), Narsche{NaTask}(5, 3, 20), serial, cycles);

# ignite(oracle)

# """
# <a-->b>.
# :c
# <b-->c>.
# :c
# """
# addone(oracle, "<cat-->animal>.")
# addone(oracle, "<dog-->animal>. %0.4%")

# addone(oracle, "<swan --> swimmer>. %0.9%")
# addone(oracle, "<swan --> bird>. %0.8%")

# addone(oracle, "<sport --> competition>. %0.9%")
# addone(oracle, "<chess --> competition>. %0.8%")

# addone(oracle, "<robin --> (|,bird,swimmer)>.")
# addone(oracle, "<robin --> swimmer>. %0.0%")

# addone(oracle, "<rabbit-->[running]>.")
# addone(oracle, "<rabbit-->[sleeping]>.")

# addone(oracle, "<bird-->animal>.")
# addone(oracle, "<robin-->bird>.")
# cycle!(oracle)
# for i = 1:40
#     cycle!(oracle)
# end
# addone(oracle, "<bird-->sth>.")
# for i in 1:10
#     cycle!(oracle)
# end
# addone(oracle, "<swan --> animal>.")
# for i in 1:30
#     cycle!(oracle)
# end

# addone(oracle, "<(&&, D, <(*,a,b)-->c>) ==> E>.")

# addone(oracle, "<<a-->b> ==> <c-->d>>.")
# addone(oracle, "(--, <a-->b>).")

# addone(oracle, "<a-->b>.")
# addone(oracle, "<b-->c>.")

# addone(oracle, "<a-->b>. %0.8;0.7%")
# addone(oracle, "<{P}-->M>.")
# addone(oracle, "<M-->[S]>.")
cycle!(oracle)
cycle!(oracle)
for i = 1:40
    cycle!(oracle)
end
