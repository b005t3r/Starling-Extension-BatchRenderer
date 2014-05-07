/**
 * User: booster
 * Date: 04/05/14
 * Time: 10:19
 */
package starling.renderer.geometry {
import flash.geom.Matrix;
import flash.geom.Point;

import starling.renderer.vertex.VertexFormat;
import starling.utils.MatrixUtil;

public class GeometryData implements IGeometryData {
    protected static const _helperPoint:Point       = new Point();

    protected var _vertexFormat:VertexFormat        = null;

    protected var _vertexRawData:Vector.<Number>    = new <Number>[];
    protected var _triangleData:Vector.<uint>       = new <uint>[];

    public function GeometryData(vertexFormat:VertexFormat) {
        _vertexFormat = vertexFormat;
    }

    public function get vertexFormat():VertexFormat { return _vertexFormat; }

    public function get vertexCount():int { return _vertexRawData.length / _vertexFormat.totalSize; }

    public function addVertices(count:int):int {
        var firstIndex:int      = vertexCount;
        _vertexRawData.length  += _vertexFormat.totalSize * count;

        return firstIndex;
    }

    public function getVertexData(vertex:int, id:int, data:Vector.<Number> = null):Vector.<Number> {
        var index:int   = _vertexFormat.totalSize * vertex + _vertexFormat.getOffset(id);
        var size:int    = _vertexFormat.getSize(id);

        if(data == null) data = new Vector.<Number>(size);

        for(var i:int = 0; i < size; ++i)
            data[i] = _vertexRawData[index + i];

        return data;
    }

    public function setVertexData(vertex:int, id:int, x:Number, y:Number = NaN, z:Number = NaN, w:Number = NaN):void {
        var index:int   = _vertexFormat.totalSize * vertex + _vertexFormat.getOffset(id);
        var size:int    = _vertexFormat.getSize(id);

        //noinspection FallthroughInSwitchStatementJS
        switch(size) {
            case 4: if(_vertexRawData[index + 3] != w) _vertexRawData[index + 3] = w;
            case 3: if(_vertexRawData[index + 2] != z) _vertexRawData[index + 2] = z;
            case 2: if(_vertexRawData[index + 1] != y) _vertexRawData[index + 1] = y;
            case 1: if(_vertexRawData[index    ] != x) _vertexRawData[index    ] = x;
                break;

            default:
                throw new Error("vertex data size invalid (" + size + "for vertex: " + vertex + ", data id: " + id);
        }
    }

    public function getVertexDataComponent(vertex:int, id:int, component:int):Number {
        var index:int   = _vertexFormat.totalSize * vertex + _vertexFormat.getOffset(id);
        var size:int    = _vertexFormat.getSize(id);

        if(size <= component)
            throw ArgumentError("reaching for a non-existent data component, size: " + size + ", component: " + component);

        return _vertexRawData[index + component];
    }

    public function setVertexDataComponent(vertex:int, id:int, component:int, value:Number):void {
        var index:int   = _vertexFormat.totalSize * vertex + _vertexFormat.getOffset(id);
        var size:int    = _vertexFormat.getSize(id);

        if(size <= component)
            throw ArgumentError("trying to set a non-existent data component, size: " + size + ", component: " + component);

        _vertexRawData[index + component] = value;
    }

    public function uploadVertexData(buffer:Vector.<Number>, startIndex:int, matrix:Matrix = null):Boolean {
        var bufferChanged:Boolean = false;

        const vertexSize:int = _vertexFormat.totalSize;

        var count:int = _vertexRawData.length;
        for(var i:int = 0, j:int = startIndex; i < count; i++, j++) {
            // transform position - first and second component of each vertex
            if(matrix != null && ((i % vertexSize) < 2)) {
                var x:Number            = _vertexRawData[i];
                var y:Number            = _vertexRawData[i + 1];
                var newPosition:Point   = MatrixUtil.transformCoords(matrix, x, y, _helperPoint);

                if(buffer[j] != newPosition.x) {
                    buffer[j] = newPosition.x;
                    bufferChanged = true;
                }

                ++j;

                if(buffer[j] != newPosition.y) {
                    buffer[j] = newPosition.y;
                    bufferChanged = true;
                }

                ++i;
            }
            else {
                var dataComponent:Number = _vertexRawData[i];

                if(! bufferChanged) {
                    if(buffer[j] == dataComponent)
                        continue;

                    bufferChanged = true;
                }

                buffer[j] = dataComponent;
            }
        }

        return bufferChanged;
    }

    public function addTriangle(v1:int, v2:int, v3:int):void {
        _triangleData[_triangleData.length] = v1;
        _triangleData[_triangleData.length] = v2;
        _triangleData[_triangleData.length] = v3;
    }

    public function get triangleCount():int {
        return _triangleData.length / 3;
    }

    public function uploadTriangleData(buffer:Vector.<uint>, startIndex:int, firstVertexID:int):Boolean {
        var bufferChanged:Boolean = false;

        var count:int = _triangleData.length;
        for(var i:int = 0, j:int = startIndex; i < count; i++, j++) {
            var vertexID:Number = _triangleData[i] + firstVertexID;

            if(! bufferChanged) {
                if(buffer[j] == vertexID)
                    continue;

                bufferChanged = true;
            }

            buffer[j] = vertexID;
        }

        return bufferChanged;
    }
}
}
