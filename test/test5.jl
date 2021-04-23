using Junars
using DataStructures

ENV["JULIA_DEBUG"] = Junars

cycles = Ref{UInt}(0)
serial = Ref{UInt}(0)

oracle = NaCore(Narsche{Concept}(100, 10, 400), Narsche{NaTask}(5, 3, 20), MutableLinkedList{NaTask}(), serial, cycles);

addone(oracle, raw"(&&, <天鹅-->动物>, <麻雀-->鸟>)?")
addone(oracle, raw"<天鹅-->动物>. %0.80%")
cycle!(oracle)

for i in 1:50
    cycle!(oracle)
end
