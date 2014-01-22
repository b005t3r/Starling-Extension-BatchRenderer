/**
 * User: booster
 * Date: 16/01/14
 * Time: 12:08
 */
package starling.renderer.examples {
import starling.renderer.*;

import com.barliesque.agal.IRegister;
import com.barliesque.agal.ISampler;
import com.barliesque.agal.TextureFlag;

import starling.renderer.vertex.VertexFormat;
import starling.textures.Texture;

use namespace renderer_internal;

public class TexturedGeometryRenderer extends BatchRenderer {
    public static const POSITION:String         = "position";
    public static const UV:String               = "uv";

    public static const INPUT_TEXTURE:String    = "inputTexture";

    private var _positionID:int, _uvID:int;

    // shader variables
    private var uv:IRegister = VARYING[0];  // v0 is used to pass interpolated uv from vertex to fragment shader

    public function TexturedGeometryRenderer() {
        setVertexFormat(createVertexFormat());
    }

    public function get inputTexture():Texture { return getInputTexture(INPUT_TEXTURE); }
    public function set inputTexture(value:Texture):void { setInputTexture(INPUT_TEXTURE, value); }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, _positionID, x, y); }

    public function getVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _uvID, uv); }
    public function setVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, _uvID, u, v); }

    override protected function vertexShaderCode():void {
        comment("output vertex position");
        multiply4x4(OUTPUT, getVertexAttribute(POSITION), getRegisterConstant(PROJECTION_MATRIX));

        comment("pass uv to fragment shader");
        move(uv, getVertexAttribute(UV));
    }

    override protected function fragmentShaderCode():void {
        var input:ISampler = getTextureSampler(INPUT_TEXTURE);

        comment("sample the texture and send resulting color to the output");
        sampleTexture(OUTPUT, uv, input, [TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_LINEAR, TextureFlag.MIP_NONE]);
    }

    private function createVertexFormat():VertexFormat {
        var format:VertexFormat = new VertexFormat();

        _positionID = format.addProperty(POSITION, 2);  // x, y; id: 0
        _uvID       = format.addProperty(UV, 2);        // u, v; id: 1

        return format;
    }
}
}
