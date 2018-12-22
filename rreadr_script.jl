using RCall

R"""
memory.limit(size=32000)
library(readr)
options(readr.num_columns = 0)
""";

warmup_filename = ARGS[1]
filename = ARGS[2]

R"""
suppressMessages(read_csv($warmup_filename, progress = FALSE))
"""

GC.gc(); GC.gc(); GC.gc()

t = convert(Float64, R"""
    start_time = Sys.time()
    suppressMessages(read_csv($filename, progress = FALSE))
    end_time = Sys.time()
    elap = end_time - start_time
""")

println(t)
