package;

import engine.Styles.StyleHandler;
import objects.Note;
import objects.ArrowStrums;
import Alphabet.AlphaCharacter;
import flixel.math.FlxRandom;
import flixel.input.keyboard.FlxKeyList;
import flixel.input.keyboard.FlxKey;
import engine.Options;
import flixel.group.FlxGroup.FlxTypedGroup;
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

	var notes:ArrowStrums;
	var letters:FlxTypedGroup<AlphaCharacter> = new FlxTypedGroup(4);

	var hitAKey:Alphabet;

	public function new() {
		realCam = new FlxCamera(Math.round(FlxG.width / 4), Math.round(FlxG.height / 4), Math.round(FlxG.width / 2), Math.round(FlxG.height / 2));
		realCam.bgColor =  FlxColor.TRANSPARENT;

		FlxG.cameras.add(realCam, false);
		
		this.camera = realCam;

		super();

		/*var magenta:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		magenta.scale.set(0.5, 0.5);
		magenta.updateHitbox();
		magenta.setPosition();
		magenta.color = 0xFFfd719b;
		magenta.alpha = 0.7;
		add(magenta);*/

		if (StyleHandler.styles.get('default') != StyleHandler.curStyle)
			StyleHandler.curStyle = StyleHandler.styles.get('default');

		notes = new ArrowStrums(Note.swagWidth / 1.2, (realCam.height / 2) - Note.swagWidth / 2);
		add(notes);

		for (i in 0...4) {
			var letter:AlphaCharacter = new AlphaCharacter(0, 0);
			letter.setPosition(notes.strums[i].x + 30, notes.strums[i].y - 69); // 69 nice
			letters.add(letter);
		}

		add(letters);

		hitAKey = new Alphabet(0, 0, "Press Any Key", true, false, -24);
		hitAKey.scale.set(0.5, 0.5);
		hitAKey.updateHitbox();

		hitAKey.x = (realCam.width / 2) - 360; // screenCenter() fucking HATES ME bro
		hitAKey.y = (realCam.height - hitAKey.height) - 64;

		hitAKey.visible = false;
		add(hitAKey);

		updateNotes();
		updateLetters();
	}

	var settingKeybind:Bool = false;
	final acceptableInputs:Array<FlxKey> = [Q, W, E, R, T, Y, U, I, O, P, A, S, D, F, G, H, J, K, L, Z, X, C, V, B, N, M]; // I'm dumb

	override public function update(elapsed:Float){	
		super.update(elapsed);

		if ((controls.LEFT_P || controls.RIGHT_P || controls.UP_P || controls.DOWN_P) && !settingKeybind) {
			if ((controls.LEFT_P || controls.UP_P) && curSelected > 0)
				--curSelected;
			else if ((controls.RIGHT_P || controls.DOWN_P) && curSelected < 3)
				++curSelected;
			else {
				var rand:Float = new FlxRandom().int(1, 3);
				FlxG.sound.play(Paths.getSound("badnoise" + rand));
			}

			updateNotes();
		}

		if (controls.BACK)
			close();
		else if (controls.ACCEPT && !settingKeybind) {
			FlxG.sound.play(Paths.getSound("clickText"));

			settingKeybind = true;
			updateNotes();
		}
		else if (settingKeybind) {
			if (notes.strums[curSelected].animation.curAnim.name != "confirm")
				notes.playAnim(curSelected, 'confirm');

			hitAKey.visible = true;

			var pressed:FlxKey = FlxG.keys.firstJustPressed();
			if (pressed.toString() != null && acceptableInputs.contains(pressed)){
				Options.controlScheme[curSelected].key = pressed;

				settingKeybind = false;
				updateNotes();
				updateLetters();

				FlxG.sound.play(Paths.getSound("confirmMenu"));

				Controls.init();
				Options.save();

				hitAKey.visible = false;
			}
			else if (pressed.toString() != null && !acceptableInputs.contains(pressed)){
				var rand:Float = new FlxRandom().int(1, 3);
				FlxG.sound.play(Paths.getSound("badnoise" + rand));
			}
		}
	}

	function updateNotes()
	{
		for (i in 0...notes.members.length)
		{
			if (i == curSelected)
				notes.playAnim(i, 'pressed');
			else
				notes.playAnim(i, 'static');

			if (notes.members[i].animation.curAnim.name == 'confirm' && notes.members[i].animation.curAnim.finished)
				notes.playAnim(i, 'static');
		}
	}
	
	function updateLetters()
	{
		for (i in 0...letters.members.length)
			letters.members[i].createBold(Options.controlScheme[i].key.toString().toUpperCase());
	}

	override public function close(){
		FlxG.cameras.remove(realCam);
		FlxG.sound.play(Paths.getSound("cancelMenu"));

		super.close();
	}
}
