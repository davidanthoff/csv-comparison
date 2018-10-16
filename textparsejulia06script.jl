using TextParse

filename = ARGS[1]

csvread(filename)

n = parse(Int, ARGS[2])
ts = []
for i=1:n
    gc(); gc(); gc()
    push!(ts, @elapsed(csvread(filename)))
end

for t in ts
    println(t)
end
