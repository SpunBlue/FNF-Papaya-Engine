package;

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

	var notes:FlxTypedGroup<FlxSprite> = new FlxTypedGroup(4);
	var letters:FlxTypedGroup<AlphaCharacter> = new FlxTypedGroup(4);

	var hitAKey:Alphabet;

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
		magenta.alpha = 0.7;
		add(magenta);

		add(notes);
		add(letters);

		hitAKey = new Alphabet(0, 0, "Press Any Key", true, false, -24);
		hitAKey.scale.set(0.5, 0.5);
		hitAKey.updateHitbox();

		hitAKey.x = (realCam.width / 2) - 360; // screenCenter() fucking HATES ME bro
		hitAKey.y = (realCam.height - hitAKey.height) - 32;

		hitAKey.visible = false;
		add(hitAKey);

		// doesn't work if i do 0...3 depite 0 - 3 being 4??? maybe I'm just dumb
		for (i in 0...4) {
			var babyArrow:FlxSprite = new FlxSprite(Note.swagWidth / 1.2, (realCam.height / 2) - Note.swagWidth / 2);
			var letter:AlphaCharacter = new AlphaCharacter(0, 0);

			babyArrow.frames = Paths.getSparrow('NOTE_assets');

			babyArrow.antialiasing = true;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

			switch (i)
			{
				case 0:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			letter.setPosition(babyArrow.x + 36, babyArrow.y + 32);

			babyArrow.animation.play('static');
			notes.add(babyArrow);
			letters.add(letter);
		}

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
			// I'll reimplement this once I rewrite the strumline code
			/*if (notes.members[curSelected].animation.curAnim.name != "confirm") {
				var note = notes.members[curSelected];
				note.animation.play('confirm');
			}*/

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
				notes.members[i].animation.play('pressed');
			else
				notes.members[i].animation.play('static');

			if (notes.members[i].animation.curAnim.name == 'confirm' && notes.members[i].animation.curAnim.finished)
				notes.members[i].animation.play('pressed');
		}
	}
	
	function updateLetters()
	{
		for (i in 0...letters.members.length)
			letters.members[i].createLetter(Options.controlScheme[i].key.toString());
	}

	override public function close(){
		FlxG.cameras.remove(realCam);
		FlxG.sound.play(Paths.getSound("cancelMenu"));

		super.close();
	}
}
