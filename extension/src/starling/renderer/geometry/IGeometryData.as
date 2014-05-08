/**
 * User: booster
 * Date: 06/05/14
 * Time: 12:48
 */
package starling.renderer.geometry {
import flash.geom.Matrix;

import starling.renderer.vertex.VertexFormat;

public interface IGeometryData {

    /** Vertex format used by this geometry. */
    function get vertexFormat():VertexFormat

    /**
     * Adds a number of vertices to this renderer and returns the first index added.
     * These vertices are not yet part of any geometry - call addTriangle() and pass vertex indexes to build
     * geometry segments.
     */
    function addVertices(count:int):int

    /** Number of vertices in this geometry. */
    function get vertexCount():int

    /**
     * Returns vertex data associated with a given vertex.
     *
     * @param vertex    vertex index
     * @param id        data id ('va' register index), @see VertexFormat
     * @param data      optional vector to hold up to 4 Numbers representing the data
     * @return          vector holding the vertex data
     */
    function getVertexData(vertex:int, id:int, data:Vector.<Number> = null):Vector.<Number>

    /**
     * Sets data associated with the given vertex.
     *
     * @param vertex    vertex index
     * @param id        data id ('va' register index), @see VertexFormat
     * @param x         first component value
     * @param y         second component value
     * @param z         third component value
     * @param w         fourth component value
     */
    function setVertexData(vertex:int, id:int, x:Number, y:Number = NaN, z:Number = NaN, w:Number = NaN):void

    /**
     * Returns vertex data component associated with a given vertex.
     *
     * @param vertex    vertex index
     * @param id        data id ('va' register index), @see VertexFormat
     * @param component index of component to retrieve (0 to 3)
     * @return value stored in the give vertex data component
     */
    function getVertexDataComponent(vertex:int, id:int, component:int):Number

    /**
     * Sets data component associated with the given vertex.
     *
     * @param vertex    vertex index
     * @param id        data id ('va' register index), @see VertexFormat
     * @param component index of component to set (0 to 3)
     * @param value     value to set the component to
     */
    function setVertexDataComponent(vertex:int, id:int, component:int, value:Number):void

    /**
     * Uploads vertex data into given output buffer.
     * Implementations may check the data already in the buffer and override only the one
     * which needs to be overridden. If none has changed, false should be returned to signalize
     * such situation (used for optimization purposes).
     *
     * @param buffer        buffer to upload data to
     * @param startIndex    first index in the buffer to be override with new data
     * @return true if data in the buffer has changed, false otherwise
     */
    function uploadVertexData(buffer:Vector.<Number>, startIndex:int, matrix:Matrix = null):Boolean

    /** Adds a new triangle out of registered vertices. */
    function addTriangle(v1:int, v2:int, v3:int):void

    /** Number of triangles this geometry holds. */
    function get triangleCount():int

    /**
     * Uploads triangle data to given output buffer. @see uploadVertexData()
     *
     * @param buffer        buffer to upload data to
     * @param startIndex    first index in the buffer to be override with new data
     * @param firstVertexID before uploading all triangles' vertices should be readjusted using this ID
     * @return true if data in the buffer has changed, false otherwise
     */
    function uploadTriangleData(buffer:Vector.<uint>, startIndex:int, firstVertexID:int):Boolean
}
}
