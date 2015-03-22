/**
 * User: booster
 * Date: 22/03/15
 * Time: 14:55
 */
package demos {
import starling.display.Image;
import starling.display.LayeredSprite;
import starling.display.Quad;
import starling.display.Sprite;
import starling.display.blend.OverlayBlendMode;
import starling.events.Event;
import starling.textures.RenderTexture;
import starling.textures.Texture;

public class LayeredSpriteDemo extends Sprite {
    [Embed(source="/starling_bird_transparent.png")]
    public static const Bird:Class;

    [Embed(source="/overlay_bottom_layer.png")]
    public static const Fibers:Class;

    public function LayeredSpriteDemo() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
        RenderTexture.optimizePersistentBuffers = true;

        var layeredSprite:LayeredSprite = new LayeredSprite();

        var bg:Image = new Image(Texture.fromBitmap(new Fibers()));
        layeredSprite.addLayer(bg, "bg");
        //layeredSprite.setBlendMode(StarlingBlendMode.getBlendMode(BlendMode.MULTIPLY), "bg");

        var bird:Image = new Image(Texture.fromBitmap(new Bird()));
        bird.x = 100;
        bird.y = 20;
        layeredSprite.addLayer(bird, "bird");
        //layeredSprite.setBlendMode(StarlingBlendMode.getBlendMode(BlendMode.ADD), "bird");
        //layeredSprite.setBlendMode(OverlayBlendMode.OVERLAY, "bird");

        var quad:Quad = new Quad(50, 70, 0xFF00FF);
        quad.x = 30;
        quad.y = 100;
        layeredSprite.addLayer(quad, "quad");
        layeredSprite.setBlendMode(OverlayBlendMode.OVERLAY, "quad");

        addChild(layeredSprite);

        layeredSprite.setLayerOrder("bg", "quad", "bird");
    }
}
}
