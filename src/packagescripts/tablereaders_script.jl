using TableReader

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(readcsv(warmup_filename))

GC.gc(); GC.gc(); GC.gc()

t2 = @elapsed(readcsv(filename))

GC.gc(); GC.gc(); GC.gc()

t3 = @elapsed(readcsv(filename))

println(t1)
println(t2)
println(t3)
