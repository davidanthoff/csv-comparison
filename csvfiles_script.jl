using CSVFiles, DataFrames

warmup_filename = ARGS[1]
filename = ARGS[2]

df = DataFrame(load(warmup_filename))

GC.gc(); GC.gc(); GC.gc()

t = @elapsed(df = DataFrame(load(filename)))

println(t)
