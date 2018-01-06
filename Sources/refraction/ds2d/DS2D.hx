package refraction.ds2d;


import haxe.ds.Vector;
import hxblit.DecrementPipeline;
import hxblit.KhaBlit;
import hxblit.ShadowPipelineState;
import kha.Color;
import kha.graphics4.Graphics;
import kha.math.FastMatrix4;

import hxblit.LightPipelineState;
import hxblit.TextureAtlas.FloatRect;
import kha.graphics4.DepthStencilFormat;
import kha.Image;
import kha.math.FastMatrix3;
import kha.math.FastVector2;
import kha.math.FastVector3;

import refraction.core.Application;

/**
 * ...
 * @author werber
 */
class DS2D 
{
	public var lights:Array<LightSource>;
	public var polygons:Array<Polygon>;
	public var circles:Array<Circle>;
	
	/*public var s:Sprite;*/
	
	public var shadowBuffer:Image;
	public var offBuffer:Image;
	public var lshader:LightPipelineState;
	public var sshader:ShadowPipelineState;// ShadowShader;
	public var decShader:DecrementPipeline;
	
	private var tempV3:FastVector2;
	private var tempV32:FastVector3;
	private var tempP:FastVector2;
	private var drawRect:FloatRect;
	
	private var ambientLevel:Float;
	private var ambientColor:Color;
	private var experimentalCullingEnabled = false;

	public var screenWidth:Int;
	public var screenHeight:Int;
	
	public function new(_screenWidth:Int, _screenHeight:Int) 
	{
		tempV3 = new FastVector2();
		tempV32 = new FastVector3();
		tempP = new FastVector2();
		lights = new Array<LightSource>();
		polygons = new Array<Polygon>();
		circles = new Array<Circle>();
		screenWidth = _screenWidth;
		screenHeight = _screenHeight;

		#if nodejs
		shadowBuffer = Image.createRenderTarget(screenWidth, screenHeight, null, true);
		offBuffer = Image.createRenderTarget(screenWidth, screenHeight, null, true);
		#else
		shadowBuffer = Image.createRenderTarget(screenWidth, screenHeight, null, DepthStencilFormat.Depth24Stencil8);
		offBuffer = Image.createRenderTarget(screenWidth, screenHeight, null, DepthStencilFormat.Depth24Stencil8);
		#end
		lshader = new LightPipelineState();
		sshader = new ShadowPipelineState();
		drawRect = new FloatRect(0, 0, screenWidth, screenHeight);
		decShader = new DecrementPipeline();
		//circles.push(new Circle(100, 100, 5));
		ambientColor = Color.fromValue(0xffffff);
		ambientLevel = 0.7;
	}
	
	public function setAmbientLevel(_level:Float){ ambientLevel = Math.max(Math.min(1, _level), 0); }
	public function getAmbientLevel():Float { return ambientLevel; }
	public function addLightSource(_l:LightSource) { lights.push(_l); }
	
	public function renderHXB(gameContext:GameContext)
	{	
		shadowBuffer.g4.begin();
		
		var backbuffer:Graphics = KhaBlit.contextG4;
		
		KhaBlit.setContext(shadowBuffer.g4);
		KhaBlit.clear(
			ambientLevel * ambientColor.R,
			ambientLevel * ambientColor.G, 
			ambientLevel * ambientColor.B, 1, 1, 1);//ambientLevel * ambientColor.B, 1, 1, 1);
			
		KhaBlit.setPipeline(decShader, "DecrementPipeline");
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", ResourceFormat.atlases.get("all").image);
		gameContext.currentMap.threashold = true;
		gameContext.currentMap.mode = 1;
		gameContext.currentMap.update();
		
		KhaBlit.draw();

		var i:Int = lights.length;
		var rv:Int = 0;
		while (i-->0){
			var l:LightSource = lights[i];
			
			var camPos:FastVector2 = new FastVector2(gameContext.camera.X(), gameContext.camera.Y());
			
			var lx = l.position.x;
			var ly = l.position.y;
			
			//l.radius = screenHeight;
			//--
			sshader.stencilReferenceValue = rv + 1;
			KhaBlit.setPipeline(sshader, "ShadowPipelineState");
			KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
			KhaBlit.setUniformVec2("cpos", l.position.sub(camPos));
			
			var j:Int = polygons.length;
			while (j-->0)
			{
				var p:Polygon = polygons[j];
				if ((p.x - lx) * (p.x - lx) + (p.y - ly) * (p.y - ly) > l.radius * l.radius)
				continue;
				var k:Int = p.faces.length;
				while (k-->0)
				{
					var f:Face = p.faces[k];
					if(experimentalCullingEnabled){
						if (f.cullNature == 1)
						{
							if (lx > f.v1._0)
							continue;
						}else if (f.cullNature == 2)
						{
							if (lx  <f.v1._0)
							continue;
						}else if (f.cullNature == 3)
						{
							if (ly > f.v1._1)
							continue;
						}else if (f.cullNature == 4)
						{
							if (ly < f.v1._1)
							continue;
						}
					}
					//trace(f.v1._0, f.v1._1, f.v2._0, f.v2._1);
					KhaBlit.pushQuad3(f.v2._0 - camPos.x,
									 f.v2._1 - camPos.y, 0,
									 f.v1._0 - camPos.x,  
									 f.v1._1 - camPos.y, 0,
									                
									 f.v1._0 - camPos.x,  
									 f.v1._1 - camPos.y, 1,
									 f.v2._0 - camPos.x,  
									 f.v2._1 - camPos.y, 1);
				}
			}
			
			KhaBlit.draw();
			
			
			lshader.stencilReferenceValue = rv + 2;
			KhaBlit.setPipeline(lshader, "LightPipelineState");
			KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
			KhaBlit.setUniformVec2("cpos", l.position.sub(camPos));
			KhaBlit.setUniformFloat("radius", l.radius);
			KhaBlit.setUniformVec4("color", l.v3Color);
			//drawRect.x = drawRect.y = 30;
			KhaBlit.pushRect(drawRect);
			KhaBlit.draw();
			rv++;
		}
		shadowBuffer.g4.end();
		
		backbuffer.begin();
		KhaBlit.setContext(backbuffer);
		KhaBlit.KHBTex2PipelineState.blendMultiply();
		KhaBlit.setPipeline(KhaBlit.KHBTex2PipelineState, "KHBTex2PipelineState");
		KhaBlit.matrix2 = FastMatrix4.scale(1, -1, 1).multmat(KhaBlit.matrix2);

		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", shadowBuffer);
		KhaBlit.blit(KhaBlit.getSurface(screenWidth, screenHeight), -1, 1);
		KhaBlit.draw();
		KhaBlit.matrix2 = FastMatrix4.scale(1, -1,1).multmat(KhaBlit.matrix2);

		backbuffer.end();
		
		gameContext.currentMap.threashold = false;
		KhaBlit.KHBTex2PipelineState.blendAlpha();
	}
	
	public function wipeout():Void
	{
		lights = new Array<LightSource>();
		polygons = new Array<Polygon>();
	}
	
}

