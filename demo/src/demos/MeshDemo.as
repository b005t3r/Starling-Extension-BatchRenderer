/**
 * User: booster
 * Date: 17/01/14
 * Time: 14:10
 */
package demos {
import flash.geom.Point;

import starling.display.BatchRendererWrapper;
import starling.display.BlendMode;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.renderer.GeometryDataUtil;
import starling.renderer.examples.colored.ColoredGeometryData;
import starling.renderer.examples.colored.ColoredGeometryRenderer;
import starling.renderer.examples.textured.TexturedGeometryData;
import starling.renderer.examples.textured.TexturedGeometryRenderer;
import starling.textures.Texture;
import starling.utils.Color;

public class MeshDemo extends Sprite {
    [Embed(source="/starling_bird_transparent.png")]
    public static const Bird:Class;

    //private var _coloredGeometry:ColoredGeometryData;
    private var _texturedGeometry:TexturedGeometryData;
    private var _wrapper:BatchRendererWrapper;

    private var _selectedVertex:int = -1;

    public function MeshDemo() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):void {
        _texturedGeometry = new TexturedGeometryData();

        var texturedRenderer:TexturedGeometryRenderer = new TexturedGeometryRenderer();

        texturedRenderer.inputTexture = Texture.fromBitmap(new Bird(), false);

        addTexturedMesh(_texturedGeometry, 0, 0, 300, 300, 2);

        //_coloredGeometry = new ColoredGeometryData();

        //addColoredMesh(_coloredGeometry, 0, 0, 300, 300, 3);

        _wrapper = new BatchRendererWrapper();
        //_wrapper.geometry = _coloredGeometry;
        _wrapper.geometry = _texturedGeometry;
        //_wrapper.renderer = new ColoredGeometryRenderer();
        _wrapper.renderer = texturedRenderer;
        _wrapper.blendMode = BlendMode.NORMAL;
        _wrapper.alignPivot();
        _wrapper.x += 400; _wrapper.y += 300;

        _wrapper.addEventListener(TouchEvent.TOUCH, onMeshTouchEvent);

        addChild(_wrapper);
    }

/*
    private function onMeshTouchEvent(event:TouchEvent):void {
        var touch:Touch, location:Point = new Point();

        var position:Vector.<Number> = new Vector.<Number>(2, true);
        var vertexPosition:Point = new Point();

        if(touch = event.getTouch(_wrapper, TouchPhase.BEGAN)) {
            location = touch.getLocation(_wrapper, location);

            _selectedVertex = 0;
            _coloredGeometry.getVertexPosition(_selectedVertex, position);
            vertexPosition.setTo(position[0], position[1]);

            var distance:Number = Point.distance(location, vertexPosition);
            for(var v:int = 1; v < _coloredGeometry.vertexCount; ++v) {
                _coloredGeometry.getVertexPosition(v, position);
                vertexPosition.setTo(position[0], position[1]);

                if(distance > Point.distance(location, vertexPosition)) {
                    _selectedVertex = v;
                    distance = Point.distance(location, vertexPosition);
                }
            }
        }
        else if(touch = event.getTouch(_wrapper, TouchPhase.MOVED)) {
            location = touch.getLocation(_wrapper, location);

            _coloredGeometry.setVertexPosition(_selectedVertex, location.x, location.y);
        }
        else if(event.getTouch(_wrapper, TouchPhase.ENDED)) {
            _selectedVertex = -1;
        }
    }
*/

    private function onMeshTouchEvent(event:TouchEvent):void {
        var touch:Touch, location:Point = new Point();

        var position:Vector.<Number> = new Vector.<Number>(2, true);
        var vertexPosition:Point = new Point();

        if(touch = event.getTouch(_wrapper, TouchPhase.BEGAN)) {
            location = touch.getLocation(_wrapper, location);

            _selectedVertex = 0;
            _texturedGeometry.getVertexPosition(_selectedVertex, position);
            vertexPosition.setTo(position[0], position[1]);

            var distance:Number = Point.distance(location, vertexPosition);
            for(var v:int = 1; v < _texturedGeometry.vertexCount; ++v) {
                _texturedGeometry.getVertexPosition(v, position);
                vertexPosition.setTo(position[0], position[1]);

                if(distance > Point.distance(location, vertexPosition)) {
                    _selectedVertex = v;
                    distance = Point.distance(location, vertexPosition);
                }
            }
        }
        else if(touch = event.getTouch(_wrapper, TouchPhase.MOVED)) {
            location = touch.getLocation(_wrapper, location);

            _texturedGeometry.setVertexPosition(_selectedVertex, location.x, location.y);
        }
        else if(event.getTouch(_wrapper, TouchPhase.ENDED)) {
            _selectedVertex = -1;
        }
    }

    private function addTexturedMesh(geometry:TexturedGeometryData, x:Number, y:Number, width:Number, height:Number, segmentsPerRow:int):void {
        var firstVertex:int = GeometryDataUtil.addRectangularMesh(geometry, segmentsPerRow + 1, segmentsPerRow + 1);

        for(var row:int = 0; row < segmentsPerRow + 1; ++row) {
            for(var col:int = 0; col < segmentsPerRow + 1; ++col) {
                var v:int = firstVertex + col + row * (segmentsPerRow + 1);

                geometry.setVertexPosition(
                    v,
                    x + col * width / segmentsPerRow,
                    y + row * height / segmentsPerRow
                );

                geometry.setVertexUV(
                    v,
                    col / segmentsPerRow,
                    row / segmentsPerRow
                );
            }
        }
    }

    private function addColoredMesh(geometry:ColoredGeometryData, x:Number, y:Number, width:Number, height:Number, segmentsPerRow:int):void {
        var colors:Vector.<int> = new <int>[
            Color.AQUA, Color.BLACK, Color.BLUE, Color.FUCHSIA, Color.GRAY, Color.GREEN, Color.LIME, Color.MAROON,
            Color.NAVY, Color.OLIVE, Color.PURPLE, Color.RED, Color.SILVER, Color.TEAL, Color.WHITE, Color.YELLOW
        ];

        var firstVertex:int = GeometryDataUtil.addRectangularMesh(geometry, segmentsPerRow + 1, segmentsPerRow + 1);

        for(var row:int = 0; row < segmentsPerRow + 1; ++row) {
            for(var col:int = 0; col < segmentsPerRow + 1; ++col) {
                var v:int = firstVertex + col + row * (segmentsPerRow + 1);

                geometry.setVertexPosition(
                    v,
                    x + col * width / segmentsPerRow,
                    y + row * height / segmentsPerRow
                );

                var color:int = colors[int(Math.random() * colors.length)];

                geometry.setVertexColor(
                    v,
                    Color.getRed(color) / 255.0,
                    Color.getGreen(color) / 255.0,
                    Color.getBlue(color) / 255.0,
                    1.0
                );
            }
        }
    }
}
}
