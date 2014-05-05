/**
 * User: booster
 * Date: 04/05/14
 * Time: 10:19
 */
package starling.renderer {
import flash.display3D.Context3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Point;

import starling.utils.MatrixUtil;

use namespace renderer_internal;

public class GeometryData {
    private static var _helperPoint:Point               = new Point();

    private var _vertexFormat:VertexFormat              = null;

    private var _buffersDirty:Boolean                   = true;

    renderer_internal var vertexBuffer:VertexBuffer3D   = null;
    renderer_internal var indexBuffer:IndexBuffer3D     = null;

    renderer_internal var vertexRawData:Vector.<Number> = new <Number>[];
    renderer_internal var triangleData:Vector.<uint>    = new <uint>[];

    public function GeometryData(vertexFormat:VertexFormat) {
        _vertexFormat = vertexFormat;
    }

    public function get vertexFormat():VertexFormat { return _vertexFormat; }

    /** Number of registered vertices. */
    public function get vertexCount():int { return vertexRawData.length / _vertexFormat.totalSize; }

    public function dispose():void {
        if(vertexBuffer != null) vertexBuffer.dispose();
        if(indexBuffer != null) indexBuffer.dispose();
    }

    /**
     * Creates new vertex- and index-buffers and uploads our vertex- and index-data into these buffers.
     *
     * @return true if there's any geometry to be rendered, false otherwise
     * */
    renderer_internal function createBuffers(context:Context3D):Boolean {
        // can't create and upload an empty buffer
        if(vertexRawData.length == 0 || triangleData.length == 0)
            return false;

        // no need to refresh buffers
        if(! _buffersDirty)
            return true;

        _buffersDirty = false;

        if (vertexBuffer) vertexBuffer.dispose();
        if (indexBuffer)  indexBuffer.dispose();

        vertexBuffer = context.createVertexBuffer(vertexCount, _vertexFormat.totalSize);
        vertexBuffer.uploadFromVector(vertexRawData, 0, vertexCount);

        indexBuffer = context.createIndexBuffer(triangleData.length);
        indexBuffer.uploadFromVector(triangleData, 0, triangleData.length);

        return true;
    }

    renderer_internal function setVertexBuffers(context:Context3D):void {
        var count:int = _vertexFormat.propertyCount;
        for(var i:int = 0; i < count; i++) {
            var size:int    = _vertexFormat.getSize(i);
            var offset:int  = _vertexFormat.getOffset(i);

            var bufferFormat:String;

            switch(size) {
                case 1: bufferFormat = Context3DVertexBufferFormat.FLOAT_1; break;
                case 2: bufferFormat = Context3DVertexBufferFormat.FLOAT_2; break;
                case 3: bufferFormat = Context3DVertexBufferFormat.FLOAT_3; break;
                case 4: bufferFormat = Context3DVertexBufferFormat.FLOAT_4; break;

                default:
                    throw new Error("vertex data size invalid (" + size + ") for data index: " + i);
            }

            context.setVertexBufferAt(i, vertexBuffer, offset, bufferFormat);
        }
    }

    renderer_internal function unsetVertexBuffers(context:Context3D):void {
        var count:int = _vertexFormat.propertyCount;
        for(var i:int = 0; i < count; i++)
            context.setVertexBufferAt(i, null);
    }

    /**
     * Adds a number of vertices to this renderer and returns the first index added.
     * These vertices are not yet part of any geometry - call addTriangle() and pass vertex indexes to build
     * geometry segments.
     */
    renderer_internal function addVertices(count:int):int {
        _buffersDirty = true;

        var firstIndex:int      = vertexCount;
        vertexRawData.length  += _vertexFormat.totalSize * count;

        return firstIndex;
    }

    /** Adds a new triangle out of registered vertices. */
    renderer_internal function addTriangle(v1:int, v2:int, v3:int):void {
        _buffersDirty = true;

        triangleData[triangleData.length] = v1;
        triangleData[triangleData.length] = v2;
        triangleData[triangleData.length] = v3;
    }

    /**
     * Returns vertex data associated with a given vertex.
     *
     * @param vertex    vertex index
     * @param id        data id ('va' register index), @see VertexFormat
     * @param data      optional vector to hold up to 4 Numbers representing the data
     * @return          vector holding the vertex data
     */
    renderer_internal function getVertexData(vertex:int, id:int, data:Vector.<Number> = null):Vector.<Number> {
        var index:int   = _vertexFormat.totalSize * vertex + _vertexFormat.getOffset(id);
        var size:int    = _vertexFormat.getSize(id);

        if(data == null) data = new Vector.<Number>(size);

        for(var i:int = 0; i < size; ++i)
            data[i] = vertexRawData[index + i];

        return data;
    }

    /**
     * Sets data associated with the given vertex.
     * Keep in mind only as many components will be used, as required by the VertexFormat set.
     *
     * @param vertex    vertex index
     * @param id        data id ('va' register index), @see VertexFormat
     * @param x         first component value
     * @param y         second component value
     * @param z         third component value
     * @param w         fourth component value
     */
    renderer_internal function setVertexData(vertex:int, id:int, x:Number, y:Number = NaN, z:Number = NaN, w:Number = NaN):void {
        var index:int   = _vertexFormat.totalSize * vertex + _vertexFormat.getOffset(id);
        var size:int    = _vertexFormat.getSize(id);

        //noinspection FallthroughInSwitchStatementJS
        switch(size) {
            case 4: if(vertexRawData[index + 3] != w) { _buffersDirty = true; vertexRawData[index + 3] = w; }
            case 3: if(vertexRawData[index + 2] != z) { _buffersDirty = true; vertexRawData[index + 2] = z; }
            case 2: if(vertexRawData[index + 1] != y) { _buffersDirty = true; vertexRawData[index + 1] = y; }
            case 1: if(vertexRawData[index    ] != x) { _buffersDirty = true; vertexRawData[index    ] = x; }
                break;

            default:
                throw new Error("vertex data size invalid (" + size + "for vertex: " + vertex + ", data id: " + id);
        }
    }

    renderer_internal function appendVertexData(vertex:int, output:Vector.<Number>, matrix:Matrix = null):void {
        var vertexSize:int      = _vertexFormat.totalSize;
        var offset:int          = vertexSize * vertex;
        var currentLength:int   = output.length;

        for(var i:int = 0; i < vertexSize; i++)
            output[currentLength + i] = vertexRawData[offset + i];
    }

    /**
     * Appends another geometry data to this geometry data.
     *
     * @param geometry geometry data to append
     * @param matrix transformation matrix for appended geometry, @default null
     * @param positionID position attribute index of appended geometry (to use with matrix)
     */
    renderer_internal function append(geometry:GeometryData, matrix:Matrix = null, positionID:int = 0):void {
        if(! _vertexFormat.isCompatible(geometry._vertexFormat))
            throw new ArgumentError("geometries' formats are not compatible");

        _buffersDirty = true;

        var firstNewVertex:int      = vertexCount;
        var firstNewTriangle:int    = triangleData.length;

        var count:int = geometry.vertexCount;
        for(var i:int = 0; i < count; i++)
            geometry.appendVertexData(i, vertexRawData, matrix);

        count = geometry.triangleData.length;
        for(i = 0; i < count; i++)
            triangleData[firstNewTriangle + i] = geometry.triangleData[i] + firstNewVertex;
    }

    /**
     * Clears this geometry.
     */
    renderer_internal function clear():void {
        _buffersDirty = true;
        vertexRawData.length = 0;
        triangleData.length = 0;
    }
}
}
