library(data.table)

args = commandArgs(trailingOnly=TRUE)

warmup_filename = args[1]
filename = args[2]

start_time = Sys.time()
x1 <- fread(warmup_filename, nThread=1)
end_time = Sys.time()
t1 = end_time - start_time


start_time = Sys.time()
x2 <- fread(filename, nThread=1)
end_time = Sys.time()
t2 = end_time - start_time


start_time = Sys.time()
x3 <- fread(filename, nThread=1)
end_time = Sys.time()
t3 = end_time - start_time

cat(as.numeric(t1))
cat('\n')
cat(t2)
cat('\n')
cat(t3)
cat('\n')
