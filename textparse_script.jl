using TextParse

warmup_filename = ARGS[1]
filename = ARGS[2]

csvread(warmup_filename)

GC.gc(); GC.gc(); GC.gc()

t = @elapsed(csvread(filename))

println(t)
