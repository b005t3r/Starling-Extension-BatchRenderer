/**
 * User: booster
 * Date: 16/01/14
 * Time: 8:48
 */
package starling.renderer {
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import starling.textures.Texture;
import starling.utils.MatrixUtil;

use namespace renderer_internal;

public class GeometryDataUtil {
    private static var _helperPoint:Point               = new Point();
    private static var _helperVector:Vector.<Number>    = new <Number>[];

    /**
     * Adds a new triangle to the renderer.
     *
     * @param geometry
     * @return index of the first vertex added (total of 3 vertices are added)
     */
    public static function addTriangle(geometry:GeometryData):int {
        var firstVertex:int = geometry.addVertices(3);

        geometry.addTriangle(firstVertex, firstVertex + 1, firstVertex + 2);

        return firstVertex;
    }

    /**
     * Adds a new quad to the renderer.
     * Quad is made of two triangles, indexed like so:
     * 0---1
     * | / |
     * 2---3
     * first triangle:   0, 1, 2
     * second triangle:  1, 3, 2
     *
     * @param geometry
     * @return index of the first vertex added (total of 4 vertices are added)
     */
    public static function addQuad(geometry:GeometryData):int {
        var firstVertex:int = geometry.addVertices(4);

        geometry.addTriangle(firstVertex    , firstVertex + 1, firstVertex + 2);
        geometry.addTriangle(firstVertex + 1, firstVertex + 3, firstVertex + 2);

        return firstVertex;
    }

    /**
     * Adds a new rectangular mesh to the renderer.
     * Mesh is made of 2 triangles per each quad segment, like so:
     * 0---1---2---3---4
     * | / | / | / | / |
     * 5---6---7---8---9
     * | / | / | / | / |
     * 10--11--12--13--14
     * | / | / | / | / |
     * 15--16--17--18--19
     *
     * @param geometry
     * @param width width of the mesh, in vertices
     * @param height height of the mesh, in vertices
     * @return
     */
    public static function addRectangularMesh(geometry:GeometryData, width:int, height:int):int {
        if(width <= 1 || height <= 1) throw new ArgumentError("width and height must be greater than one (mesh has to have at least 4 vertices)");

        var numVertices:int = width * height;
        var firstVertex:int = geometry.addVertices(numVertices);

        for(var row:int = 0; row < height - 1; ++row) {
            for(var col:int = 0; col < width - 1; ++col) {
                var v:int = firstVertex + col + row * width;

                geometry.addTriangle(v    , v     +     1, v + width);
                geometry.addTriangle(v + 1, v + width + 1, v + width);
            }
        }

        return firstVertex;
    }

    /**
     * Calculates bounding rect for the given geometry.
     *
     * @param geometry
     * @param positionID            id of vertex position attribute (x, y)
     * @param vertex                index of the first vertex
     * @param numVertices           number of vertices, if less than zero, all vertices are used
     * @param resultRect            rectangle to put the result in
     * @param transformationMatrix  matrix used to transform the geometry
     *
     * @return bounding rectangle
     */
    public static function getGeometryBounds(geometry:GeometryData, positionID:int, vertex:int = 0, numVertices:int = -1, resultRect:Rectangle = null, transformationMatrix:Matrix = null):Rectangle {
        if(resultRect == null) resultRect = new Rectangle();

        if(numVertices < 0) numVertices = geometry.vertexCount - vertex;

        if(numVertices == 0) {
            if(transformationMatrix == null) {
                resultRect.setEmpty();
            }
            else {
                MatrixUtil.transformCoords(transformationMatrix, 0, 0, _helperPoint);
                resultRect.setTo(_helperPoint.x, _helperPoint.y, 0, 0);
            }
        }
        else {
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
            var x:Number, y:Number, i:int;

            if(transformationMatrix == null) {
                for(i = 0; i < numVertices; ++i) {
                    geometry.getVertexData(vertex + i, positionID, _helperVector);

                    if(minX > _helperVector[0]) minX = _helperVector[0];
                    if(maxX < _helperVector[0]) maxX = _helperVector[0];
                    if(minY > _helperVector[1]) minY = _helperVector[1];
                    if(maxY < _helperVector[1]) maxY = _helperVector[1];
                }
            }
            else {
                for(i = 0; i < numVertices; ++i) {
                    geometry.getVertexData(vertex + i, positionID, _helperVector);

                    MatrixUtil.transformCoords(transformationMatrix, _helperVector[0], _helperVector[1], _helperPoint);

                    if(minX > _helperPoint.x) minX = _helperPoint.x;
                    if(maxX < _helperPoint.x) maxX = _helperPoint.x;
                    if(minY > _helperPoint.y) minY = _helperPoint.y;
                    if(maxY < _helperPoint.y) maxY = _helperPoint.y;
                }
            }

            resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
        }

        return resultRect;
    }

    public static function adjustUV(geometry:GeometryData, texture:Texture, uvID:int, vertex:int = 0, numVertices:int = -1):void {
        throw new Error("currently not supported, needs SubTexture.transformationMatrix to be added in Starling");
    }
}
}
