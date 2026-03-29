package macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

class AssetsMacro
{
    public static function build()
    {
        embedAssets("assets");
    }

    private static function embedAssets(source:String, ?name:String):Void
    {
        if (name == null) name = source;

        if (FileSystem.isDirectory(source))
        {
            for (file in FileSystem.readDirectory(source))
            {
                embedAssets(Path.join([source, file]), Path.join([name, file]));
            }
        }
        else
        {
            Context.addResource(name, File.getBytes(source));
        }
    }
}
#end
