/**
 * User: booster
 * Date: 16/01/14
 * Time: 8:36
 */
package starling.renderer.examples.colored {
import com.barliesque.agal.IRegister;

import starling.renderer.*;

public class ColoredGeometryRenderer extends BatchRenderer {
    // shader variables
    private var color:IRegister = VARYING[0];

    public function ColoredGeometryRenderer() {
        super(ColoredGeometryVertexFormat.cachedInstance);
    }

    override protected function vertexShaderCode():void {
        multiply4x4(OUTPUT, getVertexAttribute(VertexFormat.POSITION), getRegisterConstant(PROJECTION_MATRIX));

        move(color, getVertexAttribute(ColoredGeometryVertexFormat.COLOR));
    }

    override protected function fragmentShaderCode():void {
        move(OUTPUT, color);
    }
}
}
