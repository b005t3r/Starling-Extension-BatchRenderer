/**
 * User: booster
 * Date: 15/01/14
 * Time: 10:01
 */
package starling.renderer.constant {

public class RegisterConstant {
    private var _name:String;
    private var _type:int;
    private var _values:Vector.<Number> = new Vector.<Number>(4, true);

    public function RegisterConstant(name:String, type:int, x:Number, y:Number, z:Number, w:Number) {
        _name = name;
        _type = type;

        setValues(x, y, z, w);
    }

    public function get name():String { return _name; }
    public function get type():int { return _type; }
    public function get values():Vector.<Number> { return _values; }

    public function setValues(x:Number, y:Number, z:Number, w:Number):void {
        _values[0] = x;
        _values[1] = y;
        _values[2] = z;
        _values[3] = w;
    }
}
}
