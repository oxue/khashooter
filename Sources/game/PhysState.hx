package game;

import nape.phys.BodyType;
import nape.shape.Circle;
import nape.geom.Vec2;
import nape.shape.Polygon;
import nape.phys.Body;
import kha.Color;
import kha.Framebuffer;
import refraction.core.State;
import nape.space.Space;

class PhysState extends State {

	var space:Space;
	var body:Body;
	var shape:Polygon;

	var body2:Body;
	var shape2:Polygon;

	public function new() {
		super();
	}

	override function load() {
		space = new Space(new Vec2(0, 300));
		body = new Body(BodyType.STATIC);
		shape = new Polygon([
			new Vec2(0, 0),
			new Vec2(64, 0),
			new Vec2(64, 64),
			new Vec2(0, 64)]);
		shape.body = body;
		shape.body.position.setxy(100, 250);
		body.shapes.add(shape);
		body.space = space;

		body2 = new Body(BodyType.DYNAMIC);
		shape2 = new Polygon([
			new Vec2(-32, -32),
			new Vec2(32, -32),
			new Vec2(32, 32),
			new Vec2(-32, 32)]);
		shape2.body = body2;
		shape2.body.position.setxy(50, 0);
		body2.shapes.add(shape2);
		body2.space = space;
	}

	override function update() {
		space.step(1 / 60);
	}

	override function render(frame:Framebuffer) {
		frame.g2.begin();
		frame.g2.clear(Color.Black);
		frame.g2.color = Color.White;
		frame.g2.drawRect(
			shape.body.position.x,
			shape.body.position.y,
			64,
			64,
			1
		);

		frame.g2.pushRotation(body2.rotation, shape2.body.position.x, shape2.body.position.y);
		frame.g2.drawRect(
			shape2.body.position.x-32,
			shape2.body.position.y-32,
			64,
			64,
			1
		);
		frame.g2.popTransformation();
		frame.g2.end();
	}
}
