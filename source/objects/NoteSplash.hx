package objects;

import engine.Styles.StyleHandler;
import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite {
    var properties:SplashProperties = null;

    override public function new(?x:Float = 0, ?y:Float = 0)
    {
        super(x, y);

        var style = StyleHandler.curStyle;
        properties = style.splashProperties;

        frames = StyleHandler.getSparrow(style.splashesImagePath);

        for (i in 1...properties.impactAmount + 1)
        {
            animation.addByPrefix("purpleSplash" + i, 'note impact $i purple', properties.fps, false);
            animation.addByPrefix("blueSplash" + i, 'note impact $i blue', properties.fps, false);
            animation.addByPrefix("greenSplash" + i, 'note impact $i green', properties.fps, false);
            animation.addByPrefix("redSplash" + i, 'note impact $i red', properties.fps, false);
        }
    }

    override public function update(elapsed:Float){
        super.update(elapsed);

        if (animation.curAnim.finished)
            this.kill();
    }

    public function splash(note:Int = 0, x:Float, y:Float)
    {
        this.setPosition(x + properties.offsetX, y + properties.offsetY);

        var color:String = null;
        switch (note) {
            default:
                color = 'purple';
            case 1:
                color = 'blue';
            case 2:
                color = 'green';
            case 3:
                color = 'red';
        }

        var rand:Int = FlxG.random.int(1, properties.impactAmount);
        this.animation.play('${color}Splash${rand}');
        
        this.alpha = properties.alpha;
    }
}

typedef SplashProperties =
{
    var fps:Int;
    var offsetX:Float;
    var offsetY:Float;
    var alpha:Float;
    var impactAmount:Int;
}