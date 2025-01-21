package;

import engine.Styles.StyleHandler;
import engine.Paths;
import engine.Conductor;
import flixel.math.FlxRandom;
import engine.Options;
import flixel.util.FlxTimer;
import sys.thread.Condition;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.ArrowStrums;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import objects.Note;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;

class LatencySubstate extends MusicBeatSubstate
{
	var offsetText:FlxText;
	var noteGrp:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	var strumLine:ArrowStrums;

	var funnyCam:FlxCamera;

	var funnyPresses:Bool = false;

	override public function new()
	{
		funnyCam = new FlxCamera();
		funnyCam.bgColor = FlxColor.TRANSPARENT;

		FlxG.cameras.add(funnyCam, false);

		this.camera = funnyCam;

		strumLine = new ArrowStrums(0, 5, StyleHandler.handler);

		super();

		restartMusic();

		strumLine.screenCenter(X);
		add(strumLine);

		add(noteGrp);

		offsetText = new FlxText(0, 0, FlxG.width);
		offsetText.y = (FlxG.height - 48) - 16;
		offsetText.setFormat(null, 24, FlxColor.WHITE, CENTER);
		add(offsetText);
	}

	var doinShit:Bool = false;
	function restartMusic()
	{
		Conductor.changeBPM(120);
		Conductor.songPosition = Conductor.offset * -1;

		var play:Bool = true;
		doinShit = true;

		if (noteGrp.members.length == 0) {
			for (i in 0...32) {
				var note:Note = new Note(Conductor.crochet * i, FlxG.random.int(0, 3), StyleHandler.handler);
				note.mustPress = true;
				note.visible = true;
				note.alpha = 0;
				noteGrp.add(note);

				FlxTween.tween(note, {alpha: 1}, 0.15);
			}
		}
		else {
			play = false;
			FlxG.sound.play(Paths.getSound('rewind'));

			for (note in noteGrp.members) {
				note.visible = true;
				FlxTween.tween(note, {y: noteCalc(note)}, 1.5, {ease: FlxEase.circInOut, onComplete: function(v){
					note.tooLate = false;
					FlxTween.tween(note, {alpha: 1}, 1);
				}});
			}

			new FlxTimer().start(2.5, function(v){
				FlxG.sound.playMusic('assets/music/soundTest' + TitleState.soundExt, false);
				doinShit = false;
			});
		}

		if (play) {
			FlxG.sound.playMusic('assets/music/soundTest' + TitleState.soundExt, false);
			doinShit = false;
		}
	}
	
	override function update(elapsed:Float)
	{
		if (!FlxG.sound.music.playing && !doinShit)
			restartMusic();

		super.update(elapsed);

		offsetText.text = "Offset: " + Conductor.offset + "ms. Hold down \"ALT\" to change values.\nWarning: High/Low enough offsets may make the game unstable.";

		Conductor.songPosition = FlxG.sound.music.time - Conductor.offset;

		if (FlxG.keys.pressed.ALT) {
			var multiply:Float = 1;
			if (FlxG.keys.pressed.SHIFT)
				multiply = 5;
			else
				multiply = 1;

			if (controls.RIGHT_P)
				Conductor.offset += 1 * multiply;
			if (controls.LEFT_P)
				Conductor.offset -= 1 * multiply;

			if (Conductor.offset > 2500)
				Conductor.offset = 2500
			else if (Conductor.offset < -2500)
				Conductor.offset = -2500;

			FlxG.save.data.latency = Conductor.offset;
			Options.checkOptions();
			Options.save();
		}

		if (controls.BACK)
			close();

		for (strum in strumLine.strums) {
			if (strum.animation.curAnim.finished)
				strumLine.playAnim(strum.ID, 'static');
		}

		var controls:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
		for (i in 0...4) {
			if (!FlxG.keys.pressed.ALT && controls[i] == true) {
				strumLine.playAnim(i, 'pressed');
				funnyPresses = true;
			}
		}

		noteGrp.forEach(function(daNote:Note)
		{
			if (FlxG.sound.music.playing) {
				daNote.y = noteCalc(daNote);
				daNote.x = strumLine.strums[daNote.noteData].x;
	
				if (daNote.visible && daNote.canBeHit && (funnyPresses && (!FlxG.keys.pressed.ALT && controls[daNote.noteData] == true) || !funnyPresses && Conductor.songPosition >= daNote.strumTime)) {
					strumLine.playAnim(daNote.noteData, 'confirm');
					daNote.visible = false;
				}
			}
		});
	}

	function noteCalc(daNote:Note):Float
	{
		return (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45));
	}

	override function close()
	{
		super.close();

		if (Type.getClass(FlxG.state) != PlayState) {
			FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);
			Conductor.changeBPM(102);
		}
		else
			FlxG.sound.music.stop();
	}
}
