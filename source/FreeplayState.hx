package;

import flixel.group.FlxSpriteGroup;
import engine.editors.ChartingState;
import engine.HelpfulAPI;
import engine.Song;
import engine.Highscore;
import objects.HealthIcon;
import engine.CoolUtil;
import objects.Counter;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import objects.Alphabet;
import engine.Paths;
import flixel.math.FlxRandom;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<Array<String>> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var scoreCounter:Counter;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;

	private var curPlaying:Bool = false;

	override function create()
	{
		var temp = CoolUtil.coolTextFile('assets/data/freeplaySonglist.txt');
		for (song in temp)
			songs.push(song.split(':'));

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);
			}
		 */

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);

		var backBG:FlxSprite = new FlxSprite();
		// add(backBG);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i][0], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var songIcon:HealthIcon = new HealthIcon(songs[i][1], false);
			songIcon.target = songText;
			grpIcons.add(songIcon);
		}

		/*scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat("assets/fonts/vcr.ttf", 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;*/

		var highscoreText:FlxText = new FlxText();
		highscoreText.setFormat(null, 24, FlxColor.WHITE, LEFT);
		highscoreText.text = "Highscore: ";

		scoreCounter = new Counter(0, 16, 12, 0.25);

		scoreCounter.x += highscoreText.width;
		highscoreText.y = scoreCounter.y;
		
		var scoreShit:FlxSpriteGroup = new FlxSpriteGroup();
		scoreShit.add(scoreCounter);
		scoreShit.add(highscoreText);

		scoreShit.screenCenter(X);

		diffText = new FlxText(0, 0, 512, "", 24);
		diffText.setFormat("assets/fonts/vcr.ttf", 32, FlxColor.WHITE, CENTER);
		diffText.screenCenter(X);
		diffText.y = scoreCounter.y + scoreCounter.height + 8;
		diffText.antialiasing = false;
		add(diffText);

		// add(scoreText);

		/*add(highscoreText);
		add(scoreCounter);*/

		add(scoreShit);

		backBG.makeGraphic(Math.floor(scoreCounter.width), Math.floor(scoreCounter.height + diffText.height + 32), FlxColor.BLACK);
		backBG.screenCenter(X);
		backBG.alpha = 0.7;

		changeSelection();
		changeDiff();

		super.create();

		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (scoreCounter.count != lerpScore)
			scoreCounter.set(lerpScore);

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			/*var poop:String = Highscore.formatSong(songs[curSelected][0].toLowerCase(), curDifficulty);

			trace(poop);*/

			try {
				HelpfulAPI.playSong(songs[curSelected][0], HelpfulAPI.getDifficultyFromIndex(curDifficulty));
			}
			catch (e:Dynamic) {
				trace('Error loading song: $e');

				var rand:Float = new FlxRandom().int(1, 3);
				FlxG.sound.play(Paths.getSound("badnoise" + rand));
			}
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		intendedScore = Highscore.getScore(songs[curSelected][0], HelpfulAPI.getDifficultyFromIndex(curDifficulty));

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "EASY";
			case 1:
				diffText.text = 'NORMAL';
			case 2:
				diffText.text = "HARD";
		}

		diffText.text = '< ${diffText.text} >';
	}

	function changeSelection(change:Int = 0)
	{
		// NGio.logEvent('Fresh');
		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		intendedScore = Highscore.getScore(songs[curSelected][0], HelpfulAPI.getDifficultyFromIndex(curDifficulty));

		var bullShit:Int = 0;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}
