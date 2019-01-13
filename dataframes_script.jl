using DataFrames

warmup_filename = ARGS[1]
filename = ARGS[2]

readtable(warmup_filename)

GC.gc(); GC.gc(); GC.gc()

t = @elapsed(readtable(filename))

println(t)
