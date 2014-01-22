/**
 * User: booster
 * Date: 22/01/14
 * Time: 15:47
 */
package starling.renderer.examples {
import com.barliesque.agal.IComponent;
import com.barliesque.agal.IRegister;
import com.barliesque.agal.ISampler;
import com.barliesque.agal.TextureFlag;
import com.barliesque.shaders.macro.Blend;

import starling.renderer.BatchRenderer;
import starling.renderer.constant.ConstantType;
import starling.renderer.renderer_internal;
import starling.renderer.vertex.VertexFormat;
import starling.textures.Texture;

use namespace renderer_internal;

public class OverlayBlendModeRenderer extends BatchRenderer {
    public static const POSITION:String         = "position";
    public static const TOP_UV:String           = "uvTop";
    public static const BOTTOM_UV:String        = "uvBottom";

    public static const TOP_TEXTURE:String      = "topTexture";
    public static const BOTTOM_TEXTURE:String   = "bottomTexture";

    public static const HALF:String             = "half";
    public static const ONE:String              = "one";

    private var _positionID:int, _uvTopID:int, _uvBottomID:int;

    // shader variables
    private var uvBottom:IRegister  = VARYING[0];
    private var uvTop:IRegister     = VARYING[1];

    public function OverlayBlendModeRenderer() {
        setVertexFormat(createVertexFormat());

        addComponentConstant(HALF, ConstantType.FRAGMENT, 0.5);
        addComponentConstant(ONE, ConstantType.FRAGMENT, 1.0);
    }

    public function get bottomLayerTexture():Texture { return getInputTexture(BOTTOM_TEXTURE); }
    public function set bottomLayerTexture(value:Texture):void { setInputTexture(BOTTOM_TEXTURE, value); }

    public function get topLayerTexture():Texture { return getInputTexture(TOP_TEXTURE); }
    public function set topLayerTexture(value:Texture):void { setInputTexture(TOP_TEXTURE, value); }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, _positionID, x, y); }

    public function getTopLayerVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _uvTopID, uv); }
    public function setTopLayerVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, _uvTopID, u, v); }

    public function getBottomLayerVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _uvBottomID, uv); }
    public function setBottomLayerVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, _uvBottomID, u, v); }

    override protected function vertexShaderCode():void {
        comment("output vertex position");
        multiply4x4(OUTPUT, getVertexAttribute(POSITION), getRegisterConstant(PROJECTION_MATRIX));

        comment("pass uv to fragment shader");
        move(uvTop, getVertexAttribute(TOP_UV));
        move(uvBottom, getVertexAttribute(BOTTOM_UV));
    }

    override protected function fragmentShaderCode():void {
        var flags:Array             = [TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_LINEAR, TextureFlag.MIP_NONE];
        var bottomTexture:ISampler  = getTextureSampler(BOTTOM_TEXTURE);
        var topTexture:ISampler     = getTextureSampler(TOP_TEXTURE);
        var bottomColor:IRegister   = TEMP[0];
        var topColor:IRegister      = TEMP[1];
        var outputColor:IRegister   = TEMP[2];
        var half:IComponent         = getComponentConstant(HALF);
        var one:IComponent          = getComponentConstant(ONE);

        sampleTexture(bottomColor, uvBottom, bottomTexture, flags);
        sampleTexture(topColor, uvTop, topTexture, flags);

        Blend.overlay(outputColor, bottomColor, topColor, one, half, TEMP[3], TEMP[4],TEMP[5]);
        move(outputColor.a, bottomColor.a);

        move(OUTPUT, outputColor);
    }

    private function createVertexFormat():VertexFormat {
        var format:VertexFormat = new VertexFormat();

        _positionID = format.addProperty(POSITION, 2);  // x, y; id: 0
        _uvTopID    = format.addProperty(TOP_UV, 2);    // u, v; id: 1
        _uvBottomID = format.addProperty(BOTTOM_UV, 2); // u, v; id: 2

        return format;
    }
}
}
