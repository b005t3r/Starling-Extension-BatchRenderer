/**
 * User: booster
 * Date: 04/05/14
 * Time: 12:54
 */
package starling.renderer.examples.textured {
import starling.renderer.vertex.VertexFormat;

public class TexturedGeometryVertexFormat extends VertexFormat {
    public static const cachedInstance:TexturedGeometryVertexFormat = new TexturedGeometryVertexFormat();

    public static const UV:String = "uv";

    public var uvID:int;

    public function TexturedGeometryVertexFormat() {
        if(cachedInstance != null)
            throw new Error("don't create a new instance, use 'TexturedGeometryVertexFormat.cachedInstance' instead");

        uvID = addProperty(UV, 2);        // u, v; id: 1
    }
}
}
