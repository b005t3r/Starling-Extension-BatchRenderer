/**
 * User: booster
 * Date: 04/05/14
 * Time: 12:46
 */
package starling.renderer.examples.colored {
import flash.geom.Matrix;
import flash.geom.Point;

import starling.renderer.GeometryData;
import starling.renderer.renderer_internal;
import starling.utils.MatrixUtil;

use namespace renderer_internal;

public class ColoredGeometryData extends GeometryData {
    private static var _helperPoint:Point = new Point();

    public function ColoredGeometryData() {
        super(ColoredGeometryVertexFormat.cachedInstance);
    }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, ColoredGeometryVertexFormat.cachedInstance.positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, ColoredGeometryVertexFormat.cachedInstance.positionID, x, y); }

    public function getVertexColor(vertex:int, color:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, ColoredGeometryVertexFormat.cachedInstance.colorID, color); }
    public function setVertexColor(vertex:int, r:Number, g:Number, b:Number, a:Number):void { setVertexData(vertex, ColoredGeometryVertexFormat.cachedInstance.colorID, r, g, b, a); }

    override renderer_internal function appendVertexData(vertex:int, output:Vector.<Number>, matrix:Matrix = null):void {
        if(matrix == null)
            super.appendVertexData(vertex, output);

        var vertexSize:int      = vertexFormat.totalSize;
        var offset:int          = vertexSize * vertex;
        var currentLength:int   = output.length;

        var positionIndex:int   = vertexFormat.getOffset(ColoredGeometryVertexFormat.cachedInstance.positionID);

        for(var i:int = 0; i < vertexSize; i++) {
            if(i == positionIndex) {
                var x:Number            = vertexRawData[offset + i];
                var y:Number            = vertexRawData[offset + i + 1];
                var newPosition:Point   = MatrixUtil.transformCoords(matrix, x, y, _helperPoint);

                output[currentLength + i]       = newPosition.x;
                output[currentLength + i + 1]   = newPosition.y;

                ++i;
            }
            else {
                output[currentLength + i] = vertexRawData[offset + i];
            }
        }
    }
}
}
