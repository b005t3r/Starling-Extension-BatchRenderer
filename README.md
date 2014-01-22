Batch Renderer Starling Extension
================================

Ever wanted to create a custom DisplayObject? Needed to render a non-rectangular geometry? Had to pass custom data via vertex atribute (va) registers to your shader? Cried inside (just a little) when custom texture processing was necessary? 

If so, I might have something just for you. Behold the Batch Renderer!

What is Batch Renderer?
=======================

Batch Renderer is an extension for Starling Framework - a GPU powered, 2D rendering framework. In Starling, all rendering is (mostly) done using Quad classes which, when added to the Starling's display list hierarchy, render a rectangular region onto the screen. But sometimes you want to do something than this and for that, you can use the BatchRenderer class.

First subclass it, like so...
```as3
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

```

... and use it in your code:

```as3
// add a new quad
var vertex:int = BatchRendererUtil.addQuad(texturedRenderer);                    

// setup Quad's vertices position...
texturedRenderer.setVertexPosition(vertex    ,  0,    0);                
texturedRenderer.setVertexPosition(vertex + 1, 100,   0);                
texturedRenderer.setVertexPosition(vertex + 2,   0, 100);                
texturedRenderer.setVertexPosition(vertex + 3, 100, 100);                
                                 
// ... UV mapping...                                                                         
texturedRenderer.setVertexUV(vertex    , 0, 0);                          
texturedRenderer.setVertexUV(vertex + 1, 1, 0);                          
texturedRenderer.setVertexUV(vertex + 2, 0, 1);                          
texturedRenderer.setVertexUV(vertex + 3, 1, 1);                          

// ... and an input texture
texturedRenderer.inputTexture = Texture.fromBitmap(new AmazingBitmap());
```

You can either render to texture target:
```as3
// create rendering settings to be used                                                                         
settings               = new RenderingSettings();                        
settings.blendMode     = BlendMode.NORMAL;                               
settings.clearColor    = 0xcccccc;                                       
settings.clearAlpha    = 1.0;                                            

// and render!
var outputTexture:RenderTexture = new RenderTexture(1024, 1024, false);
texturedRenderer.renderToTexture(renderTexture, settings);              
```

... or the back buffer, using Starling's display list:

```as3
var wrapper:BatchRendererWrapper = new BatchRendererWrapper(texturedRenderer);
addChild(wrapper);
```

Doesn't look that scary, does it? Let's have a look at it in details.

Subclassing
===========

Many of BatchRenderer methids are inside a special 'renderer_internal' namespace, so make sure to include this code:
```as3
use namespace renderer_internal;
```
before your newly created class.

Creating a custom VertexFormat
------------------------------

Then you need to create a new VertexFormat and set it:
```as3
public static const POSITION:String         = "position";
public static const UV:String               = "uv";
//...
private var _positionID:int, _uvID:int;
//...
public function TexturedGeometryRenderer() {
    setVertexFormat(createVertexFormat());
}
//...
private function createVertexFormat():VertexFormat {
    var format:VertexFormat = new VertexFormat();

    _positionID = format.addProperty(POSITION, 2);  // x, y; id: 0
    _uvID       = format.addProperty(UV, 2);        // u, v; id: 1

    return format;
}

```

Vertex format is crucial - it tells the BatchRenderer implementation how and what different kinds of data are going to store data in each vertex. With this TexturedGeometryRenderer each vertex stores two kinds of data: vertex position in 2D space (x, y) and texture mapping coords (u, v). Also notice, each kind of data, when added to VertexFormat (by addProperty() method) is registered with a unique name (here *"position"* and *"uv"*, passed via static constants) and once registered is given an unique id (stored in *'_positionID'* and *'_uvID'*). The former can be used in when writing shaders' code and the later is useful for fast accessing each property in AS3 code.

Adding property accessors
-------------------------

Talking about accessing properties, let's create some accessors to our geometry and shader properties.

```as3
public static const INPUT_TEXTURE:String = "inputTexture";
private var _positionID:int, _uvID:int;
//...
public function get inputTexture():Texture { return getInputTexture(INPUT_TEXTURE); } 
public function set inputTexture(value:Texture):void { setInputTexture(INPUT_TEXTURE, value); }

public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _positionID, position); }
public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, _positionID, x, y); }   

public function getVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _uvID, uv); }                        
public function setVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, _uvID, u, v); }            
```

As you can see, they are all one-liners. Each uses an internal *BatchRenderer* method and a vertex property ID created when registering each property with a vertex format. Now you know what these IDs are for - they let you access vertex properties efficiently (no string comparison needed).

You've probably already spoted the *inputTexture* property, which does not use a vertex property ID. That's because textures are not set per vertex (duh!) - they are bound to one of the texture samplers. *BatchRenderer* makes setting and accessing textures a bit easier. You simply register as many as you need (but no more than Stage3D let's you to, I guess it's 8... or 4... let's make it your homework to find out), each with an unique name. Our renderer will only need one texture, so we simply call it *"inputTexture"* (kind of dull, I know).

We're done here, all important properties can now be easily accessed using these few one-liner methods. Just one more thing to point out - none of these are really necessary. You could always include the *renderer_internal* namespace in your client code and use the setVertexData() methods directly, right? Well, yes, you could, but you have to admit, it's much more elegant this way, is it?

Writing shaders
---------------

Once you have your vertex format defined, it's time for writing some shaders.

AGAL is the shader language used by Stage3D. It is a simple assembly language, which means it's both - easy to understand and next to impossible to actually learn and use. Seriously, to me, it was a nightmare... until I found out about EasyAGAL. EasyAGAL is a great compromise between writing an efficient, assembly code and writing an easy to read and understand, high level, abstract code. If you've never heart about it, don't worry - you'll get the hang of it in no time. If you still think you won't, then... what the hell are you still doign here? :) This is a custom rendering extension after all, not an entry level tutorial! :)

OK, sorry for that. Shaders. Here they are:

```as3
public static const POSITION:String         = "position";
public static const UV:String               = "uv";
public static const INPUT_TEXTURE:String    = "inputTexture";
//...
// shader variables
private var uv:IRegister = VARYING[0];  // v0 is used to pass interpolated uv from vertex to fragment shader
//...
override protected function vertexShaderCode():void {                                                              
    comment("output vertex position");                                                                              
    multiply4x4(OUTPUT, getVertexAttribute(POSITION), getRegisterConstant(PROJECTION_MATRIX));                         
    
    comment("pass uv to fragment shader");                              
    move(uv, getVertexAttribute(UV));                                                                         
}

override protected function fragmentShaderCode():void {                                                                    var input:ISampler = getTextureSampler(INPUT_TEXTURE);                                                                                               
    comment("sample the texture and send resulting color to the output");                                                  sampleTexture(OUTPUT, uv, input, [TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_LINEAR, TextureFlag.MIP_NONE]);                    
}                                                                                                                   
```

Each shader is really a set of two shaders. As you can see, we have a vertex shader (implemented in 'vertexShaderCode()') and a fragment (pixel) shader (implemented in 'fragmentShaderCode()'). I'm not going to get into AGAL or shader specific details, but if you're completely new to any of this, there are only three things you need to know:
* vertex shader's job is sending coordinates (x, y) of each vertex to teh OUTPUT
* fragment shader's job is sending a pixel color to the output
* values can be passed from vertex to fragment shader via VARYING (v) registers; each value passed this way will be interpolated between vertices, acording to the pixel position fragment shader is outputing color for

Out vertex shader is a simple, standard one - probably most of your vertex shaders will look very similar. First it send the current position to the output, then it passes interpolated UVs to the fragment shader. But the interesting thing is not what it does, but how it does it.

As you can see there's no hardcoded registers there. Each vertex attribute register (va) is being accessed using the getVertexAttribute() method and a string, used when setting a vertex format. The vertex constant register (vc) holding the projection matrix is accessed in a similar way - using the getRegisterConstant() method.

Also notice how the UVs are passed. 
