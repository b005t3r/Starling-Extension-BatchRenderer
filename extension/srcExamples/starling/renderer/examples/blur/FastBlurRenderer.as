/**
 * User: booster
 * Date: 11/05/15
 * Time: 14:37
 */
package starling.renderer.examples.blur {
import com.barliesque.agal.IComponent;
import com.barliesque.agal.IField;
import com.barliesque.agal.IRegister;
import com.barliesque.agal.TextureFlag;
import com.barliesque.shaders.macro.Utils;

import starling.core.RenderSupport;

import starling.renderer.BatchRenderer;
import starling.renderer.RenderingSettings;
import starling.renderer.ShaderType;
import starling.renderer.examples.textured.TexturedGeometryVertexFormat;
import starling.renderer.vertex.VertexFormat;
import starling.textures.Texture;

public class FastBlurRenderer extends BatchRenderer {
    public static const HORIZONTAL:String   = "horizontal";
    public static const VERTICAL:String     = "vertical";

    public static const DEFAULT_FIRST_PASS_STRENGTH:Number                 = 1.25;
    public static const DEFAULT_STRENGTH_INCREASE_PER_PASS_RATIO:Number    = 2.5;

    protected static const INPUT_TEXTURE:String     = "inputTexture";

    protected static const WEIGHT_CENTER:String     = "weightCenter";
    protected static const WEIGHT_ONE:String        = "weightOne";
    protected static const WEIGHT_TWO:String        = "weightTwo";
    protected static const OFFSETS:String           = "offsets";
    protected static const PIXEL_WIDTH:String       = "pixelWidth";
    protected static const PIXEL_HEIGHT:String      = "pixelHeight";
    protected static const HALF_PIXEL_WIDTH:String  = "halfPixelWidth";
    protected static const HALF_PIXEL_HEIGHT:String = "halfPixelHeight";
    protected static const U_MIN:String             = "uMin";
    protected static const U_MAX:String             = "uMax";
    protected static const V_MIN:String             = "vMin";
    protected static const V_MAX:String             = "vMax";

    protected static const TEXTURE_FLAGS:Array = [TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_LINEAR, TextureFlag.MIP_NO];

    protected static var _verticalOffsets:Vector.<Number>     = new <Number>[0.0, 1.3846153846, 0.0, 3.2307692308];
    protected static var _horizontalOffsets:Vector.<Number>   = new <Number>[1.3846153846, 0.0, 3.2307692308, 0.0];

    private var _type:String                    = HORIZONTAL;
    private var _pass:int                       = 0;
    private var _strength:Number                = Number.NaN;
    private var _firstPassStrength:Number       = DEFAULT_FIRST_PASS_STRENGTH;
    private var _strengthIncreaseRatio:Number   = DEFAULT_STRENGTH_INCREASE_PER_PASS_RATIO;

    protected var _offsetsDirty:Boolean         = true;
    protected var _strengthsDirty:Boolean       = true;

    protected var _strengths:Vector.<Number>    = new <Number>[];

    // shader constants
    protected var uvCenter:IRegister            = VARYING[0];

    public function FastBlurRenderer() {
        super(TexturedGeometryVertexFormat.cachedInstance);

        addComponentConstant(PIXEL_WIDTH,           ShaderType.FRAGMENT, NaN);
        addComponentConstant(PIXEL_HEIGHT,          ShaderType.FRAGMENT, NaN);
        addComponentConstant(HALF_PIXEL_WIDTH,      ShaderType.FRAGMENT, NaN);
        addComponentConstant(HALF_PIXEL_HEIGHT,     ShaderType.FRAGMENT, NaN);

        addRegisterConstant(OFFSETS,                ShaderType.FRAGMENT, NaN, NaN, NaN, NaN);

        addComponentConstant(U_MIN,                 ShaderType.FRAGMENT, 0);
        addComponentConstant(U_MAX,                 ShaderType.FRAGMENT, 1);
        addComponentConstant(V_MIN,                 ShaderType.FRAGMENT, 0);
        addComponentConstant(V_MAX,                 ShaderType.FRAGMENT, 1);

        addComponentConstant(WEIGHT_CENTER,         ShaderType.FRAGMENT, 0.2270270270);
        addComponentConstant(WEIGHT_ONE,            ShaderType.FRAGMENT, 0.3162162162);
        addComponentConstant(WEIGHT_TWO,            ShaderType.FRAGMENT, 0.0702702703);
    }

    public function get inputTexture():Texture { return getInputTexture(INPUT_TEXTURE); }
    public function set inputTexture(value:Texture):void { setInputTexture(INPUT_TEXTURE, value); }

    public function get type():String { return _type; }
    public function set type(value:String):void {
        if(value == _type)
            return;

        _type = value;
        _offsetsDirty = true;
    }

    public function get strength():Number { return _strength; }
    public function set strength(value:Number):void {
        if(value == _strength)
            return;

        _strength = value;
        _offsetsDirty = true;
        _strengthsDirty = true;
    }

    public function get firstPassStrength():Number { return _firstPassStrength; }
    public function set firstPassStrength(value:Number):void {
        if(_firstPassStrength == value)
            return;

        _firstPassStrength = value;
        _offsetsDirty = true;
        _strengthsDirty = true;
    }

    public function get strengthIncreaseRatio():Number { return _strengthIncreaseRatio; }
    public function set strengthIncreaseRatio(value:Number):void {
        if(_strengthIncreaseRatio == value)
            return;

        _strengthIncreaseRatio = value;
        _offsetsDirty = true;
        _strengthsDirty = true;
    }

    public function get pass():int { return _pass; }
    public function set pass(value:int):void {
        if(value == _pass)
            return;

        _pass = value;
        _offsetsDirty = true;
    }

    public function get pixelWidth():Number { return getComponentConstantObject(PIXEL_WIDTH, ShaderType.FRAGMENT).value; }
    public function set pixelWidth(value:Number):void {
        if(pixelWidth == value)
            return;

        modifyComponentConstant(PIXEL_WIDTH,        ShaderType.FRAGMENT, value);
        modifyComponentConstant(HALF_PIXEL_WIDTH,   ShaderType.FRAGMENT, value / 2);

        _offsetsDirty = true;
    }

    public function get pixelHeight():Number { return getComponentConstantObject(PIXEL_HEIGHT, ShaderType.FRAGMENT).value; }
    public function set pixelHeight(value:Number):void {
        if(pixelHeight == value)
            return;

        modifyComponentConstant(PIXEL_HEIGHT,       ShaderType.FRAGMENT, value);
        modifyComponentConstant(HALF_PIXEL_HEIGHT,  ShaderType.FRAGMENT, value / 2);

        _offsetsDirty = true;
    }

    public function get passesNeeded():int {
        if(_strengthsDirty)
            updateStrengths();

        return _strengths.length;
    }

    public function get minU():Number { return getComponentConstantObject(U_MIN, ShaderType.FRAGMENT).value; }
    public function set minU(value:Number):void { modifyComponentConstant(U_MIN, ShaderType.FRAGMENT, value); }

    public function get maxU():Number { return getComponentConstantObject(U_MAX, ShaderType.FRAGMENT).value; }
    public function set maxU(value:Number):void { modifyComponentConstant(U_MAX, ShaderType.FRAGMENT, value); }

    public function get minV():Number { return getComponentConstantObject(V_MIN, ShaderType.FRAGMENT).value; }
    public function set minV(value:Number):void { modifyComponentConstant(V_MIN, ShaderType.FRAGMENT, value); }

    public function get maxV():Number { return getComponentConstantObject(V_MAX, ShaderType.FRAGMENT).value; }
    public function set maxV(value:Number):void { modifyComponentConstant(V_MAX, ShaderType.FRAGMENT, value); }

    public function renderPasses(outputTexture:Texture, tempTexture:Texture, settings:RenderingSettings):void {
        var oldInputTexture:Texture = inputTexture;
        {
            var inTexture:Texture = oldInputTexture;

            var count:int = passesNeeded;
            for(var p:int = 0; p < count; ++p) {
                pass = p;

                inputTexture = inTexture;
                type = FastBlurRenderer.HORIZONTAL;
                renderToTexture(tempTexture, settings);

                inputTexture = tempTexture;
                type = FastBlurRenderer.VERTICAL;
                renderToTexture(outputTexture, settings);

                inTexture = outputTexture;
            }
        }
        inputTexture = oldInputTexture;
    }

    override public function renderToTexture(outputTexture:Texture, settings:RenderingSettings):void {
        if(_strengthsDirty)
            updateStrengths();

        if(_offsetsDirty)
            updateOffsets();

        super.renderToTexture(outputTexture, settings);
    }

    override public function renderToBackBuffer(support:RenderSupport, premultipliedAlpha:Boolean):void {
        throw new Error("this renderer doesn't currently support rendering to back buffer");
    }

    override protected function get cachedProgramID():String {
        return "FastBlurRenderer";
    }

    override protected function vertexShaderCode():void {
        comment("output vertex position");
        multiply4x4(OUTPUT, getVertexAttribute(VertexFormat.POSITION), getRegisterConstant(PROJECTION_MATRIX));

        comment("Pass uv coordinates to fragment shader");
        move(uvCenter, getVertexAttribute(TexturedGeometryVertexFormat.UV));
    }

    override protected function fragmentShaderCode():void {
        var weightCenter:IComponent     = getComponentConstant(WEIGHT_CENTER);
        var weightOne:IComponent        = getComponentConstant(WEIGHT_ONE);
        var weightTwo:IComponent        = getComponentConstant(WEIGHT_TWO);
        var offsets:IRegister           = getRegisterConstant(OFFSETS);
        var offsetOne:IField            = offsets.xy;
        var offsetTwo:IField            = offsets.zw;
        var halfPixelWidth:IComponent   = getComponentConstant(HALF_PIXEL_WIDTH);
        var halfPixelHeight:IComponent  = getComponentConstant(HALF_PIXEL_HEIGHT);
        var uMin:IComponent             = getComponentConstant(U_MIN);
        var uMax:IComponent             = getComponentConstant(U_MAX);
        var vMin:IComponent             = getComponentConstant(V_MIN);
        var vMax:IComponent             = getComponentConstant(V_MAX);

        var tempColor:IRegister         = reserveTempRegister();
        var outputColor:IRegister       = reserveTempRegister();
        var uv:IRegister                = reserveTempRegister();

        //sampleTexture(outputColor, uvCenter, SAMPLER[0], TEXTURE_FLAGS);
        sampleColor(outputColor, uvCenter, weightCenter);

        subtract(uv, uvCenter, offsetTwo);
        sampleColor(tempColor, uv, weightTwo, uMin, uMax, vMin, vMax, halfPixelWidth, halfPixelHeight);
        add(outputColor, outputColor, tempColor);

        subtract(uv, uvCenter, offsetOne);
        sampleColor(tempColor, uv, weightOne, uMin, uMax, vMin, vMax, halfPixelWidth, halfPixelHeight);
        add(outputColor, outputColor, tempColor);

        add(uv, uvCenter, offsetOne);
        sampleColor(tempColor, uv, weightOne, uMin, uMax, vMin, vMax, halfPixelWidth, halfPixelHeight);
        add(outputColor, outputColor, tempColor);

        add(uv, uvCenter, offsetTwo);
        sampleColor(tempColor, uv, weightTwo, uMin, uMax, vMin, vMax, halfPixelWidth, halfPixelHeight);
        add(outputColor, outputColor, tempColor);

        move(OUTPUT, outputColor);
    }

    /** Clamp value between min and max, with optional margin ([min + margin, max - margin]). */
    protected function sampleColor(sampledColor:IRegister, uv:IRegister, colorWeight:IComponent, minU:IComponent = null, maxU:IComponent = null, minV:IComponent = null, maxV:IComponent = null, halfPixelWidth:IComponent = null, halfPixelHeight:IComponent = null):void {
        if(minU != null) {
            var temp:IRegister = reserveTempRegister();
            {
                clamp(uv.x, minU, maxU, halfPixelWidth);
                clamp(uv.y, minV, maxV, halfPixelHeight);
            }
            freeTempRegister(temp);
        }

        sampleTexture(sampledColor, uv, getTextureSampler(INPUT_TEXTURE), TEXTURE_FLAGS);
        multiply(sampledColor, sampledColor, colorWeight);
    }

    protected function clamp(value:IComponent, min:IComponent, max:IComponent, margin:IComponent = null):void {
        if(margin == null) {
            Utils.clamp(value, value, min, max);
        }
        else {
            var temp:IRegister = reserveTempRegister();
            {
                move(temp.x, min);
                add(temp.x, temp.x, margin);

                move(temp.y, max);
                subtract(temp.y, temp.y, margin);

                Utils.clamp(value, value, temp.x, temp.y);
            }
            freeTempRegister(temp);
        }
    }

    protected function updateStrengths():void {
        _strengthsDirty = false;

        _strengths.length   = 0;
        var str:Number      = Math.min(_firstPassStrength, _strength);
        var sum:Number      = 0;

        while(sum + str < _strength) {
            _strengths[_strengths.length] = str;
            sum += str;
            str *= _strengthIncreaseRatio;
        }

        var diff:Number = _strength - sum;

        if(diff > 0 || _strengths.length == 0)
            _strengths[_strengths.length] = diff;

        _strengths.sort(function (a:Number, b:Number):Number { return b - a; });

        //trace("strengths: [" + _strengths + "], total: " + _strength);
    }

    protected function updateOffsets():void {
        // algorithm described here:
        // http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
        //
        // To run in constrained mode, we can only make 5 texture lookups in the fragment
        // shader. By making use of linear texture sampling, we can produce similar output
        // to what would be 9 lookups.

        _offsetsDirty = false;

        var multiplier:Number, str:Number = _strengths[_pass];
        //var i:int, count:int = 4;

        if(type == HORIZONTAL) {
            multiplier = pixelWidth * str;

            modifyRegisterConstant(OFFSETS, ShaderType.FRAGMENT,
                    _horizontalOffsets[0] * multiplier,
                    _horizontalOffsets[1] * multiplier,
                    _horizontalOffsets[2] * multiplier,
                    _horizontalOffsets[3] * multiplier
            );

            //for(i = 0; i < count; i++)
            //    _offsets[i] = _horizontalOffsets[i] * multiplier;
        }
        else {
            multiplier = pixelHeight * str;

            modifyRegisterConstant(OFFSETS, ShaderType.FRAGMENT,
                    _verticalOffsets[0] * multiplier,
                    _verticalOffsets[1] * multiplier,
                    _verticalOffsets[2] * multiplier,
                    _verticalOffsets[3] * multiplier
            );

            //for(i = 0; i < count; i++)
            //    _offsets[i] = _verticalOffsets[i] * multiplier;
        }

        //trace("str: " + str);
    }
}
}
