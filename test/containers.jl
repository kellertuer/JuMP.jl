#  Copyright 2017, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

using JuMP
using Test

macro dummycontainer(expr, requestedtype)
    name = gensym()
    refcall, indexvars, indexsets, condition = JuMP.buildrefsets(expr, name)
    if condition == :()
        return JuMP.generatecontainer(Bool, indexvars, indexsets, requestedtype)[1]
    else
        if requestedtype != :Auto && requestedtype != :SparseAxisArray
            return :(error(""))
        end
        return JuMP.generatecontainer(Bool, indexvars, indexsets,
                                      :SparseAxisArray)[1]
    end
end

function containermatches(c1::AbstractArray,c2::AbstractArray)
    return typeof(c1) == typeof(c2) && size(c1) == size(c2)
end

function containermatches(c1::JuMPArray,c2::JuMPArray)
    return typeof(c1) == typeof(c2) && axes(c1) == axes(c2)
end

function containermatches(c1::JuMP.Containers.SparseAxisArray,
                          c2::JuMP.Containers.SparseAxisArray)
    return eltype(c1) == eltype(c2)
end
containermatches(c1, c2) = false

@testset "Container syntax" begin
    @test containermatches(@dummycontainer([i=1:10], Auto), Vector{Bool}(undef,10))
    @test containermatches(@dummycontainer([i=1:10], Array), Vector{Bool}(undef,10))
    @test containermatches(@dummycontainer([i=1:10], JuMPArray), JuMPArray(Vector{Bool}(undef,10), 1:10))
    @test containermatches(@dummycontainer([i=1:10], SparseAxisArray),
                           JuMP.Containers.SparseAxisArray(Dict{Tuple{Any},Bool}()))

    @test containermatches(@dummycontainer([i=1:10,1:2], Auto), Matrix{Bool}(undef,10,2))
    @test containermatches(@dummycontainer([i=1:10,1:2], Array), Matrix{Bool}(undef,10,2))
    @test containermatches(@dummycontainer([i=1:10,n=1:2], JuMPArray), JuMPArray(Matrix{Bool}(undef,10,2), 1:10, 1:2))
    @test containermatches(@dummycontainer([i=1:10,1:2], SparseAxisArray),
                           JuMP.Containers.SparseAxisArray(Dict{NTuple{2,Any},Bool}()))

    @test containermatches(@dummycontainer([i=1:10,n=2:3], Auto), JuMPArray(Matrix{Bool}(undef,10,2), 1:10, 2:3))
    @test_throws ErrorException @dummycontainer([i=1:10,2:3], Array)
    @test containermatches(@dummycontainer([i=1:10,n=2:3], JuMPArray), JuMPArray(Matrix{Bool}(undef,10,2), 1:10, 2:3))
    @test containermatches(@dummycontainer([i=1:10,n=2:3], SparseAxisArray),
                           JuMP.Containers.SparseAxisArray(Dict{NTuple{2,Any},Bool}()))


    S = Base.OneTo(10)
    @test containermatches(@dummycontainer([i=S], Auto), Vector{Bool}(undef,10))
    @test containermatches(@dummycontainer([i=S], Array), Vector{Bool}(undef,10))
    @test containermatches(@dummycontainer([i=S], JuMPArray), JuMPArray(Vector{Bool}(undef,10), S))
    @test containermatches(@dummycontainer([i=S], SparseAxisArray),
                           JuMP.Containers.SparseAxisArray(Dict{Tuple{Any},Bool}()))

    @test containermatches(@dummycontainer([i=S,1:2], Auto), Matrix{Bool}(undef,10,2))
    @test containermatches(@dummycontainer([i=S,1:2], Array), Matrix{Bool}(undef,10,2))
    @test containermatches(@dummycontainer([i=S,n=1:2], JuMPArray), JuMPArray(Matrix{Bool}(undef,10,2), S, 1:2))
    @test containermatches(@dummycontainer([i=S,1:2], SparseAxisArray),
                           JuMP.Containers.SparseAxisArray(Dict{NTuple{2,Any},Bool}()))

    S = 1:10
    # Not type stable to return an Array by default even when S is one-based interval
    @test containermatches(@dummycontainer([i=S], Auto), JuMPArray(Vector{Bool}(undef,10), S))
    @test containermatches(@dummycontainer([i=S], Array), Vector{Bool}(undef,10))
    @test containermatches(@dummycontainer([i=S], JuMPArray), JuMPArray(Vector{Bool}(undef,10), S))
    @test containermatches(@dummycontainer([i=S], SparseAxisArray),
                           JuMP.Containers.SparseAxisArray(Dict{Tuple{Any},Bool}()))

    @test containermatches(@dummycontainer([i=S,n=1:2], Auto), JuMPArray(Matrix{Bool}(undef,10,2), S, 1:2))
    @test containermatches(@dummycontainer([i=S,1:2], Array), Matrix{Bool}(undef,10,2))
    @test containermatches(@dummycontainer([i=S,n=1:2], JuMPArray), JuMPArray(Matrix{Bool}(undef,10,2), S, 1:2))
    @test containermatches(@dummycontainer([i=S,1:2], SparseAxisArray),
                           JuMP.Containers.SparseAxisArray(Dict{NTuple{2,Any},Bool}()))

    # TODO: test case where S is index set not supported by JuMPArrays (does this exist?)

    # Conditions
    @test containermatches(@dummycontainer([i=1:10; iseven(i)], Auto),
                           JuMP.Containers.SparseAxisArray(Dict{Tuple{Any},Bool}()))
    @test_throws ErrorException @dummycontainer([i=1:10; iseven(i)], Array)
    @test_throws ErrorException @dummycontainer([i=1:10; iseven(i)], JuMPArray)
    @test containermatches(@dummycontainer([i=1:10; iseven(i)], SparseAxisArray),
                           JuMP.Containers.SparseAxisArray(Dict{Tuple{Any},Bool}()))

    # Dependent axes
    @test containermatches(@dummycontainer([i=1:10, j=1:i], Auto),
                           JuMP.Containers.SparseAxisArray(Dict{NTuple{2,Any},Bool}()))
    @test_throws ErrorException @dummycontainer([i=1:10, j=1:i], Array)
    @test_throws ErrorException @dummycontainer([i=1:10, j=1:i], JuMPArray)
    @test containermatches(@dummycontainer([i=1:10, j=1:i], SparseAxisArray),
                           JuMP.Containers.SparseAxisArray(Dict{NTuple{2,Any},Bool}()))

end

@testset "JuMPArray" begin
    @testset "undef constructor" begin
        A = @inferred JuMPArray{Int}(undef, [:a, :b], 1:2)
        A[:a, 1] = 1
        A[:b, 1] = 2
        A[:a, 2] = 3
        A[:b, 2] = 4
        @test A[:a, 1] == 1
        @test A[:b, 1] == 2
        @test A[:a, 2] == 3
        @test A[:b, 2] == 4
    end

    @testset "Range index set" begin
        A = @inferred JuMPArray([1.0,2.0], 2:3)
        @test size(A) == (2,)
        @test size(A, 1) == 2
        @test @inferred A[2] == 1.0
        @test A[3] == 2.0
        @test A[2,1] == 1.0
        @test A[3,1,1,1,1] == 2.0
        @test isassigned(A, 2)
        @test !isassigned(A, 1)
        @test length.(axes(A)) == (2,)
        plus1(x) = x + 1
        B = plus1.(A)
        @test B[2] == 2.0
        @test B[3] == 3.0
        @test sprint(show, B) == """
1-dimensional JuMPArray{Float64,1,...} with index sets:
    Dimension 1, 2:3
And data, a 2-element Array{Float64,1}:
 2.0
 3.0"""
    end

    @testset "Symbol index set" begin
        A = @inferred JuMPArray([1.0,2.0], [:a, :b])
        @test size(A) == (2,)
        @test size(A, 1) == 2
        @test @inferred A[:a] == 1.0
        @test A[:b] == 2.0
        @test length.(axes(A)) == (2,)
        plus1(x) = x + 1
        B = plus1.(A)
        @test B[:a] == 2.0
        @test B[:b] == 3.0
        @test sprint(show, B) == """
1-dimensional JuMPArray{Float64,1,...} with index sets:
    Dimension 1, Symbol[:a, :b]
And data, a 2-element Array{Float64,1}:
 2.0
 3.0"""
    end

    @testset "Mixed range/symbol index sets" begin
        A = @inferred JuMPArray([1 2; 3 4], 2:3, [:a, :b])
        @test size(A) == (2, 2)
        @test size(A, 1) == 2
        @test size(A, 2) == 2
        @test length.(axes(A)) == (2,2)
        @test @inferred A[2,:a] == 1
        @test A[3,:a] == 3
        @test A[2,:b] == 2
        @test A[3,:b] == 4
        @test A[2,:a,1] == 1
        @test A[2,:a,1,1] == 1
        @test A[3,:a,1,1,1] == 3
        @test @inferred A[:,:a] == JuMPArray([1,3], 2:3)
        @test A[2, :] == JuMPArray([1,2], [:a, :b])
        @test sprint(show, A) == """
2-dimensional JuMPArray{$Int,2,...} with index sets:
    Dimension 1, 2:3
    Dimension 2, Symbol[:a, :b]
And data, a 2×2 Array{$Int,2}:
 1  2
 3  4"""
    end

    @testset "4-dimensional JuMPArray" begin
        # TODO: This inference tests fails on 0.7. Investigate and fix.
        A = JuMPArray(zeros(2,2,2,2), 2:3, [:a, :b], -1:0, ["a","b"])
        @test size(A) == (2, 2, 2, 2)
        @test size(A, 1) == 2
        @test size(A, 2) == 2
        @test size(A, 3) == 2
        @test size(A, 4) == 2
        A[2,:a,-1,"a"] = 1.0
        f = 0.0
        for I in eachindex(A)
            f += A[I]
        end
        @test f == 1.0
        @test isassigned(A, 2, :a, -1, "a")
        @test A[:,:,-1,"a"] == JuMPArray([1.0 0.0; 0.0 0.0], 2:3, [:a,:b])
        @test_throws KeyError A[2,:a,-1,:a]
        @test sprint(show, A) == """
4-dimensional JuMPArray{Float64,4,...} with index sets:
    Dimension 1, 2:3
    Dimension 2, Symbol[:a, :b]
    Dimension 3, -1:0
    Dimension 4, ["a", "b"]
And data, a 2×2×2×2 Array{Float64,4}:
[:, :, -1, "a"] =
 1.0  0.0
 0.0  0.0

[:, :, 0, "a"] =
 0.0  0.0
 0.0  0.0

[:, :, -1, "b"] =
 0.0  0.0
 0.0  0.0

[:, :, 0, "b"] =
 0.0  0.0
 0.0  0.0"""
    end

    @testset "0-dimensional JuMPArray" begin
        a = Array{Int,0}(undef)
        a[] = 10
        A = JuMPArray(a)
        @test size(A) == tuple()
        @test A[] == 10
        A[] = 1
        @test sprint(show, A) == """
0-dimensional JuMPArray{$Int,0,...} with index sets:
And data, a 0-dimensional Array{$Int,0}:
1"""
    end

    @testset "JuMPArray keys" begin
        A = JuMPArray([5.0 6.0; 7.0 8.0], 2:3, [:a,:b])
        A_keys = collect(keys(A))
        @test A[A_keys[3]] == 6.0
        @test A[A_keys[4]] == 8.0
        @test A_keys[3][1] == 2
        @test A_keys[3][2] == :b
        @test A_keys[4][1] == 3
        @test A_keys[4][2] == :b

        B = JuMPArray([5.0 6.0; 7.0 8.0], 2:3, Set([:a,:b]))
        B_keys = keys(B)
        @test JuMP.JuMPArrayKey((2, :a)) in B_keys
        @test JuMP.JuMPArrayKey((2, :b)) in B_keys
        @test JuMP.JuMPArrayKey((3, :a)) in B_keys
        @test JuMP.JuMPArrayKey((3, :b)) in B_keys
    end
end
