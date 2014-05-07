/**
 * User: booster
 * Date: 04/05/14
 * Time: 12:16
 */
package starling.renderer.examples.overlay {
import starling.renderer.geometry.GeometryData;

public class OverlayBlendModeGeometryData extends GeometryData {
    public function OverlayBlendModeGeometryData() {
        super(OverlayBlendModeVertexFormat.cachedInstance);
    }

    public function getTopLayerVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.uvTopID, uv); }
    public function setTopLayerVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.uvTopID, u, v); }

    public function getBottomLayerVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.uvBottomID, uv); }
    public function setBottomLayerVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, OverlayBlendModeVertexFormat.cachedInstance.uvBottomID, u, v); }
}
}
