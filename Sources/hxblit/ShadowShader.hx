package hxblit;

class ShadowShader extends hxsl.Shader {

	static var SRC = {
		var input : {
			pos : Float3,
		};
		function vertex(mproj:M44, cpos:Float4) {
			var v0:Float2 = (input.pos.xy - cpos.xy);
			var v1:Float = length(v0);
			v0 = normalize([v0.x,v0.y,0]).xy;
			v0 *= input.pos.z * 200;
			v0 += input.pos.xy;
			var v1:Float4 = [v0.x, v0.y, 0, 1];
			out = v1 * mproj;
		}
		function fragment() {
			out = [0,0,0,1];
		}
	};

}
