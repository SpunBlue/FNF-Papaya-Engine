package;

import flixel.group.FlxSpriteGroup;
import engine.HelpfulAPI;
import flixel.addons.transition.FlxTransitionableState;
import engine.Highscore;
import flixel.math.FlxMath;
import objects.HealthIcon;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.NoteSplash;
import flixel.text.FlxText;
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
    public static var chartingMode:Bool = false;

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
    private var splashes:FlxTypedGroup<NoteSplash>;
    
    private var style:LocalStyle;

    private var bf:Boyfriend;
    private var dad:Character;
    private var gf:Character;

    public static var camFollow:FlxObject;

    private var camGame:FlxCamera;
    private var camHUD:FlxCamera;

    private var defaultZoom:Float = 0.9;
    private var beatZooming:Bool = true;

    private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

    private var scoreTxt:FlxText;

    private var bfIcon:HealthIcon;
    private var opponentIcon:HealthIcon;

    // stage layering
    var stageBack:FlxSpriteGroup;
    var stageMiddle:FlxSpriteGroup;
    var stageFront:FlxSpriteGroup;

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
    private var botplay:Bool = false; // Botplay adds a bit more stress to the game from what I can tell, so be warned.

    override public function create()
    {
        persistentUpdate = persistentDraw = true;

        Conductor.songPosition = -5000;

        Conductor.changeBPM(curSong.bpm);
        Conductor.mapBPMChanges(curSong);

        camGame = new FlxCamera();
        camHUD = new FlxCamera();
        camHUD.bgColor = FlxColor.TRANSPARENT;

        FlxG.cameras.add(camGame, true);
        FlxG.cameras.add(camHUD, false);

        if (camFollow == null)
            camFollow = new FlxObject();
        else
            camGame.focusOn(camFollow.getMidpoint());

        camGame.follow(camFollow, LOCKON, 0.07);

        downscroll = Options.get("downscroll");
        ghost_tapping = Options.get("ghostTapping");

        style = new LocalStyle(StyleHandler.styles.get("default"));
        if (curSong.visualStyle != null)
            style.setStyle(curSong.visualStyle);

        camGame.zoom = defaultZoom;

        stageBack = new FlxSpriteGroup();
        stageBack.active = false;
        add(stageBack);

        gf = new Character(400, 130, curSong.girlfriend);
        add(gf);

        stageMiddle = new FlxSpriteGroup();
        stageMiddle.active = false;
        add(stageMiddle);

        bf = new Boyfriend(770, 450, curSong.player1);
        add(bf);

        dad = new Character(100, 100, curSong.player2);
        add(dad);
        if (curSong.player2 == curSong.girlfriend)
            dad.setPosition(gf.x, gf.y);

        stageFront = new FlxSpriteGroup();
        stageFront.active = false;
        add(stageFront);

        if (curSong.curStage != null)
            curStage = curSong.curStage;

        switch (curStage.toLowerCase()) {
            default:
                curStage = 'stage';
                defaultZoom = 0.9;

                var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/stageback.png');
                bg.antialiasing = true;
                bg.scrollFactor.set(0.9, 0.9);
                bg.active = false;
                stageBack.add(bg);
        
                var stage:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/stagefront.png');
                stage.setGraphicSize(Std.int(stage.width * 1.1));
                stage.updateHitbox();
                stage.antialiasing = true;
                stage.scrollFactor.set(0.9, 0.9);
                stage.active = false;
                stageBack.add(stage);
        
                var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic('assets/images/stagecurtains.png');
                stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
                stageCurtains.updateHitbox();
                stageCurtains.antialiasing = true;
                stageCurtains.scrollFactor.set(1.3, 1.3);
                stageCurtains.active = false;
                stageFront.add(stageCurtains);
        }

        opponentStrums = new ArrowStrums(Note.swagWidth / 2, Note.swagWidth / 4, style);
        opponentStrums.camera = camHUD;

        playerStrums = new ArrowStrums((FlxG.width - (Note.swagWidth * 4)) - Note.swagWidth / 2, Note.swagWidth / 4, style);
        playerStrums.camera = camHUD;
        
        if (downscroll)
            playerStrums.y = opponentStrums.y = (FlxG.height - Note.swagWidth) - (Note.swagWidth / 4);
        
        if (middlescroll) {
            opponentStrums.visible = false;
            playerStrums.x = (FlxG.width - (Note.swagWidth * 4)) / 2;
        }

        notes = new FlxTypedGroup();
        notes.camera = camHUD;

        splashes = new FlxTypedGroup();
        splashes.camera = camHUD;

        var hbY:Float = FlxG.height * 0.9;
		if (downscroll)
			hbY = 30;

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

        bfIcon = new HealthIcon(curSong.player1, true);
        bfIcon.setGraphicSize(80);
        bfIcon.updateHitbox();
        bfIcon.camera = camHUD;
        bfIcon.y = healthBar.y - (bfIcon.width / 2);
        add(bfIcon);

        opponentIcon = new HealthIcon(curSong.player2);
        opponentIcon.setGraphicSize(80);
        opponentIcon.updateHitbox();
        opponentIcon.camera = camHUD;
        opponentIcon.y = healthBar.y - (opponentIcon.width / 2);
        add(opponentIcon);

        scoreTxt = new FlxText(0, (hbY + healthBar.height) + 20, FlxG.width);
        scoreTxt.setFormat(null, 12, FlxColor.WHITE, CENTER, SHADOW, FlxColor.GRAY);
        scoreTxt.camera = camHUD;
        add(scoreTxt);

        add(opponentStrums);
        add(playerStrums);
        add(notes);
        add(splashes);

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
        Conductor.songPosition = -((Conductor.crochet * (maxIterations + 1)) + Conductor.offset);

        var countdown:FlxSprite = new FlxSprite();
        countdown.camera = camHUD;
        countdown.visible = false;
        countdown.loadGraphic(style.getImage('${style.curStyle.uiDirectoryPath}/ready'));
        countdown.screenCenter(XY);
        add(countdown);

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
                    countdown.visible = true;
                case 2:
                    FlxG.sound.play(Paths.getSound("intro1"), 0.7);
                    countdown.loadGraphic(style.getImage('${style.curStyle.uiDirectoryPath}/set'));
                    countdown.screenCenter(XY);
                case 3:
                    FlxG.sound.play(Paths.getSound("introGo"), 0.7);
                    countdown.loadGraphic(style.getImage('${style.curStyle.uiDirectoryPath}/go'));
                    countdown.screenCenter(XY);

                    countdown.acceleration.y = 550;
                    countdown.velocity.y = FlxG.random.int(-140, -175);
                case 4:
                    countdown.velocity.y = FlxG.random.int(280, 260);

                    FlxTween.tween(countdown, {alpha: 0}, 0.4, {onComplete: (shit)->{
                        countdown.kill();
                    }});
            }

            if (iteration <= maxIterations) {
                ++iteration;

                timer.reset(Conductor.crochet / 1000);
            }
        });
    }

    function startSong() {
        previousFrameTime = FlxG.game.ticks;
        
        resyncAudio();

        songStarted = true;
        canPause = true;
    }

    function endSong()
    {
        canPause = false;
        
        if (!chartingMode) {
            if (!botplay)
                Highscore.saveScore(curSong.song, songScore, storyDifficulty);
    
            if (isStoryMode)
            {
                campaignScore += songScore;
    
                storyPlaylist.remove(storyPlaylist[0]);
    
                if (storyPlaylist.length <= 0)
                {
                    FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);
    
                    transIn = FlxTransitionableState.defaultTransIn;
                    transOut = FlxTransitionableState.defaultTransOut;

                    camFollow = null;
    
                    if (!botplay)
                        Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
    
                    FlxG.save.flush();

                    FlxG.switchState(new StoryMenuState());
                }
                else
                {
                    trace('LOADING NEXT SONG');
                    trace(PlayState.storyPlaylist[0].toLowerCase() + '-$storyDifficulty');
    
                    FlxTransitionableState.skipNextTransIn = true;
                    FlxTransitionableState.skipNextTransOut = true;
    
                    HelpfulAPI.playSongs(storyPlaylist, storyDifficulty);
                }
            }
            else
            {
                trace('WENT BACK TO FREEPLAY??');

                camFollow = null;
    
                FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);
                FlxG.switchState(new FreeplayState());
            }
        }
        else {
            #if debug
            FlxG.switchState(new ChartingState(curSong, 0));
            #else
            FlxG.switchState(new FreeplayState());
            #end
        }
    }

    var paused:Bool = false;
    var canPause:Bool = false;
    
    // interpolation shit
    var songTime:Float;
    var previousFrameTime:Float;

    override function update(elapsed:Float)
    {
        health = Math.min(Math.max(health, 0), 2);

        scoreTxt.text = 'Score: $songScore';
        if (botplay)
            scoreTxt.text += " - BOTPLAY";

        super.update(elapsed);

        if (songGenerated) {
            if (camFollow != null) {
                if (!curSectionData.mustHitSection)
                    camFollow.setPosition(dad.getMidpoint().x + dad.camOffsets[0], dad.getMidpoint().y + dad.camOffsets[1]);
                else
                    camFollow.setPosition(bf.getMidpoint().x + bf.camOffsets[0], bf.getMidpoint().y + bf.camOffsets[1]);
            }
            else {
                trace('camFollow is null lol');
            }

            if (songStarted) {
                Conductor.songPosition = FlxG.sound.music.time - Conductor.offset;

                songTime += FlxG.game.ticks - previousFrameTime;
                previousFrameTime = FlxG.game.ticks;

                if (Conductor.lastSongPos != Conductor.songPosition)
                {
                    songTime = (songTime + Conductor.songPosition) / 2;
                    Conductor.lastSongPos = Conductor.songPosition;
                }

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
                songTime = Conductor.songPosition;

                if (Conductor.songPosition >= 0)
                    startSong();
            }

            // You'd expect looping through every note would cause lag but surprisngly not.
            notes.forEachAlive((daNote:Note)->{
                var strumLine:ArrowStrums = null;
                switch(daNote.mustPress) {
                    case false:
                        strumLine = opponentStrums;
                    case true:
                        strumLine = playerStrums;
                }

                if (downscroll)
                    daNote.y = (strumLine.strums[daNote.noteData].y + (songTime - daNote.strumTime) * (0.45 * curSong.speed)) + daNote.yOffset;
                else
                    daNote.y = (strumLine.strums[daNote.noteData].y - (songTime - daNote.strumTime) * (0.45 * curSong.speed)) + daNote.yOffset;

                daNote.x = strumLine.strums[daNote.noteData].x + daNote.xOffset;

                // Basically, if the note is on screen, make it active.
                // Becareful if you make a mod chart since moving the notes too low (or high, depends) the notes will stay inactive.
                if (!downscroll && daNote.y <= FlxG.height || downscroll && daNote.y >= -(Note.swagWidth * 2)) {
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
                                    && daNote.y + daNote.yOffset * daNote.scale.y + daNote.height >= strumLineMid)
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
                                && daNote.y - daNote.yOffset * daNote.scale.y <= strumLineMid)
                            {
                                var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
        
                                swagRect.y = (strumLineMid - daNote.y) / daNote.scale.y;
                                swagRect.height -= swagRect.y;
                                daNote.clipRect = swagRect;
                            }
                        }

                        // CPU Note Hits. Botplay weirdly causes lag?
                        if ((!daNote.mustPress || botplay) && !daNote.wasGoodHit && daNote.noteOnTime)
                            goodNoteHit(daNote);
                        
                        // Note missing and clean up. If it's too late to hit the note, kill it and handle missing.
                        if (daNote.mustPress && daNote.tooLate && !daNote.wasGoodHit) {
                            if (!daNote.isSustainNote) {
                                noteMiss(daNote.noteData);
                            }
                            else {
                                combo = 0;
                                songScore -= 10;
                                health -= 0.025;

                                bfVocals.volume = 0;
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

        if (health <= 0 || controls.RESET) {
            FlxG.sound.music.pause();
            bfVocals.pause();

            if (opponentVocals != null)
                opponentVocals.pause();

            persistentDraw = persistentUpdate = false;
            openSubState(new GameOverSubstate(bf.x, bf.y));
        }

        if (controls.PAUSE || controls.ACCEPT) {
            persistentUpdate = false;
            paused = true;

            FlxG.sound.music.pause();
            bfVocals.pause();

            if (opponentVocals != null)
                opponentVocals.pause();

            openSubState(new PauseSubState());
        }

        #if debug
        if (FlxG.keys.justPressed.SEVEN) {
            chartingMode = true;
            FlxG.switchState(new ChartingState(curSong, curSection));
        }
        else if (FlxG.keys.justPressed.EIGHT)
            FlxG.switchState(new CharacterEditor(curSong.player1));
        else if (FlxG.keys.justPressed.TAB)
            botplay = !botplay;
        #end

        // This part is dirty af because I'm lazy and I just want to get this done
        var iconOffset:Int = 10;
		bfIcon.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		opponentIcon.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (opponentIcon.width - iconOffset);

        if (healthBar.percent < 20)
			bfIcon.animation.curAnim.curFrame = 1;
		else
			bfIcon.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			opponentIcon.animation.curAnim.curFrame = 1;
		else
			opponentIcon.animation.curAnim.curFrame = 0;

        if (beatZooming) {
            camGame.zoom = FlxMath.lerp(camGame.zoom, defaultZoom, 0.06);
            camHUD.zoom = FlxMath.lerp(camHUD.zoom, 1, 0.06);
        }
    }

    override function closeSubState() {
        if (paused)
		{
			if (FlxG.sound.music != null && songStarted)
				resyncAudio();

            previousFrameTime = FlxG.game.ticks;
			paused = false;
		}

		super.closeSubState();
    }

    function popUpScore(direction:Int, strumTime:Float)
    {
        var noteDiff:Float = Math.abs(strumTime - Conductor.songPosition);

		var score:Int = 300;
		var daRating:String = "sick";

		var safeZones:Array<Float> = [0.6, 0.45, 0.3]; // The starting value, and the next in line is the end value. So 1 - 0.6 is a Shit, but a 0.6 - 0.45 is a bad.
		var ratings:Array<String> = ['shit', 'bad', 'good'];

		for (i in 0...ratings.length) {
			var safeZone = safeZones[i];

			if (noteDiff > Conductor.safeZoneOffset * safeZone) {
				daRating = ratings[i];
				score = 100 * i;

				break;
			}
		}

		switch (daRating.toLowerCase()) {
			case 'sick':
				++sicks;

				if (style.curStyle.enableSplashes) {
                    var noteSplash:NoteSplash = new NoteSplash(style);

					noteSplash.splash(direction, playerStrums.strums[direction].x, playerStrums.strums[direction].y);
					splashes.add(noteSplash);
				}
			case 'good':
				++goods;
			case 'bads':
				++bads;
			case 'shits':
				++shits;
		}

        songScore += score;

        var items:Array<FlxSprite> = [];
        
        var rating:FlxSprite = new FlxSprite().loadGraphic(style.getImage('${style.curStyle.ratingsDirectoryPath}/$daRating'));
        rating.setGraphicSize(rating.width * 0.5);
		rating.updateHitbox();
        rating.screenCenter(X);
        items.push(rating);

        var comboSpr:FlxSprite = new FlxSprite().loadGraphic(style.getImage('${style.curStyle.uiDirectoryPath}/combo'));
        comboSpr.setGraphicSize(comboSpr.width * 0.5);
        comboSpr.updateHitbox();
        comboSpr.x = (rating.x - (comboSpr.width / 2));
        items.push(comboSpr);

        if (!downscroll) {
            rating.y = healthBarBG.y - (rating.height * 1.25);
            comboSpr.y = rating.y - comboSpr.height;
        }
        else {
            rating.y = healthBarBG.y + (rating.height * 1.25);
            comboSpr.y = rating.y + comboSpr.height;
        }

        var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

        var iteration:Int = 0;
        for (i in seperatedScore) {
            var num:FlxSprite = new FlxSprite();
            num.loadGraphic(style.getImage('${style.curStyle.numDirectoryPath}/num${Std.string(i)}'));
            num.setGraphicSize(num.width * 0.5);
            num.updateHitbox();
            num.x = comboSpr.x + comboSpr.width + (num.width * iteration);
            num.y = comboSpr.y;
            items.push(num);

            ++iteration;
        }

        for (item in items) {
            item.acceleration.y = 550;
            item.velocity.y -= FlxG.random.int(140, 175);
            item.velocity.x -= FlxG.random.int(0, 10);

            FlxTween.tween(item, {alpha: 0}, 1, { onComplete: function(tween:FlxTween) {
				item.kill();
			}});

            popUpSprites.add(item);
        }
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
            bfVocals.volume = 0;

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
		
					popUpScore(note.noteData, note.strumTime);

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

    var tracks:Array<FlxSound>;
    function resyncAudio():Void
	{
        tracks = [bfVocals, opponentVocals];
        /*if (!curSong.needsVoices)
            tracks.push(FlxG.sound.music);*/

        FlxG.sound.music.play();

		// Conductor.songPosition = FlxG.sound.music.time - Conductor.offset;
        
        for (track in tracks) {
            if (FlxG.sound.music.time < track.length) {
                track.time = FlxG.sound.music.time;
                track.play();
            }
            else {
                track.pause();
            }
        }
	}

    override function stepHit()
    {
        super.stepHit();

        for (track in tracks) {
            if (track != null && track.playing && (track.time - Conductor.offset > Conductor.songPosition + 20 || track.time - Conductor.offset < Conductor.songPosition - 20)) {
                resyncAudio();
                break;
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

        if (Options.get('allowDistractions')) {  
            if (beatZooming && curBeat % 4 == 0) {
                camGame.zoom += 0.02;
                camHUD.zoom += 0.015;
            }
            
			if (curBeat % 8 == 7 && curSong.song.toLowerCase() == 'bopeebo'){
				bf.playAnim('hey', true);
				gf.playAnim('cheer', true);
			}
		}

        if (Options.get("allowModCharts") && curSong.song.toLowerCase() == 'tutorial' && storyDifficulty == 'hard')
			notes.visible = opponentStrums.visible = playerStrums.visible = !playerStrums.visible;
    }
}