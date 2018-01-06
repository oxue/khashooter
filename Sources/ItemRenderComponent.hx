package ;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import refraction.core.Component;
import refraction.core.Application;
import refraction.display.Canvas;

/**
 * ...
 * @author worldedit
 */

class ItemRenderComponent extends Component
{

	public var targetCanvas:Canvas;
	public var blankBlock:BitmapData;
	public var blankBattery:BitmapData;
	
	private var inventory:Inventory;
	
	public function new() 
	{
		super("item_render_comp");
	}
	
	override public function load():Void 
	{
		blankBlock = new BitmapData(20, 20, true, 0x0);
		blankBlock.fillRect(blankBlock.rect, 0xaaffffff);
		blankBlock.fillRect(new Rectangle(2, 2, 16, 16), 0x0);
		
		blankBattery = new BitmapData(21, 10, true, 0x0);
		var r:Rectangle = blankBattery.rect.clone();
		r.width--;
		blankBattery.fillRect(r, 0xaaffffff);
		r.width -= 2;
		r.height -= 2;
		r.x ++;
		r.y ++;
		blankBattery.fillRect(r, 0x0);
		r = new Rectangle(20, 2, 1, 6);
		blankBattery.fillRect(r, 0xaaffffff);
		inventory = cast entity.components.get("inventory_comp");
	}
	
	override public function update():Void 
	{
		drawWeapons();
		drawBattery();
		drawAmmo();
	}
	
	private inline function drawWeapons()
	{
		var i:Int = -1;
		while (i++ < 1)
		{
			targetCanvas.displayData.copyPixels(blankBlock, blankBlock.rect, new Point(10 + i* 30,10),null,null,true);
			//targetCanvas.displayData.fillRect(new Rectangle(0, 0, 10, 10), 0xffff0000);
			if (inventory.weapons[i] != null)
			{
				targetCanvas.displayData.copyPixels(blankBlock, blankBlock.rect, new Point(12 + i* 30,10),null,null,true);
			}
		}
	}
	
	private inline function drawBattery()
	{
		targetCanvas.displayData.copyPixels(blankBattery, blankBattery.rect, new Point(10, 180), null, null, true);
		targetCanvas.displayData.fillRect(
											new Rectangle(
											12,
											182,
											10 * inventory.lightT / (inventory.lightDimmingTime + inventory.lightFullTime),
											6), 
											0xaaffffff);
	}
	
	private inline function drawAmmo()
	{
		if (inventory.currentAmmo != null)
		{
		var n:Int = inventory.currentAmmo.bulletCount;
			var r:Rectangle = new Rectangle(400 - 12, 200 - 16, 2, 6);
			while (n-->0)
			{
				targetCanvas.displayData.fillRect(r, 0xaaffffff);
				r.x -= 4;
			}
		}
	}
	
}