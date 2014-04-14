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
import starling.renderer.BatchRendererUtil;
import starling.utils.MatrixUtil;

/**
 * Custom DisplayObject for rendering contents of a BatchRenderer instance using Starling's display list.
 * Useful for creating custom display objects.
 */
public class BatchRendererWrapper extends DisplayObject {
    private static var _matrix:Matrix = new Matrix();

    protected var _renderer:BatchRenderer;
    private var _premultipliedAlpha:Boolean;

    private var _ownsRenderer:Boolean;
    private var _positionID:int;

    /**
     * Creates a new wrapper.
     *
     * @param renderer              BatchRenderer displayed by this wrapper
     * @param premultipliedAlpha    does renderer use premultiplied alpha?, @default false
     * @param vertexPositionID      which vertex attribute index does renderer use for 2D position data (FLOAT_2: x, y), @default 0
     * @param ownsRenderer          if set to true the renderer will be disposed along with this object, @default true
     */
    public function BatchRendererWrapper(renderer:BatchRenderer, premultipliedAlpha:Boolean = false, vertexPositionID:int = 0, ownsRenderer:Boolean = true) {
        _renderer           = renderer;
        _positionID         = vertexPositionID;
        _ownsRenderer       = ownsRenderer;
        _premultipliedAlpha = premultipliedAlpha;
    }

    public function get premultipliedAlpha():Boolean { return _premultipliedAlpha; }
    public function set premultipliedAlpha(value:Boolean):void { _premultipliedAlpha = value; }

    override public function dispose():void {
        if(_ownsRenderer) _renderer.dispose();

        super.dispose();
    }

    override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle {
        if (resultRect == null) resultRect = new Rectangle();

        var transformationMatrix:Matrix = getTransformationMatrix(targetSpace, _matrix);

        return BatchRendererUtil.getGeometryBounds(_renderer, _positionID, 0, -1, resultRect, transformationMatrix);
    }

    override public function render(support:RenderSupport, parentAlpha:Number):void {
        _renderer.renderToBackBuffer(support, _premultipliedAlpha);
    }
}
}
