/**
 * User: booster
 * Date: 04/05/14
 * Time: 12:16
 */
package starling.renderer.examples.overlay {
import flash.geom.Matrix;
import flash.geom.Point;

import starling.renderer.GeometryData;
import starling.renderer.renderer_internal;
import starling.utils.MatrixUtil;

use namespace renderer_internal;

public class OverlayBlendModeGeometryData extends GeometryData {
    private var _helperPoint:Point = new Point();

    public function OverlayBlendModeGeometryData() {
        super(OverlayBlendModeVertexFormat.cachedInstance);
    }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return  getVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.positionID, x, y); }

    public function getTopLayerVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.uvTopID, uv); }
    public function setTopLayerVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.uvTopID, u, v); }

    public function getBottomLayerVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.uvBottomID, uv); }
    public function setBottomLayerVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.uvBottomID, u, v); }

    override renderer_internal function appendVertexData(vertex:int, output:Vector.<Number>, matrix:Matrix = null):void {
        if(matrix == null)
            super.appendVertexData(vertex, output);

        var vertexSize:int      = vertexFormat.totalSize;
        var offset:int          = vertexSize * vertex;
        var currentLength:int   = output.length;

        var positionIndex:int   = vertexFormat.getOffset(OverlayBlendModeVertexFormat.cachedInstance.positionID);

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
