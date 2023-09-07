function differentiate(series::TimeArray,d::Int=0, D::Int=0, s::Int=1)
    series = TimeArray(timestamp(series),values(series))
    if D > 0
        @info("Seasonal difference")
        diff_values = []
        original_values = values(series)
        T = length(original_values)
        for i=1:D
            # Δyₜ = yₜ - y_t-s
            for j=i*s+1:T
                push!(diff_values, original_values[j] - original_values[j-i*s])
            end
        end
        series = TimeArray(copy(timestamp(series))[(D*s)+1:end],diff_values)
    end
    # non seasonal diff y
    @info("Non seasonal difference")
    for _ in 1:d
        diff_values = []
        original_values = values(series)
        T = length(original_values)
        # Δyₜ = yₜ - y_t-1
        for j=2:T
            push!(diff_values,original_values[j] - original_values[j-1])
        end
        series = TimeArray(copy(timestamp(series))[2:end],diff_values)
    end
    return series
end

function integrate(series::TimeArray, diff_series::Vector{Fl}, d::Int=0, D::Int=0, s::Int=1) where Fl<:Real
    series = TimeArray(timestamp(series),values(series))
    stepsAhead = length(diff_series)
    y = deepcopy(values(series))
    T = length(y)
    y = vcat(y,diff_series)
    for i=T+1:T+stepsAhead
        # @info("Non seasonal integration")
        recovered_value = y[i]
        # Δyt = y[t] - y[t-1] - y[t-12] + y[t-12-1]
        for _ in 1:d
            # Δyₜ = yₜ - y_t-1 ⇒ yₜ = Δyₜ + y_t-1
            recovered_value += y[i-1]
        end
        # @info("Seasonal integration")
        for _ in 1:D
            # Δyₜ = yₜ - y_t-s ⇒ yₜ = Δyₜ + y_t-s
            recovered_value += y[i-s]
        end
        # @info("Correction for seasonal integration")
        if D > 0 && d > 0
            # Δyₜ = yₜ - y_t-s ⇒ yₜ = Δyₜ + y_t-s
            recovered_value -= y[i-s-1]
        end
        y[i] = recovered_value
    end
    
    return y[T+1:end]
end