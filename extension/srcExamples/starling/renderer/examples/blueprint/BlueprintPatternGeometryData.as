/**
 * User: booster
 * Date: 04/05/14
 * Time: 11:24
 */
package starling.renderer.examples.blueprint {
import flash.geom.Matrix;
import flash.geom.Point;

import starling.renderer.geometry.GeometryData;
import starling.utils.MatrixUtil;

public class BlueprintPatternGeometryData extends GeometryData {
    public function BlueprintPatternGeometryData() {
        super(BlueprintPatternVertexFormat.cachedInstance);
    }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, BlueprintPatternVertexFormat.cachedInstance.positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, BlueprintPatternVertexFormat.cachedInstance.positionID, x, y); }

    public function getGeometryBounds(vertex:int, bounds:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, BlueprintPatternVertexFormat.cachedInstance.boundsID, bounds); }
    public function setGeonetryBounds(vertex:int, numVertices:int, minX:Number, maxX:Number, minY:Number, maxY:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, BlueprintPatternVertexFormat.cachedInstance.boundsID, minX, maxX, minY, maxY);
    }

    public function getGeometryBackgroundColor(vertex:int, color:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, BlueprintPatternVertexFormat.cachedInstance.backgroundColorID, color); }
    public function setGeometryBackgroundColor(vertex:int, numVertices:int, r:Number, g:Number, b:Number, a:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, BlueprintPatternVertexFormat.cachedInstance.backgroundColorID, r, g, b, a);
    }

    public function getGeometryBorderColor(vertex:int, color:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, BlueprintPatternVertexFormat.cachedInstance.borderColorID, color); }
    public function setGeometryBorderColor(vertex:int, numVertices:int, r:Number, g:Number, b:Number, a:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, BlueprintPatternVertexFormat.cachedInstance.borderColorID, r, g, b, a);
    }

    public function getGeometryMarkColor(vertex:int, color:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, BlueprintPatternVertexFormat.cachedInstance.markColorID, color); }
    public function setGeometryMarkColor(vertex:int, numVertices:int, r:Number, g:Number, b:Number, a:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, BlueprintPatternVertexFormat.cachedInstance.markColorID, r, g, b, a);
    }

    public function getGeometryLineSizes(vertex:int, sizes:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, BlueprintPatternVertexFormat.cachedInstance.lineSizesID, sizes); }
    public function setGeometryLineSizes(vertex:int, numVertices:int, borderWidth:Number, markWidth:Number, markLength:Number, markSpacing:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, BlueprintPatternVertexFormat.cachedInstance.lineSizesID, borderWidth, markWidth, markLength, markSpacing);
    }

    override public function uploadVertexData(buffer:Vector.<Number>, startIndex:int, matrix:Matrix = null):Boolean {
        var bufferChanged:Boolean = false;

        const vertexSize:int    = _vertexFormat.totalSize;
        const boundsOffset:int  = _vertexFormat.getOffset(BlueprintPatternVertexFormat.cachedInstance.boundsID);

        var count:int = _vertexRawData.length;
        for(var i:int = 0, j:int = startIndex; i < count; i++, j++) {
            // transform position - first and second component of each vertex
            if(matrix != null && ((i % vertexSize) == 0)) {
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
            else if(matrix != null && ((i % vertexSize) == boundsOffset)) {
                var minX:Number     = _vertexRawData[i];
                var maxX:Number     = _vertexRawData[i + 1];
                var minY:Number     = _vertexRawData[i + 2];
                var maxY:Number     = _vertexRawData[i + 3];

                var newMin:Point    = MatrixUtil.transformCoords(matrix, minX, minY, _helperPoint);
                minX                = newMin.x;
                minY                = newMin.y;

                var newMax:Point    = MatrixUtil.transformCoords(matrix, maxX, maxY, _helperPoint);
                maxX                = newMax.x;
                maxY                = newMax.y;

                var tmp:Number;

                if(minX > maxX) { tmp = minX; minX = maxX; maxX = tmp; }
                if(minY > maxY) { tmp = minY; minY = maxY; maxY = tmp; }

                if(buffer[j] != minX) {
                    buffer[j] = minX;
                    bufferChanged = true;
                }

                ++j;

                if(buffer[j] != maxX) {
                    buffer[j] = maxX;
                    bufferChanged = true;
                }

                ++j;

                if(buffer[j] != minY) {
                    buffer[j] = minY;
                    bufferChanged = true;
                }

                ++j;

                if(buffer[j] != maxY) {
                    buffer[j] = maxY;
                    bufferChanged = true;
                }

                i += 3;
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
}
}
