/**
 * User: booster
 * Date: 04/05/14
 * Time: 12:58
 */
package starling.renderer.examples.textured {
import starling.renderer.geometry.GeometryData;

public class TexturedGeometryData extends GeometryData {
    public function TexturedGeometryData() {
        super(TexturedGeometryVertexFormat.cachedInstance);
    }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.positionID, x, y); }

    public function getVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.uvID, uv); }
    public function setVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.uvID, u, v); }
}
}
