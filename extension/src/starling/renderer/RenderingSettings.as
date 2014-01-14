/**
 * User: booster
 * Date: 16/01/14
 * Time: 14:48
 */
package starling.renderer {
import flash.geom.Matrix;
import flash.geom.Rectangle;

import starling.display.BlendMode;
import starling.textures.Texture;

public class RenderingSettings {
    private var _premultipliedAlpha:Boolean     = false;
    private var _blendMode:String               = BlendMode.NONE;
    private var _clippingRectangle:Rectangle    = new Rectangle();
    private var _clippingEnabled:Boolean        = false;
    private var _inputTransform:Matrix          = new Matrix();
    private var _inputTransformed:Boolean       = false;
    private var _clearColor:uint                = 0x000000;
    private var _clearAlpha:Number              = 0.0;

    public function get premultipliedAlpha():Boolean { return _premultipliedAlpha; }
    public function set premultipliedAlpha(value:Boolean):void { _premultipliedAlpha = value; }

    public function set blendMode(value:String):void { _blendMode = value; }
    public function get blendMode():String { return _blendMode; }

    public function get clippingRectangle():Rectangle { return _clippingEnabled ? _clippingRectangle : null; }
    public function get clippingEnabled():Boolean { return _clippingEnabled; }
    public function disableClipping():void { _clippingEnabled = false; }
    public function enableClipping(x:Number, y:Number, width:Number, height:Number):void {
        _clippingEnabled = true;
        _clippingRectangle.setTo(x, y, width, height);
    }

    public function get inputTransform():Matrix { return _inputTransformed ? _inputTransform : null; }
    public function get inputTransformed():Boolean { return _inputTransformed; }
    public function disableInputTransform():void { _inputTransformed = false; }
    public function enableInputTransform():void {
        if(_inputTransformed)
            return;

        _inputTransformed = true;
        _inputTransform.identity();
    }

    public function get clearColor():uint { return _clearColor; }
    public function set clearColor(value:uint):void { _clearColor = value; }

    public function get clearAlpha():Number { return _clearAlpha; }
    public function set clearAlpha(value:Number):void { _clearAlpha = value; }
}
}
