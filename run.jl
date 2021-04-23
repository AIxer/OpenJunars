using Junars
using DataStructures

cycles = Ref{UInt}(0)
serial = Ref{UInt}(0)

oracle = NaCore(Narsche{Concept}(100, 10, 400), Narsche{NaTask}(5, 3, 20), MutableLinkedList{NaTask}(), serial, cycles);

ignite(oracle)