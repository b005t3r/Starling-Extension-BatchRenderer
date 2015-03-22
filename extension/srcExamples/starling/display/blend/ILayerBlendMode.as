/**
 * User: booster
 * Date: 22/03/15
 * Time: 10:07
 */
package starling.display.blend {
import starling.display.DisplayObject;
import starling.display.LayeredSprite;

public interface ILayerBlendMode {
    function blend(layer:DisplayObject, sprite:LayeredSprite):void
}
}
