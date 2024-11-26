package engine;

import flixel.FlxG;

using StringTools;

/**
 * An API designed for custom states to load songs, or assist in any other given way.
 */
class HelpfulAPI {
    public static function getDifficultyIndex(difficulty:String) {
        switch (difficulty.toLowerCase().replace('-', '')) {
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
        PlayState.SONG = retrieveSong(name, difficulty);
        PlayState.isStoryMode = false;
        PlayState.storyDifficulty = difficulty.toLowerCase();

        FlxG.sound.music.stop();
        FlxG.switchState(new PlayState());
    }

    public static function playSongs(names:Array<String>, difficulty:String) {
        PlayState.SONG = retrieveSong(names[0], difficulty);
        PlayState.isStoryMode = true;
        PlayState.campaignScore = 0;
        PlayState.storyDifficulty = difficulty.toLowerCase();
        PlayState.storyPlaylist = names;
        
        FlxG.sound.music.stop();
        FlxG.switchState(new PlayState());
    }
}