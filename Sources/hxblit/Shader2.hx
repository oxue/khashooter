package hxblit;
import refraction.ds2d.Float2;

class Shader2 extends hxsl.Shader {

	static var SRC = {
		var input : {
			pos : Float2,
			uv:Float2
		};
		var tuv:Float2;
		function vertex(mproj:M44) {
			out = input.pos.xyzw * mproj;
			tuv = input.uv;
		}
		function fragment(tex:Texture) {
			out = tex.get(tuv,clamp,nearest);
		}
	};

}

/*class Shader2 extends hxsl.Shader {
	
	var input:{
          pos:Float2,
          uv:Float2
     };
     var tuv:Float2;
     function vertex (mproj:M44) {
          out = pos.xyzw * mproj;
          tuv = uv;
     }
     function fragment (tex:Texture) {
          out = tex.get(tuv,clamp,nearest);
     }
	
}*/