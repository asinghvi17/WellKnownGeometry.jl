"""
Well Known Text (WKT) represents `geometry` as nested text by:
- Displaying the geometry type if not known beforehand (e.g `POINT `)
- Brackets open (e.g. `(`)
- Any coordinates if the geometry type is a Point, seperated by a space (e.g `1.0 2.0`)
- Or another (sub)geometry in non-Point geometry types
- Brackets close (e.g `)`)

Knowing the type of subgeometries (and thus the SF type hierarchy) is required.
For example, because a Polygon always has rings (either exterior or interior ones),
the (sub)geometry type of those rings are skipped (LinearRing) and only brackets are added.
The opposite is true for a GeometryCollection, when the subgeometry types are not known beforehand.

A few examples

POINT (30 10)
LINESTRING (30 10, 30 10)
POLYGON (((35 10, 45 45, 15 40, 10 20, 35 10),
(20 30, 35 35, 30 20, 20 30)))
"""

# Map GeoInterface type traits directly to their WKT String representation
geometry_string(::GI.AbstractPointTrait) = "POINT "
geometry_string(::GI.AbstractLineStringTrait) = "LINESTRING "
geometry_string(::GI.AbstractPolygonTrait) = "POLYGON "
geometry_string(::GI.AbstractMultiPointTrait) = "MULTIPOINT "
geometry_string(::GI.AbstractMultiLineStringTrait) = "MULTILINESTRING "
geometry_string(::GI.AbstractMultiPolygonTrait) = "MULTIPOLYGON "
geometry_string(::GI.AbstractGeometryCollectionTrait) = "GEOMETRYCOLLECTION "

"""
    getwkt(geom)

Retrieve the Well Known Text (WKT) as `String` for a `geom` that implements the GeoInterface.
"""
function getwkt(geom)
    data = Char[]
    getwkt!(data, GI.geomtype(geom), geom, true)
    return String(data)
end

"""
Push WKT to `data` for a Pointlike `type` of `geom`.

`first` indicates whether we need to print the type with brackets--like POINT ( )--
in case this outer geometry or part of a geometrycollection.
"""
function getwkt!(data, type::GI.AbstractPointTrait, geom, first::Bool)
    first && append!(data, collect(geometry_string(type))...)
    if GI.isempty(geom)
        append!(data, collect("EMPTY"))
    else
        n = GI.ncoord(geom)
        first && push!(data, '(')
        for i in 1:n
            append!(data, collect(string(GI.getcoord(geom, i))))
            i != n && push!(data, ' ')  # Don't add a ` ` on the last item
        end
        first && push!(data, ')')
    end
end

"""
Push WKT to `data` for non Pointlike `type` of `geom`.

`first` indicates whether we need to print the type with brackets--like POLYGON ( )--
in case this outer geometry. `repeat` indicates whether sub geometries need to print their type, in case `geom` is
a geometrycollection.
"""
function _getwkt!(data, type, geom, first::Bool, repeat::Bool)
    first && append!(data, collect(geometry_string(type))...)
    if GI.isempty(geom)
        append!(data, collect("EMPTY"))
    else
        n = GI.ngeom(geom)
        push!(data, '(')
        for i in 1:n
            sgeom = GI.getgeom(geom, i)
            type = GI.geomtype(sgeom)
            getwkt!(data, type, sgeom, repeat)
            i != n && push!(data, ',')  # Don't add a , on the last item
        end
        push!(data, ')')
    end
end

function getwkt!(data, type::GI.AbstractGeometryTrait, geom, first::Bool)
    _getwkt!(data, type, geom, first, false)
end

function getwkt!(data, type::GI.GeometryCollectionTrait, geom, first::Bool)
    _getwkt!(data, type, geom, first, true)
end
