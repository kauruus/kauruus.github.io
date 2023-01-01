+++
title = "Visualize Web Framework Benchmark Result"
hasplotly = true
+++

# {{ title }}

Recently, I found the latency result in [Web Frameworks Benchmark](https://web-frameworks-benchmark.netlify.app/) is weird.

It turns out that the data table shows the wrong unit. It display us as ms. So I submit a [PR](https://github.com/the-benchmarker/website/pull/34) to fix it.

After the fix, the data looks good, but the table is still hard to read, especially when you want to compare multiple frameworks and languages.

So I did draw some graphs to visualize the result.


```julia:generateplots
#hideall
using PlotlyJS
using JSON3
using DataFrames

json_data = read("./_assets/web-benchmark-2023-01-01-data.min.json", String)
data = JSON3.read(json_data)

frameworks = []
languages = []
for f in data.frameworks
    push!(frameworks, f.label)
    push!(languages, f.language)
end

p99_latency_512 = []
p99_latency_256 = []
p99_latency_64 = []

qps_512 = []
qps_256 = []
qps_64 = []

average_latency_512 = []
average_latency_256 = []
average_latency_64 = []

# assume data.metrics is sorted by framework id
for metric in data.metrics    
    if metric.level == 512
        if metric.label == "percentile_99"
            push!(p99_latency_512, metric.value / 1000)
        elseif metric.label == "total_requests_per_s"
            push!(qps_512, metric.value)
        elseif metric.label == "average_latency"
            push!(average_latency_512, metric.value / 1000)
        end
    end
    
    if metric.level == 256
        if metric.label == "percentile_99"
            push!(p99_latency_256, metric.value / 1000)
        elseif metric.label == "total_requests_per_s"
            push!(qps_256, metric.value)
        elseif metric.label == "average_latency"
            push!(average_latency_256, metric.value/ 1000)
        end
    end
    
    if metric.level == 64
        if metric.label == "percentile_99"
            push!(p99_latency_64, metric.value / 1000)
        elseif metric.label == "total_requests_per_s"
            push!(qps_64, metric.value)
        elseif metric.label == "average_latency"
            push!(average_latency_64, metric.value/ 1000)
        end
    end
end

df = DataFrame(framework=frameworks, 
language=languages,
qps_512=qps_512, qps_256=qps_256, qps_64=qps_64, 
p99_latency_512=p99_latency_512, p99_latency_256=p99_latency_256, p99_latency_64=p99_latency_64,
average_latency_512=average_latency_512, average_latency_256=average_latency_256, average_latency_64=average_latency_64
)

sorted_by_latency = sort(df, [:average_latency_64])
sorted_by_qps = sort(df, [:qps_64])

layout = Layout(
    xaxis_type="log",
    yaxis_title="Frameworks", 
    xaxis_title="Latency", 
    height=800,
    margin=attr(l=140, r=40, b=50, t=80),
)

plt1 = plot([
    scattergl(x=sorted_by_latency.p99_latency_512, y=sorted_by_latency.framework, mode="markers", name="P99, 512 Conns"),
    scattergl(x=sorted_by_latency.p99_latency_256, y=sorted_by_latency.framework, mode="markers", name="P99, 256 Conns"),
    scattergl(x=sorted_by_latency.p99_latency_64, y=sorted_by_latency.framework,  mode="markers", name="P99, 64 Conns"),
    scattergl(x=sorted_by_latency.average_latency_512, y=sorted_by_latency.framework, mode="markers", name="Avg, 512 Conns"),
    scattergl(x=sorted_by_latency.average_latency_256, y=sorted_by_latency.framework, mode="markers", name="Avg, 256 Conns"),
    scattergl(x=sorted_by_latency.average_latency_64, y=sorted_by_latency.framework,  mode="markers", name="Avg, 64 Conns"), 
    ], layout,
)

layout = Layout(
    xaxis_type="log",
    yaxis_title="Frameworks", 
    xaxis_title="QPS", 
    height=800,
    margin=attr(l=140, r=40, b=50, t=80),
)

plt2 = plot([
    scattergl(x=sorted_by_qps.qps_512, y=sorted_by_qps.framework, mode="markers", name="512 Conns"),
    scattergl(x=sorted_by_qps.qps_256, y=sorted_by_qps.framework, mode="markers", name="256 Conns"),
    scattergl(x=sorted_by_qps.qps_64, y=sorted_by_qps.framework,  mode="markers", name="64 Conns"),
    ], layout,
)

layout = Layout(
    xaxis_type="log",
    yaxis_type="log",
    yaxis_title="P99 Latency", 
    xaxis_title="QPS", 
    height=600,
    margin=attr(l=140, r=40, b=50, t=80),
)

plt3 = plot(sorted_by_qps, x=:qps_512, y=:p99_latency_512, text=:framework, color=:language, mode="markers", layout)

layout = Layout(
    xaxis_type="log",
    yaxis_type="log",
    yaxis_title="Average Latency", 
    xaxis_title="QPS", 
    height=600,
    margin=attr(l=140, r=40, b=50, t=80),
)

plt4 = plot(sorted_by_qps, x=:qps_512, y=:average_latency_512, text=:framework, color=:language, mode="markers", layout)
savejson(plt1, joinpath(@OUTPUT, "plt1.json"))
savejson(plt2, joinpath(@OUTPUT, "plt2.json"))
savejson(plt3, joinpath(@OUTPUT, "plt3.json"))
savejson(plt4, joinpath(@OUTPUT, "plt4.json"))
```

## QPS

Here is the QPS of each framework with 64, 256 and 512 concurrent clients.

\fig{plt2}

From the right parts of it, you can see that some framework's QPS increase as clients count increase.

It means that, these fast frameworks are still not reaching their limits, and we need to generate more load.

## Latency

Nowadays, we also care about user experience, and latency is a common metric for it.


\fig{plt1}

As load increases, latency will increase.

The Nickel framework is pretty amzing, it provides really low and consistent latency.

## Latency and QPS

Now we have latency and QPS data, we can combine them in the same graph.

For average latency and QPS, it's almost a straight light.

\fig{plt4}

For P99 latency and QPS, it becomes much messy, but you still can see the trend. 

\fig{plt3}

