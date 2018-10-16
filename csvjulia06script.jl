using CSV

filename = ARGS[1]

CSV.read(filename)

n = parse(Int, ARGS[2])
ts = []
for i=1:n
    gc(); gc(); gc()
    push!(ts, @elapsed(CSV.read(filename)))
end
for t in ts
    println(t)
end
