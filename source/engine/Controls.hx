package engine;

import engine.Options;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

class Controls {
	// maps
	public static var controlMap:Map<String, Array<FlxKey>> = new Map();

	// controls
	public var LEFT:Bool = false;
	public var DOWN:Bool = false;
	public var UP:Bool = false;
	public var RIGHT:Bool = false;

	public var LEFT_P:Bool = false;
	public var DOWN_P:Bool = false;
	public var UP_P:Bool = false;
	public var RIGHT_P:Bool = false;

	public var LEFT_R:Bool = false;
	public var DOWN_R:Bool = false;
	public var UP_R:Bool = false;
	public var RIGHT_R:Bool = false;

	public var ACCEPT:Bool = false;
	public var BACK:Bool = false;
	public var PAUSE:Bool = false;
	public var RESET:Bool = false;
	
	public var CHEAT:Bool = false;

	// unused
	public var DEBUG:Bool = false;
	public function new() {} // do nothing

	public static function init() // temporary
	{
		controlMap.set("left", [FlxKey.LEFT, Options.controlScheme[0].key]);
		controlMap.set("down", [FlxKey.DOWN, Options.controlScheme[1].key]);
		controlMap.set("up", [FlxKey.UP, Options.controlScheme[2].key]);
		controlMap.set("right", [FlxKey.RIGHT, Options.controlScheme[3].key]);

		controlMap.set("accept", [ENTER, SPACE]);
		controlMap.set("back", [ESCAPE, BACKSPACE]);
		controlMap.set("pause", [ESCAPE]);
		controlMap.set("reset", [F1]);

		controlMap.set("cheat", [TAB]);
	}

	public function update()
	{
		LEFT = FlxG.keys.anyPressed(controlMap.get('left'));
		LEFT_P = FlxG.keys.anyJustPressed(controlMap.get('left'));
		LEFT_R = FlxG.keys.anyJustReleased(controlMap.get('left'));

		DOWN = FlxG.keys.anyPressed(controlMap.get('down'));
		DOWN_P = FlxG.keys.anyJustPressed(controlMap.get('down'));
		DOWN_R = FlxG.keys.anyJustReleased(controlMap.get('down'));

		UP = FlxG.keys.anyPressed(controlMap.get('up'));
		UP_P = FlxG.keys.anyJustPressed(controlMap.get('up'));
		UP_R = FlxG.keys.anyJustReleased(controlMap.get('up'));

		RIGHT = FlxG.keys.anyPressed(controlMap.get('right'));
		RIGHT_P = FlxG.keys.anyJustPressed(controlMap.get('right'));
		RIGHT_R = FlxG.keys.anyJustReleased(controlMap.get('right'));

		ACCEPT = FlxG.keys.anyJustPressed(controlMap.get('accept'));
		BACK = FlxG.keys.anyJustPressed(controlMap.get('back'));
		PAUSE = FlxG.keys.anyJustPressed(controlMap.get('pause'));
		RESET = FlxG.keys.anyJustPressed(controlMap.get('reset'));

		CHEAT = FlxG.keys.anyJustPressed(controlMap.get('cheat'));
	}
}