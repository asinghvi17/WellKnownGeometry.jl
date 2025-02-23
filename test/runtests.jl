import WellKnownGeometry as WKG
import GeoFormatTypes as GFT
import GeoInterface as GI
using Test
import ArchGDAL

@testset "WellKnownGeometry.jl" begin

    coord = [1.1, 2.2]
    lcoord = [3.3, 4.4]
    ring = [[0.1, 0.2], [0.3, 0.4], [0.1, 0.2]]
    coords = [[coord, lcoord, coord], ring]

    for (type, geom) in (
        ("Point", ArchGDAL.createpoint(coord)),
        ("LineString", ArchGDAL.createlinestring([coord, lcoord])),
        ("Polygon", ArchGDAL.createpolygon(coords)),
        ("MultiPoint", ArchGDAL.createmultipoint([coord, lcoord])),
        ("MultiLineString", ArchGDAL.createmultilinestring([[coord, lcoord], [coord, lcoord]])),
        ("MultiPolygon", ArchGDAL.createmultipolygon([coords, coords])),
        ("Empty", ArchGDAL.createpoint()),
        ("Empty Multi", ArchGDAL.createmultipolygon())
    )
        @testset "$type" begin
            @testset "WKB" begin
                wkb = WKG.getwkb(geom)
                wkbc = ArchGDAL.toWKB(geom)
                @test length(GFT.val(wkb)) == length(wkbc)
                @test all(GFT.val(wkb) .== wkbc)
                ArchGDAL.fromWKB(GFT.val(wkb))
                @test all(GI.coordinates(wkb) .== GI.coordinates(geom))
            end
            @testset "WKT" begin
                wkt = WKG.getwkt(geom)
                wktc = ArchGDAL.toWKT(geom)
                @test GFT.val(wkt) == wktc
                # Test validity by reading it again
                ArchGDAL.fromWKT(GFT.val(wkt))
                if type !== "Empty"  # broken on ArchGDAL
                    @test all(GI.coordinates(wkt) .== GI.coordinates(geom))
                end
            end
        end
    end

    @testset "GeometryCollection" begin
        ArchGDAL.creategeomcollection() do collection
            for g in [
                ArchGDAL.createpoint(-122.23, 47.09),
                ArchGDAL.createlinestring([(-122.60, 47.14), (-122.48, 47.23)]),
            ]
                ArchGDAL.addgeom!(collection, g)
            end

            @testset "WKB" begin
                wkb = WKG.getwkb(collection)
                wkbc = ArchGDAL.toWKB(collection)
                @test length(GFT.val(wkb)) == length(wkbc)
                @test all(GFT.val(wkb) .== wkbc)
                collection = ArchGDAL.fromWKB(GFT.val(wkb))
                @test all(GI.coordinates(wkb) .== GI.coordinates(collection))
            end
            @testset "WKT" begin
                wkt = WKG.getwkt(collection)
                wktc = ArchGDAL.toWKT(collection)
                @test GFT.val(wkt) == wktc
                collection = ArchGDAL.fromWKT(GFT.val(wkt))
                @test all(GI.coordinates(wkt) .== GI.coordinates(collection))

            end
        end
    end

    @testset "GeoInterface" begin
        wkt = GFT.WellKnownText(GFT.Geom(), "wkt")
        wkb = GFT.WellKnownBinary(GFT.Geom(), [0x0])

        @test GI.isgeometry(wkt)
        @test GI.isgeometry(wkb)

        wkt = GFT.WellKnownText(GFT.Geom(), "POINT (30 10)")
        @test GI.testgeometry(wkt)
        @test GI.coordinates(wkt) == [30.0, 10.0]

        wkt = GFT.WellKnownText(GFT.Geom(), "LINESTRING (30.0 10.0, 10.0 30.0, 40.0 40.0)")
        @test GI.testgeometry(wkt)
        @test GI.coordinates(wkt) == [[30.0, 10.0], [10.0, 30.0], [40.0, 40.0]]
    end

    @testset "Number types" begin
        @test GFT.val(WKG.getwkb((1.0, 2.0))) == GFT.val(WKG.getwkb((1.0f0, 2.0f0)))
    end

    @testset "Oddities" begin
        # Without a space
        wkt = GFT.WellKnownText(GFT.Geom(), "POINT(30 10)")
        @test GI.testgeometry(wkt)
    end
end
