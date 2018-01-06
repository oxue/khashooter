package refraction.systems;

import refraction.core.Sys;
import zui.Zui;
import zui.Id;
import refraction.core.Application;
import refraction.generic.Tooltip;
import kha.math.Vector2;
import refraction.core.Sys;

/**
 * ...
 * @author 
 */
class TooltipSys extends Sys<Tooltip>
{
	private var ui:Zui;
	private var margin:Int = 5;
	private var textSize:Int = 16;

	public function new(_ui:Zui) 
	{
		super();
		ui = _ui;
		components = new Array<Tooltip>();
	}
	
	public function draw(g2:kha.graphics2.Graphics)
	{
		sweepRemoved();

		var mouseCoords = new Vector2(Application.mouseX / 2, Application.mouseY / 2);
		var hoveredItems = components.filter(function(tooltip) return tooltip.containsPoint(mouseCoords));
		if(hoveredItems.length != 0){
			drawTooltip(hoveredItems[0], g2);
		}
	}

	private function drawTooltip(tooltip:Tooltip, g2:kha.graphics2.Graphics):Void
	{
		g2.color = kha.Color.Black;
		var textWidth = kha.Assets.fonts.OpenSans.width(textSize,tooltip.message);
		g2.fillRect(
			Application.mouseX,
			Application.mouseY,
			textWidth + margin*2,
			kha.Assets.fonts.OpenSans.height(textSize) + margin*2*0.8);
		g2.font = kha.Assets.fonts.OpenSans;
		g2.fontSize = textSize;
		g2.color = tooltip.color;
		g2.drawString(tooltip.message, Application.mouseX +margin, Application.mouseY + margin*0.8);
	}
	
}