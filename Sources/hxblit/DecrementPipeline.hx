package hxblit;

import kha.graphics4.BlendingFactor;
import kha.graphics4.CompareMode;
import kha.graphics4.StencilAction;

/**
 * ...
 * @author
 */
class DecrementPipeline extends Tex2PipelineState {
	public function new() {
		super();

		depthWrite = true;
		stencilFrontMode = CompareMode.Always;
		stencilFrontBothPass = StencilAction.Decrement;
		stencilBackMode = CompareMode.Always;
		stencilBackBothPass = StencilAction.Decrement;
		blendSource = BlendingFactor.BlendZero;
		blendDestination = BlendingFactor.BlendOne;
	}
}
