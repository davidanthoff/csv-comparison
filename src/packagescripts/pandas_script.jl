using Pandas

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(Pandas.read_csv(warmup_filename))

GC.gc(); GC.gc(); GC.gc()

t2 = @elapsed(Pandas.read_csv(filename))

GC.gc(); GC.gc(); GC.gc()

t3 = @elapsed(Pandas.read_csv(filename))

println(t1)
println(t2)
println(t3)
