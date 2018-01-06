package hxblit;

import kha.Shaders;
import kha.graphics4.BlendingOperation;
import kha.graphics4.CompareMode;
import kha.graphics4.PipelineState;
import kha.graphics4.StencilAction;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.graphics4.BlendingFactor;

/**
 * ...
 * @author 
 */
class LightPipelineState extends PipelineState
{

	public function new() 
	{
		super();
			
		var structure:VertexStructure = new VertexStructure();
		structure.add("pos", VertexData.Float2);
		
		inputLayout = [structure];
		fragmentShader = Shaders.light_frag;
		vertexShader = Shaders.light_vert;
		compile();
		
		depthWrite = true;
		stencilReferenceValue = 2;
		stencilMode = CompareMode.NotEqual;
		stencilBothPass = StencilAction.Increment;
		blendSource = BlendingFactor.BlendOne;
		blendDestination = BlendingFactor.BlendOne;
	}
	
}