package rendering.pipelines;

import kha.graphics4.BlendingFactor;
import kha.graphics4.CompareMode;
import kha.graphics4.StencilAction;

/**
 * ...
 * @author
 */
class DecrementPipelineState extends Tex2PipelineState {

    public function new() {
        super(false);

        depthWrite = true;
        stencilMode = CompareMode.Always;
        stencilBothPass = StencilAction.Decrement;
        blendSource = BlendingFactor.BlendZero;
        blendDestination = BlendingFactor.BlendOne;

        compile();
    }
}
