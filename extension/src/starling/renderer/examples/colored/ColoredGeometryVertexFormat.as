/**
 * User: booster
 * Date: 04/05/14
 * Time: 12:41
 */
package starling.renderer.examples.colored {
import starling.renderer.VertexFormat;

public class ColoredGeometryVertexFormat extends VertexFormat {
    public static const cachedInstance:ColoredGeometryVertexFormat = new ColoredGeometryVertexFormat();

    public static const POSITION:String = "position";
    public static const COLOR:String    = "color";

    // fast access members
    public var positionID:int, colorID:int;

    public function ColoredGeometryVertexFormat() {
        if(cachedInstance != null)
            throw new Error("don't create a new instance, use 'ColoredGeometryVertexFormat.cachedInstance' instead");

        positionID  = addProperty(POSITION, 2);    // x, y;        id: 0
        colorID     = addProperty(COLOR, 4);       // r, g, b, a;  id: 1
    }
}
}
