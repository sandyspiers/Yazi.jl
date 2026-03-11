using Test
using TOML
using Yazi

@testset "Yazi.jl" begin
    @testset "binary exists and is exectable" begin
        bin = yazi_bin()
        @test isfile(bin)
        @test Sys.isexecutable(bin)
    end

    @testset "version matches" begin
        project_toml = TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
        yazi_version = project_toml["yazi"]["version"]
        out = readchomp(`$(yazi_bin()) --version`)
        @test startswith(lowercase(out), "yazi")
        @test contains(out, yazi_version)
    end
end
