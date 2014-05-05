/**
 * User: booster
 * Date: 14/01/14
 * Time: 13:48
 */
package starling.renderer {

import com.barliesque.agal.EasierAGAL;
import com.barliesque.agal.IComponent;
import com.barliesque.agal.IRegister;
import com.barliesque.agal.ISampler;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.errors.IllegalOperationError;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.utils.Dictionary;

import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.BlendMode;
import starling.errors.MissingContextError;
import starling.renderer.constant.ComponentConstant;
import starling.renderer.constant.RegisterConstant;
import starling.renderer.GeometryData;
import starling.renderer.VertexFormat;
import starling.textures.Texture;
import starling.utils.Color;
import starling.utils.MatrixUtil;

use namespace renderer_internal;

/**
 * Renderer combines geometry data: vertex data such as position, uv, etc., triangle data, a shader program and
 * (optionally) input textures.
 *
 * This class is meant to be subclassed and cannot be used as is. Subclass has to provide vertex and fragment
 * shaders, as well as set up a vertex format (specify which indexes hold what kind of data) and provide geometry
 * data matching the format (vertex data and triangle data).
 *
 * When subclassing, make sure to import 'renderer_internal' namespace (by 'use namespace renderer_internal:').
 *
 * Multiple geometries can be provided this way. They don't have to be quads - client decides on what geometry is
 * to be rendered by providing a vertex format, vertex data and setting up triangles. Keep in mind that's up to you
 * to decide what data each vertex holds. If you don't need UV, don't put them in your vertex format. If you want
 * to sample multiple textures of different sizes, you can pass multiple sets of UVs - one for each texture.
 *
 * Renderer makes it easy to create custom shader programs. Vertex and Fragment shaders are created using EasierAGAL
 * static methods and register/component objects (IRegister, IComponent, IField etc.) as well as protected
 * methods provided by this class. Methods like: getComponentConstant(), getRegisterConstant(), getTextureSampler()
 * and getVertexAttribute() make it possible not to rely on register indexes, but let you fetch given
 * registers/components by providing a previously assigned name (i.e. you no longer have to access register 'va1'
 * for vertex position, you can now call getVertexAttribute("position") without caring which register holds position).
 *
 * To make setting up geometry data easier, use methods of BatchRendererUtil static class.
 *
 * Contents of the renderer can be displayed onto a texture render target (by calling renderToTexture()) or the back
 * buffer (by using Starling's RenderSupport class) - the later requires renderer to be wrapped into a
 * BatchRendererWrapper instance (a custom DisplayObject class).
 */
public class BatchRenderer extends EasierAGAL {
    public static const PROJECTION_MATRIX:String                = "projectionMatrix";

    private static var _cachedPrograms:Dictionary               = new Dictionary();

    private static var _projectionMatrix:Matrix                 = new Matrix();
    private static var _helperMatrix:Matrix                     = new Matrix();
    private static var _matrix3D:Matrix3D                       = new Matrix3D();
    private static var _vertexConstants:Vector.<Number>         = new <Number>[];
    private static var _fragmentConstants:Vector.<Number>       = new <Number>[];

    private var _inputTextures:Vector.<Texture>                 = new <Texture>[];
    private var _inputTextureNames:Vector.<String>              = new <String>[];

    private var _vertexFormat:VertexFormat                      = null;
    private var _batchedGeometry:GeometryData                   = null;

    private var _registerConstants:Vector.<RegisterConstant>    = new <RegisterConstant>[];
    private var _componentConstants:Vector.<ComponentConstant>  = new <ComponentConstant>[];

    private var _usedVertexTempRegisters:Vector.<Boolean>       = new <Boolean>[];
    private var _usedFragmentTempRegisters:Vector.<Boolean>     = new <Boolean>[];

    private var _currentProgramType:int                         = -1;

    public function BatchRenderer(vertexFormat:VertexFormat) {
        _vertexFormat = vertexFormat;
        _batchedGeometry = new GeometryData(vertexFormat);
    }

    /** Renders geometry data to back buffer using Starling's RenderSupport. */
    public function renderToBackBuffer(support:RenderSupport, premultipliedAlpha:Boolean):void {
        var context:Context3D = Starling.context;

        if(context == null)
            throw new MissingContextError();

        var buffersReady:Boolean = _batchedGeometry.createBuffers(context);

        if(! buffersReady) return;

        // always call this method when you write custom rendering code!
        // it causes all previously batched quads/images to render.
        support.finishQuadBatch(); // (1)

        // make this call to keep the statistics display in sync.
        support.raiseDrawCount(); // (2)

        // apply the current blendmode (4)
        support.applyBlendMode(premultipliedAlpha);

        // activate program (shader) and set the required buffers, constants, texture
        context.setProgram(upload(context));

        _batchedGeometry.setVertexBuffers(context);
        setInputTextures(context);

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true); // vc0-vc3
        setProgramConstants(context, 4, 0);

        // render
        context.drawTriangles(_batchedGeometry.indexBuffer, 0, _batchedGeometry.triangleData.length / 3);

        unsetInputTextures(context);
        _batchedGeometry.unsetVertexBuffers(context);
    }

    /** Renders geometry data to texture. Clears the texture first (Stage3D requirement). */
    public function renderToTexture(outputTexture:Texture, settings:RenderingSettings):void {
        var context:Context3D = Starling.context;

        if(context == null)
            throw new MissingContextError();

        var buffersReady:Boolean = _batchedGeometry.createBuffers(context);

        if(! buffersReady) return;

        // render to output texture and clear it
        context.setRenderToTexture(outputTexture.base);
        context.clear(
            Color.getRed(settings.clearColor) / 255.0,
            Color.getGreen(settings.clearColor) / 255.0,
            Color.getBlue(settings.clearColor) / 255.0,
            settings.clearAlpha
        );

        // setup output regions for rendering and (optionally) transform input geometries
        var m:Matrix3D = setOrthographicProjection(0, 0, outputTexture.nativeWidth, outputTexture.nativeHeight, settings.inputTransform);
        context.setScissorRectangle(settings.clippingRectangle);

        // set blend mode
        var blendFactors:Array = BlendMode.getBlendFactors(settings.blendMode, settings.premultipliedAlpha);
        Starling.context.setBlendFactors(blendFactors[0], blendFactors[1]);

        // activate program (shader) and set the required buffers, constants, texture
        context.setProgram(upload(context));

        _batchedGeometry.setVertexBuffers(context);
        setInputTextures(context);

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true); // vc0-vc3
        setProgramConstants(context, 4, 0);

        // render
        context.drawTriangles(_batchedGeometry.indexBuffer, 0, _batchedGeometry.triangleData.length / 3);

        unsetInputTextures(context);
        _batchedGeometry.unsetVertexBuffers(context);
    }

    public function appendGeometry(geometry:GeometryData, matrix:Matrix = null, positionID:int = 0):void {
        _batchedGeometry.append(geometry, matrix, positionID);
    }

    public function resetGeometry():void {
        _batchedGeometry.clear();
    }

    override public function dispose():void {
        _batchedGeometry.dispose();

        super.dispose();
    }

    override public function upload(context:Context3D):Program3D {
        var cachedID:String = cachedProgramID;

        if(cachedID == null)
            return super.upload(context);

        if(_cachedPrograms[cachedID] == null)
            return (_cachedPrograms[cachedID] = super.upload(context));
        else
            return _cachedPrograms[cachedID];
    }

    override public function get program():Program3D {
        var cachedID:String = cachedProgramID;
        var prog:Program3D  = super.program;

        if(cachedID == null)
            return prog;

        if(prog == null)
            return null;
        else if(_cachedPrograms[cachedID] == null)
            return (_cachedPrograms[cachedID] = prog);
        else
            return _cachedPrograms[cachedID];
    }

    /** Provided a registered texture name, returns its sampler index. */
    renderer_internal function getInputTextureIndex(name:String):int { return _inputTextureNames.indexOf(name); }

    /** Returns a texture registered with the name provided. */
    renderer_internal function getInputTexture(name:String):Texture {
        var index:int = getInputTextureIndex(name);

        return index >= 0 ? _inputTextures[index] : null;
    }

    /** Registers a new texture (or unregisters an old one, if null) using the name provided. */
    renderer_internal function setInputTexture(name:String, texture:Texture):void {
        var index:int = getInputTextureIndex(name);

        if(index >= 0) {
            if(texture == null) {
                _inputTextures.splice(index, 1);
                _inputTextureNames.splice(index, 1);
            }
            else {
                _inputTextures[index] = texture;
            }
        }
        else if(texture != null) {
            _inputTextures[_inputTextures.length]           = texture;
            _inputTextureNames[_inputTextureNames.length]   = name;
        }
    }

    /** Adds a new constant which will be passed to the shader program (Vertex or Fragment) as one, 4-component
     * register. */
    renderer_internal function addRegisterConstant(name:String, type:int, x:Number, y:Number, z:Number, w:Number):void {
        _registerConstants[_registerConstants.length] = new RegisterConstant(name, type, x, y, z, w);
    }

    /** Adds a new constant which will be passed to the shader program (Vertex or Fragment) as a component. */
    renderer_internal function addComponentConstant(name:String, type:int, value:Number):void {
        _componentConstants[_componentConstants.length] = new ComponentConstant(name, type, value);
    }

    /** Removes previously added register constant. */
    renderer_internal function removeRegisterConstant(name:String, type:int):void {
        var index:int = getRegisterConstantIndex(name, type);

        if(index < 0) return;

        _registerConstants.splice(index, 1);
    }

    /** Removes previously added component constant. */
    renderer_internal function removeComponentConstant(name:String, type:int, value:Number):void {
        var index:int = getComponentConstantIndex(name, type);

        if(index < 0) return;

        _componentConstants.splice(index, 1);
    }

    /** Modifies previously added register constant's values. */
    renderer_internal function modifyRegisterConstant(name:String, type:int, x:Number, y:Number, z:Number, w:Number):void {
        var index:int                   = getRegisterConstantIndex(name, type);
        var constant:RegisterConstant   = _registerConstants[index];

        constant.setValues(x, y, z, w);
    }

    /** Modifies previously added component constant's values. */
    renderer_internal function modifyComponentConstant(name:String, type:int, value:Number):void {
        var index:int                   = getComponentConstantIndex(name, type);
        var constant:ComponentConstant  = _componentConstants[index];

        constant.value = value;
    }

    /** Returns a index associated with a register constant with the given name. */
    renderer_internal function getRegisterConstantIndex(name:String, type:int):int {
        var count:int = _registerConstants.length;
        for(var i:int = 0; i < count; i++) {
            var constant:RegisterConstant = _registerConstants[i];

            if(type != constant.type || name != constant.name)
                continue;

            return i;
        }

        return -1;
    }

    /** Returns a index associated with a component constant with the given name. */
    renderer_internal function getComponentConstantIndex(name:String, type:int):int {
        var count:int = _componentConstants.length;
        for(var i:int = 0; i < count; i++) {
            var constant:ComponentConstant = _componentConstants[i];

            if(type != constant.type || name != constant.name)
                continue;

            return i;
        }

        return -1;
    }

    /** Return non-null string to share this instance's program with other instances returning the same ID. */
    protected function get cachedProgramID():String { return null; }

    /** Returns a register holding a constant with the given name. Must be called inside a vertex or fragment shader. */
    protected function getRegisterConstant(name:String):IRegister {
        if(_currentProgramType != ShaderType.VERTEX && _currentProgramType != ShaderType.FRAGMENT)
            throw new IllegalOperationError("constant registers are available for vertex or fragment programs only");

        if(_currentProgramType == ShaderType.VERTEX && name == PROJECTION_MATRIX)
            return CONST[0];

        var index:int = 0;
        var count:int = _registerConstants.length;
        for(var i:int = 0; i < count; i++) {
            var constant:RegisterConstant = _registerConstants[i];

            if(_currentProgramType != constant.type)
                continue;

            if(name != constant.name) {
                ++index;
            }
            else {
                // first four vc registers are reserved for the transformation matrix
                return _currentProgramType == ShaderType.VERTEX ? CONST[index + 4] : CONST[index];
            }
        }

        return null;
    }

    /** Returns a component holding a constant with the given name. Must be called inside a vertex or fragment shader. */
    protected function getComponentConstant(name:String):IComponent {
        if(_currentProgramType != ShaderType.VERTEX && _currentProgramType != ShaderType.FRAGMENT)
            throw new IllegalOperationError("constant registers are available for vertex or fragment programs only");

        var index:int = 0;
        var count:int = _componentConstants.length;
        for(var i:int = 0; i < count; i++) {
            var constant:ComponentConstant = _componentConstants[i];

            if(_currentProgramType != constant.type)
                continue;

            if(name != constant.name) {
                ++index;
            }
            else {
                var regIndex:int    = index / 4; // 4 components per register
                var compIndex:int   = index % 4;

                // first four vc registers are reserved for the transformation matrix
                if(_currentProgramType == ShaderType.VERTEX)
                    regIndex += 4;

                switch(compIndex) {
                    case 0: return CONST[regIndex].x;
                    case 1: return CONST[regIndex].y;
                    case 2: return CONST[regIndex].z;
                    case 3: return CONST[regIndex].w;

                    default: return null; // to silence compiler warning
                }
            }
        }

        return null;
    }

    /** Returns a register holding a vertex attribute with the given name. Must be called inside a vertex shader. */
    protected function getVertexAttribute(name:String):IRegister {
        if(_currentProgramType != ShaderType.VERTEX)
            throw new IllegalOperationError("attribute registers are available for vertex programs only");

        var index:int = _vertexFormat.getPropertyIndex(name);

        return ATTRIBUTE[index];
    }

    /** Returns a texture sampler used to read texture with the given name. Must be called inside a fragment shader. */
    protected function getTextureSampler(textureName:String):ISampler {
        if(_currentProgramType != ShaderType.FRAGMENT)
            throw new IllegalOperationError("texture samplers are available for fragment programs only");

        var index:int = getInputTextureIndex(textureName);

        return SAMPLER[index];
    }

    /** Reserves first unreserved temporary register and returns it. Must be called inside a vertex or fragment shader. */
    protected function reserveTempRegister():IRegister {
        var flags:Vector.<Boolean>;

        if(_currentProgramType == ShaderType.VERTEX)
            flags = _usedVertexTempRegisters;
        else if(_currentProgramType == ShaderType.FRAGMENT)
            flags = _usedFragmentTempRegisters;
        else
            throw new IllegalOperationError("temporary registers are available for vertex or fragment programs only");

        var count:int = flags.length;
        for(var i:int = 0; i < count; i++) {
            var reserved:Boolean = flags[i];

            if(reserved)
                continue;

            flags[i] = true;
            return TEMP[i];
        }

        throw new Error("no more temporary registers left to use; free unused registers first");
    }

    /** Frees the temporary register, so it will be possible to reserve it again. Must be called inside a vertex or fragment shader. */
    protected function freeTempRegister(register:IRegister):void {
        var flags:Vector.<Boolean>;

        if(_currentProgramType == ShaderType.VERTEX)
            flags = _usedVertexTempRegisters;
        else if(_currentProgramType == ShaderType.FRAGMENT)
            flags = _usedFragmentTempRegisters;
        else
            throw new IllegalOperationError("temporary registers are available for vertex or fragment programs only");

        var index:int = TEMP.indexOf(register);

        if(index < 0)
            throw new ArgumentError("value passed is not a temporary register");

        flags[index] = false;
    }


    /** Reserves multiple unreserved temporary registers and returns them. Must be called inside a vertex or fragment shader. */
    protected function reserveTempRegisters(count:int):Array {
        var registers:Array = [];

        for(var i:int = 0; i < count; ++i)
            registers[i] = reserveTempRegister();

        return registers;
    }

    /** Frees multiple temporary registers. Must be called inside a vertex or fragment shader. */
    protected function freeTempRegisters(registers:Array):void {
        for(var i:int = 0; i < registers.length; ++i)
            freeTempRegister(registers[i])
    }

    /** Abstract method. Override to provide vertex shader code. */
    protected function vertexShaderCode():void { throw new Error("abstract method call"); }

    /** Abstract method. Override to provide fragment shader code. */
    protected function fragmentShaderCode():void { throw new Error("abstract method call"); }

    override protected function _vertexShader():void {
        _currentProgramType = ShaderType.VERTEX;

        _usedVertexTempRegisters.length = 0;
        for(var i:int = 0; i < TEMP.length; i++)
            _usedFragmentTempRegisters[i] = false;

        vertexShaderCode();

        _currentProgramType = -1;
    }

    override protected function _fragmentShader():void {
        _currentProgramType = ShaderType.FRAGMENT;

        _usedFragmentTempRegisters.length = 0;
        for(var i:int = 0; i < TEMP.length; i++)
            _usedFragmentTempRegisters[i] = false;

        fragmentShaderCode();

        _currentProgramType                 = -1;
        _usedFragmentTempRegisters.length   = 0;
    }

    private function setOrthographicProjection(x:Number, y:Number, width:Number, height:Number, transform:Matrix = null):Matrix3D {
        _projectionMatrix.setTo(
            2.0 / width, 0, 0,
            -2.0 / height, -(2 * x + width) / width, (2 * y + height) / height
        );

        if(transform == null) {
            return MatrixUtil.convertTo3D(_projectionMatrix, _matrix3D);
        }
        else {
            _helperMatrix.copyFrom(transform);
            _helperMatrix.concat(_projectionMatrix);

            return MatrixUtil.convertTo3D(_helperMatrix, _matrix3D);
        }
    }

    private function setProgramConstants(context:Context3D, vertexIndex:int, fragmentIndex:int):void {
        var i:int, count:int;

        count = _registerConstants.length;
        for(i = 0; i < count; ++i) {
            var regConstant:RegisterConstant = _registerConstants[i];

            if(regConstant.type == ShaderType.VERTEX) {
                context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexIndex, regConstant.values, 1);
                ++vertexIndex;
            }
            else {
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, fragmentIndex, regConstant.values, 1);
                ++fragmentIndex;
            }
        }

        _vertexConstants.length     = 0;
        _fragmentConstants.length   = 0;

        count = _componentConstants.length;
        for(i = 0; i < count; ++i) {
            var compConstant:ComponentConstant = _componentConstants[i];

            if(compConstant.type == ShaderType.VERTEX)
                _vertexConstants[_vertexConstants.length] = compConstant.value;
            else
                _fragmentConstants[_fragmentConstants.length] = compConstant.value;
        }

        if(_vertexConstants.length > 0) {
            var vertexRegs:int = (_vertexConstants.length % 4) == 0
                ? _vertexConstants.length / 4
                : _vertexConstants.length / 4 + 1
            ;

            _vertexConstants.length = vertexRegs * 4;

            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexIndex, _vertexConstants, vertexRegs);
        }

        if(_fragmentConstants.length > 0) {
            var fragmentRegs:int = (_fragmentConstants.length % 4) == 0
                ? _fragmentConstants.length / 4
                : _fragmentConstants.length / 4 + 1
            ;

            _fragmentConstants.length = fragmentRegs * 4;

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, fragmentIndex, _fragmentConstants, fragmentRegs);
        }
    }

    private function setInputTextures(context:Context3D):void {
        var count:int = _inputTextures.length;
        for(var i:int = 0; i < count; i++) {
            var texture:Texture = _inputTextures[i];

            context.setTextureAt(i, texture.base);
        }
    }

    private function unsetInputTextures(context:Context3D):void {
        var count:int = _inputTextures.length;
        for(var i:int = 0; i < count; i++) {
            var texture:Texture = _inputTextures[i];

            context.setTextureAt(i, null);
        }
    }
}
}
