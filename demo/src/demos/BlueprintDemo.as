/**
 * User: booster
 * Date: 20/01/14
 * Time: 13:19
 */
package demos {
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.BatchRendererWrapper;
import starling.display.BlendMode;
import starling.display.Sprite;
import starling.events.Event;
import starling.renderer.examples.blueprint.BlueprintPatternGeometryData;
import starling.renderer.examples.blueprint.BlueprintPatternRenderer;
import starling.renderer.geometry.GeometryDataUtil;

public class BlueprintDemo extends Sprite{
    private var _renderer:BlueprintPatternRenderer;

    public function BlueprintDemo() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
        _renderer = new BlueprintPatternRenderer();

        for(var i:int = 0; i < 20;++i) {
            var wrapper:BatchRendererWrapper = addObject(Math.random() * 400 + 200, Math.random() * 300 + 200, Math.random() * 500 + 100, Math.random() * 400 + 50);

            var scaleMin:Number = Math.random() * 0.2 + 0.25;
            var scaleMax:Number = Math.random() * 0.5 + 1;

            wrapper.scaleX = scaleMin;
            wrapper.scaleY = scaleMin;

            var tween:Tween = new Tween(wrapper, Math.random() * 3 + 2);
            //tween.animate("rotation", 2 * Math.PI); // uncomment to add a kind of special effect due to a faulty fragment shader :)
            tween.animate("scaleX",  scaleMax);
            tween.animate("scaleY", scaleMax);
            tween.repeatCount = 0;
            tween.reverse = true;
            tween.transition = Transitions.EASE_IN_OUT;
            Starling.juggler.add(tween);
        }
    }

    private function addObject(x:Number, y:Number, w:Number, h:Number):BatchRendererWrapper {
        var geometry:BlueprintPatternGeometryData = new BlueprintPatternGeometryData();

        GeometryDataUtil.addQuad(geometry);

        geometry.setVertexPosition(0, 0, 0);
        geometry.setVertexPosition(1, w, 0);
        geometry.setVertexPosition(2, 0, h);
        geometry.setVertexPosition(3, w, h);

        geometry.setGeonetryBounds(0, 4, 0, w, 0, h);
        geometry.setGeometryBackgroundColor(0, 4, 0.95, 0.95, 0.95, 1);
        //geometry.setGeometryBorderColor(0, 4, 0, 0.35, 0.7, 1);
        geometry.setGeometryBorderColor(0, 4, 0.2, 0.55, 0.9, 1);
        //geometry.setGeometryMarkColor(0, 4, 0.6, 0.75, 0.87, 1);
        geometry.setGeometryMarkColor(0, 4, 0.85, 0.85, 0.85, 1);
        geometry.setGeometryLineSizes(0, 4, 2, 1, 5, 50);

        // note: all wrappers can use the same renderer instance
        var wrapper:BatchRendererWrapper = new BatchRendererWrapper(geometry, _renderer);
        wrapper.blendMode   = BlendMode.NORMAL;
        //wrapper.batchable   = false; // uncomment to disable batching

        wrapper.alignPivot();
        wrapper.x += x;
        wrapper.y += y;

        addChild(wrapper);

        return wrapper;
    }
}
}
