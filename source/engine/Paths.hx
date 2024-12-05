package engine;

import flixel.graphics.frames.FlxAtlasFrames;

class Paths
{
    /**
     * Get Image
     * @param path 
     * @return String Path to image `assets/images/test.png`;
     */
    public static function getImage(path:String):String
    {
        return 'assets/images/$path.png';
    }

    /**
     * Get Sparrow
     * @param path 
     * @return FlxAtlasFrames
     */
    public static function getSparrow(path:String):FlxAtlasFrames
    {
        return FlxAtlasFrames.fromSparrow(getImage('$path'), 'assets/images/$path.xml');
    }

    /**
     * Get Song
     * @param songName Name of Song
     * @param file Inst/Voices or some other third thing
     * @return String Path to Song `assets/songs/test/Inst.ogg`;
     */
    public static function getSong(songName:String, file:String):String
    {
        return 'assets/songs/$songName/$file${TitleState.soundExt}';
    }

    /**
     * Get Sound
     * @param soundName Name of Sound
     * @return String Path to Sound `assets/sounds/test/test.ogg`;
     */
     public static function getSound(soundName:String):String
    {
        return 'assets/sounds/$soundName${TitleState.soundExt}';
    }

    /**
     * Get JSON
     * @param path 
     * @return String Path to JSON `assets/data/test.json`;
     */
    public static function getJSON(path:String):String
    {
        return 'assets/data/$path.json';
    }

    /**
     * Get TXT
     * @param path 
     * @return String Path to TXT `assets/data/test.txt`;
     */
    public static function getTxt(path:String) {
        return 'assets/data/$path.txt';
    }
}