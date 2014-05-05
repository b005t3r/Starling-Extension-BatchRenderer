/**
 * User: booster
 * Date: 04/05/14
 * Time: 12:58
 */
package starling.renderer.examples.textured {
import flash.geom.Matrix;
import flash.geom.Point;

import starling.renderer.GeometryData;
import starling.renderer.examples.colored.ColoredGeometryVertexFormat;
import starling.renderer.renderer_internal;
import starling.utils.MatrixUtil;

use namespace renderer_internal;

public class TexturedGeometryData extends GeometryData {
    private static var _helperPoint:Point = new Point();

    public function TexturedGeometryData() {
        super(TexturedGeometryVertexFormat.cachedInstance);
    }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.positionID, x, y); }

    public function getVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.uvID, uv); }
    public function setVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.uvID, u, v); }

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
