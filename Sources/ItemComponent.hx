package ;
import refraction.generic.Position;
import refraction.core.Component;

/**
 * ...
 * @author worldedit
 */

class ItemComponent extends Component
{
	
	public var position:Position;
	public var content:Weapon;

	public function new(_content:Weapon) 
	{
		super("item_comp");
		content = _content;
	}
	
	override public function load():Void 
	{
		position = cast entity.components.get("pos_comp");
	}
	
	public function collect(_inv:Inventory):Void
	{
		var m:Weapon = content;
		TextPrompt.display("picked up " + m.name);
		//make current weapon =
		_inv.currentWeapon = m;
		//put into type slot
		_inv.weapons[m.type] = m;
		
		_inv.setWeaponAnimAndSwitchAmmo(m);
		//current type
		_inv.currentIndex = m.type;
		m.getAmmo(_inv);
	}
	
}