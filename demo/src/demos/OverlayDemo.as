/**
 * User: booster
 * Date: 22/01/14
 * Time: 16:14
 */
package demos {
import starling.display.BatchRendererWrapper;
import starling.display.BlendMode;
import starling.display.Sprite;
import starling.events.Event;
import starling.renderer.BatchRendererUtil;
import starling.renderer.RenderingSettings;
import starling.renderer.examples.OverlayBlendModeRenderer;
import starling.textures.Texture;

public class OverlayDemo extends Sprite {
    [Embed(source="/starling_bird_transparent.png")]
    public static const Bird:Class;

    [Embed(source="/overlay_bottom_layer.png")]
    public static const Fibers:Class;

    public function OverlayDemo() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
        var _overlayRenderer:OverlayBlendModeRenderer = new OverlayBlendModeRenderer();

        _overlayRenderer.topLayerTexture    = Texture.fromBitmap(new Bird());
        _overlayRenderer.bottomLayerTexture = Texture.fromBitmap(new Fibers());

        // render textured quad
        var vertex:int = BatchRendererUtil.addQuad(_overlayRenderer);
        _overlayRenderer.setVertexPosition(vertex, 0, 0);
        _overlayRenderer.setVertexPosition(vertex + 1, 300, 0);
        _overlayRenderer.setVertexPosition(vertex + 2, 0, 300);
        _overlayRenderer.setVertexPosition(vertex + 3, 300, 300);

        _overlayRenderer.setTopLayerVertexUV(vertex, 0, 0);
        _overlayRenderer.setTopLayerVertexUV(vertex + 1, 1, 0);
        _overlayRenderer.setTopLayerVertexUV(vertex + 2, 0, 1);
        _overlayRenderer.setTopLayerVertexUV(vertex + 3, 1, 1);

        _overlayRenderer.setBottomLayerVertexUV(vertex, 0, 0);
        _overlayRenderer.setBottomLayerVertexUV(vertex + 1, 1, 0);
        _overlayRenderer.setBottomLayerVertexUV(vertex + 2, 0, 1);
        _overlayRenderer.setBottomLayerVertexUV(vertex + 3, 1, 1);

        var _settings:RenderingSettings = new RenderingSettings();
        _settings.clearColor = 0xcccccc;
        _settings.clearAlpha = 1.0;
        _settings.blendMode = BlendMode.NONE;

        var wrapper:BatchRendererWrapper = new BatchRendererWrapper(_overlayRenderer);
        addChild(wrapper);

        wrapper.alignPivot();
        wrapper.x += wrapper.width / 2 + 100;
        wrapper.y += wrapper.height / 2 + 100;
    }
}
}
