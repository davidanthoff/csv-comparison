ourpath(rows, cols, withna) = joinpath("data", string("rows_", rows, "_cols_", cols, "_na_", withna))

const ns = [100, 10_000, 1_000_000];
const cs = [20, 200];
const samples = 5;
const missing_share = 0.5;
