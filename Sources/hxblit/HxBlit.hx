package hxblit;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Stage;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DRenderMode;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.events.Event;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.Lib;
import flash.Memory;
import flash.utils.ByteArray;
import flash.Vector;
import hxsl.Shader;

/**
 * ...
 * @author worldedit qwerber
 */

class HxBlit 
{
	public static var context:Context3D;
	public static var atlas:TextureAtlas;
	public static var stage:Stage;
	public static var stage3:Stage3D;
	
	public static var width:Int;
	public static var height:Int;
	
	public static var _callBack:Void -> Void;
	
	public static var shader:Shader2;
	
	public static var indexBuffer:IndexBuffer3D;
	public static var vertexBuffer:VertexBuffer3D;
	
	public static var vertices:Vector<Float>;
	public static var indices:Vector<UInt>;
	
	public static var bVertices:ByteArray;
	
	public static var numVertices:Int;
	public static var vCounter:Int;
	public static var numIndices:Int;
	public static var iCounter:Int;
	
	public static var matrix2:Matrix3D;
	
	public static var currentShader:Shader;
	public static var data32PerVertex:Int;
	
	public static var HXB_shader2:Shader2;
	
	public static var vertexBufferList:Vector<VertexBuffer3D>;
	public static var indexBufferList:Vector<IndexBuffer3D>;
	
	public static function init(__callBack:Void -> Void, _width:Int = 800, _height:Int = 600, _zoom:Int = 2):Void
	{
		_callBack = __callBack;
		width = _width;
		height = _height;
		trace(width, height);
		stage = Lib.current.stage;
		stage3 = stage.stage3Ds[0];
		atlas = new TextureAtlas();
		stage3.addEventListener(Event.CONTEXT3D_CREATE, setContext3d);
		stage3.requestContext3D();
		
		matrix2 = new Matrix3D();
		matrix2.appendTranslation(-_width/(2 *_zoom), -_height/(2 *_zoom), 0);
		matrix2.appendScale((2 *_zoom)/_width, -(2 *_zoom)/_height, -1);
		matrix2.appendTranslation((2 *_zoom)/_width, (2 *_zoom)/_height, 1);
		
		vertices = new Vector<Float>(65536,true);
		indices = new Vector<UInt>(24576, true);
		
		bVertices = new ByteArray();
		bVertices.length = 65520 * 4;
		//Memory.select(bVertices);
		
		data32PerVertex = 4;
		
		vertexBufferList = new Vector<VertexBuffer3D>(10);
		indexBufferList = new Vector<IndexBuffer3D>(10);
	}
	
	static private function setContext3d(e:Event):Void 
	{
		context = stage3.context3D;
		context.enableErrorChecking = true;
		context.configureBackBuffer(width, height, 0, true);		
		
		//currentShader = new Shader2(context);
		currentShader = new Shader2();
		HXB_shader2 = cast currentShader;
		
		context.setDepthTest(true, Context3DCompareMode.ALWAYS);
		context.setCulling(Context3DTriangleFace.NONE);
		context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		
		setShader(currentShader, 4);
		
		_callBack();	
	}
	
	static public function setBlendMode(_mode:String):Void
	{
		switch(_mode)
		{
			case "REPLACE":
				context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			case "MULTIPLY":
				context.setBlendFactors(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ZERO);
			case "ALPHA":
				context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			case "ADD":
				//context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA);	
				context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA);	
			case "ADDALL":
				context.setBlendFactors(Context3DBlendFactor.SOURCE_COLOR, Context3DBlendFactor.DESTINATION_COLOR);	
			case "NOTHING":
				context.setBlendFactors(Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE);
			//case "SUB":
				//context.setBlendFactors(Context3DBlendFactor.
		}
	}
	
	static public function getSurface(_w:Int, _h:Int):Surface2
	{
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
	
	static public function setShader(_shader:Shader, _d32pv:Int):Void
	{
		currentShader = _shader;
		data32PerVertex = _d32pv;
		if (vertexBufferList[_d32pv] == null)
		{
			vertexBufferList[_d32pv] = context.createVertexBuffer(16, _d32pv);
		}
		/*if (indexBufferList[_d32pv] == null)
		{
			indexBufferList[_d32pv] = context.createIndexBuffer(24576);
		}*/
	}
	
	static public function initShader():Void
	{
		(cast currentShader).init( { mproj:matrix2}, { tex:atlas.texture } );
	}
	
	static inline public function pushRect(_rect:Rectangle):Void
	{
		vertices[vCounter] = (_rect.x);
		//Memory.setFloat(vCounter, _x);
		
		vCounter ++;
		vertices[vCounter] = (_rect.y);
		//Memory.setFloat(vCounter, _y);
		
		vCounter++;
		vertices[vCounter] = (_rect.x + _rect.width);
		//Memory.setFloat(vCounter, _x + _s2.width);
		vCounter++;
		vertices[vCounter] = (_rect.y);
		//Memory.setFloat(vCounter, _y);
		
		vCounter++;
		vertices[vCounter] = (_rect.x);
		//Memory.setFloat(vCounter,_x);
		
		vCounter++;
		vertices[vCounter] = (_rect.y + _rect.height);
		//Memory.setFloat(vCounter,_y + _s2.height);
		
		vCounter ++;
		vertices[vCounter] = (_rect.x + _rect.width);
		//Memory.setFloat(vCounter,_x + _s2.width);
		
		vCounter++;
		vertices[vCounter] = (_rect.y + _rect.height);
		//Memory.setFloat(vCounter,_y + _s2.height);
		vCounter++;
		
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
	
	static inline public function pushQuad3(x1:Float, y1:Float, z1:Float,
								   	 x2:Float, y2:Float, z2:Float,
								   	 x4:Float, y4:Float, z4:Float,
								   	 x3:Float, y3:Float, z3:Float)
	{
		vertices[vCounter] = (x1);
		vCounter ++;
		vertices[vCounter] = (y1);
		vCounter ++;
		vertices[vCounter] = (z1);
		vCounter ++;
		
		vertices[vCounter] = (x2);
		vCounter ++;
		vertices[vCounter] = (y2);		
		vCounter ++;
		vertices[vCounter] = (z2);
		vCounter ++;
		
		vertices[vCounter] = (x3);
		vCounter ++;
		vertices[vCounter] = (y3);		
		vCounter ++;
		vertices[vCounter] = (z3);		
		vCounter ++;
		
		vertices[vCounter] = (x4);		
		vCounter ++;
		vertices[vCounter] = (y4);		
		vCounter ++;
		vertices[vCounter] = (z4);
		vCounter ++;
		
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
	
	static inline public function pushQuad4(x1:Float, y1:Float, z1:Float, w1:Float,
											x2:Float, y2:Float, z2:Float, w2:Float,
											x4:Float, y4:Float, z4:Float, w4:Float,
											x3:Float, y3:Float, z3:Float, w3:Float)
	{
		vertices[vCounter] = (x1);
		vCounter ++;
		vertices[vCounter] = (y1);
		vCounter ++;
		vertices[vCounter] = (z1);
		vCounter ++;
		vertices[vCounter] = (w1);
		vCounter ++;
		
		vertices[vCounter] = (x2);
		vCounter ++;
		vertices[vCounter] = (y2);		
		vCounter ++;
		vertices[vCounter] = (z2);
		vCounter ++;
		vertices[vCounter] = (w2);
		vCounter ++;
		
		vertices[vCounter] = (x3);
		vCounter ++;
		vertices[vCounter] = (y3);		
		vCounter ++;
		vertices[vCounter] = (z3);		
		vCounter ++;
		vertices[vCounter] = (w4);
		vCounter ++;
		
		vertices[vCounter] = (x4);		
		vCounter ++;
		vertices[vCounter] = (y4);		
		vCounter ++;
		vertices[vCounter] = (z4);
		vCounter ++;
		vertices[vCounter] = (w4);
		vCounter ++;
		
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
	
	static public function blit(_s2:Surface2, _x:Int, _y:Int):Void
	{
		vertices[vCounter] = (_x);
		
		vCounter ++;
		vertices[vCounter] = (_y);
		
		vCounter++;
		vertices[vCounter] = (_s2.vx1);
		
		vCounter++;
		vertices[vCounter] = (_s2.vy1);
		
		vCounter++;
		vertices[vCounter] = (_x + _s2.width);
		vCounter++;
		vertices[vCounter] = (_y);
		vCounter++;
		vertices[vCounter] = (_s2.vx2);
		vCounter++;
		vertices[vCounter] = (_s2.vy2);
		
		vCounter++;
		vertices[vCounter] = (_x);
		
		vCounter++;
		vertices[vCounter] = (_y + _s2.height);
		
		vCounter++;
		vertices[vCounter] = (_s2.vx3);
		
		vCounter ++;
		vertices[vCounter] = (_s2.vy3);
		
		vCounter ++;
		vertices[vCounter] = (_x + _s2.width);
		
		vCounter++;
		vertices[vCounter] = (_y + _s2.height);
		
		vCounter++;
		vertices[vCounter] = (_s2.vx4);
	
		vCounter++;
		vertices[vCounter] = (_s2.vy4);
		vCounter ++;
		
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
	
	static public function nbpo2(_in:Int):Int
	{
		_in --;
		_in = (_in >> 1) | _in;
		_in = (_in >> 2) | _in;
		_in = (_in >> 4) | _in;
		_in = (_in >> 8) | _in;
		_in = (_in >> 16) | _in;
		_in++;
		
		return _in;
	}
	
	static public function clear(_r:Float = 1, _g:Float = 1, _b:Float = 1, _a:Float = 1, _d:Float = 1, _s:UInt = 1, _m:UInt = 0xffffffff):Void
	{
		context.clear(_r, _g, _b, _a, _d, _s, _m);
	}
	
	static public function flip():Void
	{
		context.present();
	}
	
	//static publi
	
	static public function draw(_targetBitmap:BitmapData = null):Void
	{
		//context.clear(0, 0, 0, 1);
		
		numVertices = cast (vCounter / data32PerVertex);

		
		if (numVertices != 0)
		{
			//vertexBuffer = vertexBufferList[data32PerVertex];
			//indexBuffer = indexBufferList[data32PerVertex];
			indexBuffer = context.createIndexBuffer(numIndices);
			vertexBuffer = context.createVertexBuffer(numVertices, data32PerVertex);
			
			vertexBuffer.uploadFromVector(vertices, 0, numVertices);
			//vertexBuffer.uploadFromByteArray(bVertices, 0, 0, numVertices);
			indexBuffer.uploadFromVector(indices, 0, numIndices);
			
			//vertexBuffer.
			currentShader.bind(context, vertexBuffer);
			//currentShader.draw(vertexBuffer, indexBuffer);
			context.drawTriangles(indexBuffer);
			currentShader.unbind(context);
			//context.drawToBitmapData(_targetBitmap);
		}
		
		numIndices = 0;
		numVertices = 0;
		vCounter = 0;
		iCounter = 0;
		bVertices.position = 0;
		
		//vertexBuffer.dispose();
		vertexBuffer.dispose();
		indexBuffer.dispose();
	}
	
}