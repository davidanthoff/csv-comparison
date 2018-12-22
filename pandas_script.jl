using Pandas

warmup_filename = ARGS[1]
filename = ARGS[2]

Pandas.read_csv(warmup_filename)

GC.gc(); GC.gc(); GC.gc()

t = @elapsed(Pandas.read_csv(filename))

println(t)
