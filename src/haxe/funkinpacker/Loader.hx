package funkinpacker;

import haxe.Exception;
import webview.WebView;
import haxe.atomic.AtomicBool;

using StringTools;

@:nullSafety
class Loader
{
	public static var webview:Null<WebView> = null;
	public static var running:AtomicBool = new AtomicBool(false);

	public static function load(debug:Bool = false):Void
	{
		Server.startServer('assets');

		webview = new WebView(debug);
		webview.setTitle('Funkin Packer');
		webview.setSize(1300, 720, NONE);
		webview.navigate(Server.resolveAsset('index.html'));

		running.store(true);
		try
		{
			webview.run();
		}
		catch (e:Exception)
		{
			trace('WebView Main Loop ran into an exception: ${e.stack}');
		}

		cleanup(false);
	}

	public static function cleanup(terminate:Bool = true):Void
	{
		if (!running.load())
			return;

		running.store(false);
		Server.closeServer();

		if (webview != null)
		{
			if (terminate)
				webview.terminate();
			webview.destroy();
			webview = null;
		}
	}
}
