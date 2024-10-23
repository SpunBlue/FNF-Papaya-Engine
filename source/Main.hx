package;

import lime.app.Application;
import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, TitleState));

		#if !mobile
		addChild(new FPS(10, 3, 0xFFFFFF));
		#end

		// Please don't remove this if you're using the Engine for your mod (:
		Application.current.window.title = Application.current.window.title + ' - Papaya Engine';
	}
}
