package;

import kha.System;
import refraction.core.Application;

class Main{
	public static function main() {
		Application.init("HXB Port", 800, 600, 2, function(){
			Application.setState(new KhaBlitTestState());
		});
	}
}
