package rendering.pipelines;

import kha.Shaders;
import kha.graphics4.BlendingFactor;
import kha.graphics4.CompareMode;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;

/**
 * ...
 * @author
 */
class Tex2PipelineState extends PipelineState {

    public function new(doCompile = true, blendMode = "alpha") {
        super();

        var structure:VertexStructure = new VertexStructure();
        structure.add("pos", VertexData.Float2);
        structure.add("uv", VertexData.Float2);

        inputLayout = [structure];

        fragmentShader = Shaders.tex2_frag;
        vertexShader = Shaders.tex2_vert;

        depthWrite = false;
        depthMode = CompareMode.Always;

        if (blendMode == "alpha") {
            useBlendAlpha();
        } else if (blendMode == "multiply") {
            useBlendMultiply();
        }

        if (doCompile) {
            compile();
        }
    }

    public function useBlendMultiply() {
        blendSource = BlendingFactor.DestinationColor;
        blendDestination = BlendingFactor.BlendZero;
        alphaBlendSource = BlendingFactor.BlendZero;
        alphaBlendDestination = BlendingFactor.BlendOne;
    }

    public function useBlendAlpha() {
        blendSource = BlendingFactor.SourceAlpha;
        blendDestination = BlendingFactor.InverseSourceAlpha;
        alphaBlendSource = BlendingFactor.BlendZero;
        alphaBlendDestination = BlendingFactor.BlendOne;
    }
}
