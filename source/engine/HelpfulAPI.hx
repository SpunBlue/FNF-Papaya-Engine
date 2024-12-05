package engine;

import flixel.FlxG;

using StringTools;

/**
 * An API designed for custom states to load songs, or assist in any other given way.
 */
class HelpfulAPI {
    public static function getDifficultyIndex(difficulty:String) {
        if (difficulty.startsWith('-'))
            difficulty = difficulty.charAt(0).replace('-', '');

        switch (difficulty.toLowerCase()) {
            case 'easy':
                return 0;
            case 'normal' | '':
                return 1;
            case 'hard':
                return 2;
            default:
                trace('Unknown Difficulty - $difficulty');
                return -1;
        }
    }

    public static function getDifficultyFromIndex(difficulty:Int):String {
        switch (difficulty) {
            case 0:
                return 'easy';
            case 1:
                return 'normal';
            case 2:
                return 'hard';
            default:
                trace('Unknown Difficulty - $difficulty');
                return null;
        }
    }
    
    public static function retrieveSong(name:String, difficulty:String) {
        name = name.toLowerCase();
        difficulty = difficulty.toLowerCase();

        return Song.loadFromJson('$name-$difficulty', name);
    }

    public static function playSong(name:String, difficulty:String) {
        PlayState.curSong = retrieveSong(name, difficulty);

        PlayState.storyWeek = -1;
        PlayState.isStoryMode = false;
        PlayState.storyDifficulty = difficulty.toLowerCase();
        PlayState.chartingMode = false;

        FlxG.sound.music.stop();
        FlxG.switchState(new PlayState());
    }

    public static function playSongs(names:Array<String>, difficulty:String, ?week:Int = -1) {
        PlayState.curSong = retrieveSong(names[0], difficulty);
        PlayState.isStoryMode = true;
        PlayState.storyWeek = week;
        PlayState.campaignScore = 0;
        PlayState.storyDifficulty = difficulty.toLowerCase();
        PlayState.storyPlaylist = names;
        PlayState.chartingMode = false;
        
        FlxG.sound.music.stop();
        FlxG.switchState(new PlayState());
    }
}