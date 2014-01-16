/**
 * User: booster
 * Date: 14/01/14
 * Time: 13:33
 */
package {
import flash.geom.Matrix;

import starling.core.Starling;
import starling.display.BlendMode;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.renderer.BatchRendererUtil;
import starling.renderer.ColoredGeometryRenderer;
import starling.renderer.TexturedGeometryRenderer;
import starling.textures.RenderTexture;
import starling.textures.Texture;

public class SimpleDemo extends Sprite {
    [Embed(source="/starling_bird_transparent.png")]
    public static const Bird:Class;

    private var _renderTexture:RenderTexture;

    private var _coloredRenderer:ColoredGeometryRenderer;
    private var _texturedRenderer:TexturedGeometryRenderer;

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

        _renderTexture.clear(0xeeeeee, 1.0);
        _coloredRenderer.render(_renderTexture, false, BlendMode.NORMAL);

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

        var m:Matrix = new Matrix();
        m.scale(10, 10);
        m.translate(0, 220);

        _texturedRenderer.render(_renderTexture, _texturedRenderer.inputTexture.premultipliedAlpha, BlendMode.NORMAL, null, m);

        // TODO: remove once fixed in Starling; starling render() method fix
        Starling.context.setRenderToBackBuffer();

        addChild(new Image(_renderTexture));
    }
}
}
