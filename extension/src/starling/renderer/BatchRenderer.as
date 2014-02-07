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
import starling.renderer.vertex.VertexFormat;
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

    private var _vertexBuffer:VertexBuffer3D                    = null;
    private var _indexBuffer:IndexBuffer3D                      = null;
    private var _buffersDirty:Boolean                           = true;

    // vertex specific variables will be changed to VertexData once it's ready for customisation
    private var _vertexRawData:Vector.<Number>                  = new <Number>[];
    private var _vertexFormat:VertexFormat                      = null;
    private var _triangleData:Vector.<uint>                     = new <uint>[];

    private var _registerConstants:Vector.<RegisterConstant>    = new <RegisterConstant>[];
    private var _componentConstants:Vector.<ComponentConstant>  = new <ComponentConstant>[];

    private var _usedVertexTempRegisters:Vector.<Boolean>       = new <Boolean>[];
    private var _usedFragmentTempRegisters:Vector.<Boolean>     = new <Boolean>[];

    private var _currentProgramType:int                         = -1;

    /** Renders geometry data to back buffer usign Starling's RenderSupport. */
    public function renderToBackBuffer(support:RenderSupport, premultipliedAlpha:Boolean):void {
        var context:Context3D = Starling.context;

        if(context == null)
            throw new MissingContextError();

        if(_buffersDirty)
            createBuffers(context);

        // always call this method when you write custom rendering code!
        // it causes all previously batched quads/images to render.
        support.finishQuadBatch(); // (1)

        // make this call to keep the statistics display in sync.
        support.raiseDrawCount(); // (2)

        // apply the current blendmode (4)
        support.applyBlendMode(premultipliedAlpha);

        // activate program (shader) and set the required buffers, constants, texture
        context.setProgram(upload(context));

        setVertexBuffers(context);
        setInputTextures(context);

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true); // vc0-vc3
        setProgramConstants(context, 4, 0);

        // render
        context.drawTriangles(_indexBuffer, 0, _triangleData.length / 3);

        unsetInputTextures(context);
        unsetVertexBuffers(context);
    }

    /** Renders geometry data to texture. Clears the texture first (Stage3D requirement). */
    public function renderToTexture(outputTexture:Texture, settings:RenderingSettings):void {
        var context:Context3D = Starling.context;

        if(context == null)
            throw new MissingContextError();

        if(_buffersDirty)
            createBuffers(context);

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

        setVertexBuffers(context);
        setInputTextures(context);

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true); // vc0-vc3
        setProgramConstants(context, 4, 0);

        // render
        context.drawTriangles(_indexBuffer, 0, _triangleData.length / 3);

        unsetInputTextures(context);
        unsetVertexBuffers(context);
    }

    /** Number of registered vertices. */
    public function get vertexCount():int { return _vertexRawData.length / _vertexFormat.totalSize; }

    override public function dispose():void {
        if(_vertexBuffer != null) _vertexBuffer.dispose();
        if(_indexBuffer != null) _indexBuffer.dispose();

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

    // also erases all vertices
    /** Sets up vertex data. Calling this method is obligatory when subclassing. */
    renderer_internal function setVertexFormat(format:VertexFormat):void {
        _buffersDirty = true;

        _vertexRawData.length   = 0;
        _triangleData.length    = 0;
        _vertexFormat           = format;
    }

    /**
     * Adds a number of verices to this renderer and returns the first index added.
     * These vertices are not yet part of any geometry - call addTriangle() and pass vertex indexes to build
     * geometry segments.
     */
    renderer_internal function addVertices(count:int):int {
        _buffersDirty = true;

        var firstIndex:int      = vertexCount;
        _vertexRawData.length  += _vertexFormat.totalSize * count;


        return firstIndex;
    }

    /** Adds a new triangle out of registered vertices. */
    renderer_internal function addTriangle(v1:int, v2:int, v3:int):void {
        _buffersDirty = true;

        _triangleData[_triangleData.length] = v1;
        _triangleData[_triangleData.length] = v2;
        _triangleData[_triangleData.length] = v3;
    }

    /**
     * Returns vertex data associated with a given vertex.
     *
     * @param vertex    vertex index
     * @param id        data id ('va' register index), @see VertexFormat
     * @param data      optional vector to hold up to 4 Numbers representing the data
     * @return          vector holding the vertex data
     */
    renderer_internal function getVertexData(vertex:int, id:int, data:Vector.<Number> = null):Vector.<Number> {
        var index:int   = _vertexFormat.totalSize * vertex + _vertexFormat.getOffset(id);
        var size:int    = _vertexFormat.getSize(id);

        if(data == null) data = new Vector.<Number>(size);

        for(var i:int = 0; i < size; ++i)
            data[i] = _vertexRawData[index + i];

        return data;
    }

    /**
     * Sets data associated with the given vertex.
     * Keep in mind only as many components will be used, as required by the VertexFormat set.
     *
     * @param vertex    vertex index
     * @param id        data id ('va' register index), @see VertexFormat
     * @param x         first component value
     * @param y         second component value
     * @param z         third component value
     * @param w         fourth component value
     */
    renderer_internal function setVertexData(vertex:int, id:int, x:Number, y:Number = NaN, z:Number = NaN, w:Number = NaN):void {
        var index:int   = _vertexFormat.totalSize * vertex + _vertexFormat.getOffset(id);
        var size:int    = _vertexFormat.getSize(id);

        //noinspection FallthroughInSwitchStatementJS
        switch(size) {
            case 4: if(_vertexRawData[index + 3] != w) { _buffersDirty = true; _vertexRawData[index + 3] = w; }
            case 3: if(_vertexRawData[index + 2] != z) { _buffersDirty = true; _vertexRawData[index + 2] = z; }
            case 2: if(_vertexRawData[index + 1] != y) { _buffersDirty = true; _vertexRawData[index + 1] = y; }
            case 1: if(_vertexRawData[index    ] != x) { _buffersDirty = true; _vertexRawData[index    ] = x; }
                break;

            default:
                throw new Error("vertex data size invalid (" + size + "for vertex: " + vertex + ", data id: " + id);
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

    /** Creates new vertex- and index-buffers and uploads our vertex- and index-data into these buffers. */
    private function createBuffers(context:Context3D):void {
        _buffersDirty = false;

        if (_vertexBuffer) _vertexBuffer.dispose();
        if (_indexBuffer)  _indexBuffer.dispose();

        _vertexBuffer = context.createVertexBuffer(vertexCount, _vertexFormat.totalSize);
        _vertexBuffer.uploadFromVector(_vertexRawData, 0, vertexCount);

        _indexBuffer = context.createIndexBuffer(_triangleData.length);
        _indexBuffer.uploadFromVector(_triangleData, 0, _triangleData.length);
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

    private function setVertexBuffers(context:Context3D):void {
        var count:int = _vertexFormat.propertyCount;
        for(var i:int = 0; i < count; i++) {
            var size:int    = _vertexFormat.getSize(i);
            var offset:int  = _vertexFormat.getOffset(i);

            var bufferFormat:String;

            switch(size) {
                case 1: bufferFormat = Context3DVertexBufferFormat.FLOAT_1; break;
                case 2: bufferFormat = Context3DVertexBufferFormat.FLOAT_2; break;
                case 3: bufferFormat = Context3DVertexBufferFormat.FLOAT_3; break;
                case 4: bufferFormat = Context3DVertexBufferFormat.FLOAT_4; break;

                default:
                    throw new Error("vertex data size invalid (" + size + ") for data index: " + i);
            }

            context.setVertexBufferAt(i, _vertexBuffer, offset, bufferFormat);
        }
    }

    private function unsetVertexBuffers(context:Context3D):void {
        var count:int = _vertexFormat.propertyCount;
        for(var i:int = 0; i < count; i++)
            context.setVertexBufferAt(i, null);
    }
}
}
