/**
 * User: booster
 * Date: 22/03/15
 * Time: 10:17
 */
package starling.display.blend {
import starling.display.BlendMode;
import starling.display.DisplayObject;
import starling.display.LayeredSprite;
import starling.display.layered_sprite_internal;

use namespace layered_sprite_internal;

public class StarlingBlendMode implements ILayerBlendMode {
    private static const NONE:StarlingBlendMode     = new StarlingBlendMode(BlendMode.NONE);
    private static const NORMAL:StarlingBlendMode   = new StarlingBlendMode(BlendMode.NORMAL);
    private static const ADD:StarlingBlendMode      = new StarlingBlendMode(BlendMode.ADD);
    private static const MULTIPLY:StarlingBlendMode = new StarlingBlendMode(BlendMode.MULTIPLY);
    private static const SCREEN:StarlingBlendMode   = new StarlingBlendMode(BlendMode.SCREEN);
    private static const ERASE:StarlingBlendMode    = new StarlingBlendMode(BlendMode.ERASE);
    private static const BELOW:StarlingBlendMode    = new StarlingBlendMode(BlendMode.BELOW);

    public static function getBlendMode(mode:String):StarlingBlendMode {
        switch(mode) {
            case BlendMode.NONE:        return NONE;
            case BlendMode.NORMAL:      return NORMAL;
            case BlendMode.ADD:         return ADD;
            case BlendMode.MULTIPLY:    return MULTIPLY;
            case BlendMode.SCREEN:      return SCREEN;
            case BlendMode.ERASE:       return ERASE;
            case BlendMode.BELOW:       return BELOW;

            default:
                throw new ArgumentError("invalid blend mode: " + mode);
        }
    }

    protected var _mode:String;

    public function StarlingBlendMode(mode:String) {
        _mode = mode;
    }

    public function blend(layer:DisplayObject, sprite:LayeredSprite):void {
        var oldMode:String  = layer.blendMode;
        layer.blendMode     = _mode;

        try {
            sprite.destinationTexture.draw(layer);
        }
        finally {
            layer.blendMode = oldMode;
        }
    }
}
}
