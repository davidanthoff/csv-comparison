using CSV

warmup_filename = ARGS[1]
filename = ARGS[2]

CSV.read(warmup_filename)

GC.gc(); GC.gc(); GC.gc()

t = @elapsed(CSV.read(filename))

println(t)
