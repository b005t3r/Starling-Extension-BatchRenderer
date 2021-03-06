/**
 * User: booster
 * Date: 22/03/15
 * Time: 9:44
 */
package starling.display {
import flash.geom.Rectangle;

import starling.core.RenderSupport;
import starling.display.blend.ILayerBlendMode;
import starling.display.blend.StarlingBlendMode;
import starling.textures.RenderTexture;
import starling.utils.getNextPowerOfTwo;

use namespace layered_sprite_internal;

public class LayeredSprite extends Sprite {
    private static const _helperRect:Rectangle              = new Rectangle();

    private var _layerOrder:Vector.<String>                 = new <String>[];
    private var _layerBlendModes:Vector.<ILayerBlendMode>   = new <ILayerBlendMode>[];
    private var _layerOrderChanged:Boolean                  = true;

    private var _renderTextures:Vector.<RenderTexture>      = new <RenderTexture>[];
    private var _usedTextures:Vector.<Boolean>              = new <Boolean>[];

    private var _minTextureWidth:Number                     = 128;
    private var _maxTextureWidth:Number                     = Infinity;
    private var _minTextureHeight:Number                    = 128;
    private var _maxTextureHeight:Number                    = Infinity;

    private var _destinationTexture:RenderTexture;
    private var _wrapperImage:Image;

    public function LayeredSprite() {
    }

    public function get minTextureWidth():Number { return _minTextureWidth; }
    public function set minTextureWidth(value:Number):void { _minTextureWidth = value; }

    public function get maxTextureWidth():Number { return _maxTextureWidth; }
    public function set maxTextureWidth(value:Number):void { _maxTextureWidth = value; }

    public function get minTextureHeight():Number { return _minTextureHeight; }
    public function set minTextureHeight(value:Number):void { _minTextureHeight = value; }

    public function get maxTextureHeight():Number { return _maxTextureHeight; }
    public function set maxTextureHeight(value:Number):void { _maxTextureHeight = value; }

    /** Read only, do not modify the contents. */
    public function get layerOrder():Vector.<String> { return _layerOrder; }

    public function addLayer(layer:DisplayObject, name:String):void {
        if(getChildByName(name) != null) throw new ArgumentError("layer with such name already registered");

        _layerOrderChanged = true;
        _layerBlendModes[_layerBlendModes.length] = null;

        layer.name = name;

        addChild(layer);
    }

    public function getLayer(name:String):DisplayObject {
        return getChildByName(name);
    }

    public function getBlendMode(name:String):ILayerBlendMode {
        var layer:DisplayObject = getChildByName(name);

        if(layer == null)
            throw new ArgumentError("no such layer: " + name);

        return _layerBlendModes[getChildIndex(layer)];
    }

    public function setBlendMode(mode:ILayerBlendMode, layerName:String):void {
        var layer:DisplayObject = getChildByName(layerName);

        if(layer == null)
            throw new ArgumentError("no such layer: " + layerName);

        if(_layerBlendModes.length < numChildren)
            _layerBlendModes.length = numChildren;

        _layerBlendModes[getChildIndex(layer)] = mode;
    }

    public function setLayerOrder(... layerOrder):void {
        if(layerOrder is Array == false && layerOrder is Vector != false)
            throw new ArgumentError("'layerOrder' has to be Array or Vector.<String>");

        if(layerOrder.length != numChildren)
            throw new ArgumentError("'layerOrder' has to be the same size as 'numChildren'");

        var count:int = _layerOrder.length = layerOrder.length;
        for(var i:int = 0; i < count; ++i)
            _layerOrder[i] = layerOrder[i];

        _layerOrderChanged = true;
    }

    override public function dispose():void {
        destinationTexture = null;

        var count:int = _renderTextures.length;
        for(var i:int = 0; i < count; ++i) {
            var texture:RenderTexture = _renderTextures[i];
            texture.dispose();
        }

        super.dispose();
    }

    override public function render(support:RenderSupport, parentAlpha:Number):void {
        var cr:Rectangle = clipRect;

        if(cr) {
            var currClipRect:Rectangle = support.pushClipRect(getClipRect(stage, _helperRect));
            if(currClipRect.isEmpty()) {
                // empty clipping bounds - no need to render children.
                support.popClipRect();
                return;
            }
        }

        renderToOutputTexture();

        _wrapperImage.alpha     = this.alpha;
        _wrapperImage.blendMode = this.blendMode;

        _wrapperImage.render(support, parentAlpha);

        if (cr)
            support.popClipRect();
    }

    layered_sprite_internal function renderToOutputTexture():void {
        var numChildren:int = this.numChildren;

        if(_layerOrderChanged) {
            if(_layerOrder.length != numChildren)
                throw new ArgumentError("layer order not set, call setLayerOrder() first");

            _layerOrderChanged = false;

            sortLayers();
        }

        if(needsTextureAdjustment())
            adjustTextureSizes();

        _destinationTexture.clear();

        var defaultBlendMode:ILayerBlendMode = StarlingBlendMode.getBlendMode(BlendMode.NORMAL);

        for(var i:int = 0; i < numChildren; ++i) {
            var layer:DisplayObject = getChildAt(i);

            if(!layer.hasVisibleArea)
                continue;

            var blendMode:ILayerBlendMode = _layerBlendModes[i] != null ? _layerBlendModes[i] : defaultBlendMode;

            blendMode.blend(layer, this);
        }
    }

    layered_sprite_internal function get destinationTexture():RenderTexture { return _destinationTexture; }
    layered_sprite_internal function set destinationTexture(value:RenderTexture):void {
        if(_destinationTexture != null) {
            freeTemporaryRenderTexture(_destinationTexture);
            _destinationTexture = null;
        }

        if(value != null) {
            var index:int = _renderTextures.indexOf(value);
            if(index < 0 || ! _usedTextures[index])
                throw new ArgumentError("only a RenderTexture allocated by this LayeredSprite and marked as used can be set as a destinationTexture");

            _destinationTexture = value;
            _wrapperImage = new Image(_destinationTexture);
        }
    }

    layered_sprite_internal function getTemporaryRenderTexture():RenderTexture {
        var count:int = _renderTextures.length;
        for(var i:int = 0; i < count; ++i) {
             if(_usedTextures[i])
                continue;

            _usedTextures[i] = true;
            return _renderTextures[i];
        }

        _usedTextures[i]    = true;
        _renderTextures[i]  = new RenderTexture(getNextPowerOfTwo(width), getNextPowerOfTwo(height), true);

        return _renderTextures[i];
    }

    layered_sprite_internal function freeTemporaryRenderTexture(texture:RenderTexture):void {
        var index:int = _renderTextures.indexOf(texture);

        if(index < 0)
            throw new ArgumentError("this RenderTexture was allocated outside of this LayeredSprite");

        _usedTextures[index] = false;
    }

    private function sortLayers():void {
        var count:int = _layerOrder.length;
        for(var i:int = 0; i < count; ++i) {
            var name:String = _layerOrder[i];

            var layer:DisplayObject = getChildByName(name);
            var j:int               = getChildIndex(layer);

            if(i != j) {
                swapChildrenAt(i, j);

                var temp:ILayerBlendMode    = _layerBlendModes[i];
                _layerBlendModes[i]         = _layerBlendModes[j];
                _layerBlendModes[j]         = temp;
            }
        }
    }

    private function needsTextureAdjustment():Boolean {
        if(_destinationTexture == null)
            return true;

        var rect:Rectangle          = _helperRect;

        getBounds(parent, rect);

        var desiredWidth:Number     = getNextPowerOfTwo(int(rect.width));
        var desiredHeight:Number    = getNextPowerOfTwo(int(rect.height));

        desiredWidth = desiredWidth > _minTextureWidth ? desiredWidth : _minTextureWidth;
        desiredWidth = desiredWidth < _maxTextureWidth ? desiredWidth : _maxTextureWidth;

        desiredHeight = desiredHeight > _minTextureHeight ? desiredHeight : _minTextureHeight;
        desiredHeight = desiredHeight < _maxTextureHeight ? desiredHeight : _maxTextureHeight;

        if(_destinationTexture.width != desiredWidth || _destinationTexture.height != desiredHeight)
            return true;

        return false;
    }

    private function adjustTextureSizes():void {
        destinationTexture = null;

        var count:int = _renderTextures.length;
        for(var i:int = 0; i < count; ++i) {
            var texture:RenderTexture = _renderTextures[i];
            texture.dispose();
        }

        _renderTextures.length = _usedTextures.length = 0;
        destinationTexture = getTemporaryRenderTexture();

//        trace("New texture size: [" + destinationTexture.width + ", " + destinationTexture.height + "]");
//        trace("x: " + x + ", y: " + y);
    }
}
}
