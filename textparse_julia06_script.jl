using TextParse

warmup_filename = ARGS[1]
filename = ARGS[2]

csvread(warmup_filename)

gc(); gc(); gc()

t = @elapsed(csvread(filename))

println(t)
