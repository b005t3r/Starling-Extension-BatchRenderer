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
import starling.renderer.geometry.GeometryDataUtil;
import starling.renderer.RenderingSettings;
import starling.renderer.examples.overlay.OverlayBlendModeGeometryData;
import starling.renderer.examples.overlay.OverlayBlendModeRenderer;
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
        var overlayRenderer:OverlayBlendModeRenderer = new OverlayBlendModeRenderer();

        overlayRenderer.topLayerTexture    = Texture.fromBitmap(new Bird());
        overlayRenderer.bottomLayerTexture = Texture.fromBitmap(new Fibers());

        var overlayGeometry:OverlayBlendModeGeometryData = new OverlayBlendModeGeometryData();

        // render textured quad
        var vertex:int = GeometryDataUtil.addQuad(overlayGeometry);
        overlayGeometry.setVertexPosition(vertex, 0, 0);
        overlayGeometry.setVertexPosition(vertex + 1, 300, 0);
        overlayGeometry.setVertexPosition(vertex + 2, 0, 300);
        overlayGeometry.setVertexPosition(vertex + 3, 300, 300);

        overlayGeometry.setTopLayerVertexUV(vertex, 0, 0);
        overlayGeometry.setTopLayerVertexUV(vertex + 1, 1, 0);
        overlayGeometry.setTopLayerVertexUV(vertex + 2, 0, 1);
        overlayGeometry.setTopLayerVertexUV(vertex + 3, 1, 1);

        overlayGeometry.setBottomLayerVertexUV(vertex, 0, 0);
        overlayGeometry.setBottomLayerVertexUV(vertex + 1, 1, 0);
        overlayGeometry.setBottomLayerVertexUV(vertex + 2, 0, 1);
        overlayGeometry.setBottomLayerVertexUV(vertex + 3, 1, 1);

        var _settings:RenderingSettings = new RenderingSettings();
        _settings.clearColor = 0xcccccc;
        _settings.clearAlpha = 1.0;
        _settings.blendMode = BlendMode.NONE;

        var wrapper:BatchRendererWrapper = new BatchRendererWrapper();
        addChild(wrapper);

        wrapper.renderer = overlayRenderer;
        wrapper.geometry = overlayGeometry;

        wrapper.alignPivot();
        wrapper.x += wrapper.width / 2 + 100;
        wrapper.y += wrapper.height / 2 + 100;
    }
}
}
