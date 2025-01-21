package;

import flixel.math.FlxMath;
import flixel.FlxCamera;
import engine.Conductor;
import objects.Boyfriend;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var camFollow:FlxObject;
	
	var deadCam:FlxCamera = new FlxCamera();

	public function new(x:Float, y:Float)
	{
		var daBf:String = PlayState.curSong.player1;

		super();

		FlxG.cameras.add(deadCam, true);

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, daBf);
		if (!bf.animation.exists('firstDeath'))
			bf = new Boyfriend(x, y, 'bf');
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		FlxG.sound.play('assets/sounds/fnf_loss_sfx' + TitleState.soundExt);
		Conductor.changeBPM(100);

		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			deadCam.follow(camFollow, LOCKON, 0.01);
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			FlxG.sound.playMusic('assets/music/gameOver' + TitleState.soundExt);
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play('assets/music/gameOverEnd' + TitleState.soundExt);
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				deadCam.fade(FlxColor.BLACK, 2, false, function()
				{
					FlxG.switchState(new PlayState());
				});
			});
		}
	}
}
