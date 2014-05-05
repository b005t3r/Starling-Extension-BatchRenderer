/**
 * User: booster
 * Date: 16/01/14
 * Time: 14:43
 */
package starling.display {
import flash.geom.Matrix;
import flash.geom.Rectangle;

import starling.core.RenderSupport;
import starling.renderer.BatchRenderer;
import starling.renderer.GeometryData;
import starling.renderer.GeometryDataUtil;
import starling.utils.MatrixUtil;

/**
 * Custom DisplayObject for rendering contents of a BatchRenderer instance using Starling's display list.
 * Useful for creating custom display objects.
 */
public class BatchRendererWrapper extends DisplayObject {
    private static var _matrix:Matrix = new Matrix();

    protected var _geometry:GeometryData    = null;
    protected var _renderer:BatchRenderer   = null;
    protected var _positionID:int           = 0;

    private var _premultipliedAlpha:Boolean = false;

    private var _ownsRenderer:Boolean       = true;
    private var _ownsGeometry:Boolean       = true;

    private var _batchable:Boolean          = true;
    private var _batched:Boolean            = false; // used internally when rendering a batch of wrappers

    public function get geometry():GeometryData { return _geometry; }
    public function set geometry(value:GeometryData):void { _geometry = value; }

    public function get renderer():BatchRenderer { return _renderer; }
    public function set renderer(value:BatchRenderer):void { _renderer = value; }

    public function get positionID():int { return _positionID; }
    public function set positionID(value:int):void { _positionID = value; }

    public function get ownsRenderer():Boolean { return _ownsRenderer; }
    public function set ownsRenderer(value:Boolean):void { _ownsRenderer = value; }

    public function get ownsGeometry():Boolean { return _ownsGeometry; }
    public function set ownsGeometry(value:Boolean):void { _ownsGeometry = value; }

    public function get premultipliedAlpha():Boolean { return _premultipliedAlpha; }
    public function set premultipliedAlpha(value:Boolean):void { _premultipliedAlpha = value; }

    public function get batchable():Boolean { return _batchable; }
    public function set batchable(value:Boolean):void { _batchable = value; }

    override public function dispose():void {
        if(_ownsRenderer) _renderer.dispose();
        if(_ownsGeometry) _geometry.dispose();

        super.dispose();
    }

    override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle {
        if(_geometry == null) return null;

        if(resultRect == null) resultRect = new Rectangle();

        var transformationMatrix:Matrix = getTransformationMatrix(targetSpace, _matrix);

        return GeometryDataUtil.getGeometryBounds(_geometry, _positionID, 0, -1, resultRect, transformationMatrix);
    }

    override public function render(support:RenderSupport, parentAlpha:Number):void {
        if(_renderer == null || _geometry == null) return;

        if(! _batchable) {
            _renderer.resetGeometry();
            _renderer.appendGeometry(_geometry);

            _renderer.renderToBackBuffer(support, _premultipliedAlpha);
        }
        else if(! _batched) {
            support.popMatrix();

            _renderer.resetGeometry();
            _renderer.appendGeometry(_geometry, transformationMatrix, _positionID);

            var index:int = parent.getChildIndex(this);

            var count:int = parent.numChildren;
            for(var i:int = index + 1; i < count; ++i) {
                var wrapper:BatchRendererWrapper = parent.getChildAt(i) as BatchRendererWrapper;

                if(wrapper == null || ! wrapper._batchable || ! wrapper.geometry.vertexFormat.isCompatible(_geometry.vertexFormat))
                    break;

                wrapper._batched = true;
                _renderer.appendGeometry(wrapper._geometry, wrapper.transformationMatrix, wrapper._positionID);
            }

            _renderer.renderToBackBuffer(support, _premultipliedAlpha);

            support.pushMatrix();
            support.transformMatrix(this); // parent expects this to be set
        }

        // reset batched flag
        _batched = false;
    }
}
}
