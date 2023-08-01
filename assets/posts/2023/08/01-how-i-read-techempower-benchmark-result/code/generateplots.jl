# This file was generated, do not modify it. # hide
#hideall
using PlotlyJS
using CSV
using DataFrames

csv_file = CSV.File("./_assets/tfb-273fa177.csv")
data = DataFrame(csv_file)

layout = Layout(
    yaxis_title="Frameworks", 
    xaxis_title="QPS", 
    height=1000,
    margin=attr(l=40, r=40, b=20, t=20),
)

layout_log = Layout(
    yaxis_title="Frameworks", 
    yaxis_type="log",
    xaxis_title="QPS", 
    height=1000,
    margin=attr(l=40, r=40, b=20, t=20),
)

benchmarks = ["plaintext", "json", "1-query", "fortunes", "20-query", "updates"]


lines = Vector{GenericTrace{Dict{Symbol, Any}}}()
for row in eachrow(data)
    scores = collect(row)[2:7]
    push!(lines, scatter(x=benchmarks, y=scores, mode="lines", name=row.framework))
end

plt1 = plot(lines, layout)
plt2 = plot(lines, layout_log)

savejson(plt1, joinpath(@OUTPUT, "tfb.json"))
savejson(plt2, joinpath(@OUTPUT, "tfb_log.json"))