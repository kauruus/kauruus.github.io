using Dates

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

# modify from https://github.com/tlienart/tilenart.github.io
@delay function hfun_posts()
    curyear = year(Dates.today())
    io = IOBuffer()
    for year in curyear:-1:2022
        ys = "$year"
        isdir(joinpath("posts", ys)) || continue
        write(io, "\n\n# $year\n\n")
        write(io, "@@list,mb-5\n")
        for month in 12:-1:1
            ms = "0"^(month < 10) * "$month"
            base = joinpath("posts", ys, ms)
            isdir(base) || continue
            posts = filter!(p -> endswith(p, ".md"), readdir(base))
            days  = zeros(Int, length(posts))
            lines = Vector{String}(undef, length(posts))
            for (i, post) in enumerate(posts)
                ps  = splitext(post)[1]
                url = "/posts/$ys/$ms/$ps/"
                surl = strip(url, '/')
                title = pagevar(surl, :title)
                days[i] = parse(Int, first(ps, 2))
                pubdate = Dates.format(
                    Date(year, month, days[i]), "U d")

                tmp = "* ~~~<span class=\"post-date\">$pubdate</span><a href=\"$url\">$title</a>"
                descr = pagevar(surl, :descr)
                if descr !== nothing
                    tmp *= ": <span class=\"post-descr\">$descr</span>"
                end
                lines[i] = tmp * "~~~\n"
            end
            # sort by day
            foreach(line -> write(io, line), lines[sortperm(days, rev=true)])
        end
        write(io, "@@\n")
    end
    return Franklin.fd2html(String(take!(io)), internal=true)
end
