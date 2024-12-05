package objects;

import flixel.tweens.FlxTween;
import engine.Styles.StyleData;
import engine.Styles.LocalStyle;
import engine.Options;
import engine.Conductor;
import engine.Styles.StyleHandler;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

using StringTools;

class Note extends FlxSprite
{
	public static var swagWidth:Float = 160 * 0.7;

	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public var altAnimation:Bool = false;

	public var noteScore:Float = 1;

	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var xOffset:Float = 0;
	public var yOffset:Float = 0;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, styleHandler:LocalStyle)
	{
		super();

		visible = false;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		this.strumTime = strumTime;

		this.noteData = noteData;

		var style:StyleData = null;
		frames = styleHandler.giveMeNotes();
		style = styleHandler.curStyle;

		for (anim in style.noteAnimations){
			if (anim != null) {
				var idleFPS:Int = 24;
				var holdFPS:Int = 24;
				var holdendsFPS:Int = 24;

				if (anim.idle.fps != null)
					idleFPS = anim.idle.fps;
				if (anim.holding.fps != null)
					holdFPS = anim.holding.fps;
				if (anim.holdends.fps != null)
					holdendsFPS = anim.holdends.fps;

				switch (anim.direction) {
					default:
						animation.addByPrefix('purpleScroll', anim.idle.prefix, idleFPS);
						animation.addByPrefix('purplehold', anim.holding.prefix, holdFPS);
						animation.addByPrefix('purpleholdend', anim.holdends.prefix, holdendsFPS);
					case 1:
						animation.addByPrefix('blueScroll', anim.idle.prefix, idleFPS);
						animation.addByPrefix('bluehold', anim.holding.prefix, holdFPS);
						animation.addByPrefix('blueholdend', anim.holdends.prefix, holdendsFPS);
					case 2:
						animation.addByPrefix('greenScroll', anim.idle.prefix, idleFPS);
						animation.addByPrefix('greenhold', anim.holding.prefix, holdFPS);
						animation.addByPrefix('greenholdend', anim.holdends.prefix, holdendsFPS);
					case 3:
						animation.addByPrefix('redScroll', anim.idle.prefix, idleFPS);
						animation.addByPrefix('redhold', anim.holding.prefix, holdFPS);
						animation.addByPrefix('redholdend', anim.holdends.prefix, holdendsFPS);
				}	
			}
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
		antialiasing = style.antialiasing;

		switch (noteData)
		{
			case 0:
				animation.play('purpleScroll');
			case 1:
				animation.play('blueScroll');
			case 2:
				animation.play('greenScroll');
			case 3:
				animation.play('redScroll');
		}

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			noteScore * 0.2;
			alpha = 0.6;

			switch (noteData)
			{
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
				case 1:
					animation.play('blueholdend');
				case 0:
					animation.play('purpleholdend');
			}

			updateHitbox();
			
			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.curSong.speed;
				prevNote.updateHitbox();
			}

			yOffset = -10;
			xOffset = (swagWidth / 2) - (width / 2);
			if (Options.get("downscroll") == true) {
				flipY = !flipY;
			}
		}
	}

	public var noteOnTime:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
			&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.75)) // funni
		{
			canBeHit = true;
		}
		else
			canBeHit = false;

		if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset)
			tooLate = true;

		if (!noteOnTime && strumTime <= Conductor.songPosition) {
			noteOnTime = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}