Batch Renderer Starling Extension
================================

Ever wanted to create a custom DisplayObject? Needed to render a non-rectangular geometry? Had to pass custom data via vertex attribute (va) registers to your shader? Cried inside (just a little) when custom texture processing was necessary? 

If so, I might have something just for you. Behold the Batch Renderer!

What is Batch Renderer?
=======================

Batch Renderer is an extension for Starling Framework - a GPU powered, 2D rendering framework. In Starling, rendering is (mostly) done using Quad classes which, when added to the Starling's display list, render a rectangular region onto the screen. That's very efficient and works great for most use cases, but sometimes you want to do something else. Something like:
<dl>
  <dt>Custom DisplayObjects</dt>
  <dd>This is of course possible to do using only Starling, but with BatchRenderer you'll be able to do it easier and quicker. Plus you won't be limited to Starling's vertex format, which can only hold position, UVs and color data.</dd>
  <dt>Blend modes impossible to set up with simple setBlendFactors() call</dt>
  <dd>Some blend modes are impossible to do by just setting the Stage3D blend factors. Overlay is a good example: It's a mix of multiply and screen, and the decision which one should be used is made based on bottom layer's pixel value. Stage3D can't do that for you, but a custom renderer can.</dd>
  <dt>Algorithms that make use of GPU's parallel processing</dt>
  <dd>Probably something like this is a good example: https://github.com/mattdesl/lwjgl-basics/wiki/2D-Pixel-Perfect-Shadows</dd>
</dl>

So where do we start?

First subclass the necassary classes, like so...
```as3

// your geometry's vertex format - what data each vertex stores
public class TexturedGeometryVertexFormat extends VertexFormat {
    public static const cachedInstance:TexturedGeometryVertexFormat = new TexturedGeometryVertexFormat();

    public static const UV:String = "uv";

    public var uvID:int;

    public function TexturedGeometryVertexFormat() {
        if(cachedInstance != null) throw new Error("format already initialized");
        
        // note: every vertex format has 2D position property added by default in the base class
        uvID = addProperty(UV, 2); // u, v; id: 1
    }
}

// your geometry - stores vertices and triangles to be rendered
public class TexturedGeometryData extends GeometryData {
    public function TexturedGeometryData() {
        super(TexturedGeometryVertexFormat.cachedInstance);
    }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.positionID, x, y); }

    public function getVertexUV(vertex:int, uv:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.uvID, uv); }
    public function setVertexUV(vertex:int, u:Number, v:Number):void { setVertexData(vertex, TexturedGeometryVertexFormat.cachedInstance.uvID, u, v); }
}

// your geometry's renderer - a pair of vertex and fragment shaders basically
public class TexturedGeometryRenderer extends BatchRenderer {
    public function TexturedGeometryRenderer() {
        super(TexturedGeometryVertexFormat.cachedInstance);
    }

    override protected function vertexShaderCode():void {
        // your vertex shader code here
    }

    override protected function fragmentShaderCode():void {
        // your fragment
    }
}
```

... and use it in your code:

```as3
// add a new quad
var renderer:TexturedGeometryRenderer = new TexturedGeometryRenderer();
var geometry:TexturedGeometryData = new TexturedGeometryData();

var vertex:int = BatchRendererUtil.addQuad(geometry);                    

// setup Quad's vertices position...
geometry.setVertexPosition(vertex    ,  0,    0);                
geometry.setVertexPosition(vertex + 1, 100,   0);                
geometry.setVertexPosition(vertex + 2,   0, 100);                
geometry.setVertexPosition(vertex + 3, 100, 100);                
                                 
// ... UV mapping...                                                                         
geometry.setVertexUV(vertex    , 0, 0);                          
geometry.setVertexUV(vertex + 1, 1, 0);                          
geometry.setVertexUV(vertex + 2, 0, 1);                          
geometry.setVertexUV(vertex + 3, 1, 1);                          

// ... and an input texture
renderer.inputTexture = Texture.fromBitmap(new AmazingBitmap());
```

You can either render to texture target:
```as3
// add geometry to renderer
renderer.addGeometry(geometry);

// create rendering settings to be used                                                                         
settings               = new RenderingSettings();                        
settings.blendMode     = BlendMode.NORMAL;                               
settings.clearColor    = 0xcccccc;                                       
settings.clearAlpha    = 1.0;                                            

// and render!
var outputTexture:RenderTexture = new RenderTexture(1024, 1024, false);
renderer.renderToTexture(renderTexture, settings);              
```

... or the back buffer, using Starling's display list and provided wrapper:

```as3
var wrapper:BatchRendererWrapper = new BatchRendererWrapper(renderer, geometry);
addChild(wrapper);
```
Doesn't look that scary, does it? Let's have a look at it in details.

Subclassing
===========

Creating a custom VertexFormat
------------------------------

First you need to define your geometry's *VertexFormat*. Typically you do that by subclassing:
```as3
public class TexturedGeometryVertexFormat extends VertexFormat {
    public static const cachedInstance:TexturedGeometryVertexFormat = new TexturedGeometryVertexFormat();

    public static const UV:String = "uv";

    public var uvID:int;

    public function TexturedGeometryVertexFormat() {
        if(cachedInstance != null) throw new Error("creating new instance forbidded; use cachedInstance");

        uvID = addProperty(UV, 2); // u, v; id: 1
    }
}
```

*VertexFormat* is crucial - it tells the *BatchRenderer* implementation what different kinds of data are stored in each vertex. With this (really simple) *TexturedGeometryVertexFormat* each vertex stores two kinds of data: vertex position (set by teh base class - every vertex has to store position, duh!) in 2D space (*x*, *y*) and texture mapping coords (set by the subclass - *u*, *v*). Also notice, each kind of data, when added to *VertexFormat* (by *addProperty()* method) is registered with an unique name (here *"position"* and *"uv"*, passed via static constants) and once registered, is given an unique ID (stored in *'uvID'*). The former can be used when writing shaders and the later is useful for efficiently accessing each property in AS3 code (more on these later).

Creating a custom geometry
--------------------------



Adding property accessors
-------------------------

Talking about accessing properties, let's create some accessors for our geometry and shader data. Client code will call these to set up things to be rendered.

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

As you can see, they are all one-liners and all use internal *BatchRenderer* methods and vertex unique property IDs created when registering each property within *VertexFormat*. Now you can see what these IDs are for and how they let vertex properties to be accessed more efficiently than by using strings (hint: no string comparison is needed).

Also, you've probably spotted the *inputTexture* property already, which does not use a vertex unique property ID. That's because textures are not set per vertex (duh!) - they are bound to one of the texture samplers. *BatchRenderer* makes setting and accessing textures really easy. You simply register as many as you need (but no more than Stage3D let's you to, I guess it's 8... or 4... let's make it your homework to find out), each with an unique name. Our renderer will only need one texture, so we simply call it *"inputTexture"* (kind of dull, I know). Same goes for constant registers (which we don't explicitly set here) - you set constants per shader, not per vertex.

Writing shaders
---------------

Once you have your vertex format defined and your property accessors in place, it's time to add some shaders. 

AGAL is the shader language used by Stage3D. It is a simple assembly language, which means it's both: a) easy to understand and b) next to impossible to actually learn and use. Seriously, to me, it was a nightmare... until I found out about EasyAGAL! EasyAGAL is a great compromise between writing an efficient, assembly code and writing an easy to read and understand, high level, abstract code. If you've never heard about it, don't worry - you'll get the hang of it in no time. If you think you won't, then... what the hell are you still doing here? :) This is a custom rendering extension after all, not an entry level tutorial! :)

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

override protected function fragmentShaderCode():void {
    var input:ISampler = getTextureSampler(INPUT_TEXTURE);
    
    comment("sample the texture and send resulting color to the output");
    sampleTexture(OUTPUT, uv, input, [TextureFlag.TYPE_2D, TextureFlag.MODE_CLAMP, TextureFlag.FILTER_LINEAR, TextureFlag.MIP_NONE]);                    
}                                                                                                                   
```

Every renderer is really a set of two shaders. As you can see, we have a vertex shader (implemented in *vertexShaderCode()*) and a fragment (pixel) shader (implemented in *fragmentShaderCode()*). I'm not going to get into AGAL or shader specific details, but if you're completely new to any of this, there are only three things you need to know:
* vertex shader's job is sending coordinates (*x*, *y*) of each vertex to the *OUTPUT*
* fragment shader's job is sending a color of each pixel being processed to the *OUTPUT*
* values can be passed from vertex to fragment shader via *VARYING* (*v*) registers; each value passed this way will be interpolated between vertices, according to the pixel position fragment shader is working on

Our vertex shader is a simple, standard one - probably most of your vertex shaders will look very similar. First it sends the current position to the output, then it passes interpolated UVs to the fragment shader. But the interesting thing is not what it does, but how it does it.

As you can see there's no hardcoded registers there. Each vertex attribute register (*va*) is being accessed using *getVertexAttribute()* method and a string, used when setting a vertex format (*"position"* and *"uv"*). The vertex constant register (*vc*) holding the projection matrix is accessed in a similar way - using *getRegisterConstant()* method (we haven't set this one explicitly, it's the only constant set by the base *BatchRenderer* class internally). 
Also notice how the UVs are passed. EasyAGAL's magic let's us define *VARYING* register 0 (*v0*) as a class variable, so in both of our shaders we don't have to reference UVs as *VARYING[0]* - we can simply use the variable. OK, it's nothing really spectacular, but it makes code much easier to read and understand.

And finally the fragment shader. All it does is sampling the input texture using the interpolated UVs passed from vertex shader and sending the result color to the OUTPUT. All of this done using only one instruction and few self-describing variables. Again, it doesn't really matter with this particular shader if you code it in AGAL assembly or using fancy looking variables and functions, but with more complex shaders, it does make a difference.

Is that it?
-----------

Yes, pretty much that's it. So, if you're interested in checking Batch Renderer out, download the code and launch the demos included. It should give you an idea of how to use this extension.

You'll also need these to make it work:
* [Starling Framework](https://github.com/PrimaryFeather/Starling-Framework/)
* [EasyAGAL](https://github.com/Barliesque/EasyAGAL)
