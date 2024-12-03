package;

import engine.editors.CharacterEditor;
import engine.editors.ChartingState;
import flixel.ui.FlxBar;
import flixel.group.FlxGroup;
import objects.Boyfriend;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxObject;
import flixel.math.FlxRect;
import engine.Options;
import flixel.util.FlxTimer;
import flixel.util.FlxSort;
import engine.Paths;
import objects.Note;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.sound.FlxSound;
import objects.ArrowStrums;
import flixel.FlxSprite;
import engine.Styles.StyleHandler;
import engine.Styles.LocalStyle;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import engine.Conductor;
import objects.Character;
import objects.Boyfriend;
import engine.Section.SwagSection;
import engine.Song;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var curSong:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:String = "normal";
    public static var campaignScore:Int = 0;

    public var curStage:String = "";

    public var curSection:Int = 0;
    public var curSectionData:SwagSection;

    private var bfVocals:FlxSound;
    private var opponentVocals:FlxSound;

    private var downscroll:Bool = false;
    private var middlescroll:Bool = false; // Not actually going to be used

    private var ghost_tapping:Bool = false;

    private var playerStrums:ArrowStrums;
    private var opponentStrums:ArrowStrums;

    private var notes:FlxTypedGroup<Note>;
    
    private var style:LocalStyle;

    private var bf:Boyfriend;
    private var dad:Character;
    private var gf:Character;

    private var camFollow:FlxObject = new FlxObject();

    private var camGame:FlxCamera;
    private var camHUD:FlxCamera;

    private var defaultZoom:Float = 0.9;

    private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

    // scoring shit
    private var songScore:Int = 0;
    
    private var combo:Int = 0;

    private var sicks:Int = 0;
    private var goods:Int = 0;
    private var bads:Int = 0;
    private var shits:Int = 0;

    private var health:Float = 1;

    // layering shit
    private var popUpSprites:FlxGroup;

    // debug stuff
    private var botplay:Bool = false;

    override public function create()
    {
        persistentUpdate = false;
        persistentDraw = true;

        Conductor.songPosition = -5000;

        Conductor.changeBPM(curSong.bpm);
        Conductor.mapBPMChanges(curSong);

        camGame = new FlxCamera();
        camHUD = new FlxCamera();
        camHUD.bgColor = FlxColor.TRANSPARENT;

        FlxG.cameras.add(camGame, true);
        FlxG.cameras.add(camHUD, false);

        camGame.follow(camFollow, LOCKON, 0.07);

        downscroll = Options.get("downscroll");
        ghost_tapping = Options.get("ghostTapping");

        style = new LocalStyle(StyleHandler.styles.get("default"));
        if (curSong.visualStyle != null)
            style.setStyle(curSong.visualStyle);

        if (curSong.curStage != null)
            curStage = curSong.curStage;

        switch (curStage.toLowerCase()) {
            default:
                defaultZoom = 0.5;

                var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/stageback.png');
                bg.antialiasing = true;
                bg.scrollFactor.set(0.9, 0.9);
                bg.active = false;
                add(bg);
        
                var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/stagefront.png');
                stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
                stageFront.updateHitbox();
                stageFront.antialiasing = true;
                stageFront.scrollFactor.set(0.9, 0.9);
                stageFront.active = false;
                add(stageFront);
        
                var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic('assets/images/stagecurtains.png');
                stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
                stageCurtains.updateHitbox();
                stageCurtains.antialiasing = true;
                stageCurtains.scrollFactor.set(1.3, 1.3);
                stageCurtains.active = false;
                add(stageCurtains);
        }

        gf = new Character(400, 130, curSong.girlfriend);
        add(gf);

        bf = new Boyfriend(770, 450, curSong.player1);
        add(bf);

        dad = new Character(100, 100, curSong.player2);
        add(dad);

        opponentStrums = new ArrowStrums(Note.swagWidth / 2, Note.swagWidth / 4, style);
        opponentStrums.camera = camHUD;
        add(opponentStrums);

        playerStrums = new ArrowStrums((FlxG.width - (Note.swagWidth * 4)) - Note.swagWidth / 2, Note.swagWidth / 4, style);
        playerStrums.camera = camHUD;
        add(playerStrums);

        if (downscroll)
            playerStrums.y = opponentStrums.y = FlxG.height - (Note.swagWidth / 4);
        
        if (middlescroll) {
            opponentStrums.visible = false;
            playerStrums.screenCenter(X);
        }

        notes = new FlxTypedGroup();
        notes.camera = camHUD;
        add(notes);

        var hbY:Float = FlxG.height * 0.9;
		if (downscroll)
			hbY = FlxG.height * 0.1;

        popUpSprites = new FlxGroup();
        popUpSprites.camera = camHUD;
        add(popUpSprites);

        healthBarBG = new FlxSprite(0, hbY).loadGraphic(style.getImage('${style.curStyle.uiDirectoryPath}/healthBar'));
		healthBarBG.screenCenter(X);
        healthBarBG.camera = camHUD;
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
        healthBar.camera = camHUD;
		add(healthBar);

        generateSong();

        super.create();

        startCountdown();
    }

    var songGenerated:Bool = false;
    function generateSong()
    {
        FlxG.sound.music.loadEmbedded(Paths.getSong(curSong.song.toLowerCase(), "Inst"), false);
        FlxG.sound.music.onComplete = endSong;

        bfVocals = new FlxSound().loadEmbedded(Paths.getSong(curSong.song.toLowerCase(), "Player-Voices"));
        FlxG.sound.list.add(bfVocals);

        opponentVocals = new FlxSound().loadEmbedded(Paths.getSong(curSong.song.toLowerCase(), "Opponent-Voices"));
        FlxG.sound.list.add(opponentVocals);

        var prevNote:Note = null;
        for (i in 0...curSong.notes.length) {
            var section:SwagSection = curSong.notes[i]; 

            var daSecNotes:Array<Note> = [];

            for (note in section.sectionNotes) {
                var noteDirection:Int = Std.int(note.noteData % 4);
                var gottaHitNote:Bool = section.mustHitSection;
				if (note.noteData > 3)
					gottaHitNote = !section.mustHitSection;

                var daNote:Note = new Note(note.strumTime, noteDirection, prevNote, false, style);
                daNote.visible = false;
                daNote.active = false; 

                daNote.sustainLength = note.sustainLength;
                daNote.altAnimation = note.altAnimation;
                daNote.mustPress = gottaHitNote;

                daSecNotes.push(daNote);
                
                var prevSustain:Note = daNote;
                for (sus in 0...Math.floor(note.sustainLength / Conductor.stepCrochet)) { // ඞ amogus
                    var sustain:Note = new Note(note.strumTime + (Conductor.stepCrochet * sus) + Conductor.stepCrochet, 
                        noteDirection, prevSustain, true, style);

                    sustain.altAnimation = note.altAnimation;
                    sustain.mustPress = gottaHitNote;

                    sustain.visible = false;
                    sustain.active = false;
                
                    daSecNotes.push(sustain);
                    prevSustain = sustain;
                }
            }

            daSecNotes.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime));

            for (note in daSecNotes)
                notes.add(note);
        }

        notes.members.sort((a, b) -> b.isSustainNote ? (a.isSustainNote ? 0 : 1) : (a.isSustainNote ? -1 : 0));
        curSectionData = curSong.notes[0];

        songGenerated = true;
    }

    var songStarted:Bool = false;
    function startCountdown()
    {
        var maxIterations:Int = 4;
        
        Conductor.songPosition = 0; // reset dat shit
        Conductor.songPosition = -((Conductor.crochet * maxIterations) + Conductor.offset);

        var iteration:Int = 0;
        new FlxTimer().start(Conductor.crochet / 1000, (timer) -> {
            bf.dance();
            dad.dance();
            gf.dance();

            switch (iteration) {
                case 0:
                    FlxG.sound.play(Paths.getSound("intro3"), 0.7);
                case 1:
                    FlxG.sound.play(Paths.getSound("intro2"), 0.7);
                case 2:
                    FlxG.sound.play(Paths.getSound("intro1"), 0.7);
                case 3:
                    FlxG.sound.play(Paths.getSound("introGo"), 0.7);
            }

            if (iteration <= maxIterations) {
                ++iteration;

                timer.reset(Conductor.crochet / 1000);
            }
        });
    }

    function startSong() {
        resyncVocals();

        songStarted = true;
    }

    function endSong()
    {
        FlxG.switchState(new FreeplayState());
    }

    var paused:Bool = false;
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (!paused) {
            if (songGenerated) {
                if (!curSectionData.mustHitSection)
                    camFollow.setPosition(dad.getMidpoint().x + dad.camOffsets[0], dad.getMidpoint().y + dad.camOffsets[1]);
                else
                    camFollow.setPosition(bf.getMidpoint().x + bf.camOffsets[0], bf.getMidpoint().y + bf.camOffsets[1]);

                if (songStarted) {
                    if (Conductor.lastSongPos != Conductor.songPosition)
                        Conductor.lastSongPos = Conductor.songPosition;
            
                    Conductor.songPosition += FlxG.elapsed * 1000;

                    for (strum in opponentStrums.strums) {
                        if (strum.animation.finished)
                            opponentStrums.playAnim(strum.ID, "static");
                    }

                    if (botplay) {
                        for (strum in playerStrums.strums) {
                            if (strum.animation.finished)
                                playerStrums.playAnim(strum.ID, "static");
                        }
                    }
                    else {
                        keyShit();
                    }
                }
                else {
                    Conductor.songPosition += FlxG.elapsed * 1000;

                    if (Conductor.songPosition >= 0 + Conductor.offset)
                        startSong();
                }

                notes.forEachAlive((daNote:Note)->{
                    var strumLine:ArrowStrums = null;
                    switch(daNote.mustPress) {
                        case false:
                            strumLine = opponentStrums;
                        case true:
                            strumLine = playerStrums;
                    }

                    if (downscroll)
                        daNote.y = (strumLine.strums[daNote.noteData].y + (Conductor.songPosition - daNote.strumTime) * (0.45 * curSong.speed)) + daNote.yOffset;
                    else
                        daNote.y = (strumLine.strums[daNote.noteData].y - (Conductor.songPosition - daNote.strumTime) * (0.45 * curSong.speed)) + daNote.yOffset;

                    daNote.x = strumLine.strums[daNote.noteData].x + daNote.xOffset;
        
                    if (!downscroll && daNote.y <= FlxG.height || downscroll && daNote.y >= FlxG.height) {
                        daNote.visible = strumLine.visible;
                        daNote.active = true;

                        if (songStarted) {
                            var strumLineMid:Float = strumLine.y + (Note.swagWidth / 2);

                            if (downscroll) {
                                if (daNote.isSustainNote)
                                {
                                    if (daNote.animation.curAnim.name.endsWith("end") && daNote.prevNote != null)
                                        daNote.y += daNote.prevNote.height;
                                    else
                                        daNote.y += daNote.height / 2;
            
                                    if ((!daNote.mustPress || botplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
                                        && daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= strumLineMid)
                                    {
                                        var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
                
                                        swagRect.height = (strumLineMid - daNote.y) / daNote.scale.y;
                                        swagRect.y = daNote.frameHeight - swagRect.height;
                                        daNote.clipRect = swagRect;
                                    }
                                }
                            }
                            else {
                                if (daNote.isSustainNote
                                    && (!daNote.mustPress || botplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
                                    && daNote.y + daNote.offset.y * daNote.scale.y <= strumLineMid)
                                {
                                    var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
            
                                    swagRect.y = (strumLineMid - daNote.y) / daNote.scale.y;
                                    swagRect.height -= swagRect.y;
                                    daNote.clipRect = swagRect;
                                }
                            }

                            if (!daNote.mustPress && daNote.noteOnTime)
                                goodNoteHit(daNote);

                            if (botplay && daNote.mustPress && daNote.noteOnTime)
                                goodNoteHit(daNote);
                            
                            if (daNote.mustPress && daNote.tooLate && !daNote.wasGoodHit) {
                                if (!daNote.isSustainNote) {
                                    noteMiss(daNote.noteData);
                                }
                                else {
                                    combo = 0;
                                    songScore -= 10;
                                    health -= 0.004;
                                }

                                daNote.kill();
                                notes.remove(daNote);
                                daNote.destroy();
                            }
                            else if (daNote.tooLate) {
                                daNote.kill();
                                notes.remove(daNote);
                                daNote.destroy();
                            }
                        }
                    }
                });
            }
        }

        #if debug
        if (FlxG.keys.justPressed.SEVEN)
            FlxG.switchState(new ChartingState(curSong, curSection));
        else if (FlxG.keys.justPressed.EIGHT)
            FlxG.switchState(new CharacterEditor(curSong.player1));
        else if (FlxG.keys.justPressed.TAB)
            botplay = !botplay;
        #end
    }

    function popUpScore(direction:Int, strumTime:Float)
    {

    }

    // Literally just copy and pasted from the old PlayState...
    // If it ain't broken, don't fix it!
    private function keyShit():Void
	{
		// HOLDING
		var up = controls.UP;
		var right = controls.RIGHT;
		var down = controls.DOWN;
		var left = controls.LEFT;

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var upR = controls.UP_R;
		var rightR = controls.RIGHT_R;
		var downR = controls.DOWN_R;
		var leftR = controls.LEFT_R;

		var pressedArray:Array<Bool> = [leftP, downP, upP, rightP];

		for (i in 0...pressedArray.length)
		{
			if (bf.stunned || !songGenerated)
				break;

			if (pressedArray[i] == true) {
				var pressed:Bool = pressedArray[i];

				var possibleNotes:Array<Note> = [];
	
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.active && daNote.noteData == i && daNote.mustPress && daNote.canBeHit && !daNote.isSustainNote && !daNote.tooLate)
					{
						possibleNotes.push(daNote);
						possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
					}
				});

				if (possibleNotes.length > 0)
				{
					var daNote = possibleNotes[0];

					// Jump notes
					if (possibleNotes.length >= 2)
					{
						if (possibleNotes[0].strumTime == possibleNotes[1].strumTime)
						{
							for (coolNote in possibleNotes)
							{
								goodNoteHit(coolNote);
							}
						}
						else if (possibleNotes[0].noteData == possibleNotes[1].noteData) // check if the player hits between two notes
						{
							noteCheck(pressed, daNote);
						}
						else
						{
							for (coolNote in possibleNotes)
							{
								noteCheck(pressed, coolNote);
							}
						}
					}
					else // regular notes?
					{
						noteCheck(pressed, daNote);
					}
					if (daNote.wasGoodHit)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
				else if (Options.get("ghostTapping") != true)
				{
					noteMiss(i);
				}
			}
		}

		// Sustain Notes (doesn't really matter as much)
		if ((up || right || down || left) && !bf.stunned && songGenerated)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
				{
					switch (daNote.noteData)
					{
						// NOTES YOU ARE HOLDING
						case 0:
							if (left)
								goodNoteHit(daNote);
						case 1:
							if (down)
								goodNoteHit(daNote);
						case 2:
							if (up)
								goodNoteHit(daNote);
						case 3:
							if (right)
								goodNoteHit(daNote);
					}
				}
			});
		}

		for (spr in playerStrums.strums) {
			switch (spr.ID)
			{
				case 0:
					if (leftP && spr.animation.curAnim.name != 'confirm')
						playerStrums.playAnim(0, 'pressed', false);
					if (leftR)
						playerStrums.playAnim(0, 'static', false);
				case 1:
					if (downP && spr.animation.curAnim.name != 'confirm')
						playerStrums.playAnim(1, 'pressed', false);
					if (downR)
						playerStrums.playAnim(1, 'static', false);
				case 2:
					if (upP && spr.animation.curAnim.name != 'confirm')
						playerStrums.playAnim(2, 'pressed', false);
					if (upR)
						playerStrums.playAnim(2, 'static', false);
				case 3:
					if (rightP && spr.animation.curAnim.name != 'confirm')
						playerStrums.playAnim(3, 'pressed', false);
					if (rightR)
						playerStrums.playAnim(3, 'static', false);
			}
		}
	}

	function noteMiss(direction:Int = 1):Void
	{
		if (!bf.stunned)
		{
			health -= 0.04;
			if (combo > 5)
			{
				gf.playAnim('sad');
			}
			combo = 0;

			songScore -= 10;

			FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + TitleState.soundExt, FlxG.random.float(0.1, 0.2));

			bf.stunned = true;

			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				bf.stunned = false;
			});

			switch (direction)
			{
				case 0:
					bf.playAnim('singLEFTmiss', true);
				case 1:
					bf.playAnim('singDOWNmiss', true);
				case 2:
					bf.playAnim('singUPmiss', true);
				case 3:
					bf.playAnim('singRIGHTmiss', true);
			}
		}
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		if (keyP)
			goodNoteHit(note);
		else
			noteMiss(note.noteData);
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{	
			note.wasGoodHit = true;
			
			var altStr:String = "";
			if (note.altAnimation)
				altStr = '-alt';
			
			if (note.mustPress) {
                bfVocals.volume = 1;

				if (!note.isSustainNote)
				{
					health += 0.023;
		
					// popUpScore(note.noteData, note.strumTime);
					combo += 1;
				}
				else {
					health += 0.004;
				}

				switch (note.noteData)
				{
					case 0:
						bf.playAnim('singLEFT' + altStr, true);
					case 1:
						bf.playAnim('singDOWN' + altStr, true);
					case 2:
						bf.playAnim('singUP' + altStr, true);
					case 3:
						bf.playAnim('singRIGHT' + altStr, true);
				}
		
				playerStrums.playAnim(note.noteData, 'confirm');
			}
			else {
                if (opponentVocals != null && opponentVocals.playing)
                    opponentVocals.volume = 1;
                else
                    bfVocals.volume = 1; // assume that it's a single tracked song

				switch (note.noteData)
				{
					case 0:
						dad.playAnim('singLEFT' + altStr, true);
					case 1:
						dad.playAnim('singDOWN' + altStr, true);
					case 2:
						dad.playAnim('singUP' + altStr, true);
					case 3:
						dad.playAnim('singRIGHT' + altStr, true);
				}

				dad.holdTimer = 0;

				opponentStrums.playAnim(note.noteData, 'confirm');
			}

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

    function resyncVocals():Void
	{
		FlxG.sound.music.play();
        bfVocals.play();
        opponentVocals.play();

		Conductor.songPosition = FlxG.sound.music.time - Conductor.offset;
        bfVocals.time = FlxG.sound.music.time;
        opponentVocals.time = FlxG.sound.music.time;
	}

    override function stepHit()
    {
        super.stepHit();

        if (curSong.needsVoices && FlxG.sound.music.time != FlxG.sound.music.length)
		{
            var daVocals:Array<FlxSound> = [bfVocals, opponentVocals];

            for (vocals in daVocals) {
                if (vocals != null && vocals.playing && (vocals.time - Conductor.offset > Conductor.songPosition + 20 || vocals.time - Conductor.offset < Conductor.songPosition - 20))
                {
                    resyncVocals();
                    break;
                }
            }
		}

        if (curSong.notes[curSection] != null && curStep % curSong.notes[curSection].lengthInSteps == 0) {
			++curSection;

			if (curSong.notes[curSection] != null)
                curSectionData = curSong.notes[curSection];
		}

        FlxG.watch.addQuick('curStep', curStep);
        FlxG.watch.addQuick('curBeat', curBeat);
		FlxG.watch.addQuick('curSection', curSection);
    }

    var gfSpeed:Int = 1;

    override function beatHit()
    {
        super.beatHit();

        if (curSectionData != null && curSectionData.changeBPM)
            Conductor.changeBPM(curSectionData.bpm);

        if (curBeat % gfSpeed == 0)
			gf.dance();

		if (!bf.dancing && bf.animation.curAnim.finished)
			bf.dance();

		if (!dad.dancing && dad.animation.curAnim.finished)
			dad.dance();
    }
}