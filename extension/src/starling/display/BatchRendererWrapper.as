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
import starling.renderer.geometry.GeometryDataUtil;
import starling.renderer.geometry.IGeometryData;

/** Custom DisplayObject for rendering contents of a BatchRenderer instance using Starling's display list. */
public class BatchRendererWrapper extends DisplayObject {
    private static var _matrix:Matrix = new Matrix();

    protected var _geometry:IGeometryData   = null;
    protected var _renderer:BatchRenderer   = null;

    private var _premultipliedAlpha:Boolean = false;

    private var _ownsRenderer:Boolean       = true;

    private var _batchable:Boolean          = true;
    private var _batched:Boolean            = false; // used internally when rendering a batch of wrappers

    public function BatchRendererWrapper(geometry:IGeometryData, renderer:BatchRenderer) {
        this.geometry = geometry;
        this.renderer = renderer;
    }

    /** Geometry to render. */
    public function get geometry():IGeometryData { return _geometry; }
    public function set geometry(value:IGeometryData):void {
        if(value == null) throw new ArgumentError("geometry cannot be null");

        _geometry = value;
    }

    /** Renderer used to render geometry. */
    public function get renderer():BatchRenderer { return _renderer; }
    public function set renderer(value:BatchRenderer):void {
        if(value == null) throw new ArgumentError("renderer cannot be null");

        _renderer = value;
    }

    /** Renderer will be disposed along with this display object. @default true */
    public function get ownsRenderer():Boolean { return _ownsRenderer; }
    public function set ownsRenderer(value:Boolean):void { _ownsRenderer = value; }

    /** Premultiplied alpha. @default false */
    public function get premultipliedAlpha():Boolean { return _premultipliedAlpha; }
    public function set premultipliedAlpha(value:Boolean):void { _premultipliedAlpha = value; }

    /** Should this wrapper be batched along with other wrappers using the same renderer? @default true */
    public function get batchable():Boolean { return _batchable; }
    public function set batchable(value:Boolean):void { _batchable = value; }

    override public function dispose():void {
        if(_ownsRenderer) _renderer.dispose();

        super.dispose();
    }

    override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle {
        if(_geometry == null) return null;

        if(resultRect == null) resultRect = new Rectangle();

        var transformationMatrix:Matrix = getTransformationMatrix(targetSpace, _matrix);

        return GeometryDataUtil.getGeometryBounds(_geometry, 0, -1, resultRect, transformationMatrix);
    }

    override public function render(support:RenderSupport, parentAlpha:Number):void {
        if(_renderer == null || _geometry == null) return;

        if(! _batchable) {
            _renderer.removeAllGeometries();
            _renderer.addGeometry(_geometry);

            _renderer.renderToBackBuffer(support, _premultipliedAlpha);
        }
        else if(! _batched) {
            support.popMatrix();
            {
                _renderer.removeAllGeometries();
                _renderer.addGeometry(_geometry, transformationMatrix);

                var index:int = parent.getChildIndex(this);

                var count:int = parent.numChildren;
                for(var i:int = index + 1; i < count; ++i) {
                    var wrapper:BatchRendererWrapper = parent.getChildAt(i) as BatchRendererWrapper;

                    if(! canBatch(wrapper))
                        break;

                    wrapper._batched = true;
                    _renderer.addGeometry(wrapper._geometry, wrapper.transformationMatrix);
                }

                _renderer.renderToBackBuffer(support, _premultipliedAlpha);
            }
            support.pushMatrix();
            support.transformMatrix(this);
        }

        // reset batched flag
        _batched = false;
    }

    // TODO: this should probably check for renderers compatibility, not only vertex format; different renderers may use the same format
    /** Can a given wrapper be batched along with this wrapper? */
    protected function canBatch(wrapper:BatchRendererWrapper):Boolean {
        return wrapper != null
            && wrapper._batchable
            && wrapper._premultipliedAlpha == _premultipliedAlpha
            && wrapper.geometry.vertexFormat.isCompatible(_geometry.vertexFormat)
        ;
    }
}
}
