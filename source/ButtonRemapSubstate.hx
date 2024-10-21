package;

import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.FlxSubState;

class ButtonRemapSubstate extends MusicBeatSubstate
{
	var realCam:FlxCamera;

	var curSelected:Int = 0;

	public function new() {
		realCam = new FlxCamera(Math.round(FlxG.width / 4), Math.round(FlxG.height / 4), Math.round(FlxG.width / 2), Math.round(FlxG.height / 2));

		FlxG.cameras.add(realCam, false);
		
		this.camera = realCam;

		super();

		var magenta:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		magenta.scale.set(0.5, 0.5);
		magenta.updateHitbox();
		magenta.setPosition();
		magenta.color = 0xFFfd719b;
		add(magenta);
	}

	override public function update(elapsed:Float){
		super.update(elapsed);

		if (controls.BACK)
			close();

		if (controls.LEFT_P || controls.RIGHT_P || controls.UP_P || controls.DOWN_P) {
			if ((controls.LEFT_P || controls.UP_P) && curSelected > 0)
				--curSelected;
			else if ((controls.RIGHT_P || controls.DOWN_P) && curSelected < 3)
				++curSelected;
		}
	}

	override public function close(){
		FlxG.cameras.remove(realCam);
		FlxG.sound.play(Paths.getSound("cancelMenu"));

		super.close();
	}
}
