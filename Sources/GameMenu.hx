package ;
import graphite.GButton;
import graphite.GDropMenu;
import graphite.GInput;
import graphite.GPane;
import graphite.GRadioButton;
import refraction.core.Application;

/**
 * ...
 * @author ...
 */
class GameMenu extends GPane
{

	private var mapNameInput:GInput;
	
	public function new() 
	{
		super("Game Menu", 300, 400, false);
		//x = y = 10;
		alpha = 0.8;
		
		addGObject(new GButton("New Game", 200, 20, newGame), 20, cast height - 40);
		mapNameInput = cast addGObject(new GInput("Map"),20,40);
		var m:GDropMenu = cast addGObject(new GDropMenu("Map Selection",200,200), 20, 80);
		m.addMenuItem("bloodstrike_zm", chooseMap);
		m.addMenuItem("rooms", chooseMap);
		//m.addMenuItem("level2", chooseMap);
		//m.addSeperator();
		//m.addMenuItem("random", chooseMap);
	}
	
	function chooseMap(b:GButton):Void
	{
		mapNameInput.set_value(b.get_label());
	}
	
	function newGame(b:GButton) 
	{
		cast(Application.currentState, GameState).loadLevel(mapNameInput.get_value() + ".json");
	}
	
}