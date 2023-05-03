import SemioticOpt: f, name, postiterationhook

Base.@kwdef struct ConsoleLogger{F<:Function,I<:Integer} <: SemioticOpt.Logger
    name::String
    frequency::I
    f::F
end

name(h::ConsoleLogger) = h.name
f(h::ConsoleLogger) = h.f
frequency(h::ConsoleLogger) = h.frequency

function postiterationhook(
    ::SemioticOpt.RunAfterIteration,
    h::ConsoleLogger,
    a::SemioticOpt.OptAlgorithm,
    z::AbstractVector{T};
    locals...
) where {T<:Real}
    if locals[:i] % frequency(h) == 0
        v = f(h)(a; locals...)
        println("$(name(h)): $v")
    end
    return z
end
