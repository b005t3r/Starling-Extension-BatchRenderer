/**
 * User: booster
 * Date: 15/05/15
 * Time: 9:00
 */
package starling.display {
import flash.geom.Matrix;
import flash.geom.Rectangle;

import starling.core.RenderSupport;

import starling.textures.RenderTexture;
import starling.utils.getNextPowerOfTwo;

public class BufferedSprite extends Sprite {
    private static var _helperBounds:Rectangle  = new Rectangle();
    private static var _helperMatrix:Matrix     = new Matrix();

    protected var _bufferTexture:RenderTexture;
    protected var _bufferImage:Image;

    protected var _minTextureWidth:Number   = 64;
    protected var _maxTextureWidth:Number   = Infinity;
    protected var _minTextureHeight:Number  = 64;
    protected var _maxTextureHeight:Number  = Infinity;

    private var _bufferingEnabled:Boolean;

    public function BufferedSprite() {
    }

    public function get bufferingEnabled():Boolean { return _bufferingEnabled; }
    public function set bufferingEnabled(value:Boolean):void { _bufferingEnabled = value; }

    public function get minTextureWidth():Number { return _minTextureWidth; }
    public function set minTextureWidth(value:Number):void { _minTextureWidth = value; }

    public function get maxTextureWidth():Number { return _maxTextureWidth; }
    public function set maxTextureWidth(value:Number):void { _maxTextureWidth = value; }

    public function get minTextureHeight():Number { return _minTextureHeight; }
    public function set minTextureHeight(value:Number):void { _minTextureHeight = value; }

    public function get maxTextureHeight():Number { return _maxTextureHeight; }
    public function set maxTextureHeight(value:Number):void { _maxTextureHeight = value; }

    override public function render(support:RenderSupport, parentAlpha:Number):void {
        if(! _bufferingEnabled) {
            super.render(support, parentAlpha);
            return;
        }

        var count:int = numChildren;
        if(count == 0) return;

        var bounds:Rectangle = getBounds(this, _helperBounds);
        var matrix:Matrix = _helperMatrix;

        if(!isBufferTextureValid())
            validateBufferTexture();

        _bufferTexture.drawBundled(function ():void {
            for(var i:int = 0; i < count; ++i) {
                var child:DisplayObject = getChildAt(i);

                matrix.identity();
                matrix.translate(-bounds.x, -bounds.y);
                matrix.concat(child.transformationMatrix);

                _bufferTexture.draw(child, matrix);
            }
        });

        _bufferImage.x = bounds.x;
        _bufferImage.y = bounds.y;

        support.pushMatrix();
        support.transformMatrix(_bufferImage);
        support.blendMode = BlendMode.NORMAL;

        _bufferImage.render(support, alpha);

        support.blendMode = blendMode;
        support.popMatrix();
    }

    protected function createBufferTexture(width:Number, height:Number):RenderTexture {
        return new RenderTexture(width, height, false);
    }

    protected function setBufferTexture(texture:RenderTexture):void {
        if(_bufferTexture != null) {
            _bufferTexture.dispose();
            _bufferTexture = null;
        }

        if(texture != null) {
            _bufferTexture = texture;
            _bufferImage = new Image(_bufferTexture);
        }
    }

    protected function isBufferTextureValid():Boolean {
        if(_bufferTexture == null)
            return false;

        var bounds:Rectangle        = getBounds(parent, _helperBounds);
        var desiredWidth:Number     = getNextPowerOfTwo(bounds.width);
        var desiredHeight:Number    = getNextPowerOfTwo(bounds.height);

        desiredWidth    = desiredWidth  > _minTextureWidth  ? desiredWidth  : _minTextureWidth;
        desiredWidth    = desiredWidth  < _maxTextureWidth  ? desiredWidth  : _maxTextureWidth;
        desiredHeight   = desiredHeight > _minTextureHeight ? desiredHeight : _minTextureHeight;
        desiredHeight   = desiredHeight < _maxTextureHeight ? desiredHeight : _maxTextureHeight;

        return _bufferTexture.width == desiredWidth && _bufferTexture.height == desiredHeight;
    }

    protected function validateBufferTexture():void {
        var bounds:Rectangle        = getBounds(parent, _helperBounds);
        var desiredWidth:Number     = getNextPowerOfTwo(bounds.width);
        var desiredHeight:Number    = getNextPowerOfTwo(bounds.height);

        setBufferTexture(createBufferTexture(desiredWidth, desiredHeight));
    }
}
}
