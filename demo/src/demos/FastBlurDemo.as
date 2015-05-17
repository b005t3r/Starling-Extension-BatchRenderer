/**
 * User: booster
 * Date: 12/05/15
 * Time: 11:48
 */
package demos {
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.BlendMode;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.renderer.RenderingSettings;
import starling.renderer.examples.blur.FastBlurRenderer;
import starling.renderer.examples.textured.TexturedGeometryData;
import starling.renderer.geometry.GeometryDataUtil;
import starling.textures.RenderTexture;
import starling.textures.Texture;

public class FastBlurDemo extends Sprite {
    [Embed(source="/starling_bird_transparent.png")]
    public static const Bird:Class;

    private var _birdTexture:Texture;
    private var _inputTexture:Texture;
    private var _outputTexture:Texture;
    private var _tempTexture:Texture;

    private var _fastBlurRenderer:FastBlurRenderer;
    private var _texturedGeometry:TexturedGeometryData;

    private var _settings:RenderingSettings;

    public function FastBlurDemo() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
        _outputTexture  = new RenderTexture(512, 512, true);
        _tempTexture    = Texture.empty(512, 512, true, false, true);
        _birdTexture    = Texture.fromBitmap(new Bird());
        _inputTexture   = new RenderTexture(_birdTexture.width, _birdTexture.height, true, _birdTexture.scale);

        var birdImage:Image = new Image(_birdTexture);
        birdImage.color     = 0x000000;
        birdImage.blendMode = BlendMode.ERASE;
        RenderTexture(_inputTexture).clear(0x000000, 1);
        RenderTexture(_inputTexture).draw(birdImage);

        _fastBlurRenderer = new FastBlurRenderer();
        _texturedGeometry = new TexturedGeometryData();

        _fastBlurRenderer.inputTexture = _inputTexture;
        _fastBlurRenderer.strength = 5;
        _fastBlurRenderer.pixelWidth = 1 / _fastBlurRenderer.inputTexture.width;
        _fastBlurRenderer.pixelHeight = 1 / _fastBlurRenderer.inputTexture.height;

        // render textured quad
        var vertex:int = GeometryDataUtil.addQuad(_texturedGeometry);

        _texturedGeometry.setVertexPosition(vertex, 0, 0);
        _texturedGeometry.setVertexPosition(vertex + 1, 512, 0);
        _texturedGeometry.setVertexPosition(vertex + 2, 0, 512);
        _texturedGeometry.setVertexPosition(vertex + 3, 512, 512);

        _texturedGeometry.setVertexUV(vertex, 0, 0);
        _texturedGeometry.setVertexUV(vertex + 1, 1, 0);
        _texturedGeometry.setVertexUV(vertex + 2, 0, 1);
        _texturedGeometry.setVertexUV(vertex + 3, 1, 1);

        _fastBlurRenderer.addGeometry(_texturedGeometry);

        _settings = new RenderingSettings();
        _settings.clearOutput = true;

        RenderTexture(_outputTexture).clear();
        _fastBlurRenderer.renderPasses(_outputTexture, _tempTexture, _settings);

        birdImage.blendMode = BlendMode.MASK;
        //birdImage.scaleX = birdImage.scaleY = 0.5;
        RenderTexture(_outputTexture).draw(birdImage);

        //addChild(new Image(_birdTexture));
        var image:Image = new Image(_outputTexture);
        //image.scaleX = image.scaleY = 2;
        addChild(image);

        addEventListener(Event.ENTER_FRAME, onEnterFrame);

        var strTween:Tween = new Tween(_fastBlurRenderer, 5, Transitions.EASE_IN_OUT);
        strTween.reverse = true;
        strTween.repeatCount = 0;
        strTween.animate("strength", 50);
        Starling.juggler.add(strTween);
    }

    private function onEnterFrame(event:Event):void {
        //trace("str:", _fastBlurRenderer.strength, "passes:", _fastBlurRenderer.passesNeeded);
        //_fastBlurRenderer.renderPasses(_outputTexture, _tempTexture, _settings);
    }
}
}
