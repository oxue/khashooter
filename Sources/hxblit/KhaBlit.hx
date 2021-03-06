package hxblit;

import haxe.ds.Vector;
import hxblit.TextureAtlas.FloatRect;
import kha.Color;
import kha.FastFloat;
import kha.Image;
import kha.Shaders;
import kha.arrays.Float32Array;
import kha.graphics4.BlendingOperation;
import kha.graphics4.CompareMode;
import kha.graphics4.Graphics;
import kha.graphics4.IndexBuffer;
import kha.graphics4.MipMapFilter;
import kha.graphics4.PipelineState;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.math.FastMatrix3;
import kha.math.FastMatrix4;
import kha.math.FastVector2;
import kha.arrays.Uint32Array;
import kha.arrays.Float32Array;
import kha.math.FastVector4;

/**
 * ...
 * @author ...
 */
class KhaBlit {
	public static var contextG4:Graphics;
	public static var currentPipelineState:PipelineState;
	public static var vboType:String;
	public static var KHBTex2PipelineState:Tex2PipelineState;

	public static var width:Int;
	public static var height:Int;

	public static var vertices:Float32Array;
	public static var indices:Uint32Array;

	public static var numVertices:Int;
	public static var vCounter:Int;
	public static var numIndices:Int;
	public static var iCounter:Int;

	// public static var
	public static var matrix2:FastMatrix4;

	public static var data32PerVertex:Int;

	public static var vertexBufferMap:Map<String, VertexBuffer>;
	public static var indexBufferMap:Map<Int, IndexBuffer>;

	public static var indexBuffer:IndexBuffer;
	public static var vertexBuffer:VertexBuffer;

	public static function init(_width:Int = 800, _height:Int = 600, _zoom:Int = 1) {
		trace("kb init 2");
		width = _width;
		height = _height;
		trace(width, height);
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

		indices = indexBuffer.lock();

		numVertices = 0;
		vCounter = 0;
		numIndices = 0;
		iCounter = 0;

		vertexBufferMap = new Map<String, VertexBuffer>();
		indexBufferMap = new Map<Int, IndexBuffer>();

		KHBTex2PipelineState = new Tex2PipelineState();
	}

	static public function setContext(g4:Graphics) {
		contextG4 = g4;
	}

	static public function clear(_r:Float = 1, _g:Float = 1, _b:Float = 1, _a:Float = 1, _d:Float = 1,
			_s:UInt = 1):Void {
		contextG4.clear(Color.fromFloats(_r, _g, _b, _a), _d, _s);
	}

	static public function setPipeline(_pipeline:PipelineState, ?_vboType:String) {
		currentPipelineState = _pipeline;
		vboType = _vboType;
		data32PerVertex = Std.int(_pipeline.inputLayout[0].byteSize() / 4);
		contextG4.setPipeline(_pipeline);

		if (vboType == null) {
			vertexBuffer = new VertexBuffer(8192, currentPipelineState.inputLayout[0], Usage.DynamicUsage);
		} else {
			if (!vertexBufferMap.exists(vboType)) {
				var vbo = new VertexBuffer(8192, currentPipelineState.inputLayout[0], Usage.DynamicUsage);
				vertexBufferMap.set(vboType, vbo);
			}
			vertexBuffer = vertexBufferMap.get(vboType);
		}

		vertices = vertexBuffer.lock();
	}

	static public function setUniformMatrix4(_name:String, _matrix:FastMatrix4) {
		contextG4.setMatrix(currentPipelineState.getConstantLocation(_name), _matrix);
	}

	static public function setUniformVec2(_name:String, _vec:FastVector2) {
		contextG4.setVector2(currentPipelineState.getConstantLocation(_name), _vec);
	}

	static public function setUniformVec4(_name:String, _vec:FastVector4) {
		contextG4.setVector4(currentPipelineState.getConstantLocation(_name), _vec);
	}

	static public function setUniformFloat(_name:String, _float:FastFloat) {
		contextG4.setFloat(currentPipelineState.getConstantLocation(_name), _float);
	}

	static public function setUniformTexture(_name:String, _texture:Image) {
		contextG4.setTexture(currentPipelineState.getTextureUnit(_name), _texture);
		contextG4.setTextureParameters(currentPipelineState.getTextureUnit(_name), TextureAddressing.Clamp,
			TextureAddressing.Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter,
			MipMapFilter.NoMipFilter);
	}

	public static function draw() {
		numVertices = cast(vCounter / data32PerVertex);

		if (numVertices != 0) {
			indexBuffer.unlock();
			vertexBuffer.unlock();
			contextG4.setIndexBuffer(indexBuffer);
			contextG4.setVertexBuffer(vertexBuffer);
			contextG4.drawIndexedVertices(0, numIndices);
		}

		numIndices = 0;
		numVertices = 0;
		vCounter = 0;
		iCounter = 0;
	}

	static inline public function pushRect(_rect:FloatRect):Void {
		vertices.set(vCounter, _rect.x);
		vCounter++;
		vertices.set(vCounter, _rect.y);
		vCounter++;
		vertices.set(vCounter, _rect.x + _rect.w);
		vCounter++;
		vertices.set(vCounter, _rect.y);
		vCounter++;
		vertices.set(vCounter, _rect.x);
		vCounter++;
		vertices.set(vCounter, _rect.y + _rect.h);
		vCounter++;
		vertices.set(vCounter, _rect.x + _rect.w);
		vCounter++;
		vertices.set(vCounter, _rect.y + _rect.h);
		vCounter++;
		indexQuad();
	}

	static inline private function indexQuad():Void {
		indices[numIndices] = iCounter;
		numIndices++;
		indices[numIndices] = iCounter + 1;
		numIndices++;
		indices[numIndices] = iCounter + 3;
		numIndices++;
		indices[numIndices] = iCounter + 0;
		numIndices++;
		indices[numIndices] = iCounter + 3;
		numIndices++;
		indices[numIndices] = iCounter + 2;
		numIndices++;
		iCounter += 4;
	}

	static inline private function indexTriangle():Void {
		indices[numIndices] = iCounter;
		numIndices++;
		indices[numIndices] = iCounter + 1;
		numIndices++;
		indices[numIndices] = iCounter + 2;
		numIndices++;
		iCounter += 3;
	}

	static inline public function pushQuad3(x1:Float, y1:Float, z1:Float, x2:Float, y2:Float, z2:Float,
			x4:Float, y4:Float, z4:Float, x3:Float, y3:Float, z3:Float) {
		stageV3(x1, y1, z1);
		stageV3(x2, y2, z2);
		stageV3(x3, y3, z3);
		stageV3(x4, y4, z4);
		indexQuad();
	}

	static inline public function pushTriangle4(x1:Float, y1:Float, z1:Float, w1:Float, x2:Float, y2:Float,
			z2:Float, w2:Float, x3:Float, y3:Float, z3:Float, w3:Float):Void {
		stageV4(x1, y1, z1, w1);
		stageV4(x2, y2, z2, w2);
		stageV4(x3, y3, z3, w3);
		indexTriangle();
	}

	static inline public function stageV3(x:Float, y:Float, z:Float):Void {
		vertices.set(vCounter, x);
		vCounter++;
		vertices.set(vCounter, y);
		vCounter++;
		vertices.set(vCounter, z);
		vCounter++;
	}

	static inline public function stageV4(x:Float, y:Float, z:Float, w:Float):Void {
		vertices.set(vCounter, x);
		vCounter++;
		vertices.set(vCounter, y);
		vCounter++;
		vertices.set(vCounter, z);
		vCounter++;
		vertices.set(vCounter, w);
		vCounter++;
	}

	static inline public function stageV6(x:Float, y:Float, z:Float, w:Float, u:Float, v:Float):Void {
		stageV4(x, y, z, w);
		vertices.set(vCounter, u);
		vCounter++;
		vertices.set(vCounter, v);
		vCounter++;
	}

	static inline public function pushQuad6(x1:Float, y1:Float, z1:Float, w1:Float, u1:Float, v1:Float,
			x2:Float, y2:Float, z2:Float, w2:Float, u2:Float, v2:Float, x4:Float, y4:Float, z4:Float,
			w4:Float, u4:Float, v4:Float, x3:Float, y3:Float, z3:Float, w3:Float, u3:Float, v3:Float) {
		stageV6(x1, y1, z1, w1, u1, v1);
		stageV6(x2, y2, z2, w2, u2, v2);
		stageV6(x3, y3, z3, w3, u3, v3);
		stageV6(x4, y4, z4, w4, u4, v4);
		indexQuad();
	}

	static inline public function pushTriangle6(x1:Float, y1:Float, z1:Float, w1:Float, u1:Float, v1:Float,
			x2:Float, y2:Float, z2:Float, w2:Float, u2:Float, v2:Float, x3:Float, y3:Float, z3:Float,
			w3:Float, u3:Float, v3:Float) {
		stageV6(x1, y1, z1, w1, u1, v1);
		stageV6(x2, y2, z2, w2, u2, v2);
		stageV6(x3, y3, z3, w3, u3, v3);
		indexTriangle();
	}

	static inline public function pushQuad4(x1:Float, y1:Float, z1:Float, w1:Float, x2:Float, y2:Float,
			z2:Float, w2:Float, x4:Float, y4:Float, z4:Float, w4:Float, x3:Float, y3:Float, z3:Float,
			w3:Float) {
		stageV4(x1, y1, z1, w1);
		stageV4(x2, y2, z2, w2);
		stageV4(x3, y3, z3, w3);
		stageV4(x4, y4, z4, w4);
		indexQuad();
	}

	static public function blit(_s2:Surface2, _x:Float, _y:Float):Void {
		stageV4(_x, _y, _s2.vx1, _s2.vy1);
		stageV4(_x + _s2.width, _y, _s2.vx2, _s2.vy2);
		stageV4(_x, _y + _s2.height, _s2.vx3, _s2.vy3);
		stageV4(_x + _s2.width, _y + _s2.height, _s2.vx4, _s2.vy4);
		indexQuad();
	}

	static public function getSurface(_w:Int, _h:Int):Surface2 {
		var s:Surface2 = new Surface2();
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
