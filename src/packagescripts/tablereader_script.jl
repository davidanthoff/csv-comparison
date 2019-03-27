using TableReader

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(readcsv(warmup_filename, chunksize = 0))

GC.gc(); GC.gc(); GC.gc()

t2 = @elapsed(readcsv(filename, chunksize = 0))

GC.gc(); GC.gc(); GC.gc()

t3 = @elapsed(readcsv(filename, chunksize = 0))

println(t1)
println(t2)
println(t3)
