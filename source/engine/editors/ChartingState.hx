package engine.editors;

import openfl.Assets;
#if debug
import lime.media.AudioBuffer;
import lime.utils.Bytes;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import objects.HealthIcon;
import engine.Section.SwagSection;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import engine.Conductor;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import objects.Note;
import flixel.FlxG;
import flixel.FlxSprite;
import engine.Section.SectionNoteData;
import engine.Song.SwagSong;
import flixel.math.FlxRect;
import objects.NameTag;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.text.FlxText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.text.FlxInputText;
import haxe.Json;
import lime.ui.FileDialog;
import flixel.math.FlxPoint;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import engine.Styles.StyleHandler;
import engine.Styles.LocalStyle;

class ChartingState extends MusicBeatState {
    private var GRID_SIZE:Int = 40;

    private var uiCam:FlxCamera;

    private var _song:SwagSong;
    private var _note:SectionNoteData;

    private var vocals:FlxSound;

    private var lastSection:Int = -1;
    private var curSection:Int = 0;

    private var sectionLine:FlxSprite;
    private var sectionBG:FlxSprite;
    private var sectionWaveform:FlxSprite;
    private var prevSectionBG:FlxSprite;

    private var strumLine:FlxSprite;
    private var daCursor:FlxSprite;

    private var iconLeft:HealthIcon;
    private var iconRight:HealthIcon;

    private var prevRenderedNotes:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
    private var renderedNotes:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();

    private var ui_box:FlxUITabMenu;
    private var songNameInput:FlxInputText;

    private var tags:FlxTypedSpriteGroup<NameTag> = new FlxTypedSpriteGroup();

    private var stupidText:FlxText;

    override public function new(song:SwagSong, ?section:Int = 0) 
    {
        _song = song;
        curSection = section;

        super();
    }

    override public function create()
    {
        uiCam = new FlxCamera();
        uiCam.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(uiCam, false);

        if (_song == null) {
            _song = {
				song: 'Tutorial',
				notes: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				girlfriend: 'gf',
				speed: 1,
				visualStyle: 'default'
			};
        }

        reloadSong(_song.song);
        Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.getImage('menuDesat'));
		bg.color = FlxColor.fromRGB(30, 30, 30);
		bg.scrollFactor.set();
		add(bg);

        // GRID_SIZE = Math.floor(Note.swagWidth / 2);

        sectionBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
        sectionBG.color = FlxColor.GRAY;

        prevSectionBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
        prevSectionBG.color = FlxColor.GRAY;

        prevSectionBG.y -= prevSectionBG.height;
        prevSectionBG.alpha = 0.5;

        add(prevSectionBG);
        add(sectionBG);

        sectionWaveform = new FlxSprite().makeGraphic(sectionBG.graphic.width, sectionBG.graphic.height, FlxColor.TRANSPARENT);
        add(sectionWaveform);
        
        add(prevRenderedNotes);
        add(renderedNotes);

        daCursor = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE, FlxColor.WHITE);
        daCursor.alpha = 0.5;
        add(daCursor);

        sectionLine = new FlxSprite().makeGraphic(4, Math.floor(sectionBG.height * 2), FlxColor.BLACK);
        sectionLine.y -= sectionBG.height;
        sectionLine.x = (sectionBG.width / 2) - 2;
        add(sectionLine);

        strumLine = new FlxSprite().makeGraphic(Math.floor(sectionBG.width), 4, FlxColor.ORANGE);
        add(strumLine);

        iconLeft = new HealthIcon("bf");
        iconLeft.setGraphicSize(iconLeft.graphic.width * 0.25);
        iconLeft.updateHitbox();
        iconLeft.setPosition(((GRID_SIZE * 4) / 2) - (iconLeft.width / 2), sectionBG.y - iconLeft.height);
        iconLeft.alpha = 1;

        iconRight = new HealthIcon("default");
        iconRight.setGraphicSize(iconLeft.graphic.width * 0.25);
        iconRight.updateHitbox();
        iconRight.setPosition((GRID_SIZE * 4) + (iconRight.width / 2), sectionBG.y - iconRight.height);
        iconRight.alpha = 0.5;

        add(iconLeft);
        add(iconRight);

        changeSection(curSection);

        // ui shit
        final tabs = [
            {name: "Editor", label: "Editor"},
            {name: "Song", label: "Song"},
            {name: "Section", label: "Section"},
            {name: "Note", label: "Note"},
        ];
        ui_box = new FlxUITabMenu(null, tabs, true);

        ui_box.resize(FlxG.width / 4, FlxG.height - 40);
        ui_box.x = FlxG.width - ui_box.width - 20;
        ui_box.y = 20;
        ui_box.camera = uiCam;

        createNoteUI();
        createSectionUI();
        createSongUI();
        createEditorUI();

        add(ui_box);

        stupidText = new FlxText(20, 20);
        stupidText.setFormat(null, 12);
        stupidText.camera = uiCam;
        add(stupidText);

        tags.camera = uiCam;
        add(tags);

        super.create();

        FlxG.camera.focusOn(sectionBG.getMidpoint());
        FlxG.camera.scroll.x += sectionBG.width / 2;

        FlxG.mouse.visible = true;

        FlxG.sound.music.time = sectionStartTime(curSection) + 20;
    }

    /**
     * Updates every frame
     */
    var updatesEveryFrame:Array<Void->Void> = [];
    /**
     * Updates when the section changes
     */
    var updatesOnSectionChange:Array<Void->Void> = [];

    var uip:FlxPoint = new FlxPoint(20, 20);
    function createEditorUI()
    {
        var group:FlxUIGroup = new FlxUIGroup();
        group.name = 'Editor';

        var loadSong:FlxUIButton = new FlxUIButton(uip.x, uip.y, "Load Song", ()->{
            var fileDialog = new FileDialog();

            fileDialog.onOpen.add((res)->{
                var chart:SwagSong = Json.parse(res).song;
                FlxG.switchState(new ChartingState(chart));
            });

            fileDialog.open("json", null, "Load Chart");
        });
        group.add(loadSong);

        var saveSong:FlxUIButton = new FlxUIButton(uip.x + 100, uip.y, "Save Song", ()->{
            var fileDialog = new FileDialog();

            _song.song = songNameInput.text;

            var json = {
                "song": _song
            };

            var data = Json.stringify(json, "\t");
            fileDialog.save(data, null, '${_song.song}-${PlayState.storyDifficulty}.json');
        });
        group.add(saveSong);

        var reloadSong:FlxUIButton = new FlxUIButton(uip.x + 200, uip.y, "Reload Audio", ()->{ reloadSong(songNameInput.text); changeSection(0); });
        group.add(reloadSong);

        var playbackStepper:FlxUINumericStepper = new FlxUINumericStepper(uip.x, uip.y + 40, 0.05, 1, 0, 2, 2);
        updatesEveryFrame.push(()->{
            vocals.pitch = FlxG.sound.music.pitch = playbackStepper.value;
        });
        group.add(playbackStepper);
        
        var pbSText:FlxText = new FlxText(playbackStepper.x + 60, playbackStepper.y, 0, "Playback Rate");
        group.add(pbSText);

        var help:FlxText = new FlxText(0, (ui_box.height - 20) - 200, 300);
        help.x = (ui_box.width / 2) - (help.width / 2);
        help.text = "W, and S, to move the strum line.\n"
            + "A, and D, to cycle through the sections.\n"
            + "Space to play the song.\n"
            + "Voices must be mixed down into one track and be named 'Mixed-Voices'.";
        help.setFormat(null, 10, FlxColor.WHITE);
        group.add(help);

        ui_box.addGroup(group);
    }

    var stepperSusLength:FlxUINumericStepper;
    var altAnimCheckbox:FlxUICheckBox;
    function createNoteUI()
    {
        var group:FlxUIGroup = new FlxUIGroup();
        group.name = 'Note';

        stepperSusLength = new FlxUINumericStepper(uip.x, uip.y, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
        updatesEveryFrame.push(()->{
            if (_note != null && _note.sustainLength != stepperSusLength.value) {
                _note.sustainLength = Math.floor(stepperSusLength.value);
                updateSection();
            }
        });
        group.add(stepperSusLength);

        var stepperText:FlxText = new FlxText(stepperSusLength.x + stepperSusLength.width + 4, stepperSusLength.y, 80, "Sustain Length");
        group.add(stepperText);

        altAnimCheckbox = new FlxUICheckBox(uip.x, uip.y + 40, null, null, "Alt Animation");
        altAnimCheckbox.callback = () -> {
            if (_note != null)
                _note.altAnimation = altAnimCheckbox.checked;
        };
        group.add(altAnimCheckbox);

        ui_box.addGroup(group);
    }

    var lengthStepper:FlxUINumericStepper;

    var copiedSection:SwagSection;
    function createSectionUI()
    {
        var group:FlxUIGroup = new FlxUIGroup();
        group.name = 'Section';

        var mustHitCheckbox:FlxUICheckBox = new FlxUICheckBox(uip.x, uip.y, null, null, "Must Hit Section");
        mustHitCheckbox.callback = () -> {
            _song.notes[curSection].mustHitSection = mustHitCheckbox.checked;
            updateGrid();
        }
        updatesOnSectionChange.push(()->{
            mustHitCheckbox.checked = _song.notes[curSection].mustHitSection;
        }); 
        group.add(mustHitCheckbox);

        lengthStepper = new FlxUINumericStepper(uip.x, uip.y + 50, 4, _song.notes[curSection].lengthInSteps, 4, 16, 0);
        updatesOnSectionChange.push(()->{
            lengthStepper.value = _song.notes[curSection].lengthInSteps;
        });
        updatesEveryFrame.push(()->{
            var section = _song.notes[curSection];
            if (section != null && section.lengthInSteps != Math.floor(lengthStepper.value)) {
                section.lengthInSteps = Math.floor(lengthStepper.value);
                updateSection();
            }
        });
        group.add(lengthStepper);

        var tag = NameTag.createTag(lengthStepper, "Section Length", "Future sections will be broken, clear them first.");
        tags.add(tag);

        var stepperText:FlxText = new FlxText(lengthStepper.x + 60, lengthStepper.y, 0, "Section Length");
        group.add(stepperText);

        var bpmStepper = new FlxUINumericStepper(uip.x + 150, uip.y + 50, 0.5, 150, 0, 512, 1);
        updatesOnSectionChange.push(()->{
            bpmStepper.value = _song.notes[curSection].bpm;
        });
        updatesEveryFrame.push(()->{
            if (_song.notes[curSection].bpm != bpmStepper.value) {
                _song.notes[curSection].bpm = bpmStepper.value;
                updateSection();
            }
        });
        group.add(bpmStepper);

        var bpmText:FlxText = new FlxText(bpmStepper.x + 60, bpmStepper.y, 0, "Section BPM");
        group.add(bpmText);

        var changeBPMCheckbox:FlxUICheckBox = new FlxUICheckBox(bpmStepper.x, bpmStepper.y + bpmStepper.height + 4, null, null, "Change BPM");
        changeBPMCheckbox.callback = () -> {
            _song.notes[curSection].changeBPM = changeBPMCheckbox.checked;
            updateSection();
        };
        updatesOnSectionChange.push(()->{
            changeBPMCheckbox.checked = _song.notes[curSection].changeBPM;
        });
        group.add(changeBPMCheckbox);

        var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(uip.x, uip.y + 120, 1, 1, -999, 999, 0);
        group.add(stepperCopy);

        var copyLastSection:FlxUIButton = new FlxUIButton(uip.x + 60, uip.y + 115, "Copy Section", ()->{
            copySection(Math.floor(stepperCopy.value));
        });
        group.add(copyLastSection);

        var swapSection:FlxUIButton = new FlxUIButton(stepperCopy.x, stepperCopy.y + 40, "Swap Section", ()->{
            var section:SwagSection = _song.notes[curSection];

            for (note in section.sectionNotes) {
                if (note.noteData > 3)
                    note.noteData -= 4;
                else
                    note.noteData += 4;
            }

            _song.notes[curSection] = section;
            updateSection();
        });
        group.add(swapSection);

        var clearSection:FlxUIButton = new FlxUIButton(uip.x, ui_box.height - 60, "CLEAR", ()->{
            _song.notes[curSection].sectionNotes = [];
            updateSection();
        });
        clearSection.color = FlxColor.RED;
        group.add(clearSection);


        ui_box.addGroup(group);
    }

    function createSongUI()
    {
        var group:FlxUIGroup = new FlxUIGroup();
        group.name = 'Song';

        songNameInput = new FlxInputText(uip.x, uip.y, 80, _song.song);
        group.add(songNameInput);

        var tag = NameTag.createTag(songNameInput, "Song Name");
        tags.add(tag);

        var bpmStepper = new FlxUINumericStepper(uip.x + 100, uip.y, 0.5, 150, 0, 512, 1);
        bpmStepper.value = _song.bpm;

        updatesEveryFrame.push(()->{
            if (_song.bpm != bpmStepper.value) {
                _song.bpm = bpmStepper.value;

				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(_song.bpm));

                updateSection();
            }
        });
        group.add(bpmStepper);

        var speedStepper = new FlxUINumericStepper(uip.x, uip.y + 40, 0.05, 1, 0.1, 10, 2);
        speedStepper.value = _song.speed;
        updatesEveryFrame.push(()->{
            if (_song.speed != speedStepper.value)
                _song.speed = speedStepper.value;
        });
        group.add(speedStepper);

        var songSpeedText:FlxText = new FlxText(speedStepper.x + 60, speedStepper.y, 100, "Speed");
        group.add(songSpeedText);

        var bpmText:FlxText = new FlxText(bpmStepper.x + 60, bpmStepper.y, 0, "BPM");
        group.add(bpmText);

        var characters:Array<String> = CoolUtil.coolTextFile('assets/data/characterList.txt');
		var styles:Array<String> = CoolUtil.coolTextFile(Paths.getTxt('visualStyleList'));
        var stages:Array<String> = CoolUtil.coolTextFile(Paths.getTxt('stageList'));

		var addLater:Array<FlxUIDropDownMenu> = [];

		var createDrop = function(x:Float, y:Float, array:Array<String>, func:FlxUIDropDownMenu->Void, callback:String->Void, tagDesc:String) {
			var dropdown = new FlxUIDropDownMenu(x, y, FlxUIDropDownMenu.makeStrIdLabelArray(array, true), callback);
			func(dropdown);

			var marker:FlxSprite = new FlxSprite(x, y).makeGraphic(125, 25, FlxColor.TRANSPARENT);
			marker.scrollFactor.set();
			group.add(marker);

			var tag = NameTag.createTag(marker, tagDesc);
            tags.add(tag);

			addLater.push(dropdown);
		};

		createDrop(20, 100, characters, function(dropdown:FlxUIDropDownMenu) { dropdown.selectedLabel = _song.player1; },
			function (string:String) { _song.player1 = characters[Std.parseInt(string)]; }, "Player Character");

		createDrop(150, 100, characters, function(dropdown:FlxUIDropDownMenu) { dropdown.selectedLabel = _song.player2; },
			function (string:String) { _song.player2 = characters[Std.parseInt(string)]; }, "Opponent Character");

		createDrop(20, 140, characters, function(dropdown:FlxUIDropDownMenu) { dropdown.selectedLabel = _song.girlfriend; },
			function (string:String) { _song.girlfriend = characters[Std.parseInt(string)]; }, "Girlfriend Character");

		createDrop(150, 140, styles, function(dropdown:FlxUIDropDownMenu) { dropdown.selectedLabel = _song.visualStyle; },
			function (string:String) { _song.visualStyle = styles[Std.parseInt(string)]; }, "Visual Style");

        createDrop(20, 180, stages, function(dropdown:FlxUIDropDownMenu) { dropdown.selectedLabel = _song.curStage; },
			function (string:String) { _song.curStage = stages[Std.parseInt(string)]; }, "Selected Stage");

        addLater.sort(function(a, b):Int {
			if (a.y > b.y) {
				return -1;
			}
			else if (a.y < b.y) {
				return 1;
			}

			return 0;
		});

        for (item in addLater)
            group.add(item);

        ui_box.addGroup(group);
    }

    function checkProperties(?updating:Bool = true)
    {
        if (updating) {
            for (update in updatesEveryFrame) {
                update();
            }
        }
        else {
            for (update in updatesOnSectionChange) {
                update();
            }
        }
    }

	function copySection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);
        if (_song.notes[daSec - sectionNum] == null) {
            trace('Copying NULL!? Nah, not happening.');
            return;
        }

        trace('Copying Section $daSec - $sectionNum...');

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note.strumTime + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:SectionNoteData =
			{
				strumTime: strum,
				noteData: note.noteData,
				sustainLength: note.sustainLength,
				altAnimation: note.altAnimation
			};

			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateSection();
	}
    
    override public function update(elapsed:Float)
    {
        if (FlxG.mouse.overlaps(sectionBG)) {
            daCursor.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;

			if (FlxG.keys.pressed.SHIFT)
				daCursor.y = Math.floor(FlxG.mouse.y / (GRID_SIZE / 2)) * (GRID_SIZE / 2);
			else if (FlxG.keys.pressed.ALT)
				daCursor.y = Math.floor(FlxG.mouse.y / (GRID_SIZE / 4)) * (GRID_SIZE / 4);
			else
				daCursor.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;

            // add/remove note
            if (FlxG.mouse.justPressed) {
                var noNote:Bool = true;

                for (note in renderedNotes) {
                    var daNote:Note = null;
                    if (note is Note)
                        daNote = cast (note, Note);
                    else
                        continue;

                    if (FlxG.mouse.overlaps(daNote)) {
                        for (i in _song.notes[curSection].sectionNotes) {
                            var check:Bool = true;
                            if (i.noteData >= 4 && !daNote.mustPress)
                                check = true;
                            else if (i.noteData < 4 && daNote.mustPress)
                                check = true;
                            else
                                check = false;

                            if (i.strumTime == daNote.strumTime && (i.noteData % 4) == daNote.noteData && check) {
                                _song.notes[curSection].sectionNotes.remove(i);

                                trace('Removed Note!');

                                noNote = false;
                                updateSection();

                                break;
                            }
                        }
                    }
                }

                // Add note if there was none
                if (noNote) {
                    trace('Adding Note!');

                    stepperSusLength.value = 0;
                    altAnimCheckbox.checked = false;

                    var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
                    var noteStrum = getStrumTime(daCursor.y) + sectionStartTime();
    
                    _note = {
                        noteData: noteData,
                        strumTime: noteStrum,
                        sustainLength: 0,
                        altAnimation: false
                    }
    
                    _song.notes[curSection].sectionNotes.push(_note);
                    updateSection();
                }
            }
        }

        if (Conductor.songPosition > sectionStartTime(curSection + 1))
            changeSection(curSection + 1);
        else if (curSection > 0 && Conductor.songPosition < sectionStartTime() - 20)
            changeSection(curSection - 1);

        curStep = recalculateSteps();
        strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));

        FlxG.camera.scroll.y = (strumLine.y - (sectionBG.height / 2)) + 2;

        if (!FlxG.mouse.overlaps(ui_box, uiCam)) {
            if (FlxG.keys.justPressed.SPACE) {
                if (FlxG.sound.music.playing) {
                    FlxG.sound.music.pause();
                    vocals.pause();
                }
                else {
                    FlxG.sound.music.play();
                    vocals.play();
                }
            }

            if (!FlxG.sound.music.playing) {
                if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D) {
                    if (FlxG.keys.justPressed.A && curSection > 0)
                        changeSection(curSection - 1);
                    else if (FlxG.keys.justPressed.D)
                        changeSection(curSection + 1);

                    FlxG.sound.music.time = sectionStartTime();
                }
            }

            if (FlxG.keys.pressed.W || FlxG.keys.pressed.S) {
                if (FlxG.sound.music.playing) {
                    FlxG.sound.music.pause();
                    vocals.pause();
                }

                if (FlxG.keys.pressed.W && FlxG.sound.music.time > 0)
                    FlxG.sound.music.time -= 700 * elapsed;
                else if (FlxG.keys.pressed.S && FlxG.sound.music.time < FlxG.sound.music.length)
                    FlxG.sound.music.time += 700 * elapsed;

                vocals.time = FlxG.sound.music.time;
            }

            if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE) {
                if (vocals != null)
                    vocals.stop();
                if (FlxG.sound.music != null)
                    FlxG.sound.music.stop();

                PlayState.curSong = _song;

                FlxG.switchState(new PlayState());
            }
        }

        super.update(elapsed);

        Conductor.songPosition = FlxG.sound.music.time;
        vocals.update(elapsed);

        checkProperties();

        if (vocals.playing && (vocals.time > FlxG.sound.music.time + 20 || vocals.time < FlxG.sound.music.time - 20))
			vocals.time = FlxG.sound.music.time;

        stupidText.text = 'Time: ${FlxG.sound.music.time / 1000}/${FlxG.sound.music.length / 1000}\n' +
            'Section: $curSection\n' +
            'Step: $curStep\n' +
            'Beat: $curBeat';
    }

    function updateGrid() {
        var mustHit:Bool = _song.notes[curSection].mustHitSection;

        if (mustHit) {
            iconLeft.changeIcon('bf');
            iconRight.changeIcon('default');
        }
        else {
            iconLeft.changeIcon('default');
            iconRight.changeIcon('bf');
        }

        sectionWaveform.clipRect = sectionBG.clipRect = new FlxRect(0, 0, GRID_SIZE * 8, GRID_SIZE * _song.notes[curSection].lengthInSteps);
        if (curSection > 0 && _song.notes[curSection - 1] != null && _song.notes[curSection - 1].lengthInSteps != 16) {
            prevRenderedNotes.visible = false;
            prevSectionBG.visible = false;
        }
        else if (curSection > 0 && _song.notes[curSection - 1] != null) {
            prevRenderedNotes.visible = true;
            prevSectionBG.visible = true;
        }
    }

    final yoMama:String = "so fat";

    function changeSection(section:Int) {
        trace('Changing Section ($curSection -> $section)...');

        lastSection = curSection;

        prevRenderedNotes.visible = false;
        renderedNotes.visible = false;

        prevRenderedNotes.killMembers();
        prevRenderedNotes.clear();

        prevSectionBG.visible = true;

        if (section > curSection) {
            for (note in renderedNotes.members) {
                if (note != null) {
                    prevRenderedNotes.add(note);
                    renderedNotes.remove(note);
        
                    note.y -= sectionBG.height;
                    note.alpha = 0.5;
                }
            }
        }
        else if (section > 0 && section < curSection) {
            createNotes(section - 1, prevRenderedNotes);
            for (note in prevRenderedNotes.members) {
                note.y -= sectionBG.height;
                note.alpha = 0.5;
            }
        }
        else if (section <= 0) {
            prevSectionBG.visible = false;
        }
    
        renderedNotes.killMembers();
        renderedNotes.clear();

        if (_song.notes[section] != null) {
            createNotes(section, renderedNotes);
        } 
        else {
            createSection(section);
        }
    
        curSection = section;
        prevRenderedNotes.visible = true;
        renderedNotes.visible = true;

        updateGrid();
        syncBPM();
        updateWaveform();
        checkProperties(false);
    }    

    function createSection(section:Int) {
        var i:Int = 0;
        while (_song.notes[section] == null) {
            var mustHit:Bool = true;

            if (i > 0 && _song.notes[i - 1] != null)
                mustHit = !_song.notes[i - 1].mustHitSection;

            if (_song.notes[i] == null) {
                _song.notes[i] = {
                    sectionNotes: [],
                    bpm: _song.bpm,
                    lengthInSteps: 16,
                    changeBPM: false,
                    mustHitSection: mustHit,
                    typeOfSection: 0
                }
            };

            ++i;
        }
    }

    function syncBPM() {
        if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
        {
            Conductor.changeBPM(_song.notes[curSection].bpm);
            FlxG.log.add('CHANGED BPM!');
        }
        else
        {
            var daBPM:Float = _song.bpm;
            for (i in 0...curSection)
                if (_song.notes[i].changeBPM)
                    daBPM = _song.notes[i].bpm;
            Conductor.changeBPM(daBPM);
        }
    }

    function updateSection() {
        renderedNotes.killMembers();
        renderedNotes.clear();

        createNotes(curSection, renderedNotes);
        updateGrid();
        syncBPM();
    }

    function createNotes(section:Int, group:FlxTypedGroup<FlxSprite>) {
        var notes = _song.notes[section].sectionNotes;

		for (note in notes)
		{
			var daNoteInfo = note.noteData;
			var daStrumTime = note.strumTime;
			var daSus = note.sustainLength;

            var note:Note = new Note(daStrumTime, daNoteInfo % 4, StyleHandler.handler);
			note.sustainLength = daSus;
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.x = Math.floor(daNoteInfo * GRID_SIZE);
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime(section)) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)));

            var gottaHitNote:Bool = true;
            if (daNoteInfo >= 4)
                gottaHitNote = false;
            
            note.mustPress = gottaHitNote;
            note.active = false;
            note.visible = true;
            
            if (daSus > 0)
			{
				var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2) - 4, (note.y + GRID_SIZE) - 5);
                sustainVis.makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, sectionBG.height)));
				group.add(sustainVis);
			}

			group.add(note);
		}
    }

    function reloadSong(song:String)
    {
        if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
        if (vocals != null)
            vocals.stop();

		FlxG.sound.playMusic(Paths.getSong(song.toLowerCase(), 'Inst'), 0.6, false);

        if (Assets.exists(Paths.getSong(song.toLowerCase(), 'Mixed-Voices')))
		    vocals = new FlxSound().loadEmbedded(Paths.getSong(song.toLowerCase(), 'Mixed-Voices'));
        else
            vocals = new FlxSound().loadEmbedded(Paths.getSong(song.toLowerCase(), 'Player-Voices'));

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function()
		{
			changeSection(0);
            Conductor.songPosition = vocals.time = FlxG.sound.music.time = 0;
		};

        Conductor.songPosition = 0;
    }

    /**
     * Retrieve the starting time of a section
     * @param section 
     * @return Float
     */
    function sectionStartTime(?section:Null<Int>):Float
	{
		if (section == null)
			section = curSection;

        if (_song.notes[section] == null)
            createSection(section);
			
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		
		for (i in 0...section)
		{
			if (_song.notes[i].changeBPM)
				daBPM = _song.notes[i].bpm;
		
			var sectionLengthInBeats = _song.notes[i].lengthInSteps / 4;
			daPos += sectionLengthInBeats * (1000 * 60 / daBPM);
		}
		
		return daPos;
	}

    /**
     * Recalculate the current step
     * @return Int
     */
    function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

    function getStrumTime(yPos:Float, ?sectionBG:FlxSprite):Float
	{
        if (sectionBG == null)
            sectionBG = this.sectionBG;

		return FlxMath.remapToRange(yPos, sectionBG.y, sectionBG.y + sectionBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, ?sectionBG:FlxSprite):Float
	{
        if (sectionBG == null)
            sectionBG = this.sectionBG;

		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, sectionBG.y, sectionBG.y + sectionBG.height);
	}

    // Borrwed this from Psych Engine, full credit to ShadowMario and the rest of the Psych Engine team.
    // I'd code this myself if I were fucking insane. Seriously, credit to them.
	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

	var lastWaveformHeight:Int = 0;
	function updateWaveform() {
        if (vocals == null)
            return;
        
		if(waveformPrinted) {
			var width:Int = Std.int(GRID_SIZE * 8);
			var height:Int = Std.int(GRID_SIZE * 16);
			if(lastWaveformHeight != height && sectionWaveform.pixels != null)
			{
				sectionWaveform.pixels.dispose();
				sectionWaveform.pixels.disposeImage();
				sectionWaveform.makeGraphic(width, height, 0x00FFFFFF);
				lastWaveformHeight = height;
			}
			sectionWaveform.pixels.fillRect(new Rectangle(0, 0, width, height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];

		var steps:Int = 16;
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		var sound:FlxSound = vocals;
		
		@:privateAccess
		if (sound != null && sound._sound != null && sound._sound.__buffer != null) {
			var bytes:Bytes = sound._sound.__buffer.data.toBytes();

			wavData = waveformData(
				sound._sound.__buffer,
				bytes,
				st,
				et,
				1,
				wavData,
				sectionBG.graphic.height
			);
		}

		// Draws
		var gSize:Int = Std.int(GRID_SIZE * 8);
		var hSize:Int = Std.int(gSize / 2);
		var size:Float = 1;

		var leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
		var rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);

		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		for (index in 0...length)
		{
			var lmin:Float = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var lmax:Float = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			var rmin:Float = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var rmax:Float = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			sectionWaveform.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), index * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.RED);
		}

		waveformPrinted = true;
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true;//samples > 17200;
		var v1:Bool = false;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1)) {
			if (index >= 0) {
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
					if (sample > lmax) lmax = sample;
				else if (sample < 0)
					if (sample < lmin) lmin = sample;

				if (channels >= 2) {
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					} else if (sample < 0) {
						if (sample < rmin) rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow) {
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
					else array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
					else array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if(gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}
}
#end