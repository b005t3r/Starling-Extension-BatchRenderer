package {

import demos.*;

import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display3D.Context3DRenderMode;
import flash.events.Event;
import flash.system.Capabilities;

import starling.core.Starling;

[SWF(width="800", height="600", backgroundColor="#aaaaaa", frameRate="60")]
public class Main extends Sprite {
    public function Main() {
        if(stage)
            init();
        else
            addEventListener(Event.ADDED_TO_STAGE, init);
    }

    public function init(event:Event = null):void {
        removeEventListener(Event.ADDED_TO_STAGE, init);

        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        // change this to start a different demo: BlueprintDemo, MeshDemo, OverlayDemo, SimpleDemo
        var demoClass:Class = FastBlurDemo;

        // make sure you use AIR 4.0, so the auto profile selection works as it should
        var starling:Starling = new Starling(demoClass, stage, null, null, Context3DRenderMode.AUTO, ["baseline", "baselineExtended"]);
        starling.simulateMultitouch = false;
        starling.enableErrorChecking = Capabilities.isDebugger;
        starling.antiAliasing = 10;
        starling.showStats = true;
        starling.start();
    }
}
}
