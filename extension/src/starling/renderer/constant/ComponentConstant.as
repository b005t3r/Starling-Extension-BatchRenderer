/**
 * User: booster
 * Date: 15/01/14
 * Time: 10:01
 */
package starling.renderer.constant {

public class ComponentConstant {
    private var _name:String;
    private var _type:int;
    private var _value:Number;

    public function ComponentConstant(name:String, type:int, value:Number) {
        _name = name;
        _type = type;
        _value = value;
    }

    public function get name():String { return _name; }
    public function get type():int { return _type; }
    public function get value():Number { return _value; }
    public function set value(v:Number):void { _value = v; }
}
}
