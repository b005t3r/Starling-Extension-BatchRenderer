/**
 * User: booster
 * Date: 16/01/14
 * Time: 8:36
 */
package starling.renderer {

import com.barliesque.agal.IRegister;

import starling.renderer.vertex.VertexFormat;

use namespace renderer_internal;

public class ColoredGeometryRenderer extends BatchRenderer {
    public static const POSITION:String = "position";
    public static const COLOR:String    = "color";

    private var _positionID:int, _colorID:int;

    // shader variables
    private var color:IRegister = VARYING[0];

    public function ColoredGeometryRenderer() {
        setVertexFormat(createVertexFormat());
    }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, _positionID, x, y); }

    public function getVertexColor(vertex:int, color:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _colorID, color); }
    public function setVertexColor(vertex:int, r:Number, g:Number, b:Number, a:Number):void { setVertexData(vertex, _colorID, r, g, b, a); }

    override protected function vertexShaderCode():void {
        multiply4x4(OUTPUT, getVertexAttribute(POSITION), getRegisterConstant(PROJECTION_MATRIX));

        move(color, getVertexAttribute(COLOR));
    }

    override protected function fragmentShaderCode():void {
        move(OUTPUT, color);
    }

    private function createVertexFormat():VertexFormat {
        var format:VertexFormat = new VertexFormat();

        _positionID = format.addProperty(POSITION, 2);    // x, y;        id: 0
        _colorID    = format.addProperty(COLOR, 4);       // r, g, b, a;  id: 1

        return format;
    }
}
}
