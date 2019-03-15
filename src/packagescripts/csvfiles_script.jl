using CSVFiles, DataFrames

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(DataFrame(load(warmup_filename)))

GC.gc(); GC.gc(); GC.gc()

t2 = @elapsed(DataFrame(load(filename)))

GC.gc(); GC.gc(); GC.gc()

t3 = @elapsed(DataFrame(load(filename)))

println(t1)
println(t2)
println(t3)
