package hxblit;

import kha.Shaders;
import kha.graphics4.BlendingOperation;
import kha.graphics4.CompareMode;
import kha.graphics4.PipelineState;
import kha.graphics4.StencilAction;
import kha.graphics4.VertexData;
import kha.graphics4.BlendingFactor;
import kha.graphics4.VertexStructure;

/**
 * ...
 * @author
 */
class ShadowPipelineState extends PipelineState {
	public function new() {
		super();

		var structure:VertexStructure = new VertexStructure();
		structure.add("pos", VertexData.Float2);
		structure.add("settings", VertexData.Float2);
		structure.add("coords", VertexData.Float2);
		inputLayout = [structure];
		fragmentShader = Shaders.shadow_frag;
		vertexShader = Shaders.shadow_vert;
		compile();

		blendSource = BlendingFactor.BlendOne;
		blendDestination = BlendingFactor.BlendOne;
		alphaBlendOperation = BlendingOperation.ReverseSubtract;
		alphaBlendDestination = BlendingFactor.BlendOne;
		alphaBlendSource = BlendingFactor.BlendOne;

		stencilMode = CompareMode.Equal;
		stencilBothPass = StencilAction.Keep;
	}
}
