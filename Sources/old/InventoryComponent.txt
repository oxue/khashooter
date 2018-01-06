package ;
import flash.geom.Point;
import flash.ui.Keyboard;
import flash.Vector;
import refraction.core.ActiveComponent;
import refraction.core.Application;
import refraction.core.Utils;
import refraction.display.BlitComponentC;
import refraction.display.Surface2RenderComponentC;
import refraction.ds2d.LightSource;
import refraction.generic.PositionComponent;
import refraction.core.SubSystem;

/**
 * ...
 * @author worldedit
 */

class InventoryComponent extends ActiveComponent
{
	
	private var mouseDown:Bool;
	private var mouseWasDown:Bool;
	
	private var position:PositionComponent;
	private var swap:Bool;
	private var winq:ItemComponent;
	
	public var currentWeapon:Weapon;
	public var weapons:Vector<Weapon>;
	public var targetSystem:SubSystem<ItemComponent>; 
	
	public var wasDownE:Bool;
	public var wasDownQ:Bool;

	public var blitc:Surface2RenderComponentC;
	
	public var targetFlashLight:LightSource;
	
	public var lightT:Int;
	public var lightFullTime:Int;
	public var lightDimmingTime:Int;
	public var dimProgressionTemp:Float;
	
	public var primaryAmmo:AmmunitionObject;
	public var secondaryAmmo:AmmunitionObject;
	
	public var currentAmmo:AmmunitionObject;
	
	private var lightControl:LightControlComponent;
	
	public var currentIndex:Int;
	
	public function new() 
	{
		super("inventory_comp");
		//currentWeapon = new M357();
		weapons = new Vector<Weapon>();
		weapons.push(null);
		weapons.push(null);
	}
	
	override public function load():Void 
	{
		lightFullTime = 11100;
		lightDimmingTime = 800;
		dimProgressionTemp = 1 / lightDimmingTime;
		lightT = lightFullTime + lightDimmingTime;
		
		position = cast entity.components.get("pos_comp");
		lightControl = cast entity.components.get("light_control_comp");
		
		
		
		//TODO: for removal cus you get get free ammo
		secondaryAmmo = new AmmunitionObject(6);
		secondaryAmmo.applyAmmo(18);
		secondaryAmmo.reload();
		
		primaryAmmo = new AmmunitionObject(30);
		primaryAmmo.applyAmmo(90);
		primaryAmmo.reload();
		
		currentAmmo = null;
	}
	
	public inline function setWeaponAnimAndSwitchAmmo(_weapon:Weapon):Void
	{
		_weapon.setAnimation(blitc);
		if (_weapon.type == 0)
		{
			currentAmmo = secondaryAmmo;
		}else if (_weapon.type == 1)
		{
			currentAmmo = primaryAmmo;
		}
	}
	
	public inline function switchWeapon():Void
	{
		//march forward in weapon index and do a modulo two
		currentIndex++;
		currentIndex %= 2;
		currentWeapon = weapons[currentIndex];
		
		//like it says
		setWeaponAnimAndSwitchAmmo(currentWeapon);
	}
	
	override public function update():Void 
	{		
		//iter through list of items on the ground
		var i:Int = targetSystem.components.length;
		while (i-->0)
		{
			var item:ItemComponent = targetSystem.components[i];
			//swap state
			swap = false;
			winq = null;
			//within distance of 100 
			//TODO: change 100
			if (Utils.posDis2(position, item.position) < 100)
			{
				//if the slot for this type of weapon is NOT empty...
				if (weapons[item.content.type] != null)
				{
					//allow for swapping
					swap = true;
					//the weapon in question is this:
					winq = item;
				}else {//not occupied bu a weapon already
					//remove the current item from the "floor" immediately
					item.entity.removeImmediately();
					//collection...
					//TODO: Review this 
					item.collect(this);
				}
			}
		}
		
		//If I just pressed E this frame and we are in "swapping state" because an nearby item is detected
		if (Application.keys.get(Keyboard.E) && !wasDownE == true && swap)
		{
			//create the weapon current weapon using the type we are trying to replace 
			// drop on current position
			Factory.createItem(weapons[winq.content.type].name, cast position.x, cast position.y);
			swap = false;//end swapping state
			
			//remove the thing from the map
			winq.entity.removeImmediately();
			//collection code TO BE REVIEWED
			winq.collect(this);
			
			//no more weapon in question cus we picked it up
			winq = null;
		}
		
		//Q press
		if (Application.keys.get(Keyboard.Q) && wasDownQ == false)
		{
			switchWeapon();
		}
		
		//save mous state
		
		mouseWasDown = mouseDown;
		mouseDown = Application.mouseIsDown;
		
		//if there currently is a weapon
		if (currentWeapon != null)
		{
			//update logic
			currentWeapon.update();
			if (mouseDown)
			{
				if (!mouseWasDown)
				{
					currentWeapon.castWeapon(position);
				}else
				{
					currentWeapon.persistCast(position);
				}
			}
		}
		
		//get key states
		wasDownE = Application.keys.get(Keyboard.E);
		wasDownQ = Application.keys.get(Keyboard.Q);
		
		//lighting code
		lightT --;
		if (lightT < lightDimmingTime)
		{
			var rat:Float = lightT / lightDimmingTime * (lightControl.targetLight.color/0xffffff);
			lightControl.setColor(rat, rat, rat);
		}
	}
}