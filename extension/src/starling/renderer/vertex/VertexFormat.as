/**
 * User: booster
 * Date: 15/01/14
 * Time: 13:18
 */
package starling.renderer.vertex {

public class VertexFormat {
    private var _names:Vector.<String>  = new <String>[];
    private var _sizes:Vector.<int>     = new <int>[];
    private var _offsets:Vector.<int>   = new <int>[];
    private var _totalSize:int          = 0;

    public function addProperty(name:String, size:int):int {
        if(_names.indexOf(name) >= 0) throw new ArgumentError("property for name '" + name + "' already registered");

        _names[_names.length]       = name;
        _sizes[_sizes.length]       = size;
        _offsets[_offsets.length]   = _totalSize;
        _totalSize                 += size;

        return _names.length - 1;
    }

    public function getPropertyIndex(name:String):int { return _names.indexOf(name); }

    public function getSize(propertyIndex:int):int { return _sizes[propertyIndex]; }
    public function getOffset(propertyIndex:int):int { return _offsets[propertyIndex]; }

    public function get totalSize():int { return _totalSize; }

    public function get propertyCount():int { return _names.length; }
}
}
