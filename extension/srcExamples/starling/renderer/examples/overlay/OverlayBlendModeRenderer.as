/**
 * User: booster
 * Date: 22/01/14
 * Time: 15:47
 */
package starling.renderer.examples.overlay {
import com.barliesque.agal.IComponent;
import com.barliesque.agal.IComponent;
import com.barliesque.agal.IField;
import com.barliesque.agal.IField;
import com.barliesque.agal.IRegister;
import com.barliesque.agal.ISampler;
import com.barliesque.agal.TextureFlag;
import com.barliesque.shaders.macro.Blend;
import com.barliesque.shaders.macro.Utils;

import starling.renderer.BatchRenderer;
import starling.renderer.ShaderType;
import starling.renderer.vertex.VertexFormat;
import starling.textures.Texture;

public class OverlayBlendModeRenderer extends BatchRenderer {
    public static const TOP_TEXTURE:String      = "topTexture";
    public static const BOTTOM_TEXTURE:String   = "bottomTexture";

    public static const ZERO:String             = "zero";
    public static const HALF:String             = "half";
    public static const ONE:String              = "one";

    private var _topTexturePMA:Boolean          = true;
    private var _bottomTexturePMA:Boolean       = true;
    private var _outputPMA:Boolean              = true;

    private var _cachedID:String;

    // shader variables
    private var uvBottom:IRegister  = VARYING[0];
    private var uvTop:IRegister     = VARYING[1];

    public function OverlayBlendModeRenderer() {
        super(OverlayBlendModeVertexFormat.cachedInstance);

        addComponentConstant(ZERO, ShaderType.FRAGMENT, 0.0);
        addComponentConstant(HALF, ShaderType.FRAGMENT, 0.5);
        addComponentConstant(ONE, ShaderType.FRAGMENT, 1.0);
    }

    public function get bottomLayerTexture():Texture { return getInputTexture(BOTTOM_TEXTURE); }
    public function set bottomLayerTexture(value:Texture):void { setInputTexture(BOTTOM_TEXTURE, value); }

    public function get topLayerTexture():Texture { return getInputTexture(TOP_TEXTURE); }
    public function set topLayerTexture(value:Texture):void { setInputTexture(TOP_TEXTURE, value); }

    public function get topTexturePMA():Boolean { return _topTexturePMA; }
    public function set topTexturePMA(value:Boolean):void {
        _topTexturePMA = value;
        updateCachedID();
    }

    public function get bottomTexturePMA():Boolean { return _bottomTexturePMA; }
    public function set bottomTexturePMA(value:Boolean):void {
        _bottomTexturePMA = value;
        updateCachedID();
    }

    public function get outputPMA():Boolean { return _outputPMA; }
    public function set outputPMA(value:Boolean):void {
        _outputPMA = value;
        updateCachedID();
    }

    override protected function get cachedProgramID():String { return _cachedID; }

    override protected function vertexShaderCode():void {
        comment("output vertex position");
        multiply4x4(OUTPUT, getVertexAttribute(VertexFormat.POSITION), getRegisterConstant(PROJECTION_MATRIX));

        comment("pass uv to fragment shader");
        move(uvTop, getVertexAttribute(OverlayBlendModeVertexFormat.TOP_UV));
        move(uvBottom, getVertexAttribute(OverlayBlendModeVertexFormat.BOTTOM_UV));
    }

    override protected function fragmentShaderCode():void {
        var flags:Array             = [TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_LINEAR, TextureFlag.MIP_NONE];
        var bottomTexture:ISampler  = getTextureSampler(BOTTOM_TEXTURE);
        var topTexture:ISampler     = getTextureSampler(TOP_TEXTURE);
        var bottomColor:IRegister   = reserveTempRegister();
        var topColor:IRegister      = reserveTempRegister();
        var overlayColor:IRegister  = reserveTempRegister();
        var outputColor:IRegister   = reserveTempRegister();
        var zero:IComponent         = getComponentConstant(ZERO);
        var half:IComponent         = getComponentConstant(HALF);
        var one:IComponent          = getComponentConstant(ONE);

        sampleInputTexture(bottomColor, uvBottom, bottomTexture, _bottomTexturePMA, zero, one, flags);
        sampleInputTexture(topColor, uvTop, topTexture, _topTexturePMA, zero, one, flags);

        var temps:Array = reserveTempRegisters(3);
        {
            Blend.overlay(overlayColor, bottomColor, topColor, one, half, temps[0], temps[1], temps[2]);
            multiply(overlayColor.a, topColor.a, bottomColor.a);
        }
        freeTempRegisters(temps);

        var tempColor:IRegister = reserveTempRegister();
        {
            alphaBlend(tempColor, topColor, bottomColor, zero, one);
            alphaBlend(outputColor, tempColor, overlayColor, zero, one);
        }
        freeTempRegister(tempColor);

        outputPixel(outputColor, _outputPMA);
    }

    private function alphaBlend(dest:IRegister, baseColor:IRegister, blendColor:IRegister, zero:IComponent, one:IComponent):void {
        if (dest == baseColor) throw new Error("'dest' and 'baseColor' can not be the same register");
        if (dest == blendColor) throw new Error("'dest' and 'blendColor' can not be the same register");

        var temp:IRegister = reserveTempRegister();

        comment("out.a = src.a + dst.a * (1 - src.a)");
        subtract(temp.a, one, blendColor.a);
        multiply(temp.a, temp.a, baseColor.a);
        add(dest.a, blendColor.a, temp.a);

        comment("out.rgb = (src.rgb * src.a + dst.rgb * dst.a * (1 - src.a)) / out.a");
        multiply(temp.rgb, blendColor.rgb, blendColor.a);
        multiply(dest.rgb, baseColor.rgb, temp.a);
        add(dest.rgb, temp.rgb, dest.rgb);
        divide(dest.rgb, dest.rgb, dest.a);
        Utils.clamp(dest.rgb, dest.rgb, zero, one);

        freeTempRegister(temp);
    }

    /** Always returns a non-PMA pixel. */
    private function sampleInputTexture(dest:IRegister, source1:IField, source2:ISampler, pma:Boolean, zero:IField, one:IField, flags:Array = null):void {
        sampleTexture(dest, source1, source2, flags);

        // unmultiply
        if(pma) {
            divide(dest.rgb, dest.rgb, dest.a);
            Utils.clamp(dest.rgb, dest.rgb, zero, one);
        }
    }

    private function outputPixel(source:IRegister, pma:Boolean):void {
        if(pma) {
            var temp:IRegister = reserveTempRegister();
            {
                multiply(temp.rgb, source.rgb, source.a);
                move(temp.a, source.a);
                move(OUTPUT, temp);
            }
            freeTempRegister(temp);
        }
        else {
            move(OUTPUT, source);
        }
    }

    private function updateCachedID():void {
        _cachedID = "OverlayBlendModeRenderer[topPMA : " + _topTexturePMA + ", bottomPMA : " + _bottomTexturePMA + ", outputPMA : " + _outputPMA + "]"
    }
}
}
