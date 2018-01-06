package refraction.control;

import kha.math.FastVector2;
import refraction.core.Component;
import refraction.generic.Position;
import refraction.generic.Velocity;

/**
 * ...
 * @author 
 */
class BreadCrumbs extends Component
{
	
	public var breadcrumbs:Array<FastVector2>;
	public var acceptanceRadius:Float;
	public var maxAcceleration:Float;
	
	public var position:Position;
	public var velocity:Velocity;

	public function new() 
	{
		breadcrumbs = new Array();
		
		super();
	}

	override public function autoParams(_args:Dynamic):Void
	{
		acceptanceRadius = _args.acceptanceRadius;
		maxAcceleration = _args.maxAcceleration;
	}

	public function addBreadCrumb(_v:FastVector2){
		breadcrumbs.push(_v);
	}
	
	override public function load():Void 
	{
		position = entity.getComponent(Position);
		velocity = entity.getComponent(Velocity);
	}
	
}