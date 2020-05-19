package hxblit;

import kha.Shaders;
import kha.graphics4.BlendingFactor;
import kha.graphics4.BlendingOperation;
import kha.graphics4.CompareMode;
import kha.graphics4.PipelineState;
import kha.graphics4.StencilAction;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;

/**
 * ...
 * @author
 */
class DecrementPipeline extends Tex2PipelineState {
	public function new() {
		super();

		depthWrite = true;
		stencilMode = CompareMode.Always;
		stencilBothPass = StencilAction.Decrement;
		blendSource = BlendingFactor.BlendZero;
		blendDestination = BlendingFactor.BlendOne;
	}
}
