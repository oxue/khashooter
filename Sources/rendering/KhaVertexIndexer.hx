package rendering;

import rendering.TextureAtlas.FloatRect;
import rendering.pipelines.Tex2PipelineState;
import kha.Color;
import kha.FastFloat;
import kha.Image;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;
import kha.graphics4.Graphics;
import kha.graphics4.IndexBuffer;
import kha.graphics4.MipMapFilter;
import kha.graphics4.PipelineState;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.math.FastMatrix4;
import kha.math.FastVector2;
import kha.math.FastVector4;

/**
 * ...
 * @author ...
 */
class KhaVertexIndexer {

    public static var contextG4:Graphics;
    public static var currentPipelineState:PipelineState;
    public static var vboType:String;
    public static var Tex2PipelineState:Tex2PipelineState;
    public static var Tex2MultiplyPipelineState:Tex2PipelineState;

    public static var width:Int;
    public static var height:Int;

    public static var vertices:Float32Array;
    public static var indices:Uint32Array;

    static var numVertices:Int;
    static var vCounter:Int;
    static var numIndices:Int;
    static var iCounter:Int;

    public static var matrix2:FastMatrix4;

    static var data32PerVertex:Int;

    static var vertexBufferMap:Map<String, VertexBuffer>;
    static var indexBufferMap:Map<String, IndexBuffer>;

    static var indexBuffer:IndexBuffer;
    static var vertexBuffer:VertexBuffer;

    public static function init(_width:Int = 800, _height:Int = 600, _zoom:Int = 1) {
        width = _width;
        height = _height;
        // atlas stuff
        matrix2 = FastMatrix4.identity();
        matrix2 = (FastMatrix4
            .translation(-_width / (2 * _zoom), -_height / (2 * _zoom), 0)
            .multmat(matrix2)
        );
        matrix2 = (FastMatrix4
            .scale((2 * _zoom) / _width, -(2 * _zoom) / _height, -1)
            .multmat(matrix2)
        );
        matrix2 = (FastMatrix4
            .translation((2 * _zoom) / _width, (2 * _zoom) / _height, 1)
            .multmat(matrix2)
        );
        indexBuffer = new IndexBuffer(12288, Usage.DynamicUsage);

        numVertices = 0;
        vCounter = 0;
        numIndices = 0;
        iCounter = 0;

        vertexBufferMap = new Map<String, VertexBuffer>();
        indexBufferMap = new Map<String, IndexBuffer>();

        Tex2PipelineState = new Tex2PipelineState();
        Tex2MultiplyPipelineState = new Tex2PipelineState(true, "multiply");
    }

    public static function setContext(g4:Graphics) {
        contextG4 = g4;
    }

    public static function clear(_r:Float = 1, _g:Float = 1, _b:Float = 1, _a:Float = 1, _d:Float = 1,
            _s:UInt = 1) {
        contextG4.clear(Color.fromFloats(_r, _g, _b, _a), _d, _s);
    }

    public static function setPipeline(_pipeline:PipelineState, ?_vboType:String) {
        currentPipelineState = _pipeline;
        vboType = _vboType;
        data32PerVertex = Std.int(_pipeline.inputLayout[0].byteSize() / 4);
        contextG4.setPipeline(_pipeline);

        if (vboType == null) {
            vertexBuffer = new VertexBuffer(
                8192,
                currentPipelineState.inputLayout[0],
                Usage.DynamicUsage
            );
            indexBuffer = new IndexBuffer(
                12288,
                Usage.DynamicUsage
            );
        } else {
            if (!vertexBufferMap.exists(vboType)) {
                vertexBufferMap.set(
                    vboType,
                    new VertexBuffer(
                        8192,
                        currentPipelineState.inputLayout[0],
                        Usage.DynamicUsage
                    )
                );
                indexBufferMap.set(
                    vboType,
                    new IndexBuffer(
                        12288,
                        Usage.DynamicUsage
                    )
                );
            }
            vertexBuffer = vertexBufferMap.get(vboType);
            indexBuffer = indexBufferMap.get(vboType);
        }

        // vertexBuffer = new VertexBuffer(
        //     8192,
        //     currentPipelineState.inputLayout[0],
        //     Usage.DynamicUsage
        // );
        // indexBuffer = new IndexBuffer(12288, Usage.DynamicUsage);

        vertices = vertexBuffer.lock(0, 8192);
        indices = indexBuffer.lock(0, 12288);
    }

    public static function setUniformMatrix4(_name:String, _matrix:FastMatrix4) {
        contextG4.setMatrix(currentPipelineState.getConstantLocation(_name), _matrix);
    }

    public static function setUniformVec2(_name:String, _vec:FastVector2) {
        contextG4.setVector2(currentPipelineState.getConstantLocation(_name), _vec);
    }

    public static function setUniformVec4(_name:String, _vec:FastVector4) {
        contextG4.setVector4(currentPipelineState.getConstantLocation(_name), _vec);
    }

    public static function setUniformFloat(_name:String, _float:FastFloat) {
        contextG4.setFloat(currentPipelineState.getConstantLocation(_name), _float);
    }

    public static function setUniformTexture(_name:String, _texture:Image) {
        contextG4.setTexture(currentPipelineState.getTextureUnit(_name), _texture);
        contextG4.setTextureParameters(
            currentPipelineState.getTextureUnit(_name),
            TextureAddressing.Clamp,
            TextureAddressing.Clamp,
            TextureFilter.PointFilter,
            TextureFilter.PointFilter,
            MipMapFilter.NoMipFilter
        );
    }

    public static function draw() {
        numVertices = cast(vCounter / data32PerVertex);

        if (numVertices != 0) {
            indexBuffer.unlock(numIndices);
            vertexBuffer.unlock(numVertices);
            contextG4.setIndexBuffer(indexBuffer);
            contextG4.setVertexBuffer(vertexBuffer);
            contextG4.drawIndexedVertices(0, numIndices);
        }

        numIndices = 0;
        numVertices = 0;
        vCounter = 0;
        iCounter = 0;
    }

    public static function pushRect(_rect:FloatRect) {
        vertices.set(vCounter, _rect.x);
        vertices.set(vCounter + 1, _rect.y);
        vertices.set(vCounter + 2, _rect.x + _rect.w);
        vertices.set(vCounter + 3, _rect.y);
        vertices.set(vCounter + 4, _rect.x);
        vertices.set(vCounter + 5, _rect.y + _rect.h);
        vertices.set(vCounter + 6, _rect.x + _rect.w);
        vertices.set(vCounter + 7, _rect.y + _rect.h);
        vCounter += 8;
        indexQuad();
    }

    static function indexQuad() {
        indices[numIndices] = iCounter;
        indices[numIndices + 1] = iCounter + 1;
        indices[numIndices + 2] = iCounter + 3;
        indices[numIndices + 3] = iCounter + 0;
        indices[numIndices + 4] = iCounter + 3;
        indices[numIndices + 5] = iCounter + 2;
        numIndices += 6;
        iCounter += 4;
    }

    static function indexTriangle() {
        indices[numIndices] = iCounter;
        indices[numIndices + 1] = iCounter + 1;
        indices[numIndices + 2] = iCounter + 2;
        numIndices += 3;
        iCounter += 3;
    }

    public static function pushQuad3(x1:Float, y1:Float, z1:Float, x2:Float, y2:Float, z2:Float, x4:Float,
            y4:Float, z4:Float, x3:Float, y3:Float, z3:Float) {
        stageV3(x1, y1, z1);
        stageV3(x2, y2, z2);
        stageV3(x3, y3, z3);
        stageV3(x4, y4, z4);
        indexQuad();
    }

    public static function pushTriangle4(x1:Float, y1:Float, z1:Float, w1:Float, x2:Float, y2:Float,
            z2:Float, w2:Float, x3:Float, y3:Float, z3:Float, w3:Float) {
        stageV4(x1, y1, z1, w1);
        stageV4(x2, y2, z2, w2);
        stageV4(x3, y3, z3, w3);
        indexTriangle();
    }

    public static function stageV3(x:Float, y:Float, z:Float) {
        vertices.set(vCounter, x);
        vertices.set(vCounter + 1, y);
        vertices.set(vCounter + 2, z);
        vCounter += 3;
    }

    public static function stageV4(x:Float, y:Float, z:Float, w:Float) {
        vertices.set(vCounter, x);
        vertices.set(vCounter + 1, y);
        vertices.set(vCounter + 2, z);
        vertices.set(vCounter + 3, w);
        vCounter += 4;
    }

    public static function stageV6(x:Float, y:Float, z:Float, w:Float, u:Float, v:Float) {
        stageV4(x, y, z, w);
        vertices.set(vCounter, u);
        vCounter++;
        vertices.set(vCounter, v);
        vCounter++;
    }

    public static function pushQuad6(x1:Float, y1:Float, z1:Float, w1:Float, u1:Float, v1:Float, x2:Float,
            y2:Float, z2:Float, w2:Float, u2:Float, v2:Float, x4:Float, y4:Float, z4:Float, w4:Float,
            u4:Float, v4:Float, x3:Float, y3:Float, z3:Float, w3:Float, u3:Float, v3:Float) {
        stageV6(x1, y1, z1, w1, u1, v1);
        stageV6(x2, y2, z2, w2, u2, v2);
        stageV6(x3, y3, z3, w3, u3, v3);
        stageV6(x4, y4, z4, w4, u4, v4);
        indexQuad();
    }

    public static function pushTriangle6(x1:Float, y1:Float, z1:Float, w1:Float, u1:Float, v1:Float,
            x2:Float, y2:Float, z2:Float, w2:Float, u2:Float, v2:Float, x3:Float, y3:Float, z3:Float,
            w3:Float, u3:Float, v3:Float) {
        stageV6(x1, y1, z1, w1, u1, v1);
        stageV6(x2, y2, z2, w2, u2, v2);
        stageV6(x3, y3, z3, w3, u3, v3);
        indexTriangle();
    }

    public static function pushQuad4(x1:Float, y1:Float, z1:Float, w1:Float, x2:Float, y2:Float, z2:Float,
            w2:Float, x4:Float, y4:Float, z4:Float, w4:Float, x3:Float, y3:Float, z3:Float, w3:Float) {
        stageV4(x1, y1, z1, w1);
        stageV4(x2, y2, z2, w2);
        stageV4(x3, y3, z3, w3);
        stageV4(x4, y4, z4, w4);
        indexQuad();
    }

    public static function blit(_s2:Surface2D, _x:Float, _y:Float) {
        stageV4(_x, _y, _s2.vx1, _s2.vy1);
        stageV4(_x + _s2.width, _y, _s2.vx2, _s2.vy2);
        stageV4(_x, _y + _s2.height, _s2.vx3, _s2.vy3);
        stageV4(_x + _s2.width, _y + _s2.height, _s2.vx4, _s2.vy4);
        indexQuad();
    }

    public static function getSurface(_w:Int, _h:Int):Surface2D {
        var s:Surface2D = new Surface2D();
        s.height = _h;
        s.width = _w;
        s.vx1 = 0;
        s.vy1 = 0;
        s.vx2 = 1;
        s.vy2 = 0;
        s.vx3 = 0;
        s.vy3 = 1;
        s.vx4 = 1;
        s.vy4 = 1;

        return s;
    }
}
