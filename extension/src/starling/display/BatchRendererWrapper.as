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
import starling.renderer.RenderingSettings;

public class BatchRendererWrapper extends DisplayObject {
    protected var _renderer:BatchRenderer;
    protected var _renderingSettings:RenderingSettings;

    private var _ownsRenderer:Boolean;
    private var _positionID:int;

    public function BatchRendererWrapper(renderer:BatchRenderer, vertexPositionID:int = 0, ownsRenderer:Boolean = false) {
        _renderer       = renderer;
        _positionID     = vertexPositionID;
        _ownsRenderer   = ownsRenderer;

        _renderingSettings = createRenderingSettings(_renderer);
    }

    override public function dispose():void {
        if(_ownsRenderer) _renderer.dispose();

        super.dispose();
    }

    override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle = null):Rectangle {
        if (resultRect == null) resultRect = new Rectangle();

        var transformationMatrix:Matrix = getTransformationMatrix(targetSpace);

        return BatchRendererUtil.getGeometryBounds(_renderer, _positionID, 0, -1, resultRect, transformationMatrix);
    }

    override public function set blendMode(value:String):void {
        super.blendMode                 = value;
        _renderingSettings.blendMode    = blendMode;
    }

    override public function render(support:RenderSupport, parentAlpha:Number):void {
        _renderer.renderToBackBuffer(support, _renderingSettings);
    }

    protected function createRenderingSettings(renderer:BatchRenderer):RenderingSettings {
        return new RenderingSettings();
    }
}
}
