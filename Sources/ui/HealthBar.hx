package ui;

import components.Health;
import kha.Framebuffer;

class HealthBar {

	private inline static var TOP_MARGIN = 10;
	private inline static var LEFT_MARGIN = 10;
	private inline static var INNER_TOP_MARGIN = 3;
	private inline static var INNER_LEFT_MARGIN = 3;

	private var width:Int;
	private var health:Health;

	public function new(_health:Health, _width = 100) {
		this.health = _health;
		this.width = _width;
	}

	public function render(f:Framebuffer) {
		f.g2.color = kha.Color.Black;
		f.g2.fillRect(LEFT_MARGIN, TOP_MARGIN, width, 20);
		f.g2.color = kha.Color.Red;
		var healthRatio = health.value / health.maxValue;
		var innerWidth = width - INNER_LEFT_MARGIN * 2;
		f.g2.fillRect(
			LEFT_MARGIN + INNER_LEFT_MARGIN, 
			TOP_MARGIN + INNER_TOP_MARGIN,
			healthRatio * innerWidth,
			20 - INNER_TOP_MARGIN * 2);
	}
}