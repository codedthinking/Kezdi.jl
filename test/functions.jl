@testset "Global df is modified" begin
    df = DataFrame(x=1:4)
    setdf(df)
    @keep @if x <= 3
    @test nrow(getdf()) == 3

    @drop @if x == 1
    @test nrow(getdf()) == 2

    @clear
    @test isnothing(getdf())
end

@testset "_describe" begin
    df = DataFrame(x=1:2, y=[1.0, 2.0], z=["a", "b"], s=[:a, :b])
    @testset for var in [:x, :y, :z, :s]
        table = Kezdi._describe(df, [var])
        @test table.variable == [var]
        @test table.eltype == [eltype(getproperty(df, var))]
    end
    table = Kezdi._describe(df)
    @test table.variable == [:x, :y, :z, :s]
    @test table.eltype == [Int64, Float64, String, Symbol]
    @testset "Union{Missing,T} is removed" begin
        df = DataFrame(x=[1, missing], y=[1.0, missing], z=["a", missing], s=[:a, missing])
        table = Kezdi._describe(df)
        @test table.variable == [:x, :y, :z, :s]
        @test table.eltype == [Int64, Float64, String, Symbol]
    end
end