/**
 * User: booster
 * Date: 14/01/14
 * Time: 13:33
 */
package {
import flash.geom.Matrix;

import starling.animation.Transitions;

import starling.animation.Tween;

import starling.core.Starling;
import starling.display.BatchRendererWrapper;
import starling.display.BlendMode;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.renderer.BatchRendererUtil;
import starling.renderer.examples.ColoredGeometryRenderer;
import starling.renderer.RenderingSettings;
import starling.renderer.examples.TexturedGeometryRenderer;
import starling.textures.RenderTexture;
import starling.textures.Texture;

public class SimpleDemo extends Sprite {
    [Embed(source="/starling_bird_transparent.png")]
    public static const Bird:Class;

    private var _renderTexture:RenderTexture;

    private var _coloredRenderer:ColoredGeometryRenderer;
    private var _texturedRenderer:TexturedGeometryRenderer;

    private var _settings:RenderingSettings;

    public function SimpleDemo() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
        _renderTexture = new RenderTexture(1024, 1024, false);

        _coloredRenderer = new ColoredGeometryRenderer();

        var vertex:int;

        // render colored quad and triangle
        vertex = BatchRendererUtil.addQuad(_coloredRenderer);
        _coloredRenderer.setVertexPosition(vertex    ,  10,  10);
        _coloredRenderer.setVertexPosition(vertex + 1, 120,  10);
        _coloredRenderer.setVertexPosition(vertex + 2,  30, 90);
        _coloredRenderer.setVertexPosition(vertex + 3, 180, 180);

        _coloredRenderer.setVertexColor(vertex    , 1.0, 0.0, 0.0, 1.0);
        _coloredRenderer.setVertexColor(vertex + 1, 0.0, 1.0, 0.0, 1.0);
        _coloredRenderer.setVertexColor(vertex + 2, 0.0, 0.0, 1.0, 1.0);
        _coloredRenderer.setVertexColor(vertex + 3, 1.0, 0.0, 1.0, 1.0);

        vertex = BatchRendererUtil.addTriangle(_coloredRenderer);
        _coloredRenderer.setVertexPosition(vertex    , 350,  10);
        _coloredRenderer.setVertexPosition(vertex + 1,  50, 450);
        _coloredRenderer.setVertexPosition(vertex + 2, 550, 350);

        _coloredRenderer.setVertexColor(vertex    , 1.0, 0.0, 0.0, 1.0);
        _coloredRenderer.setVertexColor(vertex + 1, 0.0, 1.0, 0.0, 1.0);
        _coloredRenderer.setVertexColor(vertex + 2, 0.0, 0.0, 1.0, 0.0);

        _texturedRenderer = new TexturedGeometryRenderer();

        _texturedRenderer.inputTexture = Texture.fromBitmap(new Bird());

        // render textured quad
        vertex = BatchRendererUtil.addQuad(_texturedRenderer);
        _texturedRenderer.setVertexPosition(vertex    ,  0,    0);
        _texturedRenderer.setVertexPosition(vertex + 1, 100,   0);
        _texturedRenderer.setVertexPosition(vertex + 2,   0, 100);
        _texturedRenderer.setVertexPosition(vertex + 3, 100, 100);

        _texturedRenderer.setVertexUV(vertex    , 0, 0);
        _texturedRenderer.setVertexUV(vertex + 1, 1, 0);
        _texturedRenderer.setVertexUV(vertex + 2, 0, 1);
        _texturedRenderer.setVertexUV(vertex + 3, 1, 1);

        _settings               = new RenderingSettings();
        _settings.blendMode     = BlendMode.NORMAL;
        _settings.clearColor    = 0xcccccc;
        _settings.clearAlpha    = 1.0;
        _settings.blendMode     = BlendMode.NONE;

        _settings.enableInputTransform();
        _settings.inputTransform.scale(3, 3);
        _settings.inputTransform.translate(0, 30);

        _settings.enableClipping(40, 120, 200, 100);

        _texturedRenderer.renderToTexture(_renderTexture, _settings);

        // TODO: remove once fixed in Starling; starling render() method clears render target before setting a new one
        Starling.context.setRenderToBackBuffer();

        addChild(new Image(_renderTexture));

        var wrapper:BatchRendererWrapper = new BatchRendererWrapper(_coloredRenderer, 0);
        wrapper.alignPivot();
        wrapper.x += wrapper.width / 2 + 10;
        wrapper.y += wrapper.height / 2 + 10;
        addChild(wrapper);

        var tween:Tween = new Tween(wrapper, 3);
        tween.animate("rotation", Math.PI);
        tween.animate("x", wrapper.width / 2 + 100);
        tween.animate("y", wrapper.height / 2 + 100);
        tween.repeatCount = 0;
        tween.reverse = true;
        tween.transition = Transitions.EASE_IN_OUT;
        Starling.juggler.add(tween);
    }
}
}
