package hxblit;

import kha.Shaders;
import kha.graphics4.BlendingFactor;
import kha.graphics4.BlendingOperation;
import kha.graphics4.CompareMode;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;

/**
 * ...
 * @author
 */
class Tex2PipelineState extends PipelineState {
	public function new() {
		super();

		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float2);
		structure.add("uv", VertexData.Float2);

		inputLayout = [structure];
		fragmentShader = Shaders.tex2_frag;
		vertexShader = Shaders.tex2_vert;
		compile();

		depthWrite = true;
		depthMode = CompareMode.Always;
		blendSource = BlendingFactor.SourceAlpha;
		blendDestination = BlendingFactor.InverseSourceAlpha;
	}

	public function blendMultiply() {
		blendSource = BlendingFactor.DestinationColor;
		blendDestination = BlendingFactor.BlendZero;
	}

	public function blendAlpha() {
		blendSource = BlendingFactor.SourceAlpha;
		blendDestination = BlendingFactor.InverseSourceAlpha;
	}
}
