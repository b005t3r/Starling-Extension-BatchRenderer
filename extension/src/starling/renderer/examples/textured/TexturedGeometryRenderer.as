/**
 * User: booster
 * Date: 16/01/14
 * Time: 12:08
 */
package starling.renderer.examples.textured {
import com.barliesque.agal.IRegister;
import com.barliesque.agal.ISampler;
import com.barliesque.agal.TextureFlag;

import starling.renderer.*;
import starling.textures.Texture;

public class TexturedGeometryRenderer extends BatchRenderer {
    public static const INPUT_TEXTURE:String    = "inputTexture";

    // shader variables
    private var uv:IRegister = VARYING[0];  // v0 is used to pass interpolated uv from vertex to fragment shader

    public function TexturedGeometryRenderer() {
        super(TexturedGeometryVertexFormat.cachedInstance);
    }

    public function get inputTexture():Texture { return getInputTexture(INPUT_TEXTURE); }
    public function set inputTexture(value:Texture):void { setInputTexture(INPUT_TEXTURE, value); }

    override protected function vertexShaderCode():void {
        comment("output vertex position");
        multiply4x4(OUTPUT, getVertexAttribute(VertexFormat.POSITION), getRegisterConstant(PROJECTION_MATRIX));

        comment("pass uv to fragment shader");
        move(uv, getVertexAttribute(TexturedGeometryVertexFormat.UV));
    }

    override protected function fragmentShaderCode():void {
        var input:ISampler = getTextureSampler(INPUT_TEXTURE);

        comment("sample the texture and send resulting color to the output");
        sampleTexture(OUTPUT, uv, input, [TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_LINEAR, TextureFlag.MIP_NONE]);
    }
}
}
