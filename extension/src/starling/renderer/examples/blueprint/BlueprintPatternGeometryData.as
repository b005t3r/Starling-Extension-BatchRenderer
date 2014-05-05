/**
 * User: booster
 * Date: 04/05/14
 * Time: 11:24
 */
package starling.renderer.examples.blueprint {
import flash.geom.Matrix;
import flash.geom.Point;

import starling.renderer.GeometryData;
import starling.renderer.renderer_internal;
import starling.utils.MatrixUtil;

use namespace renderer_internal;

public class BlueprintPatternGeometryData extends GeometryData {
    private static var _helperPoint:Point = new Point();

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

    override renderer_internal function appendVertexData(vertex:int, output:Vector.<Number>, matrix:Matrix = null):void {
        if(matrix == null)
            super.appendVertexData(vertex, output);

        var vertexSize:int      = vertexFormat.totalSize;
        var offset:int          = vertexSize * vertex;
        var currentLength:int   = output.length;

        var positionIndex:int   = vertexFormat.getOffset(BlueprintPatternVertexFormat.cachedInstance.positionID);
        var boundsIndex:int     = vertexFormat.getOffset(BlueprintPatternVertexFormat.cachedInstance.boundsID);

        for(var i:int = 0; i < vertexSize; i++) {
            if(i == positionIndex) {
                var x:Number            = vertexRawData[offset + i];
                var y:Number            = vertexRawData[offset + i + 1];
                var newPosition:Point   = MatrixUtil.transformCoords(matrix, x, y, _helperPoint);

                output[currentLength + i]       = newPosition.x;
                output[currentLength + i + 1]   = newPosition.y;

                ++i;
            }
            else if(i == boundsIndex) {
                output.length += 3;

                var minX:Number                 = vertexRawData[offset + i];
                var minY:Number                 = vertexRawData[offset + i + 2];
                var newMinPosition:Point        = MatrixUtil.transformCoords(matrix, minX, minY, _helperPoint);

                minX = newMinPosition.x;
                minY = newMinPosition.y;

                var maxX:Number                 = vertexRawData[offset + i + 1];
                var maxY:Number                 = vertexRawData[offset + i + 3];
                var newMaxPosition:Point        = MatrixUtil.transformCoords(matrix, maxX, maxY, _helperPoint);

                maxX = newMaxPosition.x;
                maxY = newMaxPosition.y;

                if(minX < maxX) {
                    output[currentLength + i]       = minX;
                    output[currentLength + i + 2]   = maxX;
                }
                else {
                    output[currentLength + i]       = maxX;
                    output[currentLength + i + 2]   = minX;
                }

                if(minY < maxY) {
                    output[currentLength + i + 1]   = minY;
                    output[currentLength + i + 3]   = maxY;
                }
                else {
                    output[currentLength + i + 1]   = maxY;
                    output[currentLength + i + 3]   = minY;
                }

                i += 3;
            }
            else {
                output[currentLength + i] = vertexRawData[offset + i];
            }
        }
    }
}
}
