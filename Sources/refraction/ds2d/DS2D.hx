package refraction.ds2d;

import game.GameContext;
import hxblit.DecrementPipeline;
import hxblit.KhaBlit;
import hxblit.LightPipelineState;
import hxblit.ShadowPipelineState;
import hxblit.TextureAtlas.FloatRect;
import kha.Color;
import kha.Image;
import kha.graphics4.DepthStencilFormat;
import kha.graphics4.Graphics;
import kha.math.FastMatrix4;
import kha.math.FastVector2;
import kha.math.FastVector3;
import kha.math.Vector2;
import refraction.core.Utils;
import refraction.display.ResourceFormat;

/**
 * ...
 * @author werber
 */
class DS2D {

	public var lights:Array<LightSource>;
	public var polygons:Array<Polygon>;
	public var circles:Array<CircleCmp>;

	/*public var s:Sprite;*/
	public var shadowBuffer:Image;
	public var offBuffer:Image;
	public var lshader:LightPipelineState;
	public var sshader:ShadowPipelineState; // ShadowShader;
	public var decShader:DecrementPipeline;

	public var screenWidth:Int;
	public var screenHeight:Int;

	var tempV3:Vector2;
	var tempV32:FastVector3;
	var tempP:Vector2;
	var drawRect:FloatRect;

	var ambientLevel:Float;
	var ambientColor:Color;

	public function new(_screenWidth:Int, _screenHeight:Int) {
		tempV3 = new Vector2();
		tempV32 = new FastVector3();
		tempP = new Vector2();
		lights = [];
		polygons = [];
		circles = [];
		screenWidth = _screenWidth;
		screenHeight = _screenHeight;

		#if nodejs
		shadowBuffer = Image.createRenderTarget(
			screenWidth,
			screenHeight,
			null,
			true
		);
		offBuffer = Image.createRenderTarget(
			screenWidth,
			screenHeight,
			null,
			true
		);
		#else
		shadowBuffer = Image.createRenderTarget(
			screenWidth,
			screenHeight,
			null,
			DepthStencilFormat.Depth24Stencil8
		);
		offBuffer = Image.createRenderTarget(
			screenWidth,
			screenHeight,
			null,
			DepthStencilFormat.Depth24Stencil8
		);
		#end
		lshader = new LightPipelineState();
		sshader = new ShadowPipelineState();
		drawRect = new FloatRect(0, 0, screenWidth, screenHeight);
		decShader = new DecrementPipeline();
		ambientColor = Color.fromValue(0xffffff);
		ambientLevel = 0.2;
	}

	public function setAmbientLevel(_level:Float) {
		ambientLevel = Math.max(Math.min(1, _level), 0);
	}

	public function getAmbientLevel():Float {
		return ambientLevel;
	}

	public function addLightSource(_l:LightSource) {
		lights.push(_l);
	}

	function renderPolygonShadow(p:Polygon, l:LightSource, camPos:Vector2) {
		var k:Int = p.faces.length;
		while (k-- > 0) {
			var f:Face = p.faces[k];

			var p0:Vector2 = f.v1;
			var p1:Vector2 = f.v2;
			var segment:Vector2 = p1.sub(p0);
			var toLight:Vector2 = l.position.sub(p0);
			var dot:Float = segment.dot(toLight);
			if (dot < 0) {
				var tmp = p0;
				p0 = p1;
				p1 = tmp;
			}

			// @formatter:off
			KhaBlit.pushQuad6(
				p1.x - camPos.x, p1.y - camPos.y, 0, 1, 1, 1,
				p0.x - camPos.x, p0.y - camPos.y, 0, 1, 1, 1,
				p0.x - camPos.x, p0.y - camPos.y, 1, 1, 1, 1,
				p1.x - camPos.x, p1.y - camPos.y, 1, 1, 1, 1
			);
			KhaBlit.pushTriangle6(
				p1.x - camPos.x, p1.y - camPos.y, 0, -1, 0, 0,
				p1.x - camPos.x, p1.y - camPos.y, 1, -1, 1, 0,
				p1.x - camPos.x, p1.y - camPos.y, 1, 2, 0, 1
			);
			KhaBlit.pushTriangle6(
				p0.x - camPos.x, p0.y - camPos.y, 0, -1, 0, 0,
				p0.x - camPos.x, p0.y - camPos.y, 1, -1, 1, 0,
				p0.x - camPos.x, p0.y - camPos.y, 1, 0, 0, 1
			);
			// @formatter:on
		}
	}

	function renderShadowsForLightsource(
		gameContext:GameContext,
		rv: Int,
		l: LightSource
	) {
		var camPos:Vector2 = gameContext.camera.roundedVec2();

		sshader.stencilReferenceValue = Static(rv);
		KhaBlit.setPipeline(sshader, "ShadowPipelineState");
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		var cpos = l.position.sub(camPos);
		KhaBlit.setUniformVec2(
			"cpos",
			new FastVector2(cpos.x, cpos.y)
		);
		KhaBlit.setUniformTexture(
			"normalmap",
			kha.Assets.images.normalmap
		);

		var j:Int = polygons.length;
		while (j-- > 0) {
			var p:Polygon = polygons[j];
			renderPolygonShadow(p, l, camPos);
		}

		KhaBlit.draw();

		KhaBlit.setPipeline(lshader, "LightPipelineState");
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformVec2(
			"cpos",
			new FastVector2(cpos.x, cpos.y)
		);
		KhaBlit.setUniformFloat("radius", l.radius);
		KhaBlit.setUniformVec4("color", l.v3Color);
		KhaBlit.pushRect(drawRect);
		KhaBlit.draw();
	}

	public function renderHXB(gameContext:GameContext) {
		var backbuffer:Graphics = KhaBlit.contextG4;

		shadowBuffer.g4.begin();
		KhaBlit.setContext(shadowBuffer.g4);
		KhaBlit.clear(
			ambientLevel * ambientColor.R,
			ambientLevel * ambientColor.G,
			ambientLevel * ambientColor.B,
			1,
			1,
			1
		);

		KhaBlit.setPipeline(decShader, "DecrementPipeline");
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture(
			"tex",
			ResourceFormat.atlases
				.get("all")
				.image
		);
		gameContext.tilemapRender.threashold = true;
		gameContext.tilemapRender.mode = 1;
		gameContext.tilemapRender.render();

		KhaBlit.draw();

		var i:Int = lights.length;
		var stencilValueOne:Int = 1;
		while (i-- > 0) {
			var lightSource:LightSource = lights[i];
			if (lightSource.remove) {
				Utils.quickRemoveIndex(lights, i);
				continue;
			}
			renderShadowsForLightsource(gameContext, stencilValueOne, lightSource);
		}
		shadowBuffer.g4.end();

		backbuffer.begin();
		KhaBlit.setContext(backbuffer);
		KhaBlit.KHBTex2PipelineState.blendMultiply();
		KhaBlit.setPipeline(
			KhaBlit.KHBTex2PipelineState,
			"KHBTex2PipelineState"
		);
		KhaBlit.matrix2 = FastMatrix4
			.scale(1, -1, 1)
			.multmat(KhaBlit.matrix2);

		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", shadowBuffer);
		KhaBlit.blit(
			KhaBlit.getSurface(screenWidth, screenHeight),
			-1,
			1
		);
		KhaBlit.draw();
		KhaBlit.matrix2 = FastMatrix4
			.scale(1, -1, 1)
			.multmat(KhaBlit.matrix2);

		backbuffer.end();

		gameContext.tilemapRender.threashold = false;
		KhaBlit.KHBTex2PipelineState.blendAlpha();
	}

	public function wipeout() {
		lights = [];
		polygons = [];
	}
}
