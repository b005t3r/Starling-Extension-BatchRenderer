/**
 * User: booster
 * Date: 15/01/14
 * Time: 13:18
 */
package starling.renderer {

public class VertexFormat {
    public static const POSITION:String = "position";

    private var _names:Vector.<String>  = new <String>[];
    private var _sizes:Vector.<int>     = new <int>[];
    private var _offsets:Vector.<int>   = new <int>[];
    private var _totalSize:int          = 0;

    /** First attribute of each vertex is 2D position. */
    public const positionID:int         = 0;

    public function VertexFormat() {
        addProperty(POSITION, 2); // x, y; id: 0
    }

    public function getPropertyIndex(name:String):int { return _names.indexOf(name); }

    public function getSize(propertyIndex:int):int { return _sizes[propertyIndex]; }
    public function getOffset(propertyIndex:int):int { return _offsets[propertyIndex]; }

    public function get totalSize():int { return _totalSize; }

    public function get propertyCount():int { return _names.length; }

    public function isCompatible(format:VertexFormat, quick:Boolean = true):Boolean {
        if(quick) {
            // quick class check - both are considered compatible it the classes match
            return Object(this).constructor == Object(format).constructor;
        }
        else {
            if(_totalSize != format._totalSize || _names.length != format._names.length)
                return false;

            var count:int = _names.length;
            for(var i:int = 0; i < count; i++)
                if(_names[i] != format._names[i] || _sizes[i] != format._sizes[i] || _offsets[i] != format._offsets[i])
                    return false;

            return true;
        }
    }

    protected function addProperty(name:String, size:int):int {
        if(_names.indexOf(name) >= 0) throw new ArgumentError("property for name '" + name + "' already registered");

        _names[_names.length]       = name;
        _sizes[_sizes.length]       = size;
        _offsets[_offsets.length]   = _totalSize;
        _totalSize                 += size;

        return _names.length - 1;
    }
}
}
