/**
 * User: booster
 * Date: 22/03/15
 * Time: 16:51
 */
package starling.display.blend {
import starling.display.DisplayObject;
import starling.display.LayeredSprite;
import starling.display.layered_sprite_internal;
import starling.renderer.RenderingSettings;
import starling.renderer.examples.overlay.OverlayBlendModeGeometryData;
import starling.renderer.examples.overlay.OverlayBlendModeRenderer;
import starling.renderer.geometry.GeometryDataUtil;
import starling.textures.RenderTexture;

use namespace layered_sprite_internal;

public class OverlayBlendMode implements ILayerBlendMode {
    public static const OVERLAY:OverlayBlendMode        = new OverlayBlendMode();

    private var _renderer:OverlayBlendModeRenderer      = new OverlayBlendModeRenderer();
    private var _geometry:OverlayBlendModeGeometryData  = new OverlayBlendModeGeometryData();
    private var _settings:RenderingSettings             = new RenderingSettings();

    public function OverlayBlendMode() {
        _settings.premultipliedAlpha = true;
        GeometryDataUtil.addQuad(_geometry);
        _renderer.addGeometry(_geometry);
    }

    public function blend(layer:DisplayObject, sprite:LayeredSprite):void {
        var topLayer:RenderTexture      = sprite.getTemporaryRenderTexture();
        var bottomLayer:RenderTexture   = sprite.destinationTexture;
        var destination:RenderTexture   = sprite.getTemporaryRenderTexture();

        topLayer.clear();
        topLayer.draw(layer);

        _renderer.topLayerTexture       = topLayer;
        _renderer.bottomLayerTexture    = bottomLayer;

        _geometry.setVertexPosition(0, 0, 0);
        _geometry.setVertexPosition(1, destination.width, 0);
        _geometry.setVertexPosition(2, 0, destination.height);
        _geometry.setVertexPosition(3, destination.width, destination.height);

        _geometry.setTopLayerVertexUV(0, 0, 0);
        _geometry.setTopLayerVertexUV(1, 1, 0);
        _geometry.setTopLayerVertexUV(2, 0, 1);
        _geometry.setTopLayerVertexUV(3, 1, 1);

        _geometry.setBottomLayerVertexUV(0, 0, 0);
        _geometry.setBottomLayerVertexUV(1, 1, 0);
        _geometry.setBottomLayerVertexUV(2, 0, 1);
        _geometry.setBottomLayerVertexUV(3, 1, 1);

        destination.clear();
        _renderer.renderToTexture(destination, _settings);

        sprite.destinationTexture = destination;
        sprite.freeTemporaryRenderTexture(bottomLayer);
        sprite.freeTemporaryRenderTexture(topLayer);
    }
}
}
