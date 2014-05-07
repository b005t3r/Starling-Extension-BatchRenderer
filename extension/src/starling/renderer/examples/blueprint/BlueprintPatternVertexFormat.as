/**
 * User: booster
 * Date: 04/05/14
 * Time: 11:12
 */
package starling.renderer.examples.blueprint {
import starling.renderer.VertexFormat;

public class BlueprintPatternVertexFormat extends VertexFormat {
    public static const cachedInstance:BlueprintPatternVertexFormat = new BlueprintPatternVertexFormat();

    public static const BOUNDS:String           = "bounds";
    public static const BACKGROUND_COLOR:String = "backgroundColor";
    public static const BORDER_COLOR:String     = "borderColor";
    public static const MARK_COLOR:String       = "markColor";
    public static const LINE_SIZES:String       = "lineSizes";

    // fast access members
    public var boundsID:int, backgroundColorID:int, borderColorID:int, markColorID:int, lineSizesID:int;

    public function BlueprintPatternVertexFormat() {
        if(cachedInstance != null)
            throw new Error("don't create a new instance, use 'BlueprintPatternVertexFormat.cachedInstance' instead");

        boundsID            = addProperty(BOUNDS, 4);            // minX, maxX, minY, maxY; id: 1
        backgroundColorID   = addProperty(BACKGROUND_COLOR, 4);  // r, g, b, a; id: 2
        borderColorID       = addProperty(BORDER_COLOR, 4);      // r, g, b, a; id: 3
        markColorID         = addProperty(MARK_COLOR, 4);        // r, g, b, a; id: 4
        lineSizesID         = addProperty(LINE_SIZES, 4);         // borderWidth, markWidth, markLength, markSpacing; id: 5
    }
}
}
