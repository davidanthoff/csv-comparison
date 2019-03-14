using DataFrames

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(readtable(warmup_filename))

GC.gc(); GC.gc(); GC.gc()

t2 = @elapsed(readtable(filename))

GC.gc(); GC.gc(); GC.gc()

t3 = @elapsed(readtable(filename))

println(t1)
println(t2)
println(t3)
