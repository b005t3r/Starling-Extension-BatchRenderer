/**
 * User: booster
 * Date: 20/01/14
 * Time: 11:21
 */
package starling.renderer.examples {
import com.barliesque.agal.IComponent;
import com.barliesque.agal.IRegister;
import com.barliesque.shaders.macro.Utils;

import starling.renderer.*;
import starling.renderer.vertex.VertexFormat;

use namespace renderer_internal;

public class BlueprintPatternRenderer extends BatchRenderer {
    public static const POSITION:String         = "position";
    public static const BOUNDS:String           = "bounds";
    public static const BACKGROUND_COLOR:String = "backgroundColor";
    public static const BORDER_COLOR:String     = "borderColor";
    public static const MARK_COLOR:String       = "markColor";
    public static const LINE_SIZES:String       = "lineSizes";

    public static const ZERO:String             = "zero";
    public static const ONE:String              = "one";

    private var _positionID:int;
    private var _boundsID:int;
    private var _backgroundColorID:int;
    private var _borderColorID:int;
    private var _markColorID:int;
    private var _lineSizesID:int;

    // shader vars
    private var position:IRegister          = VARYING[0];
    private var bounds:IRegister            = VARYING[1];
    private var backgroundColor:IRegister   = VARYING[2];
    private var borderColor:IRegister       = VARYING[3];
    private var markColor:IRegister         = VARYING[4];
    private var lineWidths:IRegister        = VARYING[5];
    private var borderWidth:IComponent      = VARYING[5].x;
    private var markWidth:IComponent        = VARYING[5].y;
    private var markLength:IComponent       = VARYING[5].z;
    private var markSpacing:IComponent      = VARYING[5].w;

    public function BlueprintPatternRenderer() {
        setVertexFormat(createVertexFormat());

        addComponentConstant(ZERO, ShaderType.FRAGMENT, 0);
        addComponentConstant(ONE, ShaderType.FRAGMENT, 1);
    }

    public function getVertexPosition(vertex:int, position:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _positionID, position); }
    public function setVertexPosition(vertex:int, x:Number, y:Number):void { setVertexData(vertex, _positionID, x, y); }

    public function getGeometryBounds(vertex:int, bounds:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _boundsID, bounds); }
    public function setGeonetryBounds(vertex:int, numVertices:int, minX:Number, maxX:Number, minY:Number, maxY:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, _boundsID, minX, maxX, minY, maxY);
    }

    public function getGeometryBackgroundColor(vertex:int, color:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _backgroundColorID, color); }
    public function setGeometryBackgroundColor(vertex:int, numVertices:int, r:Number, g:Number, b:Number, a:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, _backgroundColorID, r, g, b, a);
    }

    public function getGeometryBorderColor(vertex:int, color:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _borderColorID, color); }
    public function setGeometryBorderColor(vertex:int, numVertices:int, r:Number, g:Number, b:Number, a:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, _borderColorID, r, g, b, a);
    }

    public function getGeometryMarkColor(vertex:int, color:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _markColorID, color); }
    public function setGeometryMarkColor(vertex:int, numVertices:int, r:Number, g:Number, b:Number, a:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, _markColorID, r, g, b, a);
    }

    public function getGeometryLineSizes(vertex:int, sizes:Vector.<Number> = null):Vector.<Number> { return getVertexData(vertex, _lineSizesID, sizes); }
    public function setGeometryLineSizes(vertex:int, numVertices:int, borderWidth:Number, markWidth:Number, markLength:Number, markSpacing:Number):void {
        for(var i:int = vertex; i < vertex + numVertices; ++i)
            setVertexData(i, _lineSizesID, borderWidth, markWidth, markLength, markSpacing);
    }

    override protected function get cachedProgramID():String { return "BlueprintPatternRenderer"; }

    override protected function vertexShaderCode():void {
        comment("output vertex position");
        multiply4x4(OUTPUT, getVertexAttribute(POSITION), getRegisterConstant(PROJECTION_MATRIX));

        comment("pass position, bounds, background, border and mark colors, and line widths (border and mark) to fragment shader");
        move(position, getVertexAttribute(POSITION));
        move(bounds, getVertexAttribute(BOUNDS));
        move(backgroundColor, getVertexAttribute(BACKGROUND_COLOR));
        move(borderColor, getVertexAttribute(BORDER_COLOR));
        move(markColor, getVertexAttribute(MARK_COLOR));
        move(lineWidths, getVertexAttribute(LINE_SIZES));
    }

    override protected function fragmentShaderCode():void {
        var outputColor:IRegister   = reserveTempRegister();
        var borderMargins:IRegister = reserveTempRegister();
        var cellMargins:IRegister   = reserveTempRegister();
        var cellPosition:IRegister  = reserveTempRegister();
        var tempColor:IRegister     = reserveTempRegister();
        var tempRegisterA:IRegister = reserveTempRegister();
        var tempRegisterB:IRegister = reserveTempRegister();
        var zero:IComponent         = getComponentConstant(ZERO);
        var one:IComponent          = getComponentConstant(ONE);

        move(outputColor, backgroundColor);

        comment("setup cell margins: markWidth, markSpacing - markWidth, markLength, markSpacing - markLength");
        move(cellMargins.x, markWidth);
        subtract(cellMargins.y, markSpacing, markWidth);
        move(cellMargins.z, markLength);
        subtract(cellMargins.w, markSpacing, markLength);

        comment("cellPosition.x = position.x % markSpacing; cellPosition.y = position.y % markSpacing");
        divide(cellPosition.x, position.x, markSpacing);
        divide(cellPosition.y, position.y, markSpacing);
        fractional(cellPosition.z, cellPosition.x);
        fractional(cellPosition.w, cellPosition.y);
        subtract(cellPosition.x, cellPosition.x, cellPosition.z);
        subtract(cellPosition.y, cellPosition.y, cellPosition.w);
        multiply(cellPosition.x, cellPosition.x, markSpacing);
        multiply(cellPosition.y, cellPosition.y, markSpacing);
        subtract(cellPosition.x, position.x, cellPosition.x);
        subtract(cellPosition.y, position.y, cellPosition.y);

        comment("if((x <= markWidth || x >= markSpacing - markWidth) && (y <= markLength || y >= markSpacing - markLength))");
        comment("    outputColor = markColor");
        comment("else");
        comment("    outputColor = backgroundColor");
        Utils.setByComparison(tempRegisterB.x, cellPosition.x, Utils.LESS_OR_EQUAL, cellMargins.x, one, zero, tempRegisterA);
        Utils.setByComparison(tempRegisterB.y, cellPosition.x, Utils.GREATER_OR_EQUAL, cellMargins.y, one, zero, tempRegisterA);
        Utils.setByComparison(tempRegisterB.z, cellPosition.y, Utils.LESS_OR_EQUAL, cellMargins.z, one, zero, tempRegisterA);
        Utils.setByComparison(tempRegisterB.w, cellPosition.y, Utils.GREATER_OR_EQUAL, cellMargins.w, one, zero, tempRegisterA);
        add(tempRegisterB.x, tempRegisterB.x, tempRegisterB.y);
        add(tempRegisterB.z, tempRegisterB.z, tempRegisterB.w);
        multiply(tempRegisterB.x, tempRegisterB.x, tempRegisterB.z);
        Utils.setByComparison(tempColor, tempRegisterB.x, Utils.NOT_EQUAL, zero, markColor, outputColor, tempRegisterA);
        move(outputColor, tempColor);

        comment("if((y <= markWidth || y >= markSpacing - markWidth) && (x <= markLength || x >= markSpacing - markLength))");
        comment("    outputColor = markColor");
        comment("else");
        comment("    outputColor = backgroundColor");
        Utils.setByComparison(tempRegisterB.x, cellPosition.y, Utils.LESS_OR_EQUAL, cellMargins.x, one, zero, tempRegisterA);
        Utils.setByComparison(tempRegisterB.y, cellPosition.y, Utils.GREATER_OR_EQUAL, cellMargins.y, one, zero, tempRegisterA);
        Utils.setByComparison(tempRegisterB.z, cellPosition.x, Utils.LESS_OR_EQUAL, cellMargins.z, one, zero, tempRegisterA);
        Utils.setByComparison(tempRegisterB.w, cellPosition.x, Utils.GREATER_OR_EQUAL, cellMargins.w, one, zero, tempRegisterA);
        add(tempRegisterB.x, tempRegisterB.x, tempRegisterB.y);
        add(tempRegisterB.z, tempRegisterB.z, tempRegisterB.w);
        multiply(tempRegisterB.x, tempRegisterB.x, tempRegisterB.z);
        Utils.setByComparison(tempColor, tempRegisterB.x, Utils.NOT_EQUAL, zero, markColor, outputColor, tempRegisterA);
        move(outputColor, tempColor);

        comment("setup border margins: markWidth, markWidth, markSpacing - markWidth, markSpacing - markWidth");
        add(borderMargins.x, bounds.x, borderWidth);
        add(borderMargins.z, bounds.z, borderWidth);
        subtract(borderMargins.y, bounds.y, borderWidth);
        subtract(borderMargins.w, bounds.w, borderWidth);

        comment("if(x <= minMarginX || x >= maxMarginX || y <= minMarginY || y >= maxMarginY)");
        comment("    outputColor = borderColor");
        comment("else");
        comment("    outputColor = backgroundColor");
        Utils.setByComparison(tempColor, position.x, Utils.LESS_OR_EQUAL, borderMargins.x, borderColor, outputColor, tempRegisterA);
        move(outputColor, tempColor);

        Utils.setByComparison(tempColor, position.x, Utils.GREATER_OR_EQUAL, borderMargins.y, borderColor, outputColor, tempRegisterA);
        move(outputColor, tempColor);

        Utils.setByComparison(tempColor, position.y, Utils.LESS_OR_EQUAL, borderMargins.z, borderColor, outputColor, tempRegisterA);
        move(outputColor, tempColor);

        Utils.setByComparison(tempColor, position.y, Utils.GREATER_OR_EQUAL, borderMargins.w, borderColor, outputColor, tempRegisterA);
        move(outputColor, tempColor);

        move(OUTPUT, outputColor);
    }

    private function createVertexFormat():VertexFormat {
        var format:VertexFormat = new VertexFormat();

        _positionID         = format.addProperty(POSITION, 2);          // x, y; id: 0
        _boundsID           = format.addProperty(BOUNDS, 4);            // minX, maxX, minY, maxY; id: 1
        _backgroundColorID  = format.addProperty(BACKGROUND_COLOR, 4);  // r, g, b, a; id: 2
        _borderColorID      = format.addProperty(BORDER_COLOR, 4);      // r, g, b, a; id: 3
        _markColorID        = format.addProperty(MARK_COLOR, 4);        // r, g, b, a; id: 4
        _lineSizesID       = format.addProperty(LINE_SIZES, 4);         // borderWidth, markWidth, markLength, markSpacing; id: 5

        return format;
    }
}
}
