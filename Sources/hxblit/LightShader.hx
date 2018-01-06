package hxblit;

class LightShader extends hxsl.Shader {

	static var SRC = {
		var input : {
			pos : Float2,
		};
		var rel:Float4;
		var reld:Float;
		function vertex(mproj:M44, cpos:Float4, radius:Float4) {
			rel = input.pos.xyzw - cpos.xyzw;
			out = input.pos.xyzw * mproj;
			reld = radius.x;
		}
		function fragment(color:Float4) {
			var t = color * (1 - length(rel) / (reld));
			var g:Float4;
			g.x = (t.x >= 1) + t.x * (1 - (t.x >= 1));
			g.y = (t.y >= 1) + t.y * (1 - (t.y >= 1));
			g.z = (t.z >= 1) + t.z * (1 - (t.z >= 1));
			g.w = (t.w >= 1) + t.w * (1 - (t.w >= 1));
			out = g;
		}
	};

}
