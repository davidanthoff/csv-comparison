ourpath(rows, cols, withna) = joinpath(@__DIR__, "..", "data", string("rows_", rows, "_cols_", cols, "_na_", withna))

ns = [100, 10_000, 1_000_000];
cs = [20, 200];
samples = 5;
missing_share = 0.5;
