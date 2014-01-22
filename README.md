Batch Renderer Starling Extension
================================

Ever wanted to create a custom DisplayObject? Needed to render a non-rectangular geometry? Had to pass custom data via vertex atribute (va) registers to your shader? Cried inside (just a little) when custom texture processing was necessary? 

If so, I might have something just for you. Behold the Batch Renderer!

What is Batch Renderer?
=======================

Batch Renderer is an extension for Starling Framework - a GPU powered, 2D rendering framework. In Starling, rendering is (mostly) done using Quad classes which, when added to the Starling's display list hierarchy, render a rectangular region onto the screen. That's very efficient and works great or most use cases, but sometimes you want to do something else. Something like:
*
*
*

So where do we start?

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

Many of BatchRenderer methods are "hidden" in a special *renderer_internal* namespace, so make sure to include this code:
```as3
use namespace renderer_internal;
```
before your newly created class.

Creating a custom VertexFormat
------------------------------

First you need to define your renderer's *VertexFormat* and set it:
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

*VertexFormat* is crucial - it tells the *BatchRenderer* implementation how and what different kinds of data are going to be stored in each vertex. With this (really simple) *TexturedGeometryRenderer* each vertex stores two kinds of data: vertex position in 2D space (*x*, *y*) and texture mapping coords (*u*, *v*). Also notice, each kind of data, when added to *VertexFormat* (by *addProperty()* method) is registered with an unique name (here *"position"* and *"uv"*, passed via static constants) and once registered, is given an unique ID (stored in *'_positionID'* and *'_uvID'*). The former can be used in when writing shaders' code and the later is useful for efficiently accessing each property in AS3 code (more on this later).

Adding property accessors
-------------------------

Talking about accessing properties, let's create some accessors for our geometry and shader properties. Client code will call these to set up geometry to be rendered.

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

As you can see, they are all one-liners. Each uses an internal *BatchRenderer* method and a vertex unique property ID created when registering each property within *VertexFormat*. Now you can see what these IDs are for and how they let vertex properties to be accessed more efficiently than by using strings (hint: no string comparison is needed).

Also, you've probably spoted the *inputTexture* property already, which does not use a vertex unique property ID. That's because textures are not set per vertex (duh!) - they are bound to one of the texture samplers. *BatchRenderer* makes setting and accessing textures really easy. You simply register as many as you need (but no more than Stage3D let's you to, I guess it's 8... or 4... let's make it your homework to find out), each with an unique name. Our renderer will only need one texture, so we simply call it *"inputTexture"* (kind of dull, I know). Same goes for constant registers (which we don't explicitely set here) - you set constats per shader, not per vertex.

OK, we're done here. All essential properties can now be easily accessed using these few one-liner methods. But there's just one more thing to point out - none of these methods are really necessary. You could as well include the *renderer_internal* namespace in your client code and use the setVertexData() methods directly, right? Well, yes, you could, but you have to admit, it's much more elegant this way.

Writing shaders
---------------

Once you have your vertex format defined and your property accessors in place, it's time to add some shaders. 

AGAL is the shader language used by Stage3D. It is a simple assembly language, which means it's both - easy to understand and next to impossible to actually learn and use. Seriously, to me, it was a nightmare... until I found out about EasyAGAL! EasyAGAL is a great compromise between writing an efficient, assembly code and writing an easy to read and understand, high level, abstract code. If you've never heard about it, don't worry - you'll get the hang of it in no time. If you think you won't, then... what the hell are you still doing here? :) This is a custom rendering extension after all, not an entry level tutorial! :)

Sorry for that. Shaders. Here we go:

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

Each renderer is really a set of two shaders. As you can see, we have a vertex shader (implemented in 'vertexShaderCode()') and a fragment (pixel) shader (implemented in 'fragmentShaderCode()'). I'm not going to get into AGAL or shader specific details, but if you're completely new to any of this, there are only three things you need to know:
* vertex shader's job is sending coordinates (x, y) of each vertex to the OUTPUT
* fragment shader's job is sending a color of each pixel being processed to the output
* values can be passed from vertex to fragment shader via VARYING (v) registers; each value passed this way will be interpolated between vertices, acording to the pixel position fragment shader is working on

Our vertex shader is a simple, standard one - probably most of your vertex shaders will look very similar. First it sends the current position to the output, then it passes interpolated UVs to the fragment shader. But the interesting thing is not what it does, but how it does it.

As you can see there's no hardcoded registers there. Each vertex attribute register (*va*) is being accessed using the getVertexAttribute() method and a string, used when setting a vertex format (*"position"* and *"uv"*). The vertex constant register (*vc*) holding the projection matrix is accessed in a similar way - using the getRegisterConstant() method (we haven't set this one explicitely, it's the only constatnt set by the base *BatchRenderer* class internally). 
Also notice how the UVs are passed. EasyAGAL's magic let's us define *VARYING* register 0 (*v0*) as a class variable, so in both of our shaders we don't have to reference UVs as *VARYING[0]* - we can simply use the variable. OK, it's nothing really spectacular, but it makes code much easier to read and understand.

And finally the fragment shader. All it does is sampling the input texture using the interpolated UVs passed from vertex shader and sending the result color to the OUTPUT. All of this done using only one instruction and few self-describing variables. It doesn't really matter with this particular shader if you code it in AGAL assembly or using fancy looking variables and functions, but with more complex shaders, it really makes a difference.

