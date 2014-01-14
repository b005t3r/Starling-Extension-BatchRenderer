/**
 * User: booster
 * Date: 20/01/14
 * Time: 13:19
 */
package {
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.BatchRendererWrapper;
import starling.display.BlendMode;
import starling.display.Sprite;
import starling.events.Event;
import starling.renderer.BatchRendererUtil;
import starling.renderer.BlueprintPatternRenderer;

public class BlueprintDemo extends Sprite{

    public function BlueprintDemo() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
            for(var i:int = 0; i < 4;++i) {
                var wrapper:BatchRendererWrapper = addObject(Math.random() * 400 + 200, Math.random() * 300 + 200, Math.random() * 500 + 100, Math.random() * 400 + 50);

                var scaleMin:Number = Math.random() * 0.25 + 0.5;
                var scaleMax:Number = Math.random() * 2 + 1;

                wrapper.scaleX = scaleMin;
                wrapper.scaleY = scaleMin;

                var tween:Tween = new Tween(wrapper, Math.random() * 5 + 2);
                tween.animate("rotation", 2 * Math.PI);
                tween.animate("scaleX",  scaleMax);
                tween.animate("scaleY", scaleMax);
                tween.repeatCount = 0;
                tween.reverse = true;
                tween.transition = Transitions.EASE_IN_OUT;
                Starling.juggler.add(tween);
            }

    }

    private function addObject(x:Number, y:Number, w:Number, h:Number):BatchRendererWrapper {
        var blueprintRenderer:BlueprintPatternRenderer = new BlueprintPatternRenderer();

        BatchRendererUtil.addQuad(blueprintRenderer);

        blueprintRenderer.setVertexPosition(0, 0, 0);
        blueprintRenderer.setVertexPosition(1, w, 0);
        blueprintRenderer.setVertexPosition(2, 0, h);
        blueprintRenderer.setVertexPosition(3, w, h);

        blueprintRenderer.setGeonetryBounds(0, 4, 0, w, 0, h);
        blueprintRenderer.setGeometryBackgroundColor(0, 4, 0.95, 0.95, 0.95, 1);
        //blueprintRenderer.setGeometryBorderColor(0, 4, 0, 0.35, 0.7, 1);
        blueprintRenderer.setGeometryBorderColor(0, 4, 0.2, 0.55, 0.9, 1);
        //blueprintRenderer.setGeometryMarkColor(0, 4, 0.6, 0.75, 0.87, 1);
        blueprintRenderer.setGeometryMarkColor(0, 4, 0.85, 0.85, 0.85, 1);
        blueprintRenderer.setGeometryLineSizes(0, 4, 2, 1, 5, 50);

        var wrapper:BatchRendererWrapper = new BatchRendererWrapper(blueprintRenderer);
        wrapper.blendMode = BlendMode.NORMAL;
        wrapper.alignPivot();
        wrapper.x += x;
        wrapper.y += y;

        addChild(wrapper);

        return wrapper;
    }
}
}
