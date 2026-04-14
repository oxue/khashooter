package refraction.ds2d;

import refraction.core.Application;
import rendering.Camera;
import rendering.KhaVertexIndexer;
import rendering.TextureAtlas.FloatRect;
import rendering.pipelines.DecrementPipelineState;
import rendering.pipelines.LightPipelineState;
import rendering.pipelines.ShadowPipelineState;
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
    public var sshader:ShadowPipelineState;
    public var decShader:DecrementPipelineState;

    public var screenWidth:Int;
    public var screenHeight:Int;

    var tempV3:Vector2;
    var tempV32:FastVector3;
    var tempP:Vector2;
    var drawRect:FloatRect;

    var ambientLevel:Float;
    var ambientColor:Color;

    public var globalRadius:Float = 15;

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
        shadowBuffer = Image.createRenderTarget(screenWidth, screenHeight, null, true);
        offBuffer = Image.createRenderTarget(screenWidth, screenHeight, null, true);
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
        decShader = new DecrementPipelineState();
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

    public function debugDraw(camera:Camera, g:kha.graphics2.Graphics,
            shadowPolyLists:Array<Array<Polygon>>) {
        for (l in shadowPolyLists) {
            for (p in l) {
                p.debugDraw(camera, g);
            }
        }
        for (l in lights) {
            l.debugDraw(camera, g, globalRadius);
            for (ls in shadowPolyLists) {
                for (p in ls) {
                    renderDebugPolygonShadow(p, l, camera.position(), g);
                }
            }
        }
    }

    function softVert(pos:Vector2, settings:Vector2, cpos:Vector2, camera_position:Vector2,
            sourceRadius:Float):Vector2 {
        var castRadius:Float = 300; // replace this with uniform

        var penumbraOffsetFlag:Float = Math.abs(settings.y) - 1;
        var extendLineFlag:Float = settings.x;
        var camera_space_pos:Vector2 = pos.sub(camera_position);

        var light_center_pos:Vector2 = cpos.sub(camera_position);
        var lightDirection:Vector2 = camera_space_pos
            .sub(light_center_pos)
            .normalized();
        var lightLeftHand:Vector2 = new Vector2(lightDirection.y, -lightDirection.x);
        var lightPoint:Vector2 = light_center_pos.add(
            lightLeftHand.mult(penumbraOffsetFlag * sourceRadius)
        );

        var castDirection:Vector2 = camera_space_pos
            .sub(lightPoint)
            .normalized();
        castDirection = castDirection
            .mult(extendLineFlag * castRadius)
            .add(camera_space_pos);

        return new Vector2(castDirection.x, castDirection.y);
    }

    function renderDebugPolygonShadow(p:Polygon, l:LightSource, camPos:Vector2, g:kha.graphics2.Graphics) {
        var k:Int = p.faces.length;
        while (k-- > 0) {
            var f:Face = p.faces[k];

            var p0:Vector2 = f.v1;
            var p1:Vector2 = f.v2;
            var segment:Vector2 = p1.sub(p0);
            var toLight:Vector2 = l.position.sub(p0);
            var dot:Float = segment.dot(toLight);
            if (dot < 0) {
                var tmp:Vector2 = p0;
                p0 = p1;
                p1 = tmp;
            }

            var light_screen_pos:Vector2 = l.position.sub(camPos);
            // @formatter:off
            g.color = Color.Yellow;
            var zoom:Int = Application.getScreenZoom();
            var q1:Vector2 = softVert(p1, new Vector2(0, 1), l.position, camPos, globalRadius).mult(zoom);
            var q2:Vector2 = softVert(p0, new Vector2(0, 1), l.position, camPos, globalRadius).mult(zoom);
            var q3:Vector2 = softVert(p0, new Vector2(1, 1), l.position, camPos, globalRadius).mult(zoom);
            var q4:Vector2 = softVert(p1, new Vector2(1, 1), l.position, camPos, globalRadius).mult(zoom);
            g.drawLine(q1.x, q1.y, light_screen_pos.x * zoom, light_screen_pos.y * zoom);
            g.drawLine(q2.x, q2.y, light_screen_pos.x * zoom, light_screen_pos.y * zoom);

            g.drawLine(q2.x, q2.y, q3.x, q3.y);
            g.drawLine(q4.x, q4.y, q1.x, q1.y);

            // @formatter:on
        }
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
            KhaVertexIndexer.pushQuad6(
                p1.x, p1.y, 0, 1, 1, 1,
                p0.x, p0.y, 0, 1, 1, 1,
                p0.x, p0.y, 1, 1, 1, 1,
                p1.x, p1.y, 1, 1, 1, 1
            );
            KhaVertexIndexer.pushTriangle6(
                p1.x, p1.y, 0, -1, 0, 0,
                p1.x, p1.y, 1, -1, 1, 0,
                p1.x, p1.y, 1, 2, 0, 1
            );
            KhaVertexIndexer.pushTriangle6(
                p0.x, p0.y, 0, -1, 0, 0,
                p0.x, p0.y, 1, -1, 1, 0,
                p0.x, p0.y, 1, 0, 0, 1
            );
            // @formatter:on
        }
    }

    function renderShadowsForLightsource(camera:Camera, rv:Int, l:LightSource,
            shadowPolyLists:Array<Array<Polygon>>) {
        var camPos:Vector2 = camera.roundedVec2();

        sshader.stencilReferenceValue = Static(rv);
        
        KhaVertexIndexer.setPipeline(sshader, "ShadowPipelineState");
        KhaVertexIndexer.setUniformMatrix4("mproj", KhaVertexIndexer.matrix2);
        var cpos:Vector2 = l.position;
        KhaVertexIndexer.setUniformVec2("cpos", new FastVector2(cpos.x, cpos.y));
        KhaVertexIndexer.setUniformVec2(
            "camera_position",
            new FastVector2(camPos.x, camPos.y)
        );
        KhaVertexIndexer.setUniformFloat("sourceRadius", globalRadius);
        // KhaVertexIndexer.setUniformTexture("normalmap", kha.Assets.images.normalmap);

        for (polygonList in shadowPolyLists) {
            for (p in polygonList) {
                renderPolygonShadow(p, l, camPos);
            }
        }
        KhaVertexIndexer.draw();

        KhaVertexIndexer.setPipeline(lshader, "LightPipelineState");
        KhaVertexIndexer.setUniformMatrix4("mproj", KhaVertexIndexer.matrix2);
        KhaVertexIndexer.setUniformVec2("cpos", new FastVector2(cpos.x, cpos.y));
        KhaVertexIndexer.setUniformVec2(
            "camera_position",
            new FastVector2(camPos.x, camPos.y)
        );
        KhaVertexIndexer.setUniformFloat("radius", l.radius);
        KhaVertexIndexer.setUniformVec4("color", l.v3Color);
        KhaVertexIndexer.pushRect(drawRect);
        KhaVertexIndexer.draw();
    }

    public function renderSceneWithLighting(camera:Camera, tilemap:refraction.tilemap.TileMap, shadowPolyLists:Array<Array<Polygon>>) {
        var backbuffer:Graphics = KhaVertexIndexer.contextG4;

        shadowBuffer.g4.begin();
        KhaVertexIndexer.setContext(shadowBuffer.g4);
        KhaVertexIndexer.clear(
            ambientLevel * ambientColor.R,
            ambientLevel * ambientColor.G,
            ambientLevel * ambientColor.B,
            1,
            1,
            1
        );

        KhaVertexIndexer.setPipeline(decShader, "DecrementPipeline");
        KhaVertexIndexer.setUniformMatrix4("mproj", KhaVertexIndexer.matrix2);
        KhaVertexIndexer.setUniformTexture("tex", ResourceFormat.atlases
            .get("all")
            .image
        );
        tilemap.threashold = true;
        tilemap.mode = 1;
        tilemap.render(camera);

        KhaVertexIndexer.draw();

        var i:Int = lights.length;
        var stencilValueOne:Int = 1;
        while (i-- > 0) {
            var lightSource:LightSource = lights[i];
            if (lightSource.remove) {
                Utils.quickRemoveIndex(lights, i);
                continue;
            }
            renderShadowsForLightsource(
                camera,
                stencilValueOne,
                lightSource,
                shadowPolyLists
            );
        }
        shadowBuffer.g4.end();

        backbuffer.begin();
        KhaVertexIndexer.setContext(backbuffer);
        KhaVertexIndexer.setPipeline(
            KhaVertexIndexer.Tex2MultiplyPipelineState,
            "KHBTex2PipelineStateMult"
        );
        #if kha_html5
        KhaVertexIndexer.matrix2 = FastMatrix4
            .scale(1, -1, 1)
            .multmat(KhaVertexIndexer.matrix2);
        #end

        KhaVertexIndexer.setUniformMatrix4("mproj", KhaVertexIndexer.matrix2);
        KhaVertexIndexer.setUniformTexture("tex", shadowBuffer);
        KhaVertexIndexer.blit(
            KhaVertexIndexer.getSurface(screenWidth, screenHeight),
            -1,
            1
        );
        KhaVertexIndexer.draw();
        #if kha_html5
        KhaVertexIndexer.matrix2 = FastMatrix4
            .scale(1, -1, 1)
            .multmat(KhaVertexIndexer.matrix2);
        #end

        backbuffer.end();

        tilemap.threashold = false;
    }

    public function wipeout() {
        lights = [];
        polygons = [];
    }
}
