/**
 * User: booster
 * Date: 14/01/14
 * Time: 13:33
 */
package demos {
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.BatchRendererWrapper;
import starling.display.BlendMode;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.renderer.GeometryDataUtil;
import starling.renderer.RenderingSettings;
import starling.renderer.examples.colored.ColoredGeometryData;
import starling.renderer.examples.colored.ColoredGeometryRenderer;
import starling.renderer.examples.textured.TexturedGeometryData;
import starling.renderer.examples.textured.TexturedGeometryRenderer;
import starling.textures.RenderTexture;
import starling.textures.Texture;

public class SimpleDemo extends Sprite {
    [Embed(source="/starling_bird_transparent.png")]
    public static const Bird:Class;

    private var _renderTexture:RenderTexture;

    private var _coloredRenderer:ColoredGeometryRenderer;
    private var _coloredGeometry:ColoredGeometryData;

    private var _texturedRenderer:TexturedGeometryRenderer;
    private var _texturedGeometry:TexturedGeometryData;

    private var _settings:RenderingSettings;

    public function SimpleDemo() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
        _renderTexture = new RenderTexture(1024, 1024, false);

        _coloredRenderer = new ColoredGeometryRenderer();
        _coloredGeometry = new ColoredGeometryData();

        var vertex:int;

        // render colored quad and triangle
        vertex = GeometryDataUtil.addQuad(_coloredGeometry);
        _coloredGeometry.setVertexPosition(vertex    ,  10,  10);
        _coloredGeometry.setVertexPosition(vertex + 1, 120,  10);
        _coloredGeometry.setVertexPosition(vertex + 2,  30, 90);
        _coloredGeometry.setVertexPosition(vertex + 3, 180, 180);

        _coloredGeometry.setVertexColor(vertex    , 1.0, 0.0, 0.0, 1.0);
        _coloredGeometry.setVertexColor(vertex + 1, 0.0, 1.0, 0.0, 1.0);
        _coloredGeometry.setVertexColor(vertex + 2, 0.0, 0.0, 1.0, 1.0);
        _coloredGeometry.setVertexColor(vertex + 3, 1.0, 0.0, 1.0, 1.0);

        vertex = GeometryDataUtil.addTriangle(_coloredGeometry);
        _coloredGeometry.setVertexPosition(vertex    , 350,  10);
        _coloredGeometry.setVertexPosition(vertex + 1,  50, 450);
        _coloredGeometry.setVertexPosition(vertex + 2, 550, 350);

        _coloredGeometry.setVertexColor(vertex    , 1.0, 0.0, 0.0, 1.0);
        _coloredGeometry.setVertexColor(vertex + 1, 0.0, 1.0, 0.0, 1.0);
        _coloredGeometry.setVertexColor(vertex + 2, 0.0, 0.0, 1.0, 0.0);

        _texturedRenderer = new TexturedGeometryRenderer();
        _texturedGeometry = new TexturedGeometryData();

        _texturedRenderer.inputTexture = Texture.fromBitmap(new Bird());

        // render textured quad
        vertex = GeometryDataUtil.addQuad(_texturedGeometry);

        _texturedGeometry.setVertexPosition(vertex    ,  0,    0);
        _texturedGeometry.setVertexPosition(vertex + 1, 100,   0);
        _texturedGeometry.setVertexPosition(vertex + 2,   0, 100);
        _texturedGeometry.setVertexPosition(vertex + 3, 100, 100);

        _texturedGeometry.setVertexUV(vertex    , 0, 0);
        _texturedGeometry.setVertexUV(vertex + 1, 1, 0);
        _texturedGeometry.setVertexUV(vertex + 2, 0, 1);
        _texturedGeometry.setVertexUV(vertex + 3, 1, 1);

        _settings               = new RenderingSettings();
        _settings.blendMode     = BlendMode.NORMAL;
        _settings.clearColor    = 0xcccccc;
        _settings.clearAlpha    = 1.0;
        _settings.blendMode     = BlendMode.NONE;

        _settings.enableInputTransform();
        _settings.inputTransform.scale(3, 3);
        _settings.inputTransform.translate(0, 30);

        _settings.enableClipping(40, 120, 200, 100);

        // textured renderer renders to a texture target...
        _texturedRenderer.appendGeometry(_texturedGeometry);
        _texturedRenderer.renderToTexture(_renderTexture, _settings);

        // ... which is displayed using an Image instance
        addChild(new Image(_renderTexture));

        // colored renderer renders to the back buffer using a wrapper display object
        var wrapper:BatchRendererWrapper = new BatchRendererWrapper();
        wrapper.renderer = _coloredRenderer;
        wrapper.geometry = _coloredGeometry;
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
