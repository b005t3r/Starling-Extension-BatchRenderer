/**
 * User: booster
 * Date: 20/01/14
 * Time: 11:21
 */
package starling.renderer.examples.blueprint {
import com.barliesque.agal.IComponent;
import com.barliesque.agal.IRegister;
import com.barliesque.shaders.macro.Utils;

import starling.renderer.*;

use namespace renderer_internal;

public class BlueprintPatternRenderer extends BatchRenderer {
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
        super(BlueprintPatternVertexFormat.cachedInstance);

        addComponentConstant(ZERO, ShaderType.FRAGMENT, 0);
        addComponentConstant(ONE, ShaderType.FRAGMENT, 1);
    }

    override protected function get cachedProgramID():String { return "BlueprintPatternRenderer"; }

    override protected function vertexShaderCode():void {
        comment("output vertex position");
        multiply4x4(OUTPUT, getVertexAttribute(BlueprintPatternVertexFormat.POSITION), getRegisterConstant(PROJECTION_MATRIX));

        comment("pass position, bounds, background, border and mark colors, and line widths (border and mark) to fragment shader");
        move(position, getVertexAttribute(BlueprintPatternVertexFormat.POSITION));
        move(bounds, getVertexAttribute(BlueprintPatternVertexFormat.BOUNDS));
        move(backgroundColor, getVertexAttribute(BlueprintPatternVertexFormat.BACKGROUND_COLOR));
        move(borderColor, getVertexAttribute(BlueprintPatternVertexFormat.BORDER_COLOR));
        move(markColor, getVertexAttribute(BlueprintPatternVertexFormat.MARK_COLOR));
        move(lineWidths, getVertexAttribute(BlueprintPatternVertexFormat.LINE_SIZES));
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
}
}
