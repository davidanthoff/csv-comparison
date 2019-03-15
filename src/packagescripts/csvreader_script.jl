using CSVReader

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(CSVReader.read_csv(warmup_filename))

GC.gc(); GC.gc(); GC.gc()

t2 = @elapsed(CSVReader.read_csv(filename))

GC.gc(); GC.gc(); GC.gc()

t3 = @elapsed(CSVReader.read_csv(filename))

println(t1)
println(t2)
println(t3)
