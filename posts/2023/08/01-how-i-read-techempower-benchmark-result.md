+++
title = "How I Read TechEmpower Benchmark Result"
hasplotly = true
+++

# {{ title }}

In the Composite scores page, we can see a table including scores for all framework and benchmarks.


Let's first rearrange the column order, order the benchmarks by the overall QPS (Plaintext -> JSON -> 1 Query -> Fortunes -> 20 Query -> Update):

![](/assets/images/tfb.png)

A graph to see how QPS drops when more logic and DB operation are added: 


```julia:generateplots
#hideall
using PlotlyJS
using CSV
using DataFrames

csv_file = CSV.File("./_assets/tfb-273fa177.csv")
data = DataFrame(csv_file)

layout = Layout(
    yaxis_title="QPS", 
    xaxis_title="Test", 
    height=1000,
    margin=attr(l=40, r=40, b=20, t=20),
)

layout_log = Layout(
    yaxis_title="QPS", 
    yaxis_type="log",
    xaxis_title="Test", 
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
```

\fig{tfb}

in log scale:

\fig{tfb_log}



