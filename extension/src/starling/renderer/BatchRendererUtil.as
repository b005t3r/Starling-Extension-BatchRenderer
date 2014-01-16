/**
 * User: booster
 * Date: 16/01/14
 * Time: 8:48
 */
package starling.renderer {

public class BatchRendererUtil {

    /**
     * Adds a new triangle to the renderer.
     *
     * @param renderer
     * @return index of the first vertex added (total of 3 vertices are added)
     */
    public static function addTriangle(renderer:BatchRenderer):int {
        var firstVertex:int = renderer.addVertices(3);

        renderer.addTriangle(firstVertex, firstVertex + 1, firstVertex + 2);

        return firstVertex;
    }

    /**
     * Adds a new quad to the renderer.
     * Quad is made of two triangles, indexed like so:
     * first:   0, 1, 2
     * second:  1, 3, 2
     *
     * @param renderer
     * @return index of the first vertex added (total of 4 vertices are added)
     */
    public static function addQuad(renderer:BatchRenderer):int {
        var firstVertex:int = renderer.addVertices(4);

        renderer.addTriangle(firstVertex    , firstVertex + 1, firstVertex + 2);
        renderer.addTriangle(firstVertex + 1, firstVertex + 3, firstVertex + 2);

        return firstVertex;
    }
}
}
