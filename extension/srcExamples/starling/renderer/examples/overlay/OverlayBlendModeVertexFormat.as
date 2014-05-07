/**
 * User: booster
 * Date: 04/05/14
 * Time: 12:09
 */
package starling.renderer.examples.overlay {
import starling.renderer.vertex.VertexFormat;

public class OverlayBlendModeVertexFormat extends VertexFormat {
    public static const cachedInstance:OverlayBlendModeVertexFormat = new OverlayBlendModeVertexFormat();

    public static const TOP_UV:String       = "uvTop";
    public static const BOTTOM_UV:String    = "uvBottom";

    // fast access members
    public var uvTopID:int, uvBottomID:int;

    public function OverlayBlendModeVertexFormat() {
        if(cachedInstance != null)
            throw new Error("don't create a new instance, use 'OverlayBlendModeVertexFormat.cachedInstance' instead");

        uvTopID     = addProperty(TOP_UV, 2);    // u, v; id: 1
        uvBottomID  = addProperty(BOTTOM_UV, 2); // u, v; id: 2
    }
}
}
